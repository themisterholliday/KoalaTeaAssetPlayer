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
        fdescribe("QueuePlayerSpec") {
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

                    it("should move to asset at index") {
                        let index = 2
                        assetPlayer.perform(action: .moveToAsset(at: index))

                        expect(assetPlayer.properties.currentAsset).to(equal(self.assets[index]))
                    }

                    it("should automatically move to next asset") {
                        assetPlayer.perform(action: .play)

                        expect(assetPlayer.properties.currentAsset).toEventually(equal(self.asset2), timeout: 8)
                    }
                }
            }
        }
    }
}
