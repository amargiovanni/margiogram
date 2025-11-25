# CLAUDE.md - Margiogram Project Context

> **Last Updated**: November 2025
> **Recommended Model**: `claude-sonnet-4-5-20250929` (default), `claude-opus-4-5-20251101` (complex tasks)

Questo file fornisce a Claude Code tutto il contesto necessario per sviluppare Margiogram in modo efficace, sicuro e di alta qualità.

---

## Identità Progetto

```yaml
name: Margiogram
type: Telegram Client
platforms:
  - iOS 26+
  - macOS 26+
language: Swift 6.0+
ui_framework: SwiftUI
design_system: Liquid Glass (iOS 26 style)
architecture: MVVM + Clean Architecture
backend: TDLib (Telegram Database Library)
database: SwiftData
concurrency: Swift 6 strict concurrency
xcode: 17.0+
```

---

## Obiettivi Chiave

### Must Have
1. **Client Telegram completamente funzionale** - Tutte le feature disponibili per account free
2. **Design Liquid Glass** - Interfaccia moderna con effetti glass, blur e trasparenze
3. **Cross-platform perfetto** - UI che scala da iPhone a Mac senza compromessi
4. **Performance eccellente** - 60fps, startup < 1s, reattività immediata
5. **Sicurezza robusta** - Encryption, Keychain, biometrics, secure storage

### Nice to Have
- Widget iOS/macOS
- Siri Shortcuts
- Apple Watch companion
- SharePlay integration

---

## Regole di Sviluppo

### Codice Swift

```swift
// ✅ SEMPRE FARE

// 1. Usare async/await per operazioni asincrone
func loadMessages() async throws -> [Message] {
    try await repository.getMessages(chatId: chatId)
}

// 2. Gestire errori esplicitamente
do {
    let result = try await operation()
} catch {
    logger.error("Operation failed: \(error)")
    throw error
}

// 3. Usare guard per early exit
guard let user = currentUser else {
    return
}

// 4. Preferire struct a class quando possibile
struct Message: Identifiable, Equatable {
    let id: Int64
    let content: String
}

// 5. Usare @Observable per ViewModels (iOS 26+)
@Observable
final class ChatViewModel {
    var messages: [Message] = []
}

// 6. Swift 6 strict concurrency con actors
actor DataManager {
    private var cache: [String: Data] = [:]

    func getData(for key: String) -> Data? {
        cache[key]
    }
}

// 7. Usare weak self in closure che potrebbero causare retain cycle
Task { [weak self] in
    await self?.loadData()
}

// 8. Separare logica UI dalla business logic
// View -> ViewModel -> UseCase -> Repository -> DataSource

// 9. Sfruttare iOS 26 APIs
// - Liquid Glass materials
// - New animation system
// - Enhanced concurrency
```

```swift
// ❌ MAI FARE

// 1. Force unwrap
let value = optional! // NO!

// 2. Ignorare errori
try? riskyOperation() // NO! Gestisci l'errore

// 3. Usare singleton ovunque
AppManager.shared.doEverything() // NO!

// 4. Blocking main thread
DispatchQueue.main.sync { } // NO!

// 5. Hardcodare valori
let apiKey = "abc123" // NO! Usa Config o Keychain

// 6. Usare Any/AnyObject
func process(_ value: Any) // NO! Usa generics o protocolli

// 7. Lasciare print() in produzione
print("debug info") // NO! Usa Logger
```

### SwiftUI

```swift
// ✅ Pattern corretti

// 1. Estrarre subviews per leggibilità
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    // ...
}

// 2. Usare ViewModifiers per stili riutilizzabili
struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// 3. Usare @State con @Observable (iOS 26+ pattern)
@State private var viewModel = ChatViewModel()  // @Observable class

// 4. Usare .task per async work
.task {
    await viewModel.loadData()
}

// 5. Gestire stati di loading/error/empty
var body: some View {
    Group {
        if viewModel.isLoading {
            ProgressView()
        } else if let error = viewModel.error {
            ErrorView(error: error)
        } else if viewModel.items.isEmpty {
            EmptyStateView()
        } else {
            ContentView(items: viewModel.items)
        }
    }
}
```

