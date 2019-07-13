//
//  ControlsView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/6/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import SwifterSwift

/// Player delegate protocol
public protocol ControlsViewDelegate: NSObjectProtocol {
    func playButtonPressed()
    func pauseButtonPressed()
    func playbackSliderValueChanged(value: Float)
    func fullscreenButtonPressed()
    func minimizeButtonPressed()
}

public class ControlsView: PassThroughView {
    open weak var delegate: ControlsViewDelegate?
    
    lazy var activityView: UIActivityIndicatorView = UIActivityIndicatorView(frame: .zero)
    var playButton = UIButton()
    var pauseButton = UIButton()
    var fullscreenButton = UIButton()
    var minimizeButton = UIButton()
    var blackView = UIView()
    var playbackSliderView: AssetPlayerSliderView = AssetPlayerSliderView(frame: .zero)

    var isVisible: Bool {
        get {
            return self.blackView.alpha > 0
        }
    }
    
    var isRotated: Bool = false {
        didSet {
            self.fullscreenButton.isSelected = isRotated
            switch isRotated {
            case true:
                self.setRotatedConstraints()
            case false:
                self.setDefaultConstraints()
                self.fadeInSliders()
            }

            switch self.isVisible {
            case true:
                self.fadeInSliders()
            case false:
                self.fadeOutSliders()
            }
        }
    }
    
    var isWaiting: Bool = false
    var assetPlaybackManager: AssetPlayer!
    var blackViewAlpha: CGFloat = 0.15

    var fadingTime = 0.3

    private var rotatedConstraints: [NSLayoutConstraint] = []
    private var defaultConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(blackView)

        self.blackView.frame = frame
        self.blackView.backgroundColor = .black
        self.blackView.alpha = self.blackViewAlpha
        self.blackView.isUserInteractionEnabled = false
        self.blackView.constrainEdgesToSuperView()

        self.setupButtons()
        self.setupActivityIndicator()
        self.addPlaybackSlider()

        
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupActivityIndicator() {
        activityView.style = .whiteLarge
        self.addSubview(activityView)
        activityView.constrainEdgesToSuperView()
    }
    
    func enableAllButtons() {
        self.playButton.isEnabled = true
        self.pauseButton.isEnabled = true
        self.fullscreenButton.isEnabled = true
        self.minimizeButton.isEnabled = true
    }
    
    func disableAllButtons() {
        self.playButton.isEnabled = false
        self.pauseButton.isEnabled = false
        self.fullscreenButton.isEnabled = false
        self.minimizeButton.isEnabled = false
    }
    
    func fadeInThenSetWait() {
        guard !isWaiting else { return }
        self.fadeSelfIn()
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard self.assetPlaybackManager.state == .playing else { return }
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    func waitAndFadeOut() {
        guard !isWaiting else { return }
        self.isWaiting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard self.assetPlaybackManager.state == .playing else { return }
            self.isWaiting = false
            self.fadeSelfOut()
        }
    }
    
    func fadeSelfIn() {
        UIView.animate(withDuration: fadingTime, animations: {
            self.blackView.alpha = self.blackViewAlpha
            self.playButton.alpha = 1
            self.pauseButton.alpha = 1
            self.fullscreenButton.alpha = 1
            self.minimizeButton.alpha = 1
            self.playbackSliderView.showLabels()
            
            if self.isRotated {
                self.playbackSliderView.showSliders()
            }
        })
        self.fadeInSliders()
        DispatchQueue.main.asyncAfter(deadline: .now() + fadingTime / 2) {
            self.playbackSliderView.showSliderThumbImage()
        }
    }
    
    func fadeSelfOut() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.blackView.alpha = 0
            self.playButton.alpha = 0
            self.pauseButton.alpha = 0
            self.fullscreenButton.alpha = 0
            self.minimizeButton.alpha = 0
            self.playbackSliderView.hideLabels()

