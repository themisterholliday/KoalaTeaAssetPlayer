//
//  PHPhotoLibraryInterface.swift
//  AssetPlayer
//
//  Created by Craig Holliday on 8/27/18.
//

import Photos

public enum PHAssetType {
    case video
    case image
    case unknown

    init(phAssetType: PHAssetMediaType) {
        switch phAssetType {
        case .image:
            self = .image
        case .video:
            self = .video
        default:
            self = .unknown
        }
    }
}

public struct PHAssetWithThumbnail {
    let phAsset: PHAsset
    let assetType: PHAssetType
    let thumbnail: UIImage
}

public struct PHAssetCollectionWithThumbnail {
    let phAssetCollection: PHAssetCollection
    let thumbnail: UIImage
}

public enum PhotoLibraryAuthorization {
    case authorized
    case notDetermined
    case denied
}

extension PHFetchOptions {
    static func sortedByCreationDate(ascending: Bool) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        return options
    }

    static func videosSortedByCreationDate(ascending: Bool) -> PHFetchOptions {
        let options = PHFetchOptions.sortedByCreationDate(ascending: ascending)
        options.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.video.rawValue)")
        return options
    }

    static func imagesSortedByCreationDate(ascending: Bool) -> PHFetchOptions {
        let options = PHFetchOptions.sortedByCreationDate(ascending: ascending)
        options.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        return options
    }

    static var thumbnailOption: PHFetchOptions {
        let options = PHFetchOptions.sortedByCreationDate(ascending: false)
        options.fetchLimit = 1
        return options
    }
}

extension PHImageRequestOptions {
    static var synchronousHighQuality: PHImageRequestOptions {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.version = .current

        return requestOptions
    }

    static var fullImageRequest: PHImageRequestOptions {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.version = .current
        requestOptions.resizeMode = .exact

        return requestOptions
    }
}

enum PHAssetFetchState {
    case idle, successful, failed
}

struct PHAssetFetch {
    let assets: [PHAsset]
    let requestOptions: PHImageRequestOptions

    let state: PHAssetFetchState
    let fetchedAssetsWithThumbnails: [PHAssetWithThumbnail]

    init(assets: [PHAsset],
         requestOptions: PHImageRequestOptions,
         state: PHAssetFetchState = .idle,
         fetchedAssetsWithThumbnails: [PHAssetWithThumbnail] = []) {
        self.assets = assets
        self.requestOptions = requestOptions
        self.state = state
        self.fetchedAssetsWithThumbnails = fetchedAssetsWithThumbnails
    }

    func withChangingFetchedAssets(to assets: [PHAssetWithThumbnail]) -> PHAssetFetch {
        return PHAssetFetch(assets: self.assets, requestOptions: self.requestOptions, state: .successful, fetchedAssetsWithThumbnails: assets)
    }
}

class PhotoLibraryFetcher: Operation {
    var fetch: PHAssetFetch
    let partialCompletion: (Operation, [PHAssetWithThumbnail]) -> Void

    init(fetch: PHAssetFetch, partialCompletion: @escaping (Operation, [PHAssetWithThumbnail]) -> Void) {
        self.fetch = fetch
        self.partialCompletion = partialCompletion
    }

    override func main() {
        var assetsWithThumbnails = [PHAssetWithThumbnail]()

        if isCancelled {
            return
        }

        let assets = fetch.assets
        let requestOptions = fetch.requestOptions

        assets.enumerated().forEach { (index, asset) in
            if isCancelled {
                self.fetch = self.fetch.withChangingFetchedAssets(to: assetsWithThumbnails)
                return
            }

            PHPhotoLibraryInterface.fetchDefaultSizedImage(for: asset, requestOptions: requestOptions, completion: { (image) in
                if self.isCancelled {
                    return
                }
                guard let image = image else { return }
                assetsWithThumbnails.append(PHAssetWithThumbnail(phAsset: asset,
                                                                 assetType: PHAssetType(phAssetType: asset.mediaType),
                                                                 thumbnail: image))
            })

            // Complete with every amount of images
            if index != 0, index.double.remainder(dividingBy: 200) == 0 {
                if self.isCancelled {
                    return
                }

                self.partialCompletion(self, assetsWithThumbnails)
            }

            self.fetch = self.fetch.withChangingFetchedAssets(to: assetsWithThumbnails)
        }
    }
}

public class PHPhotoLibraryInterface {
    static let CustomAlbumName = "CURAGO"
    static let smallestFullTargetSize = CGSize(width: 400, height: 400)

