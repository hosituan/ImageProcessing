//
//  VectorClient.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 28/03/2023.
//

import Foundation
import ComposableArchitecture
import Photos
import Vision
import Accelerate
import KDTree

struct VectorClient {
    var createKDTree: @Sendable ([Vector2048]) async throws -> KDTree<Vector2048>
    var loadSimilarIdentifiers: @Sendable (KDTree<Vector2048>, String) async -> [String]
}

extension DependencyValues {
    var vectorClient: VectorClient {
        get { self[VectorClient.self] }
        set { self[VectorClient.self] = newValue }
    }
}

extension VectorClient: DependencyKey {
    static var liveValue: Self {
        let db = Database()
        return Self(
            createKDTree: { vectors in
                return KDTree<Vector2048>(values: vectors)
            },
            loadSimilarIdentifiers: { tree, id in
                guard let currentVector = db.fetchVectors(from: id) else { return [] }
                let start = DispatchTime.now()
                let nearestNeighbor = tree.nearestK(10, to: currentVector.vector2048)
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // subtract start 
                let timeInterval = Double(nanoTime) / 1_000_000_000 // convert nanoseconds to seconds
                print("Time elapsed: \(timeInterval) seconds")
                var ids = [String]()
                for v in nearestNeighbor {
                    ids.append(v.id)
                }
                return ids
            }
        )
    }
}
