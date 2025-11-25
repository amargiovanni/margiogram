# Margiogram - AI Agents Guide

> **Last Updated**: November 2025
> **Recommended Models**:
> - Default: `claude-sonnet-4-5-20250929`
> - Complex tasks: `claude-opus-4-5-20251101`
> - Quick tasks: `claude-haiku-3-5-20250120`

Guida per coordinare agenti AI (Claude, Copilot, altri) nello sviluppo di Margiogram.

---

## Panoramica Progetto

**Margiogram** è un client Telegram nativo per macOS e iOS con design Liquid Glass.

| Aspetto | Dettaglio |
|---------|-----------|
| Linguaggio | Swift 6.0+ |
| UI Framework | SwiftUI |
| Piattaforme | iOS 26+, macOS 26+ |
| Backend | TDLib (Telegram Database Library) |
| Database | SwiftData |
| Architettura | MVVM + Clean Architecture |
| Concurrency | Swift 6 strict concurrency |
| Xcode | 17.0+ |

---

## Principi di Sviluppo

### 1. Qualità del Codice

```
PRIORITÀ: Sicurezza > Performance > Leggibilità > Brevità
```

- **Type Safety**: Usare sempre tipi forti, evitare `Any` e `AnyObject`
- **Optionals**: Gestire sempre in modo esplicito, mai usare `!` eccetto `@IBOutlet`
- **Error Handling**: Usare `Result` type o `async throws`, mai silenziare errori
- **Concurrency**: Preferire `async/await` e `Actor` a GCD (Swift 6 strict concurrency)
- **Memory**: Attenzione ai retain cycle, usare `[weak self]` dove necessario

### 2. Naming Conventions

```swift
// Classi/Struct/Enum: PascalCase
struct MessageBubble { }
enum ChatType { }

// Variabili/Funzioni: camelCase
let messageCount: Int
func sendMessage() { }

// Costanti globali: camelCase con prefisso
let kMaxMessageLength = 4096

// Protocolli: aggettivi o sostantivi con suffisso
protocol Sendable { }
protocol MessageProviding { }

// Generics: singola lettera maiuscola o nome descrittivo
func process<T: Codable>(_ item: T) { }
func fetch<Element: Identifiable>(items: [Element]) { }
```

### 3. Struttura File

```swift
// MARK: - Imports (ordinati alfabeticamente, system first)
import Foundation
import SwiftUI

import TDLibKit  // Third party dopo

// MARK: - Protocols

protocol ViewModelProtocol { }

// MARK: - Main Type

struct MyView: View {
    // MARK: - Constants

    private enum Constants {
        static let padding: CGFloat = 16
    }

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var isLoading = false
    @StateObject private var viewModel: MyViewModel

    // MARK: - Properties

    let title: String

    // MARK: - Body

    var body: some View {
        // ...
    }

    // MARK: - Subviews

    private var headerView: some View {
        // ...
    }

    // MARK: - Methods

    private func loadData() async {
        // ...
    }
}

// MARK: - Previews

#Preview {
    MyView(title: "Test")
}
```

---

## Architettura

### Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Views     │  │ ViewModels  │  │    UI Components    │  │
│  │  (SwiftUI)  │  │ (@Observable)│  │   (Liquid Glass)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Use Cases  │  │   Models    │  │    Repositories     │  │
│  │             │  │  (Entities) │  │    (Protocols)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   TDLib     │  │  SwiftData  │  │     Keychain        │  │
│  │   Client    │  │   Storage   │  │     Services        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Dependency Flow

```
View → ViewModel → UseCase → Repository → DataSource
                                ↓
                           TDLib / SwiftData
```

### Esempio Implementazione

