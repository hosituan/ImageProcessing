//
//  PHFetchResultCollection.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 27/03/2023.
//

import Foundation
import Photos

struct PHFetchResultCollection: RandomAccessCollection, Equatable {

    typealias Element = PHAsset
    typealias Index = Int

    let fetchResult: PHFetchResult<PHAsset>

    var endIndex: Int { fetchResult.count >= 500 ? 1000 : fetchResult.count }
    var startIndex: Int { 0 }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: position)
    }
}
