# Changelog

## 0.35.0 - 2026-04-11

### Versionshinweis

- `0.35.0` ist der aktuelle Feature-Stand nach `0.30.0`
- seit `0.30.0` sind fünf neue Module hinzugekommen: `Listing-Presets`, `Auktionshaus-Favoriten`, `Auktionshaus-Filter`, `Performance-Profiler` und `Chonky Loadout-Dropdown`
- die mittlere Zahl steigt damit auf `35`, der Hotfix-Zähler steht für diesen Stand auf `0`

### Neue Module

- neues Modul `Listing-Presets` für die Gruppensuche ergänzt
- neues Modul `Auktionshaus-Favoriten` ergänzt
- neues Modul `Auktionshaus-Filter` ergänzt
- neues Modul `Erweiterter CPU/Performance-Profiler` ergänzt
- neues Modul `Chonky Loadout-Dropdown` ergänzt

### Qualitätsverbesserungen

- Performance-Verbesserungen am `Maus-Helfer` vorgenommen
- Verbesserungen an `Weekly Keys`, `Easy LFG` und weiteren Overlay-Bereichen vorgenommen
- Bedienung und Darstellung in bestehenden Fenstern und Menüs weiter vereinheitlicht
- mehrere bestehende Module in Performance, Stabilität und Kompatibilität weiter überarbeitet

### Hotfixes

- Fehlerbehebungen im `Organisierte Gruppen`-/`LFG`-Bereich ergänzt
- Korrekturen bei Dropdowns, Menüs und Fensterverhalten vorgenommen
- Kompatibilitätsfixes für Blizzard-Frames, Inspect-Ansichten und Tooltips ergänzt
- mehrere Lua-Fehler sowie kleinere Stabilitätsprobleme behoben

## 0.30.0 - 2026-04-08

### Versionshinweis

- `0.30.0` ist der nächste veröffentlichte Feature-Stand nach `0.29.0`
- dieser Release bündelt ein neues Modul, eine größere Navigation-/Schnellansicht-Überarbeitung und einen breiten UI-Polish über viele bestehende Seiten
- die mittlere Zahl steigt damit auf `30`, der Hotfix-Zähler startet für diesen Stand wieder bei `0`

### Neu

- neues Modul `Auktionshaus` ergänzt
- `Auktionshaus` besitzt die Option `Nur aktuelle Erweiterung automatisch aktivieren`
- `Schnellansicht` öffnet jetzt in einem eigenen Fenster mit Tabs für `Levelzeit`, `Itemlevel Guide`, `Quest Check`, `Quest-Abbruch` und `Goldauswertung`
- das Minimap-Kontextmenü ist in `Schnellansicht` und `An/Aus` gegliedert und besitzt passende Icons

### Verbessert

- die Hauptnavigation zeigt jetzt nur noch Kategorien; Module werden innerhalb der Kategorien über Tabs geöffnet
- `Saison Portale`, `Checkliste` und `Gruppenplaner` öffnen aus dem Minimap-Kontextmenü jetzt direkt ihr Fenster oder Overlay; die Einstellungen liegen jeweils am Zahnrad
- `Minimap-Sammler` wurde auf ein Drei-Spalten-Board mit Drag & Drop zwischen Sammler, Minimap und Ausblenden umgestellt
- Startseite, globale Einstellungen, Schnellansicht und viele Modulseiten nutzen jetzt einen gemeinsamen warmen Stil mit einheitlicheren Linien, Titeln und Abständen
- zahlreiche Modulnamen, Hinweise und Enduser-Texte wurden klarer und deutschsprachig überarbeitet

## 0.29.0 - 2026-04-07

### Versionshinweis

- `0.29.0` ist der nächste veröffentlichte Feature-Stand nach `0.28.0`
- dieser Release ergänzt bestehende Komfortfunktionen: `Rufsuche` und `Währungssuche` haben jetzt eigene Schalter im `Misc`-Bereich
- die mittlere Zahl steigt damit auf `29`, der Hotfix-Zähler startet für diesen Stand wieder bei `0`

### Neu

- `Rufsuche` ist jetzt als eigener Bereich im `Misc`-Menü sichtbar und direkt aktivierbar oder deaktivierbar
- `Währungssuche` ist jetzt als eigener Bereich im `Misc`-Menü sichtbar und direkt aktivierbar oder deaktivierbar
- Sidebar und Modulsuche können jetzt direkt zu `Rufsuche` und `Währungssuche` innerhalb von `Misc` springen

### Verbessert

- deaktivierte `Rufsuche` stellt das Blizzard-Ruf-Fenster wieder auf sein Standardlayout zurück
- deaktivierte `Währungssuche` stellt das Blizzard-Währungsfenster samt Such-/Button-Anordnung wieder auf sein Standardlayout zurück

## 0.28.0 - 2026-04-07

### Versionshinweis

- `0.28.0` ist der nächste veröffentlichte Feature-/Modulstand nach `0.27.2`
- in diesem Release-Batch steckt mit dem `Minimap-Sammler` ein neues eigenständiges Modul; weitere Ergänzungen wie `Makro`, `Ruf` und `Währungen` sind zusätzliche Features im selben Release
- die mittlere Zahl steigt damit auf `28`, der Hotfix-Zähler startet für diesen Stand wieder bei `0`

### Neu

