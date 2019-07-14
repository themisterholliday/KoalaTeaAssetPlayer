//
//  RemoteCommand.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/14/19.
//

import Foundation

public enum RemoteCommand {
    case playback
    case next
    case previous
    case changePlaybackPosition
    case skipForward(interval: Int)
    case skipBackward(interval: Int)
    case seekForwardAndBackward
    case like(localizedTitle: String?, localizedShortTitle: String?)
    case dislike(localizedTitle: String?, localizedShortTitle: String?)
    case bookmark(localizedTitle: String?, localizedShortTitle: String?)
}

public extension Sequence where Iterator.Element == RemoteCommand {
    static func all(skipInterval: Int) -> [RemoteCommand] {
        return [
            .playback,
            .next,
            .previous,
            .changePlaybackPosition,
            .skipForward(interval: skipInterval),
            .skipBackward(interval: skipInterval),
            .seekForwardAndBackward,
            .like(localizedTitle: nil, localizedShortTitle: nil),
            .dislike(localizedTitle: nil, localizedShortTitle: nil),
            .bookmark(localizedTitle: nil, localizedShortTitle: nil)
        ]
    }
}
