//
//  VideoHelpers.swift
//  koala-tea-video-editor
//
//  Created by Craig Holliday on 1/7/18.
//  Copyright © 2018 Koala Tea. All rights reserved.
//

import AVFoundation
import UIKit

/// Exporter for VideoAssets
public class VideoExporter {
    private enum VideoManagerError: Error {
        case FailedError(reason: String)
        case CancelledError
        case UnknownError
        case NoFirstVideoTrack
        case NoFirstAudioTrack
    }

    /**
     Supported Final Video Sizes

     - _1080x1080: 1080 width by 1080 height
     - _1280x720: 1280 width by 720 height
     - _720x1280: 720 width by 1280 height
     - _1920x1080: 1920 width by 1080 height
     - _1080x1920: 1080 width by 1920 height
     */
    public enum VideoExportSizes {
        case _1080x1080
        case _1024x1024
        case _1280x720
        case _720x1280
        case _1920x1080
        case _1080x1920
        case _1280x1024_twitter

        typealias RawValue = CGSize

        var rawValue: RawValue {
            switch self {
            case ._1080x1080:
                return CGSize(width: 1080, height: 1080)
            case ._1024x1024:
                return CGSize(width: 1024, height: 1024)
            case ._1280x720:
                return CGSize(width: 1280, height: 720)
            case ._720x1280:
                return CGSize(width: 720, height: 1280)
            case ._1920x1080:
                return CGSize(width: 1920, height: 1080)
            case ._1080x1920:
                return CGSize(width: 1080, height: 1920)
            case ._1280x1024_twitter:
                return CGSize(width: 1280, height: 1024)
            }
        }

        init?(string: String?) {
            switch string {
            case "720x1280":
                self = ._720x1280
            case "1080x1920":
                self = ._1080x1920
            default:
                return nil
            }
        }
    }
}

extension VideoExporter {
    /**
     Exports a video to the disk from AVMutableComposition and AVMutableVideoComposition.

     - Parameters:
     - avMutableComposition: Layer composition of everything except video
     - avMutatableVideoComposition: Video composition

     - progress: Returns progress every second.
     - success: Completion for when the video is saved successfully.
     - failure: Completion for when the video failed to save.
     */
    private static func exportVideoToDiskFrom(avMutableComposition: AVMutableComposition,
                                              avMutatableVideoComposition: AVMutableVideoComposition,
                                              progress: @escaping (Float) -> (),
                                              success: @escaping (_ fileUrl: URL) -> (),
                                              failure: @escaping (Error) -> ()) {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            failure(VideoManagerError.FailedError(reason: "Get File Path Error"))
            return
        }

        guard let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String else {
            failure(VideoManagerError.FailedError(reason: "Cannot find App Name"))
            return
        }

        let dateString = Date.currentDateTimeString
        let fileURL = documentDirectory.appendingPathComponent("\(appName)-\(dateString).mp4")

        // Remove any file at URL because if file exists assetExport will fail
        FileHelpers.removeFileAtURL(fileURL: fileURL)

        // Create AVAssetExportSession
        guard let assetExportSession = AVAssetExportSession(asset: avMutableComposition, presetName: AVAssetExportPresetHighestQuality) else {
            failure(VideoManagerError.FailedError(reason: "Can't create asset exporter"))
            return
        }
        assetExportSession.videoComposition = avMutatableVideoComposition
        assetExportSession.outputFileType = AVFileType.mp4
        assetExportSession.shouldOptimizeForNetworkUse = true
        assetExportSession.outputURL = fileURL

