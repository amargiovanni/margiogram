# Margiogram

> Un client Telegram nativo per macOS e iOS con design Liquid Glass, costruito interamente in Swift.

![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B%20%7C%20macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Panoramica

Margiogram è un client Telegram completo che sfrutta le API ufficiali di Telegram (TDLib) per offrire un'esperienza utente premium su dispositivi Apple. Il design Liquid Glass si adatta fluidamente tra iOS e macOS, mantenendo un'estetica moderna e coerente.

## Caratteristiche Principali

### Design Liquid Glass
- Effetti di trasparenza e blur dinamici
- Animazioni fluide e responsive
- Adattamento automatico alla modalità chiara/scura
- Supporto completo per Dynamic Island e StandBy Mode
- Interfaccia che scala perfettamente da iPhone a Mac

### Funzionalità Complete
- **Messaggistica completa**: testo, media, documenti, posizione, contatti
- **Chiamate**: audio e video con supporto per group calls
- **Gruppi e Canali**: gestione completa con ruoli e permessi
- **Sticker e GIF**: librerie complete con supporto animazioni
- **Bot**: interazione completa con inline mode
- **Ricerca**: globale e per chat con filtri avanzati
- **Sincronizzazione**: multi-dispositivo in tempo reale

## Requisiti di Sistema

### iOS
- iOS 17.0 o successivo
- iPhone, iPad, iPod touch

### macOS
- macOS 14.0 (Sonoma) o successivo
- Chip Apple Silicon o Intel

## Architettura

```
Margiogram/
├── App/
│   ├── MargiogramApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── TDLib/                    # Wrapper TDLib
│   │   ├── TDLibClient.swift
│   │   ├── TDLibManager.swift
│   │   └── Models/
│   ├── Database/                 # Core Data / SwiftData
│   │   ├── DataController.swift
│   │   └── Entities/
│   ├── Network/                  # Networking layer
│   │   ├── APIClient.swift
│   │   └── WebSocket/
│   └── Security/                 # Encryption & Auth
│       ├── KeychainManager.swift
│       └── EncryptionService.swift
├── Features/
│   ├── Auth/                     # Login e registrazione
│   ├── Chats/                    # Lista chat
│   ├── Conversation/             # Singola conversazione
│   ├── Contacts/                 # Rubrica
│   ├── Calls/                    # Chiamate audio/video
│   ├── Groups/                   # Gestione gruppi
│   ├── Channels/                 # Gestione canali
│   ├── Settings/                 # Impostazioni
│   ├── Profile/                  # Profilo utente
│   ├── Search/                   # Ricerca globale
│   ├── Media/                    # Galleria media
│   └── Stories/                  # Storie
├── UI/
│   ├── Components/               # Componenti riutilizzabili
│   │   ├── LiquidGlass/
│   │   ├── MessageBubble/
│   │   ├── AvatarView/
│   │   └── InputBar/
│   ├── Styles/                   # Stili e temi
│   └── Modifiers/                # View modifiers
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable/
│   └── Fonts/
└── Extensions/
    └── ...
```

## Stack Tecnologico

| Componente | Tecnologia |
|------------|------------|
| UI Framework | SwiftUI |
| Backend API | TDLib (Telegram Database Library) |
| Database Locale | SwiftData |
| Networking | URLSession + WebSocket |
| Media | AVFoundation, PhotosUI |
| Chiamate | WebRTC |
| Notifiche | UserNotifications, PushKit |
| Sicurezza | CryptoKit, Keychain |
| Animazioni | Core Animation, Metal |

## Installazione

### Prerequisites

1. **Xcode 15.0+** con Command Line Tools
2. **TDLib** compilato per le piattaforme target
3. **CocoaPods** o **Swift Package Manager**

### Setup TDLib

```bash
# Clona TDLib
git clone https://github.com/tdlib/td.git
cd td

# Build per iOS
mkdir build-ios && cd build-ios
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=../CMake/iOS.cmake \
      -DIOS_PLATFORM=OS64 ..
make -j4

# Build per macOS
cd ..
mkdir build-macos && cd build-macos
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j4
```

### Configurazione Progetto

1. Clona il repository:
```bash
git clone https://github.com/tuousername/margiogram.git
cd margiogram
```

2. Configura le API credentials:
```bash
cp Config.example.xcconfig Config.xcconfig
# Modifica Config.xcconfig con le tue API_ID e API_HASH
```

3. Apri il progetto in Xcode:
```bash
open Margiogram.xcodeproj
```

4. Build e run!

### Ottenere API Credentials

1. Vai su [my.telegram.org](https://my.telegram.org)
2. Accedi con il tuo numero di telefono
3. Vai su "API development tools"
4. Crea una nuova applicazione
5. Copia `api_id` e `api_hash`

## Configurazione

### Config.xcconfig

```xcconfig
// Telegram API
TELEGRAM_API_ID = your_api_id
TELEGRAM_API_HASH = your_api_hash

// App Configuration
APP_NAME = Margiogram
APP_BUNDLE_ID = com.yourname.margiogram

// Build Settings
DEVELOPMENT_TEAM = YOUR_TEAM_ID
```

### Info.plist Permissions

```xml
<key>NSCameraUsageDescription</key>
<string>Margiogram needs camera access for video calls and media capture</string>
<key>NSMicrophoneUsageDescription</key>
<string>Margiogram needs microphone access for voice messages and calls</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Margiogram needs photo library access to share media</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Margiogram needs location access to share your position</string>
<key>NSContactsUsageDescription</key>
<string>Margiogram needs contacts access to find your friends</string>
```

## Utilizzo

### Autenticazione

```swift
import Margiogram

// Inizializza il client
let client = TDLibClient(apiId: apiId, apiHash: apiHash)

// Login con numero di telefono
await client.authenticate(phoneNumber: "+391234567890")

// Verifica codice
await client.verifyCode("12345")

// (Opzionale) Password 2FA
await client.verify2FA(password: "your_password")
```

### Invio Messaggi

```swift
// Testo
await client.sendMessage(chatId: chatId, text: "Ciao!")

// Media
await client.sendPhoto(chatId: chatId, photo: imageData, caption: "Foto")

// Documento
await client.sendDocument(chatId: chatId, document: fileURL)

// Posizione
await client.sendLocation(chatId: chatId, latitude: 45.0, longitude: 9.0)
```

### Gestione Chat

```swift
// Ottieni lista chat
let chats = await client.getChats(limit: 100)

// Cerca messaggi
let results = await client.searchMessages(query: "keyword", chatId: chatId)

// Crea gruppo
let group = await client.createGroup(title: "Nuovo Gruppo", memberIds: [id1, id2])
```

## Design Liquid Glass

### Principi di Design

1. **Trasparenza Contestuale**: Gli elementi UI mostrano blur e trasparenza basati sul contenuto sottostante
2. **Profondità Visiva**: Uso di ombre e gradienti per creare gerarchia
3. **Fluidità**: Transizioni e animazioni smooth tra stati
4. **Adattabilità**: L'interfaccia si adatta al contesto (dispositivo, tema, contenuto)

### Implementazione

```swift
// Componente Liquid Glass base
struct LiquidGlassView<Content: View>: View {
    let content: Content

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// View Modifier
extension View {
    func liquidGlass() -> some View {
        modifier(LiquidGlassModifier())
    }
}
```

### Adattamento Cross-Platform

```swift
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // Layout iPhone
            NavigationStack { ... }
        } else {
            // Layout iPad/Mac
            NavigationSplitView { ... }
        }
    }
}
```

## Testing

### Unit Tests

```bash
xcodebuild test -scheme Margiogram -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### UI Tests

```bash
xcodebuild test -scheme MargiogramUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage

```bash
xcodebuild test -scheme Margiogram -enableCodeCoverage YES
```

## Performance

### Ottimizzazioni

- **Lazy Loading**: Immagini e media caricati on-demand
- **Caching Intelligente**: Cache multi-livello per media e messaggi
- **Background Fetch**: Sincronizzazione in background ottimizzata
- **Memory Management**: Gestione memoria aggressiva per liste lunghe

### Benchmark Target

| Operazione | Target |
|------------|--------|
| Avvio app | < 1s |
| Caricamento chat | < 100ms |
| Invio messaggio | < 50ms |
| Scroll lista | 60 FPS |

## Sicurezza

- **End-to-End Encryption**: Chat segrete con MTProto 2.0
- **Local Storage**: Dati sensibili in Keychain
- **Biometric Auth**: Face ID / Touch ID supportati
- **App Lock**: PIN/Password per protezione app

## Contribuire

### Workflow

1. Fork il repository
2. Crea un feature branch (`git checkout -b feature/amazing-feature`)
3. Commit le modifiche (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Apri una Pull Request

### Coding Guidelines

- Segui le [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Usa SwiftLint per il linting
- Scrivi test per nuove funzionalità
- Documenta con DocC

### Code Style

```swift
// MARK: - Properties
private let viewModel: ChatViewModel

// MARK: - Lifecycle
init(viewModel: ChatViewModel) {
    self.viewModel = viewModel
}

// MARK: - Methods
func sendMessage(_ text: String) async throws {
    // Implementation
}
```

## Roadmap

### v1.0 (MVP)
- [ ] Autenticazione
- [ ] Lista chat
- [ ] Messaggi testo
- [ ] Invio media base
- [ ] Notifiche push

### v1.1
- [ ] Chiamate audio
- [ ] Sticker
- [ ] GIF
- [ ] Ricerca avanzata

### v1.2
- [ ] Chiamate video
- [ ] Group calls
- [ ] Storie
- [ ] Temi personalizzati

### v2.0
- [ ] Widget iOS/macOS
- [ ] Shortcuts e Siri
- [ ] Apple Watch companion
- [ ] SharePlay integration

## Licenza

Distribuito sotto licenza MIT. Vedi `LICENSE` per maggiori informazioni.

## Riconoscimenti

- [TDLib](https://github.com/tdlib/td) - Telegram Database Library
- [WebRTC](https://webrtc.org/) - Real-time communication
- Design ispirato a iOS 18 e visionOS

## Contatti

Andrea Margiovanni - [@tuohandle](https://twitter.com/tuohandle)

Link Progetto: [https://github.com/tuousername/margiogram](https://github.com/tuousername/margiogram)

---

<p align="center">
  Made with ❤️ in Italy
</p>
