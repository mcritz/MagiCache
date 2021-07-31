import Foundation

final class MagiCache<T: Codable> {
    typealias Megabytes = Double
    typealias CacheKey = String
    
    public private(set) var size: Megabytes
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    
    public init(_ size: Megabytes = 100, identifier: String = "magicache-default") {
        let baseURL = FileManager.default
            .urls(for: .cachesDirectory,
                     in: .userDomainMask)
            .first?
            .appendingPathComponent(identifier)
        self.cacheDirectory = baseURL ??
            FileManager.default.temporaryDirectory.appendingPathComponent(identifier)
        print("Cache Directory: \(cacheDirectory.path)")
        self.size = size
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                                withIntermediateDirectories: true)
    }
    
    public func availableMegabytes() throws -> Double {
        guard let usedBytes = try FileManager.default
                .attributesOfItem(atPath: self.cacheDirectory.path)[.size] as? Double else {
            return 0
        }
        return size - (usedBytes / 1024)
    }
    
    public func value(for key: CacheKey) -> T? {
        guard let cachedData = try? Data(contentsOf: cacheDirectory.appendingPathComponent(key)) else {
            return nil
        }
        return try? decoder.decode(T.self, from: cachedData)
    }
    
    public func setValue<T: Codable>(_ value: T, for key: CacheKey) {
        guard !key.isEmpty,
            let data = try? encoder.encode(value) else { return }
        try? data.write(to: cacheDirectory.appendingPathComponent(key))
    }
    
    public func empty() throws {
        try FileManager.default
            .contentsOfDirectory(atPath: cacheDirectory.path)
            .forEach {
                let pathToDelete = cacheDirectory.appendingPathComponent($0).path
                if FileManager.default.isDeletableFile(atPath: pathToDelete) {
                    try FileManager.default.removeItem(atPath: pathToDelete)
                }
            }
    }
}
