# Beavis Quality of Life

Ein World of Warcraft Addon für Retail, das kleine und praktische Quality-of-Life-Funktionen an einem Ort sammelt.

## Über das Projekt

Ich bin **Beavis** und streame auf Twitch unter **Beavismania**.  
Dieses Addon ist mein erstes eigenes WoW-Addon und gleichzeitig ein kleines Lernprojekt, mit dem ich Schritt für Schritt **Lua** und die Entwicklung von WoW-Addons besser verstehen möchte.

Das Ziel ist nicht, alles auf einmal zu bauen, sondern nach und nach sinnvolle Funktionen zu ergänzen, sauberer zu strukturieren und dabei immer besser zu werden.  
`Beavis Quality of Life` ist deshalb ganz bewusst noch im Aufbau und wird mit der Zeit weiter wachsen.

## Aktueller Stand

- Status: `0.0.2 Alpha`
- Spielversion: `WoW Retail / Patch 12.0.1`
- Fokus: kleine Komfortfunktionen, modular aufgebaut

## Was das Addon aktuell kann

- Eigenes Hauptfenster mit Sidebar, Startseite und Versionsbereich
- Öffnen über `/beavis`
- Minimap-Button zum schnellen Öffnen
- **Levelzeit:** Erfasst die gespielte Zeit pro Level und speichert sie charakterbezogen
- **Misc:** `Auto Sell Junk`, `Auto Repair`, `Easy Delete` und `Fast Loot`
- **Pet Stuff:** `Auto Respawn Pet` beschwört dein zuletzt aktives Begleiter-Pet erneut
- **LFG:** Zeigt Länderflaggen in der Premade-Gruppensuche auf Basis des Realms an
- **Combat Text:** Passt Blizzard-Kampftext optisch an, inklusive Schriftart und Bewegungsverhalten

## Installation

### Manuell über GitHub

Wichtig:
Wenn du das Addon als ZIP laden willst, nutze nach Moeglichkeit die Datei aus
den GitHub Releases.

Der normale GitHub-Quellcode-Download ueber `Code` -> `Download ZIP` erzeugt
immer einen Ordnernamen wie `BeavisQoL-main`. Das ist ein GitHub-Standard und
nicht die eigentliche Addon-Ordnerstruktur.

Die Release-ZIP dieses Projekts entpackt dagegen direkt in einen Ordner
`BeavisQoL`.

1. Release-ZIP herunterladen oder das Repository klonen.
2. Den Addon-Ordner nach  
   `World of Warcraft/_retail_/Interface/AddOns/`  
   kopieren.
3. Darauf achten, dass der Ordner am Ende **`BeavisQoL`** heißt.
4. World of Warcraft starten oder die UI neu laden.

Beispielpfad unter Windows:

```text
World of Warcraft\_retail_\Interface\AddOns\BeavisQoL
```

## Nutzung

- Slash-Command: `/beavis`
- Alternativ über den Minimap-Button

Im Addon-Fenster findest du die einzelnen Bereiche direkt über die Sidebar.

## Warum dieses Projekt existiert

Dieses Projekt ist für mich eine Mischung aus:

- Lua lernen
- WoW-UI und Addon-Architektur verstehen
- eigene Ideen direkt im Spiel umsetzen
- etwas bauen, das mit jeder Version ein bisschen besser wird

Ich möchte dabei nicht nur ein funktionierendes Addon bauen, sondern auch selbst besser im Umgang mit Lua, WoW-APIs und sauberer Struktur werden.

## Was noch kommen soll

Das hier ist erst der Anfang. Geplant sind unter anderem:

- weitere kleine QoL-Module
- bessere Einstellungen und mehr Feinschliff im UI
- mehr Komfortfunktionen für den Spielalltag
- weitere Ausbau- und Lernschritte rund um Lua und WoW-Addon-Entwicklung

Kurz gesagt:  
**Das Addon ist noch klein, aber es wird mehr werden.**

## Feedback und Kontakt

Wenn du Feedback, Ideen oder Support dalassen möchtest:

- Twitch: [https://www.twitch.tv/beavismania](https://www.twitch.tv/beavismania)
- Website / Community: [https://www.beavismania.de](https://www.beavismania.de)

## Lizenz

Dieses Projekt ist proprietaer und bleibt urheberrechtlich geschuetzt.

Erlaubt ist die private, nicht-kommerzielle Nutzung offizieller Versionen von
`BeavisQoL` in World of Warcraft.

Ohne vorherige schriftliche Genehmigung sind insbesondere nicht erlaubt:

- Weiterverbreitung des Projekts oder wesentlicher Teile davon
- Veraenderung und Veroeffentlichung abgeleiteter Versionen
- Wiederverwendung von Code, Assets oder anderen Projektbestandteilen in
  anderen Addons oder Projekten
- kommerzielle Nutzung

Die vollstaendigen Bedingungen stehen in der Datei `LICENSE`.

## Hinweis

Dieses Projekt befindet sich noch in einer frühen Phase. Es ist ein persönliches Lern- und Entwicklungsprojekt und kann sich daher regelmäßig verändern, erweitern oder umgebaut werden.
