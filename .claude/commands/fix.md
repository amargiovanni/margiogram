---
model: claude-sonnet-4-5-20250929
description: Diagnose and fix bugs in Margiogram
updated: 2025-11
---

# Fix Command

Diagnostica e risolvi problemi nel codice.

## Utilizzo

```
/fix [error_message o file_path]
```

## Workflow di Debug

### 1. Identificazione Problema

```markdown
## Issue Report

### Error Message
[Messaggio di errore esatto]

### Context
- File: [path]
- Line: [number]
- When: [azione che causa l'errore]

### Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Expected Behavior
[Cosa dovrebbe succedere]

### Actual Behavior
[Cosa succede realmente]
```

### 2. Analisi

Verifica in ordine:
1. **Syntax Errors** - Errori di compilazione
2. **Type Mismatches** - Tipi incompatibili
3. **Nil/Optional Issues** - Force unwrap, optional chaining
4. **Concurrency** - Data races, deadlocks
5. **Logic Errors** - Bug nella logica
6. **State Issues** - Stato inconsistente

### 3. Categorie di Errori Comuni

#### Compilation Errors

```swift
// ❌ Error: Cannot convert value of type 'String' to expected argument type 'Int'
let count: Int = "5"

// ✅ Fix
let count: Int = Int("5") ?? 0

// ❌ Error: Missing argument for parameter 'id' in call
let user = User(name: "Test")

// ✅ Fix
let user = User(id: 1, name: "Test")

// ❌ Error: Type 'X' does not conform to protocol 'Y'
struct Message { }

// ✅ Fix
struct Message: Identifiable, Equatable {
    let id: Int64
    // ...
}
```

#### Runtime Errors

```swift
// ❌ Fatal error: Unexpectedly found nil while unwrapping
let value = optionalValue!

// ✅ Fix
guard let value = optionalValue else {
    // Handle nil case
    return
}

// ❌ Fatal error: Index out of range
let item = array[10]

// ✅ Fix
guard array.indices.contains(10) else { return }
let item = array[10]

// ❌ EXC_BAD_ACCESS (memory issue)
// Usually retain cycle or dangling pointer

// ✅ Fix - Use weak references
Task { [weak self] in
    await self?.loadData()
}
```

#### SwiftUI Errors

```swift
// ❌ Error: Publishing changes from background threads is not allowed
await fetchData()
self.items = newItems  // On background thread

// ✅ Fix
await fetchData()
await MainActor.run {
    self.items = newItems
}

// Or use @MainActor on the function
@MainActor
func updateItems(_ newItems: [Item]) {
    self.items = newItems
}

// ❌ Error: Modifying state during view update
var body: some View {
    isLoading = true  // Wrong!
    Text("Loading")
}

// ✅ Fix - Use .onAppear or .task
var body: some View {
    Text("Loading")
        .task { isLoading = true }
}

// ❌ Error: Type '()' cannot conform to 'View'
var body: some View {
    doSomething()  // Returns Void
}

// ✅ Fix
var body: some View {
    Color.clear.onAppear { doSomething() }
}
```

#### Async/Await Errors

```swift
// ❌ Error: 'async' call in a function that does not support concurrency
func loadData() {
    let data = await fetchData()
}

// ✅ Fix - Make function async
func loadData() async {
    let data = await fetchData()
}

// Or use Task
func loadData() {
    Task {
        let data = await fetchData()
    }
}

// ❌ Error: Actor-isolated property cannot be referenced from non-isolated context
actor MyActor {
    var value: Int = 0
}

let actor = MyActor()
print(actor.value)  // Error

// ✅ Fix - Use await
print(await actor.value)

// ❌ Error: Mutation of captured var in concurrently-executing code
var count = 0
await withTaskGroup(of: Void.self) { group in
    count += 1  // Error
}

// ✅ Fix - Use actor or proper synchronization
actor Counter {
    var count = 0
    func increment() { count += 1 }
}
```

#### TDLib Specific Errors

```swift
// ❌ TDLib Error: CHAT_ID_INVALID
try await client.send(GetChat(chatId: 0))

// ✅ Fix - Verify chat ID exists
guard chatId > 0 else {
    throw AppError.invalidChatId
}

// ❌ TDLib Error: AUTH_KEY_UNREGISTERED
// Session expired

// ✅ Fix - Re-authenticate
await authManager.logout()
await authManager.startAuthentication()

// ❌ TDLib Error: FLOOD_WAIT_X
// Too many requests

// ✅ Fix - Implement exponential backoff
func sendWithRetry<T>(_ request: T) async throws -> T.Result {
    var delay: UInt64 = 1
    for attempt in 1...3 {
        do {
            return try await client.send(request)
        } catch TDLibError.floodWait(let seconds) {
            try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            delay *= 2
        }
    }
    throw AppError.tooManyRequests
}
```

### 4. Debugging Tools

#### Print Debugging (Development Only)

```swift
#if DEBUG
func debugLog(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function) {
    let filename = (file as NSString).lastPathComponent
    print("[\(filename):\(line)] \(function) -", items)
}
#endif
```

#### Logger (Production Safe)

```swift
import OSLog

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App")
}

// Usage
Logger.app.debug("Value: \(value)")
Logger.app.error("Error: \(error.localizedDescription)")
```

#### Breakpoints Condizionali

```
// In Xcode:
// 1. Click on line number to add breakpoint
// 2. Right-click > Edit Breakpoint
// 3. Add condition: value == nil
// 4. Add action: Log Message or Debugger Command
```

#### Memory Graph

```
// In Xcode:
// Debug > View Memory Graph Hierarchy
// Look for:
// - Retain cycles (circular references)
// - Leaked objects (objects not referenced)
```

### 5. Checklist Post-Fix

- [ ] Il fix risolve il problema originale?
- [ ] Non introduce nuovi bug?
- [ ] Test esistenti passano?
- [ ] Aggiunto test per prevenire regressione?
- [ ] Performance non degradata?
- [ ] Code style rispettato?

### 6. Documentazione Fix

```markdown
## Fix: [Breve descrizione]

### Problem
[Descrizione del problema]

### Root Cause
[Causa principale identificata]

### Solution
[Descrizione della soluzione]

### Changes
- `file.swift`: [cosa è stato modificato]

### Testing
- [x] Test automatici aggiunti/modificati
- [x] Test manuale eseguito

### Prevention
[Come evitare che il problema si ripresenti]
```

## Quick Fixes Comuni

| Errore | Fix Rapido |
|--------|------------|
| Force unwrap crash | `guard let` o `if let` |
| Index out of range | `array.indices.contains(i)` |
| Background thread UI | `@MainActor` o `MainActor.run` |
| Retain cycle | `[weak self]` in closure |
| Type mismatch | Check types, add conversion |
| Missing conformance | Add protocol conformance |
| Async in sync | Wrap in `Task { }` |
| Actor isolation | Add `await` |
