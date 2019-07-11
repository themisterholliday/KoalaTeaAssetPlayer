//
//  VideoFramesView.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/29/18.
//

import AVFoundation
import SwifterSwift

public class VideoFramesView: UIView {
    required public init(videoAsset: AVURLAsset,
                         framerate: Double,
                         videoDuration: Double,
                         videoFrameSize: CGSize,
                         desiredFramesPerSecond: Double) {
        super.init(frame: .zero)
        self.clipsToBounds = true

        let frameCountForView = videoDuration * desiredFramesPerSecond
        // Frame count for view * width wanted for each frame
        let totalWidth = CGFloat(frameCountForView) * videoFrameSize.width

        let imageViews = self.getImagesViews(totalCount: frameCountForView, videoFrameSize: videoFrameSize)
        self.addSubviews(imageViews)

        videoAsset.getAllFrames(framesPerSecond: desiredFramesPerSecond) { (index, image) in
            guard let imageView = imageViews[safe: index] else {
                return
            }
            UIView.transition(with: imageView, duration: Constants.ImageViewTransitionAnimationDuration, options: .transitionCrossDissolve, animations: {
                imageView.image = image
            }, completion: nil)
        }

        self.width = totalWidth
        self.height = videoFrameSize.height
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getImagesViews(totalCount: Double,
                                videoFrameSize: CGSize) -> ([UIImageView]) {
        var imageViews = [UIImageView]()

        for _ in 0...totalCount.int {
            let x: CGFloat = CGFloat(imageViews.count) * videoFrameSize.width

            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: videoFrameSize.width, height: videoFrameSize.height))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true

            imageViews.append(imageView)
        }

        return imageViews
    }

    private func createSpreadOfImageViews(images: [UIImage],
                                          divisor: Double,
                                          size: CGSize) -> [UIImageView] {
        var imageViews = [UIImageView]()
        // Get an even spread of images per the frame count
        var counter: CGFloat = 0
        for image in images {
            guard counter.truncatingRemainder(dividingBy: CGFloat(divisor)) == 0 else {
                counter += 1
                continue
            }

            let x: CGFloat = CGFloat(imageViews.count) * size.width

            let imageView = UIImageView(frame: CGRect(x: x, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true

            imageViews.append(imageView)
            counter += 1
        }

        return imageViews
    }

    private struct Constants {
        static let DurationInSecondsForInitialLoadedFrames: Double = 10
        static let ImageViewTransitionAnimationDuration: Double = 0.15
    }
}
