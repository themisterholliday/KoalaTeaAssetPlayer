//
//  AssetPlayerDelegateSpec.swift
//  KoalaTeaAssetPlayer_Example
//
//  Created by Craig Holliday on 7/23/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import SwifterSwift
import CoreMedia
import KoalaTeaAssetPlayer

class AssetPlayerDelegateSpec: QuickSpec {
    // Minimum time it should take to setup remote video
    let minimumSetupTime: Double = 8

    lazy var remoteFiveSecondAsset: Asset = Asset(url: URL(string: "https://s3-us-west-2.amazonaws.com/curago-binaries/test_assets/videos/SampleVideo_1280x720_1mb.mp4")!)
    lazy var localFiveSecondAsset: Asset = Asset(url: Bundle(for: AssetPlayerDelegateSpec.self).url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)

    override func spec() {
        describe("AssetPlayerDelegateSpec") {
            var assetPlayer: AssetPlayer!

            beforeEach {
                assetPlayer = AssetPlayer()
            }

            afterEach {
                assetPlayer = nil
                expect(assetPlayer).to(beNil())
            }

            describe("remote asset") {
                var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                beforeEach {
                    assetPlayer.perform(action: .setup(with: self.remoteFiveSecondAsset))
                    mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                }

                it("should fire setup delegate") {
                    expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: self.remoteFiveSecondAsset)))
                    expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.remoteFiveSecondAsset))
                }

                it("should fire delegate to set current time in seconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: self.minimumSetupTime + 2)
                }

                it("should fire delegate to set current time in milliseconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: self.minimumSetupTime + 2, pollInterval: 0.01)
                }

                it("should fire playback ended delegate") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: self.minimumSetupTime + 20)
                }

                it("should fire playerBufferTimeDidChange delegate") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.bufferTime).toEventually(beGreaterThanOrEqualTo(5.0), timeout: self.minimumSetupTime + 5)
                }
            }

            describe("local asset") {
                var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                beforeEach {
                    assetPlayer.perform(action: .setup(with: self.localFiveSecondAsset))
                    mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                }

                it("should fire setup delegate") {
                    expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.localFiveSecondAsset))
                }

                it("should fire delegate to set current time in seconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: 2)
                }

                it("should fire delegate to set current time in milliseconds") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 1, pollInterval: 0.01)
                }

                it("should fire playback ended delegate") {
                    assetPlayer.perform(action: .play)
                    expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: 7)
                }
            }
        }
    }
}


class MockAssetPlayerDelegate: AssetPlayerDelegate {
    var currentAsset: Asset?
    var currentTimeInSeconds: Double = 0
    var currentTimeInMilliSeconds: Double = 0
    var timeElapsedText: String = ""
    var durationText: String = ""
    var playbackEnded = false
    var playerIsLikelyToKeepUp = false
    var bufferTime: Double = 0

    init(assetPlayer: AssetPlayer) {
        assetPlayer.delegate = self
    }

    func playerIsSetup(_ player: AssetPlayer) {
        self.currentAsset = player.properties.asset
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {}

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        let properties = player.properties
        self.currentTimeInSeconds = properties.currentTime.rounded()
        self.timeElapsedText = properties.currentTimeText
        self.durationText = properties.durationText
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        let properties = player.properties
        self.currentTimeInMilliSeconds = round(100.0 * properties.currentTime) / 100.0
        self.timeElapsedText = properties.currentTimeText
        self.durationText = properties.durationText
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.playbackEnded = true
    }

    func playerBufferedTimeDidChange(_ player: AssetPlayer) {
        let properties = player.properties
        self.bufferTime = Double(properties.bufferedTime)
    }

    func playerDidFail(_ error: Error?) {}
}

