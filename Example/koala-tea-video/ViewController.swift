//
//  ViewController.swift
//  koala-tea-video
//
//  Created by themisterholliday on 02/11/2019.
//  Copyright (c) 2019 themisterholliday. All rights reserved.
//

import UIKit
import koala_tea_video

class ViewController: UIViewController {
    lazy var assetPlayer = AssetPlayer(isPlayingLocalAsset: false, shouldLoop: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        assetPlayer.perform(action: .play)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