```swift
// MARK: - Domain Layer

// Entity
struct Message: Identifiable, Equatable {
    let id: Int64
    let chatId: Int64
    let content: MessageContent
    let date: Date
    let senderId: Int64
}

// Repository Protocol
protocol MessageRepository {
    func getMessages(chatId: Int64, limit: Int) async throws -> [Message]
    func sendMessage(chatId: Int64, content: MessageContent) async throws -> Message
    func deleteMessage(chatId: Int64, messageId: Int64) async throws
}

// Use Case
final class SendMessageUseCase {
    private let repository: MessageRepository
    private let validator: MessageValidator

    init(repository: MessageRepository, validator: MessageValidator = .init()) {
        self.repository = repository
        self.validator = validator
    }

    func execute(chatId: Int64, text: String) async throws -> Message {
        guard validator.isValid(text) else {
            throw MessageError.invalidContent
        }

        return try await repository.sendMessage(
            chatId: chatId,
            content: .text(text)
        )
    }
}

// MARK: - Data Layer

// Repository Implementation
final class TDLibMessageRepository: MessageRepository {
    private let client: TDLibClient

    init(client: TDLibClient) {
        self.client = client
    }

    func getMessages(chatId: Int64, limit: Int) async throws -> [Message] {
        let response = try await client.send(GetChatHistory(
            chatId: chatId,
            fromMessageId: 0,
            offset: 0,
            limit: Int32(limit),
            onlyLocal: false
        ))

        return response.messages.map { Message(from: $0) }
    }

    func sendMessage(chatId: Int64, content: MessageContent) async throws -> Message {
        let response = try await client.send(SendMessage(
            chatId: chatId,
            inputMessageContent: content.toInput()
        ))

        return Message(from: response)
    }

    func deleteMessage(chatId: Int64, messageId: Int64) async throws {
        try await client.send(DeleteMessages(
            chatId: chatId,
            messageIds: [messageId],
            revoke: true
        ))
    }
}

// MARK: - Presentation Layer

@Observable
final class ConversationViewModel {
    private(set) var messages: [Message] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let getMessagesUseCase: GetMessagesUseCase
    private let sendMessageUseCase: SendMessageUseCase

    init(
        getMessagesUseCase: GetMessagesUseCase,
        sendMessageUseCase: SendMessageUseCase
    ) {
        self.getMessagesUseCase = getMessagesUseCase
        self.sendMessageUseCase = sendMessageUseCase
    }

    @MainActor
    func loadMessages(chatId: Int64) async {
        isLoading = true
        defer { isLoading = false }

        do {
            messages = try await getMessagesUseCase.execute(chatId: chatId)
        } catch {
            self.error = error
        }
    }

    @MainActor
    func sendMessage(chatId: Int64, text: String) async {
        do {
            let message = try await sendMessageUseCase.execute(chatId: chatId, text: text)
            messages.insert(message, at: 0)
        } catch {
            self.error = error
        }
    }
}
```

---

## Tasks per Agenti

### Task Types

```yaml
# Task semplice
- type: feature
  scope: single-file
  complexity: low
  example: "Aggiungi animazione fade al MessageBubble"

# Task medio
- type: feature
  scope: multi-file
  complexity: medium
  example: "Implementa ricerca messaggi in chat"

# Task complesso
- type: feature
  scope: module
  complexity: high
  example: "Implementa sistema chiamate audio"
```

### Template Task Request

```markdown
## Task: [Nome Task]

### Obiettivo
Descrizione chiara dell'obiettivo.

### Contesto
- File correlati: `path/to/files`
- Dipendenze: [lista dipendenze]
- Reference: [link documentazione]

### Requisiti
1. Requisito funzionale 1
2. Requisito funzionale 2
3. ...

### Vincoli
- Performance: [requisiti]
- Sicurezza: [requisiti]
- Compatibilità: [iOS/macOS versions]

### Criteri di Accettazione
- [ ] Test unitari passano
- [ ] Test UI passano
- [ ] Nessun warning compiler
- [ ] Code review approvata

### Note Aggiuntive
Informazioni extra utili.
```

---

## Workflow Sviluppo

### 1. Prima di Iniziare

```bash
# Verifica stato progetto
git status
git pull origin main

# Verifica build
xcodebuild -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Verifica test
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### 2. Durante lo Sviluppo

```swift
// SEMPRE:
// 1. Scrivi test PRIMA del codice (TDD quando possibile)
// 2. Usa SwiftLint
// 3. Documenta API pubbliche
// 4. Gestisci tutti gli error case

// ESEMPIO test-first:

// 1. Scrivi il test
func testSendMessage_WithValidText_ReturnsMessage() async throws {
    // Given
    let sut = makeSUT()
    let chatId: Int64 = 123

    // When
    let message = try await sut.sendMessage(chatId: chatId, text: "Hello")

    // Then
    XCTAssertEqual(message.chatId, chatId)
    XCTAssertEqual(message.content, .text("Hello"))
}

// 2. Implementa per far passare il test
// 3. Refactora se necessario
```

### 3. Code Review Checklist

```markdown
## Review Checklist

