//
//  PlayerView.swift
//  KoalaTeaPlayer
//
//  Created by Craig Holliday on 8/3/17.
//  Copyright © 2017 Koala Tea. All rights reserved.
//

import UIKit
import AVFoundation

public enum Direction {
    case up
    case left
    case none
}

public enum YTPlayerState {
    case landscapeLeft
    case landscapeRight
    case portrait
    case minimized
    case hidden
}

public protocol YTPlayerViewDelegate: NSObjectProtocol {
    func didMinimize()
    func didmaximize()
    func swipeToMinimize(translation: CGFloat, toState: YTPlayerState)
    func didEndedSwipe(toState: YTPlayerState)
}

public class YTPlayerView: UIView {
    public weak var delegate: YTPlayerViewDelegate?
    
    private let assetPlayer = AssetPlayer()
    private lazy var remoteCommandManager = RemoteCommandManager(assetPlaybackManager: assetPlayer)
    
    private let playerView: PlayerView
    private lazy var controlsView: ControlsView = {
        let controlsView = ControlsView()
        controlsView.delegate = self
        return controlsView
    }()

    private lazy var skipView: SkipView = {
        let skipView = SkipView()
        skipView.delegate = self
        return skipView
    }()

    private var direction = Direction.none
    private var state = YTPlayerState.portrait {
        didSet {
            self.animate(to: self.state)
        }
    }

    private var isRotated: Bool {
        return self.state == .landscapeLeft || self.state == .landscapeRight
    }
    private var rotatedConstraints: [NSLayoutConstraint] = []
    private var defaultConstraints: [NSLayoutConstraint] = []
    
    public required init() {
        self.playerView = assetPlayer.playerView
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.addSubview(playerView)
        self.addSubview(controlsView)
//        self.addSubview(skipView)

        defaultConstraints = playerView.constrainEdgesToSuperView() ?? []

        rotatedConstraints = playerView.returnedLayout {
            return [
                $0.height == self.widthAnchor,
                $0.width == self.heightAnchor,
                $0.centerXAnchor == self.centerXAnchor,
                $0.centerYAnchor == self.centerYAnchor,
            ]
        }
        rotatedConstraints.deactivateAll()

        controlsView.constrainEdgesToSuperView()
//        skipView.constrainEdgesToSuperView()
//        self.setupGestureRecognizer()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.state = .landscapeRight
        }
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

    fileprivate func handleAssetPlaybackManagerStateChange(to state: AssetPlayerPlaybackState) {
        switch state {
        case .setup:
            controlsView.disableAllButtons()
            controlsView.activityView.startAnimating()
            
            controlsView.playButton.isHidden = false
            controlsView.pauseButton.isHidden = true
        case .playing:
            controlsView.enableAllButtons()
            controlsView.activityView.stopAnimating()
            
            controlsView.playButton.isHidden = true
            controlsView.pauseButton.isHidden = false

            self.controlsView.waitAndFadeOut()
        case .paused:
            controlsView.activityView.stopAnimating()
            
            controlsView.playButton.isHidden = false
            controlsView.pauseButton.isHidden = true
        case .failed:
            break
        case .buffering:
            controlsView.activityView.startAnimating()
            
            controlsView.playButton.isHidden = true
            controlsView.pauseButton.isHidden = true
        case .finished:
            break
        case .none:
            break
        }
    }
    
    public func orientationChange() {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            self.state = .landscapeLeft
            break
        case .landscapeRight:
            self.state = .landscapeRight
            break
        case .portrait:
            self.state = .portrait
            break
        case .portraitUpsideDown:
            break
        case .unknown:
            break
        case .faceUp:
            break
        case .faceDown:
            break
        @unknown default:
            assertionFailure()
        }
    }
}

extension YTPlayerView: AssetPlayerDelegate {
    public func playerIsSetup(_ player: AssetPlayer) {
        self.controlsView.playbackSliderView.updateSlider(maxValue: player.properties.duration.float)
    }

    public func playerPlaybackStateDidChange(_ player: AssetPlayer) {
        self.handleAssetPlaybackManagerStateChange(to: player.properties.state)
    }

    public func playerCurrentTimeDidChange(_ player: AssetPlayer) {
        let properties = player.properties
        self.controlsView.playbackSliderView.updateTimeLabels(currentTimeText: properties.currentTimeText, timeLeftText: properties.timeLeftText)
    }

    public func playerCurrentTimeDidChangeInMilliseconds(_ player: AssetPlayer) {
        self.controlsView.playbackSliderView.updateSlider(currentValue: player.properties.currentTime.float)
    }

    public func playerPlaybackDidEnd(_ player: AssetPlayer) {}

    public func playerBufferedTimeDidChange(_ player: AssetPlayer) {
        self.controlsView.playbackSliderView.updateBufferSlider(bufferValue: player.properties.bufferedTime.float)
    }

    public func playerDidFail(_ error: Error?) {
        // @TODO: handle error
    }
}

extension YTPlayerView: ControlsViewDelegate {
    public func minimizeButtonPressed() {
//        self.minimize()
    }

    public func playButtonPressed() {
//        self.assetPlayer?.play()
    }

    public func pauseButtonPressed() {
//        self.assetPlayer?.pause()
    }

    public func playbackSliderValueChanged(value: Float) {
//        assetPlayer?.seekTo(interval: TimeInterval(value))
    }
    
    public func fullscreenButtonPressed() {
        switch self.isRotated {
        case true:
            self.state = .portrait
        case false:
            self.state = .landscapeLeft
        }
    }
    