            if self.isRotated {
                self.playbackSliderView.hideSliders()
            }
        })
        self.fadeOutSliders()
        DispatchQueue.main.asyncAfter(deadline: .now() + fadingTime / 2) {
            self.playbackSliderView.hideSliderThumbImage()
        }
    }
    
    func fadeInSliders() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            self.playbackSliderView.showSliders()
        })
    }
    
    func fadeOutSliders() {
        UIView.animate(withDuration: fadingTime / 2, animations: {
            if self.isRotated {
                self.playbackSliderView.hideSliders()
            }
        })
    }
 
    func addPlaybackSlider() {
        self.addSubview(playbackSliderView)
        playbackSliderView.delegate = self
        playbackSliderView.layout {
            $0.bottom == self.bottomAnchor
            $0.leading == self.leadingAnchor + 10
            $0.trailing == self.trailingAnchor - 10
            $0.height == 40
        }
    }
    
    func setDefaultConstraints() {
        self.playbackSliderView.setDefaultConstraints()
        
//        fullscreenButton.snp.makeConstraints { (make) in
//            make.right.equalToSuperview().inset(UIView.getValueScaledByScreenWidthFor(baseValue: 5))
//            make.bottom.equalToSuperview().inset(UIView.getValueScaledByScreenHeightFor(baseValue: 5))
//        }
//
//        minimizeButton.snp.makeConstraints { (make) in
//            make.top.equalToSuperview()
//            make.left.equalToSuperview()
//        }
    }
    
    func setRotatedConstraints() {
        self.playbackSliderView.setRotatedConstraints()
        
//        fullscreenButton.snp.makeConstraints { (make) in
//            make.right.equalToSuperview().inset(UIView.getValueScaledByScreenWidthFor(baseValue: 5))
//            make.bottom.equalToSuperview().inset(UIView.getValueScaledByScreenHeightFor(baseValue: 5))
//        }
    }
    
    func setupButtons() {
        self.addSubview(playButton)
        self.addSubview(pauseButton)
        self.addSubview(fullscreenButton)
        self.addSubview(minimizeButton)

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
//
//        let iconHeight = UIView.getValueScaledByScreenHeightFor(baseValue: 35)
//        let iconColor: UIColor = .white
//
//        playButton.setIcon(icon: .fontAwesome(.play), iconSize: iconHeight, color: iconColor, forState: .normal)
//        pauseButton.setIcon(icon: .fontAwesome(.pause), iconSize: iconHeight, color: iconColor, forState: .normal)
//
//        playButton.anchorCenterSuperview()
//        pauseButton.anchorCenterSuperview()
//
//        playButton.addTarget(self, action: #selector(self.playButtonPressed), for: .touchUpInside)
//        pauseButton.addTarget(self, action: #selector(self.pauseButtonPressed), for: .touchUpInside)
//
//        playButton.isHidden = true
//
//        fullscreenButton.setIcon(icon: .linearIcons(.frameExpand), iconSize: UIView.getValueScaledByScreenHeightFor(baseValue: 20), color: iconColor, forState: .normal)
//        fullscreenButton.setIcon(icon: .linearIcons(.frameContract), iconSize: UIView.getValueScaledByScreenHeightFor(baseValue: 20), color: iconColor, forState: .selected)
//        fullscreenButton.addTarget(self, action: #selector(fullscreenButtonPressed(_:)), for: .touchUpInside)
//
//        minimizeButton.setIcon(icon: .fontAwesome(.chevronDown), iconSize: UIView.getValueScaledByScreenHeightFor(baseValue: 20), color: iconColor, forState: .normal)
//        minimizeButton.addTarget(self, action: #selector(minimizeButtonPressed(_:)), for: .touchUpInside)
    }
    
    // MARK: - Play/Pause Functions
    @objc func playButtonPressed() {
        self.delegate?.playButtonPressed()
    }
    
    @objc func pauseButtonPressed() {
        self.delegate?.pauseButtonPressed()
    }
    
    @objc func fullscreenButtonPressed(_ sender: UIButton) {
        self.delegate?.fullscreenButtonPressed()
    }
    
    @objc func minimizeButtonPressed(_ sender: UIButton) {
        self.delegate?.minimizeButtonPressed()
    }
}

extension ControlsView: AssetPlayerSliderViewDelegate {
    func playbackSliderValueChanged(value: Float) {
        self.delegate?.playbackSliderValueChanged(value: value)
    }
}
