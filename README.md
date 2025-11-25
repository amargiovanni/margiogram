# Margiogram

> Un client Telegram nativo per macOS e iOS con design Liquid Glass, costruito interamente in Swift.

![Platform](https://img.shields.io/badge/Platform-iOS%2026%2B%20%7C%20macOS%2026%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)

## Panoramica

Margiogram è un client Telegram completo che sfrutta le API ufficiali di Telegram (TDLib) per offrire un'esperienza utente premium su dispositivi Apple. Il design Liquid Glass si adatta fluidamente tra iOS e macOS, mantenendo un'estetica moderna e coerente.

## Stato Sviluppo

### ✅ Completato

#### Core Layer
- **TDLib Integration**: Wrapper completo per TDLib con supporto actor-based
  - `TDLibClient.swift` - Client principale con async/await
  - `TDLibFunctions.swift` - Tutte le funzioni TDLib (auth, chat, messages, calls, stickers)
  - `TDLibUpdateHandler.swift` - Gestione aggiornamenti real-time con delegate pattern

#### Domain Layer
- **Entities**: User, Chat, Message, ChatFolder con supporto completo
- **Repositories**: Protocol-based abstractions per data access
- **UseCases**: Business logic per Chat, Message, User operations

#### Data Layer
- **Repository Implementations**: ChatRepositoryImpl, MessageRepositoryImpl, UserRepositoryImpl
- **Mappers**: TDLib to Domain entity mapping

#### Services
- **KeychainService**: Storage sicuro con actor-based design
- **BiometricService**: Face ID / Touch ID / Optic ID support
- **NotificationService**: Push notifications con categories e actions
- **FileService**: File management con cache e directory handling
- **NetworkMonitor**: Connectivity monitoring

#### Features
| Feature | Views | ViewModels | Status |
|---------|-------|------------|--------|
| **Authentication** | AuthView, PhoneInputView, CodeInputView, PasswordView | AuthViewModel | ✅ |
| **Chat List** | ChatListView, ChatRowView | ChatListViewModel | ✅ |
| **Conversation** | ConversationView, MessageBubble, MessageInputView | ConversationViewModel | ✅ |
| **Contacts** | ContactsView | ContactsViewModel | ✅ |
| **Settings** | SettingsView | - | ✅ |
| **Profile** | ProfileView | ProfileViewModel | ✅ |
| **Media Viewer** | MediaViewerView, MediaGalleryView | MediaViewerViewModel | ✅ |
| **Global Search** | GlobalSearchView | GlobalSearchViewModel | ✅ |
| **Calls** | CallView, CallHistoryView | CallViewModel | ✅ |
| **Stickers** | StickerPanelView, StickerStoreView | StickerPanelViewModel | ✅ |
| **Forward** | ForwardView, ShareSheetView | ForwardViewModel | ✅ |

#### UI Design System
- **Liquid Glass Components**: GlassContainer, GlassButton, GlassTextField
- **Typography**: Complete type system
- **Colors**: Dynamic color palette with dark mode
- **Modifiers**: LiquidGlass view modifiers

#### Navigation
- **RootView**: Adaptive layout (TabView iPhone, NavigationSplitView iPad/Mac)
- **Cross-platform support**: iOS, iPadOS, macOS

### 🚧 In Progress
- Xcode project generation (project.yml ready)
- Widget extensions
- Watch companion app

### 📋 Planned
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
│   │   ├── TDLibClient.swift        # Main TDLib wrapper
│   │   ├── TDLibFunctions.swift     # All TDLib functions
│   │   └── TDLibUpdateHandler.swift # Update handling
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
│   │   └── ViewModels/
│   ├── ChatList/
│   │   ├── Views/
│   │   │   ├── ChatListView.swift
│   │   │   └── ChatRowView.swift
│   │   └── ViewModels/
│   │       └── ChatListViewModel.swift
│   ├── Conversation/
│   │   ├── Views/
│   │   │   ├── ConversationView.swift
│   │   │   ├── MessageBubble.swift
│   │   │   └── MessageInputView.swift
│   │   └── ViewModels/
│   │       └── ConversationViewModel.swift
│   ├── Contacts/
│   ├── Settings/
│   ├── Profile/
│   ├── MediaViewer/
│   │   ├── Views/
│   │   │   ├── MediaViewerView.swift
│   │   │   └── MediaGalleryView.swift
│   │   └── ViewModels/
│   │       └── MediaViewerViewModel.swift
│   ├── Search/
│   │   ├── Views/
│   │   │   └── GlobalSearchView.swift
│   │   └── ViewModels/
│   │       └── GlobalSearchViewModel.swift
│   ├── Calls/
│   │   ├── Views/
│   │   │   └── CallView.swift
│   │   └── ViewModels/
│   │       └── CallViewModel.swift
│   ├── Stickers/
│   │   ├── Views/
│   │   │   └── StickerPanelView.swift
│   │   └── ViewModels/
│   │       └── StickerPanelViewModel.swift
│   └── Forward/
│       ├── Views/
│       │   └── ForwardView.swift
│       └── ViewModels/
│           └── ForwardViewModel.swift
├── UI/
│   ├── DesignSystem/
│   │   ├── LiquidGlass/
│   │   │   ├── GlassContainer.swift
│   │   │   ├── GlassButton.swift
│   │   │   └── GlassTextField.swift
│   │   ├── Colors/
│   │   │   └── AppColors.swift
│   │   └── Typography/
│   │       └── AppTypography.swift
│   ├── Components/
│   └── Modifiers/
│       └── LiquidGlassModifier.swift
├── Extensions/
└── Resources/
    ├── Assets.xcassets/
    └── Localizable/
```

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| UI Framework | SwiftUI |
| Backend API | TDLib (Telegram Database Library) |
| Architecture | MVVM + Clean Architecture |
| Concurrency | Swift Concurrency (async/await, actors) |
| State Management | @Observable (iOS 17+) |
| Database Locale | SwiftData |
| Networking | URLSession + WebSocket |
| Media | AVFoundation, PhotosUI |
| Chiamate | WebRTC (planned) |
| Notifiche | UserNotifications, PushKit |
| Sicurezza | CryptoKit, Keychain |

## Requisiti di Sistema

### iOS
- iOS 26.0 o successivo
- iPhone, iPad

### macOS
- macOS 26.0 o successivo
- Chip Apple Silicon (Intel non supportato)

## Installazione

### Prerequisites

1. **Xcode 17.0+** con Command Line Tools
2. **XcodeGen** (opzionale, per generare il progetto)
3. **TDLib** compilato per le piattaforme target

### Setup

1. Clona il repository:
```bash
git clone https://github.com/amargiovanni/margiogram.git
cd margiogram
```

2. Genera il progetto Xcode (opzionale):
```bash
xcodegen generate
```

3. Configura le API credentials in `Config.xcconfig`:
```xcconfig
TELEGRAM_API_ID = your_api_id
TELEGRAM_API_HASH = your_api_hash
```

4. Apri e builda il progetto:
```bash
open Margiogram.xcodeproj
```

### Ottenere API Credentials

1. Vai su [my.telegram.org](https://my.telegram.org)
2. Accedi con il tuo numero di telefono
3. Vai su "API development tools"
4. Crea una nuova applicazione
5. Copia `api_id` e `api_hash`

## Design Liquid Glass

### Principi di Design

1. **Trasparenza Contestuale**: Elementi UI con blur e trasparenza basati sul contenuto sottostante
2. **Profondità Visiva**: Uso di ombre e gradienti per creare gerarchia
3. **Fluidità**: Transizioni e animazioni smooth tra stati
4. **Adattabilità**: Interfaccia che si adatta a dispositivo, tema e contenuto

### Implementazione

```swift
// Liquid Glass Container
struct GlassContainer<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.15), .white.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
```

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

- **End-to-End Encryption**: Chat segrete con MTProto 2.0
- **Secure Storage**: Keychain per dati sensibili
- **Biometric Auth**: Face ID / Touch ID / Optic ID
- **App Lock**: PIN/Password per protezione app

## Roadmap

### v1.0 (MVP)
- [x] Autenticazione completa
- [x] Lista chat con folders
- [x] Messaggi (testo, media, voice)
- [x] Chiamate audio/video
- [x] Sticker e GIF
- [x] Ricerca globale
- [x] Media viewer
- [x] Forward/Share
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