- neues Modul `Minimap-Sammler` ergänzt
- der Sammler bringt einen eigenen frei verschiebbaren Launcher mit rundem Beavis-Icon und transparentem Sammelfenster mit
- erkannte Minimap-Buttons können jetzt pro Eintrag gesammelt, direkt auf der Minimap gelassen oder komplett ausgeblendet werden
- `Makro`, `Ruf` und `Währungen` haben jeweils eine eigene Suchfunktion direkt in den Blizzard-Fenstern erhalten
- `Mouse Helper` zeigt jetzt optional einen `Cast-Ring` direkt um den Cursor während des Zauberns

### Verbessert

- der `Minimap-Sammler` besitzt getrennte Skalierung für Launcher und Sammelfenster
- `Mouse Helper` unterstützt Klassenfarben jetzt sowohl für den Maus-Trail als auch für den Cursor-Kreis
- der `Minimap-Sammler` öffnet per Rechtsklick direkt `/beavis` und bietet schnellere Bedienung für Reload und Launcher-Steuerung
- die Erkennung und Benennung gesammelter Minimap-Buttons wurde robuster auf echte Addon-Namen umgestellt
- die Moduloptionen des `Minimap-Sammlers` sind kompakter in mehreren Spalten angeordnet
- der `Mouse Helper` reduziert Leerlaufkosten sauberer und enthält Feinschliff an Trail-Fade und Ring-Darstellung

### Behoben

- Sammler-Launcher-Kreis und Logo-Ausrichtung stabilisiert, ohne den bekannten Beavis-Minimapbutton umzubauen
- mehrere deutsche Collector- und MouseHelper-Texte auf saubere Umlaute und klarere Beschriftungen gebracht
- Klassenfarben-Erkennung im `Mouse Helper` robuster gegen unterschiedliche Blizzard-Farbobjekte gemacht

## 0.27.2 - 2026-04-06

### Versionshinweis

- `0.27.2` ist ein weiterer Hotfix-/Verbesserungsstand zum bestehenden Release `0.27.0`, weil weiterhin keine neuen Module hinzugekommen sind
- der nächste veröffentlichte Feature-/Modulstand bleibt damit `0.28.0`

### Verbessert

- `Boss Guides` für `Maisarakavernen`, `Akademie von Algeth'ar`, `Himmelsnadel` und `Sitz des Triumvirats` weiter auf deutsche, hoverbare Bosszauber mit Spell-IDs und Icons umgestellt
- mehrere Dungeon-Guides nutzen jetzt konsistente deutsche Bosszaubernamen statt gemischter englischer Platzhalter

### Behoben

- sichtbare numerische Spell-IDs aus den Bossguide-Fließtexten entfernt, ohne die Hover- und Tooltip-Funktionalität zu verlieren
- Bossguide-Lokalisierungen in `deDE` auf fehlerhafte Umlaute und Darstellungsprobleme bereinigt

## 0.27.1 - 2026-04-06

### Versionshinweis

- `0.27.1` ist ein Hotfix-/Verbesserungsstand zum bestehenden Release `0.27.0`, weil keine neuen Module hinzugekommen sind
- der nächste veröffentlichte Feature-/Modulstand bleibt damit `0.28.0`

### Verbessert

- `Boss Guides` um umfangreiche Dungeon-Guides für `Nexuspunkt Xenas`, `Terrasse der Magister`, `Windläuferturm`, `Akademie von Algeth'ar`, `Grube von Saron`, `Himmelsnadel`, `Sitz des Triumvirats` und `Maisarakavernen` erweitert
- `Boss Guides` unterstützen jetzt einklappbare Rollenabschnitte für `Tank`, `DD`, `Heal`, `HC` und `Mythisch`, während `Allgemein` offen bleibt
- `Gruppenplaner` unterstützt jetzt 40-Spieler-Raids mit erweitertem Raidlayout und automatischer Ziel- und Schwierigkeits-Erkennung für Raid-Listings
- `Maisarakavernen` auf die kombinierte Duo-Struktur `Muro'jin & Nekraxx` umgestellt und der zusätzliche `Überblick`-Tab wieder entfernt
- `Boss Guides` behalten Rollen-Symbole auch in den neuen einklappbaren Überschriften
- `Gruppenplaner` skaliert Raidansichten breiter statt nur höher und zeigt alle Raidgruppen im Overlay sauber an
- `Gruppenplaner` öffnet auf dem eigenen Dungeon-Slot jetzt direkt die Rollen-Zuteilung statt des allgemeinen Slot-Editors
- Whisper- und Invite-Namen im `Gruppenplaner` werden robuster normalisiert, damit Realm-Anteile und gespeicherte Slot-Namen verlässlicher zusammenpassen
- `!inv`-AutoInvite funktioniert jetzt in Dungeon und Raid, greift aber nur noch, wenn für denselben Spieler bereits ein `!enter`-Eintrag im Planner existiert

### Behoben

- einklappbare Bossguide-Abschnitte rufen `UpdateGuideText` jetzt korrekt auf und werfen keinen Nil-Fehler mehr
- der `Gruppenplaner` vermeidet falsche Invite-Namen mit doppeltem Realm-Suffix, die zu irreführenden Blizzard-Fehlermeldungen führen konnten
- mehrere doppelte Lokalisierungs-Keys und Lua-Diagnostics-Fundstellen in bestehenden Modulen bereinigt, ohne produktive WoW-Funktionalität zu ändern

## 0.27.0 - 2026-04-03

### Versionshinweis

- `0.27.0` ist der aktuelle veröffentlichte Feature-Stand; mehrere neue Module können gemeinsam zu diesem einen Release gehören und erzeugen nicht automatisch mehrere Minor-Sprünge
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
- neue Module verlangen ab jetzt mindestens einen Feature-Release
- mehrere neue Module dürfen gemeinsam in demselben Feature-Release erscheinen

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
