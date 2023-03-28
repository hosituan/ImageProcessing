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
    var requestPermission: @Sendable () async -> PHAuthorizationStatus
    var loadPhotos: @Sendable () -> PHFetchResultCollection
    var processImages: @Sendable (PHFetchResultCollection) async throws -> Bool
    var loadPhotoFromIdentifier: @Sendable ([String]) -> PHFetchResultCollection
}

extension DependencyValues {
    var photoClient: PhotoClient {
        get { self[PhotoClient.self] }
        set { self[PhotoClient.self] = newValue }
    }
}

extension PhotoClient: DependencyKey {
    static var liveValue: Self {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let db = Database()
        return Self(
            requestPermission: {
                return await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
                    PHPhotoLibrary.requestAuthorization { status in
                        continuation.resume(returning: status)
                    }
                }
            },
            loadPhotos: {
                let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                return PHFetchResultCollection(fetchResult: fetchResult)
            },
            processImages: { assets in
                let start = DispatchTime.now()
                let request = VNGenerateImageFeaturePrintRequest()
                for asset in assets {
                    if db.fetchVectors(from: asset.localIdentifier) == nil, let image = try await asset.previewImage().cgImage {
                        let imageRequestHandler = VNImageRequestHandler(cgImage: image, options: [:])
                        try imageRequestHandler.perform([request])
                        if let featurePrint = request.results?.first as? VNFeaturePrintObservation {
                            featurePrint.data.withUnsafeBytes { raw in
                                let ptr = raw.baseAddress!.assumingMemoryBound(to: Float.self)
                                let vectors = Array(UnsafeBufferPointer(start: ptr, count: featurePrint.elementCount))
                                let vectorData = VectorData(id: asset.localIdentifier, vectors: vectors)
                                db.insertRow(vector: vectorData)
                            }
                        }
                    }
                }
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // subtract start
                let timeInterval = Double(nanoTime) / 1_000_000_000 // convert nanoseconds to seconds
                print("Time elapsed: \(timeInterval) seconds")
                return true
            },
            loadPhotoFromIdentifier: { identifiers in
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: fetchOptions)
                return PHFetchResultCollection(fetchResult: fetchResult)
            }
        )
        
    }
}
