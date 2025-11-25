---
model: claude-sonnet-4-5-20250929
description: Implement new features following project standards
updated: 2025-11
---

# Implement Feature Command

Implementa una nuova feature seguendo l'architettura e gli standard del progetto.

## Utilizzo

```
/implement [feature_name]
```

## Workflow Implementazione

### 1. Analisi Requirements
Prima di scrivere codice:
- Comprendi completamente i requisiti
- Identifica le dipendenze
- Verifica impatto su codice esistente
- Chiedi chiarimenti se necessario

### 2. Pianificazione
Crea un piano di implementazione:
```markdown
## Feature: [Nome]

### Obiettivo
[Descrizione chiara]

### File da creare/modificare
1. `Domain/Entities/NewEntity.swift` - Nuovo
2. `Features/NewFeature/Views/NewView.swift` - Nuovo
3. `Core/TDLib/TDLibClient.swift` - Modifica

### Dipendenze
- TDLib method: `someMethod`
- Existing: `ChatRepository`

### Steps
1. [ ] Creare entity
2. [ ] Creare repository protocol
3. [ ] Implementare repository
4. [ ] Creare use case
5. [ ] Creare ViewModel
6. [ ] Creare View
7. [ ] Scrivere test
```

### 3. Implementazione

#### Ordine di implementazione:
1. **Domain Layer** (Entities, Repository Protocols)
2. **Data Layer** (Repository Implementations)
3. **Use Cases**
4. **ViewModels**
5. **Views**
6. **Tests**

#### Template Entity
```swift
import Foundation

/// Rappresenta [descrizione]
struct FeatureName: Identifiable, Equatable, Hashable, Sendable {
    let id: Int64
    // Properties...

    init(id: Int64, /* params */) {
        self.id = id
        // ...
    }
}

// MARK: - Mapping from TDLib
extension FeatureName {
    init(from tdObject: TDFeatureName) {
        self.id = tdObject.id
        // ...
    }
}
```

#### Template Repository Protocol
```swift
import Foundation

/// Repository per gestione [feature]
protocol FeatureNameRepository: Sendable {
    /// Ottiene [cosa]
    /// - Parameters:
    ///   - param1: Descrizione
    /// - Returns: Descrizione return
    /// - Throws: `FeatureError` se [condizione]
    func getItems(param1: Type) async throws -> [Item]

    func createItem(_ item: Item) async throws -> Item
    func updateItem(_ item: Item) async throws
    func deleteItem(id: Int64) async throws
}
```

#### Template Repository Implementation
```swift
import Foundation

final class TDLibFeatureRepository: FeatureNameRepository {
    private let client: TDLibClient

    init(client: TDLibClient = .shared) {
        self.client = client
    }

    func getItems(param1: Type) async throws -> [Item] {
        let response = try await client.send(GetItems(param1: param1))
        return response.items.map { Item(from: $0) }
    }

    // ... altre implementazioni
}
```

#### Template Use Case
```swift
import Foundation

/// Use case per [azione]
final class FeatureActionUseCase: Sendable {
    private let repository: FeatureNameRepository

    init(repository: FeatureNameRepository) {
        self.repository = repository
    }

    /// Esegue [azione]
    /// - Parameters:
    ///   - input: Descrizione
    /// - Returns: Descrizione
    func execute(input: InputType) async throws -> OutputType {
        // Validazione
        guard isValid(input) else {
            throw FeatureError.invalidInput
        }

        // Business logic
        return try await repository.doSomething(input)
    }
}
```

#### Template ViewModel
```swift
import Foundation
import Observation

@Observable
final class FeatureViewModel {
    // MARK: - Published State
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies
    private let useCase: FeatureActionUseCase

    // MARK: - Init
    init(useCase: FeatureActionUseCase) {
        self.useCase = useCase
    }

    // MARK: - Actions
    @MainActor
    func loadItems() async {
        isLoading = true
        error = nil

        do {
            items = try await useCase.execute()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
```

#### Template View
```swift
import SwiftUI

struct FeatureView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var viewModel: FeatureViewModel

    // MARK: - Init
    init(viewModel: FeatureViewModel = .init()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Feature")
            .task { await viewModel.loadItems() }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            }
    }

    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.items.isEmpty {
            emptyView
        } else {
            listView
        }
    }

    private var loadingView: some View {
        ProgressView()
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Items will appear here")
        )
    }

    private var listView: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FeatureView()
    }
}
```

### 4. Testing

#### Template Test
```swift
import XCTest
@testable import Margiogram

@MainActor
final class FeatureViewModelTests: XCTestCase {
    // MARK: - Properties
    private var sut: FeatureViewModel!
    private var mockRepository: MockFeatureRepository!

    // MARK: - Setup
    override func setUp() {
        super.setUp()
        mockRepository = MockFeatureRepository()
        let useCase = FeatureActionUseCase(repository: mockRepository)
        sut = FeatureViewModel(useCase: useCase)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Tests
    func test_loadItems_whenSuccess_updatesItems() async {
        // Given
        let expectedItems = [Item.mock()]
        mockRepository.itemsToReturn = expectedItems

        // When
        await sut.loadItems()

        // Then
        XCTAssertEqual(sut.items, expectedItems)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func test_loadItems_whenFailure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.network

        // When
        await sut.loadItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
    }
}
```

### 5. Checklist Finale

- [ ] Codice compila senza warning
- [ ] Tutti i test passano
- [ ] SwiftLint non ha errori
- [ ] Documentazione completa
- [ ] Accessibility implementata
- [ ] Dark mode funziona
- [ ] Performance accettabile
- [ ] Code review completata
