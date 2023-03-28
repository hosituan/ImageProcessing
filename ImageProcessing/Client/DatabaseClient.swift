//
//  DatabaseClient.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 28/03/2023.
//

import Foundation
import Photos
import ComposableArchitecture
import GRDB
import KDTree

struct VectorData: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: String
    var vectors: Data
    
    var vector2048: Vector2048 {
        return Vector2048(id: id, values: vectors.toFloatArray())
    }
    init(id: String, vectors: [Float]) {
        self.id = id
        self.vectors = vectors.toData()
    }
}

// Can't use VectorData for KDTreePoint
struct Vector2048: KDTreePoint {
    var id: String
    var values: [Float]
    func kdDimension(_ dimension: Int) -> Double {
        guard dimension >= 0 && dimension < Vector2048.dimensions else {
            fatalError("Invalid dimension")
        }
        return Double(values[dimension])
    }
    
    func squaredDistance(to otherPoint: Vector2048) -> Double {
        return Double(l2distance(self.values, otherPoint.values))
    }
    
    func l2distance(_ feat1: [Float], _ feat2: [Float]) -> Float {
        return sqrt(zip(feat1, feat2).map { f1, f2 in pow(f2 - f1, 2) }.reduce(0, +))
    }
    
    static var dimensions = 2048
}

extension DependencyValues {
    var db: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}

extension Database: DependencyKey {
    static var liveValue = Database()
}

struct Database {
    var dbQueue: DatabaseQueue!
    init() {
        do {
            dbQueue = try DatabaseQueue(path: FileManager.databaseURL(for: "database")?.absoluteString ?? "")
        } catch let error {
            print(error)
        }
    }
    let databaseURL = FileManager.databaseURL(for: "photo")
    
    func createVectorTable() {
        do {
            try dbQueue.write { db in
                try db.create(table: "VectorData") { table in
                    table.column("id", .text).primaryKey()
                    table.column("vectors", .any).notNull()
                }
            }
        } catch let error {
            print(error)
        }
        
    }

    func insertRow(vector: VectorData) {
        do {
            try dbQueue.write { db in
                try vector.insert(db)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func fetchAll() -> [VectorData] {
        do {
            let result = try dbQueue.read({ db in
                try VectorData.fetchAll(db)
            })
            return result
        } catch let error {
            print(error)
            return []
        }
    }
    
    func fetchVectors(from id: String) -> VectorData? {
        do {
            return try dbQueue.read({ db in
                try VectorData.fetchOne(db, key: id)
            })
        } catch let error {
            print(error)
            return nil
            
        }
    }

}
