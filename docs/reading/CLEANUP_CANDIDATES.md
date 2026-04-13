# Cleanup-Kandidaten

Stand: `2026-04-13`

## Cleanup-Status

- Vollbackup vor dem Cleanup:
  `C:\Users\Danie\OneDrive\Backups\BeavisQoL\2026-04-13_062155`
- Physisches Cleanup lokal bereits ausgefuehrt:
  `.tmp/`, `.vscode/`, `release/` und `debug.log` wurden aus dem Arbeitsbaum entfernt.
- Repo-Bereinigung noch offen, bis die geloeschten getrackten Dateien committed sind.

## Kurzfazit

- Vor dem Cleanup enthielt `.tmp` etwa `73.85 MB`, `4595` Dateien und `708` Unterordner.
- Vor dem Cleanup waren `54` Eintraege unter `.tmp` noch im Git-Index.
- Vor dem Cleanup war `.vscode/settings.json` ebenfalls noch getrackt.
- `debug.log` und `release/BeavisQoL.zip` waren lokale Laufzeit-/Buildreste.

## Wahrscheinliche Altlasten im Git-Index

### Temp- und Referenzdateien unter `.tmp`

- Blizzard-/UI-Snapshots:
  `Blizzard_CurrencyTransfer.lua`, `Blizzard_CurrencyTransfer.xml`, `Blizzard_MacroUI.lua`, `Blizzard_MacroUI.xml`, `Blizzard_TokenUI.lua`, `Blizzard_TokenUI.xml`, `CursorRing.lua`, `ReputationFrame.lua`, `ReputationFrame.xml`, `wow-ui-tree.json`
- Vergleichs-/Referenzordner:
  `InFlightRef`
- Brand-/Logo-Arbeitsmaterial:
  gesamter Teilbaum `.tmp/brandassets/`
- Weitere Top-Level-Artefakte:
  `logo_original_48.tga`, `logo_preview.png`, `logo_round_mask.png`, `logo_rounded_preview.png`, `twitch_favicon.ico`

### Editor-Dateien

- `.vscode/settings.json`

## Lokale Altlasten ausserhalb des Git-Index

### Tooling- und Analyse-Scratch

- `compare/`
- `luals-check/`
- `luals-meta*/`
- `luals-run*/`
- `luals-vscode-check*/`
- `luals-vscode-meta*/`

### Importierte Fremdquellen und Vergleichsstaende

- `SpellbookAdjust_src/`
- `TomCats_src/`
- `wow-ui-source/`
- `wow-ui-source-git/`
- `SpellbookAdjust.zip`
- `TomCats-2.5.72.zip`
- `blizzmove_current.lua`
- `blizzmove_frames_current.lua`
- `moveany_current.lua`

### Lokale Laufzeit-/Buildreste

- `debug.log`
- `release/BeavisQoL.zip`

## Empfohlene Aufraeum-Reihenfolge

1. Getrackte Loeschungen committen, damit `.tmp`-Altlasten und `.vscode/settings.json` auch aus Git verschwinden.
2. Ignore- und Release-Ausschluesse beibehalten, damit die Bereiche nicht wieder auftauchen.
3. Neue lokale Scratch- oder Importbereiche kuenftig nur noch unter ignorierten Pfaden anlegen.

## Wichtiger Hinweis

`.gitignore` verhindert nur neue, ungetrackte Dateien.
Bereits getrackte Altlasten muessen spaeter bewusst per Git-Bereinigung entfernt werden.
