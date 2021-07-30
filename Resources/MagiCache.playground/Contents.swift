import Foundation

@propertyWrapper public struct Cached<T: Codable> {
    let key: String
    var storage = MagiCache<T>(identifier: "default")

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
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    let cacheDirectory: URL
    
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
        print("Cache Directory is:\n\t\(cacheDirectory.path)")
    }
    
    public func value(for key: CacheKey) -> T? {
        if let vv = try? Data(contentsOf: cacheDirectory.appendingPathComponent(key)),
           let value = try? decoder.decode(T.self, from: vv) {
            return value
        }
        return nil
    }
    
    public func setValue<T: Codable>(_ value: T, for key: CacheKey) {
        guard let data = try? encoder.encode(value) else {
            print("failed to encode \(String(describing: value))")
            return
        }
        try? data.write(to: cacheDirectory.appendingPathComponent(key))
    }
}

struct FancyValue {
    @Cached<Int>(key: "count", value: 42) public var count
    init(_ value: Int) {
        self.count = value
    }
}

var fv = FancyValue(256)
print(fv.count)
fv.count = 1
print(fv.count)

