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
        return Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
    }()
    let asset1: Asset = Asset(url: Bundle.main.url(forResource: "SampleVideo_2.5", withExtension: "mp4")!)
    let longAsset: Asset = Asset(url: URL(string: "http://clips.vorwaerts-gmbh.de/VfE_html5.mp4")!, assetName: "Long Asset", artworkURL: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        // ⭐ Try one of these ⭐
//        assetPlayerExample()
//        assetPlayerViewExample()
    }

    /// Example of how to use Asset Player by itself
    lazy var assetPlayer = AssetPlayer()
    lazy var playerView = assetPlayer.playerView

    func assetPlayerExample() {
        // You should definitely use the delegate. Check at the bottom 👇
        assetPlayer.delegate = self

        // These are some remote commands if you want your media to be accessible on the lock screen
        let likeCommand: RemoteCommand = .like(localizedTitle: "Like", localizedShortTitle: "I really like this") { (success) in
            print("Did Like from Command Center")
        }
        let dislikeCommand: RemoteCommand = .dislike(localizedTitle: "Dislike", localizedShortTitle: "I really dislike this") { (success) in
            print("Did Dislike from Command Center")
        }
        let bookmarkCommand: RemoteCommand = .bookmark(localizedTitle: "Bookmark", localizedShortTitle: "Bookmark this please") { (success) in
            print("Did Bookmark from Command Center")
        }
        let remoteCommands: [RemoteCommand] = [.playback,
                                               .changePlaybackPosition,
                                               .skipForward(interval: 15),
                                               .skipBackward(interval: 15),
                                               likeCommand,
                                               dislikeCommand,
                                               bookmarkCommand]

        // Easy setup and handling. Everything is just an action.
        assetPlayer.perform(action: .setup(with: asset, remoteCommands: remoteCommands))

        // Example actions you can perform
        assetPlayer.perform(action: .skip(by: 30))
        assetPlayer.perform(action: .skip(by: -15))
        assetPlayer.perform(action: .pause)
        assetPlayer.perform(action: .play)

        // And if you're using view, setup the player view
        playerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9/16),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }

//    func assetPlayerQueueExample() {
//        assetPlayer.delegate = self
//
//        // Easy setup and handling. Everything is just an action.
//        assetPlayer.perform(action: .setup(with: [asset, longAsset, asset1], remoteCommands: []))
//
//        assetPlayer.perform(action: .play)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            self.assetPlayer.perform(action: .moveToAssetInQueue(index: self.assetPlayer.properties.currentAssetIndex + 1))
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
////                self.assetPlayer.perform(action: .seekToTimeInSeconds(time: 0))
////                self.assetPlayer.perform(action: .moveToAssetInQueue(index: self.assetPlayer.properties.currentAssetIndex - 1))
//            }
//        }
//
//        // And if you're using view, setup the player view
//        playerView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(playerView)
//        NSLayoutConstraint.activate([
//            playerView.topAnchor.constraint(equalTo: view.topAnchor),
//            playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9/16),
//            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//            ])
//    }

    /// Example player view implementing AssetPlayer
    lazy var assetPlayerView: AssetPlayerView = {
        return AssetPlayerView(controlsViewOptions: [
            .bufferBackgroundColor(.lightGray),
            .bufferSliderColor(.darkGray),
            .playbackSliderColor(.red),
            .sliderCircleColor(.white)
            ])
    }()

    func assetPlayerViewExample() {
        // Just setup the view
        assetPlayerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(assetPlayerView)
        NSLayoutConstraint.activate([
            assetPlayerView.topAnchor.constraint(equalTo: view.topAnchor),
            assetPlayerView.heightAnchor.constraint(equalTo: assetPlayerView.widthAnchor, multiplier: 9/16),
            assetPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            assetPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

        // And setup the playback
        assetPlayerView.setupPlayback(asset: asset, remoteCommands: .all(skipInterval: 30))
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

    public func playerCurrentAssetDidChange(_ player: AssetPlayer) {
        // Asset changed in the queue
    }
}
