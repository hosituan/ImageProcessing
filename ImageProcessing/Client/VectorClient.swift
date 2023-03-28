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

struct VectorClient {
    var loadSimilarIdentifiers: @Sendable (String) async -> [String]
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
            loadSimilarIdentifiers: { id in
                let allVectors = db.fetchAll()
//                let currentVector = db.fetchVectors(from: id)?.vectors.toFloatArray() ?? []
                let currentVector = db.fetchVectors(from: id)?.vectorString.toArray() ?? []
//                let sortedVectors = allVectors.sorted(by: { vec1, vec2 in
//                    let vector1 = vec1.vectorString.toArray()
//                    let vector2 = vec2.vectorString.toArray()
//                    let dist1 = l2distance(vector1, currentVector)
//                    let dist2 = l2distance(vector2, currentVector)
//                    return dist1 < dist2
//                })
//                let ids = sortedVectors.map { $0.id }
                var minId = ""
                var min: Float = 999.0
                for vector in allVectors {
                    let dic = l2distance(currentVector, vector.vectorString.toArray())
                    if dic < min, vector.id != id {
                        min = dic
                        minId = vector.id
                    }
                }
                return [minId]
            }
        )
    }
}

extension VectorClient {
    static func l2distance(_ feat1: [Float], _ feat2: [Float]) -> Float {
        return sqrt(zip(feat1, feat2).map { f1, f2 in pow(f2 - f1, 2) }.reduce(0, +))
    }
}
