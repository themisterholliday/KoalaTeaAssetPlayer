//
//  PlayerView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/3/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import AVFoundation

public class AssetPlayerView: UIView {
    private lazy var assetPlayer = AssetPlayer()
    private lazy var remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlayer)
    
    private lazy var playerView: PlayerView = assetPlayer.playerView
    private lazy var controlsView: ControlsView = {
        return ControlsView(actions: (
            playButtonPressed: { [weak self] _ in
                self?.assetPlayer.perform(action: .play)
        },
            pauseButtonPressed: { [weak self] _ in
                self?.assetPlayer.perform(action: .pause)
        },
            didStartDraggingSlider: { [weak self] _ in
                self?.assetPlayer.perform(action: .pause)
        },
            didDragToTime: { [weak self] time in
                self?.assetPlayer.perform(action: .seekToTimeInSeconds(time: time))
                self?.assetPlayer.perform(action: .play)
        }
        ))
    }()
    
    public required init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.addSubview(playerView)
        self.addSubview(controlsView)

        playerView.constrainEdgesToSuperView()
        controlsView.constrainEdgesToSuperView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("player view deinit")
    }
    
    public func setupPlayback(asset: Asset, options: AssetPlayerSetupOptions) {
        assetPlayer.perform(action: .setup(with: asset, options: options))
        assetPlayer.perform(action: .play)
        assetPlayer.delegate = self
        setupRemoteCommandManager()
    }

    private func setupRemoteCommandManager() {
        // Always enable playback commands in MPRemoteCommandCenter.
        remoteCommandManager.activatePlaybackCommands(true)
        remoteCommandManager.toggleChangePlaybackPositionCommand(true)
        remoteCommandManager.toggleSkipBackwardCommand(true, interval: 30)
        remoteCommandManager.toggleSkipForwardCommand(true, interval: 30)
    }

    private func handleAssetPlaybackManagerStateChange(to state: AssetPlayerPlaybackState) {
        switch state {
        case .setup:
            break
        case .playing:
            controlsView.configure(with: .playing)
        case .paused:
            controlsView.configure(with: .paused)
        case .failed:
            break
        case .buffering:
            controlsView.configure(with: .buffering)
        case .finished:
            controlsView.configure(with: .finished)
        case .none:
            break
        }
    }
}

extension AssetPlayerView: AssetPlayerDelegate {
    public func playerIsSetup(_ player: AssetPlayer) {
        self.controlsView.configure(with: .setup(viewModel: player.properties.constrolsViewModel))
    }

    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        self.handleAssetPlaybackManagerStateChange(to: player.properties.state)
    }

    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {
    }

    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.controlsView.configure(with: .updating(viewModel: player.properties.constrolsViewModel))
    }

    public func playerPlaybackDidEnd(_ player: AssetPlayer) {}

    public func playerBufferedTimeDidChange(_ player: AssetPlayer) {
        self.controlsView.configure(with: .updating(viewModel: player.properties.constrolsViewModel))
    }
}

fileprivate extension AssetPlayerProperties {
    var constrolsViewModel: ControlsViewModel {
        return ControlsViewModel(currentTime: self.currentTime.float,
                                 bufferedTime: self.bufferedTime.float,
                                 maxValueForSlider: self.duration.float,
                                 currentTimeText: self.currentTimeText,
                                 timeLeftText: self.timeLeftText)
    }
}
