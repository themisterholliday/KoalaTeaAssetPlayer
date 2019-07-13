//
//  YTSlider.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 12/4/17.
//

import Foundation

extension AssetPlayerSliderView {
    typealias Actions = (
        sliderDragDidBegin: Action<Void, Void>.Sync,
        sliderDidMove: Action<Double, Void>.Sync,
        sliderDragDidEnd: Action<Double, Void>.Sync
    )
}

class AssetPlayerSliderView: PassThroughView {
    private var bufferSlider: UISlider = UISlider(frame: .zero)
    private var bufferBackgroundSlider: UISlider = UISlider(frame: .zero)
    private var playbackSlider: UISlider = UISlider(frame: .zero)
    private var bufferSliderColor: UIColor = UIColor(hex: 0xb6b8b9)!
    private var bufferBackgroundColor: UIColor = UIColor(hex: 0xb6b8b9)!
    private var playbackSliderColor: UIColor = .red
    private var sliderCircleColor: UIColor = .black
    private var currentTimeLabel: UILabel = UILabel(frame: .zero)
    private var timeLeftLabel: UILabel = UILabel(frame: .zero)

    private lazy var smallCircle: UIImage? = {
        return UIImage(named: "SmallCircle", in: Bundle(for: AssetPlayerSliderView.self), compatibleWith: nil)?.filled(withColor: self.sliderCircleColor)
    }()
    private lazy var bigCircle: UIImage? = {
        return UIImage(named: "BigCircle", in: Bundle(for: AssetPlayerSliderView.self), compatibleWith: nil)?.filled(withColor: self.sliderCircleColor)
    }()

    private let actions: Actions

    required init(actions: Actions) {
        self.actions = actions
        super.init(frame: .zero)
        addPlaybackSlider()
        addBufferSlider()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        playbackSlider.minimumTrackTintColor = .white
        playbackSlider.maximumTrackTintColor = .clear
        playbackSlider.layer.cornerRadius = 0
        playbackSlider.addTarget(self, action: #selector(playbackSliderValueChanged(slider:event:)), for: .valueChanged)
        playbackSlider.isUserInteractionEnabled = true

        self.addSubview(playbackSlider)
        self.bringSubviewToFront(playbackSlider)

        playbackSlider.layout {
            $0.top == self.topAnchor
            $0.bottom == self.bottomAnchor
            $0.leading == self.leadingAnchor
            $0.trailing == self.trailingAnchor
        }

        showSliderThumbImage()
    }

    @objc private func playbackSliderValueChanged(slider: UISlider, event: UIEvent) {
        guard let touchEvent = event.allTouches?.first else { return }
        let timeInSeconds = slider.value
        switch touchEvent.phase {
        case .began:
            actions.sliderDragDidBegin(self, ())
        case .moved:
            actions.sliderDidMove(self, timeInSeconds.double)
        case .ended:
            actions.sliderDragDidEnd(self, timeInSeconds.double)
        default:
            break
        }
    }
}

extension AssetPlayerSliderView {
    func updateSlider(maxValue: Float) {
        // Update max only once
        guard playbackSlider.maximumValue <= 1.0 else { return }

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

    func showSliders() {
        self.playbackSlider.alpha = 1
        self.bufferSlider.alpha = 1
        self.bufferBackgroundSlider.alpha = 1
    }

    func hideSliders() {
        self.playbackSlider.alpha = 0
        self.bufferSlider.alpha = 0
        self.bufferBackgroundSlider.alpha = 0
    }

    func showSliderThumbImage() {
        playbackSlider.setThumbImage(smallCircle, for: .normal)
        playbackSlider.setThumbImage(bigCircle, for: .highlighted)
    }

    func hideSliderThumbImage() {
        playbackSlider.setThumbImage(UIImage(), for: .normal)
    }
}
