//
//  AssetPlayerSpec.swift
//  koala-tea-video_Tests
//
//  Created by Craig Holliday on 7/7/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import SwifterSwift
import CoreMedia
import koala_tea_video

class AssetPlayerSpec: QuickSpec {
    override func spec() {
        describe("asset player specs") {
            describe("asset player local asset tests") {
                var thirtySecondAsset: Asset {
                    return Asset(url: Bundle(for: AssetPlayerSpec.self).url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
                }

                var fiveSecondAsset: Asset {
                    return Asset(url: Bundle(for: AssetPlayerSpec.self).url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
                }

                var assetPlayer: AssetPlayer!

                beforeEach {
                    assetPlayer = AssetPlayer(isPlayingLocalAsset: true, shouldLoop: false)
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

                describe("actionable state changes") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: thirtySecondAsset, startMuted: false))
                    }

                    it("should have SETUP state") {
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                    }

                    it("should have PLAYED state") {
                        assetPlayer.perform(action: .play)

                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                        sleep(2)
                        expect(assetPlayer.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                    }

                    it("should have PAUSED state") {
                        assetPlayer.perform(action: .pause)

                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }

                    it("should mute player & un-mute") {
                        assetPlayer.perform(action: .changeIsMuted(to: true))
                        expect(assetPlayer.isMuted).to(equal(true))

                        assetPlayer.perform(action: .changeIsMuted(to: false))
                        expect(assetPlayer.isMuted).to(equal(false))
                    }

                    it("should change start time and end time for looping") {
                        assetPlayer.perform(action: .changeStartTimeForLoop(to: 5.0))
                        expect(assetPlayer.startTimeForLoop).to(equal(5.0))

                        expect(assetPlayer.player.currentItem?.status).toEventually(equal(.readyToPlay), timeout: 20)

                        assetPlayer.perform(action: .changeEndTimeForLoop(to: 10.0))
                        expect(assetPlayer.endTimeForLoop).to(equal(10.0))
                    }
                }

                describe("finished state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                    }

                    it("should have FINISHED state") {
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: 8)
                    }

                    it("should continue looping after finishing") {
                        assetPlayer.perform(action: AssetPlayerActions.changeShouldLoop(to: true))
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: 8)
                    }
                }

                // @TODO: Test failure states with assets with protected content or non playable assets
                describe("failed state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                    }

                    it("should have FAILED state") {
                        let error = NSError(domain: "TEST", code: -1, userInfo: nil)
                        assetPlayer.state = .failed(error: error as Error)
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
                    }
                }

                describe("delegate methods") {
                    var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                        mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                    }

                    it("should fire setup delegate") {
                        expect(mockAssetPlayerDelegate.currentAsset?.urlAsset.url).toEventually(equal(fiveSecondAsset.urlAsset.url))
                    }

                    it("should fire delegate to set current time in seconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: 2)
                    }

                    it("should fire delegate to set current time in milliseconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(equal(0.50), timeout: 1, pollInterval: 0.01)
                    }

                    it("should fire playback ended delegate") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: 7)
                    }
                }
            }

            describe("asset player remote asset tests") {
                // Minimum time it should take to setup remote video
                let minimumSetupTime: Double = 8

                var thirtySecondAsset: Asset {
                    return Asset(url: URL(string: "https://s3-us-west-2.amazonaws.com/curago-binaries/test_assets/videos/SampleVideo_1280x720_5mb.mp4")!)
                }

                var fiveSecondAsset: Asset {
                    return Asset(url: URL(string: "https://s3-us-west-2.amazonaws.com/curago-binaries/test_assets/videos/SampleVideo_1280x720_1mb.mp4")!)
                }

                var assetPlayer: AssetPlayer!

                beforeEach {
                    // @TODO: fix buffering
                    assetPlayer = AssetPlayer(isPlayingLocalAsset: true, shouldLoop: false)
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

                describe("actionable state changes") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: thirtySecondAsset, startMuted: false))
                    }

                    it("should have SETUP state") {
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                    }

                    it("should have PLAYED state") {
                        assetPlayer.perform(action: .play)


                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.playing))
                        sleep(2)
                        expect(assetPlayer.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                    }

                    it("should have PAUSED state") {
                        assetPlayer.perform(action: .pause)

                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.paused))
                    }

                    it("should mute player & un-mute") {
                        assetPlayer.perform(action: .changeIsMuted(to: true))
                        expect(assetPlayer.isMuted).to(equal(true))

                        assetPlayer.perform(action: .changeIsMuted(to: false))
                        expect(assetPlayer.isMuted).to(equal(false))
                    }
                }

                describe("finished state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                    }

                    it("should have FINISHED state") {
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: minimumSetupTime + 20)
                    }

                    it("should continue looping after finishing") {
                        assetPlayer.perform(action: AssetPlayerActions.changeShouldLoop(to: true))
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: minimumSetupTime + 8)
                    }
                }

                // @TODO: Test failure states with assets with protected content or non playable assets
                describe("failed state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                    }

                    it("should have FAILED state") {
                        let error = NSError(domain: "TEST", code: -1, userInfo: nil)
                        assetPlayer.state = .failed(error: error as Error)
                        expect(assetPlayer.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
                    }
                }

                describe("delegate methods") {
                    var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false))
                        mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
                    }

                    it("should fire setup delegate") {
                        expect(mockAssetPlayerDelegate.currentAsset?.urlAsset.url).toEventually(equal(fiveSecondAsset.urlAsset.url))
                    }

                    it("should fire delegate to set current time in seconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: minimumSetupTime + 2)
                    }

                    it("should fire delegate to set current time in milliseconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: minimumSetupTime + 2, pollInterval: 0.01)
                    }

                    it("should fire playback ended delegate") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: minimumSetupTime + 20)
                    }

                    // @TODO: put these back when we fix buffering
                    //                    it("should fire playerIsLikelyToKeepUp delegate") {
                    //                        assetPlayer.perform(action: .play)
                    //                        expect(mockAssetPlayerDelegate.playerIsLikelyToKeepUp).toEventually(equal(true), timeout: minimumSetupTime)
                    //                    }

                    //                    it("should fire playerBufferTimeDidChange delegate") {
                    //                        assetPlayer.perform(action: .play)
                    //                        expect(mockAssetPlayerDelegate.bufferTime).toEventually(beGreaterThanOrEqualTo(5.0), timeout: minimumSetupTime + 5)
                    //                    }
                }
            }
        }
    }
}

class MockAssetPlayerDelegate: AssetPlayerDelegate {
    var currentAsset: AssetProtocol?
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

    func currentAssetDidChange(_ player: AssetPlayer) {
        self.currentAsset = player.asset
    }

    func playerIsSetup(_ player: AssetPlayer) {
        self.currentAsset = player.asset
    }

    func playerPlaybackStateDidChange(_ player: AssetPlayer) {}

    func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        self.currentTimeInSeconds = player.currentTime.rounded()
        self.timeElapsedText = player.timeElapsedText
        self.durationText = player.durationText
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.currentTimeInMilliSeconds = round(100.0 * player.currentTime) / 100.0
        self.timeElapsedText = player.timeElapsedText
        self.durationText = player.durationText
    }

    func playerPlaybackDidEnd(_ player: AssetPlayer) {
        self.playbackEnded = true
    }

    func playerIsLikelyToKeepUp(_ player: AssetPlayer) {
        playerIsLikelyToKeepUp = true
    }

    func playerBufferTimeDidChange(_ player: AssetPlayer) {
        self.bufferTime = Double(player.bufferedTime)
    }
}

