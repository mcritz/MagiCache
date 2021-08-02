# MagiCache

## Darwin platforms cache framework

### Features

Features are under test. Try running tests in Xcode or using `swift test`. 

- [x] Can be initialized with a maximum allowed size
    - Max size is a "Must" requirement in this implementation, but can be circumvented by passing `Int.max` to the initializer.
- [x] If a new item would cause the cache to exceed the allowed size, it should remove the least recently used elements until space is available
    - In addition, the entire cache can be cleared with `.empty()`
- [x] It should survive app restart
    - MagiCache relies on the `Caches` directory per the best practices and "should" survive a restart. But the 
- [x] It should support iOS, tvOS at least
    - ✅ 📱 iOS
    - ✅ 📺 tvOS
    - ✅ 💻 macOS
    - ✅ ⌚️ watchOS
    - ✅ ☁️ linux
    - ❔ 🪟 Windows. Unknown: but [should work](https://swift.org/download/#releases)
    - MagiCache only relies on Foundation, so it’s really versatile
- [x] It should prevent other instances of the cache from modifying its tracked data, or recalculate the used size if other cache instances modify the data on disk
    - MagiCache avoids lots of internal bookkeeping and does most cache calculations on the fly. The files in the cache are the source of truth.
    
### PropertyWrapper

I authored `@Cached`: a Swift propertyWrapper for fun to allow developers to easily add cache-backed properties.

This initializes an empty, but MagiCache-backed property:
`@Cached<String>(key: "greeting") var hello`

 This format initializes a MagiCache-backed property with an initial value
`@Cached<Int>(key: "meaningOfLife", value: 42) var meaningOfLife`

 A powerful use case would be to just cache bytes themselves wrapped in `Data`
`@Cached<Data>(key: "myPrecious") var theOneRing`


### Feature Ideas

1.  Check during  `MagiCache.init`  if there’s enough free space on disk to create the cache. Something like this…

    ```
    guard let free = try? FileManager.default
            .attributesOfFileSystem(forPath: self.cacheDirectory.path)[.systemFreeSize] as? Double,
          desiredCacheSize < (free / 1024)  else {
        /// Handle appropriately
    }
    ```

2. Use Swift Logging

    This is a good idea if MagiCache were to get more complex or to be used in production where we’d want to introspect performance. https://github.com/apple/swift-log

3. Support streaming & async

    In an effort to avoid over-engineering I didn’t create `OutputSeam` API nor a server-side `SwiftNIO` competent streaming cache handler that can handle streaming `ByteBuffers`. Likewise, the spec didn’t seem to imply much need to support custom operations for removing or copying files that might justify the use of a custom `FileManagerDelegate` nor any type of `async` based concurrency.

4. Support compression

    This could be a lot of fun and have some real benefits. https://developer.apple.com/documentation/compression
