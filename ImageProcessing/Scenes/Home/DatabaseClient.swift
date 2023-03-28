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

// We should save feature print as Data, no need to convert to 2048 dimensional vectors
struct VectorData: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: String
    var vectors: Data
    var vectorString: String
    init(id: String, vectors: [Float]) {
        self.id = id
        self.vectors = vectors.toData()
        self.vectorString = vectors.toString()
    }
}

struct FeaturePrint: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var data: Data
    
    static let databaseTableName = "feature_prints"
}

extension String {
    func toArray() -> [Float] {
        var vector: [Float] = []
        let array = self.components(separatedBy: "|")
        for item in array {
            if let value = Float(item) {
                vector.append(value)
            }
        }
        return vector
    }
}


extension Array where Element == Float {
    func toData() -> Data {
        let vectorBytes = self.withUnsafeBytes { $0 }
        guard let baseAddress = vectorBytes.baseAddress else { return Data() }
        return Data(bytes: baseAddress, count: vectorBytes.count)
    }
    
    func toString() -> String {
        var string = ""
        for item in self {
            string += "\(item)|"
        }
        return string
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
        let bufferPointer = self.withUnsafeBytes {
            return UnsafeRawBufferPointer(start: $0.baseAddress!, count: self.count/MemoryLayout<Float>.stride)
        }
        let floatPointer = bufferPointer.bindMemory(to: Float.self)
        return Array(floatPointer)
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
    //var
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
                    table.column("vectorString", .text).notNull()
                }
            }
        } catch let error {
            print(error)
        }
        
    }
    
    func createFeaturePrintTable() {
        do {
            try dbQueue.write({ db in
                try db.create(table: FeaturePrint.databaseTableName) { table in
                    table.column("id", .integer).primaryKey()
                    table.column("data", .any)
                }
            })
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
    
    func insertRow(featurePrint: FeaturePrint) {
        do {
            try dbQueue.write { db in
                try featurePrint.insert(db)
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func fetchAllFeaturePrint() -> [FeaturePrint] {
        do {
            let result = try dbQueue.read({ db in
                try FeaturePrint.fetchAll(db)
            })
            return result
        } catch let error {
            print(error)
            return []
        }
    }
    
    func fetchFeaturePrints(from id: String) -> FeaturePrint? {
        do {
            return try dbQueue.read({ db in
                try FeaturePrint.fetchOne(db, key: id)
            })
        } catch let error {
            print(error)
            return nil
        }
    }
}
