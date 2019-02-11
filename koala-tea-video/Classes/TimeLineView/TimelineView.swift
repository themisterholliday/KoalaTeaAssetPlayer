//
//  TimelineView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/11/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit

public protocol TimelineViewDelegate: class {
    func isScrolling()
    func endScrolling()
    func didChangeStartAndEndTime(to time: (startTime: Double, endTime: Double))
}

public class TimelineView: UIView {
    public weak var delegate: TimelineViewDelegate?

    // @TODO: Fix optionality
    private var videoFramesScrollingView: VideoFramesScrollingView!
    private var cropView: TimelineCropView?
    public var cropViewFrame: CGRect? {
        return self.cropView?.frame
    }

    private var playbackLineIndicator: PlaybackLineIndicatorView?
    private var timeLineStartingPoint: CGFloat = 0

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        self.backgroundColor = Constants.TimelineBackgroundColor
    }

    private var cropDurationInSeconds: Double = 0.0

    /// Setup view. Should be done after width and height is set if using auto layout
    public func setupTimeline(with video: VideoAsset) {
        self.cropDurationInSeconds = video.cropDurationInSeconds

        let widthPerSecond = Double(self.width) / (320 / 43)

        // Crop View
        let cropView = TimelineCropView(widthPerSecond: widthPerSecond,
                                maxVideoDurationInSeconds: self.cropDurationInSeconds,
                                height: self.height,
                                center: CGPoint(x: self.bounds.midX, y: self.bounds.midY))
        cropView.changeBorderColor(to: UIColor(hexString: "#33E5E9") ?? .white)
        self.cropView = cropView

        let leftRightScrollViewInset = cropView.frame.minX + cropView.layer.borderWidth
        timeLineStartingPoint = leftRightScrollViewInset

        // Layer Scroller View
        let frame = CGRect(x: 0, y: 0, width: self.width, height: self.height)

        let framerate = video.framerate ?? 0
        // Add this duration buffer for videos that are extremely close to the 5 second mark but just a little over
        let durationBuffer = 0.01
        let videoDurationGreaterThanCropTime = video.duration > VideoAsset.PublicConstants.MaxCropDurationInSeconds
        let duration = videoDurationGreaterThanCropTime ? video.duration - durationBuffer : video.duration
        videoFramesScrollingView = VideoFramesScrollingView(frame: frame,
                                                            videoAsset: video.urlAsset,
                                                            framerate: framerate,
                                                            videoDuration: duration,
                                                            videoFrameWidth: CGFloat(widthPerSecond),
                                                            leftRightScrollViewInset: leftRightScrollViewInset)
        videoFramesScrollingView.delegate = self

        // PlaybackLineIndicator
        let playbackLineIndicatorWidth: CGFloat = 24
        let playbackLineIndicatorFrame = CGRect(x: self.timeLineStartingPoint - (playbackLineIndicatorWidth / 2), y: 0, width: playbackLineIndicatorWidth, height: self.height)
        let playbackLineIndicator = PlaybackLineIndicatorView(frame: playbackLineIndicatorFrame)
        self.playbackLineIndicator = playbackLineIndicator

        self.addSubview(videoFramesScrollingView)
        self.addSubview(cropView)
        self.addSubview(playbackLineIndicator)
    }

    public func handleTracking(startTime: Double, currentTime: Double) {
        guard let cropView = self.cropView else {
            return
        }

        guard !videoFramesScrollingView.isTracking else {
            return
        }
        guard let playbackIndicator = self.playbackLineIndicator else {
            return
        }

        // Calculate size per second
        let pointsPerSecond = videoFramesScrollingView.pointsPerSecond
        let halfPlaybackIndicatorWidth = playbackIndicator.width / 2
        let normalizedTime = currentTime - startTime
        // Calculate x scroll value
        let x = CGFloat(normalizedTime * pointsPerSecond) + (cropView.frame.minX + cropView.borderWidth) - halfPlaybackIndicatorWidth

        // Scroll playbackLineIndicator
        playbackIndicator.frame.origin.x = x
        self.layoutIfNeeded()
    }

    public func changeAccentColor(to color: UIColor) {
        self.cropView?.changeBorderColor(to: color)
        self.playbackLineIndicator?.changeCenterLineColor(to: color.darken())
    }
}

extension TimelineView: VideoFramesScrollingViewDelegate {
    internal func isScrolling() {
        delegate?.isScrolling()
    }

    internal func endScrolling() {
        delegate?.endScrolling()

        let x = self.videoFramesScrollingView.contentOffset.x + self.timeLineStartingPoint
        let startTime = Double(x) / videoFramesScrollingView.pointsPerSecond
        let endTime = startTime + self.cropDurationInSeconds
        delegate?.didChangeStartAndEndTime(to: (startTime: startTime, endTime: endTime))
    }
}

extension TimelineView {
    private struct Constants {
        static let TimelineBackgroundColor = UIColor(hexString: "#DFE3E3") ?? .white
        static let CropViewColor = UIColor(hexString: "#33E5E9") ?? .white
    }
}
