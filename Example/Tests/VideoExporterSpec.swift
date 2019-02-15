import Nimble
import Quick
import SwifterSwift
import CoreMedia
import koala_tea_video

class VideoExporterSpec: QuickSpec {
    override func spec() {
        var thirtySecondAsset: VideoAsset {
            return VideoAsset(url: Bundle(for: VideoExporterSpec.self).url(forResource: "SampleVideo_1280x720_5mb", withExtension: "mp4")!)
        }

        describe("Video Asset Methods") {
            context("generateClippedAssets") {
                it("generates two clipped assets around 15 seconds long") {
                    let assets = thirtySecondAsset.generateClippedAssets(for: 15)

                    let firstAsset = assets.first
                    expect(firstAsset?.timePoints.startTimeInSeconds).to(equal(0))
                    expect(firstAsset?.timePoints.endTimeInSeconds).to(equal(15))

                    let lastAsset = assets.last
                    expect(lastAsset?.timePoints.startTimeInSeconds).to(equal(15))
                    expect(lastAsset?.timePoints.endTimeInSeconds).to(equal(29.568))
                }
            }
        }

        describe("video exporter") {
            var fileUrl: URL?
            var progressToCheck: Float = 0

            afterEach {
                if let url = fileUrl {
                    // Remove this line to manually review exported videos
                    FileHelpers.removeFileAtURL(fileURL: url)
                }

                fileUrl = nil
                progressToCheck = 0
            }

//            context("export video") {
//                it("should complete export with progress") {
//                    let start = Date()
//
//                    let finalAsset = thirtySecondAsset.changeStartTime(to: 5.0).changeEndTime(to: 10.0)
//
//                    VideoExporter
//                        .createVideoExportOperationWithoutCrop(videoAsset: finalAsset,
//                                                success: { returnedFileUrl in
//                            print(returnedFileUrl, "exported file url")
//                            fileUrl = returnedFileUrl
//
//                            print(Date().timeIntervalSince(start), "<- End Time For Export")
//                        }, failure: { (error) in
//                            expect(error).to(beNil())
//                            fail()
//                        })
//
//                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
//                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
//
//                    // Check just saved local video
//                    let savedVideo = VideoAsset(url: fileUrl!)
//                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
//                    expect(firstVideoTrack?.naturalSize.width).to(equal(1280))
//                    expect(firstVideoTrack?.naturalSize.height).to(equal(720))
//                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
//                }
//            }

//            context("export video with watermark") {
//                it("should complete export with progress") {
//                    let start = Date()
//
//                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)
//
//                    let watermarkView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
//                    watermarkView.contentMode = .scaleAspectFit
//                    watermarkView.image = UIImage(named: "long_story_watermark")
//                    watermarkView.layer.rasterizationScale = 2.0
//                    watermarkView.layer.contentsScale = 2.0
//                    watermarkView.layer.shouldRasterize = true
//
//                    VideoExporter
//                        .createVideoExportOperationWithoutCrop(videoAsset: finalAsset,
//                                                watermarkView: watermarkView,
//                                                success: { returnedFileUrl in
//                            print(returnedFileUrl, "exported file url")
//                            fileUrl = returnedFileUrl
//
//                            print(Date().timeIntervalSince(start), "<- End Time For Export")
//                        }, failure: { (error) in
//                            expect(error).to(beNil())
//                            fail()
//                        })
//
//                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
//                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
//
//                    // Check just saved local video
//                    let savedVideo = VideoAsset(url: fileUrl!)
//                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
//                    expect(firstVideoTrack?.naturalSize.width).to(equal(1280))
//                    expect(firstVideoTrack?.naturalSize.height).to(equal(720))
//                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
//                }
//            }

            context("export clipped video") {
                fit("should complete export with progress") {
                    let start = Date()

                    let watermarkView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.contentMode = .scaleAspectFit
                    watermarkView.image = UIImage(named: "long_story_watermark")
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true

                    var urls: [URL]?

                    let operation = VideoExporter
                        .exportClips(videoAsset: thirtySecondAsset,
                                     clipLength: 10,
                                     queue: .main,
                                     watermarkView: watermarkView,
                                     completed: { (exportedUrls, errors) in
                            urls = exportedUrls
                            expect(errors).to(beEmpty())
                            print(Date().timeIntervalSince(start), "<- End Time For Export")
                        })

                    operation.operations.forEach({ operation in
                        operation.progressBlock = { _ in
                            print(operation.progress)
                        }
                    })

                    expect(urls).toEventually(haveCount(3), timeout: 50)
                }
            }
        }
    }
}
