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
    lazy var playerView: PlayerView = self.assetPlayer.playerView
    lazy var asset: Asset = {
        return Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

//        self.setup()
    }

    func setup() {
        guard let url = URL(string:"http://traffic.libsyn.com/sedaily/PeriscopeData.mp3") else {
            assertionFailure()
            return
        }
        let artworkURL = URL(string: "https://www.w3schools.com/w3images/fjords.jpg")
        let asset = Asset(urlAsset: AVURLAsset(url: url), artworkURL: artworkURL)
        assetPlayer.perform(action: .setup(with: asset, options: []))
        assetPlayer.perform(action: .play)
        assetPlayer.delegate = self
        setupRemoteCommandManager()
    }

    func setupRemoteCommandManager() {
        // Always enable playback commands in MPRemoteCommandCenter.
        remoteCommandManager.activatePlaybackCommands(true)
        remoteCommandManager.toggleChangePlaybackPositionCommand(true)
        remoteCommandManager.toggleSkipBackwardCommand(true, interval: 30)
        remoteCommandManager.toggleSkipForwardCommand(true, interval: 30)
    }
}

extension ViewController: AssetPlayerDelegate {
    func playerIsSetup(_ player: AssetPlayer) {
        let properties = player.assetPlayerProperties
        print(properties.state)
        print(properties.currentTime)
        print(properties.durationText)
        print(properties.timeLeftText)
        print(properties.currentTimeText)
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {}

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        print(player.assetPlayerProperties.timeLeftText)
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {}

    func playerPlaybackDidEnd(_ player: AssetPlayer) {}

    func playerBufferedTimeDidChange(_ player: AssetPlayer) {}

    func playerDidFail(_ error: Error?) {}
}
