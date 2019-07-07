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
