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
            },
            didDragEndAtTime: { [weak self] time in
                self?.assetPlayer.perform(action: .seekToTimeInSeconds(time: time))
                if self?.assetPlayer.properties.previousState == .playing {
                    self?.assetPlayer.perform(action: .play)
                }
            }
            ), options: self.controlsViewOptions)
    }()

    private let controlsViewOptions: [ControlsViewOption]
    
    public required init(controlsViewOptions: [ControlsViewOption]) {
        self.controlsViewOptions = controlsViewOptions
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
    
    public func setupPlayback(asset: Asset, remoteCommands: [RemoteCommand]) {
        assetPlayer.remoteCommands = remoteCommands
        assetPlayer.perform(action: .setup(with: asset))
        assetPlayer.perform(action: .play)
        assetPlayer.delegate = self
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
        case .idle:
            break
        }
    }
}

extension AssetPlayerView: AssetPlayerDelegate {
    public func playerIsSetup(_ properties: AssetPlayerProperties) {
        self.controlsView.configure(with: .setup(viewModel: properties.controlsViewModel))
    }

    public func playerPlaybackStateDidChange(_ properties: AssetPlayerProperties) {
        self.handleAssetPlaybackManagerStateChange(to: properties.state)
    }

    public func playerCurrentTimeDidChange(_ properties: AssetPlayerProperties) {}

    public func playerCurrentTimeDidChangeInMilliseconds(_ properties: AssetPlayerProperties) {
        self.controlsView.configure(with: .updating(viewModel: properties.controlsViewModel))
    }

    public func playerPlaybackDidEnd(_ properties: AssetPlayerProperties) {
        // @TODO: clear view
    }

    public func playerBufferedTimeDidChange(_ properties: AssetPlayerProperties) {
        self.controlsView.configure(with: .updating(viewModel: properties.controlsViewModel))
    }

    public func playerCurrentAssetDidChange(_ properties: AssetPlayerProperties) {
        self.controlsView.configure(with: .setup(viewModel: properties.controlsViewModel))
    }
}

fileprivate extension AssetPlayerProperties {
    var controlsViewModel: ControlsViewModel {
        return ControlsViewModel(currentTime: self.currentTime.float,
                                 bufferedTime: self.bufferedTime.float,
                                 maxValueForSlider: self.duration.float,
                                 currentTimeText: self.currentTimeText,
                                 timeLeftText: self.timeLeftText)
    }
}
