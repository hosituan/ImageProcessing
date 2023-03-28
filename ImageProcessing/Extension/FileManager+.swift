//
//  FileManager+.swift
//  ImageProcessing
//
//  Created by Ho Si Tuan on 28/03/2023.
//

import Foundation

extension FileManager {
    static var databaseDirectory: URL? {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let databaseDirectory = urls.first?.appendingPathComponent("Databases")
        guard let databaseDirectory = databaseDirectory else { return nil }
        try? FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true, attributes: nil)
        return databaseDirectory
    }

    static func databaseURL(for name: String) -> URL? {
        return databaseDirectory?.appendingPathComponent("\(name).sqlite")
    }
}
