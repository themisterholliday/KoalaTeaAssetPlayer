//
//  ControlsView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/6/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import SwifterSwift

enum ControlsViewState: Equatable {
    case buffering
    case setup(viewModel: ControlsViewModel)
    case updating(viewModel: ControlsViewModel)
    case playing
    case paused
    case finished
}

struct ControlsViewModel: Equatable {
    let currentTime: Float
    let bufferedTime: Float
    let maxValueForSlider: Float
    let currentTimeText: String
    let timeLeftText: String
}

extension ControlsView {
    typealias Actions = (
        playButtonPressed: ViewAction<Void, Void>.Sync,
        pauseButtonPressed: ViewAction<Void, Void>.Sync,
        didStartDraggingSlider: ViewAction<Void, Void>.Sync,
        didDragToTime: ViewAction<Double, Void>.Sync
    )
}

public class ControlsView: UIView {
    private lazy var activityView: UIActivityIndicatorView = UIActivityIndicatorView(frame: .zero)
    private lazy var playButton = UIButton()
    private lazy var pauseButton = UIButton()
    private lazy var blackView = UIView()
    private lazy var playbackSliderView: AssetPlayerSliderView = {
        return AssetPlayerSliderView(actions: (
            sliderDragDidBegin: { _ in
                self.actions.didStartDraggingSlider(())
        },
            sliderDidMove: { time in

        },
            sliderDragDidEnd: { time in
                self.actions.didDragToTime(time)
        }
        ))
    }()

    private var isWaiting: Bool = false
    private var blackViewAlpha: CGFloat = 0.15
    private var fadingTime = 0.3

    private let actions: Actions

    required init(actions: Actions) {
        self.actions = actions
        super.init(frame: .zero)
        
        self.addSubview(blackView)

        self.blackView.frame = frame
        self.blackView.backgroundColor = .black
        self.blackView.alpha = self.blackViewAlpha
        self.blackView.isUserInteractionEnabled = false
        self.blackView.constrainEdgesToSuperView()

        self.setupButtons()
        self.setupActivityIndicator()
        self.setupPlaybackSlider()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with state: ControlsViewState) {
        if state != .buffering { activityView.stopAnimating() }
        switch state {
        case .buffering:
            activityView.startAnimating()
            playButton.isHidden = true
            pauseButton.isHidden = true
        case .paused:
            playButton.isHidden = false
            pauseButton.isHidden = true
        case .playing:
            pauseButton.isHidden = false
            playButton.isHidden = true
        case .updating(let viewModel):
            //        self.controlsView.playbackSliderView.updateTimeLabels(currentTimeText: properties.currentTimeText, timeLeftText: properties.timeLeftText)
            playbackSliderView.updateSlider(currentValue: viewModel.currentTime)
            playbackSliderView.updateBufferSlider(bufferValue: viewModel.bufferedTime)
        case .finished:
            break
        case .setup(let viewModel):
            playbackSliderView.updateSlider(maxValue: viewModel.maxValueForSlider)
            playbackSliderView.updateSlider(currentValue: viewModel.currentTime)
            playbackSliderView.updateBufferSlider(bufferValue: viewModel.bufferedTime)
        }
    }
    
    private func setupActivityIndicator() {
        activityView.style = .whiteLarge
        self.addSubview(activityView)
        activityView.constrainEdgesToSuperView()
    }

    private func setupPlaybackSlider() {
        self.addSubview(playbackSliderView)
        playbackSliderView.layout {
            $0.bottom == self.bottomAnchor
            $0.leading == self.leadingAnchor + 10
            $0.trailing == self.trailingAnchor - 10
            $0.height == 40
        }
    }

    private func setupButtons() {
        self.addSubview(playButton)
        self.addSubview(pauseButton)

        playButton.layout {
            $0.height == 40
            $0.width == 60
        }
        playButton.constrainCenterToSuperview()

        pauseButton.layout {
            $0.height == 40
            $0.width == 60
        }
        pauseButton.constrainCenterToSuperview()

        playButton.isHidden = true
        pauseButton.isHidden = false

        playButton.setTitle("Play", for: .normal)
        pauseButton.setTitle("Pause", for: .normal)

        playButton.addTarget(self, action: #selector(self.playButtonPressed), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(self.pauseButtonPressed), for: .touchUpInside)
    }

    // @TODO: do fade in
    private func fadeInThenSetWait() {
        guard !isWaiting else { return }
        self.fadeSelfIn()
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    private func waitAndFadeOut() {
        guard !isWaiting else { return }
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    private func fadeSelfIn() {
        UIView.animate(withDuration: fadingTime, animations: {
            self.blackView.alpha = self.blackViewAlpha
            self.playButton.alpha = 1
            self.pauseButton.alpha = 1
        })
        self.fadeInSliders()
        DispatchQueue.main.asyncAfter(deadline: .now() + fadingTime / 2) {
            self.playbackSliderView.showSliderThumbImage()
        }
    }
    
    private func fadeSelfOut() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.blackView.alpha = 0
            self.playButton.alpha = 0
            self.pauseButton.alpha = 0
        })
        self.fadeOutSliders()
        DispatchQueue.main.asyncAfter(deadline: .now() + fadingTime / 2) {
            self.playbackSliderView.hideSliderThumbImage()
        }
    }
    
    private func fadeInSliders() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.playbackSliderView.showSliders()
        })
    }
    
    private func fadeOutSliders() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.playbackSliderView.hideSliders()
        })
    }
}

extension ControlsView {
    @objc func playButtonPressed() {
        self.actions.playButtonPressed(())
    }
    
    @objc func pauseButtonPressed() {
        self.actions.pauseButtonPressed(())
    }
}
