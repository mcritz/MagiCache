import Foundation
import MagiCache

@propertyWrapper public struct Cached<T: Codable> {
    let key: String
    var storage = MagiCache<T>()

    public var wrappedValue: T? {
        get {
            storage.value(for: key)
        }
        set {
            storage.setValue(newValue, for: key)
        }
    }
    
    public init(key: String, value: T? = nil) {
        self.key = key
        self.wrappedValue = value
    }
}

final class MagiCache<T: Codable> {
    typealias Megabytes = Double
    typealias CacheKey = String
    
    public private(set) var size: Megabytes
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    
    public init(_ size: Megabytes = 100, identifier: String = Bundle.main.bundleIdentifier ?? "magicache-default") {
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

extension MagiCache {
    func modificationDate(of path: String) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date
    }
    
    public func oldestItemPaths() throws -> [String] {
        var paths = try FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path)
        paths = paths.map {
            cacheDirectory.path.appending("/\($0)")
        }
        paths.sort { prev, next in
            guard let prevModified = modificationDate(of: prev),
                  let nextModfied = modificationDate(of: next) else {
                return false
            }
            
            return prevModified < nextModfied
        }
        return paths
    }
}

struct FancyValue {
    @Cached<Int>(key: "count", value: 42) public var count
    init(_ value: Int) {
        self.count = value
    }
}

//var fv = FancyValue(256)
//print(fv.count)
//fv.count = 1
//print(fv.count)
//
let cache = MagiCache<Int>()

for idx in 1...100 {
    cache.setValue(idx, for: "\(idx)")
}

let paths = try cache.oldestItemPaths()

paths.forEach {
    print($0)
}
