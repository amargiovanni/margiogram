# Docs Command

Genera e gestisci la documentazione del progetto.

## Utilizzo

```
/docs [generate|update|api] [target]
```

## Tipi di Documentazione

### 1. API Documentation (DocC)

Swift Documentation Comments per API pubbliche:

```swift
/// A view that displays a chat conversation with messages.
///
/// Use `ConversationView` to present a full chat interface including:
/// - Message list with auto-scrolling
/// - Input bar for composing messages
/// - Media attachment support
///
/// ## Overview
///
/// The conversation view automatically loads messages when appearing
/// and subscribes to real-time updates.
///
/// ```swift
/// ConversationView(chat: selectedChat)
///     .navigationTitle(chat.title)
/// ```
///
/// ## Topics
///
/// ### Creating a Conversation View
/// - ``init(chat:)``
/// - ``init(chatId:)``
///
/// ### Customizing Appearance
/// - ``showsTimestamps``
/// - ``bubbleStyle``
///
/// - Note: Requires an authenticated user session.
/// - Warning: Large conversations may impact memory usage.
/// - SeeAlso: ``ChatListView``, ``Message``
struct ConversationView: View {
    /// Creates a conversation view for the specified chat.
    ///
    /// - Parameter chat: The chat to display.
    /// - Returns: A configured conversation view.
    init(chat: Chat) {
        // ...
    }
}
```

### 2. Function Documentation

```swift
/// Sends a text message to the specified chat.
///
/// This method validates the message content before sending and handles
/// network failures with automatic retry.
///
/// - Parameters:
///   - chatId: The unique identifier of the target chat.
///   - text: The message content. Must not be empty and cannot exceed 4096 characters.
///   - replyTo: Optional message ID to reply to.
///
/// - Returns: The sent message with server-assigned ID and timestamp.
///
/// - Throws:
///   - `MessageError.emptyContent` if text is empty.
///   - `MessageError.tooLong` if text exceeds 4096 characters.
///   - `NetworkError.noConnection` if offline.
///
/// - Complexity: O(1) for local validation, O(n) for network round-trip.
///
/// ## Example
///
/// ```swift
/// let message = try await sendMessage(
///     chatId: 123456,
///     text: "Hello, World!",
///     replyTo: nil
/// )
/// print("Sent message: \(message.id)")
/// ```
///
/// - Important: Messages are end-to-end encrypted in secret chats.
/// - Precondition: User must be authenticated.
func sendMessage(
    chatId: Int64,
    text: String,
    replyTo: Int64? = nil
) async throws -> Message {
    // ...
}
```

### 3. Type Documentation

```swift
/// A message in a Telegram chat.
///
/// Messages can contain various types of content including text, media,
/// stickers, and more. Each message has a unique identifier and timestamp.
///
/// ## Topics
///
/// ### Identifying Messages
/// - ``id``
/// - ``chatId``
/// - ``senderId``
///
/// ### Content
/// - ``content``
/// - ``MessageContent``
///
/// ### Metadata
/// - ``date``
/// - ``isOutgoing``
/// - ``isRead``
struct Message: Identifiable, Equatable, Sendable {
    /// The unique identifier for this message.
    ///
    /// Message IDs are unique within a chat but may be reused across
    /// different chats.
    let id: Int64

    /// The chat this message belongs to.
    let chatId: Int64

    /// The content of the message.
    ///
    /// - SeeAlso: ``MessageContent``
    let content: MessageContent

    /// The date when this message was sent.
    let date: Date

    /// Whether this message was sent by the current user.
    let isOutgoing: Bool
}

/// The content of a message.
///
/// Messages can contain different types of content. Use pattern matching
/// to handle each content type appropriately.
///
/// ```swift
/// switch message.content {
/// case .text(let text):
///     print("Text: \(text)")
/// case .photo(let photo):
///     displayImage(photo)
/// default:
///     print("Unsupported content")
/// }
/// ```
enum MessageContent {
    /// A text message with optional formatting.
    case text(String)

    /// A photo with optional caption.
    case photo(Photo)

    /// A video with optional caption.
    case video(Video)

    /// A voice message.
    case voice(VoiceNote)

