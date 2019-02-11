//
//  VideoAsset.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

//import AVFoundation
//
//public class TimePoints {
//    public var startTime: CMTime
//    public var endTime: CMTime
//
//    init(startTime: CMTime, endTime: CMTime) {
//        self.startTime = startTime
//        self.endTime = endTime
//    }
//}
//
//extension TimePoints: Equatable {
//    public static func ==(lhs: TimePoints, rhs: TimePoints) -> Bool {
//        return lhs.startTime == rhs.startTime &&
//            lhs.endTime == rhs.endTime
//    }
//}
//
//public class VideoAsset {
//    // MARK: Types
//    static let nameKey = "AssetName"
//
//    // MARK: Properties
//
//    /// The name of the asset to present in the application.
//    public var assetName: String = ""
//
//    /// The `AVURLAsset` corresponding to an asset in either the application bundle or on the Internet.
//    public var urlAsset: AVURLAsset
//
//    public var timePoints: TimePoints
//
//    public var timeRange: CMTimeRange {
//        let duration = timePoints.endTime - timePoints.startTime
//        return CMTimeRangeMake(timePoints.startTime, duration)
//    }
//
//    public var frame: CGRect = .zero
//
//    public var framerate: Double? {
//        guard let track = self.urlAsset.getFirstVideoTrack() else {
//            assertionFailure("No first video track")
//            return nil
//        }
//
//        return Double(track.nominalFrameRate)
//    }
//
//    public init(assetName: String, url: URL) {
//        self.assetName = assetName
//        let avURLAsset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
//        self.urlAsset = avURLAsset
//
//        let timePoints = TimePoints(startTime: kCMTimeZero, endTime: self.urlAsset.duration)
//        self.timePoints = timePoints
//    }
//
//    public func setupFrameFrom(_ canvasFrame: CGRect) {
//        let size = CanvasFrameSizes._16x9(forSize: canvasFrame.size).rawValue
//        let origin = CGPoint(x: 0, y: canvasFrame.height / 2 - size.height / 2)
//        self.frame = CGRect(origin: origin, size: size)
//    }
//
//    // @TODO: What is a good timescale to use? Does the timescale need to depend on framerate?
//    public func setStartime(to time: Double) {
//        let cmTime = CMTimeMakeWithSeconds(time, 600)
//        self.timePoints.startTime = cmTime
//    }
//
//    public func setEndTime(to time: Double) {
//        let cmTime = CMTimeMakeWithSeconds(time, 600)
//
//        if cmTime > self.urlAsset.duration {
//            self.timePoints.endTime = self.urlAsset.duration
//            return
//        }
//
//        self.timePoints.endTime = cmTime
//    }
//}
//
//extension VideoAsset: Equatable {
//    public static func == (lhs: VideoAsset, rhs: VideoAsset) -> Bool {
//        return lhs.assetName == rhs.assetName &&
//            lhs.urlAsset == lhs.urlAsset &&
//            lhs.timePoints == rhs.timePoints
//    }
//}
