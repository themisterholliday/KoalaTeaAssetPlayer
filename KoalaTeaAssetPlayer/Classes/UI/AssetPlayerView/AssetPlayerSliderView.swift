//
//  YTSlider.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 12/4/17.
//

import Foundation

extension AssetPlayerSliderView {
    typealias Actions = (
        sliderDragDidBegin: ViewAction<Void, Void>.Sync,
        sliderDidMove: ViewAction<Double, Void>.Sync,
        sliderDragDidEnd: ViewAction<Double, Void>.Sync
    )
}

internal class AssetPlayerSliderView: UIView {
    private var bufferSliderColor: UIColor = .darkGray
    private var bufferBackgroundColor: UIColor = .lightGray
    private var playbackSliderColor: UIColor = .black
    private var sliderCircleColor: UIColor = .white

    private var playbackSlider: UISlider = UISlider(frame: .zero)
    private var bufferSlider: UISlider = UISlider(frame: .zero)
    private var bufferBackgroundSlider: UISlider = UISlider(frame: .zero)
    private var currentTimeLabel: UILabel = UILabel(frame: .zero)
    private var timeLeftLabel: UILabel = UILabel(frame: .zero)

    private lazy var smallCircle: UIImage? = {
        return UIImage(named: "SmallCircle", in: Bundle(for: AssetPlayerSliderView.self), compatibleWith: nil)?.filled(withColor: self.sliderCircleColor)
    }()
    private lazy var bigCircle: UIImage? = {
        return UIImage(named: "BigCircle", in: Bundle(for: AssetPlayerSliderView.self), compatibleWith: nil)?.filled(withColor: self.sliderCircleColor)
    }()

    private let actions: Actions

    public var isTracking: Bool {
        return playbackSlider.isTracking
    }

    required init(actions: Actions, options: [ControlsViewOption]) {
        self.actions = actions
        super.init(frame: .zero)
        options.forEach({ handleControlsViewOption($0) })
        addPlaybackSlider()
        addBufferSlider()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleControlsViewOption(_ option: ControlsViewOption) {
        switch option {
        case .bufferSliderColor(let color):
            self.bufferSliderColor = color
        case .bufferBackgroundColor(let color):
            self.bufferBackgroundColor = color
        case .playbackSliderColor(let color):
            self.playbackSliderColor = color
        case .sliderCircleColor(let color):
            self.sliderCircleColor = color
        }
    }

    private func addBufferSlider() {
        bufferBackgroundSlider.minimumValue = 0
        bufferBackgroundSlider.isContinuous = true
        bufferBackgroundSlider.tintColor = self.bufferBackgroundColor
        bufferBackgroundSlider.layer.cornerRadius = 0
        bufferBackgroundSlider.alpha = 0.5
        bufferBackgroundSlider.isUserInteractionEnabled = false

        self.addSubview(bufferBackgroundSlider)

        bufferBackgroundSlider.constrainEdges(to: playbackSlider)

        bufferBackgroundSlider.setThumbImage(UIImage(), for: .normal)

        bufferSlider.minimumValue = 0
        bufferSlider.isContinuous = true
        bufferSlider.minimumTrackTintColor = self.bufferSliderColor
        bufferSlider.maximumTrackTintColor = .clear
        bufferSlider.layer.cornerRadius = 0
        bufferSlider.isUserInteractionEnabled = false

        self.addSubview(bufferSlider)

        bufferSlider.constrainEdges(to: playbackSlider)

        bufferSlider.setThumbImage(UIImage(), for: .normal)

        self.sendSubviewToBack(bufferSlider)
        self.sendSubviewToBack(bufferBackgroundSlider)
    }

    private func addPlaybackSlider() {
        playbackSlider.minimumValue = 0
        playbackSlider.isContinuous = true
        playbackSlider.minimumTrackTintColor = playbackSliderColor
        playbackSlider.maximumTrackTintColor = .clear
        playbackSlider.layer.cornerRadius = 0
        playbackSlider.addTarget(self, action: #selector(playbackSliderValueChanged(slider:event:)), for: .valueChanged)
        playbackSlider.isUserInteractionEnabled = true
        playbackSlider.setThumbImage(smallCircle, for: .normal)
        playbackSlider.setThumbImage(bigCircle, for: .highlighted)

        self.addSubview(playbackSlider)
        self.bringSubviewToFront(playbackSlider)

        playbackSlider.layout {
            $0.top == self.topAnchor
            $0.bottom == self.bottomAnchor
            $0.leading == self.leadingAnchor
            $0.trailing == self.trailingAnchor
        }
    }

    @objc private func playbackSliderValueChanged(slider: UISlider, event: UIEvent) {
        guard let touchEvent = event.allTouches?.first else { return }
        let timeInSeconds = slider.value
        switch touchEvent.phase {
        case .began:
            actions.sliderDragDidBegin(())
        case .moved:
            actions.sliderDidMove(timeInSeconds.double)
        case .ended:
            actions.sliderDragDidEnd(timeInSeconds.double)
        default:
            break
        }
    }
}

extension AssetPlayerSliderView {
    func updateSlider(maxValue: Float) {
        guard playbackSlider.maximumValue != maxValue else { return }

        if playbackSlider.isUserInteractionEnabled == false {
            playbackSlider.isUserInteractionEnabled = true
        }

        playbackSlider.maximumValue = maxValue
        bufferSlider.maximumValue = maxValue
    }

    func updateSlider(currentValue: Float) {
        guard !playbackSlider.isTracking else { return }
        playbackSlider.value = currentValue
    }

    func updateBufferSlider(bufferValue: Float) {
        bufferSlider.value = bufferValue
    }
}
