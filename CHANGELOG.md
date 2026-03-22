# Changelog

## 0.0.16 Alpha - 2026-03-22

### Neu

- `Checkliste` als eigenes Modul eingebaut
- `Itemlevel Guide` als eigenes Modul eingebaut
- `Logging` als eigenes Modul eingebaut
- `Quest Check` als eigenes Modul eingebaut
- `Stats` als eigenes Overlay-Modul eingebaut
- `Weekly Keys` als eigenes Overlay-Modul eingebaut
- Laufzeit-Lokalisierung fuer `deDE` und `enUS` eingebaut

### Itemlevel Guide

- neue Fortschritt-Seite als kompakte Saisonreferenz
- Tabellen fuer Upgradepfade, Crafting, Dungeons, Raid und Tiefen
- bewusst eigene Dashboard-Optik statt einfacher Zahlenliste
- Titel und Tabellenueberschriften sprachlich fuer das Addon angepasst

### Checkliste

- Daily-, Weekly- und `Im Blick halten`-Kategorien
- manuelle Aufgaben mit frei waehlbarer Kategorie
- kleines Tracker-Fenster ausserhalb des Hauptfensters
- Header-Aktionen fuer `Pin`, `Einst.`, `Add`, `Vault` und Einklappen
- automatische Resets fuer Daily und Weekly
- dynamische Weekly-Berufsaufgaben mit aktuellem Berufsnamen
- Minimap-Kontextmenue zum Ein- und Ausblenden des Trackers

### Logging

- Verkaufslog mit itemisierten Haendlerverkaeufen
- aufklappbare Verkaufszeilen fuer Itemdetails und Gold pro Item
- Reparaturlog mit Tagessummen und aufklappbaren Tagesdetails
- Gold-Einnahmen nach Kategorie
- Gold-Ausgaben nach Kategorie
- Aufbewahrungslogik:
  - Verkaufslog 30 Tage
  - Reparaturlog 30 Tage
  - Gold-Einnahmen 1 Jahr
  - Gold-Ausgaben 1 Jahr
- manuelles Loeschen nach Zeitraum ueber Popup

### Overlay-Module

- `Stats` zeigt Sekundaerwerte in einem kompakten Overlay
- `Weekly Keys` zeigt die hoechsten 8 Weekly-Dungeons inklusive Weekly-Loot
- beide Overlays haben:
  - eigene Anzeigeoptionen
  - Fixieren
  - Positions-Reset
  - Skalierung
  - kompaktere Standardwerte
- beide Overlays sind ueber das Minimap-Kontextmenue direkt ein- und ausblendbar

### Weekly Keys

- nicht erkannte Non-Key-Runs werden jetzt differenzierter als `Heroisch <Dungeon>` oder `Mythisch <Dungeon>` erfasst, sobald Blizzard die Daten liefert
- Overlay-Layering so angepasst, dass Blizzard- und Battle.net-Overlays nicht unnoetig vom Weekly-Keys-Fenster ueberdeckt werden

### Lokalisierung

- Sprache im Addon zwischen Deutsch und Englisch umschaltbar
- statische UI-Texte werden nach Sprachwechsel zentral neu aufgebaut
- neue Module und Tabelleninhalte fuer Itemlevel Guide, Logging, Checkliste, Weekly Keys, Stats, LFG, Pet Stuff und Combat Text lokalisiert

### Navigation und UI

- Tree neu in Hauptkategorien gegliedert:
  - `Fortschritt`
  - `Gold & Handel`
  - `Komfort`
  - `Interface & Kampf`
  - `Gruppe & Suche`
  - `Begleiter`
- Tree mit Scrollbar erweitert
- `Misc` im sichtbaren UI in `Komfort` umbenannt
- Rechtsklick auf den Minimap-Button oeffnet ein Schnellmenue
- Hauptfenster mit breiterer Sidebar, ruhigerem Header und luftigerer Home-Seite neu aufgebaut

### Weitere Anpassungen

- `Quest Check` Hinweistext konkretisiert: Beispiel jetzt mit `Quest ID 12345`
- `Combat Text` Text und Warnbereich sprachlich ueberarbeitet
- Hinweis bei `Auto Respawn Pet`, dass das Rufen nur ausserhalb des Kampfes funktioniert
- mehrere UI-Abstaende, Tracker-Details und Textausrichtungen nachgezogen
- Versionsstand auf `0.0.16 Alpha` angehoben

### Codepflege

- Addon-eigene Dateien menschlicher kommentiert
- erkannte doppelte oder unklare Logik schrittweise bereinigt
- README fuer Nutzer und Einsteiger im Code erweitert

## 0.0.2 Alpha - 2026-03-20

- erste spielbare Alpha-Version
- Hauptfenster mit Sidebar, Home- und Versionsseite
- Versionsseite erkennt hoehere BeavisQoL-Versionen bei anderen Spielern
- Levelzeit-Tracker mit gespeicherten Charakterdaten
- Misc-Module:
  - Auto Sell Junk
  - Auto Repair
  - Easy Delete
  - Fast Loot
- Kamera-Distanz per Button zwischen Standard und Max Distance umschaltbar
- Pet Stuff: Auto Respawn Pet
- LFG: Laenderflaggen in der Premade-Gruppensuche
- Combat Text mit Font-Auswahl und Stil-Reglern
- Minimap-Button und Slash-Command `/beavis`
