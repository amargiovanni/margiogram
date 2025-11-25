# Bug Fix Prompt

Usa questo template per richiedere la risoluzione di un bug.

## Template

```
Fix bug: [TITOLO BREVE]

## Descrizione Bug
[Descrizione chiara del problema]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[Cosa dovrebbe succedere]

## Actual Behavior
[Cosa succede realmente]

## Environment
- Device: [iPhone 15 Pro / iPad / Mac]
- OS Version: [iOS 17.2]
- App Version: [1.0.0]

## Error Messages/Logs
```
[Eventuali errori o log]
```

## Screenshots/Videos
[Se disponibili]

## Severity
- [ ] Critical (app crash, data loss)
- [ ] Major (feature broken)
- [ ] Minor (cosmetic, workaround exists)

## Files Potentially Involved
- [file1.swift]
- [file2.swift]

## Additional Context
[Altre informazioni utili]
```

## Esempio Compilato

```
Fix bug: App crash quando si invia foto senza didascalia

## Descrizione Bug
L'app crasha quando l'utente tenta di inviare una foto senza aggiungere
una didascalia, in chat private e di gruppo.

## Steps to Reproduce
1. Apri una chat qualsiasi
2. Tocca il pulsante allegati (+)
3. Seleziona "Foto"
4. Scegli una foto dalla libreria
5. NON aggiungere didascalia
6. Tocca "Invia"
7. App crasha

## Expected Behavior
La foto dovrebbe essere inviata correttamente senza didascalia.

## Actual Behavior
L'app termina inaspettatamente con crash.

## Environment
- Device: iPhone 15 Pro
- OS Version: iOS 17.2
- App Version: 1.0.0 (build 42)

## Error Messages/Logs
```
Fatal error: Unexpectedly found nil while unwrapping an Optional value
Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value

Stack trace:
0   Margiogram    MediaViewModel.swift:145
1   Margiogram    ConversationViewModel.swift:89
2   Margiogram    ConversationView.swift:234
```

## Screenshots/Videos
N/A - app crasha prima di poter catturare

## Severity
- [x] Critical (app crash, data loss)
- [ ] Major (feature broken)
- [ ] Minor (cosmetic, workaround exists)

## Files Potentially Involved
- Features/Media/ViewModels/MediaViewModel.swift
- Features/Conversation/ViewModels/ConversationViewModel.swift
- Core/TDLib/TDLibClient.swift

## Additional Context
- Bug introdotto probabilmente nel commit abc123
- Funzionava nella versione 0.9.0
- Workaround: aggiungere sempre una didascalia (anche spazio)
```

## Checklist Risoluzione Bug

### Prima del Fix
- [ ] Bug riprodotto localmente
- [ ] Causa identificata
- [ ] Impatto su altre aree valutato

### Durante il Fix
- [ ] Fix minimale (non over-engineering)
- [ ] Nessuna regressione introdotta
- [ ] Codice segue standards progetto

### Dopo il Fix
- [ ] Bug non più riproducibile
- [ ] Test aggiunto per prevenire regressione
- [ ] Code review completata
- [ ] Documentazione aggiornata se necessario
