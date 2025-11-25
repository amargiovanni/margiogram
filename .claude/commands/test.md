---
model: claude-sonnet-4-5-20250929
description: Generate and run tests for Margiogram
updated: 2025-11
---

# Test Command

Genera e/o esegui test per il codice specificato.

## Utilizzo

```
/test [file_path o modulo] [--generate|--run|--coverage]
```

### Opzioni
- `--generate`: Genera test per il codice specificato
- `--run`: Esegui test esistenti
- `--coverage`: Esegui test con report coverage

## Test Strategy

### Piramide dei Test

```
        /\
       /  \       UI Tests (10%)
      /----\      - User flows principali
     /      \     - Happy path scenarios
    /--------\
   /          \   Integration Tests (20%)
  /            \  - Repository + TDLib
 /--------------\ - ViewModel + UseCase
/                \
/------------------\  Unit Tests (70%)
                      - UseCase logic
                      - ViewModel state
                      - Entity transformations
                      - Utilities
```

### Naming Convention

```swift
func test_[methodName]_[scenario]_[expectedBehavior]()

// Esempi:
func test_sendMessage_withValidText_returnsMessage()
func test_loadChats_whenNetworkError_setsErrorState()
func test_formatDate_withPastDate_returnsRelativeString()
```

### Test Structure (Given-When-Then)

```swift
func test_example() {
    // Given - Setup preconditions
    let input = "test"
    mockService.valueToReturn = expectedValue

    // When - Execute action
    let result = sut.performAction(input)

    // Then - Verify results
    XCTAssertEqual(result, expectedValue)
}
```

## Templates

### Unit Test - ViewModel

```swift
import XCTest
@testable import Margiogram

@MainActor
final class [ViewModel]Tests: XCTestCase {
    // MARK: - Properties
    private var sut: [ViewModel]!
    private var mockRepository: Mock[Repository]!

    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        mockRepository = Mock[Repository]()
        sut = [ViewModel](repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests
    func test_initialState_isCorrect() {
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    // MARK: - Loading Tests
    func test_load_setsLoadingTrue() async {
        // Given
        mockRepository.delay = 0.1

        // When
        let task = Task { await sut.load() }

        // Then
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(sut.isLoading)

        await task.value
    }

    func test_load_whenSuccess_updatesItems() async {
        // Given
        let expected = [[Entity].mock()]
        mockRepository.itemsToReturn = expected

        // When
        await sut.load()

        // Then
        XCTAssertEqual(sut.items, expected)
        XCTAssertFalse(sut.isLoading)
    }

    func test_load_whenFailure_setsError() async {
        // Given
        mockRepository.errorToThrow = TestError.network

        // When
        await sut.load()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
        XCTAssertNotNil(sut.error)
    }

    // MARK: - Action Tests
    func test_action_withValidInput_succeeds() async {
        // Given
        let input = "valid"

        // When
        await sut.performAction(input)

        // Then
        XCTAssertTrue(mockRepository.actionCalled)
    }

    func test_action_withInvalidInput_fails() async {
        // Given
        let input = ""

        // When
        await sut.performAction(input)

        // Then
        XCTAssertNotNil(sut.error)
    }
}
```

### Unit Test - UseCase

```swift
import XCTest
@testable import Margiogram

final class [UseCase]Tests: XCTestCase {
    private var sut: [UseCase]!
    private var mockRepository: Mock[Repository]!

    override func setUp() {
        super.setUp()
        mockRepository = Mock[Repository]()
        sut = [UseCase](repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    func test_execute_withValidInput_returnsExpectedResult() async throws {
        // Given
        let input = InputType.valid
        let expected = OutputType.expected
        mockRepository.resultToReturn = expected

        // When
        let result = try await sut.execute(input: input)

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_execute_withInvalidInput_throwsError() async {
        // Given
        let input = InputType.invalid

        // When/Then
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
}
```

### Integration Test

