# Changelog

## 0.27.0 - 2026-04-03

### Versionshinweis

- `0.27.0` ist der aktuelle Feature-Stand; die heutigen Erweiterungen an neuen Modulen gehören weiter zu diesem Release und sind kein separates Hotfix-Release
- die mittlere Zahl steht für den nächsten Feature-/Modulstand, die hintere Zahl bleibt ohne Hotfixes auf `0`

### Neu

- neues Komfort-Modul `Cutscene Skip` ergänzt
- neues Komfort-Modul `Flugmeister-Timer` ergänzt
- neues Komfort-Modul `Schlüsselstein-Buttons` ergänzt
- neues Fenster-Modul `Portal Viewer` ergänzt
- `Schlüsselstein-Buttons` ersetzen im Mythic+-Schlüsselsteinfenster den Aktivieren-Button durch `Readycheck`, `Timer & GO` und optionalen `Auto Timer`
- `Portal Viewer` im Minimap-Schnellmenü ergänzt
- `Gruppensuche` zeigt jetzt für Dungeon-, LFR-, Arena- und Schlachtfeld-Einladungen einen sichtbaren Ablauf-Timer
- `Flugmeister-Timer` zeigt beim Flugmeister einen mittigen Countdown bis zur Ankunft
- `Flugmeister-Timer` unterstützt optionale Ankunftssounds mit Auswahl und Test-Button
- `Checkliste` enthält neue Weekly-Standardaufgaben für `PvP-Quests`, `Tiefenfortschritt` und `Tiefen-Held-Karte`

### Verbessert

- `Portal Viewer` kompakter und transparenter gestaltet und erkennt den Portalstatus robuster über Zauber- und Erfolgsdaten
- `Cutscene Skip` merkt sich ausgelöste Movie- und Cinematic-Events dauerhaft und zeigt unbekannte Szenen weiterhin einmal normal an
- `Flugmeister-Timer` lernt fehlende Flugrouten automatisch nach und nutzt bekannte Zeiten direkt als Schätzung
- `Flugmeister-Timer` bietet jetzt auswählbare Ankunftssounds, einen Test-Button sowie einen Positioniermodus mit fixierbarem Overlay
- `Flugmeister-Timer` lässt sich über ein Beispiel-Overlay auch ohne aktiven Flug ausrichten und auf seine Standardposition zurücksetzen
- `Schlüsselstein-Buttons` unterstützen optionalen Gruppen-Lock sowie frei einstellbare Timer-Sekunden zwischen `1` und `30`
- `Angelhilfe` hebt Angelgeräusche gezielter hervor, indem Musik, Ambiente und Haustier-Sounds während des Wartens reduziert und die ursprünglichen Soundeinstellungen danach wiederhergestellt werden
- Versions- und Startseiteninfos lesen Version, Release-Datum, Spielversion und Release-Kanal jetzt zentral aus den Addon-Metadaten, damit der Projektstatus korrekt den aktuellen Status wie `Beta` statt eines festen `Alpha`-Labels zeigt
- `Gruppensuche` bietet optionalen Countdown-Sound für Einladungen in den letzten fünf Sekunden
- `Gruppensuche` registriert optionale Battlefield-Events jetzt client-sicherer
- `Gruppensuche` deckt mit den Länderflaggen jetzt deutlich mehr Realms ab und verankert sie sauberer am sichtbaren Namen

### Behoben

- `Checkliste` setzt Berufs-Weekly-Aufgaben wieder zuverlässig beim Wochenreset zurück

## 0.24.1 - 2026-03-26

### Behoben

- `Jagd-Fortschritt` zeigt `Phase 1/4` nicht mehr ohne aktive Jagd an
- `Jagd-Fortschritt` akzeptiert nur noch echte Blizzard-Prey-Hunt-Widgets und ignoriert fremde Statusleisten

## 0.24.0 - 2026-03-26

### Neu

- neues Komfort-Modul `Jagd-Fortschritt` ergänzt
- aktive Midnight-Jagden zeigen jetzt eine Stufenanzeige direkt am Blizzard-Jagd-Symbol

### Verbessert

