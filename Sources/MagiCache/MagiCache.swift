import Foundation

typealias Megabytes = Double

extension Megabytes {
    var bytesInt: Int {
        Int(self * 1024 * 1024)
    }
    
    var bytes: Double {
        self * 1024 * 1024
    }
}

final class MagiCache<T: Codable> {
    typealias CacheKey = String
    
    public private(set) var size: Megabytes
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    
    public init(_ size: Megabytes = 10, identifier: String = "magicache-default") throws {
        let baseURL = FileManager.default
            .urls(for: .cachesDirectory,
                     in: .userDomainMask)
            .first?
            .appendingPathComponent(identifier)
        self.cacheDirectory = baseURL ??
            FileManager.default.temporaryDirectory.appendingPathComponent(identifier)
        #if DEBUG
        print("Cache Directory: \(cacheDirectory.path)")
        #endif
        self.size = size
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                                withIntermediateDirectories: true)
    }
    
    public func availableMegabytes() throws -> Double {
        guard let usedBytes = try FileManager.default
                .attributesOfItem(atPath: self.cacheDirectory.path)[.size] as? Double else {
            return size.bytes
        }
        return size.bytes - usedBytes
    }

    public func value(for key: CacheKey) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        do {
            try FileManager.default.setAttributes(
                [.modificationDate : Date()],
                ofItemAtPath: fileURL.path
            )
            let cachedData = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: cachedData)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    public func setValue<T: Codable>(_ value: T, for key: CacheKey) {
        guard !key.isEmpty,
            let data = try? encoder.encode(value),
            let available = try? available() else {
                return
        }
        #if DEBUG
        print("Available: \(available)")
        print("New item: \(data.count)")
        #endif
        guard data.count < size.bytesInt else {
            #if DEBUG
            print("Value too large for cache")
            #endif
            return
        }
        if data.count > available {
            #if DEBUG
            print("Value \(value) will cause cache to flush")
            #endif
            flush(bytes: data.count)
        }
        try? data.write(to: cacheDirectory.appendingPathComponent(key))
    }
    
    public func empty() throws {
        try FileManager.default
            .contentsOfDirectory(atPath: cacheDirectory.path)
            .forEach {
                let urlToDelete = cacheDirectory.appendingPathComponent($0)
                try FileManager.default.removeItem(at: urlToDelete)
            }
    }
}

extension MagiCache {
    
    func flush(bytes: Int) {
        guard var sortedByOldest: [(path: String, bytes: Int)] = try? newestItemsWithSizes() else {
            return
        }
        var pathsToDelete = [String]()
        var flushed = 0
        while flushed <= bytes {
            guard let oldest = sortedByOldest.popLast() else { break }
            pathsToDelete.append(oldest.path)
            flushed += oldest.bytes
        }
        pathsToDelete.forEach {
            #if DEBUG
            print("flushing: \($0)")
            #endif
            // TODO: Set up a custom FileManager Delegate?
            do {
                try FileManager.default.removeItem(atPath: $0)
            } catch {
                print("Could not flush \($0)")
            }
        }
    }
    
    func modificationDate(of path: String) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
    }
    
    func itemBytes(at path: String) -> Int? {
        // NOTE: FileAttributes.size excludes resource forks
        // As we aren’t setting any resource forks, this should be fine.
        try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int
    }
    
    func usedCacheBytes() throws -> Int {
        let paths = try allCachedItemsPaths()
        return paths.reduce(0) { result, path in
            var next = result
            next += itemBytes(at: path) ?? 0
            return next
        }
    }
    
    func available() throws -> Int {
        let used = try usedCacheBytes()
        return size.bytesInt - used
    }
    
    func allCachedItemsPaths() throws -> [String] {
        var paths = try FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path)
        paths = paths.map {
            cacheDirectory.appendingPathComponent($0, isDirectory: true).path
        }
        return paths
    }

    func newestPathItems() throws -> [String] {
        var paths = try allCachedItemsPaths()
        paths.sort { prev, next in
            guard let prevModified = modificationDate(of: prev),
                  let nextModfied = modificationDate(of: next) else {
                return false
            }
            
            return prevModified > nextModfied
        }
        return paths
    }
    
    func newestItemsWithSizes() throws -> [(path: String, bytes: Int)]{
        let sortedByOldest = try newestPathItems()
        return sortedByOldest.compactMap { path in
            guard let diskBytes = itemBytes(at: path) else {
                return nil
            }
            return (path: path, bytes: diskBytes)
        }
    }
}