---

## Struttura Progetto

```
Margiogram/
├── App/
│   ├── MargiogramApp.swift          # Entry point
│   ├── AppDelegate.swift            # App lifecycle
│   └── SceneDelegate.swift          # Scene management
│
├── Core/
│   ├── TDLib/
│   │   ├── TDLibClient.swift        # Main client wrapper
│   │   ├── TDLibManager.swift       # Connection management
│   │   ├── Updates/                 # Update handlers
│   │   └── Models/                  # TDLib model extensions
│   │
│   ├── Database/
│   │   ├── DataController.swift     # SwiftData setup
│   │   └── Models/                  # SwiftData entities
│   │
│   ├── Networking/
│   │   ├── NetworkMonitor.swift     # Connectivity
│   │   └── ImageLoader.swift        # Async image loading
│   │
│   └── Security/
│       ├── KeychainService.swift    # Secure storage
│       ├── BiometricAuth.swift      # Face ID / Touch ID
│       └── EncryptionService.swift  # Local encryption
│
├── Domain/
│   ├── Entities/                    # Business models
│   │   ├── Message.swift
│   │   ├── Chat.swift
│   │   ├── User.swift
│   │   └── ...
│   │
│   ├── Repositories/                # Repository protocols
│   │   ├── MessageRepository.swift
│   │   ├── ChatRepository.swift
│   │   └── ...
│   │
│   └── UseCases/                    # Business logic
│       ├── SendMessageUseCase.swift
│       ├── LoadChatsUseCase.swift
│       └── ...
│
├── Data/
│   ├── Repositories/                # Repository implementations
│   │   ├── TDLibMessageRepository.swift
│   │   ├── TDLibChatRepository.swift
│   │   └── ...
│   │
│   └── Mappers/                     # Entity mappers
│       ├── MessageMapper.swift
│       └── ...
│
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── CodeVerificationView.swift
│   │   │   └── TwoFactorAuthView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── ChatList/
│   │   ├── Views/
│   │   │   ├── ChatListView.swift
│   │   │   └── ChatListRow.swift
│   │   └── ViewModels/
│   │       └── ChatListViewModel.swift
│   │
│   ├── Conversation/
│   │   ├── Views/
│   │   │   ├── ConversationView.swift
│   │   │   ├── MessageBubble.swift
│   │   │   └── InputBar.swift
│   │   └── ViewModels/
│   │       └── ConversationViewModel.swift
│   │
│   ├── Contacts/
│   ├── Calls/
│   ├── Groups/
│   ├── Channels/
│   ├── Settings/
│   ├── Profile/
│   ├── Search/
│   ├── Media/
│   └── Stories/
│
├── UI/
│   ├── DesignSystem/
│   │   ├── LiquidGlass/
│   │   │   ├── LiquidGlassModifier.swift
│   │   │   ├── GlassButton.swift
│   │   │   └── GlassCard.swift
│   │   │
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   └── Spacing.swift
│   │
│   ├── Components/
│   │   ├── AvatarView.swift
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── EmptyStateView.swift
│   │
│   └── Modifiers/
│       ├── ShakeEffect.swift
│       └── PressEffect.swift
│
├── Extensions/
│   ├── View+Extensions.swift
│   ├── Date+Extensions.swift
│   ├── String+Extensions.swift
│   └── ...
│
├── Utilities/
│   ├── Logger.swift
│   ├── Formatters.swift
│   └── Constants.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable/
│   │   ├── en.lproj/
│   │   └── it.lproj/
│   └── Fonts/
│
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

---

## Design System: Liquid Glass

### Principi

1. **Trasparenza**: Elementi UI mostrano il contenuto sottostante con blur
2. **Profondità**: Ombre e bordi creano gerarchia visiva
3. **Fluidità**: Transizioni smooth tra stati
4. **Coerenza**: Stesso linguaggio visivo su iOS e macOS

### Colori

```swift
extension Color {
    // Primary
    static let primaryGlass = Color("PrimaryGlass")  // Accent con trasparenza
    static let secondaryGlass = Color("SecondaryGlass")

