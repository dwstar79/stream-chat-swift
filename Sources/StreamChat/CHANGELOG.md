# StreamChat iOS SDK Changelog
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

# Unreleased

### 🐞 Fixed
 - Fix development token not working properly [#760](https://github.com/GetStream/stream-chat-swift/pull/760)


# [3.0](https://github.com/GetStream/stream-chat-swift/releases/tag/3.0)
_January 22nd, 2021_

## StreamChat SDK reaches another milestone with version 3.0 🎉  

### New features:

* **Offline support**: Browse channels and send messages while offline.
* **First-class support for `SwiftUI` and `Combine`**: Built-it wrappers make using the SDK with the latest Apple frameworks a seamless experience.
* **Uses `UIKit` patterns and paradigms:** The API follows the design of native system SDKs. It makes integration with your existing code easy and familiar.
* Currently, 3.0 version is available only using CocoaPods. We will add support for SPM soon.

To use the new version of the framework, add to your `Podfile`:
```ruby
pod 'StreamChat', '~> 3.0'
```

### ⚠️ Breaking Changes ⚠️

In order to provide new features like offline support and `SwiftUI` wrappers, we had to make notable breaking changes to the public API of the SDKs. 

**Please don't upgrade to version `3.0` before you get familiar with the changes and their impact on your codebase.**

To prevent CocoaPods from updating `StreamChat` to version 3, you can explicitly pin the SDKs to versions `2.x` in your `podfile`:
```ruby
pod 'StreamChat', '~> 2.0'
pod 'StreamChatCore', '~> 2.0' # if needed
pod 'StreamChatClient', '~> 2.0' # if needed
```

The framework naming and overall structure were changed. Since version 3.0, Stream Chat iOS SDK consists of:

#### `StreamChat` framework

Contains low-level logic and is meant to be used by users who want to build a fully custom UI. It covers functionality previously provided by `StreamChatCore` and `StreamChatClient`.

#### `StreamChat UI` framework _(currently in public beta)_

Contains a complete set of ready-to-use configurable UI elements that you can customize a use for building your own chat UI. It covers functionality previously provided by `StreamChat`.

### Sample App

The best way to explore the SDKs and their usage is our [sample app](https://github.com/GetStream/stream-chat-swift/tree/main/Sample). It contains an example implementation of a simple IRC-style chat app using the following patterns:

* `UIKit` using delegates
* `UIKit` using reactive patterns and SDK's built-in `Combine` wrappers.
* `SwiftUI` using the SDK's built-in `ObservableObject` wrappers.
* Learn more about the sample app at its own [README](https://github.com/GetStream/stream-chat-swift/tree/main/Sample).

### Documentation Quick Links

- [**Cheat Sheet**](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet) Real-world code examples showcasing the usage of the SDK.
- [**Controller Overview**](https://github.com/GetStream/stream-chat-swift/wiki/Controllers-Overview) This page contains a list of all available controllers within StreamChat, including their short description and typical use-cases.
- [**Glossary**](https://github.com/GetStream/stream-chat-swift/wiki/Glossary) A list of names and terms used in the framework and documentation.