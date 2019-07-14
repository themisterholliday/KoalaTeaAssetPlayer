//
//  DeinitTest.swift
//  KoalaTeaAssetPlayer_Tests
//
//  Created by Craig Holliday on 7/14/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest

class DeinitTest: XCTestCase {

    func testCleanup() {

        // Extend your class inline in order to add closure property `deinitCalled`,
        // which indicates when/if your class's deinit() gets called
        class ClassUnderTest: ViewController {
            var deinitCalled: (() -> Void)?
            deinit { deinitCalled?() }
        }

        // Set up async expectation, which causes the test to wait for `deinitCalled`
        // to be called
        let exp = expectation(description: "exp")

        // Initialize the class
        var instance: ClassUnderTest? = ClassUnderTest()

        // Set up up the `deinitCalled` closure, making the test succeed
        instance?.deinitCalled = {
            exp.fulfill()
        }

        // On a different queue, remove the instance from memory,
        // which should call `deinit`, in order to clean up resources.
        // If this doesn't cause `deinit` to be called, you probably have a
        // retain cycle
        DispatchQueue.global(qos: .background).async {
            instance = nil
        }

        // Wait for max. five seconds for the test to succeed, if not,
        // you may have a memory leak due to a retain cycle
        waitForExpectations(timeout: 5)
    }

}
