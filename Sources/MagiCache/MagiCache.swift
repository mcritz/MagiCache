import Foundation

final class MagiCache<T: Codable> {
    typealias Megabytes = Double
    typealias CacheKey = String
    
    public private(set) var size: Megabytes
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    
    public init(_ size: Megabytes = 512, identifier: String = "default") {
        let baseURL = FileManager.default
            .urls(for: .cachesDirectory,
                     in: .userDomainMask)
            .first?
            .appendingPathComponent(identifier)
        self.cacheDirectory = baseURL ??
            FileManager.default.temporaryDirectory.appendingPathComponent(identifier)
        self.size = size
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                                withIntermediateDirectories: true)
    }
    
    public func value(for key: CacheKey) -> T? {
        guard let cachedData = try? Data(contentsOf: cacheDirectory.appendingPathComponent(key)) else {
            return nil
        }
        return try? decoder.decode(T.self, from: cachedData)
    }
    
    public func setValue<T: Codable>(_ value: T, for key: CacheKey) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: cacheDirectory.appendingPathComponent(key))
    }
}
