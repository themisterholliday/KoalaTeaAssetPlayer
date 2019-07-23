# KoalaTea Asset Player

[![CI Status](https://img.shields.io/travis/themisterholliday/KoalaTeaAssetPlayer.svg?style=flat)](https://travis-ci.org/themisterholliday/KoalaTeaAssetPlayer)
[![Version](https://img.shields.io/cocoapods/v/KoalaTeaAssetPlayer.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAssetPlayer)
[![License](https://img.shields.io/cocoapods/l/KoalaTeaAssetPlayer.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAssetPlayer)
[![Platform](https://img.shields.io/cocoapods/p/KoalaTeaAssetPlayer.svg?style=flat)](https://cocoapods.org/pods/KoalaTeaAssetPlayer)

KoalaTea Asset Player is a wrapper around AVPlayer that provides an easy way to play video and audio in your app.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

```
iOS 10.3+
```

## Installation

KoalaTeaAssetPlayer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KoalaTeaAssetPlayer'
```

## Usage

Always have to import first

```swift
import KoalaTeaAssetPlayer
```

First you'll need to create an asset from a url. (File url or remote url)

```swift
let asset = Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
```

Now you have two options:

### Option 1: Using AssetPlayer directly

Here is how you can setup the AssetPlayer along with options you can use.

```swift
let assetPlayer = AssetPlayer()
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
// You can of course also just set either of the above to []

// Now use the `setup` action.
assetPlayer.perform(action: .setup(with: asset,
                                    options: options,
                                    remoteCommands: remoteCommands))
```

And performing any action is the same a setting up. Everything is just an 'action'.

```swift
assetPlayer.perform(action: .play)
assetPlayer.perform(action: .pause)
assetPlayer.perform(action: .skip(by: 30))
assetPlayer.perform(action: .skip(by: -15))
```

Now that you are setup and can perform actions, you'll need implement the delegate to get information you need about the player.

```swift
assetPlayer.delegate = self

extension ViewController: AssetPlayerDelegate {
    func playerIsSetup(_ properties: AssetPlayerProperties) {
        // Here the player is setup and you can set the max value for a time slider or anything else you need to show in your UI.
    }

    func playerPlaybackStateDidChange(_ properties: AssetPlayerProperties) {
        // Can handle state changes here if you need to display the state in a view
    }

    func playerCurrentTimeDidChange(_ properties: AssetPlayerProperties) {
        // This is fired every second while the player is playing.
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ properties: AssetPlayerProperties) {
        /*
            This is fired every millisecond while the player is playing.
            You should probably update your slider here to have a smooth animated slider
         */
    }

    func playerPlaybackDidEnd(_ properties: AssetPlayerProperties) {
        /*
            The playback did end for the player
            Dismiss the player, track some progress, whatever you need to do after the asset is done.
         */
    }

    func playerBufferedTimeDidChange(_ properties: AssetPlayerProperties) {
        /*
            This is for tracking the buffered time for the player.
            This is that little gray bar you see on YouTube or Vimeo that shows how much track time you have left before you see that buffering spinner
         */
    }

    func playerDidFail(_ error: Error?) {
        // 😱 Something has gone wrong and you should really present a nice error message and log this somewhere. Please don't just print the error.
    }
}
```

If you're using video you'll also have to setup a player view. I've tried to make that as easy as possible.

```swift
// Asset player has a player view for you to use
let playerView = assetPlayer.playerView

// Then you can layout the view however you want.
playerView.translatesAutoresizingMaskIntoConstraints = false
self.view.addSubview(playerView)
NSLayoutConstraint.activate([
    playerView.topAnchor.constraint(equalTo: view.topAnchor),
    playerView.heightAnchor.constraint(equalTo: playerView.widthAnchor, multiplier: 9/16),
    playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])
```

Then you should be good to go! 🎉🎉🎉

### Option 2: Using pre-made UI

I've created an `AssetPlayerView` as an example of the UI that can be made. I'll be continuing to work on UI and releasing more as updates come.

```swift
// There are a few options you can use to customize this view
let options: [ControlsViewOption] = [.bufferBackgroundColor(.lightGray),
                                             .bufferSliderColor(.darkGray),
                                             .playbackSliderColor(.red),
                                             .sliderCircleColor(.white)]
let assetPlayerView = AssetPlayerView(controlsViewOptions: options)

// With this view it only supports programmatic layout right now.
assetPlayerView.translatesAutoresizingMaskIntoConstraints = false
self.view.addSubview(assetPlayerView)
NSLayoutConstraint.activate([
    assetPlayerView.topAnchor.constraint(equalTo: view.topAnchor),
    assetPlayerView.heightAnchor.constraint(equalTo: assetPlayerView.widthAnchor, multiplier: 9/16),
    assetPlayerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    assetPlayerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    ])

// and we have a function to setup the asset player much like we do above.
assetPlayerView.setupPlayback(asset: asset, options: [.shouldLoop], remoteCommands: .all(skipInterval: 30))
```

## Contributing

Open an issue.

Open a PR.

or shoot me an email and I'll get back to you.

## Author

Craig Holliday

email: hello@craigholliday.net

twitter: https://twitter.com/TheMrHolliday

## License

KoalaTeaAssetPlayer is available under the MIT license. See the LICENSE file for more info.