    func handleStateChangeforControlView() {
        switch self.state {
        case .minimized:
            self.controlsView.fadeSelfOut()
            self.controlsView.fadeOutSliders()
        case .landscapeLeft, .landscapeRight:
            self.controlsView.setRotatedConstraints()
            self.controlsView.minimizeButton.isHidden = true
        case .portrait:
            self.controlsView.fadeSelfIn()
            self.controlsView.fadeInSliders()
            self.controlsView.setDefaultConstraints()
            self.controlsView.minimizeButton.isHidden = false
        case .hidden:
            break
        }
    }
}

extension YTPlayerView: SkipViewDelegate {
    public func skipForwardButtonPressed() {
        self.controlsView.fadeSelfOut()
        self.assetPlayer.perform(action: .skip(by: 10))
    }
    
    public func skipBackwardButtonPressed() {
        self.controlsView.fadeSelfOut()
        self.assetPlayer.perform(action: .skip(by: 10))
    }
    
    public func singleTap() {
        guard self.state != .minimized else {
            self.state = .portrait
            self.delegate?.didmaximize()
            return
        }

        switch controlsView.isVisible {
        case true:
            self.controlsView.fadeSelfOut()
            break
        case false:
            self.controlsView.fadeSelfIn()
            break
        }
    }
}

extension YTPlayerView: UIGestureRecognizerDelegate {
    func animate(to: YTPlayerState) {
//        guard let superView = self.superview else { return }

//        let originPoint = CGPoint(x: 0, y: 0)
//        self.layer.anchorPoint = originPoint

        switch self.state {
        case .minimized:
//            UIView.animate(withDuration: 0.3, animations: {
//
//                self.width = UIView.getValueScaledByScreenWidthFor(baseValue: 200)
//                self.height = self.width / (16/9)
//
//                let x = superView.frame.maxX - self.width - 10
//                let y = superView.frame.maxY - self.height - 10
//                self.layer.position = CGPoint(x: x, y: y)
//            })
            self.delegate?.didMinimize()
        case .landscapeLeft:
            self.controlsView.isRotated = true
//            UIView.animate(withDuration: 0.3, animations: {
//                // This is an EXACT order for left and right
//                // Transform > Change height and width > Change layer position
//                let newTransform = CGAffineTransform(rotationAngle: (CGFloat.pi / 2))
//                self.transform = newTransform
//
//                self.height = superView.width
//                self.width = superView.height
//
//                if #available(iOS 10.0, *) {
//                    self.height = superView.height
//                    self.width = superView.width
//                }
//
//                self.layer.position = CGPoint(x: superView.frame.maxX, y: 0)
//            })
        case .landscapeRight:
            self.controlsView.isRotated = true
            defaultConstraints.deactivateAll()
            rotatedConstraints.activateAll()
            UIView.animate(withDuration: 0.3, animations: {
//                // This is an EXACT order for left and right
//                // Transform > Change height and width > Change layer position
                let newTransform = CGAffineTransform(rotationAngle: -(CGFloat.pi / 2))
                self.playerView.transform = newTransform
//
//                self.height = superView.width
//                self.width = superView.height
//
//                if #available(iOS 10.0, *) {
//                    self.height = superView.height
//                    self.width = superView.width
//                }
//
//                self.layer.position = CGPoint(x: 0, y: superView.frame.maxY)
                self.layoutIfNeeded()
            })
        case .portrait:
            self.controlsView.isRotated = false
//            UIView.animate(withDuration: 0.3, animations: {
//                self.transform = CGAffineTransform.identity
//                self.layer.position = CGPoint(x: 0, y: 0)
//
//                self.height = superView.width / (16/9)
//                self.width = superView.width
//            })
            self.delegate?.didmaximize()
        case .hidden:
            break
        }

        self.handleStateChangeforControlView()
    }

    func minimize() {
        self.state = .minimized
        self.delegate?.didMinimize()
    }

    func setupGestureRecognizer() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.minimizeGesture(_:)))
        gestureRecognizer.delegate = self
        self.addGestureRecognizer(gestureRecognizer)
    }

    @objc func minimizeGesture(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            let velocity = sender.velocity(in: nil)
            if abs(velocity.x) < abs(velocity.y) {
                self.direction = .up
            } else {
                self.direction = .left
            }
        }
        var finalState = YTPlayerState.portrait
        switch self.state {
        case .portrait:
//            let factor = (abs(sender.translation(in: nil).y) / UIScreen.main.bounds.height)
//            self.changeValues(scaleFactor: factor)
//            self.delegate?.swipeToMinimize(translation: factor, toState: .minimized)
//            finalState = .minimized
            break
        case .minimized:
            if self.direction == .left {
                finalState = .hidden
                let factor: CGFloat = sender.translation(in: nil).x
                self.delegate?.swipeToMinimize(translation: factor, toState: .hidden)
            } else {
                finalState = .portrait
                let factor = 1 - (abs(sender.translation(in: nil).y) / UIScreen.main.bounds.height)
                self.changeValues(scaleFactor: factor)
                self.delegate?.swipeToMinimize(translation: factor, toState: .portrait)
            }
        default: break
        }
        if sender.state == .ended {
            self.state = finalState
            self.delegate?.didEndedSwipe(toState: self.state)
            if self.state == .hidden {
//                self.assetPlayer?.pause()
            }
        }
    }

    func changeValues(scaleFactor: CGFloat) {
//        self.controlsView?.minimizeButton.alpha = 1 - scaleFactor
////        self.alpha = 1 - scaleFactor
//        let scale = CGAffineTransform.init(scaleX: (1 - 0.5 * scaleFactor), y: (1 - 0.5 * scaleFactor))
//        let trasform = scale.concatenating(CGAffineTransform.init(translationX: -(self.bounds.width / 4 * scaleFactor), y: -(self.bounds.height / 4 * scaleFactor)))
//        self.transform = trasform
    }
}
