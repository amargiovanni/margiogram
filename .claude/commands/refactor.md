---
model: claude-sonnet-4-5-20250929
description: Refactor code to improve quality and maintainability
updated: 2025-11
---

# Refactor Command

Migliora la struttura e qualità del codice senza cambiare comportamento.

## Utilizzo

```
/refactor [file_path o modulo] [--type=extract|rename|simplify|optimize]
```

## Principi di Refactoring

### Golden Rules

1. **No behavior change** - Il codice deve funzionare esattamente come prima
2. **Small steps** - Cambiamenti piccoli e incrementali
3. **Test coverage** - Assicurati che i test passino prima e dopo
4. **One thing at a time** - Un tipo di refactoring per volta

### When to Refactor

```
✅ Refactor quando:
- Codice duplicato
- Funzioni troppo lunghe (> 50 righe)
- Classi troppo grandi (> 400 righe)
- Naming poco chiaro
- Nested if/else troppo profondi
- Magic numbers
- Code smells evidenti

❌ Non refactor quando:
- Deadline imminente
- Nessun test coverage
- Non capisci completamente il codice
- Stai già fixando un bug
```

## Refactoring Patterns

### 1. Extract Method

```swift
// ❌ Prima
func processOrder(_ order: Order) {
    // Validate order
    guard order.items.count > 0 else { return }
    guard order.total > 0 else { return }
    guard order.customer != nil else { return }

    // Calculate totals
    var subtotal = 0.0
    for item in order.items {
        subtotal += item.price * Double(item.quantity)
    }
    let tax = subtotal * 0.22
    let total = subtotal + tax

    // Send notification
    let message = "Order #\(order.id) confirmed. Total: \(total)"
    NotificationCenter.default.post(name: .orderConfirmed, object: message)
}

// ✅ Dopo
func processOrder(_ order: Order) {
    guard isValid(order) else { return }

    let total = calculateTotal(for: order)
    sendConfirmation(for: order, total: total)
}

private func isValid(_ order: Order) -> Bool {
    order.items.count > 0 && order.total > 0 && order.customer != nil
}

private func calculateTotal(for order: Order) -> Double {
    let subtotal = order.items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    let tax = subtotal * Constants.taxRate
    return subtotal + tax
}

private func sendConfirmation(for order: Order, total: Double) {
    let message = "Order #\(order.id) confirmed. Total: \(total)"
    NotificationCenter.default.post(name: .orderConfirmed, object: message)
}
```

### 2. Extract Type

```swift
// ❌ Prima - ViewModel troppo grande
class ChatViewModel {
    // 50+ properties
    // 100+ methods
    // Handles: loading, sending, media, calls, etc.
}

// ✅ Dopo - Responsabilità separate
class ChatListViewModel {
    // Chat list loading/filtering
}

class ConversationViewModel {
    // Message handling
}

class MediaPickerViewModel {
    // Media selection
}

class CallViewModel {
    // Call handling
}
```

### 3. Replace Conditionals with Polymorphism

```swift
// ❌ Prima
func handle(message: Message) {
    switch message.type {
    case .text:
        handleTextMessage(message)
    case .photo:
        handlePhotoMessage(message)
    case .video:
        handleVideoMessage(message)
    case .voice:
        handleVoiceMessage(message)
    // ... 20 more cases
    }
}

// ✅ Dopo
protocol MessageHandler {
    func handle(_ message: Message)
}

class TextMessageHandler: MessageHandler {
    func handle(_ message: Message) { /* ... */ }
}

class PhotoMessageHandler: MessageHandler {
    func handle(_ message: Message) { /* ... */ }
}

// Usage
let handlers: [MessageType: MessageHandler] = [
    .text: TextMessageHandler(),
    .photo: PhotoMessageHandler(),
    // ...
]

func handle(message: Message) {
    handlers[message.type]?.handle(message)
}
```

### 4. Simplify Nested Conditionals

```swift
// ❌ Prima
func canSendMessage() -> Bool {
    if isLoggedIn {
        if hasPermission {
            if !isBanned {
                if !isRateLimited {
                    return true
                }
            }
        }
    }
    return false
}

// ✅ Dopo - Guard clauses
func canSendMessage() -> Bool {
    guard isLoggedIn else { return false }
    guard hasPermission else { return false }
    guard !isBanned else { return false }
    guard !isRateLimited else { return false }
    return true
}

// Oppure
var canSendMessage: Bool {
    isLoggedIn && hasPermission && !isBanned && !isRateLimited
}
```

