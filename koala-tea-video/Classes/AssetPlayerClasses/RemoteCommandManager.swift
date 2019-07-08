/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	`RemoteCommandManager` contains all the APIs calls to MPRemoteCommandCenter to enable and disable various remote control events.
 */

import Foundation
import MediaPlayer

public class RemoteCommandManager: NSObject {
    
    // MARK: Properties
    
    /// Reference of `MPRemoteCommandCenter` used to configure and setup remote control events in the application.
    fileprivate let remoteCommandCenter = MPRemoteCommandCenter.shared()
    
    /// The instance of `AssetPlaybackManager` to use for responding to remote command events.
    let assetPlayer: AssetPlayer
    
    // MARK: Initialization.
    
    public init(assetPlaybackManager: AssetPlayer) {
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
        toggleLikeCommand(false)
        toggleDislikeCommand(false)
        toggleBookmarkCommand(false)
    }
    
    // MARK: MPRemoteCommand Activation/Deactivation Methods
    
    #if os(tvOS)
    public func activateRemoteCommands(_ enable: Bool) {
        activatePlaybackCommands(enable)
        
        // To support Siri's "What did they say?" command you have to support the appropriate skip commands.  See the README for more information.
        toggleSkipForwardCommand(enable, interval: 15)
        toggleSkipBackwardCommand(enable, interval: 20)
    }
    #endif

    public func activatePlaybackCommands(_ enable: Bool) {
        if enable {
            remoteCommandCenter.playCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePlayCommandEvent(_:)))
            remoteCommandCenter.pauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePauseCommandEvent(_:)))
            remoteCommandCenter.stopCommand.addTarget(self, action: #selector(RemoteCommandManager.handleStopCommandEvent(_:)))
            remoteCommandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(RemoteCommandManager.handleTogglePlayPauseCommandEvent(_:)))
            
        }
        else {
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
    
    public func toggleNextTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.nextTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        else {
            remoteCommandCenter.nextTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleNextTrackCommandEvent(_:)))
        }
        
        remoteCommandCenter.nextTrackCommand.isEnabled = enable
    }
    
    public func togglePreviousTrackCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.previousTrackCommand.addTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.previousTrackCommand.removeTarget(self, action: #selector(RemoteCommandManager.handlePreviousTrackCommandEvent(event:)))
        }
        
        remoteCommandCenter.previousTrackCommand.isEnabled = enable
    }
    
    public func toggleSkipForwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipForwardCommand.isEnabled = enable
    }
    
    public func toggleSkipBackwardCommand(_ enable: Bool, interval: Int = 0) {
        if enable {
            remoteCommandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: interval)]
            remoteCommandCenter.skipBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.skipBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSkipBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.skipBackwardCommand.isEnabled = enable
    }
    
    public func toggleSeekForwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekForwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.seekForwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekForwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekForwardCommand.isEnabled = enable
    }
    
    public func toggleSeekBackwardCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.seekBackwardCommand.addTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.seekBackwardCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleSeekBackwardCommandEvent(event:)))
        }
        
        remoteCommandCenter.seekBackwardCommand.isEnabled = enable
    }
    
    public func toggleChangePlaybackPositionCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.changePlaybackPositionCommand.addTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleChangePlaybackPositionCommandEvent(event:)))
        }
        
        
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = enable
    }
    
    public func toggleLikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.likeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.likeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleLikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.likeCommand.isEnabled = enable
    }
    
    public func toggleDislikeCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.dislikeCommand.addTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.dislikeCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleDislikeCommandEvent(event:)))
        }
        
        remoteCommandCenter.dislikeCommand.isEnabled = enable
    }
    
    public func toggleBookmarkCommand(_ enable: Bool) {
        if enable {
            remoteCommandCenter.bookmarkCommand.addTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
        }
        else {
            remoteCommandCenter.bookmarkCommand.removeTarget(self, action: #selector(RemoteCommandManager.handleBookmarkCommandEvent(event:)))
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
    
    // MARK: Feedback Command Handlers
    @objc func handleLikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlayer.asset != nil {
            print("Did recieve likeCommand for \(String(describing: assetPlayer.asset?.assetName))")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    @objc func handleDislikeCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlayer.asset != nil {
            print("Did recieve dislikeCommand for \(String(describing: assetPlayer.asset?.assetName))")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
    
    @objc func handleBookmarkCommandEvent(event: MPFeedbackCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        if assetPlayer.asset != nil {
            print("Did recieve bookmarkCommand for \(String(describing: assetPlayer.asset?.assetName))")
            return .success
        }
        else {
            return .noSuchContent
        }
    }
}
