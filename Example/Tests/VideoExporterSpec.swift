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
//                    FileHelpers.removeFileAtURL(fileURL: url)
                }

                fileUrl = nil
                progressToCheck = 0
            }

            context("export video") {
                it("should complete export with progress") {
                    let start = Date()

                    let finalAsset = thirtySecondAsset.changeStartTime(to: 5.0).changeEndTime(to: 10.0)

                    VideoExporter
                        .exportVideoWithoutCrop(videoAsset: finalAsset,
                                     progress:
                            { (progress) in
                                print("export video: \(progress)")
                                progressToCheck = progress
                        }, success: { returnedFileUrl in
                            print(returnedFileUrl, "exported file url")
                            fileUrl = returnedFileUrl

                            print(Date().timeIntervalSince(start), "<- End Time For Export")
                        }, failure: { (error) in
                            expect(error).to(beNil())
                            fail()
                        })

                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)

                    // Check just saved local video
                    let savedVideo = VideoAsset(url: fileUrl!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(1280))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(720))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }
            }

            context("export video with watermark") {
                fit("should complete export with progress") {
                    let start = Date()

                    let finalAsset = thirtySecondAsset.changeStartTime(to: 0.0).changeEndTime(to: 5.0)

                    let watermarkView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
                    watermarkView.contentMode = .scaleAspectFit
                    watermarkView.image = UIImage(named: "long_story_watermark")
                    watermarkView.layer.rasterizationScale = 2.0
                    watermarkView.layer.contentsScale = 2.0
                    watermarkView.layer.shouldRasterize = true

                    VideoExporter
                        .exportVideoWithoutCrop(videoAsset: finalAsset,
                                                watermarkView: watermarkView,
                                                progress:
                            { (progress) in
                                print("export video: \(progress)")
                                progressToCheck = progress
                        }, success: { returnedFileUrl in
                            print(returnedFileUrl, "exported file url")
                            fileUrl = returnedFileUrl

                            print(Date().timeIntervalSince(start), "<- End Time For Export")
                        }, failure: { (error) in
                            expect(error).to(beNil())
                            fail()
                        })

                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)

                    // Check just saved local video
                    let savedVideo = VideoAsset(url: fileUrl!)
                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
                    expect(firstVideoTrack?.naturalSize.width).to(equal(1280))
                    expect(firstVideoTrack?.naturalSize.height).to(equal(720))
                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
                }
            }

            context("media watermark test") {
                it("") {
                    let logoImage = UIImage(named: "long_story_watermarkx200")
                    let item = MediaItem(url: thirtySecondAsset.urlAsset.url)!

                    let firstElement = MediaElement(image: logoImage!)
                    firstElement.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

                    item.add(elements: [firstElement])

                    var url: URL?

                    let mediaProcessor = MediaProcessor()
                    mediaProcessor.processElements(item: item) { [weak self] (result, error) in
                        print(result.processedUrl)
                        url = result.processedUrl
                    }

                    expect(url).toEventuallyNot(beNil(), timeout: 180)
                }
            }

//            describe("export vertical video with theme preset") {
//                // draggable video view
//                let draggableViewSize = CGSize(width: 281.25, height: 500)
//                let draggableViewFrame = CGRect(origin: CGPoint(x: canvasViewFrame.midX - (draggableViewSize.width / 2), y: 0),
//                                                size: draggableViewSize)
//                let finalVerticalAsset = verticalVideoWithPortraitOrientation.withChangingFrame(to: draggableViewFrame).changeStartTime(to: 5.0).changeEndTime(to: 10.0)
//
//                it("should complete export with progress") {
//                    VideoExporter.exportThemeVideo(with: finalVerticalAsset,
//                                                   cropViewFrame: cropViewFrame,
//                                                   progress:
//                        { (progress) in
//                            print("export vertical video with theme preset: \(progress)")
//                            progressToCheck = progress
//                    }, success: { returnedFileUrl in
//                        fileUrl = returnedFileUrl
//                    }, failure: { (error) in
//                        expect(error).to(beNil())
//                        fail()
//                    })
//
//                    expect(progressToCheck).toEventually(beGreaterThan(0.5), timeout: 30)
//                    expect(fileUrl).toEventuallyNot(beNil(), timeout: 30)
//
//                    // Check just saved local video
//                    let savedVideo = VideoAsset(url: fileUrl!)
//                    let firstVideoTrack = savedVideo.urlAsset.getFirstVideoTrack()
//                    expect(firstVideoTrack?.naturalSize.width).to(equal(1080))
//                    expect(firstVideoTrack?.naturalSize.height).to(equal(1920))
//                    expect(firstVideoTrack?.asset?.duration.seconds).to(equal(5))
//                }
//            }
        }
    }
}
