//
//  QueuePlayerSpec.swift
//  KoalaTeaAssetPlayer_Example
//
//  Created by Craig Holliday on 7/21/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import KoalaTeaAssetPlayer

class QueuePlayerSpec: QuickSpec {
    lazy var asset1: Asset = Asset(url: Bundle(for: QueuePlayerSpec.self).url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
    lazy var asset2: Asset = Asset(url: Bundle(for: QueuePlayerSpec.self).url(forResource: "SampleVideo_1280x720_1mb.2", withExtension: "mp4")!)
    lazy var asset3: Asset = Asset(url: Bundle(for: QueuePlayerSpec.self).url(forResource: "SampleVideo_1280x720_1mb.3", withExtension: "mp4")!)
    lazy var assets: [Asset] = [asset1, asset2, asset3]

    override func spec() {
        describe("QueuePlayerSpec") {
            it("assets should not be the same") {
                expect(self.asset1).toNot(equal(self.asset2))
                expect(self.asset1).toNot(equal(self.asset3))
                expect(self.asset2).toNot(equal(self.asset3))
            }

            context("AssetQueuePlayer") {
                var assetPlayer: AssetQueuePlayer!

                beforeEach {
                    assetPlayer = AssetQueuePlayer()
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

                describe("perform action") {
                    beforeEach {
                        assetPlayer.perform(action: .setup(with: self.assets))
                    }

                    it("should have SETUP state") {
                        expect(assetPlayer.properties.assets).to(equal(self.assets))
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

                    it("should move to next asset") {
                        assetPlayer.perform(action: .nextAsset)

                        expect(assetPlayer.properties.currentAsset).to(equal(self.asset2))
                    }

                    it("should move to previous asset") {
                        assetPlayer.perform(action: .nextAsset)
                        assetPlayer.perform(action: .nextAsset)
                        assetPlayer.perform(action: .previousAsset)

                        expect(assetPlayer.properties.currentAsset).to(equal(self.asset2))
                    }

                    it("should not move past final asset") {
                        assetPlayer.perform(action: .nextAsset)
                        assetPlayer.perform(action: .nextAsset)
                        assetPlayer.perform(action: .nextAsset)
                        assetPlayer.perform(action: .nextAsset)

                        expect(assetPlayer.properties.currentAsset).to(equal(self.asset3))
                    }

                    it("should move to asset at index") {
                        let index = 2
                        assetPlayer.perform(action: .moveToAsset(at: index))

                        expect(assetPlayer.properties.currentAsset).to(equal(self.assets[index]))
                    }

                    it("should not move to asset at index greater than count") {
                        let index = 4
                        assetPlayer.perform(action: .moveToAsset(at: index))

                        expect(assetPlayer.properties.currentAsset).to(equal(self.asset1))
                    }

                    it("should automatically move to next asset") {
                        assetPlayer.perform(action: .play)

                        expect(assetPlayer.properties.currentAsset).toEventually(equal(self.asset2), timeout: 8)
                    }
                }
            }

            describe("QueuePlayer Delegate") {
                var assetPlayer: AssetQueuePlayer!

                beforeEach {
                    assetPlayer = AssetQueuePlayer()
                }

                afterEach {
                    assetPlayer = nil
                    expect(assetPlayer).to(beNil())
                }

//                describe("remote asset") {
//                    var mockAssetPlayerDelegate: MockAssetQueuePlayerDelegate!
//
//                    beforeEach {
//                        assetPlayer.perform(action: .setup(with: self.remoteFiveSecondAsset))
//                        mockAssetPlayerDelegate = MockAssetPlayerDelegate(assetPlayer: assetPlayer)
//                    }
//
//                    it("should fire setup delegate") {
//                        expect(assetPlayer.properties.state).to(equal(AssetPlayerPlaybackState.setup(asset: self.remoteFiveSecondAsset)))
//                        expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.remoteFiveSecondAsset))
//                    }
//
//                    it("should fire delegate to set current time in seconds") {
//                        assetPlayer.perform(action: .play)
//                        expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: self.minimumSetupTime + 2)
//                    }
//
//                    it("should fire delegate to set current time in milliseconds") {
//                        assetPlayer.perform(action: .play)
//                        expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: self.minimumSetupTime + 2, pollInterval: 0.01)
//                    }
//
//                    it("should fire playback ended delegate") {
//                        assetPlayer.perform(action: .play)
//                        expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: self.minimumSetupTime + 20)
//                    }
//
//                    it("should fire playerBufferTimeDidChange delegate") {
//                        assetPlayer.perform(action: .play)
//                        expect(mockAssetPlayerDelegate.bufferTime).toEventually(beGreaterThanOrEqualTo(5.0), timeout: self.minimumSetupTime + 5)
//                    }
//                }

                describe("local asset") {
                    var mockAssetPlayerDelegate: MockAssetQueuePlayerDelegate!

                    beforeEach {
                        assetPlayer.perform(action: .setup(with: self.assets))
                        mockAssetPlayerDelegate = MockAssetQueuePlayerDelegate(assetPlayer: assetPlayer)
                    }

                    it("should fire setup delegate") {
                        expect(mockAssetPlayerDelegate.allAssets).toEventually(equal(self.assets))
                    }

                    it("should fire delegate to set current time in seconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInSeconds).toEventually(equal(1), timeout: 2)
                    }

                    it("should fire delegate to set current time in milliseconds") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentTimeInMilliSeconds).toEventually(beGreaterThanOrEqualTo(0.50), timeout: 1, pollInterval: 0.01)
                    }

                    it("should fire asset change delegate") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.asset1), timeout: 3)
                        expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.asset2), timeout: 8)
                        expect(mockAssetPlayerDelegate.currentAsset).toEventually(equal(self.asset3), timeout: 18)
                    }

