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

    func playerDidFail(_ error: Error?)
}

public enum AssetPlayerPlaybackState: Equatable {
    case setup(asset: Asset)
    case playing, paused, buffering, finished, none
    case failed(error: Error?)

    public static func == (lhs: AssetPlayerPlaybackState, rhs: AssetPlayerPlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.setup(let lKey), .setup(let rKey)):
            return lKey.urlAsset.url == rKey.urlAsset.url
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
        case (.none, .none):
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
    internal var isPlayingLocalAsset: Bool
    internal var shouldLoop: Bool
    internal var startTimeForLoop: Double = 0
    internal var endTimeForLoop: Double?
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
            self.avPlayerItem?.audioTimePitchAlgorithm = self.currentAVAudioTimePitchAlgorithm
        }
    }

    private func setAudioTimePitch(by rate: Float) {
        guard rate <= 2.0 else {
            self.currentAVAudioTimePitchAlgorithm = .spectral
            return
        }
        self.currentAVAudioTimePitchAlgorithm = .timeDomain
    }

    internal var avPlayerItem: AVPlayerItem? = nil {
        willSet {
            if avPlayerItem != nil {
                self.removePlayerItemObservers()
            }
        }
        didSet {
            if avPlayerItem != nil {
                self.addPlayerItemObservers()
            }
            /*
             If needed, configure player item here before associating it with a player.
             (example: adding outputs, setting text style rules, selecting media options)
             */
            player.replaceCurrentItem(with: self.avPlayerItem)
        }
    }

    internal var asset: Asset? {
        didSet {
            guard let newAsset = self.asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }

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

    // MARK: - Life Cycle
    public override init() {
        self.state = .none
        self.previousState = .none
        self.isPlayingLocalAsset = false
        self.shouldLoop = false

        super.init()

        // Allow background audio and playing audio with silent switch on
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
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
                guard newAsset.urlAsset == self.asset?.urlAsset else { return }

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
                self.avPlayerItem = AVPlayerItem(asset: newAsset.urlAsset)
                self.delegate?.playerIsSetup(self)
                
                if self.state != .playing, self.state != .paused, self.state != .buffering {
                    self.state = .none
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
        case .none:
            self.player.pause()
        case .setup(let asset):
            self.asset = asset
        case .playing:
            self.player.playImmediately(atRate: self.rate)
        case .paused:
            self.player.pause()
        case .failed(let error):
            self.player.pause()
            self.delegate?.playerDidFail(error)
        case .buffering:
            self.player.pause()
        case .finished:
            self.player.pause()

            guard !shouldLoop else {
                self.currentTime = startTimeForLoop
                self.seekToTimeInSeconds(startTimeForLoop) { _ in
                    self.state = .playing
                }
                return
            }
        }

        self.delegate?.playerPlaybackStateDidChange(self)
    }
}

// MARK: Asset Player Observers
extension AssetPlayer {
    private func addPlayerItemObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAVPlayerItemDidPlayToEndTimeNotification(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: avPlayerItem)

        playbackBufferEmptyObserver = avPlayerItem?.observe(\.isPlaybackBufferEmpty, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            self?.handleBufferEmptyChange()
        })

        playbackLikelyToKeepUpObserver = avPlayerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            self?.handleLikelyToKeepUpChange()
        })

        loadedTimeRangesObserver = avPlayerItem?.observe(\.loadedTimeRanges, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            self?.handleLoadedTimeRangesChange()
        })

        playbackStatusObserver = avPlayerItem?.observe(\.status, options: [.new, .old, .initial], changeHandler: { [weak self] _, change in
            self?.handleStatusChange(change: change)
        })

        playbackDurationObserver = avPlayerItem?.observe(\.duration, options: [.new, .old, .initial], changeHandler: { _, _ in
            // Should be ready to play here
            // @TODO: handle
        })

        playbackRateObserver = player.observe(\.rate, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            self?.updatePlaybackMetadata()
        })
    }

    internal func removePlayerItemObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: avPlayerItem)

        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        playbackStatusObserver?.invalidate()
        playbackDurationObserver?.invalidate()
        playbackRateObserver?.invalidate()
    }

    @objc private func handleAVPlayerItemDidPlayToEndTimeNotification(notification: Notification) {
        guard !shouldLoop else {
            self.currentTime = startTimeForLoop
            self.seekToTimeInSeconds(startTimeForLoop) { _ in
                self.state = .playing
            }
            return
        }

        self.delegate?.playerPlaybackDidEnd(self)
        self.state = .finished
    }

    private func handleBufferEmptyChange() {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerEmptyBufferKey
        if let item = self.avPlayerItem {
            if item.isPlaybackBufferEmpty && !item.isPlaybackBufferFull {
                self.state = .buffering
            }
        }
    }

    private func handleLikelyToKeepUpChange() {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerKeepUpKey
        if let item = self.avPlayerItem {
            if item.isPlaybackLikelyToKeepUp {
                if self.state == .buffering, previousState == .playing {
                    self.state = previousState
                }
            } else {
                if self.state != .buffering, self.state != .paused {
                    self.state = .buffering
                }
            }
        }
    }

    private func handleLoadedTimeRangesChange() {
        // No need to use this keypath if we are playing local video
        guard !isPlayingLocalAsset else { return }

        // PlayerLoadedTimeRangesKey
        if let item = self.avPlayerItem {
            let timeRanges = item.loadedTimeRanges
            if let timeRange = timeRanges.first?.timeRangeValue {
                let bufferedTime = Double(CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration)))
                self.bufferedTime = bufferedTime
                self.delegate?.playerBufferedTimeDidChange(self)
            }
        }
    }

    private func handleStatusChange(change: NSKeyValueObservedChange<AVPlayerItem.Status>) {
        var newStatus: AVPlayerItem.Status

        if let status = change.newValue {
            newStatus = status
        } else {
            newStatus = .unknown
        }

        if newStatus == .failed, newStatus == .unknown {
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
