---
model: claude-sonnet-4-5-20250929
description: Code review command for Margiogram
updated: 2025-11
---

# Code Review Command

Esegui una code review approfondita del codice specificato.

## Utilizzo

```
/review [file_path o modulo]
```

## Checklist Review

### 1. Correttezza Funzionale
- [ ] Il codice fa quello che dovrebbe?
- [ ] Edge cases gestiti correttamente?
- [ ] Error handling appropriato?
- [ ] Nessun bug logico evidente?

### 2. Sicurezza
- [ ] Input validation presente?
- [ ] Nessun dato sensibile esposto?
- [ ] Uso corretto di Keychain per secrets?
- [ ] Nessuna vulnerabilità OWASP?

### 3. Performance
- [ ] Nessun potential memory leak?
- [ ] Operazioni pesanti su background thread?
- [ ] Lazy loading implementato dove serve?
- [ ] Caching appropriato?

### 4. Qualità Codice
- [ ] Naming chiaro e consistente?
- [ ] Nessuna duplicazione?
- [ ] Single Responsibility Principle rispettato?
- [ ] Funzioni non troppo lunghe (< 50 righe)?

### 5. SwiftUI Best Practices
- [ ] State management corretto (@State, @StateObject, @Observable)?
- [ ] View non troppo complesse (estrazione subviews)?
- [ ] Animazioni smooth?
- [ ] Preview funzionanti?

### 6. Testabilità
- [ ] Dependency injection usato?
- [ ] Codice facilmente testabile?
- [ ] Mock-friendly interfaces?

### 7. Accessibilità
- [ ] Accessibility labels presenti?
- [ ] VoiceOver funzionante?
- [ ] Dynamic Type supportato?

### 8. Documentazione
- [ ] API pubbliche documentate?
- [ ] Commenti per logica complessa?
- [ ] README aggiornato se necessario?

## Output Atteso

Fornisci:
1. **Summary**: Breve descrizione del codice
2. **Issues**: Lista problemi trovati (Critical, Major, Minor)
3. **Suggestions**: Miglioramenti suggeriti
4. **Good Practices**: Cosa è fatto bene
5. **Action Items**: Lista azioni da intraprendere

## Esempio Output

```markdown
## Code Review: ChatListViewModel.swift

### Summary
ViewModel per la gestione della lista chat. Gestisce loading, filtering e sorting.

### Issues

#### Critical
- Nessuno

#### Major
1. **Line 45**: Force unwrap potenzialmente pericoloso
   ```swift
   // Attuale
   let chat = chats.first!

   // Suggerito
   guard let chat = chats.first else { return }
   ```

#### Minor
1. **Line 23**: Variabile `x` ha nome poco descrittivo
2. **Line 67**: Magic number 100, estrarre in costante

### Suggestions
1. Estrarre logica di filtering in funzione separata
2. Aggiungere caching per risultati ricerca

### Good Practices
- Uso corretto di @Observable
- Error handling ben implementato
- Separazione concerns rispettata

### Action Items
- [ ] Fix force unwrap line 45
- [ ] Rinominare variabile line 23
- [ ] Estrarre magic number line 67
```
