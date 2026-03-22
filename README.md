# Beavis Quality of Life

Ein World of Warcraft Retail Addon, das mehrere kleine Quality-of-Life-Module in einem gemeinsamen Hauptfenster sammelt.

## Aktueller Stand

- Version: `0.0.16 Alpha`
- Release-Datum: `2026-03-22`
- Schwerpunkt dieser Version:
  - neue Fortschritts- und Logging-Module
  - zwei frei verschiebbare Overlay-Module
  - ueberarbeitetes Hauptfenster mit neuer Tree-Struktur
  - deutsche und englische Laufzeit-Lokalisierung

## Download

Die fertigen Release-ZIPs liegen hier:

https://github.com/beavismania/BeavisQoL/releases

## Projektziel

`BeavisQoL` ist gleichzeitig Addon, Lernprojekt und Baukasten.
Der Code wird bewusst modular gehalten, damit neue Funktionen ohne kompletten Umbau dazukommen koennen.

Das Projekt soll:

- nuetzliche Alltagsfunktionen fuer WoW Retail sammeln
- moeglichst sauber in getrennte Module aufteilen
- beim Lernen von Lua und WoW-Addon-APIs helfen
- langfristig gut wartbar bleiben

## Aktueller Schwerpunkt

- ein gemeinsames Hauptfenster mit Tree-Navigation
- mehrere sichtbare Overlay-Module fuer den Spielalltag
- charakterbezogene Logs, Checklisten und Referenzseiten
- code-nahe Dokumentation fuer Anfaenger

## Module im Addon

### Fortschritt

- `Levelzeit`
  - misst die gespielte Zeit pro Level
- `Checkliste`
  - Daily-, Weekly- und "Im Blick halten"-Aufgaben
  - kleines Tracker-Fenster ausserhalb des Hauptfensters
- `Weekly Keys`
  - zeigt die hoechsten 8 Weekly-Dungeons und den Vault-Loot
- `Itemlevel Guide`
  - saisonale Referenz fuer Upgradepfade, Crafting, Dungeon-, Raid- und Tiefen-Itemlevel
- `Quest Check`
  - prueft Queststatus per Quest-ID, WoWHead-Link oder exaktem Namen

### Gold & Handel

- `Logging`
  - Verkaufslog
  - Reparaturlog mit Tagessummen
  - aufklappbare Verkaufs- und Reparaturdetails
  - Gold-Einnahmen nach Kategorie
  - Gold-Ausgaben nach Kategorie
  - manuelles Loeschen nach Zeitraum
- `Auto Sell Junk`
  - verkauft graue Items beim Haendler automatisch
- `Auto Repair`
  - repariert automatisch, optional bevorzugt ueber Gildengold

### Komfort

- `Fast Loot`
  - lootet direkt beim Oeffnen des Lootfensters
- `Easy Delete`
  - ersetzt die DELETE-Texteingabe bei passenden Items durch eine einfache Bestaetigung
- `Kameraweite`
  - schaltet zwischen Standard und Max Distance um und setzt den Wert nach Login erneut

### Interface & Kampf

- `Combat Text`
  - eigene Combat-Text-Anpassungen fuer Schrift und Bewegung
- `Stats`
  - kompaktes Overlay fuer Sekundaerwerte
  - frei verschiebbar, skalierbar und in der Transparenz anpassbar

### Gruppe & Suche

- `Gruppensuche`
  - Laenderflaggen in der Premade-Suche
- `Weekly Keys`
  - Overlay fuer die 8 hoechsten Wochenlaeufe
  - zeigt Weekly-Vault-Loot direkt in derselben Anzeige
  - erfasst neben M+ auch erkannte heroische und mythische Non-Key-Runs

### Begleiter

- `Pet Stuff`
  - Auto Respawn Pet fuer Begleiter-Pets ausserhalb des Kampfes

## Modulerweiterungen in 0.0.16 Alpha

- `Checkliste`
  - eigene Fortschrittsseite mit Daily-, Weekly- und Watch-Kategorien
  - manuelle Aufgaben pro Charakter
  - separates Tracker-Fenster mit Schnellaktionen
- `Itemlevel Guide`
  - neue Saison-Referenzseite fuer Upgradepfade, Crafting, Dungeon, Raid und Tiefen
- `Quest Check`
  - Questpruefung per ID, WoWHead-Link oder exaktem Namen
- `Logging`
  - vollwertige Verkaufs-, Reparatur-, Einnahmen- und Ausgabenprotokolle
- `Stats` und `Weekly Keys`
  - als eigenstaendige Overlay-Module mit Position, Scale und Transparenz
- `UI und Navigation`
  - breitere Sidebar
  - neue Hauptkategorien im Tree
  - Schnellmenue am Minimap-Button
- `Lokalisierung`
  - Deutsch und Englisch direkt im Addon umschaltbar

## Bedienung

- Slash-Command: `/beavis`
- Minimap-Button:
  - Linksklick: Hauptfenster zeigen / verstecken
  - Rechtsklick: Schnellmenue
  - Shift-Klick: `ReloadUI()`
  - Schnellmenue: direkter Zugriff auf Checkliste-, Weekly-Keys- und Stats-Overlay

## Installation

1. Release-ZIP herunterladen oder Repository klonen.
2. Den Ordner `BeavisQoL` nach `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
3. Darauf achten, dass der finale Ordner wirklich `BeavisQoL` heisst.
4. Spiel starten oder `/reload` nutzen.

Beispielpfad:

```text
World of Warcraft\_retail_\Interface\AddOns\BeavisQoL
```

## Fuer Einsteiger im Code

Der Addon-Code ist absichtlich so aufgebaut, dass man ihn besser lesen kann:

- `Core.lua`
  - Basis-Startpunkt und Slash-Command
- `UI.lua`
  - Hauptfenster, Header, Sidebar, Content-Bereich, gemeinsames Link-Popup
- `Tree.lua`
  - Navigation und Seitenwechsel
- `Pages/`
  - jede groessere Funktion hat eine eigene Seite oder Unterlogik

Die Addon-eigenen Dateien sind inzwischen bewusst menschlich kommentiert.
Fokus der Kommentare:

- Was speichert die Funktion?
- Warum ist ein bestimmter Guard noetig?
- Welche Events steuern den Ablauf?
- Was ist UI und was ist eigentliche Logik?

Nicht kommentiert werden bewusst die eingebundenen Drittanbieter-Bibliotheken unter `Libs/`.

## Entwicklungshinweis

Wenn du das Addon als Lernprojekt lesen willst, starte am besten in dieser Reihenfolge:

1. `Core.lua`
2. `UI.lua`
3. `Tree.lua`
4. eine einzelne Seite unter `Pages/`
5. danach die zugehoerigen Unterdateien, z. B. `Pages/Misc/*.lua`

## Feedback und Kontakt

- Twitch: https://www.twitch.tv/beavismania
- Website / Community: https://www.beavismania.de

## Lizenz

Dieses Projekt ist proprietaer und urheberrechtlich geschuetzt.

Erlaubt ist die private, nicht-kommerzielle Nutzung offizieller Versionen von `BeavisQoL` in World of Warcraft.

Ohne vorherige schriftliche Genehmigung sind insbesondere nicht erlaubt:

- Weiterverbreitung des Projekts oder wesentlicher Teile davon
- Veraenderung und Veroeffentlichung abgeleiteter Versionen
- Wiederverwendung von Code, Assets oder anderen Projektbestandteilen in anderen Addons oder Projekten
- kommerzielle Nutzung

Die vollstaendigen Bedingungen stehen in `LICENSE`.
