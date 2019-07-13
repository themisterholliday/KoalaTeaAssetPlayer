//
//  Action.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/13/19.
//

internal enum Action<I, O> {
    typealias Sync = (NSObject, I) -> O
    typealias Async = (NSObject, I, @escaping (O) -> Void) -> Void
}
