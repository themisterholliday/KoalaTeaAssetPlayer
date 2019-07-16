//
//  RemoteCommand.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 7/14/19.
//

import Foundation

/// Remote Commands to match the CommandCenter commands
///
/// - playback: Play or pause.
/// - next: Next asset in queue. !Not implemented yet
/// - previous: Previous asset in queue. !Not implemented yet
/// - changePlaybackPosition: Change playback position in media item.
/// - seekForwardAndBackward: Seek to time in media item.
/// - skipForward: Skip forward to a time in the media item by an interval
/// - skipBackward: Skip backward to a time in the media item by an interval
/// - like: Handle like from command center. !Not implemented yet
/// - dislike: Handle dislike from command center. !Not implemented yet
/// - bookmark: Handle bookmark from command center. !Not implemented yet
public enum RemoteCommand {
    case playback, next, previous, changePlaybackPosition, seekForwardAndBackward
    case skipForward(interval: Int)
    case skipBackward(interval: Int)
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
