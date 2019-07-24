//
//  AssetPlayer+AssetPlayerActions.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import Foundation
import AVKit

public enum AssetPlayerAction {
    case setup(with: Asset)
    case setupRemoteCommands([RemoteCommand])
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
    case changeIsMuted(to: Bool)
    case changeVolume(to: Float)
}

extension AssetPlayer {
    // swiftlint:disable cyclomatic_complexity
    public func perform(action: AssetPlayerAction) {
        switch action {
        case .setup(let asset):
            handleSetup(with: asset)
        case .setupRemoteCommands(let commands):
            self.remoteCommands = commands
        case .play:
            self.state = .playing
        case .pause:
            self.state = .paused
        case .seekToTimeInSeconds(let time):
            seekToTimeInSeconds(time) { _ in }
        case .changePlayerPlaybackRate(let rate):
            changePlayerPlaybackRate(to: rate)
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

    private func handleSetup(with asset: Asset) {
        // Allow background audio and playing audio with silent switch on
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

        self.state = .setup(asset: asset)
        self.updateGeneralMetadata()
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
        player.replaceCurrentItem(with: nil)
        playerView.player = nil

        removePlayerItemObservers(playerItem: self.asset?.playerItem)
    }

    internal func setupTimeObservers() {
        timeObserverToken = nil
        timeObserverTokenMilliseconds = nil

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

        self.delegate?.playerCurrentTimeDidChange(self.properties)
        self.updatePlaybackMetadata()
    }

    private func handleMillisecondTimeObserver(with time: CMTime) {
        guard self.state != .finished else { return }

        let timeElapsed = time.seconds

        self.currentTime = timeElapsed
        self.delegate?.playerCurrentTimeDidChangeInMilliseconds(self.properties)
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
