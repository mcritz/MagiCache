import Foundation

typealias Megabytes = Double

extension Megabytes {
    var bytesInt: Int {
        Int(self * 1048576) // (1024 * 1024)
    }
    
    var bytes: Double {
        self * 1048576 // (1024 * 1024)
    }
}

final class MagiCache<T: Codable> {
    typealias CacheKey = String
    
    public private(set) var size: Megabytes
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Creates an disk-backed object cache. The cache uses an `identifier` property to find the
    /// cache on disk even between launches or processes.
    /// - Parameters:
    ///   - size: the cache's maximum size, in Megabytes (1048576 byte chunks)
    ///   - identifier: an optional stringy value to identify the cache on disk. By default the identifier will use any app’s main bundle identifier, and falls back to "magicache-default" as a last resort
    /// NOTE: The cache will use `FileManager.default.temporaryDirectory` as its base url per the best practices
    public init(_ size: Megabytes = 10, identifier: String = Bundle.main.bundleIdentifier ?? "magicache-default") throws {
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
    
    /// Retrieves a cached item from disk
    /// - Parameter key: the identifer defined during `setValue(:, for:)`
    /// - Returns: the cached value, if set
    /// Note that accessing the value will alter its modification date on disk
    /// even if the file has not been altered.
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
    
    /// Sets a codable value in a disk-backed cache with an key identifier.
    /// Using the same identifier again will clear the previously set value with the new value.
    /// - Parameters:
    ///   - value: some Codable value
    ///   - key: a Stringy identifier for retrieving the cached item
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
    
    /// Empties the entire cache
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
    /// Flushes last-used cache files until there is space enough for `bytes` parameter
    /// - Parameter bytes: The size in bytes to flush
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
            // IDEA: Set up a custom FileManager Delegate?
            // We could do some just-in-time check prior to delete, better
            // support concurrency or handle failures with a retry
            do {
                try FileManager.default.removeItem(atPath: $0)
            } catch {
                print("Could not flush \($0)")
            }
        }
    }
    
    /// Convenience method for finding the modification date of an item at a path
    /// - Parameter path: filesystem path to an item on disk
    /// - Returns: the modification date, if set
    func modificationDate(of path: String) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
    }
    
    /// Convenience method for finding the disk bytes of the item at `path`
    /// - Parameter path: filesystem path to an item on disk
    /// - Returns: Filesize in bytes
    func itemBytes(at path: String) -> Int? {
        // NOTE: FileAttributes.size excludes resource forks
        // As we aren’t setting any resource forks, this should be fine.
        try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int
    }
    
    /// Gets the sum of all items in cache
    /// - Returns: size of all items in bytes
    func usedCacheBytes() throws -> Int {
        let paths = try allCachedItemsPaths()
        return paths.reduce(0) { result, path in
            var next = result
            next += itemBytes(at: path) ?? 0
            return next
        }
    }
    
    /// Gets the available cache size
    /// - Returns: size in bytes
    public func available() throws -> Int {
        let used = try usedCacheBytes()
        return size.bytesInt - used
    }
    
    /// Gets all items in cache
    /// - Returns: full paths of all items
    func allCachedItemsPaths() throws -> [String] {
        var paths = try FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path)
        paths = paths.map {
            cacheDirectory.appendingPathComponent($0, isDirectory: true).path
        }
        return paths
    }
    
    /// Gets all the items in cache sorted by newest modification date
    /// - Returns: full paths of all items
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
    
    /// Gets all items in cache with their size in bytes
    /// - Returns: Array of Tuples with `path` full path of item and `bytes` item's size in bytes
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