    static var photoFetchTasksQueue: OperationQueue {
        let queue = OperationQueue()
        queue.name = "Photo Fetch Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }

    static var firstAssetCollection: PHAssetCollection? {
        return PHPhotoLibraryInterface.specificCollection(matchingTitle: .recentlyAdded)
    }

    static var customCollection: PHAssetCollection? {
        let allCollections = PHPhotoLibraryInterface.fetchAllAssetCollections()
        return PHPhotoLibraryInterface.collection(from: allCollections, matchingTitle: .curago)
    }

    private static func specificCollection(matchingTitle title: DefaultAssetCollectionTitles) -> PHAssetCollection? {
        let allCollections = PHPhotoLibraryInterface.fetchAllAssetCollections()
        return allCollections.filter({ ($0.localizedTitle ?? "").lowercased() == title.rawValue }).first
    }

    private static func collection(from assetCollections: [PHAssetCollection], matchingTitle title: DefaultAssetCollectionTitles) -> PHAssetCollection? {
        return assetCollections.filter({ ($0.localizedTitle ?? "").lowercased() == title.rawValue }).first
    }

    public static var authorizationStatus: PhotoLibraryAuthorization {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .restricted:
            return .authorized
        @unknown default:
            assertionFailure()
            return .denied
        }
    }

