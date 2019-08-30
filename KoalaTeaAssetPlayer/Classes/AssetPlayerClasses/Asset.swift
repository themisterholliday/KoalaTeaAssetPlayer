/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 `Asset` is a wrapper struct around an `AVURLAsset` and its asset name.
 */

import Foundation
import AVFoundation

open class Asset {
    public let urlAsset: AVURLAsset
    public let assetName: String
    public let artworkURL: URL?
    public var isLocalFile: Bool {
        return urlAsset.url.isFileURL
    }
    public let playerItem: AVPlayerItem

    public init(url: URL, assetName: String? = nil, artworkURL: URL? = nil) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.urlAsset = asset
        self.assetName = assetName ?? ""
        self.artworkURL = artworkURL
        self.playerItem = AVPlayerItem(asset: asset)
    }

    public init(urlAsset: AVURLAsset, assetName: String? = nil, artworkURL: URL? = nil) {
        self.urlAsset = urlAsset
        self.assetName = assetName ?? ""
        self.artworkURL = artworkURL
        self.playerItem = AVPlayerItem(asset: urlAsset)
    }
}

public extension Asset {
    struct PublicConstants {
        public static let DefaultTimeScale: Int32 = 1000
    }

    static func adjustedTimeScaleDuration(for duration: CMTime) -> CMTime {
        guard duration.timescale != PublicConstants.DefaultTimeScale else {
            return duration
        }

        let newDuration = duration.convertScale(PublicConstants.DefaultTimeScale, method: .default)
        return newDuration
    }

    var naturalAssetSize: CGSize? {
        return self.urlAsset.getFirstVideoTrack()?.naturalSize
    }
}

extension Asset: Equatable {
    public static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.urlAsset.url == rhs.urlAsset.url &&
            lhs.urlAsset.metadata == rhs.urlAsset.metadata &&
            lhs.assetName == rhs.assetName &&
            lhs.artworkURL == rhs.artworkURL
    }
}
