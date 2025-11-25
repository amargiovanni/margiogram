# Margiogram

> Un client Telegram nativo per macOS e iOS con design Liquid Glass, costruito interamente in Swift.

![Platform](https://img.shields.io/badge/Platform-iOS%2026%2B%20%7C%20macOS%2026%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)

## Panoramica

Margiogram è un client Telegram completo che sfrutta le API ufficiali di Telegram (TDLib) per offrire un'esperienza utente premium su dispositivi Apple. Il design Liquid Glass si adatta fluidamente tra iOS e macOS, mantenendo un'estetica moderna e coerente.

## Stato Sviluppo Attuale

L'app compila e funziona con **dati mock** per lo sviluppo e il testing dell'UI. L'integrazione reale con TDLib è pianificata per la prossima fase.

### Modalità Mock

L'app attualmente funziona in modalità mock che permette di:
- Testare il flusso completo di autenticazione (phone -> code -> auth)
- Visualizzare chat mock con messaggi di esempio
- Navigare tra tutte le schermate dell'app
- Testare tutte le interazioni UI

**Per autenticarsi in modalità mock:**
1. Inserire un numero di telefono in formato internazionale (es. `+39123456789`)
2. Cliccare "Continue"
3. Inserire il codice `12345` (o qualsiasi codice di 4+ cifre)

### Completato

#### Core Layer
- **TDLib Mock Client**: Wrapper completo con supporto async/await
  - `TDLibClient.swift` - Client principale con mock data
  - `TDLibTypes.swift` - Tipi base (TDFunction, TDUpdate, Ok)
  - `TDLibFunctions.swift` - Definizioni funzioni TDLib
  - `TDLibUpdateHandler.swift` - Gestione aggiornamenti con delegate pattern
  - `AuthenticationManager.swift` - Gestione flusso di autenticazione

#### Domain Layer
- **Entities**: User, Chat, Message, ChatFolder con supporto completo e mock data
- **Repositories**: Protocol-based abstractions per data access
- **UseCases**: Business logic per Chat, Message, User operations

#### Data Layer
- **Repository Implementations**: ChatRepositoryImpl, MessageRepositoryImpl, UserRepositoryImpl
- **Mock Data**: Dati di esempio per tutte le entità

#### Services
- **KeychainService**: Storage sicuro con actor-based design
- **BiometricService**: Face ID / Touch ID / Optic ID support
- **NotificationService**: Push notifications con categories e actions
- **FileService**: File management con cache e directory handling
- **NetworkMonitor**: Connectivity monitoring

#### Features
| Feature | Views | ViewModels | Status |
|---------|-------|------------|--------|
| **Authentication** | AuthenticationView, PhoneInputView, CodeInputView, PasswordView | AuthViewModel | ✅ |
| **Chat List** | ChatListView, ChatRowView | ChatListViewModel | ✅ |
| **Conversation** | ConversationView, MessageBubble, MessageInputView | ConversationViewModel | ✅ |
| **Contacts** | ContactsView | ContactsViewModel | ✅ |
| **Settings** | SettingsView | - | ✅ |
| **Profile** | ProfileView | ProfileViewModel | ✅ |
| **Media Viewer** | MediaViewerView, MediaGalleryView | MediaViewerViewModel | ✅ |
| **Global Search** | GlobalSearchView | GlobalSearchViewModel | ✅ |
| **Calls** | CallView | CallViewModel | ✅ |
| **Stickers** | StickerPanelView | StickerPanelViewModel | ✅ |
| **Forward** | ForwardView | ForwardViewModel | ✅ |

#### UI Design System
- **Liquid Glass Components**: GlassContainer, GlassButton, GlassTextField, GlassSectionHeader
- **Typography**: Complete type system con Typography enum
- **Colors**: Dynamic color palette con AppColors
- **Spacing**: Spacing constants per consistenza UI
- **Modifiers**: LiquidGlassModifier view modifiers
- **Components**: AvatarView, MessageBubble, e altri componenti riutilizzabili

#### Navigation
- **RootView**: Adaptive layout (TabView iPhone, NavigationSplitView iPad/Mac)
- **Cross-platform support**: iOS, iPadOS, macOS

### In Progress
- Integrazione reale TDLib
- Widget extensions
- Watch companion app

### Planned
- Stories feature
- Channels management
- Bot interactions
- SharePlay integration
- Siri shortcuts

## Architettura

```
Margiogram/
├── App/
│   ├── MargiogramApp.swift          # Entry point
│   └── RootView.swift               # Adaptive navigation
├── Core/
│   ├── TDLib/
│   │   ├── TDLibClient.swift        # Main TDLib wrapper (mock)
│   │   ├── TDLibTypes.swift         # Base types (TDFunction, TDUpdate, Ok)
│   │   ├── TDLibFunctions.swift     # TDLib function definitions
│   │   ├── TDLibUpdateHandler.swift # Update handling
│   │   └── AuthenticationManager.swift # Auth flow management
│   ├── Database/
│   │   └── DatabaseService.swift
│   ├── Network/
│   │   └── NetworkMonitor.swift
│   ├── Security/
│   │   ├── KeychainService.swift
│   │   └── BiometricService.swift
│   └── Services/
│       ├── NotificationService.swift
│       └── FileService.swift
├── Domain/
│   ├── Entities/
│   │   ├── User.swift
│   │   ├── Chat.swift
│   │   ├── Message.swift
│   │   └── ChatFolder.swift
│   ├── Repositories/                # Protocols
│   └── UseCases/
│       ├── ChatUseCases.swift
│       ├── MessageUseCases.swift
│       └── UserUseCases.swift
├── Data/
│   ├── Repositories/
│   │   ├── ChatRepositoryImpl.swift
│   │   ├── MessageRepositoryImpl.swift
│   │   └── UserRepositoryImpl.swift
│   └── Mappers/
├── Features/
│   ├── Auth/
│   │   ├── Views/
│   │   │   └── AuthenticationView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   ├── ChatList/
│   │   ├── Views/
│   │   │   ├── ChatListView.swift
│   │   │   └── ChatRowView.swift
│   │   └── ViewModels/
│   │       └── ChatListViewModel.swift
│   ├── Conversation/
│   │   ├── Views/
│   │   │   ├── ConversationView.swift
│   │   │   └── MessageInputView.swift
│   │   └── ViewModels/
│   │       └── ConversationViewModel.swift
│   ├── Contacts/
│   ├── Settings/
│   ├── Profile/
│   ├── MediaViewer/
│   ├── Search/
│   ├── Calls/
│   ├── Stickers/
│   └── Forward/
├── UI/
│   ├── DesignSystem/
│   │   ├── LiquidGlass/
│   │   │   └── LiquidGlassModifier.swift
│   │   ├── Colors/
│   │   │   └── Colors.swift
│   │   └── Typography/
│   │       └── Typography.swift
│   ├── Components/
│   │   ├── AvatarView.swift
│   │   ├── GlassButton.swift
│   │   ├── GlassContainer.swift
│   │   └── MessageBubble.swift
│   └── Modifiers/
├── Extensions/
├── Utilities/
└── Resources/
    ├── Assets.xcassets/
    └── Localizable/
```

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| UI Framework | SwiftUI (iOS 26+) |
| Backend API | TDLib (Telegram Database Library) - mock |
| Architecture | MVVM + Clean Architecture |
| Concurrency | Swift 6.0 Strict Concurrency (async/await, actors) |
| State Management | @Observable, @Bindable |
| Project Generation | XcodeGen |
| Media | AVFoundation, PhotosUI |
| Notifiche | UserNotifications |
| Sicurezza | CryptoKit, Keychain |

## Requisiti di Sistema

### iOS
- iOS 26.0 o successivo
- iPhone, iPad

### macOS
- macOS 26.0 o successivo

### Development
- Xcode 17.0+ (beta)
- XcodeGen (per generare il progetto)
- Swift 6.0

## Installazione

### Prerequisites

1. **Xcode 17.0+** con Command Line Tools
2. **XcodeGen** per generare il progetto Xcode

```bash
brew install xcodegen
```

### Setup

1. Clona il repository:
```bash
git clone https://github.com/amargiovanni/margiogram.git
cd margiogram
```

2. Genera il progetto Xcode:
```bash
xcodegen generate
```

3. Apri e builda il progetto:
```bash
open Margiogram.xcodeproj
```

4. Seleziona lo scheme "Margiogram" e un simulatore iOS 26+

5. Build and Run (Cmd+R)

### Configurazione TDLib (per integrazione reale)

Quando l'integrazione TDLib sarà implementata:

1. Vai su [my.telegram.org](https://my.telegram.org)
2. Accedi con il tuo numero di telefono
3. Vai su "API development tools"
4. Crea una nuova applicazione
5. Configura le credenziali nel progetto

## Design Liquid Glass

### Principi di Design

1. **Trasparenza Contestuale**: Elementi UI con blur e trasparenza basati sul contenuto sottostante
2. **Profondità Visiva**: Uso di ombre e gradienti per creare gerarchia
3. **Fluidità**: Transizioni e animazioni smooth tra stati
4. **Adattabilità**: Interfaccia che si adatta a dispositivo, tema e contenuto

### Componenti Principali

```swift
// Glass Container
GlassContainer {
    Text("Content")
}

// Glass Button
GlassButton("Action") {
    // action
}

// Liquid Glass Modifier
Text("Hello")
    .liquidGlass()
```

## Strict Concurrency (Swift 6.0)

Il progetto utilizza Swift 6.0 con strict concurrency checking:

- **@MainActor** per ViewModels e UI code
- **actor** per services thread-safe (KeychainService, repositories)
- **Sendable** conformance per tipi condivisi
- **async/await** per tutte le operazioni asincrone

## Performance

### Ottimizzazioni Implementate

- **Lazy Loading**: Immagini e media caricati on-demand
- **Actor-based Services**: Thread-safe operations
- **Cache Multi-livello**: Per media e messaggi
- **Async/Await**: Modern concurrency throughout

### Target Performance

| Operazione | Target |
|------------|--------|
| Avvio app | < 1s |
| Caricamento chat | < 100ms |
| Invio messaggio | < 50ms |
| Scroll lista | 60 FPS |

## Sicurezza

- **Secure Storage**: Keychain per dati sensibili
- **Biometric Auth**: Face ID / Touch ID / Optic ID
- **App Lock**: PIN/Password per protezione app (planned)
- **E2E Encryption**: Per chat segrete (con TDLib reale)

## Roadmap

### v0.1 (Current - Mock Mode)
- [x] UI completa per tutte le features
- [x] Flusso autenticazione mock
- [x] Mock data per testing UI
- [x] Build funzionante iOS/macOS

### v1.0 (MVP - TDLib Integration)
- [ ] Integrazione TDLib reale
- [ ] Autenticazione completa
- [ ] Messaggi real-time
- [ ] Notifiche push
- [ ] Widget iOS

### v1.1
- [ ] Storie
- [ ] Bot interactions
- [ ] Temi personalizzati
- [ ] Scheduled messages

### v2.0
- [ ] Group calls
- [ ] Apple Watch companion
- [ ] SharePlay integration
- [ ] Siri shortcuts

## Contribuire

### Workflow

1. Fork il repository
2. Crea un feature branch (`git checkout -b feature/amazing-feature`)
3. Commit le modifiche (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Apri una Pull Request

### Coding Guidelines

- Segui le [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Usa `@Observable` per ViewModels
- Usa `actor` per services thread-safe
- Strict concurrency compliance (Swift 6.0)
- Documenta con DocC

## Licenza

Distribuito sotto licenza MIT. Vedi `LICENSE` per maggiori informazioni.

## Riconoscimenti

- [TDLib](https://github.com/tdlib/td) - Telegram Database Library
- Design ispirato a iOS 26 Liquid Glass e visionOS

## Contatti

Andrea Margiovanni - [@margio.uk](https://bsky.app/profile/margio.uk)

Link Progetto: [https://github.com/amargiovanni/margiogram](https://github.com/amargiovanni/margiogram)

---

<p align="center">
  Made with ❤️ in Europe
</p>