    public static func requestPhotosAccess(completion: @escaping (_ status: PhotoLibraryAuthorization) -> ()) {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                switch status {
                case .notDetermined:
                    completion(.notDetermined)
                case .denied:
                    completion(.denied)
                case .authorized, .restricted:
                    completion(.authorized)
                @unknown default:
                    assertionFailure()
                }
            }
        }
    }

    // MARK - Fetch Assets with Thumbnails

    @discardableResult public static func fetchAssetsWithThumbnail(from collection: PHAssetCollection,
                                                type: PHAssetType?,
                                                partialCompletion: @escaping ([PHAssetWithThumbnail]) -> (),
                                                completion: @escaping ([PHAssetWithThumbnail]) -> ()) -> Operation {
        let collectionAssets = PHPhotoLibraryInterface.fetchAssets(from: collection, type: type)

        return fetchAssetsWithThumbnail(from: collectionAssets, partialCompletion: partialCompletion, completion: completion)
    }

    @discardableResult public static func fetchAssetsWithThumbnail(from assets: [PHAsset],
                                                partialCompletion: @escaping ([PHAssetWithThumbnail]) -> (),
                                                completion: @escaping ([PHAssetWithThumbnail]) -> ()) -> Operation {
        let requestOptions = PHImageRequestOptions.synchronousHighQuality

        let operationQueue = PHPhotoLibraryInterface.photoFetchTasksQueue

        let fetch = PHAssetFetch(assets: assets, requestOptions: requestOptions)
        let fetchOperation = PhotoLibraryFetcher(fetch: fetch) { (operation, assetsWithThumbnails) in
            guard !operation.isCancelled else { return }
            partialCompletion(assetsWithThumbnails)
        }

        fetchOperation.completionBlock = {
            guard !fetchOperation.isCancelled else { return }
            let assetsWithThumbnails = fetchOperation.fetch.fetchedAssetsWithThumbnails
            completion(assetsWithThumbnails)
        }

        operationQueue.addOperation(fetchOperation)

        return fetchOperation
    }

    // MARK - Single Fetch Requets

    public static func fetchDefaultSizedImage(for asset: PHAsset, requestOptions: PHImageRequestOptions?, completion: @escaping (UIImage?) -> ()) {
        // @TODO: figure out target size. If target size above 200x200 the request is very slow
        let targetSize = CGSize(width: 200, height: 200)
        PHImageManager.default()
            .requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { (image, info) in
                guard let image = image else {
                    completion(nil)
                    return
                }
                completion(image)
        }
    }

    public static func fetchFullImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> ()) {
        let requestOptions = PHImageRequestOptions.fullImageRequest

        PHImageManager
            .default()
            .requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: requestOptions) { (image, info) in
                guard let image = image else {
                    // If target size is smallestFullTargetSize then we have fallen back for some reason and this was our last request
                    guard targetSize != PHPhotoLibraryInterface.smallestFullTargetSize else {
                        if let info = info {
                            print("PHPhotoLibraryInterface fetchFullImage Error: \(info)")
                        }
                        completion(nil)
                        return
                    }
                    // Make request that has a fallback size that should work for any asset
                    PHPhotoLibraryInterface
                        .fetchFullImage(for: asset,
                                        targetSize: PHPhotoLibraryInterface.smallestFullTargetSize,
                                        completion: completion)
                    return
                }
                completion(image)
        }
    }

    public static func fetchVideoAsset(for asset: PHAsset, completion: @escaping (VideoAsset?) -> ()) {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, avAudioMix, info) in
            guard let asset = avAsset as? AVURLAsset else {
                completion(nil)
                return
            }

            let videoAsset = VideoAsset(urlAsset: asset)
            completion(videoAsset)
        }
    }

    // MARK: Fetch Assets

    public static func fetchAssets(from collection: PHAssetCollection, type: PHAssetType?) -> [PHAsset] {
        var assets = [PHAsset]()

        var options = PHFetchOptions.sortedByCreationDate(ascending: false)

        if let type = type {
            switch type {
            case .video:
                options = PHFetchOptions.videosSortedByCreationDate(ascending: false)
            case .image:
                options = PHFetchOptions.imagesSortedByCreationDate(ascending: false)
            case .unknown:
                break
            }
        }

        let fetchResult = PHAsset.fetchAssets(in: collection, options: options)

        fetchResult.enumerateObjects({ (object, count, stop) in
            assets.append(object)
        })

        return assets
    }

    public static func fetchAllAssetCollections() -> [PHAssetCollection] {
        let userAlbums = PHPhotoLibraryInterface.fetchAssetCollections(with: .album)
        let smartAlbums = PHPhotoLibraryInterface.fetchAssetCollections(with: .smartAlbum)

        return userAlbums + smartAlbums
    }

    public static func fetchAllAssetCollectionsWithAssets() -> [PHAssetCollection] {
        let allCollections = PHPhotoLibraryInterface.fetchAllAssetCollections().sorted(by: { $0.localizedTitle ?? "" < $1.localizedTitle ?? "" })
        
        return allCollections.filter({ $0.estimatedAssetCount > 0 })
    }

    public static func fetchAllAssetCollectionsWithThumbnails() -> [PHAssetCollectionWithThumbnail] {
        let allAssetCollections = self.fetchAllAssetCollectionsWithAssets()
        var assetCollecitonWithThumbnails = [PHAssetCollectionWithThumbnail]()

        allAssetCollections.forEach { (collection) in
            PHPhotoLibraryInterface.fetchThumbnail(for: collection, completion: { (image) in
                guard let image = image else { return }

                let collectionWithThumbnail = PHAssetCollectionWithThumbnail(phAssetCollection: collection, thumbnail: image)
                assetCollecitonWithThumbnails.append(collectionWithThumbnail)
            })
        }

        return assetCollecitonWithThumbnails
    }

    public static func fetchNonDefaultAssetCollectionsWithThumbnails() -> [PHAssetCollectionWithThumbnail] {
        let allTitles = DefaultAssetCollectionTitles.allTitles
        
        let allAssetCollections = self.fetchAllAssetCollectionsWithAssets().filter { (collection) -> Bool in
            guard let title = collection.localizedTitle else {
                return false
            }
            return !allTitles.contains(title.lowercased())
        }

        var assetCollecitonWithThumbnails = [PHAssetCollectionWithThumbnail]()

        allAssetCollections.forEach { (collection) in
            PHPhotoLibraryInterface.fetchThumbnail(for: collection, completion: { (image) in
                guard let image = image else { return }

                let collectionWithThumbnail = PHAssetCollectionWithThumbnail(phAssetCollection: collection, thumbnail: image)
                assetCollecitonWithThumbnails.append(collectionWithThumbnail)
            })
        }
        
        return assetCollecitonWithThumbnails
    }

    public static func fetchAllDefaultAssetCollectionsWithThumbnails() -> [PHAssetCollectionWithThumbnail] {
        let allTitles = DefaultAssetCollectionTitles.allTitles
        let allAssetCollections = self.fetchAllAssetCollections().filter { (collection) -> Bool in
            guard let title = collection.localizedTitle else {
                return false
            }
            return allTitles.contains(title.lowercased())
        }

        var assetCollecitonWithThumbnails = [PHAssetCollectionWithThumbnail]()

        allAssetCollections.forEach { (collection) in
            PHPhotoLibraryInterface.fetchThumbnail(for: collection, completion: { (image) in
                guard let image = image else { return }

                let collectionWithThumbnail = PHAssetCollectionWithThumbnail(phAssetCollection: collection, thumbnail: image)
                assetCollecitonWithThumbnails.append(collectionWithThumbnail)
            })
        }

        // Default has a specific sort
        let sorted = assetCollecitonWithThumbnails
            .sorted{ allTitles.firstIndex(of: ($0.phAssetCollection.localizedTitle ?? "").lowercased()) ?? 0 < allTitles.firstIndex(of: ($1.phAssetCollection.localizedTitle ?? "").lowercased()) ?? 0 }

        return sorted
    }

    // MARK: Private
    private static func fetchThumbnail(for collection: PHAssetCollection, completion: @escaping (UIImage?) -> ()) {
        guard let asset = PHPhotoLibraryInterface.fetchFirstAsset(from: collection) else {
            completion(nil)
            return
        }

        let requestOptions = PHImageRequestOptions.synchronousHighQuality

        PHPhotoLibraryInterface.fetchDefaultSizedImage(for: asset, requestOptions: requestOptions) { (image) in
            completion(image)
        }
    }

    private static func fetchFirstAsset(from collection: PHAssetCollection) -> PHAsset? {
        let fetchResult = PHAsset.fetchAssets(in: collection, options: PHFetchOptions.thumbnailOption)

        var asset: PHAsset?
        fetchResult.enumerateObjects({ (object, count, stop) in
            asset = object
        })

        return asset
    }

    private static func fetchAssetCollections(with type: PHAssetCollectionType) -> [PHAssetCollection] {
        var collections = [PHAssetCollection]()

        let fetchResults = PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)
        fetchResults.enumerateObjects { (collection, count, stop) in
            collections.append(collection)
        }

        return collections
    }

    static func cancelRequest(imageRequestId: PHImageRequestID) {
        PHImageManager.default().cancelImageRequest(imageRequestId)
    }

    // MARK - Saving
    public static func saveFileUrlToPhotos(fileUrl: URL,
                                           success: @escaping () -> (),
                                           failure: @escaping (Error?) -> ()) {
        PHPhotoLibraryInterface.getOrCreateCustomAlbum(success: { (customCollection) in
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileUrl)
                guard let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset else {
                    failure(NSError(domain: "com.curago.PHPhotoLibraryInterface.saveFileUrlToPhotos", code: -1, userInfo: nil))
                    return
                }
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: customCollection)
                let enumeration: NSArray = [assetPlaceholder]
                albumChangeRequest?.addAssets(enumeration)
            }) { saved, error in
                guard saved == true else {
                    failure(error)
                    return
                }
                success()
            }
        }, failure: failure)
    }

    public static func saveImageToPhotos(image: UIImage,
                                         success: @escaping () -> (),
                                         failure: @escaping (Error?) -> ()) {
        PHPhotoLibraryInterface.getOrCreateCustomAlbum(success: { (customCollection) in
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                guard let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset else {
                    failure(NSError(domain: "com.curago.PHPhotoLibraryInterface.saveImageToPhotos", code: -1, userInfo: nil))
                    return
                }
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: customCollection)
                let enumeration: NSArray = [assetPlaceholder]
                albumChangeRequest?.addAssets(enumeration)
            }) { saved, error in
                guard saved == true else {
                    failure(error)
                    return
                }
                success()
            }
        }, failure: failure)
    }

    private static func getOrCreateCustomAlbum(success: @escaping (PHAssetCollection) -> (),
                                               failure: @escaping (Error?) -> ()) {
        guard let customCollection = PHPhotoLibraryInterface.customCollection else {
            PHPhotoLibraryInterface.createCustomAlbum(success: success, failure: failure)
            return
        }
        success(customCollection)
    }

    public static func createCustomAlbum(success: @escaping (PHAssetCollection) -> (),
                                         failure: @escaping (Error?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: PHPhotoLibraryInterface.CustomAlbumName)
        }) { saved, error in
            guard saved == true else {
                failure(error)
                return
            }
            guard let customCollection = PHPhotoLibraryInterface.customCollection else {
                failure(NSError(domain: "com.curago.PHPhotoLibraryInterface.createCustomAlbum", code: -1, userInfo: nil))
                return
            }
            success(customCollection)
        }
    }
}

extension PHPhotoLibraryInterface {
    private enum DefaultAssetCollectionTitles: String, CaseIterable {
        case recentlyAdded = "recently added"
        case cameraRoll = "camera roll"
        case allPhotos = "all photos"
        case videos = "videos"
        case curago = "curago"

        static var allTitles: [String] {
            return DefaultAssetCollectionTitles.allCases.compactMap({ $0.rawValue })
        }
    }
}

public enum AVCaptureDeviceAuthorization {
    case authorized
    case notDetermined
    case denied
}

class AVCaptureDeviceInterface {
    public static var authorizationStatus: AVCaptureDeviceAuthorization {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .restricted:
            return .authorized
        @unknown default:
            assertionFailure()
            return.denied
        }
    }

    public static func requestCameraAccess(completion: @escaping (_ status: AVCaptureDeviceAuthorization) -> ()) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            completion(AVCaptureDeviceInterface.authorizationStatus)
        }
    }
}

extension PHAsset {
    var pixelSize: CGSize {
        return CGSize(width: self.pixelWidth, height: self.pixelHeight)
    }
}