```swift
import XCTest
@testable import Margiogram

final class [Feature]IntegrationTests: XCTestCase {
    private var viewModel: [ViewModel]!
    private var mockTDLib: MockTDLibClient!

    override func setUp() {
        super.setUp()
        mockTDLib = MockTDLibClient()
        let repository = TDLib[Repository](client: mockTDLib)
        let useCase = [UseCase](repository: repository)
        viewModel = [ViewModel](useCase: useCase)
    }

    func test_fullFlow_fromLoadToDisplay() async {
        // Given
        mockTDLib.responsesToReturn = [
            .getChats: MockChatsResponse()
        ]

        // When
        await viewModel.load()

        // Then
        XCTAssertFalse(viewModel.items.isEmpty)
        XCTAssertTrue(mockTDLib.getChatsWasCalled)
    }
}
```

### UI Test

```swift
import XCTest

final class [Feature]UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func test_[screen]_displaysCorrectly() {
        // Given
        let element = app.staticTexts["screenTitle"]

        // Then
        XCTAssertTrue(element.exists)
    }

    func test_[action]_navigatesToExpectedScreen() {
        // Given
        let button = app.buttons["actionButton"]

        // When
        button.tap()

        // Then
        let destination = app.navigationBars["DestinationTitle"]
        XCTAssertTrue(destination.waitForExistence(timeout: 2))
    }

    func test_[input]_showsValidation() {
        // Given
        let textField = app.textFields["inputField"]
        let errorLabel = app.staticTexts["errorLabel"]

        // When
        textField.tap()
        textField.typeText("invalid")
        app.buttons["submitButton"].tap()

        // Then
        XCTAssertTrue(errorLabel.waitForExistence(timeout: 1))
    }
}
```

### Mock Template

```swift
import Foundation
@testable import Margiogram

final class Mock[Repository]: [Repository]Protocol {
    // MARK: - Call Tracking
    var loadCalled = false
    var loadCallCount = 0
    var lastLoadParameters: LoadParameters?

    // MARK: - Stubbed Returns
    var itemsToReturn: [[Entity]] = []
    var errorToThrow: Error?
    var delay: TimeInterval = 0

    // MARK: - Protocol Implementation
    func load(parameters: LoadParameters) async throws -> [[Entity]] {
        loadCalled = true
        loadCallCount += 1
        lastLoadParameters = parameters

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = errorToThrow {
            throw error
        }

        return itemsToReturn
    }

    // MARK: - Helpers
    func reset() {
        loadCalled = false
        loadCallCount = 0
        lastLoadParameters = nil
        itemsToReturn = []
        errorToThrow = nil
        delay = 0
    }
}
```

### Test Data Factory

```swift
import Foundation
@testable import Margiogram

enum TestData {
    static func makeChat(
        id: Int64 = Int64.random(in: 1...1000),
        title: String = "Test Chat",
        unreadCount: Int32 = 0
    ) -> Chat {
        Chat(id: id, title: title, unreadCount: unreadCount)
    }

    static func makeMessage(
        id: Int64 = Int64.random(in: 1...1000),
        chatId: Int64 = 1,
        text: String = "Test message",
        date: Date = Date()
    ) -> Message {
        Message(id: id, chatId: chatId, content: .text(text), date: date)
    }

    static func makeUser(
        id: Int64 = Int64.random(in: 1...1000),
        firstName: String = "Test",
        lastName: String = "User"
    ) -> User {
        User(id: id, firstName: firstName, lastName: lastName)
    }
}

// Extension for mock data
extension Chat {
    static func mock(
        id: Int64 = 1,
        title: String = "Mock Chat"
    ) -> Chat {
        TestData.makeChat(id: id, title: title)
    }
}
```

## Commands

### Run All Tests
```bash
xcodebuild test \
  -scheme Margiogram \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath TestResults.xcresult
```

### Run Specific Test
```bash
xcodebuild test \
  -scheme Margiogram \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MargiogramTests/ChatViewModelTests/test_loadChats_success
```

### Run with Coverage
```bash
xcodebuild test \
  -scheme Margiogram \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES

# View coverage report
xcrun xccov view --report --json TestResults.xcresult
```

### Run Tests in Parallel
```bash
xcodebuild test \
  -scheme Margiogram \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count 4
```

## Coverage Requirements

| Module | Minimum Coverage |
|--------|-----------------|
| Domain (Entities, UseCases) | 90% |
| ViewModels | 85% |
| Repositories | 80% |
| Views | 50% (UI tests) |
| Utilities | 95% |
| **Overall** | **80%** |
