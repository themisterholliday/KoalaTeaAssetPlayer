//
//  AssetQueuePlayer.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/22/19.
//

import Foundation
import SwifterSwift

public protocol AssetQueuePlayerDelegate: class {
    func playerIsSetup(_ properties: AssetQueuePlayerProperties)
    func playerPlaybackStateDidChange(_ properties: AssetQueuePlayerProperties)
    func playerCurrentTimeDidChange(_ properties: AssetQueuePlayerProperties)
    func playerCurrentTimeDidChangeInMilliseconds(_ properties: AssetQueuePlayerProperties)
    func playerPlaybackDidEnd(_ properties: AssetQueuePlayerProperties)
    func playerBufferedTimeDidChange(_ properties: AssetQueuePlayerProperties)
    func playerDidChangeAsset(_ properties: AssetQueuePlayerProperties)
}

public enum AssetQueuePlayerAction {
    case setup(with: [Asset])
    case nextAsset
    case previousAsset
    case moveToAsset(at: Int)

    case assetPlayerAction(value: AssetPlayerAction)
    public static func setupRemoteCommands(_ commands: [RemoteCommand]) -> AssetQueuePlayerAction { return assetPlayerAction(value: .setupRemoteCommands(commands)) }
    public static var play: AssetQueuePlayerAction { return assetPlayerAction(value: .play) }
    public static var pause: AssetQueuePlayerAction { return assetPlayerAction(value: .pause) }
    public static var togglePlayPause: AssetQueuePlayerAction { return assetPlayerAction(value: .togglePlayPause) }
    public static var stop: AssetQueuePlayerAction { return assetPlayerAction(value: .stop) }
    public static var beginFastForward: AssetQueuePlayerAction { return assetPlayerAction(value: .beginFastForward) }
    public static var endFastForward: AssetQueuePlayerAction { return assetPlayerAction(value: .endFastForward) }
    public static var beginRewind: AssetQueuePlayerAction { return assetPlayerAction(value: .beginRewind) }
    public static var endRewind: AssetQueuePlayerAction { return assetPlayerAction(value: .endRewind) }
    public static func seekToTimeInSeconds(time: Double) -> AssetQueuePlayerAction { return assetPlayerAction(value: .seekToTimeInSeconds(time: time)) }
    public static func skip(by: Double) -> AssetQueuePlayerAction { return assetPlayerAction(value: .skip(by: by)) }
    public static func changePlayerPlaybackRate(to: Float) -> AssetQueuePlayerAction { return assetPlayerAction(value: .changePlayerPlaybackRate(to: to)) }
    public static func changeIsMuted(to: Bool) -> AssetQueuePlayerAction { return assetPlayerAction(value: .changeIsMuted(to: to)) }
    public static func changeVolume(to: Float) -> AssetQueuePlayerAction { return assetPlayerAction(value: .changeVolume(to: to)) }
}

final public class AssetQueuePlayer {
    public weak var delegate: AssetQueuePlayerDelegate?
    
    private lazy var assetPlayer = AssetPlayer()
    private lazy var playerView = assetPlayer.playerView

    private var assets: [Asset] = []
    private var currentAsset: Asset?
    private var currentAssetIndex: Int = 0

    public init(remoteCommands: [RemoteCommand] = []) {
        assetPlayer.delegate = self
        assetPlayer.remoteCommands = remoteCommands
    }

    public func perform(action: AssetQueuePlayerAction) {
        switch action {
        case .assetPlayerAction(let value):
            assetPlayer.perform(action: value)
        case .setup(let assets):
            self.assets = assets
            guard let firstAsset = assets.first else {
                return
            }
            currentAsset = firstAsset
            assetPlayer.perform(action: .setup(with: firstAsset))
        case .nextAsset:
            guard currentAssetIndex != assets.count else { return }
            moveToAsset(at: currentAssetIndex + 1)
        case .previousAsset:
            guard currentAssetIndex != 0 else { return }
            moveToAsset(at: currentAssetIndex - 1)
        case .moveToAsset(let index):
            moveToAsset(at: index)
        }
    }

    private func moveToAsset(at index: Int) {
        guard let asset = assets[safe: index] else { return }
        assetPlayer.perform(action: .setup(with: asset))
        perform(action: .play)
        currentAsset = asset
        currentAssetIndex = index
        delegate?.playerDidChangeAsset(self.properties)
    }
}

extension AssetQueuePlayer: AssetPlayerDelegate {
    public func playerIsSetup(_ properties: AssetPlayerProperties) {
        delegate?.playerIsSetup(self.properties)
    }

    public func playerPlaybackStateDidChange(_ properties: AssetPlayerProperties) {
        delegate?.playerPlaybackStateDidChange(self.properties)
    }

    public func playerCurrentTimeDidChange(_ properties: AssetPlayerProperties) {
        delegate?.playerCurrentTimeDidChange(self.properties)
    }

    public func playerCurrentTimeDidChangeInMilliseconds(_ properties: AssetPlayerProperties) {
        delegate?.playerCurrentTimeDidChangeInMilliseconds(self.properties)
    }

    public func playerPlaybackDidEnd(_ properties: AssetPlayerProperties) {
        guard currentAssetIndex != (assets.count - 1) else {
            delegate?.playerPlaybackDidEnd(self.properties)
            return
        }
        perform(action: .nextAsset)
    }

    public func playerBufferedTimeDidChange(_ properties: AssetPlayerProperties) {
        delegate?.playerBufferedTimeDidChange(self.properties)
    }
}

fileprivate extension AssetQueuePlayer {
    static var defaultCommands: [RemoteCommand] {
        return [
            .playback,
            .changePlaybackPosition,
            .seekForwardAndBackward,
            .next,
            .previous,
        ]
    }
}

public struct AssetQueuePlayerProperties {
    public let assets: [Asset]?
    public let currentAsset: Asset?
    public let currentAssetIndex: Int?
    public let isMuted: Bool
    public let currentTime: Double
    public let bufferedTime: Double
    public let currentTimeText: String
    public let durationText: String
    public let timeLeftText: String
    public let duration: Double
    public let rate: Float
    public let state: AssetPlayerPlaybackState
    public let previousState: AssetPlayerPlaybackState
}

public extension AssetQueuePlayer {
    var properties: AssetQueuePlayerProperties {
        let playerPropertires = assetPlayer.properties
        return AssetQueuePlayerProperties(assets: assets,
                                          currentAsset: currentAsset,
                                          currentAssetIndex: currentAssetIndex,
                                          isMuted: playerPropertires.isMuted,
                                          currentTime: playerPropertires.currentTime,
                                          bufferedTime: playerPropertires.bufferedTime,
                                          currentTimeText: playerPropertires.currentTimeText,
                                          durationText: playerPropertires.durationText,
                                          timeLeftText: playerPropertires.timeLeftText,
                                          duration: playerPropertires.duration,
                                          rate: playerPropertires.rate,
                                          state: playerPropertires.state,
                                          previousState: playerPropertires.previousState)
    }
}