        // Schedule timer for sending progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (timer) in
            progress(assetExportSession.progress)
        })

        assetExportSession.exportAsynchronously(completionHandler: {
            timer.invalidate()

            switch assetExportSession.status {
            case .completed:
                success(fileURL)
            case .cancelled:
                failure(assetExportSession.error ?? VideoManagerError.CancelledError)
            case .failed:
                failure(assetExportSession.error ?? VideoManagerError.FailedError(reason: "Asset Exporter Failed"))
            case .unknown, .exporting, .waiting:
                // Should never arrive here
                failure(assetExportSession.error ?? VideoManagerError.UnknownError)
            }
        })
    }

    private static func videoCompositionInstructionFor(compositionTrack: AVCompositionTrack,
                                                       assetTrack: AVAssetTrack,
                                                       assetFrameAdjustedOrigin: CGPoint,
                                                       playerViewFrame: CGRect,
                                                       playerViewTransform: CGAffineTransform,
                                                       widthMultiplier: CGFloat,
                                                       heightMultiplier: CGFloat,
                                                       cropViewFrame: CGRect) -> AVMutableVideoCompositionLayerInstruction
    {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)

        let assetInfo = assetTrack.assetInfo
        let assetTransform = assetTrack.preferredTransform

        let exportSizeRatio = min(widthMultiplier, heightMultiplier)

        // Get scale
        let targetAssetWidth = playerViewFrame.width * exportSizeRatio
        let targetAssetHeight = playerViewFrame.height * exportSizeRatio

        // Flip width and height on portrait
        var targetView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: targetAssetWidth, height: targetAssetHeight)))

        if assetInfo.isPortrait {
            targetView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: targetAssetHeight, height: targetAssetWidth)))
        }

        let naturalView = UIView(frame: CGRect(origin: .zero, size: assetTrack.naturalSize))

        let naturalSizeToTargetSizeTransform = CGAffineTransform(from: naturalView.originalFrame, toRect: targetView.originalFrame)
        let onlyScaleForTarget = CGAffineTransform(scaleX: naturalSizeToTargetSizeTransform.getScale, y: naturalSizeToTargetSizeTransform.getScale)

        // Get origin
        let targetAssetX: CGFloat = (assetFrameAdjustedOrigin.x - cropViewFrame.minX) * exportSizeRatio
        let targetAssetY: CGFloat = (assetFrameAdjustedOrigin.y - cropViewFrame.minY) * exportSizeRatio

        // player view transforms
        let originTransform = CGAffineTransform(translationX: targetAssetX, y: targetAssetY)
        let playerViewRotationTransform = CGAffineTransform(rotationAngle: playerViewTransform.rotation)
        let playerViewScaleTransform = CGAffineTransform(scaleX: playerViewTransform.getScale, y: playerViewTransform.getScale)

        let exportTransform = assetTransform
            .concatenating(onlyScaleForTarget)
            .concatenating(playerViewScaleTransform)
            .concatenating(playerViewRotationTransform)
            .concatenating(originTransform)

        instruction.setTransform(exportTransform, at: CMTime.zero)

        return instruction
    }

    private static func createSimpleVideoCompositionInstruction(compositionTrack: AVCompositionTrack,
                                                                assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction
    {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)

        let assetTransform = assetTrack.preferredTransform
        instruction.setTransform(assetTransform, at: CMTime.zero)
        return instruction
    }
}

extension AVAssetTrack {
    var assetInfo: (orientation: UIImage.Orientation, isPortrait: Bool) {
        let assetTransform = self.preferredTransform
        let assetInfo = VideoExporterOrientationHelper.orientationFromTransform(transform: assetTransform)
        return assetInfo
    }
}

// MARK: Generic Export Method
extension VideoExporter {
    /// Export video from VideoAsset with a cropping view to a final export size.
    ///
    /// - Parameters:
    ///   - videoAsset: VideoAsset to export
    ///   - cropViewFrame: frame of crop view that will determine crop of final exported video. Crop View frame is in relation to a CanvasViewFrame
    ///   - finalExportSize: final export size the video will be after completeing
    ///   - progress: progress of export
    ///   - success: successful completion of export
    ///   - failure: export failure
    public static func exportVideoWithCrop(videoAsset: VideoAsset,
                                           cropViewFrame: CGRect,
                                           finalExportSize: VideoExportSizes,
                                           progress: @escaping (Float) -> (),
                                           success: @escaping (_ fileUrl: URL) -> (),
                                           failure: @escaping (Error) -> ()) {
        let exportVideoSize = finalExportSize.rawValue

        // Canvas view has to be same aspect ratio as export video size
        guard cropViewFrame.size.getAspectRatio() == exportVideoSize.getAspectRatio() else {
            assertionFailure("Selected export size's aspect ratio: \(exportVideoSize.getAspectRatio()) does not equal Cropped View Frame's aspect ratio: \(cropViewFrame.size.getAspectRatio())")
            failure(VideoManagerError.FailedError(reason: "Issue with Crop View Frame Size"))
            return
        }

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else
        {
            failure(VideoManagerError.FailedError(reason: "Failed To Create Video Track"))
            return
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            failure(VideoManagerError.NoFirstVideoTrack)
            return
        }

        // Attach timerange for first video track
        do {
            try firstTrack.insertTimeRange(videoAsset.timeRange,
                                           of: assetFirstVideoTrack,
                                           at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Video Track"))
            return
        }

        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        let durationOfExportedVideo = CMTimeRange(start: CMTime.zero, duration: videoAsset.durationInCMTime)
        mainInstruction.timeRange = durationOfExportedVideo

        // Multipliers to scale height and width of video to final export size
        let heightMultiplier: CGFloat = exportVideoSize.height / cropViewFrame.height
        let widthMultiplier: CGFloat = exportVideoSize.width / cropViewFrame.width
        // 2.2
        let firstInstruction = self.videoCompositionInstructionFor(compositionTrack: firstTrack,
                                                                   assetTrack: assetFirstVideoTrack,
                                                                   assetFrameAdjustedOrigin: videoAsset.adjustedOrigin,
                                                                   playerViewFrame: videoAsset.frame,
                                                                   playerViewTransform: videoAsset.viewTransform,
                                                                   widthMultiplier: widthMultiplier,
                                                                   heightMultiplier: heightMultiplier,
                                                                   cropViewFrame: cropViewFrame)

        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]

        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        guard let framerate = videoAsset.framerate else {
            failure(VideoManagerError.FailedError(reason: "No Framerate for Asset"))
            return
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(framerate))
        avMutableVideoComposition.renderSize = exportVideoSize

        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            failure(VideoManagerError.FailedError(reason: "No First Audio Track"))
            return
        }

        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(videoAsset.timeRange,
                                            of: audioAsset,
                                            at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Audio Track"))
        }

