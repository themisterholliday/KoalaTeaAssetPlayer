//
//  properties.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

public struct AssetPlayerProperties {
    public let asset: Asset?
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

public extension AssetPlayer {
    var properties: AssetPlayerProperties {
        return AssetPlayerProperties(
            asset: asset,
            isMuted: player.isMuted,
            currentTime: currentTime,
            bufferedTime: bufferedTime,
            currentTimeText: createTimeString(time: currentTime.rounded()),
            durationText: createTimeString(time: duration),
            timeLeftText: "-\(createTimeString(time: duration.rounded() - currentTime.rounded()))",
            duration: duration,
            rate: rate,
            state: state,
            previousState: previousState)
    }

    private func createTimeString(time: Double) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))

        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
}
