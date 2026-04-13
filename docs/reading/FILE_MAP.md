# Wichtige Dateien

## Zuerst lesen

- [README.md](../../README.md)
  Projektziel, aktueller Stand, Versionierung und Installationshinweise.
- [CHANGELOG.md](../../CHANGELOG.md)
  Release-Historie und sichtbare Änderungen.
- [BeavisQoL.toc](../../BeavisQoL.toc)
  Addon-Metadaten, Version, Release-Datum, Dateien und Lade-Reihenfolge.

## Release und Repository-Hygiene

- [.gitignore](../../.gitignore)
  Lokale Arbeitsreste, die künftig nicht neu getrackt werden sollen.
- [.gitattributes](../../.gitattributes)
  Ausschlüsse für Release-Archive.
- [.github/workflows/package-release.yml](../../.github/workflows/package-release.yml)
  Erzeugung und Upload des Release-ZIPs.

## Kern-Einstiegspunkte im Code

- [Core.lua](../../Core.lua)
  Zentrale Metadaten, gemeinsame Funktionen und Hilfslogik.
- [UI.lua](../../UI.lua)
  Aufbau des Hauptfensters und allgemeine UI-Helfer.
- [Tree.lua](../../Tree.lua)
  Navigationsbaum, Modulregistrierung und Suchbegriffe.

## Wichtige Inhaltsbereiche

- [Localization/Localization.lua](../../Localization/Localization.lua)
  Gemeinsamer Zugriff auf Übersetzungen.
- [Localization/deDE.lua](../../Localization/deDE.lua)
  Deutsche Texte.
- [Localization/enUS.lua](../../Localization/enUS.lua)
  Englische Texte.

## Aktuell sensible Module

- [Pages/MouseHelper.lua](../../Pages/MouseHelper.lua)
  Cursor-Kreis, Cast-Ring, Trail und Laufzeit-Updates.
- [Pages/StreamerPlanner.lua](../../Pages/StreamerPlanner.lua)
  Overlay, Slot-Logik, Bewerberverwaltung und Whisper-Handling.
- [Pages/Misc/MinimapHud.lua](../../Pages/Misc/MinimapHud.lua)
  Minimap-HUD-Logik.
- [MinimapCollector.lua](../../MinimapCollector.lua)
  Sammlung und Verwaltung von Minimap-Buttons.
- [MinimapButton.lua](../../MinimapButton.lua)
  Eigener Minimap-Button und Interaktionen.

## Zusätzliche Referenzen

- [fonts/LIZENZNACHWEISE.md](../../fonts/LIZENZNACHWEISE.md)
  Font- und Asset-Hinweise.
- [Media/Sounds/FlightTimer/README.md](../../Media/Sounds/FlightTimer/README.md)
  Sound-bezogene Zusatzinfos.