### 5. Replace Magic Numbers

```swift
// ❌ Prima
func isValidPassword(_ password: String) -> Bool {
    password.count >= 8 && password.count <= 128
}

func loadChats() async {
    let chats = try await repository.getChats(limit: 100)
}

// ✅ Dopo
private enum Constants {
    enum Password {
        static let minLength = 8
        static let maxLength = 128
    }

    enum Pagination {
        static let defaultPageSize = 100
    }
}

func isValidPassword(_ password: String) -> Bool {
    (Constants.Password.minLength...Constants.Password.maxLength).contains(password.count)
}

func loadChats() async {
    let chats = try await repository.getChats(limit: Constants.Pagination.defaultPageSize)
}
```

### 6. Introduce Parameter Object

```swift
// ❌ Prima
func createUser(
    firstName: String,
    lastName: String,
    email: String,
    phone: String,
    address: String,
    city: String,
    country: String,
    zipCode: String
) { }

// ✅ Dopo
struct UserCreationRequest {
    let firstName: String
    let lastName: String
    let email: String
    let phone: String
    let address: Address
}

struct Address {
    let street: String
    let city: String
    let country: String
    let zipCode: String
}

func createUser(_ request: UserCreationRequest) { }
```

### 7. Replace Inheritance with Composition

```swift
// ❌ Prima - Deep inheritance hierarchy
class BaseView: UIView { }
class StyledView: BaseView { }
class AnimatedView: StyledView { }
class InteractiveView: AnimatedView { }
class ChatView: InteractiveView { }

// ✅ Dopo - Composition with protocols
protocol Stylable {
    var style: ViewStyle { get }
}

protocol Animatable {
    func animate(_ animation: Animation)
}

protocol Interactive {
    func handleTap(_ location: CGPoint)
}

struct ChatView: View, Stylable, Animatable, Interactive {
    let style: ViewStyle
    // ...
}
```

### 8. Use Extensions for Organization

```swift
// ❌ Prima - Tutto in una struct
struct ChatListView: View {
    // 500 lines of mixed code
}

// ✅ Dopo - Organizzato con extensions
struct ChatListView: View {
    @State private var viewModel: ChatListViewModel
    @State private var searchText = ""

    var body: some View {
        content
    }
}

// MARK: - Subviews
private extension ChatListView {
    var content: some View { /* ... */ }
    var searchBar: some View { /* ... */ }
    var chatList: some View { /* ... */ }
    var emptyState: some View { /* ... */ }
}

// MARK: - Actions
private extension ChatListView {
    func selectChat(_ chat: Chat) { /* ... */ }
    func deleteChat(_ chat: Chat) { /* ... */ }
    func archiveChat(_ chat: Chat) { /* ... */ }
}

// MARK: - Helpers
private extension ChatListView {
    func formatDate(_ date: Date) -> String { /* ... */ }
}
```

## Refactoring Checklist

### Before Refactoring
- [ ] Codice compila e funziona
- [ ] Test esistenti passano
- [ ] Hai capito il codice da refactorare
- [ ] Hai identificato cosa migliorare
- [ ] Hai un piano incrementale

### During Refactoring
- [ ] Un cambiamento alla volta
- [ ] Compila dopo ogni cambiamento
- [ ] Test dopo ogni cambiamento
- [ ] Commit frequenti

### After Refactoring
- [ ] Tutti i test passano
- [ ] Comportamento invariato
- [ ] Codice più leggibile
- [ ] Nessun code smell residuo
- [ ] Performance uguale o migliore

## Code Smells to Fix

| Code Smell | Refactoring |
|------------|-------------|
| Long Method | Extract Method |
| Large Class | Extract Class |
| Long Parameter List | Parameter Object |
| Duplicated Code | Extract Method/Class |
| Feature Envy | Move Method |
| Data Clumps | Extract Class |
| Primitive Obsession | Value Object |
| Switch Statements | Polymorphism |
| Parallel Inheritance | Composition |
| Comments explaining code | Rename, Extract |
| Dead Code | Remove |
| Speculative Generality | Remove |

## Metrics Target Post-Refactor

| Metric | Target |
|--------|--------|
| Method length | < 50 lines |
| Class length | < 400 lines |
| Parameters per method | < 5 |
| Nesting depth | < 4 levels |
| Cyclomatic complexity | < 10 |
| Test coverage | > 80% |