                    it("should fire playback ended delegate") {
                        assetPlayer.perform(action: .play)
                        expect(mockAssetPlayerDelegate.playbackEnded).toEventually(equal(true), timeout: 24)
                    }
                }
            }
        }
        
    }
}

class MockAssetQueuePlayerDelegate: AssetQueuePlayerDelegate {
    var allAssets: [Asset]?
    var currentAsset: Asset?
    var currentTimeInSeconds: Double = 0
    var currentTimeInMilliSeconds: Double = 0
    var timeElapsedText: String = ""
    var durationText: String = ""
    var playbackEnded = false
    var playerIsLikelyToKeepUp = false
    var bufferTime: Double = 0

    init(assetPlayer: AssetQueuePlayer) {
        assetPlayer.delegate = self
    }

    func playerIsSetup(_ properties: AssetQueuePlayerProperties) {
        self.allAssets = properties.assets
        self.currentAsset = properties.currentAsset
    }

    func playerDidChangeAsset(_ properties: AssetQueuePlayerProperties) {
        self.currentAsset = properties.currentAsset
    }

    func playerPlaybackStateDidChange(_ properties: AssetQueuePlayerProperties) {}

    func playerCurrentTimeDidChange(_ properties: AssetQueuePlayerProperties) {
        self.currentTimeInSeconds = properties.currentTime.rounded()
        self.timeElapsedText = properties.currentTimeText
        self.durationText = properties.durationText
    }

    func playerCurrentTimeDidChangeInMilliseconds(_ properties: AssetQueuePlayerProperties) {
        self.currentTimeInMilliSeconds = round(100.0 * properties.currentTime) / 100.0
        self.timeElapsedText = properties.currentTimeText
        self.durationText = properties.durationText
    }

    func playerPlaybackDidEnd(_ properties: AssetQueuePlayerProperties) {
        self.playbackEnded = true
    }

    func playerBufferedTimeDidChange(_ properties: AssetQueuePlayerProperties) {
        self.bufferTime = Double(properties.bufferedTime)
    }

    func playerDidFail(_ error: Error?) {}
}

