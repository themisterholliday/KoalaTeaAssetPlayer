//
//  AssetPlayerRemoteAssetSpec.swift
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

class AssetPlayerRemoteAssetSpec: QuickSpec {
    lazy var thirtySecondAsset: Asset = Asset(url: Bundle(for: AssetPlayerSpec.self).url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
    lazy var fiveSecondAsset: Asset = Asset(url: Bundle(for: AssetPlayerSpec.self).url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)

    override func spec() {
        describe("AssetPlayerRemoteAssetSpec") {
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

            describe("perform action") {
                beforeEach {
                    assetPlayer.perform(action: .setup(with: thirtySecondAsset))
                }

                it("should have SETUP state") {
                    expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: thirtySecondAsset)))
                }

                it("should have PLAYED state") {
                    assetPlayer.perform(action: .play)


                    expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.playing))
                    expect(assetPlayer.properties.state).toEventuallyNot(equal(AssetPlayerPlaybackState.failed(error: nil)), timeout: 2)
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

            describe("finished state") {
                beforeEach {
                    assetPlayer.perform(action: .setup(with: fiveSecondAsset))
                }

                it("should have FINISHED state") {
                    expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: fiveSecondAsset)))
                    assetPlayer.perform(action: .play)
                    expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: minimumSetupTime + 20)
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
        }
    }
}
