/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 `Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

public protocol AssetProtocol {
    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
    var urlAsset: AVURLAsset { get }
    var naturalAssetSize: CGSize? { get }
}

extension AssetProtocol {
    public var naturalAssetSize: CGSize? {
        return self.urlAsset.getFirstVideoTrack()?.naturalSize
    }
}

// MARK: Asset

public struct Asset: AssetProtocol {
    public var urlAsset: AVURLAsset

    public init(url: URL) {
        self.urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
    }

    public init(urlAsset: AVURLAsset) {
        self.urlAsset = urlAsset
    }
}

public extension Asset {
    struct PublicConstants {
        static let MaxCropDurationInSeconds = 5.0
        // @TODO: Look in to using a dynamic time scale
        static let DefaultTimeScale: Int32 = 1000
    }

    static func adjustedTimeScaleDuration(for duration: CMTime) -> CMTime {
        guard duration.timescale != PublicConstants.DefaultTimeScale else {
            return duration
        }

        let newDuration = duration.convertScale(PublicConstants.DefaultTimeScale, method: .default)
        return newDuration
    }
}

// MARK: Video Asset

public struct TimePoints {
    public let startTime: CMTime
    public let endTime: CMTime

    public var startTimeInSeconds: Double {
        return startTime.seconds
    }

    public var endTimeInSeconds: Double {
        return endTime.seconds
    }

    public func withChangingStartTime(to startTime: CMTime) -> TimePoints {
        return TimePoints(startTime: startTime, endTime: endTime)
    }

    public func withChangingEndTime(to endTime: CMTime) -> TimePoints {
        return TimePoints(startTime: startTime, endTime: endTime)
    }
}

extension TimePoints: Equatable {
    public static func == (lhs: TimePoints, rhs: TimePoints) -> Bool {
        return lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime
    }
}

public struct MediaAsset {
    public let urlAsset: AVURLAsset
    public let timePoints: TimePoints
    let startTime: CMTime

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(start: timePoints.startTime, duration: duration)
    }

    public var duration: Double {
        return durationInCMTime.seconds
    }

    public var durationInCMTime: CMTime {
        return timePoints.endTime - timePoints.startTime
    }

    // MARK: Init
    public init(urlAsset: AVURLAsset,
                timePoints: TimePoints,
                startTime: CMTime) {
        self.urlAsset = urlAsset
        self.timePoints = timePoints
        self.startTime = startTime
    }

    // MARK: Mutating Functions
    public func changeStartTime(to time: Double) -> MediaAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
        
        guard time > 0 else {
            return MediaAsset(urlAsset: self.urlAsset,
                              timePoints: self.timePoints.withChangingStartTime(to: CMTime.zero),
                              startTime: self.startTime)
        }
        
        return MediaAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingStartTime(to: cmTime),
                          startTime: self.startTime)
    }

    public func changeEndTime(to time: Double,
                              ignoreOffset: Bool = false) -> MediaAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

        let urlAssetDuration = Asset.adjustedTimeScaleDuration(for: urlAsset.duration)

        guard cmTime < urlAssetDuration else {
            var offset = CMTime(seconds: 0, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

            if !ignoreOffset {
                offset = cmTime - urlAssetDuration
            }

            let newStartTime = self.timePoints.startTime - offset

            let newVideoAsset = MediaAsset(urlAsset: self.urlAsset,
                                           timePoints: timePoints.withChangingEndTime(to: urlAssetDuration),
                                           startTime: self.startTime)
            // Adjust start time before returning
            return newVideoAsset.changeStartTime(to: newStartTime.seconds)
        }

        return MediaAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingEndTime(to: cmTime),
                          startTime: self.startTime)
    }
}

public struct VideoAsset: AssetProtocol {
    public let urlAsset: AVURLAsset
    /// Start and End times for export
    public let timePoints: TimePoints
    /// frame of video in relation to CanvasView to be exported
    public let frame: CGRect
    public let viewTransform: CGAffineTransform
    public let adjustedOrigin: CGPoint

    /// Framerate of Video
    public var framerate: Double? {
        guard let track = self.urlAsset.getFirstVideoTrack() else {
            assertionFailure("VideoAsset: " + "Failure getting first video track")
            return nil
        }

        return Double(track.nominalFrameRate)
    }

    public var timeRange: CMTimeRange {
        let duration = timePoints.endTime - timePoints.startTime
        return CMTimeRangeMake(start: timePoints.startTime, duration: duration)
    }

    public var duration: Double {
        return durationInCMTime.seconds
    }

    public var durationInCMTime: CMTime {
        return timePoints.endTime - timePoints.startTime
    }

    public var cropDurationInSeconds: Double {
        return self.duration > Asset.PublicConstants.MaxCropDurationInSeconds ? Asset.PublicConstants.MaxCropDurationInSeconds : self.duration
    }

    // MARK: Init
    public init(urlAsset: AVURLAsset,
                timePoints: TimePoints,
                frame: CGRect = .zero,
                viewTransform: CGAffineTransform = .identity,
                adjustedOrigin: CGPoint = .zero) {
        self.urlAsset = urlAsset
        self.timePoints = timePoints
        self.frame = frame
        self.viewTransform = viewTransform
        self.adjustedOrigin = adjustedOrigin
    }

    public init(url: URL) {
        let urlAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let timePoints = TimePoints(startTime: CMTime.zero, endTime: Asset.adjustedTimeScaleDuration(for: urlAsset.duration))
        self.init(urlAsset: urlAsset, timePoints: timePoints)
    }

    public init(urlAsset: AVURLAsset) {
        let timePoints = TimePoints(startTime: CMTime.zero, endTime: Asset.adjustedTimeScaleDuration(for: urlAsset.duration))
        self.init(urlAsset: urlAsset, timePoints: timePoints)
    }

    // MARK: Mutating Functions
    public func changeStartTime(to time: Double) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

        guard time > 0 else {
            return VideoAsset(urlAsset: self.urlAsset,
                              timePoints: self.timePoints.withChangingStartTime(to: CMTime.zero),
                              frame: self.frame)
        }

        return VideoAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingStartTime(to: cmTime),
                          frame: self.frame)
    }

    public func changeEndTime(to time: Double,
                              ignoreOffset: Bool = false) -> VideoAsset {
        let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

        let urlAssetDuration = Asset.adjustedTimeScaleDuration(for: urlAsset.duration)

        guard cmTime < urlAssetDuration else {
            var offset = CMTime(seconds: 0, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)

            if !ignoreOffset {
                offset = cmTime - urlAssetDuration
            }

            let newStartTime = self.timePoints.startTime - offset

            let newVideoAsset = VideoAsset(urlAsset: self.urlAsset,
                                           timePoints: timePoints.withChangingEndTime(to: urlAssetDuration),
                                           frame: self.frame)
            // Adjust start time before returning
            return newVideoAsset.changeStartTime(to: newStartTime.seconds)
        }

        return VideoAsset(urlAsset: self.urlAsset,
                          timePoints: self.timePoints.withChangingEndTime(to: cmTime),
                          frame: self.frame)
    }

    public func withChangingFrame(to frame: CGRect) -> VideoAsset {
        return VideoAsset(urlAsset: self.urlAsset, timePoints: self.timePoints, frame: frame)
    }

    public func withChangingViewTransform(to transform: CGAffineTransform) -> VideoAsset {
        return VideoAsset(urlAsset: self.urlAsset, timePoints: self.timePoints, frame: self.frame, viewTransform: transform)
    }

    public func withChangingAdjustedOrigin(to adjustedOrigin: CGPoint) -> VideoAsset {
        return VideoAsset(urlAsset: self.urlAsset, timePoints: self.timePoints, frame: self.frame, viewTransform: self.viewTransform, adjustedOrigin: adjustedOrigin)
    }
}



extension VideoAsset {
    public func generateClippedAssets(for clipLength: Int) -> [VideoAsset] {
        let ranges = VideoAsset.getTimeRanges(for: self.duration.rounded().int, clipLength: clipLength)
        return ranges.map { (range) -> VideoAsset in
            return self.changeStartTime(to: range.start.seconds).changeEndTime(to: range.end.seconds, ignoreOffset: true)
        }
    }

    private static func getTimeRanges(for duration: Int, clipLength: Int) -> [CMTimeRange] {
        // @TODO: figure out how to use doubles?
        let numbers = Array(1...duration)
        let result = numbers.chunked(into: clipLength)

        return result.compactMap { (value) -> CMTimeRange? in
            guard let first = value.first, let last = value.last else {
                return nil
            }
            let start = CMTime(seconds: first.double - 1.0, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
            let end = CMTime(seconds: last.double, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
            return CMTimeRange(start: start, end: end)
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
