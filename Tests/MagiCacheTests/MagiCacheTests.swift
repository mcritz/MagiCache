import XCTest
@testable import MagiCache

final class MagiCacheTests: XCTestCase {
    
    var cache: MagiCache<String>!
    
    override func setUpWithError() throws { cache = MagiCache() }
    override func tearDownWithError() throws { cache = nil }
    
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
}
