//
//  AssetPlayer+AssetPlayerActions.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import Foundation
import AVKit

public enum AssetPlayerSetupOptions {
    case startMuted, shouldLoop
}

public enum AssetPlayerActions {
    case setup(with: Asset, options: [AssetPlayerSetupOptions], remoteCommands: [RemoteCommand])
    case play
    case pause
    case togglePlayPause
    case stop
    case beginFastForward
    case endFastForward
    case beginRewind
    case endRewind
    case seekToTimeInSeconds(time: Double)
    case skip(by: Double)
    case changePlayerPlaybackRate(to: Float)
    case changeIsPlayingLocalAsset(to: Bool)
    case changeShouldLoop(to: Bool)
    case changeStartTimeForLoop(to: Double)
    case changeEndTimeForLoop(to: Double)
    case changeIsMuted(to: Bool)
    case changeVolume(to: Float)
}

extension AssetPlayer {
    // swiftlint:disable cyclomatic_complexity
    open func perform(action: AssetPlayerActions) {
        switch action {
        case .setup(let asset, let options, let remoteCommands):
            handleSetup(with: asset, options: options, remoteCommands: remoteCommands)
        case .play:
            self.state = .playing
        case .pause:
            self.state = .paused
        case .seekToTimeInSeconds(let time):
            seekToTimeInSeconds(time) { _ in }
        case .changePlayerPlaybackRate(let rate):
            changePlayerPlaybackRate(to: rate)
        case .changeIsPlayingLocalAsset(let isPlayingLocalAsset):
            self.isPlayingLocalAsset = isPlayingLocalAsset
        case .changeShouldLoop(let shouldLoop):
            self.shouldLoop = shouldLoop
        case .changeStartTimeForLoop(let time):
            handleChangeStartTimeForLoop(to: time)
        case .changeEndTimeForLoop(let time):
            handleChangeEndTimeForLoop(to: time)
        case .changeIsMuted(let isMuted):
            player.isMuted = isMuted
        case .stop:
            handleStop()
        case .beginFastForward:
            perform(action: .changePlayerPlaybackRate(to: 2.0))
        case .beginRewind:
            perform(action: .changePlayerPlaybackRate(to: -2.0))
        case .endRewind, .endFastForward:
            perform(action: .changePlayerPlaybackRate(to: 1.0))
        case .togglePlayPause:
            handleTogglePlayPause()
        case .skip(let interval):
            perform(action: .seekToTimeInSeconds(time: currentTime + interval))
        case .changeVolume(let newVolume):
            player.volume = newVolume
        }
    }
    // swiftlint:enable cyclomatic_complexity

    private func handleSetup(with asset: Asset, options: [AssetPlayerSetupOptions], remoteCommands: [RemoteCommand]) {
        self.setup(with: asset)
        self.player.isMuted = options.contains(.startMuted)
        self.shouldLoop = options.contains(.shouldLoop)
        self.isPlayingLocalAsset = asset.isLocalFile
        self.enableRemoteCommands(remoteCommands)
        
        // Allow background audio and playing audio with silent switch on
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func handleChangeStartTimeForLoop(to time: Double) {
        guard time > 0 else {
            self.startTimeForLoop = 0
            return
        }
        self.startTimeForLoop = time
    }

    private func handleChangeEndTimeForLoop(to time: Double) {
        guard self.duration != 0 else {
            return
        }
        guard time < self.duration else {
            self.endTimeForLoop = self.duration
            return
        }
        self.endTimeForLoop = time
    }

    private func handleTogglePlayPause() {
        if state == .playing {
            self.perform(action: .pause)
        } else {
            self.perform(action: .play)
        }
    }

    internal func handleStop() {
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

    private func setup(with asset: Asset) {
        self.updateGeneralMetadata()

        self.state = .setup(asset: asset)

        // Seconds time observer
        let interval = CMTimeMake(value: 1, timescale: 2)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            self?.handleSecondTimeObserver(with: time)
        }

        // Millisecond time observer
        let millisecondInterval = CMTimeMake(value: 1, timescale: 100)
        timeObserverTokenMilliseconds = player.addPeriodicTimeObserver(forInterval: millisecondInterval, queue: DispatchQueue.main) { [weak self] time in
            self?.handleMillisecondTimeObserver(with: time)
        }
    }

    private func handleSecondTimeObserver(with time: CMTime) {
        guard self.state != .finished else { return }

        self.delegate?.playerCurrentTimeDidChange(self)
        self.updatePlaybackMetadata()
    }

    private func handleMillisecondTimeObserver(with time: CMTime) {
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

    private func seekToTimeInSeconds(_ time: Double, completion: ((Bool) -> Void)?) {
        guard asset != nil else { return }
        let newPosition = CMTimeMakeWithSeconds(time, preferredTimescale: 1000)
        if let completion = completion {
            self.player.seek(to: newPosition, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: completion)
        } else {
            self.player.seek(to: newPosition, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
        self.updatePlaybackMetadata()
    }

    private func changePlayerPlaybackRate(to newRate: Float) {
        guard asset != nil else { return }
        self.rate = newRate
    }
}
