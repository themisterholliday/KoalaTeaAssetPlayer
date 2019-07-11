//
//  AssetPlayer+MPNowPlayingInforCenter.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/11/19.
//

import MediaPlayer

public extension AssetPlayer {
    func updateGeneralMetadata() {
        guard self.player.currentItem != nil, let urlAsset = self.player.currentItem?.asset else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let title = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? asset?.assetName
        let album = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyAlbumName, keySpace: AVMetadataKeySpace.common).first?.value as? String ?? ""
        var artworkData = AVMetadataItem.metadataItems(from: urlAsset.commonMetadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common).first?.value as? Data ?? Data()
        if let url = asset?.artworkURL {
            if let data = try? Data(contentsOf: url) {
                artworkData = data
            }
        }

        let image = UIImage(data: artworkData) ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
            return image
        })

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = album
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func updatePlaybackMetadata() {
        guard self.player.currentItem != nil else {
            nowPlayingInfoCenter.nowPlayingInfo = nil

            return
        }

        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(self.player.currentItem?.currentTime() ?? .zero)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = self.player.rate

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
