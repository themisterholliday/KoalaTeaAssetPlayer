//
//  ControlsView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/6/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import SwifterSwift

public enum ControlsViewOption {
    case bufferSliderColor(UIColor)
    case bufferBackgroundColor(UIColor)
    case playbackSliderColor(UIColor)
    case sliderCircleColor(UIColor)
}

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
        didDragToTime: ViewAction<Double, Void>.Sync,
        didDragEndAtTime: ViewAction<Double, Void>.Sync
    )
}

internal class ControlsView: UIView {
    private lazy var currentTimeTextLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .left
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        return label
    }()
    private lazy var timeLeftTextLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textAlignment = .right
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        return label
    }()
    private lazy var activityView: UIActivityIndicatorView = UIActivityIndicatorView(frame: .zero)

    private lazy var playButton = UIButton()
    private lazy var pauseButton = UIButton()

    private lazy var blackView = UIView()
    private lazy var viewTapView = UIView()

    private lazy var playbackSliderView: AssetPlayerSliderView = {
        return AssetPlayerSliderView(actions: (
            sliderDragDidBegin: { _ in
                self.actions.didStartDraggingSlider(())
        },
            sliderDidMove: { time in
                self.actions.didDragToTime(time)
        },
            sliderDragDidEnd: { time in
                self.actions.didDragEndAtTime(time)
        }
            ), options: self.options)
    }()

    private var forceStayOpen: Bool = false
    private var isWaiting: Bool = false
    private var isFadedOut: Bool = false
    private var fadeWaitTime: Double = 8.0
    private var blackViewAlpha: CGFloat = 0.15
    private var fadingTime = 0.5

    private let actions: Actions
    private let options: [ControlsViewOption]

    required init(actions: Actions, options: [ControlsViewOption]) {
        self.actions = actions
        self.options = options
        super.init(frame: .zero)

        self.addSubview(viewTapView)

        self.viewTapView.backgroundColor = .clear
        self.viewTapView.constrainEdgesToSuperView()

        self.addSubview(blackView)

        self.blackView.backgroundColor = .black
        self.blackView.alpha = blackViewAlpha
        self.blackView.isUserInteractionEnabled = false
        self.blackView.constrainEdgesToSuperView()

        setupButtons()
        setupActivityIndicator()
        setupPlaybackSlider()
        setupLabels()

        setupViewTappedGestureRecognizer()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func configure(with state: ControlsViewState) {
        if state != .buffering { activityView.stopAnimating() }
        switch state {
        case .buffering:
            forceStayOpen = true
            activityView.startAnimating()

            playButton.isHidden = true
            pauseButton.isHidden = true
            fadeSelfIn()
        case .paused:
            forceStayOpen = true

            playButton.isHidden = false
            pauseButton.isHidden = true
            fadeSelfIn()
        case .playing:
            forceStayOpen = false

            pauseButton.isHidden = false
            playButton.isHidden = true
            waitAndFadeOut()
        case .updating(let viewModel):
            playbackSliderView.updateSlider(currentValue: viewModel.currentTime)
            playbackSliderView.updateBufferSlider(bufferValue: viewModel.bufferedTime)
            currentTimeTextLabel.text = viewModel.currentTimeText
            timeLeftTextLabel.text = viewModel.timeLeftText

            guard !playbackSliderView.isTracking else { return }
            waitAndFadeOut()
        case .finished:
            forceStayOpen = true

            fadeSelfIn()
        case .setup(let viewModel):
            playbackSliderView.updateSlider(maxValue: viewModel.maxValueForSlider)
            playbackSliderView.updateSlider(currentValue: viewModel.currentTime)
            playbackSliderView.updateBufferSlider(bufferValue: viewModel.bufferedTime)
        }
    }

    private func setupLabels() {
        self.addSubview(currentTimeTextLabel)
        self.addSubview(timeLeftTextLabel)

        currentTimeTextLabel.layout {
            $0.leading == self.playbackSliderView.leadingAnchor
            $0.bottom == playbackSliderView.topAnchor + 4
        }

        timeLeftTextLabel.layout {
            $0.trailing == self.playbackSliderView.trailingAnchor
            $0.bottom == playbackSliderView.topAnchor + 4
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

    private func setupViewTappedGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped))
        tapGesture.cancelsTouchesInView = false
        viewTapView.addGestureRecognizer(tapGesture)
    }

    private func fadeInThenSetWait() {
        guard !isWaiting else { return }
        self.fadeSelfIn()
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeWaitTime) {
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    private func waitAndFadeOut() {
        guard !isWaiting, !isFadedOut else { return }
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeWaitTime) {
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    private func fadeSelfIn() {
        guard isFadedOut else { return }
        UIView.animate(withDuration: fadingTime, animations: {
            self.blackView.alpha = self.blackViewAlpha
            self.playButton.alpha = 1
            self.pauseButton.alpha = 1
            self.currentTimeTextLabel.alpha = 1
            self.timeLeftTextLabel.alpha = 1
            self.playbackSliderView.alpha = 1
        }, completion: { [weak self] _ in
            self?.isFadedOut = false
        })
    }
    
    private func fadeSelfOut() {
        guard !forceStayOpen, !playbackSliderView.isTracking, !isFadedOut else { return }
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.blackView.alpha = 0
            self.playButton.alpha = 0
            self.pauseButton.alpha = 0
            self.currentTimeTextLabel.alpha = 0
            self.timeLeftTextLabel.alpha = 0
            self.playbackSliderView.alpha = 0
        }, completion: { [weak self] _ in
            self?.isFadedOut = true
        })
    }
}

extension ControlsView {
    @objc private func viewTapped() {
        if self.isFadedOut {
            fadeSelfIn()
        } else {
            fadeSelfOut()
        }
    }

    @objc private func playButtonPressed() {
        self.actions.playButtonPressed(())
    }
    
    @objc private func pauseButtonPressed() {
        self.actions.pauseButtonPressed(())
    }
}
