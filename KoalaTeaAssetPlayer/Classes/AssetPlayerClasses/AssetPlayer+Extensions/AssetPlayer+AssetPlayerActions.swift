//
//  AssetPlayer+AssetPlayerActions.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import Foundation
import AVKit

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

extension AssetPlayer {
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
                self.startTimeForLoop = 0
                return
            }
            self.startTimeForLoop = time
        case .changeEndTimeForLoop(let time):
            guard self.duration != 0 else {
                return
            }
            guard time < self.duration else {
                self.endTimeForLoop = self.duration
                return
            }
            self.endTimeForLoop = time
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

    private func setup(with asset: AssetProtocol) {
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

    internal func seekTo(_ newPosition: CMTime) {
        guard asset != nil else { return }
        self.player.seek(to: newPosition, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    internal func seekToTimeInSeconds(_ time: Double, completion: @escaping (Bool) -> Void) {
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
