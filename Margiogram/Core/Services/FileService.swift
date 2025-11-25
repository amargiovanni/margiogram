//
//  FileService.swift
//  Margiogram
//
//  Created by Andrea Margiovanni on 2024.
//

import Foundation
import UniformTypeIdentifiers

// MARK: - File Service

/// Service for file operations and management.
actor FileService {
    // MARK: - Shared Instance

    static let shared = FileService()

    // MARK: - Properties

    private let fileManager = FileManager.default

    // MARK: - Directories

    var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var cachesDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    var temporaryDirectory: URL {
        fileManager.temporaryDirectory
    }

    var applicationSupportDirectory: URL {
        get throws {
            try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
    }

    // MARK: - Margiogram Directories

    var mediaDirectory: URL {
        get throws {
            let url = try applicationSupportDirectory.appendingPathComponent("Media", isDirectory: true)
            try createDirectoryIfNeeded(at: url)
            return url
        }
    }

    var downloadsDirectory: URL {
        get throws {
            let url = try applicationSupportDirectory.appendingPathComponent("Downloads", isDirectory: true)
            try createDirectoryIfNeeded(at: url)
            return url
        }
    }

    var databaseDirectory: URL {
        get throws {
            let url = try applicationSupportDirectory.appendingPathComponent("Database", isDirectory: true)
            try createDirectoryIfNeeded(at: url)
            return url
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Directory Operations

    func createDirectoryIfNeeded(at url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func removeDirectory(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
    }

    // MARK: - File Operations

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func fileSize(at url: URL) throws -> Int64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }

    func creationDate(at url: URL) throws -> Date? {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return attributes[.creationDate] as? Date
    }

    func moveFile(from source: URL, to destination: URL) throws {
        // Remove existing file if present
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }

    func copyFile(from source: URL, to destination: URL) throws {
        // Remove existing file if present
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    func deleteFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    // MARK: - Data Operations

    func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
    }

    func readData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    // MARK: - Cache Management

    func clearCache() throws {
        let contents = try contentsOfDirectory(at: cachesDirectory)
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }

    func cacheSize() throws -> Int64 {
        var totalSize: Int64 = 0
        let contents = try contentsOfDirectory(at: cachesDirectory)

        for url in contents {
            totalSize += (try? fileSize(at: url)) ?? 0
        }

        return totalSize
    }

    func mediaSize() throws -> Int64 {
        var totalSize: Int64 = 0
        let media = try mediaDirectory
        let contents = try contentsOfDirectory(at: media)

        for url in contents {
            totalSize += (try? fileSize(at: url)) ?? 0
        }

        return totalSize
    }

    // MARK: - Temporary Files

    func createTemporaryFile(extension ext: String) -> URL {
        temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }

    func cleanTemporaryFiles() throws {
        let contents = try contentsOfDirectory(at: temporaryDirectory)
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }

    // MARK: - File Type Detection

    func mimeType(for url: URL) -> String? {
        guard let utType = UTType(filenameExtension: url.pathExtension) else {
            return nil
        }
        return utType.preferredMIMEType
    }

    func fileType(for url: URL) -> FileType {
        guard let utType = UTType(filenameExtension: url.pathExtension) else {
            return .other
        }

        if utType.conforms(to: .image) {
            return .image
        } else if utType.conforms(to: .video) {
            return .video
        } else if utType.conforms(to: .audio) {
            return .audio
        } else if utType.conforms(to: .pdf) {
            return .document
        } else if utType.conforms(to: .text) {
            return .document
        } else {
            return .other
        }
    }

    // MARK: - Formatted Size

    func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - File Type

enum FileType: String, Sendable {
    case image
    case video
    case audio
    case document
    case other

    var icon: String {
        switch self {
        case .image:
            return "photo"
        case .video:
            return "video"
        case .audio:
            return "waveform"
        case .document:
            return "doc"
        case .other:
            return "doc.fill"
        }
    }
}
