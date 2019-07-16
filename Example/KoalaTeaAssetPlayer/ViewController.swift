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
    lazy var asset: Asset = {
        return Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
    }()

    lazy var assetPlayer = AssetPlayer()
    lazy var playerView = assetPlayer.playerView

    lazy var assetPlayerView: AssetPlayerView = {
        return AssetPlayerView(controlsViewOptions: [
            .sliderCircleColor(.white),
            .playbackSliderColor(.red),
            ])
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // ⭐ Try one of these ⭐
//        assetPlayerExample()
//        assetPlayerViewExample()
    }

    /// Example of how to use Asset Player by itself
    func assetPlayerExample() {
        // You should definitely use the delegate. Check at the bottom 👇
        assetPlayer.delegate = self
        /*
            Player options.
            `shouldLoop` will loop asset indefinitely.
            `startMuted` will ...... start the asset muted
         */
        let options: [AssetPlayerSetupOption] = [.shouldLoop, .startMuted]

        // These are some remote commands if you want your media to be accessible on the lock screen
        let remoteCommands: [RemoteCommand] = [.playback,
                                               .changePlaybackPosition,
                                               .skipForward(interval: 15),
                                               .skipBackward(interval: 15)]

        // Easy setup and handling. Everything is just an action.
        assetPlayer.perform(action: .setup(with: asset,
                                           options: options,
                                           remoteCommands: remoteCommands))
        // Example actions you can perform
        assetPlayer.perform(action: .play)
        assetPlayer.perform(action: .pause)
        assetPlayer.perform(action: .skip(by: 30))
        assetPlayer.perform(action: .skip(by: -15))
    }

    /// Example player view implementing AssetPlayer
    func assetPlayerViewExample() {
        // Just setup the view
        assetPlayerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(assetPlayerView)
        if #available(iOS 11.0, *) {
            NSLayoutConstraint.activate([
                assetPlayerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                assetPlayerView.heightAnchor.constraint(equalTo: assetPlayerView.widthAnchor, multiplier: 9/16),
                assetPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                assetPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
        } else {
            // Fallback on earlier versions
        }

        // And setup the playback
        assetPlayerView.setupPlayback(asset: asset, options: [.shouldLoop], remoteCommands: .all(skipInterval: 30))
    }
}

extension ViewController: AssetPlayerDelegate {
    func playerIsSetup(_ player: AssetPlayer) {
        // Here the player is setup and you can set the max value for a time slider or anything else you need to show in your UI.
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        // Can handle state changes here if you need to display the state in a view
    }

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        // This is fired every second while the player is playing.
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        /*
            This is fired every millisecond while the player is playing.
            You should probably update your slider here to have a smooth animated slider
         */
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        /*
            The playback did end for the player
            Dismiss the player, track some progress, whatever you need to do after the asset is done.
         */
    }

    func playerBufferedTimeDidChange(_ player: AssetPlayer) {
        /*
            This is for tracking the buffered time for the player.
            This is that little gray bar you see on YouTube or Vimeo that shows how much track time you have left before you see that buffering spinner
         */
    }

    func playerDidFail(_ error: Error?) {
        // 😱 Something has gone wrong and you should really present a nice error message and log this somewhere. Please don't just print the error.
    }
}
