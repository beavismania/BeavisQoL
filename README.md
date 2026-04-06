# Beavis Quality of Life

Ein World of Warcraft Retail Addon, das mehrere kleine Quality-of-Life-Module in einem gemeinsamen Hauptfenster bündelt.

## Aktueller Stand

- Version: `0.27.2`
- Release-Datum: `2026-04-06`
- Release-Kanal: `beta`
- Highlights dieser Version:
  - `Boss Guides` zeigen in weiteren Midnight-S1-Dungeons jetzt deutsche, hoverbare Bosszauber mit passenden Icons
  - sichtbare Spell-IDs wurden aus den Guide-Texten entfernt, während Hover-Infos über die Spell-Map erhalten bleiben
  - Bossguide-Texte und Lokalisierungen wurden auf fehlerhafte Umlaute und Darstellungsprobleme bereinigt
  - `Gruppenplaner`- und Guide-Verbesserungen aus `0.27.1` bleiben vollständig enthalten

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
  - Hauptversion für größere Releases, Richtungswechsel oder bewusst große Meilensteine
- `0.1.0`
  - mittlere Zahl für den nächsten Feature-/Modulstand
- `0.0.1`
  - hintere Zahl als Hotfix-Zähler für Nachbesserungen an einem bereits veröffentlichten Stand

Regeln:

- die mittlere Zahl steigt mit jedem neuen Feature- oder Modulstand
- die hintere Zahl bleibt bei neuen Feature-/Modulständen auf `0`
- Weiterentwicklung, Feinschliff und Bugfixes an neuen Modulen bleiben im selben laufenden Feature-Release und erhöhen nicht automatisch die `patch`-Version
- reine Bugfixes an bereits veröffentlichten Ständen ohne neue Module erhöhen die `patch`-Version
- bei einem neuen Feature-/Modulstand wird der Hotfix-Zähler wieder auf `0` gesetzt
- größere Richtungswechsel oder bewusst große Meilensteine erhöhen die `major`-Version

Beispiele:

- `0.27.0` → letzter veröffentlichter Feature-/Modulstand
- `0.27.2` → aktueller Hotfix-Stand mit Verbesserungen an bestehenden Modulen
- Hotfix nach veröffentlichtem `0.27.2` → `0.27.3`
- nächstes neues Modul nach `0.27.2` → `0.28.0`
- großer Hauptrelease → `1.0.0`

## Module im Addon

### Fortschritt

- `Levelzeit`
  - misst die gespielte Zeit pro Level
- `Checkliste`
  - Daily-, Weekly- und „Im Blick halten“-Aufgaben
  - separates Tracker-Fenster außerhalb des Hauptfensters
  - zusätzliche Weekly-Standardaufgaben für `PvP-Quests`, `Tiefenfortschritt` und `Tiefen-Held-Karte`
  - Berufs-Weekly-Aufgaben werden beim Wochenreset wieder korrekt zurückgesetzt
- `Weekly Keys`
  - zeigt die höchsten 8 Wochenläufe und den Vault-Loot
  - kann in instanzierten Bereichen automatisch ausgeblendet werden
- `Itemlevel Guide`
  - saisonale Referenz für Upgradepfade, Crafting, Dungeon-, Raid- und Tiefen-Itemlevel
- `Quest Check`
  - prüft Queststatus per Quest-ID, WoWHead-Link oder exaktem Namen
- `Quest Abandon`
  - zeigt sichtbare aktive Quests in einer Auswahl-Liste
  - erlaubt gezieltes Markieren und Sammel-Abbrechen

### Gold & Handel

- `Logging`
  - Verkaufslog, Reparaturlog sowie Gold-Einnahmen und -Ausgaben
- `Auto Sell Junk`
  - verkauft graue Items beim Händler automatisch
- `Auto Repair`
  - repariert automatisch, optional bevorzugt über Gildengold

### Komfort

- `Fast Loot`
  - lootet direkt beim Öffnen des Lootfensters
- `Easy Delete`
  - ersetzt die DELETE-Texteingabe bei passenden Items durch eine einfache Bestätigung