    /// A sticker.
    case sticker(Sticker)
}
```

### 4. Protocol Documentation

```swift
/// A type that can provide messages for a chat.
///
/// Implement this protocol to create custom message sources,
/// such as local caches or mock data for testing.
///
/// ## Conforming to MessageProviding
///
/// To conform to `MessageProviding`, implement the required methods
/// for loading and observing messages:
///
/// ```swift
/// class MockMessageProvider: MessageProviding {
///     func getMessages(chatId: Int64, limit: Int) async throws -> [Message] {
///         return [Message.mock(), Message.mock()]
///     }
///
///     var messageUpdates: AsyncStream<Message> {
///         AsyncStream { continuation in
///             // Yield mock updates
///         }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Loading Messages
/// - ``getMessages(chatId:limit:)``
/// - ``getMessage(chatId:messageId:)``
///
/// ### Observing Updates
/// - ``messageUpdates``
protocol MessageProviding {
    /// Loads messages for the specified chat.
    ///
    /// - Parameters:
    ///   - chatId: The chat to load messages from.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: An array of messages, newest first.
    func getMessages(chatId: Int64, limit: Int) async throws -> [Message]

    /// A stream of new messages as they arrive.
    var messageUpdates: AsyncStream<Message> { get }
}
```

## README Template

```markdown
# [Component/Feature Name]

Brief description of what this component does.

## Overview

More detailed explanation of the component's purpose and functionality.

## Installation

### Requirements
- iOS 17.0+
- macOS 14.0+
- Xcode 15.0+

### Swift Package Manager

```swift
dependencies: [
    .package(url: "...", from: "1.0.0")
]
```

## Usage

### Basic Usage

```swift
// Code example
```

### Advanced Usage

```swift
// More complex example
```

## Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `property1` | `String` | `""` | Description |
| `property2` | `Bool` | `true` | Description |

## Examples

### Example 1: Simple Case

```swift
// Example code
```

### Example 2: Complex Case

```swift
// Example code
```

## API Reference

See [API Documentation](./docs/api.md) for full reference.

## Contributing

See [Contributing Guidelines](./CONTRIBUTING.md).

## License

MIT License - see [LICENSE](./LICENSE) for details.
```

## Architecture Documentation

```markdown
# Architecture Overview

## Layer Structure

```
┌─────────────────────────────────────────────────┐
│                 Presentation                     │
│  Views, ViewModels, UI Components               │
├─────────────────────────────────────────────────┤
│                    Domain                        │
│  Entities, Use Cases, Repository Protocols      │
├─────────────────────────────────────────────────┤
│                     Data                         │
│  Repository Impls, Data Sources, Mappers        │
└─────────────────────────────────────────────────┘
```

## Data Flow

```
User Action → View → ViewModel → UseCase → Repository → DataSource
                                    ↓
                                 TDLib/SwiftData
```

## Key Components

### TDLibClient
Manages communication with Telegram servers.

### DataController
Handles local data persistence with SwiftData.

### AuthenticationManager
Manages user authentication state.

## Design Decisions

### Why MVVM?
- Clean separation of concerns
- Testable ViewModels
- SwiftUI compatible

### Why TDLib?
- Official Telegram library
- Handles all protocol complexity
- Automatic updates and caching
```

## Changelog Template

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description

### Changed
- Changed feature description

### Deprecated
- Deprecated feature description

### Removed
- Removed feature description

### Fixed
- Bug fix description

### Security
- Security fix description

## [1.0.0] - 2024-01-15

### Added
- Initial release
- Chat list view
- Conversation view
- Message sending
- Media support
```

## API Documentation Generator

```bash
#!/bin/bash
# Generate DocC documentation

# Build documentation
xcodebuild docbuild \
    -scheme Margiogram \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -derivedDataPath ./DerivedData

# Export documentation
$(xcrun --find docc) process-archive \
    transform-for-static-hosting \
    ./DerivedData/Build/Products/Debug-iphonesimulator/Margiogram.doccarchive \
    --output-path ./docs

# Serve locally
python3 -m http.server 8000 --directory ./docs
```

## Documentation Checklist

### For Every Public API
- [ ] One-line summary
- [ ] Detailed description (if complex)
- [ ] Parameter descriptions
- [ ] Return value description
- [ ] Throws documentation
- [ ] Code example
- [ ] Related symbols (SeeAlso)

### For Every Module
- [ ] README with overview
- [ ] Architecture diagram
- [ ] Getting started guide
- [ ] API reference

### For Project
- [ ] Main README
- [ ] CONTRIBUTING guide
- [ ] CHANGELOG
- [ ] LICENSE
- [ ] Architecture documentation
