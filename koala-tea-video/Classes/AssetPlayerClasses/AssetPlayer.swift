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
    func currentAssetDidChange(_ player: AssetPlayer)
    func playerIsSetup(_ player: AssetPlayer)

    // Playback
    func playerPlaybackStateDidChange(_ player: AssetPlayer)
    func playerCurrentTimeDidChange(_ player: AssetPlayer)
    /// Current time change but in milliseconds
    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer)
    func playerPlaybackDidEnd(_ player: AssetPlayer)
    
    // This is the time in seconds that the video has been buffered.
    // If implementing a UIProgressView, user this value / player.maximumDuration to set progress.
    func playerBufferTimeDidChange(_ player: AssetPlayer)
}

public enum AssetPlayerPlaybackState: Equatable {
    case setup(asset: AssetProtocol)
    case playing, paused, interrupted, buffering, finished, none
    case failed(error: Error?)

    public static func == (lhs: AssetPlayerPlaybackState, rhs: AssetPlayerPlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.setup(let lKey), .setup(let rKey)):
            return lKey.urlAsset.url == rKey.urlAsset.url
        case (.playing, .playing):
            return true
        case (.paused, .paused):
            return true
        case (.interrupted, .interrupted):
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

extension AssetPlayer {
    private struct Constants {
        // Keys required for a playable item
        static let AssetKeysRequiredToPlay = [
            "playable",
            "hasProtectedContent"
        ]
    }

    public static var defaultLocalPlayer: AssetPlayer {
        return AssetPlayer()
    }

    public static var defaultRemotePlayer: AssetPlayer {
        return AssetPlayer()
    }
}

open class AssetPlayer: NSObject {
    /// Player delegate.
    public weak var delegate: AssetPlayerDelegate?

    // MARK: Options
    private var isPlayingLocalAsset: Bool
    private var shouldLoop: Bool
    private var _startTimeForLoop: Double = 0
    public var startTimeForLoop: Double {
        return self._startTimeForLoop
    }
    private var _endTimeForLoop: Double?
    public var endTimeForLoop: Double? {
        return self._endTimeForLoop
    }
    public var isMuted: Bool {
        return self.player.isMuted
    }

    // MARK: - Time Properties
    public var currentTime: Double = 0

    public var bufferedTime: Double = 0 {
        didSet {
            self.delegate?.playerBufferTimeDidChange(self)
        }
    }

    public var timeElapsedText: String {
        return createTimeString(time: self.currentTime)
    }
    public var durationText: String {
        return createTimeString(time: self.duration)
    }

    public var timeLeftText: String {
        let timeLeft = duration - currentTime
        return self.createTimeString(time: timeLeft)
    }

    public var maxSecondValue: Float = 0

    public var duration: Double {
        guard let currentItem = player.currentItem?.asset else { return 0.0 }

        return currentItem.duration.seconds
    }

    public var rate: Float = 1.0 {
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
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()

    /// AVPlayer to pass in to any PlayerView's
    @objc public let player = AVPlayer()

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

    private var avPlayerItem: AVPlayerItem? = nil {
        willSet {
            if avPlayerItem != nil {
                // Remove observers before changing player item
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

    public var asset: AssetProtocol? {
        didSet {
            guard let newAsset = self.asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }

    // MARK: Observers
    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?

    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverTokenMilliseconds: Any?

    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    private var playbackStatusObserver: NSKeyValueObservation?
    private var playbackDurationObserver: NSKeyValueObservation?
    private var playbackRateObserver: NSKeyValueObservation?

    public var previousState: AssetPlayerPlaybackState

    /// The state that the internal `AVPlayer` is in.
    public var state: AssetPlayerPlaybackState {
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
    private func asynchronouslyLoadURLAsset(_ newAsset: AssetProtocol) {
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
                self.delegate?.currentAssetDidChange(self)
                self.delegate?.playerIsSetup(self)
                
                if self.state != .playing, self.state != .paused, self.state != .buffering {
                    self.state = .none
                }

            }
        }
    }

    // MARK: Playback Control Methods.
    // swiftlint:disable cyclomatic_complexity
    open func perform(action: AssetPlayerActions) {
        switch action {
        case .setup(let asset, let startMuted, let shouldLoop):
            self.setup(with: asset)
            self.player.isMuted = startMuted
            self.shouldLoop = shouldLoop
            self.isPlayingLocalAsset = asset.isLocalFile
        case .play:
            self.state = .playing
        case .pause:
            self.state = .paused
        case .seekToTimeInSeconds(let time):
            self.seekToTimeInSeconds(time) { _ in }
        case .changePlayerPlaybackRate(let rate):
            self.changePlayerPlaybackRate(to: rate)
        case .changeIsPlayingLocalAsset(let isPlayingLocalAsset):
            self.isPlayingLocalAsset = isPlayingLocalAsset
        case .changeShouldLoop(let shouldLoop):
            self.shouldLoop = shouldLoop
        case .changeStartTimeForLoop(let time):
            guard time > 0 else {
                self._startTimeForLoop = 0
                return
            }
            self._startTimeForLoop = time
        case .changeEndTimeForLoop(let time):
            guard self.duration != 0 else {
                return
            }
            guard time < self.duration else {
                self._endTimeForLoop = self.duration
                return
            }
            self._endTimeForLoop = time
        case .changeIsMuted(let isMuted):
            self.player.isMuted = isMuted
        case .stop:
            self.handleStop()
        case .beginFastForward:
            self.perform(action: .changePlayerPlaybackRate(to: 2.0))
        case .beginRewind:
            self.perform(action: .changePlayerPlaybackRate(to: -2.0))
        case .endRewind, .endFastForward:
            self.perform(action: .changePlayerPlaybackRate(to: 1.0))
        case .togglePlayPause:
            if state == .playing {
                self.perform(action: .pause)
            } else {
                self.perform(action: .play)
            }
        case .skip(let interval):
            self.perform(action: .seekToTimeInSeconds(time: currentTime + interval))
        }
    }
    // swiftlint:enable cyclomatic_complexity

    func handleStop() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        if let timeObserverTokenMilliseconds = timeObserverTokenMilliseconds {
            player.removeTimeObserver(timeObserverTokenMilliseconds)
            self.timeObserverTokenMilliseconds = nil
        }

        player.pause()
        avPlayerItem = nil
        player.replaceCurrentItem(with: nil)
        playerView.player = nil

        if avPlayerItem != nil {
            self.removePlayerItemObservers()
        }
    }

    // MARK: Time Formatting
    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    // Lazy init time formatter because create a formatter multiple times is expensive
    lazy var timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]

        return formatter
    }()

    private func createTimeString(time: Double) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))

        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
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
            if #available(iOS 10.0, *) {
                self.player.playImmediately(atRate: self.rate)
            } else {
                // Fallback on earlier versions
                self.player.rate = self.rate
                self.player.play()
            }
        case .paused:
            self.player.pause()
        case .interrupted:
            self.player.pause()
        case .failed:
            self.player.pause()
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

    // MARK: Notification Observing Methods
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
}