    // Backgrounds
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)

    // Text
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    // Semantic
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}
```

### Componenti Base

```swift
// Glass Container
struct GlassContainer<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Glass Button
struct GlassButton: View {
    let title: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}
```

---

## TDLib Integration

### Setup

TDLib è il cuore dell'app. Gestisce tutta la comunicazione con i server Telegram.

```swift
// TDLibClient.swift
actor TDLibClient {
    private var client: OpaquePointer?
    private var isRunning = false

    // Singleton per accesso globale
    static let shared = TDLibClient()

    private init() {
        client = td_json_client_create()
    }

    // Invia richiesta e attendi risposta
    func send<T: TDFunction>(_ function: T) async throws -> T.Result {
        guard let client = client else {
            throw TDLibError.clientNotInitialized
        }

        let requestId = UUID().uuidString
        var request = try function.encode()
        request["@extra"] = requestId

        let jsonData = try JSONSerialization.data(withJSONObject: request)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        td_json_client_send(client, jsonString)

        // Attendi risposta con matching @extra
        return try await waitForResponse(requestId: requestId)
    }

    // Stream di updates
    var updates: AsyncStream<TDUpdate> {
        AsyncStream { continuation in
            Task {
                while isRunning {
                    if let result = td_json_client_receive(client, 1.0) {
                        let json = String(cString: result)
                        if let update = parseUpdate(json) {
                            continuation.yield(update)
                        }
                    }
                }
                continuation.finish()
            }
        }
    }
}
```

### Autenticazione Flow

```
1. setTdlibParameters     → Configura TDLib
2. setAuthenticationPhoneNumber → Invia numero
3. [Server invia SMS]
4. checkAuthenticationCode → Verifica codice
5. [Se 2FA abilitato]
6. checkAuthenticationPassword → Verifica password
7. authorizationStateReady → Autenticato!
```

---

## Testing Strategy

### Unit Tests

```swift
// Test ViewModel
@MainActor
final class ChatListViewModelTests: XCTestCase {
    var sut: ChatListViewModel!
    var mockRepository: MockChatRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockChatRepository()
        sut = ChatListViewModel(repository: mockRepository)
    }

    func test_loadChats_success_updatesChats() async {
        // Given
        let expectedChats = [Chat.mock(), Chat.mock()]
        mockRepository.chatsToReturn = expectedChats

        // When
        await sut.loadChats()

        // Then
        XCTAssertEqual(sut.chats, expectedChats)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_loadChats_failure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.networkError

        // When
        await sut.loadChats()

        // Then
        XCTAssertTrue(sut.chats.isEmpty)
        XCTAssertNotNil(sut.error)
    }
}
```

### UI Tests

```swift
final class ChatListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func test_chatList_displaysChats() {
        // Given user is logged in (handled by launch arguments)

        // Then
        let chatList = app.collectionViews["chatList"]
        XCTAssertTrue(chatList.exists)
        XCTAssertGreaterThan(chatList.cells.count, 0)
    }

    func test_tapChat_opensConversation() {
        // Given
        let chatList = app.collectionViews["chatList"]
        let firstChat = chatList.cells.firstMatch

        // When
        firstChat.tap()

        // Then
        let messageInput = app.textFields["messageInput"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 2))
    }
}
```

---

## Error Handling

```swift
// Errori domain-specific
enum MargiogramError: LocalizedError {
    case networkUnavailable
    case authenticationFailed(reason: String)
    case messageNotSent(reason: String)
    case invalidInput(field: String)
    case storageError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .messageNotSent(let reason):
            return "Message not sent: \(reason)"
        case .invalidInput(let field):
            return "Invalid input for \(field)"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        }
    }
}

// Error handling in ViewModel
@Observable
final class ConversationViewModel {
    var error: MargiogramError?
    var showError = false

