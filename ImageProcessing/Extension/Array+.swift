//
//  Array+.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 29/03/2023.
//

import Foundation

extension Array where Element == Float {
    func toData() -> Data {
        let count = self.count * MemoryLayout<Float>.stride
        let data = self.withUnsafeBytes { ptr in
            return Data(bytes: ptr.baseAddress!, count: count)
        }
        return data
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
