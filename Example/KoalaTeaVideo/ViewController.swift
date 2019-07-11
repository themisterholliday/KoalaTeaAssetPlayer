//
//  ViewController.swift
//  KoalaTeaVideo
//
//  Created by themisterholliday on 02/11/2019.
//  Copyright (c) 2019 themisterholliday. All rights reserved.
//

import UIKit
import AVFoundation
import KoalaTeaVideo

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

        self.setup()
    }

    func setup() {
        guard let url = URL(string:"http://traffic.libsyn.com/sedaily/PeriscopeData.mp3") else {
            assertionFailure()
            return
        }
        let artworkURL = URL(string: "https://www.w3schools.com/w3images/fjords.jpg")
        let asset = Asset(urlAsset: AVURLAsset(url: url), artworkURL: artworkURL)
        assetPlayer.perform(action: .setup(with: asset, startMuted: false, shouldLoop: true))
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
    func currentAssetDidChange(_ player: AssetPlayer) {
//        print("currentAssetDidChange")
    }

    func playerIsSetup(_ player: AssetPlayer) {
//        print("player is setup")
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
//        print("playerPlaybackStateDidChange")
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
//        print("playerCurrentTimeDidChange", player.currentTime)
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
//        print("playerCurrentTimeDidChangeInMilliseconds")
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
//        print("playerPlaybackDidEnd")
    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
//        print("playerBufferTimeDidChange")
    }
}
