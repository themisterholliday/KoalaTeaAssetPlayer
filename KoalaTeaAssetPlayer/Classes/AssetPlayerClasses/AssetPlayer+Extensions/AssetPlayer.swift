//
//  AssetPlayer.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 9/26/17.
//

import Foundation
import AVFoundation
import MediaPlayer
import SwifterSwift

public protocol AssetPlayerDelegate: class {
    // Setup
    func playerIsSetup(_ player: AssetPlayer)

    // Playback
    func playerPlaybackStateDidChange(_ player: AssetPlayer)
    func playerCurrentTimeDidChange(_ player: AssetPlayer)
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer)
    func playerPlaybackDidEnd(_ player: AssetPlayer)
    
    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set buffering progress.
    func playerBufferedTimeDidChange(_ player: AssetPlayer)
}

public enum AssetPlayerPlaybackState: Equatable {
    case setup(asset: Asset)
    case playing, paused, buffering, finished, idle
    case failed(error: Error?)

    public static func == (lhs: AssetPlayerPlaybackState, rhs: AssetPlayerPlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.setup(let lKey), .setup(let rKey)):
            return lKey == rKey
        case (.playing, .playing):
            return true
        case (.paused, .paused):
            return true
        case (.failed, .failed):
            return true
        case (.buffering, .buffering):
            return true
        case (.finished, .finished):
            return true
        case (.idle, .idle):
            return true
        default:
            return false
        }
    }
}

open class AssetPlayer: NSObject {
    private struct Constants {
        // Keys required for a playable item
        static let AssetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
    }

    public weak var delegate: AssetPlayerDelegate?

    // MARK: Properties
    internal var isPlayingLocalAsset: Bool = false
    internal var currentTime: Double = 0
    internal var bufferedTime: Double = 0

    internal var duration: Double {
        guard let currentItem = player.currentItem?.asset else { return 0.0 }

        return currentItem.duration.seconds
    }

    internal var rate: Float = 1.0 {
        willSet {
            guard newValue != self.rate else { return }
        }
        didSet {
            player.rate = rate
            self.setAudioTimePitch(by: rate)
        }
    }

    internal var isMovingInQueue: Bool = false

    // MARK: AV Properties

    /// The instance of `MPNowPlayingInfoCenter` that is used for updating metadata for the currently playing `Asset`.
    internal let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    /// AVPlayer to pass in to any PlayerView's
    internal let player = AVPlayer()

    private var currentAVAudioTimePitchAlgorithm: AVAudioTimePitchAlgorithm = .timeDomain {
        willSet {
            guard newValue != self.currentAVAudioTimePitchAlgorithm else { return }
        }
        didSet {
            self.player.currentItem?.audioTimePitchAlgorithm = self.currentAVAudioTimePitchAlgorithm
        }
    }

    private func setAudioTimePitch(by rate: Float) {
        guard rate <= 2.0 else {
            self.currentAVAudioTimePitchAlgorithm = .spectral
            return
        }
        self.currentAVAudioTimePitchAlgorithm = .timeDomain
    }

    internal var asset: Asset? {
        willSet {
            self.removePlayerItemObservers()
        }
        didSet {
            guard let newAsset = self.asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }

    internal var currentAssetIndex: Int = 0

    // MARK: - Periodic Time Observers
    internal var timeObserverToken: Any?
    internal var timeObserverTokenMilliseconds: Any?

    // MARK: - Property Observers
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    private var playbackStatusObserver: NSKeyValueObservation?
    private var playbackDurationObserver: NSKeyValueObservation?
    private var playbackRateObserver: NSKeyValueObservation?

    internal var previousState: AssetPlayerPlaybackState

    /// The state that the internal `AVPlayer` is in.
    internal var state: AssetPlayerPlaybackState {
        willSet {
            guard state != newValue else { return }
        }
        didSet {
            self.previousState = oldValue
            self.handleStateChange(state)
        }
    }

    public lazy var playerView: PlayerView = {
        let playerView = PlayerView()
        playerView.player = self.player
        return playerView
    }()

    private var remoteCommands: [RemoteCommand] = []
    private lazy var remoteCommandManager: RemoteCommandManager = RemoteCommandManager(assetPlaybackManager: self)

    // MARK: - Life Cycle
    public override init() {
        self.state = .idle
        self.previousState = .idle

        super.init()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    deinit {
        handleStop()
    }

    // MARK: - Asset Loading
    private func asynchronouslyLoadURLAsset(_ newAsset: Asset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.urlAsset.loadValuesAsynchronously(forKeys: Constants.AssetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset == self.asset else { return }
                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in Constants.AssetKeysRequiredToPlay {
                    var error: NSError?

                    if newAsset.urlAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        self.state = .failed(error: error as Error?)

                        return
                    }
                }

                // We can't play this asset.
                if !newAsset.urlAsset.isPlayable || newAsset.urlAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")

                    let error = NSError(domain: message, code: -1, userInfo: nil) as Error
                    self.state = .failed(error: error)

                    return
                }

                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                let playerItem = AVPlayerItem(asset: newAsset.urlAsset)
                self.player.replaceCurrentItem(with: playerItem)
                self.delegate?.playerIsSetup(self)
                self.addPlayerItemObservers(playerItem: playerItem)
                self.setupTimeObservers()
                
                if self.state != .playing, self.state != .paused, self.state != .buffering {
                    self.state = .idle
                }
            }
        }
    }

    /*
     A formatter for individual date components used to provide an appropriate
     value for any text properties.

     Lazy init because creating a formatter multiple times is expensive
     */
    internal lazy var timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]

        return formatter
    }()
}