- `Jagd-Fortschritt` verwendet jetzt die Anzeige `Phase 1/4` bis `Boss bereit` statt uneindeutiger Prozentwerte
- `Jagd-Fortschritt` initialisiert sich nach Login, Reload und Weltwechsel robuster neu
- `Jagd-Fortschritt` übernimmt die Frame-Ebene des Blizzard-Widgets, damit die Anzeige nicht dauerhaft vor Karte und großen Fenstern liegt

### Behoben

- `Weekly Keys` zählt für die Weekly-Gear-Anzeige nur noch abgeschlossene M+-Runs
- `Weekly Keys` verhindert doppelte Einträge, wenn ein Key zusätzlich als normaler mythischer Dungeon erkannt wurde
- `Angelhilfe`-Soundregler nutzt wieder einen sauberen Bereich und lässt sich korrekt ziehen
- `Maus-Helfer` richtet den unteren Farbbutton jetzt sauber wie den oberen aus
- `Gruppensuche` zeigt die `Easy LFG`-Slider und den unteren Bedienbereich wieder ohne Überlappungen
- `Gruppenplaner` schneidet den unteren Bereich rechts nicht mehr ab

## 0.23.0 - 2026-03-24

### Neu

- neues Modul `Boss Guides` ergänzt
- neues Modul `Maus-Helfer` ergänzt
- `Boss Guides` blendet einen frei positionierbaren Overlay-Button für unterstützte Dungeons und Raids ein
- `Boss Guides` öffnet ein Guide-Fenster mit Instanz-Auswahl, Boss-Tabs und hinterlegten Taktiken
- `Maus-Helfer` bündelt Cursor-Kreis, Maus-Trail und Blizzard-Mausvergrößerung in einer eigenen Seite

### Verbessert

- gebündelte Schriftarten für die UI überarbeitet und um neue Fonts ergänzt
- Lokalisierungen für `Boss Guides` und `Maus-Helfer` in `deDE` und `enUS` ergänzt
- Tree, Core und Font-Registrierung um die neuen Module erweitert

## 0.22.0 - 2026-03-23

### Neu

- `Easy LFG` als kompaktes Applicant-Overlay für eigene Gruppenanzeigen ergänzt
- Bewerber können direkt im Overlay eingeladen oder abgelehnt werden
- Rollen- und Spezialisierungsanzeige für Bewerber im Overlay ergänzt
- Mehrspieler-Bewerbungen werden als aufklappbare Gruppen über den Gruppenleiter dargestellt
- Minimap-Schnellmenü um `Easy LFG` und den `Gruppenplaner` erweitert
- `Angelhilfe` als Ein-Tasten-Komfortmodul für entspannteres Angeln ergänzt
- `Gruppenplaner` um Zielvorschläge für Dungeon-, Raid- und Tiefenziele inklusive `M+0` bis `M+20` erweitert
- `Gruppenplaner`-Sloteditor um Klassen- und Spezialisierungswahl ergänzt

### Verbessert

- `Easy LFG` öffnet und schließt sich automatisch anhand der eigenen aktiven Listung
- `Easy LFG` unterstützt jetzt Position, Lock, Skalierung, Transparenz, Größenänderung und Scrollliste dauerhaft gespeichert
- `Easy LFG` zeigt Länderflaggen, Gruppierung, Rollen- und Spec-Symbole kompakter und übersichtlicher an
- abgelaufene oder inaktive Bewerbungen werden im `Easy LFG` nicht mehr angezeigt
- `Gruppenplaner`-Overlay um `Menü`, `X`, `Alle leeren` und einen integrierten Timerblock ergänzt
- Header-, Timer- und Ziellayout des `Gruppenplaners` neu gestapelt, damit Überlappungen im Overlay wegfallen
- Slot-Bearbeiten-Dialog des `Gruppenplaners` wächst jetzt sauber mit Klassen- und Spec-Auswahl mit, ohne dass Buttons überlappt werden

## 0.21.0 - 2026-03-23

### Neu

- neues Modul `Markerleiste` ergänzt
- transparente, frei verschiebbare und skalierbare Leiste für Raidmarker eingebaut
- normaler Klick setzt Zielmarker direkt auf das aktuelle Ziel
- `Shift`-Klick setzt Bodenmarker, sofern Gruppenbedingungen und Berechtigungen erfüllt sind

### Verbessert

