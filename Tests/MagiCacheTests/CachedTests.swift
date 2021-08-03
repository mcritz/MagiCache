import XCTest
@testable import MagiCache

final class CachedTests: XCTestCase {
    
    struct PresidentCat {
        @Cached<Int>(key: "cat-age") var age
        @Cached<String>(key: "doesnt-answer-to") var name
        @Cached<Int>(key: "lives", value: 9) var lives
        @Cached<Bool>(key: "current-neurosis", value: Bool.random()) var isHappy
        
        var attitude: String {
            guard let isHappy = isHappy else {
                XCTFail("The only way this should fail is a disk hardware failure")
                return "Rwowrer!"
            }
            return isHappy ? "Purr" : "Hiss!"
        }
    }
    
    func testCachePropetyWrapper() throws {
        let catName = "Purrack"
        let catAge = 7
        var georgeScratchington = PresidentCat()
        georgeScratchington.name = catName
        georgeScratchington.age = catAge
        
        
        let testCache = try MagiCache()
        
        let storedAge = try XCTUnwrap(testCache.value(Int.self, for: "cat-age"))
        XCTAssertEqual(catAge, storedAge, "Cached values can be retrieved outside of the Type & propertyWrapper")
        
        let newAge = 8
        georgeScratchington.age = newAge
        let storedAgeAltered = try XCTUnwrap(testCache.value(Int.self, for: "cat-age"))
        XCTAssertEqual(newAge, storedAgeAltered, "Altering an @Cached property will modify its cached value")

        XCTAssertNotNil(georgeScratchington.isHappy, "Cached values with defaults can be retrieved")
    }
}
