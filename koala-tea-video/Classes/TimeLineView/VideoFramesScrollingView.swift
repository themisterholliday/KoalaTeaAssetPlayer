//
//  VideoFramesScrollingView.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 3/6/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoFramesScrollingViewDelegate: class {
    func isScrolling()
    func endScrolling()
}

public class VideoFramesScrollingView: UIView {
    weak var delegate: VideoFramesScrollingViewDelegate?

    private let scrollView = UIScrollView()
    public var isTracking: Bool {
        return self.scrollView.isTracking
    }
    public var contentOffset: CGPoint {
        return self.scrollView.contentOffset
    }

    private let framerate: Double
    private let videoDuration: Double

    public var pointsPerSecond: Double {
        return Double(self.scrollView.contentSize.width) / self.videoDuration
    }

    private var videoFramesView: VideoFramesView?

    required public init(frame: CGRect,
                         videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         videoFrameWidth: CGFloat,
                         leftRightScrollViewInset: CGFloat) {
        self.framerate = framerate
        self.videoDuration = videoDuration

        super.init(frame: frame)

        self.setupScrollView(leftRightInset: leftRightScrollViewInset)

        // Video frame view
        let newVideoFramesView = VideoFramesView(videoAsset: videoAsset,
                                              framerate: framerate,
                                              videoDuration: videoDuration,
                                              videoFrameSize: CGSize(width: videoFrameWidth, height: self.height),
                                              desiredFramesPerSecond: Constants.DesiredFramesPerSecond)
        self.scrollView.contentSize = newVideoFramesView.size
        self.scrollView.addSubview(newVideoFramesView)
        self.videoFramesView = newVideoFramesView
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScrollView(leftRightInset: CGFloat) {
        self.scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        self.scrollView.delegate = self

        self.scrollView.contentSize = CGSize(width: self.scrollView.width, height: self.scrollView.height)
        self.scrollView.contentInset = UIEdgeInsets(top: 0, left: leftRightInset, bottom: 0, right: leftRightInset)

        self.addSubview(scrollView)

        self.scrollView.contentOffset = CGPoint(x: -(scrollView.width / 2), y: 0)

        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
    }
}

extension VideoFramesScrollingView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.isScrolling()
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegate?.endScrolling()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        self.delegate?.endScrolling()
    }
}

public extension VideoFramesScrollingView {
    private struct Constants {
        static let DesiredFramesPerSecond: Double = 1
    }
}