- Markerleiste als eigene Seite im Hauptfenster integriert
- Overlay-Darstellung der Markerleiste auf reine Symbolleiste reduziert
- Hover-Zustand der Markersymbole klarer hervorgehoben

### Hinweis

- Bodenmarker funktionieren nur in Gruppen; in Raids zusätzlich nur mit Leiter- oder Assistentenrechten

## 0.20.0 - 2026-03-23

### Neu

- neue Funktion `Overlays schnell ausblenden` für instanzierte Bereiche ergänzt
- auswählbar, welche Overlays automatisch ausgeblendet werden sollen: `Checkliste`, `Weekly Keys` und `Stats`
- zusätzliche Option `Nur im Kampf ausblenden` ergänzt, damit die Ausblendung in instanzierten Bereichen optional auf Kampf begrenzt werden kann

### Verbessert

- Minimap-Kontextmenü zeigt für das Thema nur noch den schnellen Master-Schalter, die Detailauswahl liegt in den globalen Einstellungen
- Einstellungsseite in die Bereiche `Allgemein`, `Minimap`, `Schnell ausblenden` und `Zurücksetzen` gegliedert

## 0.19.3 - 2026-03-23

### Hotfix

- Auktionshaus-Logging für Commodities korrigiert, damit die Einstellgebühr mit `itemID` statt fälschlich mit `itemLocation` berechnet wird


## 0.19.0 - 2026-03-23

### Verbessert

- Checklisten-Tracker blendet sich bei aktiver Option in Raid, Dungeon, Tiefe und Schlachtfeld während des Kampfes automatisch aus
- Weekly-Keys-Overlay blendet sich bei aktiver Option in Raid, Dungeon, Tiefe und Schlachtfeld während des Kampfes automatisch aus

## 0.18.0 - 2026-03-23

### Neu

- `Quest-Abbruch` als eigenes Modul aus `Quest Check` ausgelagert
- `Quest Check` wieder auf Suche und Statusprüfung fokussiert

### Verbessert

- Quest-Abbruch filtert sichtbare Standard-Questlogeinträge strenger, damit Task-, Story- und Kampagnenzeilen nicht als normale Abbruchliste erscheinen

## 0.17.0 - 2026-03-23

### Neu

- `Quest Check` um eine Auswahl-Liste zum Abbrechen aktiver Quests erweitert
- einzelne Quests können nun gezielt markiert und gesammelt abgebrochen werden
- zusätzliche Schnellaktionen für `Alle markieren` und `Alle demarkieren`

## 0.16.2 - 2026-03-23

### Hotfix

- Tooltip-Itemlevel im sicheren Tooltip-Pfad gegen mehrere Taint-Fälle abgesichert
- textbasierte Tooltip-Zeilensuche durch referenzbasierte Aktualisierung ersetzt
- GUID-basierte Vergleiche sowie Cache- und Pending-Zustände aus dem kritischen Tooltip-Laufweg entfernt

## 0.16.1 - 2026-03-23

### Neu

- Versionsschema auf `major.minor.patch` umgestellt
- Versionierungsregeln in der Projektdokumentation festgehalten
- `Tooltip-Itemlevel` als Komfort-Modul für Mouseover-Tooltips ergänzt

### Versionierung

- `major` steht für Hauptversionen wie `1.0.0`
- `minor` steht für Feature-Releases wie `0.1.0`
- `patch` steht für Hotfix-Releases wie `0.0.1`
- neue Module müssen ab jetzt mindestens die Feature-Version erhöhen

## 0.0.16 Alpha - 2026-03-22

### Neu

- `Checkliste` als eigenes Modul eingebaut
- `Itemlevel Guide` als eigenes Modul eingebaut
- `Logging` als eigenes Modul eingebaut
- `Quest Check` als eigenes Modul eingebaut
- `Stats` als eigenes Overlay-Modul eingebaut
- `Tooltip-Itemlevel` als Komfort-Modul eingebaut
- `Weekly Keys` als eigenes Overlay-Modul eingebaut
- Laufzeit-Lokalisierung für `deDE` und `enUS` eingebaut

### Itemlevel Guide

- neue Fortschritt-Seite als kompakte Saisonreferenz
- Tabellen für Upgradepfade, Crafting, Dungeons, Raid und Tiefen
- bewusst eigene Dashboard-Optik statt einfacher Zahlenliste
- Titel und Tabellenüberschriften sprachlich für das Addon angepasst

