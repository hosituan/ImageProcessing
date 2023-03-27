//
//  PHAsset+.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import Foundation
import Photos
import UIKit

extension PHAsset {
    func previewImage(completionHandler: @escaping (UIImage) -> ()){
        var thumbnail = UIImage()
        let imageManager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        imageManager.requestImage(for: self, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: options, resultHandler: { img, _ in
            if let img = img {
                thumbnail = img
                completionHandler(thumbnail)
            }
        })
    }
    
    func previewImage(targetSize: CGSize = CGSize(width: 200, height: 200)) async throws -> UIImage {
        let imageManager = PHCachingImageManager()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        let img = try await imageManager.requestImage(for: self, targetSize: targetSize, contentMode: .aspectFit, options: options)
        return img
    }
    
}

