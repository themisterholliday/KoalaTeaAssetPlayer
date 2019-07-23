//
//  AssetQueuePlayer.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/22/19.
//

import Foundation
import SwifterSwift

protocol AssetQueuePlayerDelegate {
    
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
    private lazy var assetPlayer = AssetPlayer()
    private lazy var playerView = assetPlayer.playerView

    private var assets: [Asset] = []
    private var currentAsset: Asset?
    private var currentItemIndex: Int? {
        guard let asset = currentAsset else { return nil }
        return assets.firstIndex(of: asset)
    }

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
            guard let currentIndex = self.currentItemIndex, currentIndex != assets.count else { return }
            moveToAsset(at: currentIndex + 1)
        case .previousAsset:
            guard let currentIndex = self.currentItemIndex, currentIndex != 0 else { return }
            moveToAsset(at: currentIndex - 1)
        case .moveToAsset(let index):
            moveToAsset(at: index)
        }
    }

    private func moveToAsset(at index: Int) {
        guard let asset = assets[safe: index] else { return }
        currentAsset = asset
        assetPlayer.perform(action: .setup(with: asset))
    }
}

extension AssetQueuePlayer: AssetPlayerDelegate {
    public func playerIsSetup(_ player: AssetPlayer) {

    }

    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {

    }

    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {

    }

    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {

    }

    public func playerPlaybackDidEnd(_ player: AssetPlayer) {
        perform(action: .nextAsset)
    }

    public func playerBufferedTimeDidChange(_ player: AssetPlayer) {

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
                                          currentAssetIndex: currentItemIndex,
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
