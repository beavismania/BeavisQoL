# Beavis Quality of Life

Ein World of Warcraft Retail Addon, das mehrere kleine Quality-of-Life-Module in einem gemeinsamen Hauptfenster sammelt.

## Aktueller Stand

- Version: `0.24.1`
- Release-Datum: `2026-03-26`
- Schwerpunkt dieser Version:
  - `Jagd-Fortschritt` zeigt `Phase 1/4` nicht mehr ohne aktive Jagd an
  - die Widget-Erkennung akzeptiert nur noch echte Blizzard-Prey-Hunt-Widgets

## Download

Die fertigen Release-ZIPs liegen hier:

https://github.com/beavismania/BeavisQoL/releases

## Projektziel

`BeavisQoL` ist gleichzeitig Addon, Lernprojekt und Baukasten.
Der Code bleibt bewusst modular, damit neue Funktionen ohne kompletten Umbau dazukommen können.

Das Projekt soll:

- nützliche Alltagsfunktionen für WoW Retail sammeln
- Funktionen klar in getrennte Module aufteilen
- beim Lernen von Lua und WoW-Addon-APIs helfen
- langfristig gut wartbar bleiben

## Versionierung

`BeavisQoL` nutzt ein festes `major.minor.patch`-Schema:

- `1.0.0`
  - Hauptversion für größere Releases, Richtungswechsel oder bewusst große Paketzustände
- `0.1.0`
  - Featureversion für neue Funktionen oder neue Module
- `0.0.1`
  - Hotfixversion für kleine Fehlerbehebungen ohne neues Modul

Regel für künftige Releases:

- sobald ein neues Modul hinzugefügt wird, muss mindestens die `minor`-Version erhöht werden
- reine Bugfixes ohne neues Modul erhöhen nur die `patch`-Version
- größere Meilensteine oder bewusst große Umbauten erhöhen die `major`-Version

Beispiel:

- `0.24.1` -> aktueller Stand
- neues Modul -> `0.25.0`
- weiterer Hotfix -> `0.24.2`
- großer Hauptrelease -> `1.0.0`

## Aktueller Schwerpunkt

- ein gemeinsames Hauptfenster mit Tree-Navigation
- mehrere sichtbare Overlay-Module für den Spielalltag
- charakterbezogene Logs, Checklisten und Referenzseiten
- code-nahe Dokumentation für Anfänger

## Module im Addon

### Fortschritt

- `Levelzeit`
  - misst die gespielte Zeit pro Level
- `Checkliste`
  - Daily-, Weekly- und "Im Blick halten"-Aufgaben
  - kleines Tracker-Fenster außerhalb des Hauptfensters
  - kann in instanzierten Bereichen automatisch ausgeblendet werden, optional nur im Kampf
- `Weekly Keys`
  - zeigt die höchsten 8 Weekly-Dungeons und den Vault-Loot
  - kann in instanzierten Bereichen automatisch ausgeblendet werden, optional nur im Kampf
  - zählt für die Weekly-Gear-Anzeige nur abgeschlossene M+-Runs
  - verhindert doppelte Einträge zwischen Key und mythischem Non-Key-Run
- `Itemlevel Guide`
  - saisonale Referenz für Upgradepfade, Crafting, Dungeon-, Raid- und Tiefen-Itemlevel
- `Quest Check`
  - prüft Queststatus per Quest-ID, WoWHead-Link oder exaktem Namen
- `Quest Abandon`
  - zeigt sichtbare aktive Quests in einer Auswahl-Liste
  - erlaubt gezieltes Markieren, Sammel-Abbrechen und Schnellaktionen für alle markieren oder leeren

### Gold & Handel

- `Logging`
  - Verkaufslog
  - Reparaturlog mit Tagessummen
  - aufklappbare Verkaufs- und Reparaturdetails
  - Gold-Einnahmen nach Kategorie
  - Gold-Ausgaben nach Kategorie
  - manuelles Löschen nach Zeitraum
- `Auto Sell Junk`
  - verkauft graue Items beim Händler automatisch
- `Auto Repair`
  - repariert automatisch, optional bevorzugt über Gildengold

### Komfort

- `Fast Loot`
  - lootet direkt beim Öffnen des Lootfensters
- `Easy Delete`
  - ersetzt die DELETE-Texteingabe bei passenden Items durch eine einfache Bestätigung
- `Tooltip-Itemlevel`
  - zeigt das ausgerüstete Itemlevel anderer Spieler direkt im Mouseover-Tooltip
  - arbeitet über Blizzard-Inspect und daher nur in Reichweite des Zielspielers
- `Kameraweite`
  - schaltet zwischen Standard und Max Distance um und setzt den Wert nach Login erneut
