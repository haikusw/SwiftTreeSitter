[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]

# SwiftTreeSitter

Swift wrappers for the [tree-sitter](https://tree-sitter.github.io/) incremental parsing system.

## Integration

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ChimeHQ/SwiftTreeSitter")
]
```

## Predicate Support

| Predicate | Readable | Supported |
| ----------|:--------:|:---------:|
| `eq?` | yes | yes |
| `match?`  | yes | yes |
| `is-not?`  | `local` only | no |

Query predicates are complex to support and have performance implications. Notably, `is-not? local` is **just** supported enough to be correctly read, but is not applied. Please open up an issue if you need additional support here.

## Runtime/Parser Dependencies

Remember that tree-sitter has both runtime and per-language dependencies. SwiftTreeSitter now depends on [tree-sitter-xcframework](https://github.com/krzyzanowskim/tree-sitter-xcframework), which provides pre-built binaries for the runtime and **some** parsers. If you need support for parsers not included in that project, the best best is to try to add them!

But, that is not necessary - you can build and link parsers manually.

Note: These instructions assume a macOS target. Also, I've only tested tree-sitter down to 10.13. I suspect it will work with lower targets, but have not tried.

### build

Check out and build tree-sitter from source. 

    CFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" CXXFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" LDFLAGS="-arch arm64 -arch x86_64 -mmacosx-version-min=10.13" make

### install

Install it into `/usr/local`.

    sudo make install PREFIX=/usr/local

## Building Language Libraries

In addition to the runtime, you'll probably also want at least one language library. These are more complex to build than the runtime. In fact, I've struggled with them so much that I began adapting the runtime's Makefile for the parsers themselves. This is a [work-in-progress](https://github.com/tree-sitter/tree-sitter/issues/1488). But, if the parser you'd like to use doesn't have a Makefile, let me know and I'll help get it set up.

And, if the parser does have a Makefile, then the process is identical to the runtime above.

## Suggestions or Feedback

We'd love to hear from you! Get in touch via [twitter](https://twitter.com/chimehq), an issue, or a pull request.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

[build status]: https://github.com/ChimeHQ/SwiftTreeSitter/actions
[build status badge]: https://github.com/ChimeHQ/SwiftTreeSitter/workflows/CI/badge.svg
[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/SwiftTreeSitter
[platforms]: https://swiftpackageindex.com/ChimeHQ/SwiftTreeSitter
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FSwiftTreeSitter%2Fbadge%3Ftype%3Dplatforms
