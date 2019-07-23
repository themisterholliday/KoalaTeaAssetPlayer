/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandManager` contains all the APIs calls to MPRemoteCommandCenter to enable and disable various remote control events.
 */

import Foundation
import MediaPlayer

internal class RemoteCommandManager: NSObject {
    
    // MARK: Properties
    
    /// Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    /// The instance of `AssetPlaybackManager` to use for responding to remote command events.
    let assetPlayer: AssetPlayer
    
    // MARK: Initialization.
    
    internal init(assetPlaybackManager: AssetPlayer) {
        self.assetPlayer = assetPlaybackManager
    }
    
    deinit {
        
        #if os(tvOS)
        activatePlaybackCommands(false)
        #endif
        
        activatePlaybackCommands(false)
        toggleNextTrackCommand(false)
        togglePreviousTrackCommand(false)
        toggleSkipForwardCommand(false)
        toggleSkipBackwardCommand(false)
        toggleSeekForwardCommand(false)
        toggleSeekBackwardCommand(false)
        toggleChangePlaybackPositionCommand(false)
        toggleLikeCommand(false, localizedTitle: nil, localizedShortTitle: nil, completion: nil)
        toggleDislikeCommand(false, localizedTitle: nil, localizedShortTitle: nil, completion: nil)
        toggleBookmarkCommand(false, localizedTitle: nil, localizedShortTitle: nil, completion: nil)
    }
    
    // MARK: MPRemoteCommand Activation/Deactivation Methods
    
    #if os(tvOS)
    internal func activateRemoteCommands(_ enable: Bool) {
        activatePlaybackCommands(enable)
        
        // To support Siri's "What did they say?" command you have to support the appropriate skip commands.  See the README for more information.
        toggleSkipForwardCommand(enable, interval: 15)
        toggleSkipBackwardCommand(enable, interval: 20)
    }
    #endif

    internal func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
        } else {
            remoteCommandCenter.playCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
        }
        remoteCommandCenter.playCommand.isEnabled = enable
        remoteCommandCenter.pauseCommand.isEnabled = enable
        remoteCommandCenter.stopCommand.isEnabled = enable
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = enable
    }
    
    internal func toggleNextTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        } else {
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
    }
    
    internal func togglePreviousTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        } else {
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    internal func toggleSkipForwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        } else {
            remoteCommandCenter.skipForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipForwardCommand.isEnabled = enable
    }
    
    internal func toggleSkipBackwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        } else {
            remoteCommandCenter.skipBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipBackwardCommand.isEnabled = enable
    }
    
    internal func toggleSeekForwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        } else {
            remoteCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekForwardCommand.isEnabled = enable
    }
    
    internal func toggleSeekBackwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        } else {
            remoteCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekBackwardCommand.isEnabled = enable
    }
    
    internal func toggleChangePlaybackPositionCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        } else {
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = enable
    }
    
    internal func toggleLikeCommand(_ enable: Bool,
                                    localizedTitle: String?,
                                    localizedShortTitle: String?,
                                    completion: ((Bool) -> Void)?) {
        remoteCommandCenter.likeCommand.localizedTitle = localizedTitle ?? ""
        remoteCommandCenter.likeCommand.localizedShortTitle = localizedShortTitle ?? ""

        if enable {
            remoteCommandCenter.likeCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let `self` = self else { return .commandFailed }
                if self.assetPlayer.asset != nil {
                    completion?(true)
                    return .success
                } else {
                    completion?(false)
                    return .noSuchContent
                }
            }
        } else {
            remoteCommandCenter.likeCommand.removeTarget(self)
        }
        
        remoteCommandCenter.likeCommand.isEnabled = enable
    }
    
    internal func toggleDislikeCommand(_ enable: Bool,
                                       localizedTitle: String?,
                                       localizedShortTitle: String?,
                                       completion: ((Bool) -> Void)?) {
        remoteCommandCenter.dislikeCommand.localizedTitle = localizedTitle ?? ""
        remoteCommandCenter.dislikeCommand.localizedShortTitle = localizedShortTitle ?? ""

        if enable {
            remoteCommandCenter.dislikeCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let `self` = self else { return .commandFailed }
                if self.assetPlayer.asset != nil {
                    completion?(true)
                    return .success
                } else {
                    completion?(false)
                    return .noSuchContent
                }
            }
        } else {
            remoteCommandCenter.dislikeCommand.removeTarget(self)
        }
        
        remoteCommandCenter.dislikeCommand.isEnabled = enable
    }
    
    internal func toggleBookmarkCommand(_ enable: Bool,
                                        localizedTitle: String?,
                                        localizedShortTitle: String?,
                                        completion: ((Bool) -> Void)?) {
        remoteCommandCenter.bookmarkCommand.localizedTitle = localizedTitle ?? ""
        remoteCommandCenter.bookmarkCommand.localizedShortTitle = localizedShortTitle ?? ""

        if enable {
            remoteCommandCenter.bookmarkCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
                guard let `self` = self else { return .commandFailed }
                if self.assetPlayer.asset != nil {
                    completion?(true)
                    return .success
                } else {
                    completion?(false)
                    return .noSuchContent
                }
            }
        } else {
            remoteCommandCenter.bookmarkCommand.removeTarget(self)
        }
        
        remoteCommandCenter.bookmarkCommand.isEnabled = enable
    }
    
    // MARK: MPRemoteCommand handler methods.
    
    // MARK: Playback Command Handlers
    @objc func handlePauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .pause)

        return .success
    }
    
    @objc func handlePlayCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .play)
        return .success
    }
    
    @objc func handleStopCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .stop)

        return .success
    }
    
    @objc func handleTogglePlayPauseCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .togglePlayPause)
        
        return .success
    }
    
    // MARK: Track Changing Command Handlers
    @objc func handleNextTrackCommandEvent(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        // @TODO: handle tracks
//        if assetPlaybackManager.asset != nil {
//            assetPlaybackManager.nextTrack()
//
//            return .success
//        }
//        else {
            return .noSuchContent
//        }
    }
    
    @objc func handlePreviousTrackCommandEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        // @TODO: handle tracks
//        if assetPlaybackManager.asset != nil {
//            assetPlaybackManager.previousTrack()
//
//            return .success
//        }
//        else {
            return .noSuchContent
//        }
    }
    
    // MARK: Skip Interval Command Handlers
    @objc func handleSkipForwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .skip(by: event.interval))

        return .success
    }
    
    @objc func handleSkipBackwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .skip(by: -(event.interval)))

        return .success
    }
    
    // MARK: Seek Command Handlers
    @objc func handleSeekForwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        switch event.type {
        case .beginSeeking: assetPlayer.perform(action: .beginFastForward)
        case .endSeeking: assetPlayer.perform(action: .endFastForward)
        @unknown default:
            break
        }
        return .success
    }
    
    @objc func handleSeekBackwardCommandEvent(event: MPSeekCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch event.type {
        case .beginSeeking: assetPlayer.perform(action: .beginRewind)
        case .endSeeking: assetPlayer.perform(action: .endRewind)
        @unknown default:
            break
        }
        return .success
    }
    
    @objc func handleChangePlaybackPositionCommandEvent(event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        assetPlayer.perform(action: .seekToTimeInSeconds(time: event.positionTime))
        
        return .success
    }

    internal func enableCommands(from commands: [RemoteCommand]) {
        commands.forEach({ setRemoteCommand($0, to: true) })
    }

    internal func disableCommands(from commands: [RemoteCommand]) {
        commands.forEach({ setRemoteCommand($0, to: false) })
    }

    private func setRemoteCommand(_ remoteCommand: RemoteCommand, to enabled: Bool) {
        switch remoteCommand {
        case .playback:
            activatePlaybackCommands(true)
        case .next:
            toggleNextTrackCommand(true)
        case .previous:
            togglePreviousTrackCommand(true)
        case .changePlaybackPosition:
            toggleChangePlaybackPositionCommand(true)
        case .skipForward(let interval):
            toggleSkipForwardCommand(true, interval: interval)
        case .skipBackward(let interval):
            toggleSkipBackwardCommand(true, interval: interval)
        case .seekForwardAndBackward:
            toggleSeekForwardCommand(true)
            toggleSeekBackwardCommand(true)
        case .like(let localizedTitle, let localizedShortTitle, let completion):
            toggleLikeCommand(true, localizedTitle: localizedTitle, localizedShortTitle: localizedShortTitle, completion: completion)
        case .dislike(let localizedTitle, let localizedShortTitle, let completion):
            toggleDislikeCommand(true, localizedTitle: localizedTitle, localizedShortTitle: localizedShortTitle, completion: completion)
        case .bookmark(let localizedTitle, let localizedShortTitle, let completion):
            toggleBookmarkCommand(true, localizedTitle: localizedTitle, localizedShortTitle: localizedShortTitle, completion: completion)
        }
    }
}