extension AssetPlayer {
    private func setup(with asset: AssetProtocol) {
        /*
         Update the UI when these player properties change.
         
         Use the context parameter to distinguish KVO for our particular observers
         and not those destined for a subclass that also happens to be observing
         these properties.
         */
        self.updateGeneralMetadata()

        self.state = .setup(asset: asset)

        // Seconds time observer
        let interval = CMTimeMake(value: 1, timescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            self?.handleSecondTimeObserver(with: time)
        }

        // Millisecond time observer
        let millisecondInterval = CMTimeMake(value: 1, timescale: 100)
        timeObserverTokenMilliseconds = player.addPeriodicTimeObserver(forInterval: millisecondInterval, queue: DispatchQueue.main) { [weak self] time in
            self?.handleMillisecondTimeObserver(with: time)
        }
    }

    func handleSecondTimeObserver(with time: CMTime) {
        guard self.state != .finished else { return }

        self.delegate?.playerCurrentTimeDidChange(self)
        self.updatePlaybackMetadata()
    }

    func handleMillisecondTimeObserver(with time: CMTime) {
        guard self.state != .finished else { return }

        let timeElapsed = time.seconds

        self.currentTime = timeElapsed
        self.delegate?.playerCurrentTimeDidChangeInMilliseconds(self)

        // Set finished state if we are looping and passed our loop end time
        if let endTime = self.endTimeForLoop, timeElapsed >= endTime, self.shouldLoop {
            self.state = .finished
        }
    }

    private func seekTo(_ newPosition: CMTime) {
        guard asset != nil else { return }
        self.player.seek(to: newPosition, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    private func seekToTimeInSeconds(_ time: Double, completion: @escaping (Bool) -> Void) {
        guard asset != nil else { return }
        let newPosition = CMTimeMakeWithSeconds(time, preferredTimescale: 1000)
        self.player.seek(to: newPosition, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: completion)

        self.updatePlaybackMetadata()
    }

    private func changePlayerPlaybackRate(to newRate: Float) {
        guard asset != nil else { return }
        self.rate = newRate
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

        playbackDurationObserver = avPlayerItem?.observe(\.duration, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            // Should be ready to play here
            // @TODO: handle
        })

        playbackRateObserver = player.observe(\.rate, options: [.new, .old, .initial], changeHandler: { [weak self] _, _ in
            self?.updatePlaybackMetadata()
        })
    }

    private func removePlayerItemObservers() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: avPlayerItem)

        playbackBufferEmptyObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        playbackStatusObserver?.invalidate()
        playbackDurationObserver?.invalidate()
        playbackRateObserver?.invalidate()
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
}

public enum AssetPlayerActions {
    case setup(with: AssetProtocol, startMuted: Bool, shouldLoop: Bool)
    case play
    case pause
    case togglePlayPause
    case stop
    case beginFastForward
    case endFastForward
    case beginRewind
    case endRewind
    case seekToTimeInSeconds(time: Double)
    case skip(by: TimeInterval)
    case changePlayerPlaybackRate(to: Float)
    case changeIsPlayingLocalAsset(to: Bool)
    case changeShouldLoop(to: Bool)
    case changeStartTimeForLoop(to: Double)
    case changeEndTimeForLoop(to: Double)
    case changeIsMuted(to: Bool)
}

// MARK: MPNowPlayingInforCenter Management Methods
public extension AssetPlayer {
    func updateGeneralMetadata() {
        guard self.player.currentItem != nil, let urlAsset = self.player.currentItem?.asset else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let title = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? asset?.assetName
        let album = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
        var artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()
        if let url = asset?.artworkURL {
            if let data = try? Data(contentsOf: url) {
                artworkData = data
            }
        }

        let image = UIImage(data: artworkData) ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func updatePlaybackMetadata() {
        guard self.player.currentItem != nil else {
            nowPlayingInfoCenter.nowPlayingInfo = nil

            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self.player.currentItem?.currentTime() ?? .zero)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = self.player.rate

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}

private extension AssetPlayer {
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
}
