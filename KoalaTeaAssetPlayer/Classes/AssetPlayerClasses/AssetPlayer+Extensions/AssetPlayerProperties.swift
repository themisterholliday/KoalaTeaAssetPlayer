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
        let finalCurrentTime = currentTime.cleaned
        let finalBufferedTime = bufferedTime.cleaned
        let finalDuration = duration.cleaned
        return AssetPlayerProperties(
            asset: asset,
            isMuted: player.isMuted,
            currentTime: finalCurrentTime,
            bufferedTime: finalBufferedTime,
            currentTimeText: createTimeString(time: currentTime.rounded()),
            durationText: createTimeString(time: duration),
            timeLeftText: "-\(createTimeString(time: duration.rounded() - currentTime.rounded()))",
            duration: finalDuration,
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

private extension Double {
    var cleaned: Double {
        if self.isNaN || self.isInfinite {
            return 0
        } else {
            return self
        }
    }
}
