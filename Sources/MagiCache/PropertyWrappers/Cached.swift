//
//  Cached.swift
//
//  The idea here is to provide a very ‘Swifty’ interface by taking advantage of Swift’s propertyWrapper feature
//
//  Created by Michael Critz on 7/29/21.
//

/// **Cached property wrapper convenience**
/// This quality of life improvement allows developers to easily cache properties with the following syntax.
/// This initializes an empty, but MagiCache-backed property:
/// `@Cached<String>(key: "greeting") var hello`
/// This format initializes a MagiCache-backed property with an initial value
/// `@Cached<Int>(key: "meaningOfLife", value: 42) var meaningOfLife`
@propertyWrapper public struct Cached<T: Codable> {
    let key: String
    var storage = try? MagiCache<T>(identifier: "default")

    public var wrappedValue: T? {
        get {
            storage?.value(for: key)
        }
        set {
            storage?.setValue(newValue, for: key)
        }
    }
    
    public init(key: String, value: T? = nil) {
        self.key = key
        self.wrappedValue = value
    }
}
