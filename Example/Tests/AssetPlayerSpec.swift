//
//  AssetPlayerSpec.swift
//  KoalaTeaAssetPlayer_Tests
//
//  Created by Craig Holliday on 7/7/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Nimble
import Quick
import SwifterSwift
import CoreMedia
import KoalaTeaAssetPlayer

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
                    assetPlayer = AssetPlayer()
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

                describe("actionable state changes") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: thirtySecondAsset, options: []))
                    }

                    it("should have SETUP state") {
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                    }

                    it("should have PLAYED state") {
                        assetPlayer.perform(action: .play)

                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.playing))
                        sleep(2)
                        expect(assetPlayer.properties.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                    }

                    it("should have PAUSED state") {
                        assetPlayer.perform(action: .pause)

                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.paused))
                    }

                    it("should mute player & un-mute") {
                        assetPlayer.perform(action: .changeIsMuted(to: true))
                        expect(assetPlayer.properties.isMuted).to(equal(true))

                        assetPlayer.perform(action: .changeIsMuted(to: false))
                        expect(assetPlayer.properties.isMuted).to(equal(false))
                    }

                    it("should change start time and end time for looping") {
                        assetPlayer.perform(action: .changeStartTimeForLoop(to: 5.0))
                        expect(assetPlayer.properties.startTimeForLoop).to(equal(5.0))

                        expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.idle), timeout: 20)

                        assetPlayer.perform(action: .changeEndTimeForLoop(to: 10.0))
                        expect(assetPlayer.properties.endTimeForLoop).to(equal(10.0))
                    }
                }

                describe("finished state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, options: []))
                    }

                    it("should have FINISHED state") {
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: 8)
                    }

                    it("should continue looping after finishing") {
                        assetPlayer.perform(action: AssetPlayerActions.changeShouldLoop(to: true))
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: 8)
                    }
                }

//                // @TODO: Test failure states with assets with protected content or non playable assets
//                describe("failed state test") {
//                    beforeEach {
//                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false, shouldLoop: false))
//                    }
//
//                    it("should have FAILED state") {
//                        let error = NSError(domain: "TEST", code: -1, userInfo: nil)
//                        assetPlayer.properties.state = .failed(error: error as Error)
//                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
//                    }
//                }

                describe("delegate methods") {
                    var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, options: []))
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
                        expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 1, pollInterval: 0.01)
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
                    assetPlayer = AssetPlayer()
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

                describe("actionable state changes") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: thirtySecondAsset, options: []))
                    }

                    it("should have SETUP state") {
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                    }

                    it("should have PLAYED state") {
                        assetPlayer.perform(action: .play)


                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.playing))
                        sleep(2)
                        expect(assetPlayer.properties.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)))
                    }

                    it("should have PAUSED state") {
                        assetPlayer.perform(action: .pause)

                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.paused))
                    }

                    it("should mute player & un-mute") {
                        assetPlayer.perform(action: .changeIsMuted(to: true))
                        expect(assetPlayer.properties.isMuted).to(equal(true))

                        assetPlayer.perform(action: .changeIsMuted(to: false))
                        expect(assetPlayer.properties.isMuted).to(equal(false))
                    }
                }

                describe("finished state test") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, options: []))
                    }

                    it("should have FINISHED state") {
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: minimumSetupTime + 20)
                    }

                    it("should continue looping after finishing") {
                        assetPlayer.perform(action: AssetPlayerActions.changeShouldLoop(to: true))
                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                        assetPlayer.perform(action: .play)
                        expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.playing), timeout: minimumSetupTime + 8)
                    }
                }

//                // @TODO: Test failure states with assets with protected content or non playable assets
//                describe("failed state test") {
//                    beforeEach {
//                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, startMuted: false, shouldLoop: false))
//                    }
//
//                    it("should have FAILED state") {
//                        let error = NSError(domain: "TEST", code: -1, userInfo: nil)
//                        assetPlayer.properties.state = .failed(error: error as Error)
//                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.failed(error: error)))
//                    }
//                }

                describe("delegate methods") {
                    var mockAssetPlayerDelegate: MockAssetPlayerDelegate!

                    beforeEach {
                        assetPlayer.perform(action: .setup(with: fiveSecondAsset, options: []))
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
                      
                    it("should fire playerBufferTimeDidChange delegate") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.bufferTime).toEventually(beGreaterThanOrEqualTo(5.0), timeout: minimumSetupTime + 5)
                    }
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

