//
//  PhotoClient.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import Foundation
import ComposableArchitecture
import Photos
import Vision

struct PhotoClient {
    var requestPermission: @Sendable () async throws -> PHAuthorizationStatus
    var loadPhotos: @Sendable () async throws -> PHFetchResultCollection
    var processImages: @Sendable (PHFetchResultCollection) async throws -> Bool
}

extension DependencyValues {
    var photoClient: PhotoClient {
        get { self[PhotoClient.self] }
        set { self[PhotoClient.self] = newValue }
    }
}

extension PhotoClient: DependencyKey {
    static var liveValue = PhotoClient(
        requestPermission: {
            return await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
                    PHPhotoLibrary.requestAuthorization { status in
                        continuation.resume(returning: status)
                    }
                }
        },
        loadPhotos: {
            return PHFetchResultCollection(fetchResult: PHAsset.fetchAssets(with: .image, options: PHFetchOptions()))
        },
        processImages: { assets in
            let request = VNGenerateImageFeaturePrintRequest()
            for asset in assets {
                if let image = try await asset.previewImage().cgImage {
                    let imageRequestHandler = VNImageRequestHandler(cgImage: image, options: [:])
                    try imageRequestHandler.perform([request])
                    if let featurePrint = request.results?.first as? VNFeaturePrintObservation {
                        //print(featurePrint)
                    }
                }
//                progress.completedUnitCount += 1
//                print(progress.completedUnitCount)
            }
            return true
        }
    )
}
