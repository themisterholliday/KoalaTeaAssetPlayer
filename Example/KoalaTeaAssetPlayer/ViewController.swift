//
//  ViewController.swift
//  KoalaTeaAssetPlayer
//
//  Created by themisterholliday on 02/11/2019.
//  Copyright (c) 2019 themisterholliday. All rights reserved.
//

import UIKit
import AVFoundation
import KoalaTeaAssetPlayer

class ViewController: UIViewController {
    lazy var assetPlayer = AssetPlayer()
    lazy var remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlayer)
    lazy var asset: Asset = {
        return Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
    }()
    lazy var assetPlayerView: AssetPlayerView = AssetPlayerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assetPlayerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(assetPlayerView)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                assetPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                //            assetPlayerView.heightAnchor.constraint(equalTo: assetPlayerView.widthAnchor),
                assetPlayerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                assetPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                assetPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
        } else {
            // Fallback on earlier versions
        }

//        guard let url = URL(string:"https://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/adulting/adulting070919_s1e8.mp3") else {
//            assertionFailure()
//            return
//        }
//        let artworkURL = URL(string: "https://www.w3schools.com/w3images/fjords.jpg")
//        let asset = Asset(urlAsset: AVURLAsset(url: url), artworkURL: artworkURL)

        assetPlayerView.setupPlayback(asset: asset, options: [.shouldLoop])
    }
}

extension ViewController: AssetPlayerDelegate {
    func playerIsSetup(_ player: AssetPlayer) {
//        let properties = player.properties
//        print(properties.state)
//        print(properties.currentTime)
//        print(properties.durationText)
//        print(properties.timeLeftText)
//        print(properties.currentTimeText)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {}

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
//        print(player.properties.timeLeftText)
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {}

    func playerPlaybackDidEnd(_ player: AssetPlayer) {}

    func playerBufferedTimeDidChange(_ player: AssetPlayer) {}

    func playerDidFail(_ error: Error?) {}
}