- `Angelhilfe`
  - Ein-Tasten-Helfer für das Auswerfen und Einsammeln des Bobbers
  - legt die gewählte Taste während aktivem Bobber vorübergehend auf Blizzard-Interaktion um
  - kann die Effektlautstärke beim Angeln temporär anheben
- `Jagd-Fortschritt`
  - blendet bei aktiven Midnight-Jagden eine Stufenanzeige direkt am Blizzard-Symbol ein
  - zeigt `Phase 1/4` bis `Phase 3/4` und in der letzten Stufe `Boss bereit`

### Interface & Kampf

- `Combat Text`
  - eigene Combat-Text-Anpassungen für Schrift und Bewegung
- `Markerleiste`
  - transparente Leiste mit Raidmarkern für Zielmarker und Bodenmarker
  - frei verschiebbar, skalierbar und fixierbar
  - Bodenmarker funktionieren nur in Gruppen, im Raid zusätzlich nur mit Leiter- oder Assistentenrechten
- `Maus-Helfer`
  - eigene Komfortseite für Blizzard-Mausgröße, Cursor-Kreis und Maus-Trail
  - Kreis und Trail lassen sich in Stil, Größe, Farbe und Sichtbarkeit anpassen
- `Boss Guides`
  - zeigt in unterstützten Instanzen einen Overlay-Button für Boss-Taktiken an
  - Guide-Fenster mit Instanz-Auswahl, Boss-Tabs, Rollenlegende und skalierbarer Darstellung
- `Stats`
  - kompaktes Overlay für Sekundärwerte
  - frei verschiebbar, skalierbar und in der Transparenz anpassbar
  - kann in instanzierten Bereichen automatisch ausgeblendet werden, optional nur im Kampf

### Gruppe & Suche

- `Gruppensuche`
  - Länderflaggen in der Premade-Suche
  - `Easy LFG` als kompaktes Bewerber-Overlay für eigene aktive Listungen
  - direktes Einladen oder Ablehnen aus dem Overlay heraus
  - Rollen- und Spec-Symbole, Länderflaggen sowie aufklappbare Gruppenbewerbungen
- `Weekly Keys`
  - Overlay für die 8 höchsten Wochenläufe
  - zeigt Weekly-Vault-Loot direkt in derselben Anzeige
  - erfasst ergänzend erkannte heroische und mythische Non-Key-Runs, sofern Blizzard-Daten dafür vorliegen

### Streamer Tools

- `Gruppenplaner`
  - transparentes Overlay für feste Dungeon- und Raid-Slots
  - Timerblock, Zielanzeige und Schnellaktion `Alle leeren` direkt im Overlay
  - Sloteditor mit Klassen- und Spezialisierungsauswahl
  - Zielvorschläge für Dungeons, Raids, Tiefen und Keystufen bis `M+20`

### Begleiter

- `Pet Stuff`
  - Auto Respawn Pet für Begleiter-Pets außerhalb des Kampfes

## Modulerweiterungen bis 0.24.1

- `Checkliste`
  - eigene Fortschrittsseite mit Daily-, Weekly- und Watch-Kategorien
  - manuelle Aufgaben pro Charakter
  - separates Tracker-Fenster mit Schnellaktionen
- `Itemlevel Guide`
  - neue Saison-Referenzseite für Upgradepfade, Crafting, Dungeon, Raid und Tiefen
- `Quest Check`
  - Questprüfung per ID, WoWHead-Link oder exaktem Namen
- `Quest Abandon`
  - Quest-Abbruch als eigenes Modul mit Auswahl-Liste für sichtbare aktive Quests
- `Logging`
  - vollwertige Verkaufs-, Reparatur-, Einnahmen- und Ausgabenprotokolle
- `Tooltip-Itemlevel`
  - Komfort-Modul für das direkte Anzeigen fremder Itemlevel im Tooltip
- `Stats` und `Weekly Keys`
  - eigenständige Overlay-Module mit Position, Skalierung und Transparenz
- `Markerleiste`
  - Modul für Zielmarker und Bodenmarker mit transparenter Symbolleiste
  - eigene Overlay-Steuerung für Anzeigen, Fixieren, Skalierung und Positions-Reset
- `Maus-Helfer`
  - Komfortseite für vergrößerten Blizzard-Cursor, Cursor-Kreis und Maus-Trail
  - Kreis- und Trail-Stile lassen sich direkt im Addon konfigurieren
- `Boss Guides`
  - Modul für Boss-Taktiken mit Overlay-Button und Guide-Fenster pro unterstützter Instanz
  - Instanz-Auswahl, Boss-Tabs und Rollenlegende direkt im Fenster enthalten
