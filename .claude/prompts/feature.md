# Feature Implementation Prompt

Usa questo template per richiedere l'implementazione di una nuova feature.

## Template

```
Implementa la feature: [NOME FEATURE]

## Descrizione
[Descrizione chiara di cosa deve fare la feature]

## User Stories
- Come [tipo utente], voglio [azione] per [beneficio]
- ...

## Requisiti Funzionali
1. [Requisito 1]
2. [Requisito 2]
3. ...

## Requisiti Non-Funzionali
- Performance: [requisiti]
- Sicurezza: [requisiti]
- Accessibilità: [requisiti]

## Mockup/Design
[Descrizione UI o link a design]

## Dipendenze
- [Dipendenza esistente 1]
- [Dipendenza esistente 2]

## API TDLib Necessarie
- [TDLib method 1]
- [TDLib method 2]

## Criteri di Accettazione
- [ ] [Criterio 1]
- [ ] [Criterio 2]
- [ ] Test unitari presenti
- [ ] Test UI presenti
- [ ] Documentazione aggiornata

## Note
[Informazioni aggiuntive]
```

## Esempio Compilato

```
Implementa la feature: Ricerca Messaggi

## Descrizione
Implementare la funzionalità di ricerca messaggi all'interno di una chat specifica,
con supporto per filtri per tipo di contenuto e range temporale.

## User Stories
- Come utente, voglio cercare messaggi in una chat per trovare rapidamente informazioni
- Come utente, voglio filtrare la ricerca per tipo (foto, video, link) per affinare i risultati
- Come utente, voglio cercare in un range di date specifico

## Requisiti Funzionali
1. Campo di ricerca nella toolbar della conversazione
2. Risultati mostrati con highlight del testo cercato
3. Navigazione ai messaggi trovati
4. Filtri: tutti, foto, video, documenti, link, audio
5. Filtro per data (da-a)
6. Conteggio risultati in tempo reale

## Requisiti Non-Funzionali
- Performance: risultati in <500ms per query
- Debounce input: 300ms
- Cache risultati recenti
- Supporto offline per messaggi locali

## Mockup/Design
- Search bar espandibile nella navigation bar
- Sheet con risultati e filtri
- Evidenziazione testo nei risultati
- Pulsante "Vai al messaggio"

## Dipendenze
- ConversationView esistente
- TDLibClient
- MessageRepository

## API TDLib Necessarie
- searchChatMessages
- SearchMessagesFilter (photo, video, document, url, audio)

## Criteri di Accettazione
- [ ] Ricerca testo funziona correttamente
- [ ] Filtri applicati correttamente
- [ ] Navigazione al messaggio funziona
- [ ] Performance <500ms
- [ ] UI accessibile (VoiceOver)
- [ ] Dark mode funziona
- [ ] Test unitari per SearchViewModel
- [ ] Test UI per flusso ricerca

## Note
- Considerare local search per messaggi già scaricati
- Implementare highlight con AttributedString
- Usare @FocusState per gestione keyboard
```

## Checklist Pre-Implementazione

Prima di iniziare:

- [ ] Requirements chiari e completi
- [ ] Design/mockup disponibile
- [ ] API TDLib identificate
- [ ] Dipendenze esistenti verificate
- [ ] Edge cases considerati
- [ ] Error handling pianificato
