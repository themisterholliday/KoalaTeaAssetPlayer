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
    override func spec() {
        let asset1: Asset = Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)

        let asset2: Asset = Asset(url: Bundle.main.url(forResource: "SampleVideo_1280x720_1mb", withExtension: "mp4")!)
        
        fdescribe("queue player") {
            var assetPlayer: AssetPlayer!

            beforeEach {
                assetPlayer = AssetPlayer()
            }

            afterEach {
                assetPlayer = nil
                expect(assetPlayer).to(beNil())
            }

            it("can do maths") {
//                assetPlayer.playerItems = [asset1, asset2]
//                assetPlayer.perform(action: .play)
//                expect(assetPlayer.playerItems.count) == 2
//                expect(assetPlayer.properties.currentTime).toEventually(equal(3), timeout: 10)
//                expect(assetPlayer.playerItems.count).toEventually(equal(1), timeout: 10)
//                expect(assetPlayer.properties.state).toEventually(equal(AssetPlayerPlaybackState.finished), timeout: 10)
            }
        }
    }
}
