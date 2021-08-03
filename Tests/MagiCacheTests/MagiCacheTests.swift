import XCTest
@testable import MagiCache

final class MagiCacheTests: XCTestCase {
    private let testID = "magicache-tests"
    
    var cache: MagiCache!
    
    override func setUpWithError() throws { cache = try MagiCache(1, identifier: testID) }
    override func tearDownWithError() throws {
        try cache.empty()
        cache = nil
    }
    
    func testInitWithMaximumSize() throws {
        let size = 10.0
        let cache = try MagiCache(size, identifier: testID)
        XCTAssertEqual(cache.size, size, "Can be initialized with a maximum allowed size")
    }
    
    func testInitWithInvalidSize() throws {
        let size = -10.0
        XCTAssertThrowsError(try MagiCache(size, identifier: testID), "it throws if the cache size is negative")
        
        let zero = 0.0
        XCTAssertThrowsError(try MagiCache(zero, identifier: testID), "it throws if the cache size is zero")
    }
    
    func testOverflowInit() throws {
        let size = 0.01
        let cache = try MagiCache(size, identifier: testID)
        let overflowValue = String(repeating: "Z", count: 100_000)
        XCTAssertThrowsError(try cache.setValue(overflowValue, for: "NOPE"), "it won't cache values that exceed the cache size")
    }
    
    func testValidKey() throws {
        let lifeEtc = "Fourty-Two"
        XCTAssertThrowsError(try cache.setValue(lifeEtc, for: ""), "it won't cache if the key is invalid")
    }
    
    func testAddAndRetrieveItem() throws {
        let testValue = "Cache me, please"
        let id = "PersistantValueID"
        
        try cache.setValue(testValue, for: id)
        let cachedValue = try XCTUnwrap(cache.value(String.self, for: id))
        XCTAssertEqual(testValue, cachedValue, "Cache can retrieve an item")
        
        let intID = "zip"
        let zipCode = 94122
        try cache.setValue(zipCode, for: intID)
        let cachedInt = try XCTUnwrap(cache.value(Int.self, for: intID))
        XCTAssertEqual(zipCode, cachedInt, "Cache can store multiple value types")
    }
    
    func testValueForSameKey() throws {
        let oldValue = "Obi Wan in Episode IV"
        try cache.setValue(oldValue, for: "obiwan")
        let newValue = "Obi Wan in Episode I"
        try cache.setValue(newValue, for: "obiwan")
        let cachedValue = cache.value(String.self, for: "obiwan")
        XCTAssertEqual(newValue, cachedValue, "New values overwrite old values")
    }
    
    func testClearCache() throws {
        try cache.setValue("Another cached value", for: "testClearCache")
        let existingFiles = try FileManager.default.contentsOfDirectory(atPath: testPath())
        XCTAssertFalse(existingFiles.isEmpty, "File created. Caching works.")
        
        try cache.empty()
        let folderContents = try FileManager.default.contentsOfDirectory(atPath: testPath())
        XCTAssertTrue(folderContents.isEmpty, "cache.empty() should empty all the cache contents")
    }
    
    func testAvailable() throws {
        let before = try cache.available()
        let prettyLargeString = String(repeating: "X", count: 500)
        try cache.setValue(prettyLargeString, for: "someKey")
        let after = try cache.available()
        XCTAssert(before > after, "availableMegabytes() will be smaller when things are added to the cache")
    }
    
    func testItemExceedsMaxSize() throws {
        let dataCache = try MagiCache(1, identifier: testID)
        defer {
            try? dataCache.empty()
        }
        let lotsOfA: Data = String(repeating: "A", count: 500_000).data(using: .utf8)! // 666670 bytes
        let lotsOfB: Data = String(repeating: "B", count: 200_000).data(using: .utf8)! // 266670 bytes
        let lotsOfC: Data = String(repeating: "C", count: 400_000).data(using: .utf8)! // 533338 bytes
        try dataCache.setValue(lotsOfA, for: "aaa")
        try dataCache.setValue(lotsOfB, for: "bbb")
        try dataCache.setValue(lotsOfC, for: "ccc")
        
        // 1_048_576 (1MB Cache Size)
        // 666670 + 266670 = 933340 (A + B)
        // 933340 + 533338 = 1466678 (AB + C :: too large for 1MB cache, so flush A)
        // 266670 + 533338 = 800008 (B + C)
        // 1_048_576 - 800008 = 248568 (Cache Size - B+C)
        XCTAssertEqual(try dataCache.available(), 248568, "Available cache is the size minus the two most recently added items that fit")
        
        ["bbb", "ccc"].forEach { key in
            XCTAssertNotNil(dataCache.value(Data.self, for: key))
        }
        
        XCTAssertNil(dataCache.value(Data.self, for: "aaa"), "If a new item would cause the cache to exceed the allowed size, it should remove the least recently used elements until space is available")
    }
    
    func testPerformance() {
        print("\n\nHEAD’S UP! Testing performance. This could take up to 30 seconds on a slow machine.\n\n")
        let dataSize = 10_000_000
        let valueQQ = Data.random(dataSize)
        let valueTT = Data.random(dataSize)
        let valueUU = Data.random(dataSize)

        measure { // Author’s baseline is ≈0.6 seconds
            do {
                let niceCache = try MagiCache(60, identifier: testID)
                try niceCache.setValue(valueQQ, for: "QQ")
                try niceCache.setValue(valueTT, for: "TT")
                try niceCache.setValue(valueUU, for: "UU")
                let qq = niceCache.value(Data.self, for: "QQ")
                let tt = niceCache.value(Data.self, for: "TT")
                let uu = niceCache.value(Data.self, for: "UU")
                XCTAssertEqual(valueQQ, qq)
                XCTAssertEqual(valueTT, tt)
                XCTAssertEqual(valueUU, uu)
            } catch {
                XCTFail("Could not run performance test:\n\t\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Helpers
private extension MagiCacheTests {
    func testPath() throws -> String {
        let testURL = FileManager.default
            .urls(for: .cachesDirectory,
                     in: .userDomainMask)
            .first?
            .appendingPathComponent(testID)
        let testPath = try XCTUnwrap(testURL?.path)
        return testPath
    }
}

private extension Data {
    static func random(_ size: Int) -> Data {
        var value = ""
        for _ in 0...size {
            value.append(String.randomAlphanumeric())
        }
        return value.data(using: .ascii)!
    }
}

private extension String {
    static func randomAlphanumeric() -> String {
        "1234567890abcdefghijklmnopqrstuvwxyz".randomElement().map {
            Bool.random() ? String($0).capitalized : String($0)
        }!
    }
}