- `Easy LFG`
  - kompaktes Bewerber-Overlay für eigene Gruppenlistungen
  - direkte Invite- und Ablehnen-Aktionen, Rollen-/Spec-Symbole und Länderflaggen
  - gruppierte, aufklappbare Mehrspieler-Bewerbungen statt einer flachen Liste
- `Gruppenplaner`
  - transparenter Gruppenplaner mit eigenem Timerblock und erweiterten Overlay-Steuerungen
  - Sloteditor mit Klassen- und Spec-Auswahl sowie Zielvorschlägen für verschiedene Inhalte
- `Angelhilfe`
  - Komfort-Modul für einen vereinfachten Ein-Tasten-Ablauf beim Angeln
- `Jagd-Fortschritt`
  - neues Komfort-Modul für Midnight-Jagden mit direkter Anzeige am Blizzard-Symbol
  - stellt den Hunt-Fortschritt als `Phase 1/4` bis `Boss bereit` dar
  - zeigt `Phase 1/4` nicht mehr fälschlich ohne aktive Jagd an
- `Weekly Keys`
  - zählt für die Weekly-Gear-Anzeige nur noch abgeschlossene M+-Runs
  - verhindert doppelte Einträge, wenn ein Key zuvor als normaler mythischer Dungeon erkannt wurde
- `UI und Komfortseiten`
  - optische Korrekturen für `Gruppensuche`, `Gruppenplaner`, `Angelhilfe` und `Maus-Helfer`
- `UI und Navigation`
  - breitere Sidebar
  - neue Hauptkategorien im Tree
  - Schnellmenü am Minimap-Button
- `Overlay-Steuerung`
  - Schnell-Ausblenden für instanzierte Bereiche mit Detailauswahl für Checkliste, Weekly Keys und Stats
  - optionale Einschränkung auf Kampf innerhalb instanzierter Bereiche
- `Lokalisierung`
  - Deutsch und Englisch direkt im Addon umschaltbar

## Bedienung

- Slash-Command: `/beavis`
- Minimap-Button:
  - Linksklick: Hauptfenster zeigen / verstecken
  - Rechtsklick: Schnellmenü
  - Shift-Klick: `ReloadUI()`
  - Schnellmenü: direkter Zugriff auf Checkliste-, Weekly-Keys-, Stats-, `Easy LFG`- und `Gruppenplaner`-Overlay
  - Schnellmenü: Master-Schalter `Overlays schnell ausblenden`

## Installation

1. Release-ZIP herunterladen oder Repository klonen.
2. Den Ordner `BeavisQoL` nach `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
3. Darauf achten, dass der finale Ordner wirklich `BeavisQoL` heißt.
4. Spiel starten oder `/reload` nutzen.

Beispielpfad:

```text
World of Warcraft\_retail_\Interface\AddOns\BeavisQoL
```

## Für Einsteiger im Code

Der Addon-Code ist bewusst so aufgebaut, dass man ihn gut lesen kann:

- `Core.lua`
  - Basis-Startpunkt und Slash-Command
- `UI.lua`
  - Hauptfenster, Header, Sidebar, Content-Bereich, gemeinsames Link-Popup
- `Tree.lua`
  - Navigation und Seitenwechsel
- `Pages/`
  - jede größere Funktion hat eine eigene Seite oder Unterlogik

Die Addon-eigenen Dateien sind inzwischen bewusst menschlich kommentiert.
Fokus der Kommentare:

- Was speichert die Funktion?
- Warum ist ein bestimmter Guard nötig?
- Welche Events steuern den Ablauf?
- Was ist UI und was ist eigentliche Logik?

Nicht kommentiert werden bewusst die eingebundenen Drittanbieter-Bibliotheken unter `Libs/`.

## Entwicklungshinweis

Wenn du das Addon als Lernprojekt lesen willst, starte am besten in dieser Reihenfolge:

1. `Core.lua`
2. `UI.lua`
3. `Tree.lua`
4. eine einzelne Seite unter `Pages/`
5. danach die zugehörigen Unterdateien, zum Beispiel `Pages/Misc/*.lua`

## Feedback und Kontakt

- Twitch: https://www.twitch.tv/beavismania
- Website / Community: https://www.beavismania.de

## Lizenz

Dieses Projekt ist proprietär und urheberrechtlich geschützt.

Erlaubt ist die private, nicht-kommerzielle Nutzung offizieller Versionen von `BeavisQoL` in World of Warcraft.

Ohne vorherige schriftliche Genehmigung sind insbesondere nicht erlaubt:

- Weiterverbreitung des Projekts oder wesentlicher Teile davon
- Veränderung und Veröffentlichung abgeleiteter Versionen
- Wiederverwendung von Code, Assets oder anderen Projektbestandteilen in anderen Addons oder Projekten
- kommerzielle Nutzung

Die vollständigen Bedingungen stehen in `LICENSE`.
