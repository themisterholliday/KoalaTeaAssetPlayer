//
//  ViewController.swift
//  koala-tea-video
//
//  Created by themisterholliday on 02/11/2019.
//  Copyright (c) 2019 themisterholliday. All rights reserved.
//

import UIKit
import AVFoundation
import koala_tea_video

class ViewController: UIViewController {
    lazy var assetPlayer = AssetPlayer(isPlayingLocalAsset: false, shouldLoop: false)
    lazy var remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlayer)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.setup()
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setup() {
        guard let url = URL(string:"https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3") else {
            assertionFailure()
            return
        }
        let artworkURL = URL(string: "https://www.w3schools.com/w3images/fjords.jpg")
        let asset = Asset(urlAsset: AVURLAsset(url: url), artworkURL: artworkURL)
        assetPlayer.perform(action: .setup(with: asset, startMuted: false))
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

    }

    func playerIsSetup(_ player: AssetPlayer) {

    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {

    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {

    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {

    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {

    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {

    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
        
    }
}
