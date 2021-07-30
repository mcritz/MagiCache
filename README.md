# MagiCache

## Darwin platforms cache framework

### Features

- [x] Can be initialized with a maximum allowed size
- [ ] If a new item would cause the cache to exceed the allowed size, it should remove the least recently used elements until space is available
- [ ] It should survive app restart
- [ ] It should support iOS, tvOS at least
- [ ] It should prevent other instances of the cache from modifying its tracked data, or recalculate the used size if other cache instances modify the data on disk