### Checkliste

- Daily-, Weekly- und `Im Blick halten`-Kategorien
- manuelle Aufgaben mit frei wählbarer Kategorie
- kleines Tracker-Fenster außerhalb des Hauptfensters
- Header-Aktionen für `Pin`, `Einst.`, `Add`, `Vault` und Einklappen
- automatische Resets für Daily und Weekly
- dynamische Weekly-Berufsaufgaben mit aktuellem Berufsnamen
- Minimap-Kontextmenü zum Ein- und Ausblenden des Trackers

### Logging

- Verkaufslog mit itemisierten Händlerverkäufen
- aufklappbare Verkaufszeilen für Itemdetails und Gold pro Item
- Reparaturlog mit Tagessummen und aufklappbaren Tagesdetails
- Gold-Einnahmen nach Kategorie
- Gold-Ausgaben nach Kategorie
- Aufbewahrungslogik:
  - Verkaufslog 30 Tage
  - Reparaturlog 30 Tage
  - Gold-Einnahmen 1 Jahr
  - Gold-Ausgaben 1 Jahr
  - manuelles Löschen nach Zeitraum über Popup

### Overlay-Module

- `Stats` zeigt Sekundärwerte in einem kompakten Overlay
- `Weekly Keys` zeigt die höchsten 8 Weekly-Dungeons inklusive Weekly-Loot
- beide Overlays haben:
  - eigene Anzeigeoptionen
  - Fixieren
  - Positions-Reset
  - Skalierung
  - kompaktere Standardwerte
- beide Overlays sind über das Minimap-Kontextmenü direkt ein- und ausblendbar

### Weekly Keys

- nicht erkannte Non-Key-Runs werden jetzt differenzierter als `Heroisch <Dungeon>` oder `Mythisch <Dungeon>` erfasst, sobald Blizzard die Daten liefert
- Overlay-Layering so angepasst, dass Blizzard- und Battle.net-Overlays nicht unnötig vom Weekly-Keys-Fenster überdeckt werden

### Lokalisierung

- Sprache im Addon zwischen Deutsch und Englisch umschaltbar
- statische UI-Texte werden nach Sprachwechsel zentral neu aufgebaut
- neue Module und Tabelleninhalte für Itemlevel Guide, Logging, Checkliste, Weekly Keys, Stats, LFG, Pet Stuff und Combat Text lokalisiert

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
- Rechtsklick auf den Minimap-Button öffnet ein Schnellmenü
- Hauptfenster mit breiterer Sidebar, ruhigerem Header und luftigerer Home-Seite neu aufgebaut

### Weitere Anpassungen

- `Quest Check` Hinweistext konkretisiert: Beispiel jetzt mit `Quest ID 12345`
- `Combat Text` Text und Warnbereich sprachlich überarbeitet
- Hinweis bei `Auto Respawn Pet`, dass das Rufen nur außerhalb des Kampfes funktioniert
- `Tooltip-Itemlevel` zeigt das ausgerüstete Itemlevel anderer Spieler direkt im Mouseover-Tooltip
- mehrere UI-Abstände, Tracker-Details und Textausrichtungen nachgezogen
- Versionsstand auf `0.0.16 Alpha` angehoben

### Codepflege

- Addon-eigene Dateien menschlicher kommentiert
- erkannte doppelte oder unklare Logik schrittweise bereinigt
- README für Nutzer und Einsteiger im Code erweitert

## 0.0.2 Alpha - 2026-03-20

- erste spielbare Alpha-Version
- Hauptfenster mit Sidebar, Home- und Versionsseite
- Versionsseite erkennt höhere BeavisQoL-Versionen bei anderen Spielern
- Levelzeit-Tracker mit gespeicherten Charakterdaten
- Misc-Module:
  - Auto Sell Junk
  - Auto Repair
  - Easy Delete
  - Fast Loot
- Kamera-Distanz per Button zwischen Standard und Max Distance umschaltbar
- Pet Stuff: Auto Respawn Pet
- LFG: Länderflaggen in der Premade-Gruppensuche
- Combat Text mit Font-Auswahl und Stil-Reglern
- Minimap-Button und Slash-Command `/beavis`