### Funzionalità
- [ ] Il codice fa quello che dovrebbe?
- [ ] Edge cases gestiti?
- [ ] Error handling appropriato?

### Codice
- [ ] Naming chiaro e consistente?
- [ ] Nessuna duplicazione?
- [ ] Complessità accettabile?
- [ ] SOLID principles rispettati?

### Performance
- [ ] Nessun memory leak potenziale?
- [ ] Operazioni costose su background thread?
- [ ] Lazy loading dove appropriato?

### Sicurezza
- [ ] Input validation presente?
- [ ] Nessun dato sensibile in log?
- [ ] Keychain per credenziali?

### Test
- [ ] Test unitari presenti?
- [ ] Test coverage adeguato?
- [ ] Test cases significativi?

### UI/UX
- [ ] Accessibilità supportata?
- [ ] Dark mode funziona?
- [ ] Animazioni smooth?
```

---

## Comandi Utili per Agenti

### Analisi Codebase

```bash
# Trova tutti i file Swift
find . -name "*.swift" -type f

# Conta linee di codice
find . -name "*.swift" | xargs wc -l

# Trova TODO/FIXME
grep -r "TODO\|FIXME" --include="*.swift" .

# Trova import non usati
# (usa SwiftLint con regola unused_import)

# Analizza dipendenze circolari
# (usa strumento come swift-dependency-graph)
```

### Testing

```bash
# Run tutti i test
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run test specifico
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MargiogramTests/MessageViewModelTests

# Run test con coverage
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -enableCodeCoverage YES

