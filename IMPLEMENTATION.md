# Margiogram - Guida all'Implementazione

Questo documento descrive tutte le funzionalità da implementare per un client Telegram completo (account free) e le strategie di implementazione ad alto livello.

---

## Indice

1. [Autenticazione e Sicurezza](#1-autenticazione-e-sicurezza)
2. [Chat e Messaggistica](#2-chat-e-messaggistica)
3. [Media e File](#3-media-e-file)
4. [Chiamate e Videochiamate](#4-chiamate-e-videochiamate)
5. [Gruppi](#5-gruppi)
6. [Canali](#6-canali)
7. [Contatti](#7-contatti)
8. [Sticker, GIF e Emoji](#8-sticker-gif-e-emoji)
9. [Bot e Inline Mode](#9-bot-e-inline-mode)
10. [Ricerca](#10-ricerca)
11. [Storie](#11-storie)
12. [Notifiche](#12-notifiche)
13. [Impostazioni e Profilo](#13-impostazioni-e-profilo)
14. [Sincronizzazione e Storage](#14-sincronizzazione-e-storage)
15. [UI/UX Liquid Glass](#15-uiux-liquid-glass)
16. [Funzionalità Platform-Specific](#16-funzionalità-platform-specific)

---

## 1. Autenticazione e Sicurezza

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Login con numero | Autenticazione via SMS/Call | P0 |
| Codice verifica | Input e validazione codice | P0 |
| 2FA (Two-Factor Auth) | Password aggiuntiva | P0 |
| QR Code Login | Login tramite scansione QR | P1 |
| Logout | Disconnessione completa | P0 |
| Sessioni attive | Visualizzazione e gestione | P1 |
| Termina altre sessioni | Logout remoto | P1 |
| Cambio numero | Migrazione account | P2 |
| Elimina account | Cancellazione definitiva | P2 |
| Face ID / Touch ID | Blocco app biometrico | P1 |
| PIN / Password app | Blocco app manuale | P1 |
| Auto-lock | Blocco automatico dopo timeout | P1 |

### Implementazione

```swift
// MARK: - AuthenticationManager

class AuthenticationManager: ObservableObject {
    private let tdClient: TDLibClient

    enum AuthState {
        case waitPhoneNumber
        case waitCode(codeInfo: AuthCodeInfo)
        case waitPassword(hint: String)
        case waitRegistration
        case ready
    }

    @Published var state: AuthState = .waitPhoneNumber

    // Step 1: Invia numero di telefono
    func sendPhoneNumber(_ phone: String) async throws {
        try await tdClient.send(SetAuthenticationPhoneNumber(phoneNumber: phone))
        // TDLib risponderà con authorizationStateWaitCode
    }

    // Step 2: Verifica codice
    func verifyCode(_ code: String) async throws {
        try await tdClient.send(CheckAuthenticationCode(code: code))
    }

    // Step 3: (Opzionale) 2FA
    func verify2FA(_ password: String) async throws {
        try await tdClient.send(CheckAuthenticationPassword(password: password))
    }
}
```

**TDLib Methods:**
- `setAuthenticationPhoneNumber` - Avvia autenticazione
- `checkAuthenticationCode` - Verifica SMS/Call code
- `checkAuthenticationPassword` - Verifica 2FA
- `requestQrCodeAuthentication` - Login QR
- `getActiveSessions` - Lista sessioni
- `terminateSession` - Termina sessione
- `terminateAllOtherSessions` - Termina tutte le altre sessioni

---

## 2. Chat e Messaggistica

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Lista chat | Visualizzazione tutte le conversazioni | P0 |
| Chat privata | Conversazione 1-to-1 | P0 |
| Messaggi testo | Invio/ricezione testo | P0 |
| Formattazione | Bold, italic, mono, link, spoiler | P0 |
| Rispondi | Reply a messaggio specifico | P0 |
| Inoltra | Forward messaggi | P0 |
| Modifica | Edit messaggio inviato | P0 |
| Elimina | Delete per me/per tutti | P0 |
| Reazioni | Emoji reactions | P1 |
| Pin messaggio | Fissa messaggio in chat | P1 |
| Messaggi vocali | Registrazione e invio | P0 |
| Video messaggi | Registrazione circolare | P1 |
| Messaggi programmati | Scheduled messages | P2 |
| Messaggi silenziosi | Invio senza notifica | P1 |
| Messaggi auto-eliminanti | Self-destructing | P1 |
| Chat segrete | End-to-end encryption | P1 |
| Bozze | Draft messages | P1 |
| Typing indicator | "Sta scrivendo..." | P0 |
| Read receipts | Spunte blu | P0 |
| Quote | Citazione testo | P1 |
| Link preview | Anteprima URL | P0 |
| Traduzioni | Traduzione messaggi | P2 |
| Sondaggi | Creazione e voto | P1 |
| Quiz | Sondaggi con risposta corretta | P1 |

### Implementazione

```swift
// MARK: - ChatListViewModel

@MainActor
class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false

    private let tdClient: TDLibClient

    // Carica lista chat
    func loadChats() async {
        isLoading = true
        defer { isLoading = false }

        // TDLib usa un sistema di "chat list" con offset
        let result = try await tdClient.send(GetChats(
            chatList: .main,
            limit: 100
        ))

        // Carica dettagli per ogni chat
        for chatId in result.chatIds {
            let chat = try await tdClient.send(GetChat(chatId: chatId))
            chats.append(chat)
        }
    }
}

// MARK: - MessageViewModel

@MainActor
class MessageViewModel: ObservableObject {
    @Published var messages: [Message] = []

    // Invia messaggio testo
    func sendTextMessage(chatId: Int64, text: String, replyTo: Int64? = nil) async throws {
        let content = InputMessageText(
            text: FormattedText(text: text, entities: []),
            disableWebPagePreview: false,
            clearDraft: true
        )

        try await tdClient.send(SendMessage(
            chatId: chatId,
            messageThreadId: 0,
            replyTo: replyTo.map { .message(messageId: $0) },
            options: nil,
            inputMessageContent: content
        ))
    }

    // Modifica messaggio
    func editMessage(chatId: Int64, messageId: Int64, newText: String) async throws {
        try await tdClient.send(EditMessageText(
            chatId: chatId,
            messageId: messageId,
            inputMessageContent: InputMessageText(text: FormattedText(text: newText))
        ))
    }

    // Elimina messaggio
    func deleteMessages(chatId: Int64, messageIds: [Int64], forAll: Bool) async throws {
        try await tdClient.send(DeleteMessages(
            chatId: chatId,
            messageIds: messageIds,
            revoke: forAll
        ))
    }

    // Aggiungi reazione
    func addReaction(chatId: Int64, messageId: Int64, emoji: String) async throws {
        try await tdClient.send(AddMessageReaction(
            chatId: chatId,
            messageId: messageId,
            reactionType: .emoji(emoji),
            isBig: false,
            updateRecentReactions: true
        ))
    }
}
```

**TDLib Methods:**
- `getChats` - Lista chat
- `getChat` - Dettagli chat
- `sendMessage` - Invia messaggio
- `editMessageText` - Modifica testo
- `deleteMessages` - Elimina messaggi
- `forwardMessages` - Inoltra
- `addMessageReaction` - Aggiungi reazione
- `pinChatMessage` / `unpinChatMessage` - Pin/Unpin
- `setChatDraftMessage` - Salva bozza
- `sendChatAction` - Typing indicator

---

## 3. Media e File

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Foto | Invio/ricezione immagini | P0 |
| Video | Invio/ricezione video | P0 |
| Documenti | Qualsiasi tipo di file | P0 |
| Audio | File audio/musica | P1 |
| Messaggi vocali | Voice messages | P0 |
| Video messaggi | Round video | P1 |
| GIF | Animazioni | P1 |
| Posizione | Location sharing | P1 |
| Posizione live | Real-time location | P2 |
| Contatti | Condivisione contatto | P1 |
| Album | Gruppi di media | P1 |
| Compressione | Opzione qualità | P1 |
| Download manager | Gestione download | P1 |
| Cloud storage | File salvati | P2 |
| Media gallery | Galleria per chat | P1 |
| Anteprima media | Quick look | P0 |
| Editor foto | Crop, rotate, filter | P2 |
| Streaming video | Play senza download completo | P1 |

### Implementazione

```swift
// MARK: - MediaManager

class MediaManager {
    private let tdClient: TDLibClient
    private let fileManager: FileManager = .default
    private var downloadTasks: [Int32: Task<URL, Error>] = [:]

    // Invia foto
    func sendPhoto(
        chatId: Int64,
        imageData: Data,
        caption: String? = nil,
        spoiler: Bool = false
    ) async throws {
        // Salva temporaneamente
        let tempURL = saveTempFile(data: imageData, extension: "jpg")

        let content = InputMessagePhoto(
            photo: .local(path: tempURL.path),
            thumbnail: nil,
            addedStickerFileIds: [],
            width: 0,
            height: 0,
            caption: caption.map { FormattedText(text: $0) },
            showCaptionAboveMedia: false,
            selfDestructType: nil,
            hasSpoiler: spoiler
        )

        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: content
        ))
    }

    // Invia video
    func sendVideo(
        chatId: Int64,
        videoURL: URL,
        caption: String? = nil,
        supportsStreaming: Bool = true
    ) async throws {
        let content = InputMessageVideo(
            video: .local(path: videoURL.path),
            thumbnail: nil,
            addedStickerFileIds: [],
            duration: 0,
            width: 0,
            height: 0,
            supportsStreaming: supportsStreaming,
            caption: caption.map { FormattedText(text: $0) },
            showCaptionAboveMedia: false,
            selfDestructType: nil,
            hasSpoiler: false
        )

        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: content
        ))
    }

    // Download file con progress
    func downloadFile(fileId: Int32, priority: Int32 = 1) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Avvia download
                try await tdClient.send(DownloadFile(
                    fileId: fileId,
                    priority: priority,
                    offset: 0,
                    limit: 0,
                    synchronous: false
                ))

                // Ascolta aggiornamenti
                for await update in tdClient.updates {
                    if case .updateFile(let file) = update, file.id == fileId {
                        let progress = DownloadProgress(
                            downloaded: file.local.downloadedSize,
                            total: file.expectedSize
                        )
                        continuation.yield(progress)

                        if file.local.isDownloadingCompleted {
                            continuation.finish()
                            break
                        }
                    }
                }
            }
        }
    }

    // Invia posizione
    func sendLocation(
        chatId: Int64,
        latitude: Double,
        longitude: Double,
        livePeriod: Int32 = 0  // 0 = statica, >0 = live in secondi
    ) async throws {
        let content = InputMessageLocation(
            location: Location(latitude: latitude, longitude: longitude),
            livePeriod: livePeriod,
            heading: 0,
            proximityAlertRadius: 0
        )

        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: content
        ))
    }
}
```

**TDLib Methods:**
- `sendMessage` con vari `InputMessageContent`
- `downloadFile` - Download file
- `cancelDownloadFile` - Annulla download
- `uploadFile` - Upload manuale
- `getFile` - Info file
- `readFilePart` - Leggi parte di file
- `deleteFile` - Elimina file locale

---

## 4. Chiamate e Videochiamate

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Chiamata audio | Voice call 1-to-1 | P1 |
| Videochiamata | Video call 1-to-1 | P1 |
| Group call | Chiamate di gruppo | P2 |
| Screen sharing | Condivisione schermo | P2 |
| Picture-in-Picture | PiP durante chiamata | P1 |
| Mute/Unmute | Controllo microfono | P0 |
| Camera on/off | Controllo camera | P0 |
| Speaker/Earpiece | Switch audio output | P1 |
| Call history | Storico chiamate | P1 |
| Incoming call UI | Schermata chiamata in arrivo | P0 |
| CallKit integration | Integrazione sistema iOS | P1 |
| Noise cancellation | Riduzione rumore | P2 |

### Implementazione

```swift
// MARK: - CallManager

class CallManager: NSObject, ObservableObject {
    private let tdClient: TDLibClient
    private var callController: CXCallController?
    private var provider: CXProvider?

    @Published var activeCall: Call?
    @Published var callState: CallState = .idle

    enum CallState {
        case idle
        case ringing
        case connecting
        case active
        case ended
    }

    // Inizia chiamata
    func startCall(userId: Int64, isVideo: Bool) async throws {
        let call = try await tdClient.send(CreateCall(
            userId: userId,
            protocol: CallProtocol(
                udpP2p: true,
                udpReflector: true,
                minLayer: 65,
                maxLayer: 65,
                libraryVersions: ["3.0.0"]
            ),
            isVideo: isVideo
        ))

        activeCall = call
        callState = .ringing

        // Setup WebRTC
        setupWebRTC(call: call)
    }

    // Accetta chiamata
    func acceptCall(callId: Int32) async throws {
        try await tdClient.send(AcceptCall(
            callId: callId,
            protocol: CallProtocol(/* ... */)
        ))
        callState = .connecting
    }

    // Termina chiamata
    func endCall(callId: Int32) async throws {
        try await tdClient.send(DiscardCall(
            callId: callId,
            isDisconnected: false,
            duration: 0,
            isVideo: activeCall?.isVideo ?? false,
            connectionId: 0
        ))
        callState = .ended
    }

    // Setup WebRTC
    private func setupWebRTC(call: Call) {
        // Configura WebRTC per gestire audio/video
        // Usa le encryption key da TDLib
        // Connetti ai server TURN/STUN di Telegram
    }
}

// MARK: - Group Calls

class GroupCallManager: ObservableObject {
    @Published var participants: [GroupCallParticipant] = []
    @Published var isMuted = false
    @Published var isVideoEnabled = false

    // Unisciti a group call
    func joinGroupCall(chatId: Int64) async throws {
        let groupCall = try await tdClient.send(GetGroupCall(groupCallId: /* ... */))

        try await tdClient.send(JoinGroupCall(
            groupCallId: groupCall.id,
            participantId: nil,  // self
            audioSourceId: 0,
            payload: "",  // WebRTC SDP
            isMuted: true,
            isMyVideoEnabled: false,
            inviteHash: nil
        ))
    }

    // Toggle mute
    func toggleMute() async throws {
        isMuted.toggle()
        try await tdClient.send(ToggleGroupCallParticipantIsMuted(
            groupCallId: /* ... */,
            participantId: /* self */,
            isMuted: isMuted
        ))
    }
}
```

**TDLib Methods:**
- `createCall` - Avvia chiamata
- `acceptCall` - Accetta
- `discardCall` - Termina
- `sendCallRating` - Valuta qualità
- `getGroupCall` - Info group call
- `joinGroupCall` - Unisciti
- `leaveGroupCall` - Esci
- `toggleGroupCallParticipantIsMuted` - Mute participant
- `setGroupCallParticipantVolumeLevel` - Volume partecipante

---

## 5. Gruppi

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Crea gruppo | Nuovo gruppo base | P0 |
| Crea supergruppo | Gruppo con >200 membri | P1 |
| Aggiungi membri | Invita utenti | P0 |
| Rimuovi membri | Kick utenti | P0 |
| Admin | Promuovi/degrada admin | P1 |
| Permessi | Gestione permessi dettagliati | P1 |
| Link invito | Genera/gestisci invite link | P1 |
| Info gruppo | Nome, foto, descrizione | P0 |
| Modifica gruppo | Cambia info | P1 |
| Cerca membri | Ricerca partecipanti | P1 |
| Membri online | Conteggio online | P1 |
| Cronologia admin | Log azioni admin | P2 |
| Slow mode | Limite invio messaggi | P1 |
| Banned users | Lista bannati | P1 |
| Reply threads | Thread di risposte | P1 |
| Topics | Forum topics (supergruppi) | P2 |
| Anti-spam | Protezione spam | P2 |
| Join requests | Richieste di iscrizione | P2 |

### Implementazione

```swift
// MARK: - GroupManager

class GroupManager: ObservableObject {
    private let tdClient: TDLibClient

    // Crea gruppo base
    func createBasicGroup(title: String, userIds: [Int64]) async throws -> Chat {
        let chat = try await tdClient.send(CreateNewBasicGroupChat(
            userIds: userIds,
            title: title,
            messageAutoDeleteTime: 0
        ))
        return chat
    }

    // Crea supergruppo
    func createSupergroup(
        title: String,
        description: String,
        isChannel: Bool = false,
        isForum: Bool = false
    ) async throws -> Chat {
        let chat = try await tdClient.send(CreateNewSupergroupChat(
            title: title,
            isForum: isForum,
            isChannel: isChannel,
            description: description,
            location: nil,
            messageAutoDeleteTime: 0,
            forImport: false
        ))
        return chat
    }

    // Aggiungi membro
    func addMember(chatId: Int64, userId: Int64) async throws {
        try await tdClient.send(AddChatMember(
            chatId: chatId,
            userId: userId,
            forwardLimit: 100
        ))
    }

    // Rimuovi membro
    func removeMember(chatId: Int64, userId: Int64) async throws {
        try await tdClient.send(SetChatMemberStatus(
            chatId: chatId,
            memberId: .user(userId: userId),
            status: .left
        ))
    }

    // Promuovi ad admin
    func promoteToAdmin(
        chatId: Int64,
        userId: Int64,
        permissions: ChatAdminPermissions
    ) async throws {
        try await tdClient.send(SetChatMemberStatus(
            chatId: chatId,
            memberId: .user(userId: userId),
            status: .administrator(
                customTitle: permissions.customTitle,
                canBeEdited: true,
                rights: ChatAdministratorRights(
                    canManageChat: permissions.canManageChat,
                    canChangeInfo: permissions.canChangeInfo,
                    canPostMessages: permissions.canPostMessages,
                    canEditMessages: permissions.canEditMessages,
                    canDeleteMessages: permissions.canDeleteMessages,
                    canInviteUsers: permissions.canInviteUsers,
                    canRestrictMembers: permissions.canRestrictMembers,
                    canPinMessages: permissions.canPinMessages,
                    canManageTopics: permissions.canManageTopics,
                    canPromoteMembers: permissions.canPromoteMembers,
                    canManageVideoChats: permissions.canManageVideoChats,
                    canPostStories: false,
                    canEditStories: false,
                    canDeleteStories: false,
                    isAnonymous: permissions.isAnonymous
                )
            )
        ))
    }

    // Genera link invito
    func createInviteLink(
        chatId: Int64,
        expireDate: Date? = nil,
        memberLimit: Int32? = nil,
        createsJoinRequest: Bool = false
    ) async throws -> ChatInviteLink {
        let link = try await tdClient.send(CreateChatInviteLink(
            chatId: chatId,
            name: "",
            expirationDate: expireDate.map { Int32($0.timeIntervalSince1970) } ?? 0,
            memberLimit: memberLimit ?? 0,
            createsJoinRequest: createsJoinRequest
        ))
        return link
    }

    // Ottieni lista membri
    func getMembers(
        chatId: Int64,
        filter: SupergroupMembersFilter = .recent,
        offset: Int32 = 0,
        limit: Int32 = 200
    ) async throws -> [ChatMember] {
        // Per supergruppi
        let supergroup = try await tdClient.send(GetSupergroupMembers(
            supergroupId: /* extract from chat */,
            filter: filter,
            offset: offset,
            limit: limit
        ))
        return supergroup.members
    }
}

struct ChatAdminPermissions {
    var customTitle: String = ""
    var canManageChat: Bool = true
    var canChangeInfo: Bool = true
    var canPostMessages: Bool = true
    var canEditMessages: Bool = false
    var canDeleteMessages: Bool = true
    var canInviteUsers: Bool = true
    var canRestrictMembers: Bool = true
    var canPinMessages: Bool = true
    var canManageTopics: Bool = false
    var canPromoteMembers: Bool = false
    var canManageVideoChats: Bool = true
    var isAnonymous: Bool = false
}
```

**TDLib Methods:**
- `createNewBasicGroupChat` / `createNewSupergroupChat` - Crea gruppo
- `addChatMember` / `addChatMembers` - Aggiungi membri
- `setChatMemberStatus` - Modifica status membro
- `getChatMember` - Info membro
- `getSupergroupMembers` - Lista membri supergruppo
- `setChatPermissions` - Permessi gruppo
- `createChatInviteLink` - Crea invite link
- `getChatInviteLinks` - Lista invite links
- `setChatSlowModeDelay` - Imposta slow mode

---

## 6. Canali

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Crea canale | Nuovo canale | P1 |
| Post | Pubblica messaggi | P0 |
| Post programmati | Scheduled posts | P1 |
| Post silenziosi | Silent broadcast | P1 |
| Firma post | Author signature | P1 |
| Statistiche | Channel analytics | P2 |
| Discussione | Link a gruppo discussione | P2 |
| Admin | Gestione admin | P1 |
| Iscriviti/Esci | Join/Leave | P0 |
| Gestione iscritti | Subscriber management | P1 |

### Implementazione

```swift
// MARK: - ChannelManager

class ChannelManager: ObservableObject {
    private let tdClient: TDLibClient

    // Crea canale
    func createChannel(
        title: String,
        description: String
    ) async throws -> Chat {
        let chat = try await tdClient.send(CreateNewSupergroupChat(
            title: title,
            isForum: false,
            isChannel: true,  // <- Questo lo rende un canale
            description: description,
            location: nil,
            messageAutoDeleteTime: 0,
            forImport: false
        ))
        return chat
    }

    // Pubblica post
    func publishPost(
        channelId: Int64,
        content: InputMessageContent,
        disableNotification: Bool = false,
        scheduleDate: Date? = nil
    ) async throws {
        var options = MessageSendOptions(
            disableNotification: disableNotification,
            fromBackground: false,
            protectContent: false,
            updateOrderOfInstalledStickerSets: false,
            schedulingState: nil,
            effectId: 0,
            sendingId: 0,
            onlyPreview: false
        )

        if let date = scheduleDate {
            options.schedulingState = .scheduledForDate(sendDate: Int32(date.timeIntervalSince1970))
        }

        try await tdClient.send(SendMessage(
            chatId: channelId,
            messageThreadId: 0,
            replyTo: nil,
            options: options,
            inputMessageContent: content
        ))
    }

    // Toggle firma autore
    func toggleSignatures(chatId: Int64, enabled: Bool) async throws {
        try await tdClient.send(ToggleSupergroupSignMessages(
            supergroupId: /* extract from chat */,
            signMessages: enabled
        ))
    }

    // Ottieni statistiche (richiede TDLib 1.8+)
    func getStatistics(chatId: Int64) async throws -> ChatStatistics {
        let stats = try await tdClient.send(GetChatStatistics(
            chatId: chatId,
            isDark: false
        ))
        return stats
    }

    // Link gruppo discussione
    func setDiscussionGroup(channelId: Int64, groupId: Int64) async throws {
        try await tdClient.send(SetChatDiscussionGroup(
            chatId: channelId,
            discussionChatId: groupId
        ))
    }
}
```

**TDLib Methods:**
- `createNewSupergroupChat(isChannel: true)` - Crea canale
- `sendMessage` - Pubblica post
- `toggleSupergroupSignMessages` - Firma post
- `getChatStatistics` - Statistiche
- `setChatDiscussionGroup` - Link gruppo discussione
- `getSupergroupMembers` - Iscritti (con filtri)

---

## 7. Contatti

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Importa contatti | Sync rubrica | P0 |
| Lista contatti | Visualizza contatti | P0 |
| Cerca contatti | Ricerca locale | P0 |
| Aggiungi contatto | Manualmente | P0 |
| Rimuovi contatto | Elimina | P1 |
| Blocca utente | Block user | P0 |
| Sblocca utente | Unblock | P0 |
| Lista bloccati | Blocked list | P1 |
| Condividi contatto | Share contact | P1 |
| Privacy contatti | Chi può vedere | P1 |
| Cerca username | Cerca per @username | P0 |
| Nearby | Persone vicine | P2 |

### Implementazione

```swift
// MARK: - ContactsManager

class ContactsManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var contacts: [User] = []
    @Published var blockedUsers: [User] = []

    // Importa contatti dal dispositivo
    func importContacts(contacts: [CNContact]) async throws {
        let telegramContacts = contacts.map { contact -> Contact in
            Contact(
                phoneNumber: contact.phoneNumbers.first?.value.stringValue ?? "",
                firstName: contact.givenName,
                lastName: contact.familyName,
                vcard: "",
                userId: 0
            )
        }

        let result = try await tdClient.send(ImportContacts(contacts: telegramContacts))
        // result contiene userIds per contatti trovati
    }

    // Ottieni lista contatti
    func loadContacts() async throws {
        let users = try await tdClient.send(GetContacts())

        // Carica dettagli per ogni utente
        for userId in users.userIds {
            let user = try await tdClient.send(GetUser(userId: userId))
            contacts.append(user)
        }
    }

    // Aggiungi contatto
    func addContact(
        userId: Int64? = nil,
        phoneNumber: String,
        firstName: String,
        lastName: String = ""
    ) async throws {
        let contact = Contact(
            phoneNumber: phoneNumber,
            firstName: firstName,
            lastName: lastName,
            vcard: "",
            userId: userId ?? 0
        )

        try await tdClient.send(AddContact(
            contact: contact,
            sharePhoneNumber: false
        ))
    }

    // Rimuovi contatto
    func removeContact(userId: Int64) async throws {
        try await tdClient.send(RemoveContacts(userIds: [userId]))
    }

    // Blocca utente
    func blockUser(userId: Int64) async throws {
        try await tdClient.send(SetMessageSenderBlockList(
            senderId: .user(userId: userId),
            blockList: .main
        ))
    }

    // Sblocca utente
    func unblockUser(userId: Int64) async throws {
        try await tdClient.send(SetMessageSenderBlockList(
            senderId: .user(userId: userId),
            blockList: nil
        ))
    }

    // Cerca per username
    func searchByUsername(_ username: String) async throws -> User? {
        let chat = try await tdClient.send(SearchPublicChat(username: username))
        if case .private(let userId) = chat.type {
            return try await tdClient.send(GetUser(userId: userId))
        }
        return nil
    }

    // Cerca contatti
    func searchContacts(query: String, limit: Int32 = 50) async throws -> [User] {
        let result = try await tdClient.send(SearchContacts(query: query, limit: limit))
        return try await withThrowingTaskGroup(of: User.self) { group in
            for userId in result.userIds {
                group.addTask {
                    try await self.tdClient.send(GetUser(userId: userId))
                }
            }
            var users: [User] = []
            for try await user in group {
                users.append(user)
            }
            return users
        }
    }
}
```

**TDLib Methods:**
- `importContacts` - Importa contatti
- `getContacts` - Lista contatti
- `addContact` - Aggiungi
- `removeContacts` - Rimuovi
- `searchContacts` - Cerca
- `setMessageSenderBlockList` - Blocca/Sblocca
- `getBlockedMessageSenders` - Lista bloccati
- `searchPublicChat` - Cerca per username
- `searchChatsNearby` - Nearby

---

## 8. Sticker, GIF e Emoji

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Sticker statici | PNG stickers | P1 |
| Sticker animati | TGS (Lottie) stickers | P1 |
| Sticker video | WebM stickers | P1 |
| Sticker pack | Visualizza/installa pack | P1 |
| Sticker recenti | Recently used | P1 |
| Sticker preferiti | Favorites | P1 |
| Cerca sticker | Search by emoji | P1 |
| GIF | Animazioni GIF | P1 |
| GIF recenti | Recently used GIFs | P1 |
| Cerca GIF | Search GIFs | P1 |
| Emoji standard | Unicode emoji | P0 |
| Emoji custom | Custom emoji (come sticker) | P2 |
| Emoji status | Status emoji premium-like | P2 |
| Crea sticker | Sticker creator | P3 |

### Implementazione

```swift
// MARK: - StickerManager

class StickerManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var installedStickerSets: [StickerSet] = []
    @Published var recentStickers: [Sticker] = []
    @Published var favoriteStickers: [Sticker] = []

    // Carica sticker set installati
    func loadInstalledStickerSets() async throws {
        let result = try await tdClient.send(GetInstalledStickerSets(stickerType: .regular))

        for setId in result.sets.map({ $0.id }) {
            let stickerSet = try await tdClient.send(GetStickerSet(setId: setId))
            installedStickerSets.append(stickerSet)
        }
    }

    // Carica sticker recenti
    func loadRecentStickers() async throws {
        let result = try await tdClient.send(GetRecentStickers(isAttached: false))
        recentStickers = result.stickers
    }

    // Carica sticker preferiti
    func loadFavoriteStickers() async throws {
        let result = try await tdClient.send(GetFavoriteStickers())
        favoriteStickers = result.stickers
    }

    // Cerca sticker per emoji
    func searchStickers(emoji: String) async throws -> [Sticker] {
        let result = try await tdClient.send(GetStickers(
            stickerType: .regular,
            query: emoji,
            limit: 100,
            chatId: 0
        ))
        return result.stickers
    }

    // Installa sticker set
    func installStickerSet(setId: Int64) async throws {
        try await tdClient.send(ChangeStickerSet(
            setId: setId,
            isInstalled: true,
            isArchived: false
        ))
    }

    // Rimuovi sticker set
    func removeStickerSet(setId: Int64) async throws {
        try await tdClient.send(ChangeStickerSet(
            setId: setId,
            isInstalled: false,
            isArchived: false
        ))
    }

    // Aggiungi a preferiti
    func addToFavorites(sticker: Sticker) async throws {
        try await tdClient.send(AddFavoriteSticker(sticker: .id(id: sticker.sticker.id)))
    }

    // Invia sticker
    func sendSticker(chatId: Int64, sticker: Sticker) async throws {
        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: InputMessageSticker(
                sticker: .id(id: sticker.sticker.id),
                thumbnail: nil,
                width: sticker.width,
                height: sticker.height,
                emoji: sticker.emoji
            )
        ))
    }
}

// MARK: - GIFManager

class GIFManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var savedGifs: [Animation] = []

    // Carica GIF salvate
    func loadSavedGifs() async throws {
        let result = try await tdClient.send(GetSavedAnimations())
        savedGifs = result.animations
    }

    // Cerca GIF
    func searchGifs(query: String) async throws -> [Animation] {
        let result = try await tdClient.send(SearchInstalledStickerSets(
            stickerType: .regular,
            query: query,
            limit: 50
        ))
        // Usa inline bot @gif per ricerca più ampia
        return []
    }

    // Salva GIF
    func saveGif(animationId: Int32) async throws {
        try await tdClient.send(AddSavedAnimation(animation: .id(id: animationId)))
    }

    // Invia GIF
    func sendGif(chatId: Int64, animation: Animation) async throws {
        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: InputMessageAnimation(
                animation: .id(id: animation.animation.id),
                thumbnail: nil,
                addedStickerFileIds: [],
                duration: animation.duration,
                width: animation.width,
                height: animation.height,
                caption: nil,
                showCaptionAboveMedia: false,
                hasSpoiler: false
            )
        ))
    }
}
```

**TDLib Methods:**
- `getInstalledStickerSets` - Sticker installati
- `getStickerSet` - Dettagli set
- `searchStickerSet` - Cerca set
- `changeStickerSet` - Installa/rimuovi
- `getRecentStickers` - Recenti
- `getFavoriteStickers` - Preferiti
- `addFavoriteSticker` - Aggiungi a preferiti
- `getStickers` - Cerca per emoji
- `getSavedAnimations` - GIF salvate
- `addSavedAnimation` - Salva GIF
- `searchInstalledStickerSets` - Cerca tra installati

---

## 9. Bot e Inline Mode

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Comandi bot | /command | P1 |
| Inline query | @bot query | P1 |
| Inline results | Mostra risultati inline | P1 |
| Keyboard buttons | Reply keyboard | P1 |
| Inline buttons | Inline keyboard | P1 |
| Callback buttons | Button con callback | P1 |
| URL buttons | Button con link | P1 |
| Login button | Telegram Login | P2 |
| Web App button | Mini App / Web App | P2 |
| Game | Giochi Telegram | P2 |
| Payment | Pagamenti (come display) | P3 |
| Bot menu | Menu comandi | P1 |

### Implementazione

```swift
// MARK: - BotManager

class BotManager: ObservableObject {
    private let tdClient: TDLibClient

    // Invia comando
    func sendCommand(
        chatId: Int64,
        command: String,
        botUserId: Int64? = nil
    ) async throws {
        var commandEntity = TextEntity(
            offset: 0,
            length: Int32(command.count),
            type: .botCommand
        )

        try await tdClient.send(SendMessage(
            chatId: chatId,
            inputMessageContent: InputMessageText(
                text: FormattedText(text: command, entities: [commandEntity]),
                disableWebPagePreview: true,
                clearDraft: true
            )
        ))
    }

    // Inline query
    func performInlineQuery(
        botUserId: Int64,
        query: String,
        chatId: Int64? = nil
    ) async throws -> InlineQueryResults {
        let result = try await tdClient.send(GetInlineQueryResults(
            botUserId: botUserId,
            chatId: chatId ?? 0,
            userLocation: nil,
            query: query,
            offset: ""
        ))
        return result
    }

    // Invia risultato inline
    func sendInlineResult(
        chatId: Int64,
        queryId: Int64,
        resultId: String
    ) async throws {
        try await tdClient.send(SendInlineQueryResultMessage(
            chatId: chatId,
            messageThreadId: 0,
            replyTo: nil,
            options: nil,
            queryId: queryId,
            resultId: resultId,
            hideViaBot: false
        ))
    }

    // Gestisci callback button
    func answerCallbackQuery(
        chatId: Int64,
        messageId: Int64,
        callbackData: String
    ) async throws {
        try await tdClient.send(GetCallbackQueryAnswer(
            chatId: chatId,
            messageId: messageId,
            payload: .data(data: Data(callbackData.utf8))
        ))
    }

    // Ottieni comandi bot
    func getBotCommands(botUserId: Int64, chatId: Int64) async throws -> [BotCommand] {
        // I comandi sono spesso nel messaggio di benvenuto o nel profilo bot
        let user = try await tdClient.send(GetUser(userId: botUserId))
        // Estrai comandi da user.type.botInfo
        return []
    }

    // Apri Web App
    func openWebApp(
        chatId: Int64,
        botUserId: Int64,
        url: String
    ) async throws -> WebAppInfo {
        let result = try await tdClient.send(OpenWebApp(
            chatId: chatId,
            botUserId: botUserId,
            url: url,
            theme: nil,
            applicationName: "Margiogram",
            messageThreadId: 0,
            replyTo: nil
        ))
        return result
    }
}
```

**TDLib Methods:**
- `sendMessage` con comando - Invia comando
- `getInlineQueryResults` - Query inline
- `sendInlineQueryResultMessage` - Invia risultato
- `getCallbackQueryAnswer` - Rispondi a callback
- `openWebApp` - Apri Web App
- `getWebAppUrl` - URL Web App
- `closeWebApp` - Chiudi Web App

---

## 10. Ricerca

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Ricerca globale | Cerca ovunque | P0 |
| Ricerca in chat | Cerca in conversazione | P0 |
| Ricerca messaggi | Cerca testo messaggi | P0 |
| Ricerca media | Filtra per tipo media | P1 |
| Ricerca hashtag | Cerca #hashtag | P1 |
| Ricerca @mention | Cerca @username | P1 |
| Ricerca file | Cerca documenti | P1 |
| Ricerca link | Cerca URL | P1 |
| Filtri data | Per periodo | P1 |
| Filtri mittente | Per autore | P1 |
| Chat pubbliche | Cerca canali/gruppi pubblici | P1 |
| Recent searches | Cronologia ricerche | P2 |

### Implementazione

```swift
// MARK: - SearchManager

class SearchManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var searchResults: SearchResults = .empty

    struct SearchResults {
        var chats: [Chat] = []
        var messages: [Message] = []
        var publicChats: [Chat] = []

        static let empty = SearchResults()
    }

    // Ricerca globale
    func searchGlobal(query: String) async throws {
        // Cerca chat
        let chatsResult = try await tdClient.send(SearchChats(query: query, limit: 50))

        // Cerca messaggi globalmente
        let messagesResult = try await tdClient.send(SearchMessages(
            chatList: nil,
            onlyInChannels: false,
            query: query,
            offset: nil,
            limit: 100,
            filter: nil,
            minDate: 0,
            maxDate: 0
        ))

        // Cerca chat pubbliche
        let publicResult = try await tdClient.send(SearchPublicChats(query: query))

        searchResults = SearchResults(
            chats: chatsResult.chatIds.compactMap { /* load chat */ nil },
            messages: messagesResult.messages,
            publicChats: publicResult.chatIds.compactMap { /* load chat */ nil }
        )
    }

    // Ricerca in chat specifica
    func searchInChat(
        chatId: Int64,
        query: String,
        filter: SearchMessagesFilter? = nil,
        fromMessageId: Int64 = 0,
        fromDate: Date? = nil,
        toDate: Date? = nil,
        senderId: MessageSender? = nil
    ) async throws -> [Message] {
        let result = try await tdClient.send(SearchChatMessages(
            chatId: chatId,
            query: query,
            senderId: senderId,
            fromMessageId: fromMessageId,
            offset: 0,
            limit: 100,
            filter: filter,
            messageThreadId: 0,
            savedMessagesTopicId: 0
        ))
        return result.messages
    }

    // Ricerca solo media
    func searchMedia(
        chatId: Int64,
        filter: SearchMessagesFilter
    ) async throws -> [Message] {
        return try await searchInChat(
            chatId: chatId,
            query: "",
            filter: filter
        )
    }

    // Cerca chat pubbliche per username
    func searchPublicChat(username: String) async throws -> Chat? {
        let chat = try await tdClient.send(SearchPublicChat(username: username))
        return chat
    }

    // Hashtag search
    func searchHashtag(_ hashtag: String) async throws -> [Message] {
        return try await tdClient.send(SearchMessages(
            chatList: nil,
            onlyInChannels: false,
            query: hashtag,
            offset: nil,
            limit: 100,
            filter: nil,
            minDate: 0,
            maxDate: 0
        )).messages
    }
}

// Filtri disponibili
enum SearchMessagesFilter {
    case empty
    case animation
    case audio
    case document
    case photo
    case video
    case voiceNote
    case photoAndVideo
    case url
    case chatPhoto
    case videoNote
    case voiceAndVideoNote
    case mention
    case unreadMention
    case unreadReaction
    case failedToSend
    case pinned
}
```

**TDLib Methods:**
- `searchChats` - Cerca chat
- `searchMessages` - Cerca messaggi globalmente
- `searchChatMessages` - Cerca in chat
- `searchPublicChat` - Cerca per username
- `searchPublicChats` - Cerca chat pubbliche
- `getMessagePublicForwards` - Trova forward pubblici
- `getChatMessageByDate` - Trova per data

---

## 11. Storie

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Visualizza storie | Story viewer | P1 |
| Pubblica storia | Post story (foto/video) | P1 |
| Storie contatti | Lista storie amici | P1 |
| My stories | Le mie storie | P1 |
| Story reactions | Reazioni alle storie | P2 |
| Story views | Chi ha visto | P2 |
| Story privacy | Impostazioni privacy | P1 |
| Story highlight | Storie in evidenza | P2 |
| Story caption | Testo/link | P1 |
| Story editing | Modifica/elimina | P1 |
| Story archive | Archivio storie | P2 |

### Implementazione

```swift
// MARK: - StoryManager

class StoryManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var contactStories: [UserStories] = []
    @Published var myStories: [Story] = []

    struct UserStories: Identifiable {
        let id: Int64
        let user: User
        let stories: [Story]
        var hasUnread: Bool
    }

    // Carica storie contatti
    func loadContactStories() async throws {
        // Le storie sono gestite come chat list speciale
        let chatList = try await tdClient.send(GetChats(
            chatList: .story,
            limit: 100
        ))

        // Carica storie per ogni chat
        for chatId in chatList.chatIds {
            let stories = try await tdClient.send(GetChatActiveStories(chatId: chatId))
            // Processa storie
        }
    }

    // Pubblica storia
    func postStory(
        content: StoryContent,
        caption: String? = nil,
        privacy: StoryPrivacySettings = .contacts
    ) async throws {
        let inputContent: InputStoryContent

        switch content {
        case .photo(let data):
            let tempURL = saveTempFile(data: data, extension: "jpg")
            inputContent = .photo(photo: .local(path: tempURL.path), addedStickerFileIds: [])

        case .video(let url):
            inputContent = .video(
                video: .local(path: url.path),
                addedStickerFileIds: [],
                duration: 0,
                isAnimation: false
            )
        }

        try await tdClient.send(SendStory(
            chatId: 0,  // 0 = my profile
            content: inputContent,
            areas: nil,
            caption: caption.map { FormattedText(text: $0) },
            privacySettings: convertPrivacy(privacy),
            activePeriod: 86400,  // 24 ore
            fromStoryFullId: nil,
            isPostedToChatPage: true,
            protectContent: false
        ))
    }

    // Visualizza storia (marca come vista)
    func viewStory(chatId: Int64, storyId: Int32) async throws {
        try await tdClient.send(OpenStory(
            storySenderChatId: chatId,
            storyId: storyId
        ))
    }

    // Reagisci a storia
    func reactToStory(
        chatId: Int64,
        storyId: Int32,
        reaction: String
    ) async throws {
        try await tdClient.send(SetStoryReaction(
            storySenderChatId: chatId,
            storyId: storyId,
            reactionType: .emoji(reaction),
            updateRecentReactions: true
        ))
    }

    // Ottieni visualizzazioni
    func getStoryViews(storyId: Int32) async throws -> [StoryViewer] {
        let result = try await tdClient.send(GetStoryViewers(
            storyId: storyId,
            query: "",
            onlyContacts: false,
            preferWithReaction: false,
            offset: "",
            limit: 100
        ))
        return result.viewers
    }

    // Elimina storia
    func deleteStory(storyId: Int32) async throws {
        try await tdClient.send(DeleteStory(
            storySenderChatId: 0,
            storyId: storyId
        ))
    }

    enum StoryPrivacySettings {
        case everyone
        case contacts
        case closeFriends
        case selected([Int64])
    }

    enum StoryContent {
        case photo(Data)
        case video(URL)
    }
}
```

**TDLib Methods:**
- `getChatActiveStories` - Storie attive di una chat
- `sendStory` - Pubblica storia
- `editStory` - Modifica storia
- `deleteStory` - Elimina storia
- `openStory` - Marca come vista
- `closeStory` - Chiudi visualizzazione
- `setStoryReaction` - Reagisci
- `getStoryViewers` - Chi ha visto
- `getArchivedStories` - Archivio

---

## 12. Notifiche

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Push notifications | Notifiche remote | P0 |
| Local notifications | Notifiche locali | P0 |
| Badge count | Contatore icona | P0 |
| Sound | Suoni notifica | P1 |
| Vibration | Vibrazione (iOS) | P1 |
| Per-chat settings | Impostazioni per chat | P1 |
| Mute chat | Silenzia chat | P0 |
| Notification groups | Raggruppamento | P1 |
| Quick reply | Risposta rapida | P1 |
| Mark as read | Marca letto da notifica | P1 |
| Notification preview | Anteprima contenuto | P1 |
| Do Not Disturb | Modalità silenziosa | P1 |
| Schedule mute | Silenzia per periodo | P2 |

### Implementazione

```swift
// MARK: - NotificationManager

class NotificationManager: NSObject, ObservableObject {
    private let tdClient: TDLibClient
    private let center = UNUserNotificationCenter.current()

    @Published var notificationSettings: NotificationSettings = .default

    struct NotificationSettings {
        var showPreview: Bool = true
        var sound: Bool = true
        var vibrate: Bool = true
        var badgeEnabled: Bool = true

        static let `default` = NotificationSettings()
    }

    // Setup notifiche
    func setupNotifications() async throws {
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            let granted = try await center.requestAuthorization(options: [
                .alert, .badge, .sound, .provisional
            ])

            if granted {
                await registerForPushNotifications()
            }
        }
    }

    // Registra per push
    @MainActor
    func registerForPushNotifications() {
        #if os(iOS)
        UIApplication.shared.registerForRemoteNotifications()
        #elseif os(macOS)
        NSApplication.shared.registerForRemoteNotifications()
        #endif
    }

    // Invia token a Telegram
    func registerDeviceToken(_ token: Data) async throws {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()

        try await tdClient.send(RegisterDevice(
            deviceToken: .apns(deviceToken: tokenString, isAppSandbox: false),
            otherUserIds: []
        ))
    }

    // Mostra notifica locale
    func showLocalNotification(for message: Message, in chat: Chat) {
        let content = UNMutableNotificationContent()
        content.title = chat.title
        content.body = getMessagePreview(message)
        content.sound = .default
        content.badge = NSNumber(value: getUnreadCount())
        content.userInfo = [
            "chatId": chat.id,
            "messageId": message.id
        ]

        // Categoria per azioni
        content.categoryIdentifier = "MESSAGE"

        let request = UNNotificationRequest(
            identifier: "\(chat.id)_\(message.id)",
            content: content,
            trigger: nil
        )

        center.add(request)
    }

    // Mute chat
    func muteChat(chatId: Int64, duration: MuteDuration) async throws {
        let muteFor: Int32
        switch duration {
        case .oneHour: muteFor = 3600
        case .eightHours: muteFor = 28800
        case .twoDays: muteFor = 172800
        case .forever: muteFor = Int32.max
        case .custom(let seconds): muteFor = seconds
        }

        try await tdClient.send(SetChatNotificationSettings(
            chatId: chatId,
            notificationSettings: ChatNotificationSettings(
                useDefaultMuteFor: false,
                muteFor: muteFor,
                useDefaultSound: true,
                soundId: 0,
                useDefaultShowPreview: true,
                showPreview: true,
                useDefaultMuteStories: true,
                muteStories: false,
                useDefaultStorySound: true,
                storySoundId: 0,
                useDefaultShowStorySender: true,
                showStorySender: true,
                useDefaultDisablePinnedMessageNotifications: true,
                disablePinnedMessageNotifications: false,
                useDefaultDisableMentionNotifications: true,
                disableMentionNotifications: false
            )
        ))
    }

    enum MuteDuration {
        case oneHour
        case eightHours
        case twoDays
        case forever
        case custom(Int32)
    }

    // Setup categorie notifica
    func setupNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Message..."
        )

        let markReadAction = UNNotificationAction(
            identifier: "MARK_READ",
            title: "Mark as Read",
            options: []
        )

        let muteAction = UNNotificationAction(
            identifier: "MUTE",
            title: "Mute",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: "MESSAGE",
            actions: [replyAction, markReadAction, muteAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([category])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let chatId = userInfo["chatId"] as? Int64 else { return }

        switch response.actionIdentifier {
        case "REPLY":
            if let textResponse = response as? UNTextInputNotificationResponse {
                let text = textResponse.userText
                try? await sendQuickReply(chatId: chatId, text: text)
            }

        case "MARK_READ":
            try? await markAsRead(chatId: chatId)

        case "MUTE":
            try? await muteChat(chatId: chatId, duration: .eightHours)

        default:
            // Apri chat
            NotificationCenter.default.post(
                name: .openChat,
                object: nil,
                userInfo: ["chatId": chatId]
            )
        }
    }
}
```

**TDLib Methods:**
- `registerDevice` - Registra per push
- `getOption("notification_group_count_max")` - Limiti
- `setChatNotificationSettings` - Impostazioni per chat
- `setScopeNotificationSettings` - Impostazioni globali
- `getPushReceiverId` - ID per push

---

## 13. Impostazioni e Profilo

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Modifica profilo | Nome, bio, foto | P0 |
| Username | Imposta @username | P0 |
| Foto profilo | Aggiungi/rimuovi foto | P0 |
| Privacy numero | Chi vede il numero | P1 |
| Privacy ultimo accesso | Chi vede online status | P1 |
| Privacy foto profilo | Chi vede la foto | P1 |
| Privacy bio | Chi vede la bio | P1 |
| Privacy chiamate | Chi può chiamare | P1 |
| Privacy gruppi | Chi può aggiungere | P1 |
| Privacy forward | Collegamento forward | P1 |
| Password 2FA | Gestione 2FA | P1 |
| Email recupero | Email per 2FA | P1 |
| Sessioni attive | Gestione dispositivi | P1 |
| Storage usage | Uso memoria | P1 |
| Network usage | Uso dati | P2 |
| Lingua app | Language | P1 |
| Tema | Light/Dark/System | P0 |
| Dimensione testo | Font size | P1 |
| Auto-download | Settings media | P1 |
| Proxy | Configurazione proxy | P2 |
| Data e ora | Formato data/ora | P2 |
| Animazioni | Enable/disable | P1 |

### Implementazione

```swift
// MARK: - ProfileManager

class ProfileManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var currentUser: User?
    @Published var privacySettings: PrivacySettings = .default

    struct PrivacySettings {
        var phoneNumber: PrivacyRule = .contacts
        var lastSeen: PrivacyRule = .everyone
        var profilePhoto: PrivacyRule = .everyone
        var bio: PrivacyRule = .everyone
        var forwards: PrivacyRule = .everyone
        var calls: PrivacyRule = .everyone
        var groups: PrivacyRule = .everyone

        static let `default` = PrivacySettings()
    }

    enum PrivacyRule {
        case everyone
        case contacts
        case nobody
        case custom(allow: [Int64], disallow: [Int64])
    }

    // Carica profilo corrente
    func loadCurrentUser() async throws {
        currentUser = try await tdClient.send(GetMe())
    }

    // Modifica nome
    func updateName(firstName: String, lastName: String) async throws {
        try await tdClient.send(SetName(firstName: firstName, lastName: lastName))
    }

    // Modifica bio
    func updateBio(_ bio: String) async throws {
        try await tdClient.send(SetBio(bio: bio))
    }

    // Modifica username
    func updateUsername(_ username: String) async throws {
        try await tdClient.send(SetUsername(username: username))
    }

    // Imposta foto profilo
    func setProfilePhoto(imageData: Data) async throws {
        let tempURL = saveTempFile(data: imageData, extension: "jpg")

        try await tdClient.send(SetProfilePhoto(
            photo: .photo(photo: .local(path: tempURL.path), animation: nil),
            isPublic: true
        ))
    }

    // Rimuovi foto profilo
    func deleteProfilePhoto(photoId: Int64) async throws {
        try await tdClient.send(DeleteProfilePhoto(profilePhotoId: photoId))
    }

    // Privacy settings
    func updatePrivacySetting(_ setting: PrivacySettingType, rule: PrivacyRule) async throws {
        let rules: UserPrivacySettingRules

        switch rule {
        case .everyone:
            rules = UserPrivacySettingRules(rules: [.allowAll])
        case .contacts:
            rules = UserPrivacySettingRules(rules: [.allowContacts])
        case .nobody:
            rules = UserPrivacySettingRules(rules: [.restrictAll])
        case .custom(let allow, let disallow):
            var ruleList: [UserPrivacySettingRule] = [.restrictAll]
            if !allow.isEmpty {
                ruleList.append(.allowUsers(userIds: allow))
            }
            if !disallow.isEmpty {
                ruleList.append(.restrictUsers(userIds: disallow))
            }
            rules = UserPrivacySettingRules(rules: ruleList)
        }

        try await tdClient.send(SetUserPrivacySettingRules(
            setting: convertSetting(setting),
            rules: rules
        ))
    }

    enum PrivacySettingType {
        case phoneNumber
        case lastSeen
        case profilePhoto
        case bio
        case forwards
        case calls
        case groups
    }
}

// MARK: - SettingsManager

class SettingsManager: ObservableObject {
    private let tdClient: TDLibClient

    @Published var theme: AppTheme = .system
    @Published var fontSize: FontSize = .medium
    @Published var autoDownloadSettings: AutoDownloadSettings = .default

    enum AppTheme: String, CaseIterable {
        case light, dark, system
    }

    enum FontSize: Int, CaseIterable {
        case small = 14
        case medium = 16
        case large = 18
        case extraLarge = 20
    }

    struct AutoDownloadSettings {
        var photos: AutoDownloadRule = .always
        var videos: AutoDownloadRule = .wifi
        var files: AutoDownloadRule = .never
        var voiceNotes: AutoDownloadRule = .always
        var videoNotes: AutoDownloadRule = .wifi

        static let `default` = AutoDownloadSettings()
    }

    enum AutoDownloadRule {
        case always
        case wifi
        case never
    }

    // Ottieni storage usage
    func getStorageUsage() async throws -> StorageStatistics {
        let stats = try await tdClient.send(GetStorageStatistics(chatLimit: 100))
        return stats
    }

    // Ottimizza storage
    func optimizeStorage(
        maxSize: Int64,
        ttl: Int32 = 60 * 60 * 24 * 7,  // 7 giorni
        keepMedia: [FileType] = []
    ) async throws -> StorageStatistics {
        let result = try await tdClient.send(OptimizeStorage(
            size: maxSize,
            ttl: ttl,
            count: Int32.max,
            immunityDelay: 0,
            fileTypes: nil,
            chatIds: [],
            excludeChatIds: [],
            returnDeletedFileStatistics: true,
            chatLimit: 100
        ))
        return result
    }

    // Sessioni attive
    func getActiveSessions() async throws -> [Session] {
        let result = try await tdClient.send(GetActiveSessions())
        return result.sessions
    }

    // Termina sessione
    func terminateSession(sessionId: Int64) async throws {
        try await tdClient.send(TerminateSession(sessionId: sessionId))
    }

    // Termina tutte le altre sessioni
    func terminateAllOtherSessions() async throws {
        try await tdClient.send(TerminateAllOtherSessions())
    }

    // Imposta password 2FA
    func set2FAPassword(
        oldPassword: String?,
        newPassword: String,
        hint: String,
        email: String?
    ) async throws {
        try await tdClient.send(SetPassword(
            oldPassword: oldPassword ?? "",
            newPassword: newPassword,
            newHint: hint,
            setRecoveryEmailAddress: email != nil,
            newRecoveryEmailAddress: email ?? ""
        ))
    }

    // Proxy settings
    func addProxy(
        server: String,
        port: Int32,
        type: ProxyType
    ) async throws -> Proxy {
        let proxyType: TDProxyType
        switch type {
        case .socks5(let username, let password):
            proxyType = .socks5(username: username, password: password)
        case .http(let username, let password):
            proxyType = .http(username: username, password: password, httpOnly: false)
        case .mtproto(let secret):
            proxyType = .mtproto(secret: secret)
        }

        let proxy = try await tdClient.send(AddProxy(
            server: server,
            port: port,
            enable: true,
            type: proxyType
        ))
        return proxy
    }

    enum ProxyType {
        case socks5(username: String, password: String)
        case http(username: String, password: String)
        case mtproto(secret: String)
    }
}
```

**TDLib Methods:**
- `getMe` - Utente corrente
- `setName` - Modifica nome
- `setBio` - Modifica bio
- `setUsername` - Modifica username
- `setProfilePhoto` - Imposta foto
- `deleteProfilePhoto` - Rimuovi foto
- `setUserPrivacySettingRules` - Privacy
- `getStorageStatistics` - Uso storage
- `optimizeStorage` - Pulisci storage
- `getNetworkStatistics` - Uso rete
- `getActiveSessions` - Sessioni
- `terminateSession` - Termina sessione
- `setPassword` - 2FA password
- `addProxy` / `editProxy` / `removeProxy` - Proxy

---

## 14. Sincronizzazione e Storage

### Funzionalità

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Sync messaggi | Sincronizzazione real-time | P0 |
| Sync media | Download automatico | P1 |
| Cache locale | Cache intelligente | P0 |
| Database locale | Persistenza dati | P0 |
| Sync contatti | Sincronizzazione contatti | P1 |
| Background sync | Sync in background | P1 |
| Sync state | Gestione stato sync | P0 |
| Conflict resolution | Risoluzione conflitti | P1 |
| Offline mode | Funzionalità offline | P1 |
| Queue messaggi | Coda invio offline | P1 |

### Implementazione

```swift
// MARK: - SyncManager

class SyncManager: ObservableObject {
    private let tdClient: TDLibClient
    private let dataController: DataController

    @Published var syncState: SyncState = .idle
    @Published var connectionState: ConnectionState = .waitingForNetwork

    enum SyncState {
        case idle
        case syncing(progress: Double)
        case completed
        case failed(Error)
    }

    enum ConnectionState {
        case waitingForNetwork
        case connectingToProxy
        case connecting
        case updating
        case ready
    }

    // Ascolta aggiornamenti TDLib
    func startListening() {
        Task {
            for await update in tdClient.updates {
                await handleUpdate(update)
            }
        }
    }

    @MainActor
    private func handleUpdate(_ update: Update) async {
        switch update {
        case .updateConnectionState(let state):
            updateConnectionState(state.state)

        case .updateNewMessage(let message):
            await processNewMessage(message.message)

        case .updateMessageContent(let content):
            await updateMessageContent(
                chatId: content.chatId,
                messageId: content.messageId,
                content: content.newContent
            )

        case .updateDeleteMessages(let info):
            await deleteMessages(
                chatId: info.chatId,
                messageIds: info.messageIds
            )

        case .updateChatReadInbox(let info):
            await updateReadState(
                chatId: info.chatId,
                lastReadId: info.lastReadInboxMessageId
            )

        case .updateUserStatus(let status):
            await updateUserStatus(
                userId: status.userId,
                status: status.status
            )

        case .updateFile(let file):
            await handleFileUpdate(file.file)

        default:
            break
        }
    }

    // Processa nuovo messaggio
    private func processNewMessage(_ message: Message) async {
        // Salva in database locale
        await dataController.saveMessage(message)

        // Notifica UI
        NotificationCenter.default.post(
            name: .newMessage,
            object: nil,
            userInfo: ["message": message]
        )

        // Mostra notifica se necessario
        if shouldShowNotification(for: message) {
            notificationManager.showLocalNotification(for: message)
        }
    }

    // Background fetch
    func performBackgroundFetch() async -> BackgroundFetchResult {
        do {
            // Riconnetti se necessario
            if connectionState != .ready {
                try await reconnect()
            }

            // Forza sync
            try await tdClient.send(GetChats(chatList: .main, limit: 10))

            return .newData
        } catch {
            return .failed
        }
    }

    enum BackgroundFetchResult {
        case newData
        case noData
        case failed
    }
}

// MARK: - DataController (SwiftData)

@MainActor
class DataController: ObservableObject {
    let container: ModelContainer

    init() throws {
        let schema = Schema([
            CachedChat.self,
            CachedMessage.self,
            CachedUser.self,
            CachedFile.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        container = try ModelContainer(for: schema, configurations: config)
    }

    // Salva messaggio
    func saveMessage(_ message: Message) async {
        let cached = CachedMessage(from: message)
        container.mainContext.insert(cached)
        try? container.mainContext.save()
    }

    // Ottieni messaggi cached
    func getCachedMessages(chatId: Int64, limit: Int = 50) async -> [CachedMessage] {
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.chatId == chatId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? container.mainContext.fetch(descriptor)) ?? []
    }

    // Pulisci cache vecchia
    func cleanOldCache(olderThan days: Int = 30) async {
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))

        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: #Predicate { $0.cacheDate < cutoffDate }
        )

        if let old = try? container.mainContext.fetch(descriptor) {
            for item in old {
                container.mainContext.delete(item)
            }
            try? container.mainContext.save()
        }
    }
}

// MARK: - SwiftData Models

@Model
class CachedChat {
    @Attribute(.unique) var id: Int64
    var title: String
    var lastMessageDate: Date?
    var unreadCount: Int32
    var cacheDate: Date

    init(from chat: Chat) {
        self.id = chat.id
        self.title = chat.title
        self.unreadCount = chat.unreadCount
        self.cacheDate = Date()
    }
}

@Model
class CachedMessage {
    @Attribute(.unique) var id: Int64
    var chatId: Int64
    var senderId: Int64
    var content: Data  // Serialized content
    var date: Date
    var cacheDate: Date

    init(from message: Message) {
        self.id = message.id
        self.chatId = message.chatId
        self.date = Date(timeIntervalSince1970: Double(message.date))
        self.cacheDate = Date()
        // Serialize content
    }
}
```

**TDLib Updates to handle:**
- `updateConnectionState` - Stato connessione
- `updateNewMessage` - Nuovo messaggio
- `updateMessageContent` - Contenuto modificato
- `updateDeleteMessages` - Messaggi eliminati
- `updateChatReadInbox` - Letto inbox
- `updateChatReadOutbox` - Letto outbox
- `updateUserStatus` - Stato utente
- `updateFile` - Aggiornamento file
- `updateChatLastMessage` - Ultimo messaggio chat

---

## 15. UI/UX Liquid Glass

### Componenti

| Componente | Descrizione | Priorità |
|------------|-------------|----------|
| LiquidGlassView | Container base glass | P0 |
| GlassNavigationBar | Navbar trasparente | P0 |
| GlassTabBar | Tab bar glass | P0 |
| MessageBubble | Bubble messaggi glass | P0 |
| ChatListRow | Row lista chat | P0 |
| AvatarView | Avatar con bordo glass | P0 |
| InputBar | Barra input glass | P0 |
| ActionSheet | Sheet glass | P1 |
| ContextMenu | Menu contestuale glass | P1 |
| FloatingButton | FAB glass | P1 |
| SearchBar | Barra ricerca glass | P0 |
| MediaViewer | Viewer fullscreen | P1 |
| CallUI | Interfaccia chiamata | P1 |
| StoryViewer | Viewer storie | P1 |

### Implementazione

```swift
// MARK: - Liquid Glass Design System

// Base glass effect
struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    var intensity: GlassIntensity = .regular
    var cornerRadius: CGFloat = 20

    enum GlassIntensity {
        case ultraThin, thin, regular, thick, ultraThick

        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .ultraThick: return .ultraThickMaterial
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .background(intensity.material)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(colorScheme == .dark ? 0.05 : 0.3),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}

extension View {
    func liquidGlass(
        intensity: LiquidGlassModifier.GlassIntensity = .regular,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(LiquidGlassModifier(intensity: intensity, cornerRadius: cornerRadius))
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromMe: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                // Content
                messageContent

                // Time & status
                HStack(spacing: 4) {
                    Text(formatTime(message.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if isFromMe {
                        Image(systemName: readStatusIcon)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(bubbleBackground)
            .clipShape(BubbleShape(isFromMe: isFromMe))

            if !isFromMe { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    var messageContent: some View {
        switch message.content {
        case .text(let text):
            Text(text.text.text)
                .font(.body)

        case .photo(let photo):
            AsyncImage(url: photo.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(maxWidth: 250, maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        default:
            Text("[Unsupported content]")
                .italic()
                .foregroundStyle(.secondary)
        }
    }

    var bubbleBackground: some View {
        Group {
            if isFromMe {
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Material.regularMaterial
                    .overlay(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}

struct BubbleShape: Shape {
    let isFromMe: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromMe {
            // Bubble con coda a destra
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            // Tail
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX + tailSize, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Bubble con coda a sinistra - mirror
            // ...similar implementation
        }

        return path
    }
}

// MARK: - Chat List Row

struct ChatListRow: View {
    let chat: Chat
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(chat: chat, size: 56)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text(formatDate(chat.lastMessage?.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if let lastMessage = chat.lastMessage {
                        Text(messagePreview(lastMessage))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isPressed ? Color.primary.opacity(0.05) : Color.clear)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let chat: Chat
    let size: CGFloat

    var body: some View {
        Group {
            if let photoUrl = chat.photo?.small {
                AsyncImage(url: photoUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderAvatar
                }
            } else {
                placeholderAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    var placeholderAvatar: some View {
        ZStack {
            LinearGradient(
                colors: avatarColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    var initials: String {
        chat.title.prefix(2).uppercased()
    }

    var avatarColors: [Color] {
        // Colori basati su hash del titolo
        let hash = abs(chat.title.hashValue)
        let colorPairs: [[Color]] = [
            [.red, .orange],
            [.orange, .yellow],
            [.green, .mint],
            [.teal, .cyan],
            [.blue, .indigo],
            [.purple, .pink]
        ]
        return colorPairs[hash % colorPairs.count]
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    let onAttachment: () -> Void

    @FocusState private var isFocused: Bool
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 12) {
            // Attachment button
            Button(action: onAttachment) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // Text field
            HStack {
                TextField("Message", text: $text, axis: .vertical)
                    .focused($isFocused)
                    .lineLimit(1...5)

                // Emoji button
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Send / Voice button
            Button(action: text.isEmpty ? startRecording : onSend) {
                Image(systemName: text.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(text.isEmpty ? .secondary : .accent)
            }
            .scaleEffect(isRecording ? 1.2 : 1.0)
            .animation(.spring(response: 0.3), value: isRecording)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func startRecording() {
        isRecording = true
        // Start audio recording
    }
}

// MARK: - Adaptive Layout

struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @StateObject var appState = AppState()

    var body: some View {
        Group {
            #if os(iOS)
            if sizeClass == .compact {
                // iPhone layout
                iPhoneLayout
            } else {
                // iPad layout
                iPadLayout
            }
            #elseif os(macOS)
            // macOS layout
            macOSLayout
            #endif
        }
        .environmentObject(appState)
    }

    var iPhoneLayout: some View {
        NavigationStack {
            ChatListView()
                .navigationDestination(for: Chat.self) { chat in
                    ConversationView(chat: chat)
                }
        }
    }

    var iPadLayout: some View {
        NavigationSplitView {
            ChatListView()
        } detail: {
            if let chat = appState.selectedChat {
                ConversationView(chat: chat)
            } else {
                ContentUnavailableView(
                    "Select a Chat",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation from the list")
                )
            }
        }
    }

    #if os(macOS)
    var macOSLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar con cartelle
            SidebarView()
        } content: {
            // Lista chat
            ChatListView()
        } detail: {
            // Conversazione
            if let chat = appState.selectedChat {
                ConversationView(chat: chat)
            } else {
                ContentUnavailableView(
                    "Select a Chat",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Choose a conversation from the list")
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    #endif
}
```

---

## 16. Funzionalità Platform-Specific

### iOS

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Dynamic Island | Live Activities per chiamate | P2 |
| StandBy Mode | Widget StandBy | P2 |
| Lock Screen Widgets | Widget schermata blocco | P2 |
| Home Screen Widgets | Widget home | P1 |
| Live Activities | Attività in tempo reale | P2 |
| Siri Shortcuts | Scorciatoie Siri | P2 |
| Share Extension | Condivisione da altre app | P1 |
| App Intents | Intents per Siri | P2 |
| iCloud Sync | Sync preferenze | P2 |
| Haptic Feedback | Feedback tattile | P1 |
| 3D Touch / Haptic Touch | Quick actions | P1 |
| PiP | Picture in Picture video | P1 |
| CallKit | Integrazione chiamate | P1 |
| SharePlay | Attività condivise | P3 |

### macOS

| Feature | Descrizione | Priorità |
|---------|-------------|----------|
| Menu Bar | Icona menu bar | P1 |
| Notifications | Notifiche native | P0 |
| Keyboard Shortcuts | Scorciatoie tastiera | P1 |
| Touch Bar | Supporto Touch Bar | P3 |
| Drag & Drop | Drag file/media | P1 |
| Quick Look | Anteprima file | P1 |
| Spotlight | Ricerca Spotlight | P2 |
| Desktop Widgets | Widget desktop | P2 |
| Menu Bar Extra | App menu bar | P2 |
| Multi-window | Finestre multiple | P1 |
| Full Screen | Supporto fullscreen | P1 |
| Split View | Affiancamento finestre | P1 |

### Implementazione

```swift
// MARK: - iOS Specific

#if os(iOS)

// Widget
struct ChatWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ChatWidget",
            provider: ChatWidgetProvider()
        ) { entry in
            ChatWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Chats")
        .description("Quick access to your recent conversations")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Live Activity per chiamate
struct CallActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var callDuration: TimeInterval
        var isMuted: Bool
        var isVideoEnabled: Bool
    }

    var callerName: String
    var callerPhoto: Data?
}

// Dynamic Island
struct CallLiveActivity: View {
    let context: ActivityViewContext<CallActivityAttributes>

    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(.green)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading) {
                Text(context.attributes.callerName)
                    .font(.headline)
                Text(formatDuration(context.state.callDuration))
                    .font(.caption)
            }

            Spacer()

            // Controls
            Button(action: {}) {
                Image(systemName: context.state.isMuted ? "mic.slash.fill" : "mic.fill")
            }

            Button(action: {}) {
                Image(systemName: "phone.down.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

// App Shortcuts
struct MargiogramShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SendMessageIntent(),
            phrases: [
                "Send a message with \(.applicationName)",
                "Message \(\.$contact) on \(.applicationName)"
            ],
            shortTitle: "Send Message",
            systemImageName: "message"
        )
    }
}

// Share Extension
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            return
        }

        // Processa allegati e mostra UI per selezionare chat
    }
}

#endif

// MARK: - macOS Specific

#if os(macOS)

// Menu Bar App
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "paperplane.fill", accessibilityDescription: nil)
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: QuickChatView())
        popover?.behavior = .transient
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

// Keyboard Shortcuts
struct KeyboardShortcuts {
    static let newMessage = KeyboardShortcut("n", modifiers: .command)
    static let search = KeyboardShortcut("f", modifiers: .command)
    static let settings = KeyboardShortcut(",", modifiers: .command)
    static let nextChat = KeyboardShortcut(.downArrow, modifiers: [.command, .option])
    static let previousChat = KeyboardShortcut(.upArrow, modifiers: [.command, .option])
    static let markAsRead = KeyboardShortcut("r", modifiers: .command)
    static let archive = KeyboardShortcut("e", modifiers: .command)
    static let delete = KeyboardShortcut(.delete, modifiers: .command)
}

// Multi-window support
struct ContentView: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        // ...
        Button("Open in New Window") {
            openWindow(id: "conversation", value: chatId)
        }
    }
}

#endif

// MARK: - Shared Extensions

extension View {
    @ViewBuilder
    func platformSpecific() -> some View {
        #if os(iOS)
        self
            .sensoryFeedback(.impact, trigger: /* trigger */)
        #elseif os(macOS)
        self
            .keyboardShortcut(/* shortcut */)
        #endif
    }
}
```

---

## Checklist Implementazione

### Fase 1: Core (Settimane 1-4)
- [ ] Setup progetto Xcode
- [ ] Integrazione TDLib
- [ ] Sistema autenticazione completo
- [ ] Lista chat base
- [ ] Messaggi testo base
- [ ] Database locale (SwiftData)
- [ ] Design system Liquid Glass base

### Fase 2: Messaggistica Avanzata (Settimane 5-8)
- [ ] Media (foto, video, documenti)
- [ ] Messaggi vocali
- [ ] Rispondi/Inoltra/Modifica/Elimina
- [ ] Reazioni
- [ ] Formattazione testo
- [ ] Link preview
- [ ] Typing indicators

### Fase 3: Gruppi e Contatti (Settimane 9-12)
- [ ] Gestione gruppi completa
- [ ] Canali
- [ ] Contatti
- [ ] Ricerca globale
- [ ] Sticker e GIF

### Fase 4: Chiamate e Media (Settimane 13-16)
- [ ] Chiamate audio
- [ ] Videochiamate
- [ ] Group calls
- [ ] Media viewer
- [ ] Editor foto base

### Fase 5: Features Avanzate (Settimane 17-20)
- [ ] Storie
- [ ] Bot e inline mode
- [ ] Notifiche avanzate
- [ ] Widget iOS/macOS
- [ ] Siri Shortcuts

### Fase 6: Polish e Ottimizzazione (Settimane 21-24)
- [ ] Performance tuning
- [ ] Animazioni avanzate
- [ ] Accessibilità
- [ ] Localizzazione
- [ ] Testing completo
- [ ] Beta testing

---

## Note Tecniche

### TDLib Integration

TDLib è una libreria C++ che gestisce tutta la logica Telegram. Per integrarla in Swift:

1. **Build TDLib** per iOS/macOS
2. **Crea wrapper Swift** usando il binding JSON
3. **Gestisci updates** in modo asincrono

```swift
// Esempio wrapper base
actor TDLibClient {
    private var client: UnsafeMutableRawPointer?

    init() {
        client = td_json_client_create()
    }

    func send<T: TDFunction>(_ function: T) async throws -> T.Result {
        let json = try JSONEncoder().encode(function)
        let jsonString = String(data: json, encoding: .utf8)!

        td_json_client_send(client, jsonString)

        // Wait for response...
    }

    var updates: AsyncStream<Update> {
        AsyncStream { continuation in
            Task {
                while true {
                    if let result = td_json_client_receive(client, 1.0) {
                        let data = String(cString: result).data(using: .utf8)!
                        if let update = try? JSONDecoder().decode(Update.self, from: data) {
                            continuation.yield(update)
                        }
                    }
                }
            }
        }
    }
}
```

### Security Considerations

1. **API Credentials**: Mai committare `api_id` e `api_hash`
2. **Keychain**: Usare Keychain per token e credenziali
3. **Encryption**: Chat segrete usano MTProto 2.0
4. **Certificate Pinning**: Implementare per connessioni TDLib
5. **Biometric**: Usare LocalAuthentication framework

### Performance Tips

1. **Lazy Loading**: Caricare messaggi/media on-demand
2. **Image Caching**: Cache multi-livello con NSCache + disk
3. **Background Fetch**: Ottimizzare per battery life
4. **Memory Management**: Rilasciare risorse non visibili
5. **List Virtualization**: Usare LazyVStack per liste lunghe