        // 4 Export Video
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition, avMutatableVideoComposition: avMutableVideoComposition, progress: progress, success: success, failure: failure)
    }

    public static func exportVideoWithoutCrop(videoAsset: VideoAsset,
                                              watermarkView: UIView? = nil,
                                              progress: @escaping (Float) -> (),
                                              success: @escaping (_ fileUrl: URL) -> (),
                                              failure: @escaping (Error) -> ()) {
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        // 2 - Create video tracks
        guard let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else
        {
            failure(VideoManagerError.FailedError(reason: "Failed To Create Video Track"))
            return
        }
        guard let assetFirstVideoTrack = videoAsset.urlAsset.getFirstVideoTrack() else {
            failure(VideoManagerError.NoFirstVideoTrack)
            return
        }

        // Attach timerange for first video track
        do {
            try firstTrack.insertTimeRange(videoAsset.timeRange,
                                           of: assetFirstVideoTrack,
                                           at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Video Track"))
            return
        }

        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        let durationOfExportedVideo = CMTimeRange(start: CMTime.zero, duration: videoAsset.durationInCMTime)
        mainInstruction.timeRange = durationOfExportedVideo

        // 2.2
        let firstInstruction = self.createSimpleVideoCompositionInstruction(compositionTrack: firstTrack,
                                                                            assetTrack: assetFirstVideoTrack)

        // 2.3
        mainInstruction.layerInstructions = [firstInstruction]

        let avMutableVideoComposition = AVMutableVideoComposition()
        avMutableVideoComposition.instructions = [mainInstruction]
        guard let framerate = videoAsset.framerate else {
            failure(VideoManagerError.FailedError(reason: "No Framerate for Asset"))
            return
        }
        avMutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(framerate))
        avMutableVideoComposition.renderSize = assetFirstVideoTrack.naturalSize

        var finalAVMutable = avMutableVideoComposition
        if let watermarkView = watermarkView {
            finalAVMutable = self.addView(watermarkView, to: avMutableVideoComposition)
        }

        // 3 - Audio track
        guard let audioAsset = videoAsset.urlAsset.getFirstAudioTrack() else {
            failure(VideoManagerError.FailedError(reason: "No First Audio Track"))
            return
        }

        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(videoAsset.timeRange,
                                            of: audioAsset,
                                            at: CMTime.zero)
        } catch {
            failure(VideoManagerError.FailedError(reason: "Failed To Insert Time Range For Audio Track"))
        }

        // 4 Export Video
        self.exportVideoToDiskFrom(avMutableComposition: mixComposition,
                                   avMutatableVideoComposition: finalAVMutable,
                                   progress: progress,
                                   success: success,
                                   failure: failure)
    }

    // @TODO: move somewhere else
    static func addView(_ view: UIView,
                        to avMutableVideoComposition: AVMutableVideoComposition) -> AVMutableVideoComposition {
        let frameForLayers = CGRect(origin: .zero, size: avMutableVideoComposition.renderSize)
        let videoLayer = CALayer()
        videoLayer.frame = frameForLayers

        let parentlayer = CALayer()
        parentlayer.frame = frameForLayers
        parentlayer.isGeometryFlipped = true
        parentlayer.addSublayer(videoLayer)

        parentlayer.addSublayer(view.layer)

        avMutableVideoComposition
            .animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer,
                                                                 in: parentlayer)
        return avMutableVideoComposition
    }
}

extension VideoExporter {
    func exportClips(videoAsset: VideoAsset,
                     clipLength: Int,
                     queue: DispatchQueue,
                     fullProgress: @escaping (Float) -> (),
                     completed: @escaping (_ fileUrls: [URL], _ errors: [Error]) -> ()) {
        let assets = videoAsset.generateClippedAssets(for: clipLength)
        let assetCount = assets.count.float

        var fileUrls = [URL]()
        var errors = [Error]()

        let dispatchGroup = DispatchGroup()

        assets.forEach { (asset) in
            dispatchGroup.enter()

            VideoExporter.exportVideoWithoutCrop(videoAsset: asset,
                                                 progress:
                { (progress) in
                    fullProgress(progress / assetCount)
            }, success: { (url) in
                dispatchGroup.leave()
                fileUrls.append(url)
            }, failure: { (error) in
                dispatchGroup.leave()
                errors.append(error)
            })
        }

        dispatchGroup.notify(queue: queue) {
            completed(fileUrls, errors)
        }
    }
}

extension Date {
    static var currentDateTimeString: String {
        let utcTimeZone = TimeZone(abbreviation: "UTC")
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = utcTimeZone
        return dateFormatter.string(from: Date())
    }
}