# Genera report coverage
xcrun xccov view --report Build/Logs/Test/*.xcresult
```

### Linting

```bash
# SwiftLint
swiftlint lint --strict

# SwiftLint autofix
swiftlint lint --fix

# SwiftFormat
swiftformat . --swiftversion 6.0
```

---

## Patterns da Usare

### 1. Dependency Injection

```swift
// PREFERITO: Constructor injection
final class MessageViewModel {
    private let repository: MessageRepository

    init(repository: MessageRepository) {
        self.repository = repository
    }
}

// Per SwiftUI
struct MessageView: View {
    @StateObject private var viewModel: MessageViewModel

    init(repository: MessageRepository = TDLibMessageRepository.shared) {
        _viewModel = StateObject(wrappedValue: MessageViewModel(repository: repository))
    }
}
```

### 2. Protocol-Oriented Design

```swift
// Definisci comportamento con protocolli
protocol Loadable {
    associatedtype Content
    var isLoading: Bool { get }
    var content: Content? { get }
    var error: Error? { get }

    func load() async
}

// Default implementation
extension Loadable {
    var hasContent: Bool { content != nil }
    var hasError: Bool { error != nil }
}

// Usa in ViewModels
@Observable
final class ChatListViewModel: Loadable {
    typealias Content = [Chat]

    private(set) var isLoading = false
    private(set) var content: [Chat]?
    private(set) var error: Error?

    func load() async {
        // ...
    }
}
```

### 3. Result Builder per UI

```swift
// Custom result builder per conditional views
@resultBuilder
struct ConditionalViewBuilder {
    static func buildBlock<V: View>(_ component: V) -> V { component }

    static func buildEither<TrueContent: View, FalseContent: View>(
        first component: TrueContent
    ) -> _ConditionalContent<TrueContent, FalseContent> {
        .init(first: component)
    }

    static func buildEither<TrueContent: View, FalseContent: View>(
        second component: FalseContent
    ) -> _ConditionalContent<TrueContent, FalseContent> {
        .init(second: component)
    }
}
```

### 4. Async Sequence per Updates

```swift
// Stream di updates da TDLib
extension TDLibClient {
    var messageUpdates: AsyncStream<Message> {
        AsyncStream { continuation in
            Task {
                for await update in self.updates {
                    if case .updateNewMessage(let newMessage) = update {
                        continuation.yield(Message(from: newMessage.message))
                    }
                }
            }
        }
    }
}

// Uso nel ViewModel
func observeNewMessages(chatId: Int64) {
    Task {
        for await message in client.messageUpdates where message.chatId == chatId {
            await MainActor.run {
                messages.insert(message, at: 0)
            }
        }
    }
}
```

---

## Anti-Patterns da Evitare

### 1. Force Unwrap

```swift
// ❌ MALE
let user = users.first!
let name = json["name"] as! String

// ✅ BENE
guard let user = users.first else { return }
guard let name = json["name"] as? String else {
    throw ParsingError.missingField("name")
}
```

### 2. Massive View/ViewModel

```swift
// ❌ MALE - ViewModel con troppe responsabilità
class ChatViewModel {
    func loadChats() { }
    func sendMessage() { }
    func deleteMessage() { }
    func loadContacts() { }
    func blockUser() { }
    func uploadPhoto() { }
    // ... 50 altre funzioni
}

// ✅ BENE - Separazione responsabilità
class ChatListViewModel { func loadChats() { } }
class ConversationViewModel { func sendMessage() { } func deleteMessage() { } }
class ContactsViewModel { func loadContacts() { } func blockUser() { } }
class MediaViewModel { func uploadPhoto() { } }
```

### 3. Callback Hell

```swift
// ❌ MALE
func loadData(completion: @escaping (Result<Data, Error>) -> Void) {
    fetchUser { userResult in
        switch userResult {
        case .success(let user):
            fetchChats(for: user) { chatsResult in
                switch chatsResult {
                case .success(let chats):
                    fetchMessages(for: chats.first!) { messagesResult in
                        // ... ancora più nesting
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

// ✅ BENE - Async/await
func loadData() async throws -> Data {
    let user = try await fetchUser()
    let chats = try await fetchChats(for: user)
    guard let firstChat = chats.first else {
        throw AppError.noChats
    }
    let messages = try await fetchMessages(for: firstChat)
    return messages
}
```

### 4. God Objects

```swift
// ❌ MALE - Singleton che fa tutto
class AppManager {
    static let shared = AppManager()
    var currentUser: User?
    var chats: [Chat] = []
    var settings: Settings = .default

    func login() { }
    func logout() { }
    func sendMessage() { }
    func fetchChats() { }
    // ... tutto il resto
}

// ✅ BENE - Servizi separati
class AuthService { }
class ChatService { }
class SettingsService { }
```

---

## Sicurezza

### Checklist Sicurezza

```markdown
## Security Checklist

### Autenticazione
- [ ] Token salvati in Keychain
- [ ] Session timeout implementato
- [ ] Biometric authentication disponibile

### Dati
- [ ] Encryption at rest per dati sensibili
- [ ] No PII in logs
- [ ] Secure delete implementato

### Rete
- [ ] Certificate pinning per TDLib
- [ ] No HTTP (solo HTTPS)
- [ ] Timeout appropriati

### Input Validation
- [ ] Tutti gli input utente validati
- [ ] SQL injection prevention (SwiftData parametrizzato)
- [ ] XSS prevention in WebView

### Code
- [ ] No hardcoded secrets
- [ ] No debug code in produzione
- [ ] Obfuscation per release build
```

### Esempio Secure Storage

```swift
import Security

final class KeychainService {
    enum Key: String {
        case authToken
        case userId
        case encryptionKey
    }

    func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing
        SecItemDelete(query as CFDictionary)

        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func get(_ key: Key) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.readFailed(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    func delete(_ key: Key) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
```

---

## Performance

### Guidelines

```swift
// 1. Lazy loading
struct ChatListView: View {
    var body: some View {
        LazyVStack {  // Non VStack per liste lunghe
            ForEach(chats) { chat in
                ChatRow(chat: chat)
            }
        }
    }
}

// 2. Image caching
actor ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()

    func image(for url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }

        cache.setObject(image, forKey: key)
        return image
    }
}

// 3. Debouncing
extension Publisher {
    func debounceSearch() -> some Publisher<Output, Failure> {
        self.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    }
}

// 4. Background processing
func processLargeData(_ data: Data) async -> ProcessedData {
    await Task.detached(priority: .background) {
        // Heavy computation
    }.value
}
```

### Profiling Commands

```bash
# Instruments - Time Profiler
xcrun xctrace record --template 'Time Profiler' --launch -- ./Margiogram.app

# Instruments - Allocations
xcrun xctrace record --template 'Allocations' --launch -- ./Margiogram.app

# Memory Graph
# In Xcode: Debug > View Memory Graph Hierarchy
```

---

## Risorse

### Documentazione

- [TDLib Documentation](https://core.telegram.org/tdlib)
- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Tools

- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [Periphery](https://github.com/peripheryapp/periphery) - Dead code detection

### References

- [Telegram API](https://core.telegram.org/api)
- [MTProto](https://core.telegram.org/mtproto)
- [TDLib JSON Interface](https://core.telegram.org/tdlib/docs/)