// MARK: State Management Methods
extension AssetPlayer {
    private func handleStateChange(_ state: AssetPlayerPlaybackState) {
        switch state {
        case .idle:
            self.player.pause()
        case .setup(let asset):
            self.asset = asset
        case .playing:
            self.player.playImmediately(atRate: self.rate)
        case .paused:
            self.player.pause()
        case .failed:
            self.player.pause()
        case .buffering:
            self.player.pause()
        case .finished:
            self.player.pause()
        }

        self.delegate?.playerPlaybackStateDidChange(self)
    }
}

// MARK: Asset Player Observers
extension AssetPlayer {
    private func addPlayerItemObservers(playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)),
                                               name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new, .old, .initial], changeHandler: { [weak self] playerItem, _ in
            self?.handleBufferEmptyChange(playerItem: playerItem)
        })

        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old, .initial], changeHandler: { [weak self] playerItem, _ in
            self?.handleLikelyToKeepUpChange(playerItem: playerItem)
        })

        loadedTimeRangesObserver = playerItem.observe(\.loadedTimeRanges, options: [.new, .old, .initial], changeHandler: { [weak self] playerItem, _ in
            self?.handleLoadedTimeRangesChange(playerItem: playerItem)
        })

        playbackStatusObserver = playerItem.observe(\.status, options: [.new, .old], changeHandler: { [weak self] _, change in
            self?.handleStatusChange(change: change)
        })
    }

    internal func removePlayerItemObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        playbackStatusObserver?.invalidate()
        playbackDurationObserver?.invalidate()
        playbackRateObserver?.invalidate()
    }

    @objc private func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        self.delegate?.playerPlaybackDidEnd(self)
        self.state = .finished
    }

    private func handleBufferEmptyChange(playerItem: AVPlayerItem) {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerEmptyBufferKey
        if playerItem.isPlaybackBufferEmpty && !playerItem.isPlaybackBufferFull {
            self.state = .buffering
        }
    }

    private func handleLikelyToKeepUpChange(playerItem: AVPlayerItem) {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerKeepUpKey
        if playerItem.isPlaybackLikelyToKeepUp {
            if self.state == .buffering, previousState == .playing {
                self.state = previousState
            }
        } else {
            if self.state != .buffering, self.state != .paused {
                self.state = .buffering
            }
        }
    }

    private func handleLoadedTimeRangesChange(playerItem: AVPlayerItem) {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerLoadedTimeRangesKey
        let timeRanges = playerItem.loadedTimeRanges
        if let timeRange = timeRanges.first?.timeRangeValue {
            let bufferedTime = Double(CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration)))
            self.bufferedTime = bufferedTime
            self.delegate?.playerBufferedTimeDidChange(self)
        }
    }

    private func handleStatusChange(change: NSKeyValueObservedChange<AVPlayerItem.Status>) {
        var newStatus: AVPlayerItem.Status

        if let status = change.newValue {
            newStatus = status
        } else {
            newStatus = .unknown
        }

        if newStatus == .failed {
            self.state = .failed(error: player.currentItem?.error)
        }
        updateGeneralMetadata()
    }

    @objc func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            // Interruption began, take appropriate actions
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                    self.perform(action: .play)
                } else {
                    // Interruption Ended - playback should NOT resume
                    self.perform(action: .pause)
                }
            }
        }
    }

    @objc func appMovedToBackground() {
        playerView.playerLayer.player = nil
        playerView.alpha = 0
    }

    @objc func appMovedToForeground() {
        playerView.playerLayer.player = self.player
        UIView.animate(withDuration: 0.5) {
            self.playerView.alpha = 1
        }
    }
}

extension AssetPlayer {
    func enableRemoteCommands(_ commands: [RemoteCommand]) {
        self.remoteCommandManager.enableCommands(from: commands)
    }
}



////swiftlint:disable block_based_kvo
//open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
//    // Make sure the this KVO callback was intended for this view controller.
//    guard context == &AssetPlayerKVOContext else {
//        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        return
//    }
//
//    switch keyPath {
//    case "currentItem":
//        print("did change")
//        guard let currentItem = self.player.currentItem else {
//            guard !self.isMovingInQueue else { return }
//            self.currentAsset = nil
//            self.removePlayerObservers()
//            self.removePlayerItemObservers()
//            self.delegate?.playerPlaybackDidEnd(self)
//            self.state = .finished
//            return
//        }
//        handleChangingCurrentPlayerItem(to: currentItem)
//    default:
//        break
//    }
//}
////swiftlint:enable block_based_kvo
//
//internal func handleChangingCurrentPlayerItem(to currentItem: AVPlayerItem) {
//    print("handling")
//    let asset = assets?.filter({ $0.urlAsset == currentItem.asset }).first
//    currentAsset = asset
//    if let asset = asset {
//        currentAssetIndex = assets?.firstIndex(of: asset) ?? 0
//        print(currentAssetIndex)
//    }
//    addPlayerItemObservers(playerItem: currentItem)
//    setupTimeObservers()
//}

//func addPlayerObservers() {
//    player.addObserver(self, forKeyPath: "currentItem", options: [.old, .new], context: &AssetPlayerKVOContext)
//}
//
//func removePlayerObservers() {
//    player.removeObserver(self, forKeyPath: "currentItem", context: &AssetPlayerKVOContext)
//}


///*
// KVO context used to differentiate KVO callbacks for this class versus other
// classes in its class hierarchy.
// */
//private var AssetPlayerKVOContext = 0