- `Cutscene Skip`
  - zeigt unbekannte Movies und Cutscenes beim ersten Auslösen normal an
  - überspringt bekannte Szenen bei späteren Auslösungen automatisch
- `Flugmeister-Timer`
  - zeigt während Flugmeister-Flügen mittig am Bildschirm einen Countdown bis zur Ankunft
  - lernt fehlende Routenzeiten automatisch nach
  - optionaler Ankunftssound mit Auswahl und Test-Button
  - Overlay ist über die Optionen positionierbar, zurücksetzbar und standardmäßig fixiert
- `Schlüsselstein-Buttons`
  - ersetzt im Mythic+-Schlüsselsteinfenster den Aktivieren-Button durch `Readycheck` und `Timer & GO`
  - optionaler `Auto Timer` startet nach dem eigenen Readycheck automatisch, sobald alle bereit sind
  - Countdown-Dauer ist einstellbar und die Buttons können optional außerhalb von Gruppen gesperrt bleiben
- `Tooltip-Itemlevel`
  - zeigt das ausgerüstete Itemlevel anderer Spieler direkt im Mouseover-Tooltip
- `Kameraweite`
  - schaltet zwischen Standard und Max Distance um
- `Angelhilfe`
  - Ein-Tasten-Helfer für entspanntes Angeln
  - hebt auf Wunsch den Bobber-Sound hervor und stellt den vorherigen Soundmix danach wieder her
- `Jagd-Fortschritt`
  - blendet bei aktiven Midnight-Jagden die aktuelle Stufe direkt am Blizzard-Symbol ein
- `Portal Viewer`
  - Schnellansicht für die aktuellen Midnight-S1-Dungeonportale
  - zeigt freigeschaltete und fehlende Portale direkt in einem kompakten Fenster
  - verfügbare Portale lassen sich direkt per Linksklick benutzen
  - öffnet sich über das Minimap-Schnellmenü

### Interface & Kampf

- `Combat Text`
  - eigene Combat-Text-Anpassungen für Schrift und Bewegung
- `Markerleiste`
  - transparente Leiste mit Raidmarkern für Zielmarker und Bodenmarker
- `Maus-Helfer`
  - Komfortseite für Blizzard-Mausgröße, Cursor-Kreis und Maus-Trail
- `Boss Guides`
  - Overlay-Button und Guide-Fenster für unterstützte Instanzen
- `Stats`
  - kompaktes Overlay für Sekundärwerte

### Gruppe & Suche

- `Gruppensuche`
  - Länderflaggen in der Premade-Suche mit robusterer Realm-Erkennung für mehr Regionen
  - `Easy LFG` als kompaktes Bewerber-Overlay für eigene aktive Listungen
  - Invite-Timer für Dungeon-, LFR-, Arena- und Schlachtfeld-Einladungen
  - optionaler Countdown-Sound in den letzten fünf Sekunden

### Streamer Tools

- `Gruppenplaner`
  - transparentes Overlay für feste Dungeon- und Raid-Slots
  - Timerblock, Zielanzeige und Schnellaktion `Alle leeren`

### Begleiter

- `Pet Stuff`
  - Auto Respawn Pet für Begleiter-Pets außerhalb des Kampfes

## Bedienung

- Slash-Command: `/beavis`
- Minimap-Button:
  - Linksklick: Hauptfenster zeigen / verstecken
  - Rechtsklick: Schnellmenü öffnen
  - Shift-Klick: `ReloadUI()`
  - Schnellmenü: direkter Zugriff auf Checkliste-, Weekly-Keys-, Stats-, `Easy LFG`- und `Gruppenplaner`-Overlay
  - Schnellmenü: `Portal Viewer` für die aktuellen Midnight-S1-Dungeonportale
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
  - Basis-Startpunkt, Metadaten und Slash-Command
- `UI.lua`
  - Hauptfenster, Header, Sidebar und Content-Bereich
- `Tree.lua`
  - Navigation und Seitenwechsel
- `Pages/`
  - jede größere Funktion hat eine eigene Seite oder Unterlogik

Die Addon-eigenen Dateien sind bewusst menschlich kommentiert.
Nicht kommentiert werden die eingebundenen Drittanbieter-Bibliotheken unter `Libs/`.

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