    func sendMessage(_ text: String) async {
        do {
            try await messageRepository.send(text, to: chatId)
        } catch let error as MargiogramError {
            self.error = error
            self.showError = true
        } catch {
            self.error = .messageNotSent(reason: error.localizedDescription)
            self.showError = true
        }
    }
}

// Error display in View
struct ConversationView: View {
    @Bindable var viewModel: ConversationViewModel

    var body: some View {
        content
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.showError = false }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Unknown error")
            }
    }
}
```

---

## Logging

```swift
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!

    static let auth = Logger(subsystem: subsystem, category: "Authentication")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let database = Logger(subsystem: subsystem, category: "Database")
    static let tdlib = Logger(subsystem: subsystem, category: "TDLib")
}

// Usage
Logger.auth.info("User logged in: \(userId, privacy: .private)")
Logger.network.error("Request failed: \(error)")
Logger.tdlib.debug("Received update: \(updateType)")
```

---

## Performance Guidelines

### Immagini

```swift
// Lazy loading con caching
struct CachedAsyncImage: View {
    let url: URL?
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
                    .task { await loadImage() }
            }
        }
    }

    private func loadImage() async {
        guard let url else { return }
        image = await ImageCache.shared.image(for: url)
    }
}
```

### Liste

```swift
// Sempre usare LazyVStack per liste lunghe
struct ChatListView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(chats) { chat in
                    ChatRow(chat: chat)
                        .id(chat.id)  // Importante per performance
                }
            }
        }
    }
}
```

### Memory

```swift
// Rilascia risorse quando view scompare
.onDisappear {
    viewModel.cleanup()
}

// Weak references in closures
Task { [weak self] in
    guard let self else { return }
    await self.loadData()
}
```

---

## Accessibilità

```swift
// Sempre aggiungere accessibility
struct ChatRow: View {
    let chat: Chat

    var body: some View {
        HStack {
            AvatarView(chat: chat)
            VStack(alignment: .leading) {
                Text(chat.title)
                Text(chat.lastMessage ?? "")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chat.title), \(chat.lastMessage ?? "no messages")")
        .accessibilityHint("Double tap to open conversation")
        .accessibilityAddTraits(.isButton)
    }
}

// Dynamic Type support
Text(message.text)
    .font(.body)  // Usa stili semantici, non dimensioni fisse
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)  // Limita se necessario
```

---

## Localizzazione

```swift
// Usa sempre LocalizedStringKey
Text("chat_list_title")  // Cerca in Localizable.strings

// String interpolation
Text("messages_count \(count)")  // "messages_count" = "%lld messages"

// Pluralization (Localizable.stringsdict)
Text("unread_messages_\(count)")

// Date formatting
Text(date, style: .relative)  // Automaticamente localizzato
```

---

## Comandi Utili

```bash
# Build
xcodebuild -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Test
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Lint
swiftlint lint --strict

# Format
swiftformat . --swiftversion 6.0

# Clean
xcodebuild clean -scheme Margiogram

# Archive
xcodebuild archive -scheme Margiogram -archivePath ./build/Margiogram.xcarchive
```

---

## Checklist Pre-Commit

- [ ] Codice compila senza warning
- [ ] Tutti i test passano
- [ ] SwiftLint non ha errori
- [ ] Nessun `print()` o `debugPrint()` in produzione
- [ ] Nessun force unwrap (`!`)
- [ ] Error handling completo
- [ ] Accessibility labels presenti
- [ ] Localizzazione per nuove stringhe
- [ ] Documentazione per API pubbliche

---

## Contatti e Risorse

- **Repository**: [github.com/username/margiogram](https://github.com/username/margiogram)
- **TDLib Docs**: [core.telegram.org/tdlib](https://core.telegram.org/tdlib)
- **Telegram API**: [core.telegram.org/api](https://core.telegram.org/api)
- **SwiftUI Docs**: [developer.apple.com/documentation/swiftui](https://developer.apple.com/documentation/swiftui)
