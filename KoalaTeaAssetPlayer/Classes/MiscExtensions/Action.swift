//
//  Action.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/13/19.
//

internal enum ViewControllerAction<I, O> {
    typealias Sync = (UIViewController, I) -> O
    typealias Async = (UIViewController, I, @escaping (O) -> Void) -> Void
}

internal enum ViewAction<I, O> {
    typealias Sync = (I) -> O
    typealias Async = (I, @escaping (O) -> Void) -> Void
}
