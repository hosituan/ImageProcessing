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

// We should save feature print as Data, no need to convert to 2048 dimensional vectors
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

extension Array where Element == Float {
    func toData() -> Data {
        let count = self.count * MemoryLayout<Float>.stride
        let data = self.withUnsafeBytes { ptr in
            return Data(bytes: ptr.baseAddress!, count: count)
        }
        return data
    }
}

public enum ArrayResult<T:Equatable> {
    case success(result: [T])
    case failure(error: Error)
}

extension ArrayResult: Equatable {
    public static func ==(lhs: ArrayResult<T>, rhs: ArrayResult<T>) -> Bool {
        switch (lhs) {
        case .success(let lhsResult):
            if case .success(let rhsResult) = rhs, lhsResult == rhsResult { return true }
        case .failure(let lhsError):
            if case .failure(let rhsError) = rhs, lhsError as NSError == rhsError as NSError { return true }
        }
        return false
    }
}

extension Data {
    func toFloatArray() -> [Float] {
        let count = self.count / MemoryLayout<Float>.stride
        let floatArray = self.withUnsafeBytes { ptr in
            return ptr.bindMemory(to: Float.self).prefix(count).map { $0 }
        }
        return floatArray

    }
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
        } catch {
            
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
