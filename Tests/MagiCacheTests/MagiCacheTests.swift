import XCTest
@testable import MagiCache

final class MagiCacheTests: XCTestCase {
    private let testID = "magicache-tests"
    
    var cache: MagiCache<String>!
    
    override func setUpWithError() throws { cache = MagiCache(identifier: testID) }
    override func tearDownWithError() throws {
        try cache.empty()
        cache = nil
    }
    
    func testInitWithMaximumSize() {
        let size = 10.0
        let cache = MagiCache<Int>(size)
        XCTAssertEqual(cache.size, size)
    }
    
    func testAddAndRetrieveItem() throws {
        let testValue = "Cache me, please"
        let id = "PersistantValueID"
        
        cache.setValue(testValue, for: id)
        let cachedValue = try XCTUnwrap(cache.value(for: id))
        XCTAssertEqual(testValue, cachedValue)
    }
    
    func testClearCache() throws {
        cache.setValue("Another cached value", for: "testClearCache")
        let existingFiles = try FileManager.default.contentsOfDirectory(atPath: testPath())
        XCTAssertFalse(existingFiles.isEmpty, "File created. Caching works.")
        
        try cache.empty()
        let folderContents = try FileManager.default.contentsOfDirectory(atPath: testPath())
        XCTAssertTrue(folderContents.isEmpty, "cache.empty() should empty all the cache contents")
    }
    
    func testAvailableMegabytes() throws {
        let before = try? cache.availableMegabytes()
        let old = try XCTUnwrap(before)
        let prettyLargeString = String(repeating: "A", count: 100_000)
        
        cache.setValue(prettyLargeString, for: "someKey")
        let after = try? cache.availableMegabytes()
        
        let new = try XCTUnwrap(after)
        print("before \(old)\nafter: \(new)")
        XCTAssert(old > new, "availableMegabytes() will be smaller when things are added to the cache")
    }
}

extension MagiCacheTests {
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
