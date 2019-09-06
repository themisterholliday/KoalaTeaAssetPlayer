//
//  AVAssetExtensions.swift
//  KoalaTeaVideo-editor
//
//  Created by Craig Holliday on 2/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

extension AVAsset {
    public func getFirstVideoTrack() -> AVAssetTrack? {
        guard let track = self.tracks(withMediaType: AVMediaType.video).first else {
            assertionFailure("AVAsset: " + "Failure getting first video track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }

    public func getFirstAudioTrack() -> AVAssetTrack? {
        guard let track = self.tracks(withMediaType: AVMediaType.audio).first else {
            assertionFailure("AVAsset: " + "Failure getting first audio track")
            return nil
        }
        let videoTrack: AVAssetTrack = track as AVAssetTrack
        return videoTrack
    }
}

// MARK: Frame getters

extension AVAsset {
    public func getFramesBySecond(every seconds: Double, withStreaming: @escaping (Int, UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []

            // Frame Reader
            guard let reader = try? AVAssetReader(asset: self) else {
                assertionFailure()
                return
            }

            guard let firstTrack = self.getFirstVideoTrack() else {
                return
            }
            let assetTransform = firstTrack.preferredTransform

            let divisor = (seconds * Double(firstTrack.nominalFrameRate)).rounded()

            // read video frames as BGRA
            let trackReaderOutput = AVAssetReaderTrackOutput(track: firstTrack,
                                                             outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)])
            reader.add(trackReaderOutput)
            reader.startReading()

            var counter: Double = 0
            while let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() {
                guard counter.truncatingRemainder(dividingBy: divisor) == 0 else {
                    counter += 1
                    continue
                }
                autoreleasepool {
                    let image = CMBufferHelper.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                    images.append(image)

                    DispatchQueue.main.async {
                        if let image = image.fixingVideoFrameOrientation(assetTransform: assetTransform) {
                            withStreaming(images.count - 1, image)
                        }
                    }
                }
                counter += 1
            }
        }
    }

    public func getAllFrames(framesPerSecond seconds: Double, withStreaming: @escaping (Int, UIImage) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let duration = self.duration.seconds.rounded() * seconds
            let generator = AVAssetImageGenerator(asset: self)
            generator.maximumSize = CGSize(width: 200, height: 200)
            generator.appliesPreferredTrackTransform = true
            var frames = [UIImage]()
            for index in 0...Int(duration) {
                if let image = AVAsset.getFrame(fromTime: Float64(index), with: generator) {
                    frames.append(image)
                    DispatchQueue.main.async {
                        withStreaming(frames.count - 1, image)
                    }
                }
            }
            frames = []
        }
    }

    private static func getFrame(fromTime: Float64, with generator: AVAssetImageGenerator) -> UIImage? {
        let time: CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: Asset.PublicConstants.DefaultTimeScale)
        do {
            let image = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: image)
        } catch {
            return nil
        }
    }
}

extension AVAsset {
    private struct Constants {
        static let InitialFrameFetchCount = 10
    }
}

extension UIImage {
    func fixingVideoFrameOrientation(assetTransform: CGAffineTransform) -> UIImage? {
        let assetInfo = VideoExporterOrientationHelper.orientationFromTransform(transform: assetTransform)

        let image = self
        if assetInfo.orientation == .up, !assetInfo.isPortrait {
            return image
        }

        switch assetInfo.orientation {
        case .left, .leftMirrored:
            return self.rotate(radians: -CGFloat(Double.pi / 2))
        case .right, .rightMirrored:
            return self.rotate(radians: CGFloat(Double.pi / 2))
        default:
            return self
        }
    }

    func rotate(radians: CGFloat) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: radians)).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: radians)

        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
