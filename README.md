# MagiCache

## Darwin platforms cache framework

### Features

- [x] Can be initialized with a maximum allowed size
- [x] If a new item would cause the cache to exceed the allowed size, it should remove the least recently used elements until space is available
- [x] It should survive app restart
- [x] It should support iOS, tvOS at least
- [ ] It should prevent other instances of the cache from modifying its tracked data, or recalculate the used size if other cache instances modify the data on disk

### Ideas

1.  Check at  `MagiCache.init`  if there’s enough free space on disk to create the cache. Something like this…
```
guard let free = try? FileManager.default
        .attributesOfFileSystem(forPath: self.cacheDirectory.path)[.systemFreeSize] as? Double,
      desiredCacheSize < (free / 1024)  else {
    /// Handle appropriately
}
```

