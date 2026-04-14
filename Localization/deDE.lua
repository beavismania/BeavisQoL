local _, BeavisQoL = ...

BeavisQoL = BeavisQoL or {}
BeavisQoL.Localization = BeavisQoL.Localization or {}

BeavisQoL.Localization.deDE = {
	-- Allgemein
	UNKNOWN = "Unbekannt",
	RELOAD = "Neu laden",
	CLOSE = "Schließen",
	CANCEL = "Abbrechen",
	VERSION = "Version",
	LANGUAGE = "Sprache",

	-- Header/Main
	HEADER_SUBTITLE = "Das Quality of Life Addon aus der BeavisMania",

	-- Navigation
	NAVIGATION = "Navigation",
	NAVIGATION_HINT = "",
	NAVIGATION_SEARCH_PLACEHOLDER = "Navigation durchsuchen",
	NAVIGATION_SEARCH_HINT = "Filtert Namen und Seitentexte live.",
	NAVIGATION_SEARCH_RESULTS = "%d Treffer in der Navigation",
	NAVIGATION_SEARCH_EMPTY = "Keine Treffer in der Navigation.",
	NAVIGATION_SECTION_ADDON = "Addon",
	GENERAL = "Allgemein",
	MODULES = "Module",
	HOME = "Startseite",
	SETTINGS = "Einstellungen",
	PROGRESS = "Fortschritt",
	GOLD_TRADE = "Gold & Handel",
	COMFORT = "Komfort",
	INTERFACE_COMBAT = "Interface & Kampf",
	GROUP_SEARCH = "Gruppe & Suche",
	STREAMER_TOOLS = "Streamer Tools",
	PROGRESS_QUESTS = "Fortschritt & Quests",
	GOLD_VENDOR = "Gold & Händler",
	EVERYDAY_AUTOMATION = "Alltag & Automatik",
	WINDOWS_SEARCH = "Fenster & Suche",
	WORLD_TRAVEL = "Welt & Reisen",
	GROUP_INSTANCES = "Gruppe & Instanzen",
	INTERFACE_OVERLAYS = "Interface & Overlays",
	COMPANION = "Begleiter",

	-- Module/Entries
	LEVEL_TIME = "Levelzeit",
	CHECKLIST = "Checkliste",
	WEEKLY_KEYS = "Weekly Keys",
	ITEMLEVEL_GUIDE = "Itemlevel Guide",
	QUEST_CHECK = "Quest Check",
	QUEST_ABANDON = "Quest-Abbruch",
	GOLDAUSWERTUNG = "Goldauswertung",
	AUTOSELL_JUNK = "Automatisch Verkaufen",
	AUTOREPAIR = "Automatisch Reparieren",
	AUCTION_HOUSE_MODULE = "Auktionshaus",
	FAST_LOOT = "Schneller Looten",
	EASY_DELETE = "Einfaches Item löschen",
	TOOLTIP_ITEMLEVEL = "Tooltip-Itemlevel",
	TOOLTIP_SETTINGS = "Tooltip Einstellungen",
	CAMERA_DISTANCE = "Max. Sichtweite",
	MACRO_FRAME = "Makrofenster",
	TALENT_FRAME_SCALE = "Talentfenster-Skalierung",
	TALENT_LOADOUT_REMINDER = "Talent-Loadout-Reminder",
	MINIMAP_HUD = "Minimap-HUD",
	PREY_HUNT_PROGRESS = "Beutejagd",
	FISHING_HELPER = "Bequem Angeln",
	STATS = "Stats",
	MARKER_BAR = "Markerleiste",
	COMBAT_TEXT = "Kampftext",
	MOUSE_HELPER = "Maushilfen",
	MINIMAP_COLLECTOR = "Minimap-Sammler",
	BOSS_GUIDES = "Boss Guides",
	LFG = "Gruppensuche",
	STREAMER_PLANNER = "Gruppenplaner",
	PET_STUFF = "Pet Stuff",
	MODULE_OVERVIEW = "Übersicht",

	-- Settings
	GLOBAL_SETTINGS = "Globale Addon-Einstellungen",
	GLOBAL_SETTINGS_DESC = "Hier kannst du Einstellungen für das gesamte Addon-Fenster und den Minimap-Button anpassen.",
	SETTINGS_SECTION_GENERAL = "Allgemein",
	SETTINGS_SECTION_GENERAL_DESC = "Sprache und Verhalten des Hauptfensters gehören zusammen und stehen deshalb ganz oben.",
	SETTINGS_SECTION_MINIMAP = "Minimap",
	SETTINGS_SECTION_MINIMAP_DESC = "Optionen für das Symbol an der Minimap bleiben in einem eigenen Block getrennt vom Rest der Oberfläche.",
	SETTINGS_SECTION_QUICK_HIDE = "Schnell ausblenden",
	SETTINGS_SECTION_QUICK_HIDE_DESC = "Hier legst du fest, welche Overlays in instanzierten Bereichen automatisch ausgeblendet werden und ob das nur im Kampf passieren soll.",
	SETTINGS_SECTION_RESET = "Zurücksetzen",
	SETTINGS_SECTION_RESET_DESC = "Seltene Notfall- oder Korrekturaktionen stehen separat, damit sie nicht zwischen normalen Optionen untergehen.",
	LOCK_WINDOW = "Hauptfenster fixieren (nicht verschiebbar)",
	MINIMAP_BUTTON_HIDE = "Minimap-Button ausblenden",
	QUICK_HIDE_OVERLAYS = "Overlays schnell ausblenden",
	QUICK_HIDE_CHECKLIST_OVERLAY = "Checklisten-Overlay ausblenden",
	QUICK_HIDE_WEEKLY_OVERLAY = "Weekly-Overlay ausblenden",
	QUICK_HIDE_STATS_OVERLAY = "Stats-Overlay ausblenden",
	QUICK_HIDE_OVERLAYS_IN_COMBAT = "Nur im Kampf ausblenden",
	HIDE_OVERLAYS_IN_COMBAT = "Overlays in Instanzen im Kampf ausblenden",
	RESET_POSITION = "Position zurücksetzen",

	-- Home/Startseite
	GOLDAUSWERTUNG_DESC = "Kompakte Übersicht für Einnahmen, Ausgaben, Reparaturen und Währungen. Gesamtverlauf über Verlauf.",
	GOLDAUSWERTUNG_CLEANUP = "Zeitraum löschen",
	WELCOME_TITLE = "Alles Wichtige auf einen Blick",
	WELCOME_SUBTITLE = "",
	GOLDAUSWERTUNG_RETENTION_HINT = "Reparaturen 30 Tage, Gold und Währungen 1 Jahr.",
	WELCOME_BODY = "Wähle links eine Kategorie und öffne direkt die gewünschten Module.",
	GOLDAUSWERTUNG_CLEANUP_TITLE = "Log-Zeitraum löschen",
	PROJECT_STATUS = "Projektstatus",
	GOLDAUSWERTUNG_CLEANUP_HINT = "Entfernt Einträge, die älter sind als der gewählte Zeitraum. Reparaturen bleiben zusätzlich automatisch auf 30 Tage begrenzt.",
	HOME_SUPPORT_TITLE = "Unterstütze mich",
	RELEASE_STATUS_FORMAT = "Status: %s",
	HOME_SUPPORT_BODY = "Dieses Projekt kostet viel Zeit.",
	GOLDAUSWERTUNG_HISTORY_TITLE = "Gesamtverlauf",
	HOME_SUPPORT_HINT = "Du kannst mich auf Twitch oder hier unterstützen.",
	RELEASE_CHANNEL_ALPHA = "Alpha",
	GOLDAUSWERTUNG_HISTORY_HINT = "Suche im Verlauf oder wechsle zwischen den Kategorien.",
	HOME_SUPPORT_LINK = "Spendenlink öffnen",
	HOME_SUPPORT_POPUP = "Spendenlink öffnen",
	RELEASE_CHANNEL_BETA = "Beta",
	GOLDAUSWERTUNG_HISTORY_TAB_INCOME = "Einnahmen",
	RELEASE_CHANNEL_RC = "Release Candidate",
	GOLDAUSWERTUNG_HISTORY_TAB_EXPENSE = "Ausgaben",
	RELEASE_CHANNEL_RELEASE = "Release",
	GOLDAUSWERTUNG_HISTORY_TAB_REPAIRS = "Reparaturen",
	STATUS_ALPHA = "Status: Alpha, aktiv im Ausbau",
	GOLDAUSWERTUNG_HISTORY_TAB_CURRENCY = "Währungen",
	STATUS_FOCUS = "Fokus: stabile Kernmodule, klare Bedienung und ein kompakter Zugriff auf häufig genutzte Funktionen.",
	GOLDAUSWERTUNG_HISTORY_SEARCH = "Suche",

	GOLDAUSWERTUNG_HISTORY_LOAD_MORE = "Mehr laden",
	PROGRESS_CARD_TITLE = "Fortschritt im Blick",
	GOLDAUSWERTUNG_HISTORY_NO_MATCHES = "Keine Treffer im aktiven Verlauf.",
	PROGRESS_CARD_BODY = "Levelzeit, Checkliste, Weekly Keys, Itemlevel Guide und Quest Check holen die Dinge nach vorne, die man sonst über mehrere Blizzard-Fenster verteilt suchen muss.",
	GOLDAUSWERTUNG_OVERVIEW_NO_MATCHES = "Keine Treffer für diese Suche.",
	PROGRESS_CARD_FOOTER = "Levelzeit - Checkliste - Weekly Keys - Itemlevel Guide - Quest Check",
	GOLDAUSWERTUNG_HISTORY_SHOWING = "%d Einträge sichtbar.",

	GOLDAUSWERTUNG_HISTORY_SHOWING_MORE = "%d Einträge sichtbar. Weitere Einträge können geladen werden.",
	COMFORT_CARD_TITLE = "Weniger Kleinkram",
	GOLDAUSWERTUNG_ENTRY = "Eintrag",
	COMFORT_CARD_BODY = "Komfort-Module decken typische Routineaufgaben ab, darunter Looten, Reparieren, Verkaufen und kleine UI-Erweiterungen für den Alltag.",
	GOLDAUSWERTUNG_MISC = "Sonstiges",
	COMFORT_CARD_FOOTER = "Automatisch Verkaufen - Automatisch Reparieren - Schneller Looten - Einfaches Item löschen - Max. Sichtweite",
	GOLDAUSWERTUNG_SALE = "Verkauf",

	GOLDAUSWERTUNG_ITEM = "Item",
	TWITCH_TITLE = "Twitch",
	GOLDAUSWERTUNG_ITEMS = "Items",
	TWITCH_BODY = "Wenn du sehen willst, wie das Addon weiter wächst, findest du Streams, Updates und den direkten Draht auf twitch.tv/beavismania.",
	GOLDAUSWERTUNG_REPAIR = "Reparatur",
	TWITCH_FOOTER = "Zum Twitch-Kanal",
	GOLDAUSWERTUNG_REPAIRS = "Reparaturen",
	TWITCH_POPUP = "Twitch-Kanal öffnen",
	GOLDAUSWERTUNG_SELF_PAID = "Selbst bezahlt",

	GOLDAUSWERTUNG_GUILD = "Gilde",
	DISCORD_TITLE = "Discord & Support",
	GOLDAUSWERTUNG_VENDOR = "Händler",
	DISCORD_BODY = "Feedback, Ideen und Support laufen über die Website und die Community-Kanäle. So lassen sich Rückmeldungen und offene Punkte gesammelt nachhalten.",
	GOLDAUSWERTUNG_VENDOR_SALE = "Händler",
	DISCORD_FOOTER = "Zur Beavismania-Website",
	GOLDAUSWERTUNG_MAIL = "Post",
	DISCORD_POPUP = "Beavismania öffnen",
	HOME_FEEDBACK_TITLE = "Feedback, Ideen & Bugs",
	HOME_FEEDBACK_BODY = "Feedback, Ideen und Bugs laufen über die Webseite.",
	HOME_FEEDBACK_FOOTER = "Zur Beavismania-Website",
	HOME_FEEDBACK_POPUP = "Beavismania öffnen",
	GOLDAUSWERTUNG_MAILBOX = "Postfach",
	WEBSITE_CARD_TITLE = "Beavismania.de",
	GOLDAUSWERTUNG_AUCTIONHOUSE = "Auktionshaus",
	WEBSITE_CARD_BODY = "Alle Infos rund um den Stream, Guides, Addons und alle Streams zum Nachschauen findest du gesammelt auf www.beavismania.de.",
	GOLDAUSWERTUNG_TRADE = "Handel",
	WEBSITE_CARD_FOOTER = "Zur Website www.beavismania.de",
	GOLDAUSWERTUNG_QUEST = "Quest",
	WEBSITE_CARD_POPUP = "Beavismania.de öffnen",
	GOLDAUSWERTUNG_QUEST_REWARD = "Questbelohnung",

	GOLDAUSWERTUNG_LOOT = "Beute",
	FOOTER_TEXT = "Die Oberfläche ist auf kurze Wege, klare Bereiche und ausreichend Platz für zusätzliche Module ausgelegt.",
	GOLDAUSWERTUNG_PICKED_UP = "Aufgesammelt",

	GOLDAUSWERTUNG_FLIGHTMASTER = "Flugmeister",
	-- Link-Popup
	GOLDAUSWERTUNG_TRAINER = "Trainer",
	LINK_OPEN = "Link öffnen",
	LINK_COPY_DESC = "World of Warcraft erlaubt Addons nicht, Webseiten direkt zu öffnen. Du kannst die Adresse hier markieren und kopieren:",
	LINK_COPY_HINT = "Tipp: Link markieren und mit Strg+C kopieren.",
	DEBUG_CONSOLE_TITLE = "Beavis Debug",
	DEBUG_CONSOLE_MODULE = "Modul: %s",
	DEBUG_CONSOLE_MODULE_NONE = "Modul: keines",
	DEBUG_CONSOLE_COPY_HINT = "Debug-Ausgaben werden hier gesammelt. Text markieren und mit Strg+C kopieren.",
	DEBUG_CONSOLE_EMPTY = "Noch keine Debug-Ausgabe gespeichert.",
	MINIMAP_TRACKER_SHOW = "Checklisten-Tracker anzeigen",
	MINIMAP_WEEKLY_KEYS_SHOW = "Weekly Keys anzeigen",
	MINIMAP_STATS_SHOW = "Stats anzeigen",
	MINIMAP_MARKER_BAR_SHOW = "Markerleiste anzeigen",
	MINIMAP_STREAMER_PLANNER_SHOW = "Gruppenplaner anzeigen",
	MINIMAP_EASY_LFG_SHOW = "SmartLFG anzeigen",
	MINIMAP_PORTAL_VIEWER_SHOW = "Saison Portale anzeigen",
	MINIMAP_QUICK_HIDE_SHOW = "Fenster autom. ausblenden",
	MINIMAP_QUICK_HIDE_SETTINGS = "Einstellungen",
	MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE = "Im Minimap-Schnellmenü anzeigen",
	MINIMAP_CONTEXT_MENU_ENTRY_VISIBLE_HINT = "Steuert, ob dieses Modul im Schnellmenü des Minimap-Buttons erscheint.",
	MINIMAP_CONTEXT_QUICK_VIEW = "Schnellansicht",
	MINIMAP_CONTEXT_TOGGLE_SECTION = "An/Aus",
	MINIMAP_LEFT_CLICK = "Linksklick: Fenster öffnen / schließen",
	MINIMAP_RIGHT_CLICK = "Rechtsklick: Schnellmenü",
	MINIMAP_SHIFT_CLICK = "Shift-Klick: UI neu laden",
	MINIMAP_CTRL_LEFT_CLICK = "Strg-Linksklick: Saison Portale",
	MINIMAP_CTRL_RIGHT_CLICK = "Strg-Rechtsklick: Minimap-HUD",
	MINIMAP_DRAG = "Drag: Position ändern",
	ACTIVE = "Aktiv",
	FONT = "Schriftart",
	DISPLAY = "Darstellung",
	IMPORTANT = "Wichtig",
	READY = "Bereit",
	NOT_FOUND = "Nicht gefunden",
	STATUS = "Status",
	ADDON_MESSAGE = "Beavis QoL: %s",
	CHONKY_LOADOUT_LABEL = "Loadout",
	CHONKY_LOADOUT_TOOLTIP = "Wählt ein Talent-Loadout für die aktive Spezialisierung.",
	CHONKY_LOADOUT_NONE = "Kein Loadout",
	CHONKY_LOADOUT_NO_LOADOUTS = "Keine Loadouts",
	CHONKY_LOADOUT_FALLBACK_NAME = "Loadout %d",
	CHONKY_LOADOUT_COMBAT_BLOCKED = "Talent-Loadouts können im Kampf nicht gewechselt werden.",
	CHONKY_LOADOUT_FAILED = "Loadout konnte nicht gewechselt werden: %s",
	CHONKY_LOADOUT_API_MISSING = "Talent-Loadout-API nicht verfügbar.",
	CHONKY_LOADOUT_MENU_MISSING = "Dropdown-Menü-API nicht verfügbar.",
	PORTAL_VIEWER_TITLE = "Saison Portale",
	PORTAL_VIEWER_DESC = "Schnelle Übersicht der erspielten Portale und direkte Nutzung.",
	PORTAL_VIEWER_SUBTITLE = "Midnight S1 Dungeonportale",
	PORTAL_VIEWER_HINT = "Zeigt dir für die aktuelle Mythic+-Rotation von Midnight Saison 1, welche Dungeonportale du schon hast und welche noch fehlen.",
	PORTAL_VIEWER_SECTION_AVAILABLE = "Vorhanden",
	PORTAL_VIEWER_SECTION_MISSING = "Fehlt",
	PORTAL_VIEWER_EMPTY_AVAILABLE = "Noch kein Saison-1-Portal freigeschaltet.",
	PORTAL_VIEWER_EMPTY_MISSING = "Alle Saison-1-Portale sind vorhanden.",
	PORTAL_VIEWER_UNLOCKED = "Freigeschaltet",
	PORTAL_VIEWER_LOCKED = "Nicht freigeschaltet",
	PORTAL_VIEWER_ACTION_USE = "Porten",
	PORTAL_VIEWER_ACTION_COOLDOWN = "CD %s",
	PORTAL_VIEWER_ACTION_MISSING = "Fehlt",
	PORTAL_VIEWER_CLICK_HINT = "Linksklick: Portal benutzen",
	PORTAL_VIEWER_COOLDOWN_REMAINING = "Abklingzeit: %s",
	PORTAL_VIEWER_ACHIEVEMENT_UNKNOWN = "Kein passender Portal-Erfolg gefunden",
	PORTAL_VIEWER_REQUIREMENT = "Freischaltung: Portal-Belohnung für diesen Dungeon",
	PORTAL_VIEWER_CLOSE_TOOLTIP = "Fenster ausblenden",
	PORTAL_VIEWER_SETTINGS_HINT = "Hier steuerst du Sichtbarkeit, Fensterstatus und den Schnellmenü-Eintrag von Saison Portale.",
	PORTAL_VIEWER_ENABLE_WINDOW = "Saison Portale aktivieren",
	PORTAL_VIEWER_ENABLE_WINDOW_HINT = "Schaltet das Fenster von Saison Portale insgesamt ein oder aus.",
	PORTAL_VIEWER_LOCK_WINDOW = "Fenster fixieren",
	PORTAL_VIEWER_LOCK_WINDOW_HINT = "Wenn aktiv, bleibt das Portal-Viewer-Fenster an seiner Position und kann nicht verschoben werden.",
	PORTAL_VIEWER_SHOW_MINIMAP_MENU = "Im Minimap-Schnellmenü anzeigen",
	PORTAL_VIEWER_SHOW_MINIMAP_MENU_HINT = "Steuert, ob Saison Portale im Schnellmenü des Minimap-Buttons erscheint.",
	PORTAL_VIEWER_DUNGEON_MAGISTERS_TERRACE = "Terrasse der Magister",
	PORTAL_VIEWER_DUNGEON_MAISARA_CAVERNS = "Maisarakavernen",
	PORTAL_VIEWER_DUNGEON_NEXUS_POINT_XENAS = "Nexuspunkt Xenas",
	PORTAL_VIEWER_DUNGEON_WINDRUNNER_SPIRE = "Windläuferturm",
	PORTAL_VIEWER_DUNGEON_ALGETHAR_ACADEMY = "Akademie von Algeth'ar",
	PORTAL_VIEWER_DUNGEON_PIT_OF_SARON = "Die Grube von Saron",
	PORTAL_VIEWER_DUNGEON_SEAT_OF_THE_TRIUMVIRATE = "Sitz des Triumvirats",
	PORTAL_VIEWER_DUNGEON_SKYREACH = "Himmelsnadel",

	MISC_TITLE = "Komfort",
	MISC_DESC = "Hier findest du Komfortfunktionen, die unabhängig vom Rest des Addons genutzt werden können.",
	REPUTATION_SEARCH = "Rufsuche",
	REPUTATION_SEARCH_PLACEHOLDER = "Ruf suchen",
	REPUTATION_SEARCH_HINT = "Fügt dem Blizzard-Ruf-Fenster ein Suchfeld hinzu, damit du Fraktionen direkt filtern kannst.",
	CURRENCY_SEARCH = "Währungssuche",
	CURRENCY_SEARCH_PLACEHOLDER = "Währung suchen",
	CURRENCY_SEARCH_HINT = "Fügt dem Blizzard-Währungsfenster ein Suchfeld hinzu, damit du Währungen direkt filtern kannst.",
	AUTOSELL_HINT = "Verkauft beim Öffnen eines Händlers automatisch alle grauen Gegenstände mit Händlerwert.",
	AUTOREPAIR_HINT = "Repariert beim Öffnen eines Händlers automatisch beschädigte Gegenstände.",
	AUCTION_HOUSE_DESC = "Automatisiert im Blizzard-Auktionshaus auf Wunsch einzelne Filter für Erweiterung und Seltenheit.",
	AUCTION_HOUSE_CURRENT_EXPANSION_FILTER = "Nur aktuelle Erweiterung automatisch aktivieren",
	AUCTION_HOUSE_CURRENT_EXPANSION_FILTER_HINT = "Setzt beim Öffnen des Blizzard-Auktionshauses automatisch den Filter \"Nur aktuelle Erweiterung\".",
	AUCTION_HOUSE_POOR_QUALITY_FILTER = "Schlecht automatisch deaktivieren",
	AUCTION_HOUSE_POOR_QUALITY_FILTER_HINT = "Deaktiviert im Blizzard-Auktionshaus bei Seltenheit automatisch den Filter \"Schlecht\".",
	AUCTION_HOUSE_COMMON_QUALITY_FILTER = "Gewöhnlich automatisch deaktivieren",
	AUCTION_HOUSE_COMMON_QUALITY_FILTER_HINT = "Deaktiviert im Blizzard-Auktionshaus bei Seltenheit automatisch den Filter \"Gewöhnlich\".",
	AUCTION_HOUSE_FAVORITE_GROUPS_TITLE = "Favoritengruppen",
	AUCTION_HOUSE_FAVORITE_GROUP_ALL = "Alle Favoriten",
	AUCTION_HOUSE_FAVORITE_GROUP_UNGROUPED = "Keine Kategorie",
	AUCTION_HOUSE_FAVORITE_GROUP_ADD_TOOLTIP = "Neue Favoritengruppe erstellen",
	AUCTION_HOUSE_FAVORITE_GROUP_ASSIGN_TOOLTIP = "Favoriten-Gruppe zuweisen",
	AUCTION_HOUSE_FAVORITE_GROUP_CURRENT_LABEL = "Aktuelle Gruppe: %s",
	AUCTION_HOUSE_FAVORITE_GROUP_CURRENT_NONE = "Aktuelle Gruppe: Keine",
	AUCTION_HOUSE_FAVORITE_GROUP_EDIT_BUTTON = "Bearbeiten",
	AUCTION_HOUSE_FAVORITE_GROUP_EDIT_TOOLTIP = "Gruppe bearbeiten",
	AUCTION_HOUSE_FAVORITE_GROUP_DELETE_TOOLTIP = "Gruppe \"%s\" löschen",
	AUCTION_HOUSE_FAVORITE_GROUP_CREATE_POPUP = "Name für die neue Favoritengruppe:",
	AUCTION_HOUSE_FAVORITE_GROUP_RENAME_POPUP = "Neuer Name für die Favoritengruppe:",
	AUCTION_HOUSE_FAVORITE_GROUP_CREATE_BUTTON = "Erstellen",
	AUCTION_HOUSE_FAVORITE_GROUP_CREATE_EMPTY = "Bitte gib einen Gruppennamen ein.",
	AUCTION_HOUSE_FAVORITE_GROUP_CREATE_DUPLICATE = "Diese Favoritengruppe gibt es bereits.",
	AUCTION_HOUSE_FAVORITE_GROUP_DELETE_CONFIRM = "Willst du die Gruppe \"%s\" wirklich löschen?",
	AUCTION_HOUSE_FAVORITE_GROUP_MENU_TITLE = "Zu Gruppe zuweisen",
	AUCTION_HOUSE_FAVORITE_GROUP_MENU_CREATE = "Neue Gruppe erstellen",
	AUTOREPAIR_GUILD = "Per Gilde vorrangig",
	AUTOREPAIR_GUILD_HINT = "Wenn möglich, wird zuerst Gildengold für die Reparatur verwendet.",
	EASY_DELETE_HINT = "Entfernt bei Items mit LÖSCHEN-Abfrage die Texteingabe und ersetzt sie durch eine einfache Bestätigung.",
	FAST_LOOT_HINT = "Lootet Beute direkt beim Öffnen und blendet das Lootfenster dabei aus.",
	CUTSCENE_SKIP = "Video's überspringen",
	CUTSCENE_SKIP_HINT = "Zeigt Cutscenes und Movies beim ersten Auslösen normal an. Sobald derselbe Event-Schlüssel bereits einmal gesehen wurde, wird er beim nächsten Start automatisch übersprungen.",
	FLIGHT_MASTER_TIMER = "Flugmeister-Timer",
	FLIGHT_MASTER_TIMER_HINT = "Zeigt während Flugmeister-Flügen mittig am Bildschirm einen Countdown bis zur Ankunft an und lernt fehlende Routenzeiten automatisch nach.",
	FLIGHT_MASTER_TIMER_UNKNOWN = "Ankunft unbekannt",
	FLIGHT_MASTER_TIMER_SOUND = "Ankunftssound aktiv",
	FLIGHT_MASTER_TIMER_SOUND_HINT = "Spielt bei der Ankunft einmal ein kurzes Signal ab. Die Auswahl nutzt Blizzard-Client-Sounds; es werden keine fremden Audiodateien mitgeliefert.",
	FLIGHT_MASTER_TIMER_SOUND_SELECT = "Sound:",
	FLIGHT_MASTER_TIMER_SOUND_TEST = "Test",
	FLIGHT_MASTER_TIMER_SOUND_PLAY_HINT = "Spielt den aktuell gewählten Sound einmal ab.",
	FLIGHT_MASTER_TIMER_SOUND_SQUIRE_HORN = "Knappenhorn",
	FLIGHT_MASTER_TIMER_SOUND_DWARF_HORN = "Zwergenhorn",
	FLIGHT_MASTER_TIMER_SOUND_SIMON_CHIME = "Simon-Klang",
	FLIGHT_MASTER_TIMER_SOUND_SCOURGE_HORN = "Geißelhorn",
	FLIGHT_MASTER_TIMER_SOUND_GRIMRAIL_TRAIN_HORN = "Grimmgleis-Zughorn",
	FLIGHT_MASTER_TIMER_LOCK_OVERLAY = "Timer fixieren",
	FLIGHT_MASTER_TIMER_LOCK_OVERLAY_HINT = "Wenn gelöst, kannst du das Timer-Overlay während eines Flugs direkt mit Linksklick verschieben. Standardmäßig bleibt es fixiert.",
	FLIGHT_MASTER_TIMER_POSITION_MODE = "Positionieren",
	FLIGHT_MASTER_TIMER_POSITION_MODE_STOP = "Positionieren beenden",
	FLIGHT_MASTER_TIMER_POSITION_MODE_HINT = "Blendet ein Beispiel-Overlay ein, damit du die Position auch ohne aktiven Flug verschieben und danach direkt wieder fixieren kannst.",
	FLIGHT_MASTER_TIMER_PREVIEW_DESTINATION = "Dornogal",
	FLIGHT_MASTER_TIMER_RESET_HINT = "Setzt das Timer-Overlay auf seine Standardposition unterhalb der Bildschirmmitte zurück.",
	TOOLTIP_ITEMLEVEL_HINT = "Zeigt im Mouseover-Tooltip das ausgerüstete Itemlevel anderer Spieler an. Funktioniert per Inspect nur in Reichweite.",
	TOOLTIP_ITEMLEVEL_LABEL = "Itemlevel",
	TOOLTIP_ITEMLEVEL_LOADING = "wird geprüft...",
	MACRO_FRAME_HINT = "Vergrößert das Blizzard-Makrofenster nach unten, damit mehr Makros gleichzeitig sichtbar sind.",
	TALENT_FRAME_SCALE_HINT = "Aktiviert die Skalierung für das Blizzard-Talentfenster. Den Wert kannst du direkt hier anpassen oder später über den kleinen Prozent-Button im Talentfenster.",
	TALENT_LOADOUT_REMINDER_HINT = "Zeigt bei jedem Bereitschaftscheck oben mittig dein aktuelles Talent-Loadout an. Schließt nach 10 Sekunden automatisch oder per kleinem X.",
	TALENT_LOADOUT_REMINDER_WARNING = "Achtung!",
	TALENT_LOADOUT_REMINDER_CURRENT = "Aktuelles Loadout:",
	TALENT_LOADOUT_REMINDER_LOOT = "Aktuelle Looteinstellung:",
	TALENT_LOADOUT_REMINDER_LOOT_CURRENT_SPEC_FORMAT = "Aktuelle Spezialisierung (%s)",
	TALENT_LOADOUT_REMINDER_LOOT_UNKNOWN = "Nicht verfügbar",
	TALENT_FRAME_SCALE_BUTTON_TOOLTIP = "Talentfenster skalieren",
	TALENT_FRAME_SCALE_BUTTON_TOOLTIP_HINT = "Öffnet ein separates Skalierungsfenster. Darin kannst du auch das Talentfenster fixieren oder zum Verschieben freigeben.",
	TALENT_FRAME_SCALE_WINDOW_LOCK_TOOLTIP = "Talentfenster fixieren",
	TALENT_FRAME_SCALE_WINDOW_UNLOCK_TOOLTIP = "Talentfenster verschiebbar machen",
	TALENT_FRAME_SCALE_WINDOW_LOCK_TOOLTIP_HINT = "Wenn gelöst, kannst du das Talentfenster direkt oben greifen und die Position wird gespeichert.",
	PREY_HUNT_PROGRESS_HINT = "Blendet bei einer aktiven Midnight-Beutejagd die aktuelle Stufe direkt am Blizzard-Beutejagd-Symbol ein.",
	PREY_HUNT_STAGE_FORMAT = "Phase %d/%d",
	PREY_HUNT_STAGE_READY = "Boss bereit",
	KEYSTONE_ACTIONS = "M+ Optionen",
	KEYSTONE_ACTIONS_HINT = "Ersetzt im Mythic+-Schlüsselsteinfenster den Aktivieren-Button durch Bereitschaftscheck, Timer und Start. Mit Auto startet nach deinem Bereitschaftscheck der Timer automatisch, sobald alle bereit sind, und danach wird Start gedrückt.",
	KEYSTONE_ACTIONS_GROUP_LOCK = "Knöpfe nur in Gruppe aktiv",
	KEYSTONE_ACTIONS_GROUP_LOCK_HINT = "Wenn aktiv, bleiben Bereitschaftscheck, Timer und Start außerhalb einer Gruppe gesperrt.",
	KEYSTONE_ACTIONS_SECONDS = "Timer-Sekunden:",
	KEYSTONE_ACTIONS_SECONDS_HINT = "Gilt für Timer und Auto. Zulässig sind 1 bis 30 Sekunden.",
	KEYSTONE_ACTIONS_AUTOTIMER = "Auto-Timer",
	KEYSTONE_ACTIONS_AUTO = "Auto",
	KEYSTONE_ACTIONS_READYCHECK = "Bereitschaftscheck",
	KEYSTONE_ACTIONS_START = "Start",
	KEYSTONE_ACTIONS_PULLTIMER = "Timer",
	KEYSTONE_ACTIONS_CANCEL = "Abbrechen",
	FISHING_HELPER_DESC = "Ein Ein-Tasten-Modul für entspanntes Angeln. Dieselbe Taste wirft die Angel aus und wird solange dein Bobber aktiv ist vorübergehend auf Blizzards Interaktion umgelegt, damit du ihn ohne exakten Mouseover mit derselben Taste einsammeln kannst.",
	FISHING_HELPER_USAGE_HINT = "Ablauf: Taste drücken zum Auswerfen, dann den Bobber im Blick behalten und dieselbe Taste erneut drücken. Während der Bobber im Wasser ist, bleibt deine Taste auf Interaktion gelegt statt erneut auszuwerfen.",
	FISHING_HELPER_ENABLE = "Angelhilfe aktivieren",
	FISHING_HELPER_SET_KEY = "Taste festlegen",
	FISHING_HELPER_CLEAR_KEY = "Taste löschen",
	FISHING_HELPER_CURRENT_KEY = "Aktuelle Taste",
	FISHING_HELPER_NO_KEY = "Keine Taste festgelegt",
	FISHING_HELPER_CAPTURE_HINT = "Drücke jetzt die gewünschte Taste. Escape bricht ab, Entfernen löscht die Belegung.",
	FISHING_HELPER_STATUS = "Status",
	FISHING_HELPER_STATUS_DISABLED = "Deaktiviert",
	FISHING_HELPER_STATUS_IDLE = "Bereit zum Auswerfen",
	FISHING_HELPER_STATUS_WAITING = "Pose im Wasser - warte auf Biss",
	FISHING_HELPER_STATUS_READY = "Biss erkannt - Interaktion liegt auf deiner Taste",
	FISHING_HELPER_STATUS_NO_SPELL = "Angeln nicht gefunden",
	FISHING_HELPER_STATUS_CAPTURE = "Warte auf Tasteneingabe",
	FISHING_HELPER_INTERACT_BINDING = "Blizzard-Interaktion",
	FISHING_HELPER_INTERACT_BINDING_NONE = "Keine Standardtaste belegt",
	FISHING_HELPER_INTERACT_HINT = "Sobald der Bobber aktiv ist, wird deine festgelegte Taste vorübergehend auf Blizzards Interaktion umgebogen. Zusätzlich setzt das Modul Soft-Interact währenddessen kurz auf den passenden Wert, damit richtungsbasiertes Einsammeln greift.",
	FISHING_HELPER_SOUND_ENABLE = "Angel-Sound hervorheben",
	FISHING_HELPER_SOUND_MIN = "Angel-Sound-Verstärkung",
	FISHING_HELPER_SOUND_HINT = "Solange deine Pose im Wasser ist, dämpft das Addon Musik, Ambiente und Haustier-Sounds, hebt Effekt- und Masterlautstärke relativ zu deinem aktuellen Mix an und stellt danach alles wieder her. 100% = unverändert, 200% = doppelt so laut bis zum WoW-Limit.",
	MOUSE_HELPER_DESC = "Bündelt Maus-Qualitätseinstellungen in einer Seite: sichtbarer Marker um den Cursor, ein bewegter Trail und die Blizzard-Mausvergrößerung.",
	MOUSE_HELPER_SETTINGS = "Allgemein",
	MOUSE_HELPER_ENABLE = "Maushilfen aktivieren",
	MOUSE_HELPER_CURSOR_SIZE = "Blizzard-Mausgröße",
	MOUSE_HELPER_CURSOR_SIZE_DEFAULT = "Standard",
	MOUSE_HELPER_CURSOR_SIZE_32 = "32x32",
	MOUSE_HELPER_CURSOR_SIZE_48 = "48x48",
	MOUSE_HELPER_CURSOR_SIZE_64 = "64x64",
	MOUSE_HELPER_CURSOR_SIZE_96 = "96x96",
	MOUSE_HELPER_CURSOR_SIZE_128 = "128x128",
	MOUSE_HELPER_BLIZZARD_CURSOR = "Blizzard-Maus vergrößern",
	MOUSE_HELPER_BLIZZARD_CURSOR_HINT = "Schaltet die eingebaute Blizzard-Funktion für einen größeren Mauszeiger direkt hier mit.",
	MOUSE_HELPER_BLIZZARD_CURSOR_UNSUPPORTED = "Auf diesem Client konnte keine unterstützte Blizzard-CVar für Mausgrößen erkannt werden.",
	MINIMAP_COLLECTOR_DESC = "Sammelt erkannte Addon-Minimapbuttons in einem eigenen, frei verschiebbaren Launcher mit transparentem Sammelfenster.",
	MINIMAP_COLLECTOR_ENABLE = "Minimap-Sammler aktivieren",
	MINIMAP_COLLECTOR_ENABLE_HINT = "Blendet den separaten Sammler-Launcher ein oder aus. Wenn deaktiviert, bleiben alle Buttons an ihrer normalen Minimap-Position.",
	MINIMAP_COLLECTOR_LAUNCHER_DESC = "Der Sammler hat einen eigenen Launcher auf dem Bildschirm. Linksklick öffnet das angedockte Fenster, Shift-Linksklick lädt die UI neu, Rechtsklick öffnet /beavis und Drag verschiebt den Launcher.",
	MINIMAP_COLLECTOR_SCALE = "Skalierung",
	MINIMAP_COLLECTOR_SCALE_HINT = "Passt die Größe von Launcher und Sammelfenster gemeinsam an.",
	MINIMAP_COLLECTOR_LAUNCHER_SCALE = "Button-Skalierung",
	MINIMAP_COLLECTOR_LAUNCHER_SCALE_HINT = "Passt nur die Größe des verschiebbaren Launcher-Buttons an.",
	MINIMAP_COLLECTOR_WINDOW_SCALE = "Fenster-Skalierung",
	MINIMAP_COLLECTOR_WINDOW_SCALE_HINT = "Passt nur die Größe des Sammelfensters an.",
	MINIMAP_COLLECTOR_BUTTONS_DESC = "Hier legst du fest, ob erkannte Minimapbuttons gesammelt, direkt an der Minimap gelassen oder komplett ausgeblendet werden.",
	MINIMAP_COLLECTOR_BUTTONS_HINT = "Addons per Drag & Drop zwischen Sammler, Minimap und Ausblenden verschieben.",
	MINIMAP_COLLECTOR_COLUMN_COLLECT = "Im Button-Sammler sammeln",
	MINIMAP_COLLECTOR_COLUMN_VISIBLE = "An der Minimap lassen",
	MINIMAP_COLLECTOR_COLUMN_HIDE = "Ausblenden",
	MINIMAP_COLLECTOR_COLUMN_EMPTY = "Keine Addons in dieser Spalte.",
	MINIMAP_COLLECTOR_SELECTED = "Ausgewählt: %s",
	MINIMAP_COLLECTOR_SELECTED_NONE = "Kein Addon ausgewählt.",
	MINIMAP_COLLECTOR_MOVE_LEFT = "Nach links verschieben",
	MINIMAP_COLLECTOR_MOVE_RIGHT = "Nach rechts verschieben",
	MINIMAP_COLLECTOR_EMPTY = "Noch keine sammelbaren Minimap-Buttons erkannt.",
	MINIMAP_COLLECTOR_RESET_POSITION = "Launcher-Position zurücksetzen",
	MINIMAP_COLLECTOR_LAUNCHER_CLICK = "Linksklick: Sammlerfenster öffnen / schließen",
	MINIMAP_COLLECTOR_LAUNCHER_RELOAD = "Shift-Linksklick: UI neu laden",
	MINIMAP_COLLECTOR_LAUNCHER_MENU = "Rechtsklick: /beavis öffnen",
	MINIMAP_COLLECTOR_LAUNCHER_DRAG = "Drag: Launcher verschieben",
	MINIMAP_COLLECTOR_CONFLICT_TEXT = "BeavisQoL hat erkannt, dass %s aktiv ist.\n\nWelches Addon soll die Minimap-Button-Verwaltung übernehmen?",
	MINIMAP_COLLECTOR_CONFLICT_USE_BEAVIS = "BeavisQoL verwenden",
	MINIMAP_COLLECTOR_CONFLICT_USE_MBB = "Minimap Button Button verwenden",
	MINIMAP_COLLECTOR_MODE_COLLECT = "Sammeln",
	MINIMAP_COLLECTOR_MODE_SHOW = "Minimap",
	MINIMAP_COLLECTOR_MODE_HIDE = "Ausblenden",
	MINIMAP_HUD_HINT = "Zieht die Live-Minimap groß und transparent in die Bildschirmmitte. Rahmen, Buttons und der Minimap-Sammler bleiben dabei oben rechts.",
	MINIMAP_HUD_TOGGLE = "HUD umschalten",
	MINIMAP_HUD_TOGGLE_HINT = "Öffnet oder schließt die große HUD-Ansicht in der Bildschirmmitte.",
	MINIMAP_HUD_OPEN = "HUD öffnen",
	MINIMAP_HUD_CLOSE = "HUD schließen",
	MINIMAP_HUD_SIZE = "HUD-Größe",
    MINIMAP_HUD_MAP_ALPHA = "Karten-Transparenz",
	MINIMAP_HUD_COORDS = "Koordinaten anzeigen",
	MINIMAP_HUD_MOUSE = "Minimap-Maus aktivieren",
	MINIMAP_HUD_MOUSE_HINT = "Wenn aktiv, kannst du im HUD über Knoten hovern. Klicks in die Spielwelt innerhalb des HUDs werden dann aber blockiert.",
	MINIMAP_HUD_TOPRIGHT_MINIMAP = "Rahmen und Buttons bleiben oben rechts",
	MINIMAP_HUD_TOPRIGHT_MINIMAP_HINT = "In der Mitte erscheint nur die vergrößerte Scan-Karte. Der normale Minimap-Rahmen und der Minimap-Sammler bleiben oben rechts an ihrem Platz.",
	MINIMAP_HUD_MOUSE_ON = "Maus: An",
	MINIMAP_HUD_MOUSE_OFF = "Maus: Aus",
	MINIMAP_HUD_COMBAT_BLOCKED = "Das Minimap-HUD kann im Kampf nicht umgeschaltet werden.",
	MOUSE_HELPER_CIRCLE_TITLE = "Cursor-Kreis",
	MOUSE_HELPER_CIRCLE_ENABLE = "Kreis anzeigen",
	MOUSE_HELPER_CIRCLE_COMBAT_ONLY = "Kreis nur im Kampf anzeigen",
	MOUSE_HELPER_CIRCLE_CLASS_COLOR = "Klassenfarbe automatisch verwenden",
	MOUSE_HELPER_CAST_RING_ENABLE = "Cast-Ring beim Zaubern anzeigen",
	MOUSE_HELPER_CAST_RING_COLOR = "Cast-Ring Farbe",
	MOUSE_HELPER_CIRCLE_SIZE = "Größe",
	MOUSE_HELPER_CIRCLE_THICKNESS = "Rahmenstärke",
	MOUSE_HELPER_CIRCLE_STYLE = "Optikstil",
	MOUSE_HELPER_CIRCLE_STYLE_STANDARD = "Standard",
	MOUSE_HELPER_CIRCLE_STYLE_3D = "3D-Look",
	MOUSE_HELPER_CIRCLE_SHAPE = "Form",
	MOUSE_HELPER_SHAPE_RING = "Ring",
	MOUSE_HELPER_SHAPE_SQUARE = "Quadrat",
	MOUSE_HELPER_SHAPE_DIAMOND = "Raute",
	MOUSE_HELPER_COLOR_PICK = "Farbe wählen",
	MOUSE_HELPER_CIRCLE_HINT = "Der Kreis folgt deiner Maus in Echtzeit und bleibt mittig um den Cursor.",
	MOUSE_HELPER_TRAIL_TITLE = "Maus-Trail",
	MOUSE_HELPER_TRAIL_ENABLE = "Trail anzeigen",
	MOUSE_HELPER_TRAIL_LENGTH = "Länge",
	MOUSE_HELPER_TRAIL_SIZE = "Punktgröße",
	MOUSE_HELPER_TRAIL_STYLE = "Trail-Stil",
	MOUSE_HELPER_TRAIL_CLASS_COLOR = "Klassenfarbe automatisch verwenden",
	MOUSE_HELPER_TRAIL_STYLE_LIGHTNING = "Blitz",
	MOUSE_HELPER_TRAIL_STYLE_HOLY = "Heiliges Licht",
	MOUSE_HELPER_TRAIL_STYLE_ARC = "Bögen (Ice)",
	MOUSE_HELPER_TRAIL_STYLE_CLEAN = "Sauber",
	MOUSE_HELPER_TRAIL_HINT = "Der Trail hinterlässt beim Bewegen kurze Punkte, die nach hinten sanft ausblenden.",
	BOSS_GUIDES_DESC = "Zeigt in unterstützten Dungeons/Raids oben links einen Boss-Guides-Button. Darüber öffnest du ein Fenster mit Boss-Tabs und den hinterlegten Taktiken.",
	BOSS_GUIDES_SETTINGS = "Einstellungen",
	BOSS_GUIDES_SHOW_OVERLAY = "Overlay-Button anzeigen",
	BOSS_GUIDES_OVERLAY_MODE = "Anzeigemodus",
	BOSS_GUIDES_MODE_ALWAYS = "Immer anzeigen",
	BOSS_GUIDES_MODE_INSTANCE = "Nur in Dungeon/Raid",
	BOSS_GUIDES_LOCK_OVERLAY = "Overlay-Position fixieren",
	BOSS_GUIDES_SCALE = "Skalierung",
	BOSS_GUIDES_FONT_SIZE = "Schriftgröße",
	BOSS_GUIDES_RESET_POSITION = "Positionen zurücksetzen",
	BOSS_GUIDES_BUTTON = "Boss Guides",
	BOSS_GUIDES_OVERVIEW_TITLE = "Guide-Übersicht",
	BOSS_GUIDES_OVERVIEW_HINT = "Wähle eine Kategorie oder öffne einen Guide direkt aus der Übersicht.",
	BOSS_GUIDES_EMPTY_CATEGORY = "Für diese Kategorie ist noch kein Guide hinterlegt.",
	BOSS_GUIDES_OPEN_GUIDE = "Guide öffnen",
	BOSS_GUIDES_BOSS_COUNT = "%d Bosse",
	BOSS_GUIDES_GUIDE_COUNT = "%d Guides",
	BOSS_GUIDES_STATUS_ALWAYS = "Immer sichtbar",
	BOSS_GUIDES_STATUS_INSTANCE = "Nur in Instanz",
	BOSS_GUIDES_STATUS_LOCKED = "Fixiert",
	BOSS_GUIDES_STATUS_UNLOCKED = "Verschiebbar",
	BOSS_GUIDES_BOSSES = "Bosse",
	BOSS_GUIDES_BOSS_FALLBACK_LABEL = "Boss %d",
	BOSS_GUIDES_INSTANCE = "Instanz",
	BOSS_GUIDES_NO_GUIDE = "Für diese Instanz ist aktuell kein Guide hinterlegt.",
	BOSS_GUIDES_CURRENT_INSTANCE = "Aktuelle Instanz",
	BOSS_GUIDES_NONE = "Keine",
	BOSS_GUIDES_CAT_RAID = "Raid",
	BOSS_GUIDES_CAT_DUNGEON = "Dungeon",
	BOSS_GUIDES_HOME_CATEGORY_RAIDS = "Raids",
	BOSS_GUIDES_HOME_CATEGORY_DUNGEONS = "Dungeons",
	BOSS_GUIDES_HOME_EMPTY = "Noch keine Bossguides verfügbar.",
	BOSS_GUIDES_SELECT_INSTANCE = "Instanz wählen...",
	BOSS_GUIDES_NO_INSTANCES = "Noch keine Einträge",
	BOSS_GUIDES_SECTION_GENERAL = "Allgemein",
	BOSS_GUIDES_LABEL_MYTHIC = "Mythisch",
	BOSS_GUIDES_LEGEND_TANK = "Tank",
	BOSS_GUIDES_LEGEND_DD = "DD",
	BOSS_GUIDES_LEGEND_HEAL = "Heiler",
	BOSS_GUIDES_LEGEND_HC = "HC",
	BOSS_GUIDES_LEGEND_M = "M",
	BOSS_GUIDES_INSTANCE_VOIDSPIRE_TITLE = "Leerenspitze",
	BOSS_GUIDES_INSTANCE_VOIDSPIRE_TOKENS = { "leerenspitze", "leeren", "voidspire", "void spire" },
	BOSS_GUIDES_BOSS_IMPERATOR_AVERZIAN_NAME = "Imperator Averzian",
	BOSS_GUIDES_BOSS_IMPERATOR_AVERZIAN_BODY = [=[
Allgemein: Ziel ist, niemals eine Dreier-Linie aus beanspruchten Feldern zu erzeugen, damit Marsch der Unendlichen nicht ausgelöst wird.
• Schattenvorstoß bringt drei Leerenformer. Die Wellen werden über Umbralkollaps kontrolliert, indem der Split-Soak gezielt auf Leerenformer und gefährdete Felder gelegt wird.
• Boss und Adds niemals auf beanspruchten Feldern parken, sonst verstärkt Ruhm des Imperators den Druck unnötig.
• Leerenformer haben immer Priorität und Bollwerk errichten muss sofort gekickt werden.
• Zorn der Vergessenheit und Leerenfall dürfen niemanden unnötig treffen. Sauber laufen ist hier wichtiger als gieriger Schaden.
{TANK} Umbralkollaps aktiv führen. Der Raid stackt bei dir und du setzt den Einschlag so, dass der Leerenformer getroffen und das Feld gerettet wird.
• Schwärzende Wunden stapeln. Bei hohen Stapeln sauber wechseln und den freien Tank die Adds übernehmen lassen.
• Boss immer von beanspruchten Feldern wegziehen und Adds nicht unnötig mit Ruhm des Imperators buffen.
{DD} Fokusziel sind die Abyssischen Leerenformer. Sie müssen fallen, bevor Leerenruptur weitere Felder verliert.
• Bollwerk errichten ist absolute Kick-Pflicht.
• Leerenschlund vor seiner Portal-Heilung finishen. Knirschende Leere im Blick behalten und bei Bedarf Defensives oder Offheal benutzen.
{HEAL} Dauerhafter Grunddruck kommt durch Dunkle Verwerfung. Heil-CDs so staffeln, dass Umbralkollaps-Spitzen mit abgedeckt sind.
• Leerenfall zwingt zu Bewegung. Repositionieren früh mit einplanen und AoE-Heilfenster vorbereiten.
• Ziele von Dunkles Sperrfeuer stabilisieren und bei Bedarf extern absichern.
{HC} Leerenformer bekommen zusätzlichen Druck durch Aufziehende Dunkelheit und müssen noch härter priorisiert oder gestoppt werden.
• Der Lauf von Leerenschlund Richtung beanspruchtes Feld ist auf HC relevant und Humpelnd markiert die Bewegung zusätzlich.
• Adds separiert tanken, damit keine unnötigen Synergien oder Boss-Buffs entstehen.
{M} Ein zusätzlicher Abyssischer Malus erhöht den Gesamtdruck deutlich.
• Kosmischer Panzer erschwert das Lösen über Umbralkollaps. Leerenmarkiert muss gezielt entfernt werden, damit Lauernde Dunkelheit entsteht und Kosmischer Panzer in der Nähe verbraucht wird.
• Schwarzes Miasma und Folgeeffekte wie Geschwächt sauber managen, sonst kippt der Heil- und Debuffdruck schnell.
]=],
	BOSS_GUIDES_BOSS_VORASIUS_NAME = "Vorasius",
	BOSS_GUIDES_BOSS_VORASIUS_BODY = [=[
Allgemein: Loop: Zerschmettert -> Adds und Wände -> Strahl -> Reset.
• In der Mitte und vorne spielen, nicht hinten herum, sonst blockieren Wände die Laufwege.
• Urzeitliches Brüllen ist Pull, Knockback und hoher Raid-Schaden zugleich. Heil-CDs planen und so stehen, dass niemand herunterfällt.
• Urzeitliche Macht stapelt über den ganzen Kampf und lässt den Schaden immer weiter ansteigen.
{TANK} Immer mit einem Tank in Nahkampfreichweite bleiben, sonst wirkt Überwältigender Puls.
• Jeden Schattenklauenhieb sicher soaken. Wenn kein Treffer genommen wird, kassiert der ganze Raid.
• Die ersten ein bis zwei Soaks von Zerschmettert stapeln stark. Danach sauber wechseln und Defensivs ziehen.
• Nachbeben ist der Ring direkt danach. Sauber herauslaufen oder durchgehen.
{DD} Blasenkriecher fixieren Spieler. Adds zur gewünschten Wand kiten und dort töten, damit Pustelbersten die Wand beschädigt oder öffnet.
• Nie im Explosionsradius von Pustelbersten stehen und Add-Kills staffeln, weil der Raid-Schaden sonst überlappt.
• Beim Leerenatem die Startseite sofort erkennen und direkt auf die gegenüberliegende Kante laufen.
• Während Parasitenausstoß und Dunkle Energie immer mit zusätzlichen Bodenflächen rechnen. Swirls meiden und nicht gierig stehen bleiben.
{HEAL} Urzeitliches Brüllen zusammen mit den späteren Stapeln von Urzeitliche Macht ist das große Rotationsfenster für Raid-CDs.
• Kriecherspritzer ist ein Magieeffekt mit Slow und soll schnell dispellt werden, damit Fixate-Kiting sauber bleibt.
• Add-Kills durch Pustelbersten verursachen spürbare Heilspitzen. Kills ansagen lassen und nicht alles gleichzeitig detonieren.
{HC} Kristallwände brauchen zwei Explosions-Kills durch Pustelbersten pro Wand.
{M} Kristallwände brauchen drei Explosions-Kills durch Pustelbersten und die Adds müssen noch genauer verteilt werden.
• Unter explodierten Adds entstehen Pfützen aus Dunkler Schleim. Kill-Spots vorher planen, sonst wird der Raum unspielbar.
]=],
	BOSS_GUIDES_BOSS_FALLEN_KING_SALHADAAR_NAME = "Gefallener König Salhadaar",
	BOSS_GUIDES_BOSS_FALLEN_KING_SALHADAAR_BODY = [=[
Allgemein: Kugeln haben absolute Priorität. Leerenkonvergenz schickt zwei Kugeln zum Boss und jeder Bosskontakt gibt Leereninfusion.
• Kugeln niemals berühren, sonst gibt es Leerenaussetzung.
• Kugeln versetzt töten, besonders auf HC, weil jede Kugel Dunkle Strahlung auslöst.
• Gebrochene Projektion beschwört Abbilder. Deren Schattenfraktur sofort unterbrechen oder kontrollieren, sonst kommen massiver Raid-Schaden und weitere Flächen.
• Quälendes Extrakt immer außen parken. Die Flächen bleiben dauerhaft liegen und kommen auch nach Phasen wieder.
• Despotischer Befehl aus dem Raid tragen und am Rand auslaufen oder dispellen. Danach Drückende Finsternis sofort hochheilen und die neue Fläche einplanen.
• Bei 100 Energie startet Entropische Auflösung als Burn- und Heilfenster. Vorher den Boss an den nächsten Rand ziehen und währenddessen Umbrastrahlen dodgen.
• Windende Obskurität ist permanenter Raid-Schaden mit langem DoT und muss über den ganzen Kampf mitgeheilt werden.
{TANK} Boss konstant am Rand führen, damit Quälendes Extrakt den Raum nicht verbaut. Vor Entropische Auflösung schon den nächsten Randpunkt vorbereiten.
• Destabilisierende Stöße bei hohen Stapeln sauber tauschen.
• Zertrümmerndes Zwielicht immer weg vom Raid spielen und die Pfeile von der Gruppe wegdrehen. Nach dem Einschlag sofort Zwielichtstacheln ausweichen.
• In Entropische Auflösung mit dem Boss mitlaufen und Umbrastrahlen niemals durch den Raid schneiden.
{DD} Priorität ist Kugeln vor Abbildern vor Boss.
• Leerenkonvergenz sofort zerstören und auf HC den Kill-Timer wegen Dunkle Strahlung ansagen.
• Gebrochene Projektion und deren Abbilder sofort kontrollieren. Schattenfraktur ist Kick-Pflicht, solange Kugeln noch leben.
• In Entropische Auflösung alle CDs nutzen. Das ist das klare Burn-Fenster, während ihr weiter Umbrastrahlen dodged.
{HEAL} Dunkle Strahlung nach Kugel-Toden auf HC gezielt gegenheilen und nicht doppelt überlappen lassen.
• Windende Obskurität ist die konstante DoT-Last des Kampfes und verlangt frühe Throughput-Planung.
• Entropische Auflösung ist 20 Sekunden dauerhafte Raid-AoE plus Bewegung. Dafür eine klare Raid-CD-Rotation planen.
• Despotischer Befehl am Rand auflösen und Drückende Finsternis zielpriorisiert wegheilen, damit niemand kippt.
• Quälendes Extrakt bleibt permanent liegen. Dispel- und Ablaufpositionen müssen deshalb eng geführt werden.
{HC} Kugel-Kills geben Dunkle Strahlung mit stapelbarem Raid-Schaden. Mindestens einen Debuff auslaufen lassen, bevor die nächste Kugel stirbt.
• Zertrümmerndes Zwielicht markiert auf HC zusätzliche Spieler und erzeugt mehr Spike-Richtungen.
{M} In den eingesehenen Kurzguides gibt es keine zusätzlich benannten Mythisch-Mechaniken gegenüber HC.
• Mythisch ist hier vor allem ein Zahlen-, Timing- und Raum-Disziplin-Check über Kugeln, Projektionen-Kicks, Flächenmanagement und Entropische Auflösung.
]=],
	BOSS_GUIDES_BOSS_VAELGOR_EZZORAK_NAME = "Vaelgor & Ezzorak",
	BOSS_GUIDES_BOSS_VAELGOR_EZZORAK_BODY = [=[
Allgemein: Zwei Ziele ohne geteilte Lebenspunkte. Schaden splitten und beide möglichst gleichzeitig töten, sonst kommt Zwielichtfuror.
• Der Kampf steht und fällt mit Positionierung: Bosse immer mindestens 15 Meter auseinanderhalten wegen Zwielichtbund und die HP-Differenz möglichst bei maximal 10 Prozent halten.
• Niemals hinter die Drachen gehen. Schwanzpeitscher und Durchbohren bestrafen das sofort mit Knockback, Stun oder DoT.
• Kern-Loop des Kampfes: Leerenheulen, danach Nullstrahl oder Nullzone und kurz darauf Düsternis.
• Bei 100 Energie startet die Zwischenphase Mitternachtsflammen. Sofort in die Strahlende Barriere gehen und das Add priorisieren.
{TANK} Beide Bosse nahe ihrer Spawn-Seite halten, aber immer mit mindestens 15 Metern Abstand wegen Zwielichtbund. Niemals so drehen, dass Melees hinten stehen.
• Nach wenigen Stapeln von Vaelschwinge und Rakzahn sauber tauschen, bevor Autos und Absorbs eskalieren.
• Nullstrahl aktiv für den Raid spielen und nie durch die Raid-Mitte schneiden lassen.
• Nullzone mit Ansage brechen. Jeder Snap verursacht Nullbruch, der Tank bricht meist zuletzt.
• Düsternis bewusst an freie Wandkanten und weg von alten Düsternisfeldern legen.
{DD} HP-Differenz klein halten. Im Zweifel Single-Target bremsen, statt einen Boss zu weit herunterzuspielen.
• Nach Leerenheulen Kreise nicht stacken und danach Void-Adds sofort fokussieren. Leerenblitz darf nicht frei durchgehen.
• Düsternis nur mit den zugewiesenen Soakern spielen. Jeder Kontakt gibt Düsternisberührt und darf nicht zufällig passieren.
• In der Zwischenphase die Manifestation sofort töten, bevor Ungebundener Schatten eskaliert.
• Auf Mythisch immer Kosmose mitdenken. Klone spielen Kernfähigkeiten nach und machen Platz sowie Bewegung deutlich enger.
{HEAL} Entsetzlicher Atem sofort dispellen, damit Fear und CC nicht außer Kontrolle geraten. Das Ziel muss raus und der Kegel weg vom Raid.
• Größte Raid-CD-Fenster sind Serien von Nullzone-Snaps. Jeder Snap macht Nullbruch und auf HC ist besonders der letzte Snap gefährlich.
• Düsternisberührt stapelt realen Soak-Schaden. Auf HC kommt danach Geschwächt, deshalb ist eine feste Soak-Rotation Pflicht.
• In der Zwischenphase in der Strahlenden Barriere stacken und Spieler mit Schattenmal an den Rand schicken.
• Mitternachtsmanifestation ist ein stapelbarer DoT auf Zufallszielen und wird beim Eintritt in die Strahlende Barriere entfernt.
{HC} Düsternis braucht pro Orb feste Soak-Teams. Geschwächt blockt den nächsten Soak über lange Zeit.
• In Nullzone verursacht der letzte Snap einen deutlich größeren Raid-Burst durch Nullzonenimplosion.
• Das Zwischenphasen-Add wirkt Schattenmal. Betroffene strikt an den Rand schicken, sonst cleaven sie den Raid.
{M} Düsternis braucht bis zu sieben Kontakte für die volle Reduktion. Soaker verursachen zusätzlich Nahbereichsschaden, deshalb vorher sauber positionieren und nicht spontan hineinlaufen.
• Nullzone bekommt zusätzlich Nullstreu. Schon der erste Snap kann Hagel oder Einschläge auslösen, daher Spread und Bewegung strikt nach Plan.
• Die Zwischenphase wird durch zusätzliche Overlaps und Kosmose-Klone deutlich enger. Strahlende Barriere sauber halten und Schattenmal diszipliniert rausspielen.
]=],

	BOSS_GUIDES_BOSS_LIGHTBLINDED_VANGUARD_NAME = "Lichtblinde Vorhut",
	BOSS_GUIDES_BOSS_LIGHTBLINDED_VANGUARD_BODY = [=[
Allgemein: Council mit drei HP-Balken. Lebenspunkte eng zusammenhalten, sonst rampen die Überlebenden wie ein Enrage.
• Bei 100 Energie startet eine Aura-Phase mit Aura der Hingabe, Aura des Zorns oder Aura des Friedens. Die anderen Bosse müssen sofort aus dem Kreis und am Rand rotiert werden.
• Nach Ultimates bleiben große Bodenflächen liegen. Tanks ziehen deshalb immer im Uhrzeigersinn weiter, während der Raid in der Mitte bleibt.
• Todesurteil verlangt getrennte Kreise mit festen Helfern, pro Spieler nur ein Soak. Danach direkt die rotierenden Hämmer von Göttlicher Hammer dodgen.
• Bei Schild des Rächers spreaden und den DoT sauber entzaubern.
• Geheiligter Schild macht Blendendes Licht kurz unkickbar. Schild erst brechen, dann kicken oder alternativ wegdrehen.
• Lichtdurchdrungen wird nach jeder Aura härter. Heiler-CDs früh staffeln.
{TANK} Bosse am Rand halten und bei jeder Aura die aktiven Bosse sofort aus dem Kreis ziehen, Raid bleibt in der Mitte.
• Richturteil verlangt den sofortigen Taunt-Swap, damit Letztes Urteil oder Schild der Rechtschaffenen nicht denselben Tank treffen.
• Tyrs Zorn trifft die nächsten Spieler. Tanks vermeiden unnötige Nähe, wenn Rotation oder Absorb bereits hoch ist.
• Defensives für harte Treffer und Überlappungen aufheben, besonders wenn Soak, Raid-Druck und Aura zusammenkommen.
{DD} Schaden gleichmäßig auf alle drei Bosse verteilen und keinen Boss solo herunterprügeln.
• Geheiligter Schild hat Mechanik-Priorität. Schild sofort brechen, dann Blendendes Licht kicken.
• Bei Schild des Rächers spreaden und nach dem Dispel nicht direkt wieder nachstacken.
• Todesurteil nur mit den zugewiesenen Soakern spielen, danach raus und Hämmer dodgen.
• Göttlicher Glockenschlag mit den Schild-Salven immer vollständig auslaufen.
{HEAL} Lichtdurchdrungen plus der Aura-Zyklus ist eine planbare Ramp für eure CD-Rotation.
• Tyrs Zorn erzeugt Heilabsorbs auf den nächststehenden Zielen. Spieler dafür rotieren lassen und Doppel- oder Dreifachstacks vermeiden.
• Schild des Rächers schnell dispellen und die Ziele vor der Explosion stabilisieren.
• Todesurteil erzeugt Peaks plus Nachbewegung durch die Hämmer. Spotheal und Bewegungsheals bereithalten.
{HC} Der Raumcheck wird deutlich härter: sehr große dauerhaft liegende Bodenflächen nach Ultimates machen die Rotation am Rand zur Pflicht.
{M} Eifernder Geist verstärkt abwechselnd einen Boss, erhöht Schaden oder ermächtigt eine Fähigkeit und sorgt für gefährliche Overlaps.
• Schild des Rächers zielt auf Mythisch durch den Hotfix nur noch auf vier Spieler, bleibt aber weiter relevant.
• Tyrs Zorn hat auf Mythisch per Hotfix etwas weniger Heilabsorption, bleibt aber ein klares CD- und Rotationsfenster.
• Heiliger Tribut ist per Hotfix etwas entschärft, bleibt aber ein gefährliches Schadensfenster.
]=],

	BOSS_GUIDES_BOSS_CROWN_OF_COSMOS_NAME = "Krone des Kosmos",
	BOSS_GUIDES_BOSS_CROWN_OF_COSMOS_BODY = [=[
Allgemein: Phase 1 mit drei Wächtern spielen, Silberschlagpfeil bewusst nutzen, die Immunität herunternehmen und Bodeneffekte eng stapeln.
• In den Zwischenphasen im Slice bleiben, gegen den Sog aus Stellaremission anlaufen, Silberschlagbeschuss für Resets timen und Singularitätsausbruch sowie Umkreisende Materie meiden.
• In Phase 2 Boss und Klon getrennt halten, Adds freischalten, Interrupts priorisieren und rotieren, wenn der Platz knapp wird.
• In Phase 3 stacken, Bindungen nacheinander lösen, danach sofort Tankwechsel und Plattformwechsel sauber ohne Panik spielen.
{TANK} In Phase 1 hält ein Tank Vorelus und Leerentröpfchen, der andere den Fokus-Wächter. Immer Nahkampfpräsenz an den Wächtern sichern, sonst eskaliert Hallende Dunkelheit.
• In Phase 2 Boss und Klon auseinanderziehen, damit Ermächtigende Dunkelheit nicht bufft. Nach Debuff-Stapeln tauschen und Crossing über Risse nur kurz und gezielt.
• In Phase 3 Bindungsbruch als Tank-Swap-Trigger behandeln, weil nach dem Collapse physischer Burst folgt.
{DD} Als Ranged Bodeneffekte so baiten, dass Laufwege und Segmente frei bleiben.
• Silberschlagpfeil und Mal des Waldläuferhauptmanns so ausrichten, dass Adds und Wächter getroffen werden, nicht der Raid.
• In Phase 2 Adds sofort markieren und freischalten, schnell töten und Ruf der Leere oder andere Void-Casts kicken, bevor die Energie eskaliert.
• In Phase 3 alles in den Boss drücken, aber Mechaniken vor DPS stellen. Ein falscher Bindungsbruch kostet den Pull.
{HEAL} Nullkorona vorrangig wegheilen. Dispel nur, wenn sonst jemand stirbt, weil der Rest-Absorb weiterspringt.
• In den Zwischenphasen Ramp-Schaden und Sog mit CDs planen. Silberschlagbeschuss-Resets sind gewollt, kommen aber als Spikes rein.
• In Phase 2 und 3 DoTs und Plattformwechsel-Spitzen antizipieren und die Heal-Range zum Off-Tank in Phase 1 sichern.
{HC} In Phase 2 kommen mehr Leerenausstoß-Kugeln, dadurch mehr Bodeneffekte und schneller Platzdruck.
• Pfeil-Treffer geben einen Debuff, der den nächsten Pfeilschaden stark erhöht. Niemals doppelt getroffen werden und Pfeil-Resets strikt koordinieren.
• Leerenpirscherstich hält deutlich länger, also Heiler-CDs und Defensives einplanen oder nach Plan über Pfeile entfernen.
• In Phase 1 wird die Wächter-Aura relevanter. Melee- und Tank-Zuordnung deshalb strikter spielen.
{M} Griff des Nichts verlangsamt deutlich stärker. Früh ausrichten und früh laufen, spätes Drehen wird gefährlich.
• Silberschlagbeschuss in den Zwischenphasen bestraft härter und kann den erlittenen Pfeilschaden massiv erhöhen. Trefferplanung extrem konservativ halten.
• Stellaremission verstärkt die erzwungene Bewegung spürbar. Sog und Drift brauchen mehr Mobility und Speed-CDs.
• Leerenausstoß trifft auch auf Mythisch zusätzliche Spieler. Das Platzproblem wird dadurch noch schneller zum Soft-Enrage.
]=],
	BOSS_GUIDES_INSTANCE_DREAMRIFT_TITLE = "Traumriss",
	BOSS_GUIDES_INSTANCE_DREAMRIFT_TOKENS = { "traumriss", "traum riss", "dreamrift", "dream rift" },

	BOSS_GUIDES_BOSS_CHIMAERUS_NAME = "Chimaerus, der Ungeträumte Gott",
	BOSS_GUIDES_BOSS_CHIMAERUS_BODY = [=[
Allgemein: Pre-Pull den Raid in zwei feste Teams teilen, pro Team ein Tank, etwa halbe Heiler und halbe DPS. Diese Teams rotieren die gesamte Riss-Arbeit.
• Alnstaubaufruhr am aktiven Tank soaken, Team A und B strikt abwechselnd. Nach dem Knock-up gibt Alnsicht den Zugang zum Riss.
• Im Riss haben Adds Alnschleier. Erst den Schild brechen, damit die Adds in die Realität kommen und dort sofort sterben können.
• In der Realität haben Manifestationen und andere Essenz-Adds absolute Priorität. Wenn sie durchkommen oder verschlungen werden, entstehen Verschlungene Essenz-Stapel und der Kampf kippt sehr schnell.
• Alnstaubessenz-Pfützen nicht betreten und den Raum aktiv freihalten.
• In der Flugphase Verderbte Vernichtung und Flugbahnen meiden, neue Adds sofort töten und vor Gefräßiger Sturzflug alles sauber haben.
{TANK} In der Realität den Boss an den Rand ziehen und wegen Reißendes Schlitzen konsequent vom Raid wegdrehen. Nicht mittig stehen bleiben.
• Im Riss Adds kontrollieren und zuerst das große Add stabil halten, während kleine Adds mit Cleave mitfallen.
• Bei Verschlingen auf 100 Energie während der Kanalisierung alle übrigen Adds finishen, damit keine Verschlungene Essenz-Stapel entstehen.
{DD} Manifestationen und Essenz-Adds sind immer Prio eins. Boss-DPS ist zweitrangig, solange Adds leben.
• Fürchterlicher Schrei immer unterbrechen. Essenzblitz nach Möglichkeit ebenfalls kicken.
• Niemals in Alnstaubessenz stehen. In der Intermission Linien sauber dodgen und danach sofort wieder auf Adds gehen.
{HEAL} Heil-Rotation für Ätzenden Auswurf, Risskrankheit und die gesamte Add-Phase vorbereiten.
• Zehrendes Miasma gezielt dispellen, nicht im Stack. Explosion und Knockback vorher einplanen.
{HC} Rissvulnerabilität bedeutet, dass niemand zweimal hintereinander Alnstaubaufruhr soaken darf. Teams strikt abwechseln.
• Zehrendes Miasma ist auf HC das zentrale Werkzeug, um Alnstaubessenz aus dem Raum zu entfernen. Die Fläche muss nur überdeckt werden, man muss nicht in der Pfütze stehen.
• In der Intermission räumt Gefräßiger Sturzflug Pfützen nicht zuverlässig weg, daher den Raum primär über Miasma-Dispels managen.
{M} Dissonanz bestraft Nähe zur anderen Realm-Gruppe. Zwei feste Teams und zwei feste Seiten spielen, nicht in oder nahe die andere Gruppe laufen.
• Risswahn markiert zwei Spieler im Riss. Dafür feste Swap-Spots und feste Tauschpartner definieren, damit die Reiche sauber gewechselt werden.
• Vor dem Phasenübergang wird zusätzlich Alnstaubaufruhr erzwungen. Adds deshalb vorher sicher vorbereiten und dann kontrolliert in den Übergang gehen.
• In der Flugphase erzeugt Verderbte Vernichtung auch im Riss Manifestationen. Das Rift-Team muss daher selbst in der Intermission weiterarbeiten.
]=],
	BOSS_GUIDES_INSTANCE_MARCH_ON_QUEL_DANAS_TITLE = "Marsch auf Quel'Danas",
	BOSS_GUIDES_INSTANCE_MARCH_ON_QUEL_DANAS_TOKENS = { "marsch auf quel danas", "marsch auf queldanas", "marsch auf quel'danas", "march on quel danas", "march on queldanas", "march on quel'danas", "quel danas", "quel'danas" },
	BOSS_GUIDES_BOSS_BELOREN_CHILD_OF_ALAR_NAME = "Belo'ren, Kind von Al'ar",
	BOSS_GUIDES_BOSS_BELOREN_CHILD_OF_ALAR_BODY = [=[
Allgemein: Farben: Leerenlichtkonvergenz -> Lichtfeder oder Leerenfeder. Nur die eigene Farbe spielt die jeweilige Mechanik.
Soaks: Lichtsturzschlag oder Leerensturzschlag. Das Ziel geht zum Marker, dieselbe Farbe soaked mit.
Adds: Funken von Belo'ren schnell kontrollieren. Lichteruption und Leereneruption dürfen nur von der passenden Farbe gekickt werden.
Orbs: Strahlende Echos. Die richtige Farbe öffnet Lücken, die falsche Farbe ist gefährlich.
Tank-Combo: Edikt des Wächters führt in Lichtedikt oder Leerenedikt.
Heilercheck: Ewige Verbrennungen ist ein Absorb und muss schnell weggeheilt werden.
Übergang: Todessturz führt in die Ei-Phase. Wiedergeburt verhindern und Aschener Segen im Blick behalten.
{TANK} Tanks spielen immer gegensätzlich mit Lichtfeder und Leerenfeder. Edikt des Wächters mit dem passenden Kegel fangen und den Knockback nicht von der Plattform schicken. Boss nur für Soaks leicht bewegen, wenn die Fläche sauber ist. In der Ei-Phase weiter Kegel fangen und Defensives für spätere Stapel von Aschener Segen planen.
{DD} Beim Soak-Kreis steht das Ziel am Marker und nur dieselbe Farbe geht rein. Funken von Belo'ren haben Priorität, danach das Ei sofort finishen, damit Wiedergeburt nicht durchgeht. Lichteruption und Leereneruption nur mit passender Farbe unterbrechen. Strahlende Echos mit der eigenen Farbe benutzen, um der anderen Gruppe Lücken zu öffnen. CDs und BL/Hero für die Ei-Phase halten.
{HEAL} Brennendes Herz ist konstanter AoE und wird in der Ei-Phase deutlich härter. Ewige Verbrennungen schnell wegheilen und die Ziele stabilisieren. Nach Todessturz den Raid sofort auffangen und Bewegung absichern. Mit stapelndem Aschener Segen Heil-CDs für spätere Ei-Phasen einteilen.
{HC} Erfüllte Federkiele müssen abgefangen werden. Die richtige Farbe stellt sich in die Linie.
{M} Strahlende Echos, die den Boss erreichen, verursachen massiven Raid-Schaden und müssen deutlich konsequenter entfernt werden. Erfüllte Federkiele verursachen nach dem Abfangen zusätzlichen Nahbereichsschaden, daher nicht direkt auf dem Ziel stacken.
]=],
	BOSS_GUIDES_BOSS_MIDNIGHT_FALLS_NAME = "Anbruch der Mitternacht",
	BOSS_GUIDES_BOSS_MIDNIGHT_FALLS_BODY = [=[
Allgemein: 2-teiliger Kampf: Phase 1 mit Kristallen und Runen, dann Unterbrechung, dann Phase 2 mit Reaktor und Überladung.
• Zwielichtkristalle bis zum Dämmerkristall hochheilen, damit Licht- und Schutzzone aktiv bleiben.
• Mitternachtskristalle sofort fokussieren, sonst droht Kosmische Fraktur und hoher Raid-Schaden.
• Klagelied des Todes sauber über Runen und Noten lösen. Zuordnungen vorher ansagen, kein Chaos im Raid.
• Totale Finsternis verlangt eine feste Unterbrechungskette plus Defensives. Wenn etwas durchgeht, wird es sofort ein Heil-CD-Fenster.
• Große Raid-Peaks kommen durch Zerschmetterter Himmel zusammen mit Verdunkelt oder Lichtentzug. Heil-CDs vorher planen.
{TANK} Boss stabil halten und Frontal- oder Cleave-Effekte vom Raid wegdrehen. Bewegung klein halten, damit Runen und Soaks sauber bleiben.
• Lanze des Himmels ist der große Tank-Hit und soll aktiv mit Def-CDs genommen werden.
• Aufgespießt sauber managen und den Tankwechsel vorher absprechen.
• Im Übergang und in Phase 2 so stehen, dass der Raid Überlastungsladung kontrolliert spielen kann.
{DD} Mitternachtskristalle haben absolute Priorität, damit Kosmische Fraktur nicht durchgeht.
• Klagelied des Todes und Dunkelrune sauber spielen: kurz raus, Mechanik lösen, dann wieder rein.
• Tränen von L'ura aktiv abfangen. Wenn Kugeln durchgehen, kommt Naarutrauer.
• In Phase 2 diszipliniert stacken oder spreaden, je nach Ansage für Überlastungsladung.
{HEAL} Zwielichtkristalle auf 100 Prozent hochheilen, damit der Dämmerkristall sicher bleibt.
• Verdunkelt oder Lichtentzug zusammen mit Zerschmetterter Himmel sind die zentralen Burst-Fenster für eure CD-Rotation.
• Tränen von L'ura verursachen Soak-Schaden und brauchen Spotheal oder Bewegungsheilung.
• In Phase 2 Überlastungsladung mit Heil-CDs und Externals abfedern, besonders wenn der Stack unsauber ist.
{HC} Hotfix: Verdunkelt, Lichtentzug und Donnernder Brunnen skalieren je nach Gruppengröße bis etwa 20 Prozent niedriger auf Normal und HC.
• Zerschmetterter Himmel ist auf HC für große Gruppen etwas milder, für kleine Gruppen aber deutlich härter.
• Konsequenz: Große Raids haben mehr Luft, kleine Raidgrößen müssen Defensives und Heil-CDs enger timen.
{M} Derzeit sind keine verlässlich dokumentierten zusätzlichen Mythisch-Mechaniken aus frei zugänglichen deutschen Quellen bestätigt.
• Rechnet vor allem mit höheren Zahlen und strengeren Checks in allen Kernmechaniken.
]=],
	BOSS_GUIDES_INSTANCE_WINDRUNNER_SPIRE_TITLE = "Windläuferturm",
	BOSS_GUIDES_INSTANCE_MAGISTERS_TERRACE_TITLE = "Terrasse der Magister",
	BOSS_GUIDES_INSTANCE_ALGETHAR_ACADEMY_TITLE = "Akademie von Algeth'ar",
	BOSS_GUIDES_INSTANCE_PIT_OF_SARON_TITLE = "Grube von Saron",
	BOSS_GUIDES_INSTANCE_MAISARA_CAVERNS_TITLE = "Maisarakavernen",
	BOSS_GUIDES_BOSS_VORDAZA_NAME = "Vordaza",
	BOSS_GUIDES_BOSS_VORDAZA_BODY = [=[
Allgemein: Welkendes Miasma tickt permanent und verlangt einen langen Heal-Plan statt Panik-CDs.
• Seelendieb macht burstigen Tankschaden plus Heilungsabsorb; dafür kurze dichte Heilfenster vorbereiten.
• Zerrütten seitlich verlassen und den Pushback nicht gegenheilen.
• Phantome entreißen kontrollieren, damit Unstable Phantoms nicht unkontrolliert in Spieler einschlagen.
• Letzte Verfolgung sauber kiten, damit Phantom-Explosionen nicht in der Gruppe detonieren.
• Wer Heimsuchende Überreste trägt, meidet die nächsten Explosionen noch strikter, weil der Folgeschaden stark skaliert.
• Seelenfäule-Pfützen nach Phantom-Toden aus der Kampfzone ziehen und nicht stapeln.
• Schwelender Schrecken entzerren, damit mehrere Explosionen nicht gleichzeitig hochgehen.
• Sobald Nekrotische Konvergenz startet, Fokus auf das saubere Beenden der Phase legen und parallel Geronnener Tod dodgen.
• Während Todesschleier sind Unterbrechungen wertlos; Ressourcen auf Überleben und Phasenkontrolle statt auf verpuffte Kicks legen.
• Geronnener Tod ist ein früher Dodge-Check: lieber früh laufen als spät sidesteppen.
• Verhüllte Präsenz-Phantome lösen sich nicht über Burst, sondern über Zeit und sauberes Setup, weil sie fast keinen Schaden nehmen.
{TANK} Seelendieb mit Defensiv- und aktiver Mitigation abfangen, weil der Heilungsabsorb die Heilerreaktion einschränkt.
• Zerrütten nie durch die Gruppe drehen.
{DD} Phantome entreißen kontrolliert parken, mit CC, Slow oder Knockback je nach Setup, damit Explosionen geplant passieren.
• In Nekrotische Konvergenz Priorität auf das saubere Ausspielen der Phase und gleichzeitiges Dodgen von Geronnener Tod legen.
{HEAL} Welkendes Miasma konstant gegenheilen, damit Phantom-Spikes nicht sofort tödlich werden.
• Wenn Schwelender Schrecken mehrfach überlappt, Heal-CDs staffeln statt alles auf einmal zu drücken.
• Den Heilungsabsorb von Seelendieb aktiv callen und dichten HPS durchdrücken, statt nur auf HoTs zu vertrauen.
{HC} Auf höheren Schwierigkeiten verlieren Verhüllte Präsenz-Phantome anscheinend keine HP mehr von selbst; Add-Management und Damage-Plan werden dadurch wichtiger.
]=],
	BOSS_GUIDES_BOSS_RAKTUL_VESSEL_OF_SOULS_NAME = "Rak'tul, Gefäß der Seelen",
	BOSS_GUIDES_BOSS_RAKTUL_VESSEL_OF_SOULS_BODY = [=[
Allgemein: Todesverschlungenes Gefäß ist der konstante Fight-Timer; Heil-CDs auf wiederkehrende Pulsfenster staffeln.
• Flüchtige Essenz nicht stacken lassen und Einschläge wie Swirlies behandeln.
• Geistbrecher ist ein schwerer Hit auf das Primärziel plus Knock-up; der Tank braucht dafür feste Defensives.
• Spektraler Verfall-Pfützen meiden, weil sie ticken und erlittenen Schaden erhöhen.
• Markierte Spieler platzieren Seelen brechen so, dass Totems cleavebar sind, aber nicht mitten in der Gruppe liegen.
• Totems der Seelenbindung schnell töten, bevor sie weiter kontrollieren oder Schaden drücken.
• Seelenreißendes Brüllen startet die Restless-Masses-Sequenz als Sprint- und Survivalteil; so schnell wie möglich zurücklaufen, bevor Verdorrende Seele hochstapelt.
• Verdorrende Seele stackt alle vier Sekunden und tickt jede Sekunde; Movement-Fehler werden dadurch exponentiell teurer.
• Schreie der Gefallenen auf dem Rückweg meiden, weil Root plus Schaden Tempo und Heilfenster zerstört.
• Ewiges Leid in der Seelenphase zuverlässig kicken oder kontrollieren, um den Aura-Druck zu stoppen und Spektrale Rückstände zu bekommen.
• Spektrale Rückstände nach erfolgreichem Unterbrechen aktiv nutzen, um mit Movespeed und Output die Phase zu stabilisieren.
• Nach Seelenausstoß ist der Boss lange betäubt; dieses Fenster für Totem- und Add-Cleanup plus Boss-Schaden nutzen.
• Vor Seelenreißendes Brüllen möglichst alle Totems entfernen, weil Zerschmettertes Totem sonst pro Totem zusätzlichen Gruppenschaden skaliert.
{TANK} Geistbrecher ist der größte Tank-Checkpoint. Defensiv planen und so stehen, dass Knock-up oder Knockback nicht in Pfützen oder Orbs führen.
• Spektraler Verfall-Pfützen bewusst mit der Gruppenbewegung ablegen, damit Melees nicht dauerhaft verdrängt werden.
{DD} Totems der Seelenbindung priorisieren, damit die Gruppe sauber in die nächste Roar- oder Bridge-Sequenz geht.
• Für Ewiges Leid eine feste Kick-Rotation legen, damit Spektrale Rückstände verlässlich kommt.
• In Seelenreißendes Brüllen nicht blind Adds tunneln; erst sicheren Rückweg herstellen, dann wieder Bossdruck.
{HEAL} Todesverschlungenes Gefäß bestimmt den AoE-Plan des Kampfes; CDs auf den Pulsrhythmus legen, nicht auf Zufallsschaden.
• In der Bridge-Sequenz bei Verdorrende Seele Überleben und Tempo priorisieren, inklusive Movespeed-Buffs und Externals.
{HC} Zusätzliche HC-spezifische Änderungen sind in den verfügbaren Quellen derzeit nicht verlässlich bestätigt.
]=],
	BOSS_GUIDES_INSTANCE_SKYREACH_TITLE = "Himmelsnadel",
	BOSS_GUIDES_INSTANCE_SEAT_OF_THE_TRIUMVIRATE_TITLE = "Sitz des Triumvirats",
	BOSS_GUIDES_INSTANCE_NEXUS_POINT_XENAS_TITLE = "Nexuspunkt Xenas",
	BOSS_GUIDES_BOSS_MAISARA_CAVERNS_OVERVIEW_NAME = "Überblick",
	BOSS_GUIDES_BOSS_MAISARA_CAVERNS_OVERVIEW_BODY = [=[
Allgemein: Die Maisarakavernen sind ein 5-Spieler-Dungeon in Zul'Aman mit einem Duo-Encounter, einer Seelenritualistin und einem Finalboss mit Gauntlet- beziehungsweise Seelenphase.
• Kernthemen sind sauberes Movement, kontrollierte Adds sowie gezieltes Dispellen und Unterbrechen.
• Haltet die Spielzone in allen drei Kämpfen so sauber wie möglich, weil fast jede Phase über zugemüllten Boden oder ungeplante Add-Overlaps kippt.
]=],
	BOSS_GUIDES_BOSS_MUROJIN_NEKRAXX_NAME = "Muro'jin & Nekraxx",
	BOSS_GUIDES_BOSS_MUROJIN_NEKRAXX_BODY = [=[
Allgemein: Schaden immer auf beide Bosse verteilen, weil Tier wiederbeleben und Zorn des Wildtiers sonst die Endphase eskalieren.
• Speerfeuer ist die anvisierte Frontale: Das Ziel steht stabil und dreht den Kegel weg, alle anderen verlassen ihn konsequent.
• Als Gruppe eng zusammen rotieren, weil Eiskältefalle unter Spielern entsteht und sonst Wege blockiert.
• Wenn Eisige Lache aktiv ist, die Eisfläche meiden.
• Infizierte Flügelspitzen ist der Hauptdruck des Kampfes. Defensiv- und Heal-CDs nach DoT-Stacks timen.
• Nach Faulem Federsturm sofort aus Flächen und Swirlies laufen, damit kein Dodge-Teppich entsteht.
• Wer von Aasfressersturzflug markiert ist, stellt sich so, dass die Charge nicht durch die Gruppe geht.
• Bei Koordinierter Angriff steht niemand in der Charge-Linie, damit Knock-up-Ziele keine Extra-Treffer kassieren.
• Flankenspeer so spielen, dass Knockbacks niemanden in Fallen drücken.
• Offene Wunde ist planbarer Tankdruck und wird zusammen mit Speer- oder Knockback-Fenstern defensiv abgefangen.
• Stich der Blutfratzen ist vor allem ein Movement-Problem durch stapelnde Verlangsamung.
• Wenn Muro'jin allein steht, wird Tier wiederbeleben zum kurzen Finish-Fenster.
• Wenn Nekraxx allein steht, skaliert Zorn des Wildtiers stapelnd; Finish priorisieren statt safe zu spielen.
{TANK} Flankenspeer aktiv defensiv nehmen und den Knockback mit Mobilität abfangen, damit du sofort wieder Positionskontrolle hast.
• Offene Wunde mit Mitigation und externen CDs vorplanen.
• So stehen, dass dich kein Rückstoß in eine Eiskältefalle drückt.
{DD} Schaden immer splitten oder cleaven, damit kein Boss alleine übrig bleibt.
• Wenn du Ziel von Aasfressersturzflug bist, kann ein Eiskältefalle-Intercept Nekraxx stoppen; Timing gruppenintern callen.
• Wenn du Ziel von Speerfeuer bist, den Kegel stabil vom Raid weg parken.
{HEAL} Infizierte Flügelspitzen-Dispels rotieren, statt alles gleichzeitig zu lösen, damit der Healdruck geglättet wird.
• Wer eine Eiskältefalle auslöst, ist kurz aus dem Spiel; dafür Spot-Heals und Externals bereithalten, bis die Gruppe wieder stabil ist.
{HC} Zusätzlich zu Eiskältefalle kann Eisige Lache als rutschige Frostfläche entstehen und verschärft das Movement.
]=],
	BOSS_GUIDES_BOSS_OBERSTER_KERNBAUER_KASRETH_NAME = "Oberster Kernbauer Kasreth",
	BOSS_GUIDES_BOSS_OBERSTER_KERNBAUER_KASRETH_BODY = [=[
Allgemein: Arkanes Schocken immer unterbrechen und Leylinienmatrix niemals kreuzen. Spieler mit Ladungsrückstoß stellen sich an eine Kreuzung von mindestens zwei Leylinien, damit die Strahlen verschwinden. Fluxkollaps und Arkanfleck konsequent räumen. Bei Kernfunkendetonation aus dem Einschlag raus und danach Funkenbrand sofort wegheilen.
• Der Kampf wird deutlich leichter, wenn freie Wege zwischen den Leylinien stehen bleiben und der Kreuzungs-Spot nicht zugemüllt wird.
{TANK} Stelle den Boss so, dass die Gruppe freie Laufwege zwischen den Leylinien behält und Ladungsrückstoß sauber auf einer vorbereiteten Kreuzung gespielt werden kann.
{DD} Bei Kernfunkendetonation sofort raus und danach Schaden drücken, während Funkenbrand abgearbeitet wird. Unterbrechungen auf Arkanes Schocken haben Priorität.
{HEAL} Kernfunkendetonation plus Funkenbrand ist das klare Schadensfenster des Kampfes. CD, Externals und Spotheal dafür einplanen.
{HC} In der Quelle sind keine explizit neuen HC-Fähigkeiten genannt; zusätzliche Effekte sind nur allgemein als höhere Modi markiert.
]=],
	BOSS_GUIDES_BOSS_KERNWAECHTERIN_NYSARRA_NAME = "Kernwächterin Nysarra",
	BOSS_GUIDES_BOSS_KERNWAECHTERIN_NYSARRA_BODY = [=[
Allgemein: Bei Verdunkelnder Schritt sofort aus dem 14-Meter-Umkreis raus. Nullvorhut startet die Add-Phase; Adds sofort priorisieren, Neutralisieren kicken und Dämmerschrecken ausweichen. Umbralpeitsche endet mit Leerenschnitt und ist die zentrale Tank-Combo. Lichtgezeichnete Flamme ist euer Burstfenster im Lichtkegel, bringt aber konstanten Heiligschaden.
{TANK} Plane Defensives für Umbralpeitsche und vor allem den letzten Treffer Leerenschnitt. Friss danach keine unnötigen Zusatzhits und nutze bei Bedarf Kiten oder Externals.
{DD} Nullvorhut ist höchste Priorität und Neutralisieren muss immer gestoppt werden. Nutzt Lichtgezeichnete Flamme bewusst als Schadensfenster.
{HEAL} Im Lichtkegel von Lichtgezeichnete Flamme kommt konstanter Gruppenschaden herein. Hier Gruppenheilung durchdrücken und danach die Gruppe schnell wieder stabilisieren.
{HC} Ab höheren Modi kommen laut Quelle zusätzliche Adds oder Strafmechaniken hinzu; das Grundgerüst mit Add-Priorität, Kicks und sauberem Lichtfenster bleibt aber gleich.
]=],
	BOSS_GUIDES_BOSS_LOTHRAXION_NAME = "Lothraxion",
	BOSS_GUIDES_BOSS_LOTHRAXION_BODY = [=[
Allgemein: Sengende Verwundung und Strahlende Narbe kontrollieren den Boden; den Boss sofort aus Narben ziehen. Bei Strahlende Zerstreuung verteilt stehen, weil Abbilder an Spielern erscheinen und mit 8 Metern AoE explodieren. Gespiegeltes Verwunden niemals berühren, sonst folgen Knockback, Stapel-DoT und neue Narbe. Bei 100 Energie startet Göttliche List: den echten Boss am Abbild ohne Hörner erkennen und sofort unterbrechen.
{TANK} Bewege Lothraxion dauerhaft aus Strahlender Narbe heraus und halte eine saubere Kampfzone frei, damit der Raum nicht früh kippt.
{DD} Bei Göttliche List sofort target-swappen und den Kick auf das richtige Ziel sichern. Nach Strahlende Zerstreuung nicht in Pfeil- oder Sprungrichtungen stehen bleiben.
{HEAL} Größte Heilspitzen kommen durch Strahlende Zerstreuung und Fehler bei Gespiegeltes Verwunden. Halte dafür schnelle Gruppenstabilisierung bereit.
{HC} In höheren Modi wird ein verpasster Unterbruch auf Göttliche List zusätzlich mit Kernbelastung bestraft.
]=],
	BOSS_GUIDES_BOSS_ARKANOTRONWAECHTER_NAME = "Arkanotronwächter",
	BOSS_GUIDES_BOSS_ARKANOTRONWAECHTER_BODY = [=[
Allgemein: Während Aufladeprotokoll zieht der Boss Energiekugeln an. Diese Kugeln abfangen, damit keine Arkane Ermächtigung auf dem Boss landet. Jeder Soak gibt Instabile Energie, also Treffer rotieren. Arkane Überreste kommen in höheren Modi als zusätzliche Bodenflächen dazu und dürfen den Raum nicht zumüllen.
{TANK} Halte den Boss stabil, damit Soaker die Energiekugel sicher auf der Linie abfangen können und nichts unkontrolliert in den Boss läuft.
{DD} Nutzt Aufladeprotokoll als Burstfenster, aber nicht auf Kosten sauberer Kugel-Soaks. Wenn der Boss Arkane Ermächtigung bekommt, war der Fehler meist schon vorher.
{HEAL} Instabile Energie stapelt und tickt hart. Soaker brauchen schnelle Spotheals und oft auch einen External, wenn mehrere Kugeln kurz nacheinander gefangen werden.
{HC} Zusätzliche Flächen und höhere Komplexität sind in der Quelle erst ab höheren Modi markiert, vor allem über Arkane Überreste.
]=],
	BOSS_GUIDES_BOSS_SERANEL_SONNENPEITSCHE_NAME = "Seranel Sonnenpeitsche",
	BOSS_GUIDES_BOSS_SERANEL_SONNENPEITSCHE_BODY = [=[
Allgemein: Unterdrückungsbereich ist Silence- und Pacify-Zone und zugleich Lösung für Runenmal. Betroffene entfernen den Debuff im Unterdrückungsbereich, lösen dabei aber Rückkopplung aus und müssen die Einschläge dodgen. Für Welle der Stille rechtzeitig in den Unterdrückungsbereich stellen, sonst sind 8 Sekunden lang keine Wirkungen möglich. Beschleunigender Zauberschutz sofort dispellen oder purgen.
{TANK} Wenn Beschleunigender Zauberschutz durchkommt, defensiv spielen und bei Bedarf kurz kiten, bis der Buff entfernt ist.
{DD} Rückkopplung sauber ausweichen und Beschleunigender Zauberschutz sofort entfernen. Betroffene mit Runenmal brauchen klare Wege in die Zone.
{HEAL} Wenn Runenmal im Unterdrückungsbereich gereinigt wird, erzeugt Rückkopplung oft kurz Chaos. Erst stabilisieren, dann die nächste Mechanik vorbereiten.
{HC} Ab höheren Modi kommt Nullreaktion als zusätzlicher Schaden und Slow beim Entfernen von Runenmal dazu.
]=],
	BOSS_GUIDES_BOSS_GEMELLUS_NAME = "Gemellus",
	BOSS_GUIDES_BOSS_GEMELLUS_BODY = [=[
Allgemein: Verdreifachung teilt den Kampf zu Pull und bei etwa 50 Prozent in Klone mit geteilten Lebenspunkten. Astraler Griff zwingt euch zum Gegenlaufen; wer stehen bleibt, frisst Kosmische Strahlung. Kosmischer Stich hinterlässt Leerenabsonderung und muss sauber aus dem Spielraum herausgelegt werden. In höheren Modi kommt Neurale Verbindung dazu: Pfeil lesen und die Verbindung rechtzeitig brechen.
{TANK} Stelle die Klone so, dass Astraler Griff die Gruppe nicht durch Pfützen aus Leerenabsonderung zieht und freie Ausweichwege offen bleiben.
{DD} Bei Astraler Griff sofort gegenlaufen und bei Bedarf defensiv spielen. Die Arena kippt hier eher durch schlechte Bewegung als durch fehlenden Bossschaden.
{HEAL} Heil-CDs für Astraler Griff und mögliche Treffer von Kosmische Strahlung vorbereiten. DoTs und Pfützenfehler eskalieren sehr schnell.
{HC} Mehrmechaniken wie Neurale Verbindung sind in der Quelle erst ab höheren Modi markiert.
]=],
	BOSS_GUIDES_BOSS_DEGENTRIUS_NAME = "Degentrius",
	BOSS_GUIDES_BOSS_DEGENTRIUS_BODY = [=[
Allgemein: Leerenströme dürfen nie berührt werden und zwingen zu permanenter Raumkontrolle. Instabile Leerenessenz schlägt in mehreren Zonen ein; jede Zone braucht Spieler im Einschlag, sonst folgt Leerenzerstörung. Verschlingende Entropie erzeugt beim Dispel oder Auslaufen Entropiekugeln, deshalb Debuffs gestaffelt auflösen. Wuchtiges Fragment und Umbralsplitter sind die zentrale Tank-Combo und gehören aus der Gruppe heraus.
{TANK} Trage Wuchtiges Fragment immer von der Gruppe weg und plane Defensives für Umbralsplitter ein. Die Nahgruppe darf nie im 8-Meter-Bereich stehen.
{DD} Bei Instabile Leerenessenz jede Zone zuverlässig besetzen. Wenn ein Einschlag verpasst wird, endet das meist direkt in Leerenzerstörung.
{HEAL} Für Verschlingende Entropie einen klaren Dispelplan spielen, zum Beispiel einen Debuff sofort und einen verzögert, damit die Entropiekugeln nicht gleichzeitig eskalieren.
{HC} Die Quelle markiert zusätzliche Spitzen eher allgemein als höhere Modi; Kernprinzipien bleiben Soak-Disziplin, kontrollierte Dispels und stabiles Orb-Management.
]=],
	BOSS_GUIDES_BOSS_DAEMMERGLUT_NAME = "Dämmerglut",
	BOSS_GUIDES_BOSS_DAEMMERGLUT_BODY = [=[
Allgemein: Flammender Aufwind immer nach außen droppen, damit Fläche und Wirbel die Arena nicht schließen. Flammender Wirbelsturm sauber ausweichen. Brennende Bö ist die Energie-Phase mit anhaltendem Gruppenschaden und Knockback. Sengender Schnabel ist der zentrale Tankbuster.
{TANK} Sengender Schnabel defensiv planen, weil der Treffer physischen Schaden plus Feuer-DoT kombiniert.
{DD} Flammender Aufwind wirklich konsequent am Rand ablegen. Ein schlechter Drop macht den Rest des Kampfes unnötig eng.
{HEAL} Brennende Bö ist das klare Heilfenster. Gruppen-CDs und Spotheal auf Aufwind-Ziele hier bündeln.
{HC} Ab höheren Modi kommt zusätzlich Feueratem während Brennende Bö dazu.
]=],
	BOSS_GUIDES_BOSS_HERUNTERGEKOMMENES_DUO_NAME = "Heruntergekommenes Duo",
	BOSS_GUIDES_BOSS_HERUNTERGEKOMMENES_DUO_BODY = [=[
Allgemein: Zerrissenes Band macht den Kampf zu einem reinen Health-Check. Stirbt ein Ziel deutlich früher, wird der Überlebende massiv stärker. Entkräftendes Kreischen ist die gefährlichste Gruppenphase und muss gestoppt oder mit CDs überlebt werden.
{TANK} Positioniere beide Ziele so, dass die Gruppe nicht zwischen Folge-Mechaniken eingekesselt wird. Wenn Entkräftendes Kreischen durchgeht, sofort defensiv reagieren.
{DD} Kicks und Stops auf Entkräftendes Kreischen priorisieren und die Lebenspunkte beider Ziele eng zusammenhalten, damit Zerrissenes Band nicht eskaliert.
{HEAL} Entkräftendes Kreischen ist der große Healcheck. Große CDs lieber dafür aufheben als für zufälligen Streuschaden.
{HC} Ab höheren Modi kommt Fluch der Dunkelheit mit fixierenden Geistern dazu. Diese werden gekitet oder kontrolliert, nicht aus Versehen mitgetankt.
]=],
	BOSS_GUIDES_BOSS_COMMANDER_KROLUK_NAME = "Kommandant Kroluk",
	BOSS_GUIDES_BOSS_COMMANDER_KROLUK_BODY = [=[
Allgemein: Versammelndes Gebrüll ruft den Kriegstrupp. Solange Adds leben, kanalisiert der Boss Klingensturm und ist zusätzlich durch Schildwall geschützt. Toben ist der Tankbuster. Tollkühner Sprung geht auf den entferntesten Spieler und wird danach von Fallendes Geröll begleitet.
{TANK} Plane Defensives und Externals für Toben. Stelle den Boss so, dass Add-Phase und Sprung-Bait die Gruppe nicht zerreißen.
{DD} In der Gebrüll-Phase haben Adds absolute Priorität, sonst läuft Klingensturm zu lange weiter. Der weiteste Spieler für Tollkühner Sprung sollte bewusst gewählt sein.
{HEAL} Größte Gruppenspitze ist Versammelndes Gebrüll zusammen mit Klingensturm. Heile hier aktiv vor statt hinterher.
{HC} Ab höheren Modi kommt Drohruf hinzu und darf nicht solo genommen werden; die Gruppe muss dafür bewusst stacken.
]=],
	BOSS_GUIDES_BOSS_DAS_RASTLOSE_HERZ_NAME = "Das rastlose Herz",
	BOSS_GUIDES_BOSS_DAS_RASTLOSE_HERZ_BODY = [=[
Allgemein: Zielscheibenwindstoß erzeugt Wogender Wind als expandierenden Ring und darf die Arena nicht ungünstig zerschneiden. Pfeilhagel spawnt Swirls; daraus entstehen Turbulente Pfeile mit Knock-up. Sturmschlitzer ist ein stapelnder Tankbuster, der laut Mechanik über Turbulente Pfeile gelöst wird. Blitzbö ist ein frontaler Sperrfeuer-Channel auf ein Ziel; das Ziel bleibt stehen, alle anderen weichen aus.
{TANK} Sturmschlitzer wird mit jedem Stapel gefährlicher. Defensives einteilen und den Reset über Turbulente Pfeile aktiv mitspielen.
{DD} Zielscheibenwindstoß so platzieren, dass Wogender Wind nicht die ganze Arena abschneidet. Böenschuss kann in höheren Modi Stürmischer Seelenquell entfernen.
{HEAL} Blitzbö und Sturmböensprung erzeugen die größten Gruppenspitzen. Plane CDs dafür und halte besonders Fehler nach Knock-ups im Blick.
{HC} Ab höheren Modi wird Stürmischer Seelenquell zur Zusatzgefahr und muss mit Böenschuss kontrolliert werden.
]=],
	BOSS_GUIDES_BOSS_UEBERWUCHERTES_URTUM_NAME = "Überwuchertes Urtum",
	BOSS_GUIDES_BOSS_UEBERWUCHERTES_URTUM_BODY = [=[
Allgemein: Keimen als Gruppe stacken und gemeinsam rotieren, damit die entstehenden Adds gebündelt cleavbar bleiben.
Verästeln mit großem Einschlag oder Knockback seitlich dodgen, damit niemand in Folgeeffekte gedrückt wird.
Heilende Berührung vom Ast eines Urtums immer unterbrechen, sonst heilt der Encounter unnötig hoch.
Überfluss im Kreis nach Add-Tod stehen, um die Bleed-Stacks sicher zu entfernen und den Reset mitzunehmen.
{TANK} Borkenbrecher mit aktiver Mitigation nehmen, weil der Tankbuster danach physischen Folgeschaden deutlich gefährlicher macht.
Explosionsartiges Erwachen vor dem 100-Energie-AoE mit Defensives und Add-Aggro-Plan vorbereiten, um aktivierte Peitscher sofort zu kontrollieren.
{DD} Splitterborke beim Überfluss-Kreis kurz stacken, damit der Gruppen-Bleed nicht weiter eskaliert.
{HEAL} Peitschergift als Poison-Stacks wenn möglich rotierend dispellen, weil sie auf Tanks und Spielern schnell überdrehen.
{HC} Borkenbrecher erhöht auf Heroic+ den physischen Damage-Taken-Debuff deutlich und macht gleichzeitig lebende Adds wesentlich punisher.
]=],
	BOSS_GUIDES_BOSS_KRAAS_NAME = "Kraas",
	BOSS_GUIDES_BOSS_KRAAS_BODY = [=[
Allgemein: Ball spielen! verlangt, dass Bälle konsequent in ein Ziel gespielt werden, statt nebenbei DPS zu greeden.
Feuersturm erzeugt danach dauerhaft neue Feuerzonen, die strikt gedodged werden müssen; das Burst-Fenster sauber nutzen.
Sturmkraft über Umherstreifende Zyklone kontrollieren und den erhaltenen Knockback-Schutz oder Speed-Buff aktiv fürs Positionsspiel verwenden.
Verwüstende Winde bei 75 Prozent und 45 Prozent HP früh gegenhalten, damit niemand in Folgemechaniken fliegt.
{TANK} Wildes Picken vor dem Treffer defensiv planen, weil physischer Spike und Bleed sonst schnell Heiler überfordern.
{DD} Ohrenbetäubendes Kreischen sauber timen und danach sofort stabil repositionieren, statt im Push zu sterben.
{HEAL} Sengendes Feuer erzeugt nach Feuersturm permanenten Gruppenschaden; Heals und Defensivs deshalb über Zeit staffeln.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den verfügbaren Quellen war keine eindeutige HC-Abweichung dokumentiert.
]=],
	BOSS_GUIDES_BOSS_VEXAMUS_NAME = "Vexamus",
	BOSS_GUIDES_BOSS_VEXAMUS_BODY = [=[
Allgemein: Arkane Kugeln früh soaken, bevor sie den Boss erreichen, damit er keine Energie- oder Damage-Eskalation bekommt.
Manabomben als Ziel nach außen laufen und die Pfützen so droppen, dass Wege frei bleiben.
Arkanriss bei 100 Energie den Knockback gegensteuern und die entstehenden Bodenkreise konsequent dodgen.
{TANK} Arkaner Ausstoß als Frontal strikt von der Gruppe weg stellen und für den Treffer aktive Mitigation oder Defensive nutzen.
{DD} Aggressives Absorbieren nie unnötig mehrfach soaken, weil der Debuff das nächste Soaken massiv gefährlicher macht.
{HEAL} Verderbtes Mana darf niemand stehen lassen, weil die Pfütze konstant tickt und Overlaps deutlich schwerer heilbar macht.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den verfügbaren Quellen wurde keine eigene Heroic-Abweichung belastbar dokumentiert.
]=],
	BOSS_GUIDES_BOSS_ECHO_OF_DORAGOSA_NAME = "Echo von Direktorin Doragosa",
	BOSS_GUIDES_BOSS_ECHO_OF_DORAGOSA_BODY = [=[
Allgemein: Energie entfesseln bedeutet, dass der Pull nur mit vollen HP erfolgen sollte, weil der Startcast sofort Gruppenschaden plus Rifts erzeugt.
Arkaner Riss bewusst an den Rand legen, damit beim späteren Pull oder Knock keine No-Go-Zonen im Kern entstehen.
Unkontrollierte Energie aus den Rifts konsequent dodgen, weil Treffer weitere Stack-Eskalation auslösen.
Überwältigende Kraft möglichst komplett vermeiden und bei drohendem Stack-Trigger die nächste Rift an eine saubere Stelle platzieren.
{TANK} Kraftvakuum verlangt, dass der Boss so steht, dass das Gruppenziehen niemanden in Rifts zieht; nach dem Pull sofort aus dem AoE heraus.
{DD} Energiebombe isoliert spielen, damit die Explosion keine Mitspieler cleavt und keine unnötigen Stacks erzeugt.
{HEAL} Arkane Geschosse ist vor allem in Overlaps ein Kill-Setup; Spot-Heal oder Defensiv-Calls daher früh setzen.
Astralschock nie unnötig überlappen lassen, weil sonst Stacks und Rift-Dichte eskalieren.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den verfügbaren Quellen war keine verlässliche HC-Sonderliste dokumentiert.
]=],
	BOSS_GUIDES_BOSS_FORGEMASTER_GARFROST_NAME = "Schmiedemeister Garfrost",
	BOSS_GUIDES_BOSS_FORGEMASTER_GARFROST_BODY = [=[
Allgemein: Throw Saronite nicht stacken und die Ore Chunks sinnvoll platzieren, damit die Arena nicht zugestellt wird.
Bei voller Energie folgt Glacial Overload; dafür hinter einem Ore Chunk verstecken, weil der Chunk die Abschirmung liefert.
Nach Glacial Overload kommt Cryostomp mit Gruppen-AoE und zwei Magie-Debuffs; diese schnell dispellen, damit sie nicht zusammen mit Siphoning Chill unnötig viel Heilung fressen.
{TANK} Orebreaker ist der Tank-Buster. Defensiv timen und den Boss so stellen, dass dabei ein Ore Chunk getroffen oder zerstört wird.
Lasst nicht mehrere ungelöste Ore Chunks gleichzeitig stehen, wenn euer Setup sie schlecht kontrolliert bekommt.
{DD} Ore Chunks kontrolliert mit entfernen und nicht wahllos zusätzliche Bodenprobleme erzeugen.
Während Glacial Overload sauber hinter den Chunk gehen und danach sofort wieder heraus, damit Uptime und Wege kurz bleiben.
{HEAL} Cryostomp ist das klare Heil-CD-Fenster, besonders auf höheren Stufen.
Die Magie-Debuffs nach Cryostomp zügig dispellen, idealerweise ein Ziel sofort und das zweite je nach GCD und Gruppenschaden.
Siphoning Chill läuft dauerhaft als Aura-Schaden und bestimmt euren Mana- und CD-Plan.
{HC} In den aktuell verfügbaren Guides werden keine getrennten Mechanik-Unterschiede für Heroic gegenüber Mythic genannt; der Unterschied liegt vor allem im Tuning.
]=],
	BOSS_GUIDES_BOSS_ICK_AND_KRICK_NAME = "Ick und Krick",
	BOSS_GUIDES_BOSS_ICK_AND_KRICK_BODY = [=[
Allgemein: Necrolink bedeutet geteilte HP; cleaven deshalb immer mit, wenn es sicher geht.
Blight Smash und Plague Explosion erzeugen Area-Denial; haltet daher bewusst saubere Zonen offen.
Shade Shift bringt Adds ins Spiel; cleave diese mit Priorität, ohne dabei den wichtigsten Interrupt zu verlieren.
{TANK} Blight Smash defensiv spielen und die entstehende Fläche aus dem Kampfbereich heraus droppen, nicht in Melee- oder Heiler-Positionen.
Während Get 'em, Ick! fixiert der Boss ein Zufallsziel; wenn das bei dir oder in deiner Nähe passiert, so laufen, dass die Gruppe nicht gegrieft wird.
{DD} Death Bolt von Krick ist Top-Priorität für Kicks.
Bei Shade Shift Shades sofort cleaven oder töten; Shadowbind unterbrechen oder entfluchen, wenn euer Setup das kann.
Wenn Get 'em, Ick! auf dich geht, sauber kiten; wenn nicht, das Fenster für Cleave und Push nutzen.
{HEAL} Plague Explosion wird schnell spiky, wenn Spieler schlecht stehen; vorher HoTs oder Schilde vorbereiten.
Shadowbind bei verfügbarem Fluch-Dispel zügig lösen, alternativ Kicks und Stops sauber abdecken.
{HC} Öffentlich dokumentiert sind vor allem Mythic- und M+-Mechaniken, die laut Guides weitgehend auch für Normal und Heroic gelten; Unterschiede liegen meist in Zahlen und Tuning.
]=],
	BOSS_GUIDES_BOSS_SCOURGELORD_TYRANNUS_NAME = "Geißelfürst Tyrannus",
	BOSS_GUIDES_BOSS_SCOURGELORD_TYRANNUS_BODY = [=[
Allgemein: Bone Piles sind das Kernobjektiv des Encounters. Wenn du Rime Blast bekommst, so stehen, dass du gezielt ein markiertes Bone Pile cleavest.
Army Of The Dead aktiviert Bone Piles und erzeugt Rotlings sowie bei infizierten Piles gefährlichere Scourge Plaguespreaders; diese haben Fokus und Interrupt-Priorität.
Death's Grasp und Ice Barrage erzeugen zusätzliche Dodge-Zonen; also in Bewegung bleiben und keine unnötigen Treffer nehmen.
{TANK} Scourgelord's Brand ist ein großer Knockback mit Folge-Sprung. Defensives und Bewegung so einplanen, dass der zweite Treffer nicht gratis durchgeht.
In den Add-Wellen Rotting Strikes-Stacks von Rotlings im Blick behalten und bei Möglichkeit Disease-Dispels oder Externals einfordern.
{DD} Scourge Plaguespreaders nach Army Of The Dead sofort answappen; Plague Bolt kicken, weil Festering Pulse starken Gruppenschaden erzeugt.
Bone Piles nicht zufällig cleaven, sondern über das Positionsspiel von Rime Blast gezielt vorbereiten.
{HEAL} Die Army-Phase rund um Army Of The Dead ist euer großes Druckfenster; Festering Pulse plus Flächenfehler eskalieren dort sehr schnell.
Rotting Strikes-Stacks auf dem Tank sind Heil- und Mitigation-Checks; bei hohen Stacks Externals oder Dispels früh einplanen.
{HC} Auch hier fokussieren die verfügbaren Quellen vor allem Mythic und M+ und beschreiben die Mechaniken als weitgehend auf Normal und Heroic übertragbar; spezifische Heroic-only-Mechaniken sind nicht separat ausgewiesen.
]=],
	BOSS_GUIDES_BOSS_RANJIT_NAME = "Ranjit",
	BOSS_GUIDES_BOSS_RANJIT_BODY = [=[
Allgemein: Windchakram niemals im Hin- oder Rückflug schneiden; die Linie ist der gefährlichste One-Shot des Kampfes.
• Sturmwoge stößt Spieler zurück; so stehen, dass niemand in Verdichteter Wind oder aus sicherem Raum gedrückt wird.
• Während Chakramvortex zusätzliche Sturmwoge sauber dodgen und Überleben vor DPS stellen.
• Klingenfächer ist das planbare Gruppenschadensfenster und wird in hektischen Overlaps besonders gefährlich.
{TANK} Ranjit eher am Rand halten, damit die Gruppe mehr Platz für Windchakram und Verdichteter Wind hat.
• Den Boss so drehen, dass Bewegungsmechaniken nicht die gesamte Mitte abschneiden.
{DD} In Chakramvortex defensiv spielen und keine Uptime greeden, wenn dafür sichere Wege verloren gehen.
• Windchakram nie quer durch die Gruppe ziehen und immer den Rückflug mitdenken.
{HEAL} Klingenfächer ist euer bestes CD-Fenster, besonders wenn es mit Chakramvortex überlappt.
• Nach Sturmwoge Rückstoß-Ziele sofort stabilisieren, falls sie in Verdichteter Wind oder schlechte Positionen geraten.
{HC} Keine separat verlässlichen HC-Zusatzmechaniken gefunden; der Kampf wird vor allem durch härteres Tuning und strengere Fehlerverzeihung punisher.
]=],
	BOSS_GUIDES_BOSS_ARAKNATH_NAME = "Araknath",
	BOSS_GUIDES_BOSS_ARAKNATH_BODY = [=[
Allgemein: Lichtstrahl immer soaken, damit Araknath durch Aufladen weder heilt noch zusätzliche Solarinfusion für die nächste Supernova bekommt.
• Supernova ist der große Gruppenhit des Kampfes; je weniger Aufladen durchkommt, desto leichter wird das Fenster.
• Verteidigungsprotokoll und Hitzeausstoß sauber dodgen, damit niemand ungewollt aus einem Lichtstrahl herausmuss.
• Wenn mehrere Strahlen gleichzeitig aktiv sind, zuerst die Soaks stabil halten und erst dann wieder greedige Positionen suchen.
{TANK} Feuriges Schmettern strikt von der Gruppe wegdrehen und nie durch Lichtstrahl-Soaker ziehen.
• Immer in Nahkampfreichweite bleiben, damit Druckwelle nicht unnötig ausgelöst wird.
{DD} Lichtstrahl blocken ist die eigentliche Kernmechanik des Bosses und wichtiger als jede einzelne Cast-Reihe.
• Vor Supernova mit Defensives helfen, wenn Solarinfusion-Stacks durchgegangen sind.
{HEAL} Beam-Soaker aktiv spotheilen; der konstante Schaden aus Lichtstrahl ist planbar, der Burst nach Supernova weniger.
• Große CDs für Supernova staffeln und nicht schon für einzelne Soak-Ticks verschwenden.
{HC} Keine separat verlässlichen HC-Zusatzmechaniken gefunden; auf höheren Stufen bleiben dieselben Kernmechaniken entscheidend.
]=],
	BOSS_GUIDES_BOSS_RUKHRAN_NAME = "Rukhran",
	BOSS_GUIDES_BOSS_RUKHRAN_BODY = [=[
Allgemein: Für Sonnenbruch nah am Boss stacken, damit die Sonnenschwinge in cleavbarer Position erscheint.
• Brennende Verfolgung sofort kontrollieren und mit CC verlangsamen; der Add-Tod darf niemals auf einem Schwelenden Ei passieren.
• Flammen des Ruhms und Schwelendes Ei sauber verteilen, damit kein alter Spawn wiederbelebt wird.
• Sengende Federn immer hinter der Mittelsäule line-of-sighten.
{TANK} Immer in Nahkampfreichweite bleiben, damit Kreischen nicht ausgelöst wird.
• Brennende Klauen aktiv defensiv abfangen.
{DD} Die Sonnenschwinge sofort kontrollieren und töten, aber ihren Todesort bewusst wählen.
• Wenn du von Brennende Verfolgung fixiert bist, das Add gezielt weg von vorhandenen Eiern ziehen.
{HEAL} Während Sonnenbruch und solange die Sonnenschwinge lebt, entsteht der höchste Gruppenschaden; CDs hier timen.
• Fixate-Ziele aus Brennende Verfolgung aktiv spotheilen.
{HC} Keine separat verlässlichen HC-Zusatzmechaniken gefunden; auf höheren Stufen bestraft vor allem schlechtes Ei- und Add-Management.
]=],
	BOSS_GUIDES_BOSS_HIGH_SAGE_VIRYX_NAME = "Hochweise Viryx",
	BOSS_GUIDES_BOSS_HIGH_SAGE_VIRYX_BODY = [=[
Allgemein: Solarentladung konsequent unterbrechen; jeder freie Cast erzeugt unnötigen Burst auf die Gruppe.
• Ziel von Lichtreflex läuft aus der Gruppe und legt Lodernde Erde sauber an den Rand.
• Bei Hinabwerfen sofort auf den Sonnenzeloten wechseln; der getragene Spieler hilft mit Schaden.
• Die Bossposition möglichst weg vom Rand halten, damit für Lichtreflex und Hinabwerfen Raum bleibt.
{TANK} Viryx eher zur Mitte oder nahe an das Hinabwerfen-Ziel ziehen, damit Boss und Add cleavbar bleiben.
• Sengender Strahl defensiv mit einplanen, falls ein Cast durchkommt oder du das Ziel bist.
{DD} Sonnenzeloten aus Hinabwerfen immer höchste Priorität geben.
• Wer Lichtreflex bekommt, zieht den Strahl nicht durch die Gruppe und zerschneidet keine freien Wege.
{HEAL} Sengender Strahl ist das planbare CD-Fenster des Kampfes.
• Nach Lichtreflex-Fehlern und während Hinabwerfen schnell stabilisieren, weil Plattformverluste kaum recoverbar sind.
{HC} Keine separat verlässlichen HC-Zusatzmechaniken gefunden; auf höheren Stufen kippt der Kampf meist über schlechte Lichtreflex- oder Hinabwerfen-Ausführung.
]=],
	BOSS_GUIDES_BOSS_ZURAAL_THE_ASCENDED_NAME = "Zuraal der Aufgestiegene",
	BOSS_GUIDES_BOSS_ZURAAL_THE_ASCENDED_BODY = [=[
Allgemein: Dezimieren so platzieren, dass die entstehende Pfütze am Rand oder auf bestehenden Flächen landet und nicht den Kampfbereich schließt.
Hand der Nichtigkeit sofort seitlich auslaufen, weil es als Frontal sehr oft tödlich ist.
Triefendes Schmettern fügt der Gruppe einen DoT zu und spawnt Verdichtete Leere, die ihr verlangsamen, kontrollieren und priorisiert töten müsst.
Hereinbrechende Leere zieht Spieler und beschleunigt Verdichtete Leere; diese daher vorher töten oder kontrollieren und beim Knockback nicht in Pfützen fliegen.
Leerenschlitzer ist die Tank-Buster-Combo, daher zählt jeder abgefangene Treffer über Defensives und aktive Mitigation.
Quellen: 4Fansites, WoWHead DE, Method, Icy Veins und wow.gg.
{TANK} Leerenschlitzer immer mit aktiver Mitigation oder Defensive abfangen, weil die Combo extrem hoch spikt.
Bei Dezimieren den Boss so stellen, dass Verdichtete Leere nicht geradeaus in ihn hineinläuft.
{DD} Verdichtete Leere sofort fokussieren und mit Slows, Stuns oder Knockbacks Zeit kaufen, weil Kontakt mit dem Boss sonst massiven Gruppenschaden verursacht.
Hand der Nichtigkeit strikt frontal vermeiden und als Range nicht durch die Melee-Positionen laufen.
{HEAL} Für Triefendes Schmettern früh einen CD-Plan haben, weil Gruppen-DoT und Flächen gleichzeitig Heilstress erzeugen.
Hereinbrechende Leere als großen Gruppentreffer plus Knockback vorbereiten und die Gruppe vor Channel-Ende stabilisieren.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den priorisierten Quellen war keine verifizierbare HC-exklusive Änderungsliste auffindbar.
]=],
	BOSS_GUIDES_BOSS_SARPUSH_NAME = "Saprish",
	BOSS_GUIDES_BOSS_SARPUSH_BODY = [=[
Allgemein: Leerenbombe nicht berühren, sondern mit dem Phasenspurt-Kreis entfernen, um möglichst viele Bomben kontrolliert zu beseitigen.
Überladung wird umso gefährlicher, je mehr Bomben noch liegen; Restbomben daher vor Cast-Ende defensiv oder mit Immunities soaken.
Kreischen des Grauens von Schemenschwinge konsequent unterbrechen, weil Fear und Schaden Overlap-Fenster schnell eskalieren lassen.
Schattenhaftes Anspringen von Dunkelzahn verursacht Schaden auf Zufallsziele mit Blutung; betroffene Spieler daher sofort stabilisieren und Cleanses bei Bedarf nutzen.
Verwundende Leere ist dauerhafter tanklastiger Nahkampfschaden und verschärft besonders die Stressfenster rund um Überladung.
Quellen: 4Fansites, WoWHead DE, Method, Icy Veins und Blizzard Hotfix Notes.
{TANK} Boss und Begleiter dauerhaft stapeln, weil sie Health teilen und ihr sonst unnötig Zeit verliert.
Wenn vor Überladung noch Bomben liegen, diese gezielt als Tank oder mit Immunity-Spielern aufnehmen, um zusätzlichen Stack- oder Explosionsschaden zu verhindern.
{DD} Phasenspurt so laufen, dass Bomben maximal mitgenommen werden und nicht im Kernbereich des Kampfes liegen bleiben.
Kreischen des Grauens mit fester Kick-Rotation absichern, weil Overlaps mit Phasenspurt sonst sehr schnell zu Kettenfehlern führen.
{HEAL} Die Gruppe vor Überladung immer vollständig vorbereiten, weil zusätzlich DoT-Druck entsteht und kleine Vorfehler dann sofort eskalieren.
Ziele von Schattenhaftes Anspringen priorisiert spothealen, weil zufällige Blutung plus Überladung-Fenster schnell tödlich werden kann.
{HC} Bestätigte Hotfix-Änderungen ohne klare Schwierigkeitsbindung: Leerenbombe bekam ein Visual-Update und der Impact-Radius von Phasenspurt wurde auf 8 Meter erhöht.
Darüber hinaus sind derzeit keine verifizierbaren HC-exklusiven Änderungen bestätigt.
]=],
	BOSS_GUIDES_BOSS_VICEROY_NEZHAR_NAME = "Vizekönig Nezhar",
	BOSS_GUIDES_BOSS_VICEROY_NEZHAR_BODY = [=[
Allgemein: Gedankenschlag ist ein Tank-Cast und muss mit Kick-Rotation gedeckelt werden, sonst kippt der Kampf sehr schnell.
Tore des Abgrunds spawnen Umbralwellen, die ihr konsequent dodgen müsst, weil sie dauerhaften Raumdruck erzeugen.
Massenleereninfusion trifft mehrere Spieler gleichzeitig; Defensives und Heiler-CDs daher gezielt auf diese Fenster legen.
Umbraltentakel erscheinen in Sets und channeln Gedankenschinden auf Spieler; sie müssen schnell gecleavt oder fokussiert werden.
Bei voller Energie folgt Abstoßende Kraft mit Knockback und danach Kollabierende Leere; dann sofort unter den Boss in die Safe-Zone spielen und Gruppendefensives ziehen.
Quellen: 4Fansites, WoWHead DE, Method, wow.gg und Icy Veins.
{TANK} Gedankenschlag aktiv in die Interrupt-Rotation einplanen und defensiv mitdenken, weil es der Primärspike auf den Tank ist.
Vor Abstoßende Kraft den Boss möglichst zentral positionieren, damit die Gruppe die Safe-Zone unter dem Boss für Kollabierende Leere zuverlässig erreicht.
{DD} Umbraltentakel sofort cleaven oder töten, weil jede Channel-Sekunde von Gedankenschinden zusätzlichen Gruppenschaden bedeutet.
In der Kollabierende Leere-Phase Movement-CDs nutzen, um den Safe-Spot unter dem Boss sicher zu halten, statt außerhalb zu greeden.
{HEAL} Massenleereninfusion und Kollabierende Leere sind die klaren CD-Anker des Kampfes.
Nach dem Knockback von Abstoßende Kraft direkt stabilisieren, weil Fehlpositionen sonst zusätzliche Treffer durch Waves erzwingen.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den priorisierten Quellen war keine verifizierbare HC-exklusive Änderungsliste auffindbar.
]=],
	BOSS_GUIDES_BOSS_LURA_NAME = "L'ura",
	BOSS_GUIDES_BOSS_LURA_BODY = [=[
Allgemein: Klagelied der Verzweiflung ist der Gruppentreffer, der Noten der Verzweiflung erzeugt; Heiler-CDs daher über die Note-Phase verteilen.
Disharmonischer Strahl gezielt auf aktive Noten der Verzweiflung schießen, um sie zu silencen und so den permanenten Puls-Schaden zu reduzieren.
Wenn alle Noten der Verzweiflung gesilenced sind, startet eine Intermission mit Leere entziehen als klarem Schadensfenster; DPS-CDs dafür sparen.
Grimmiger Chor repositioniert Noten der Verzweiflung und erzeugt Gefahrenzonen um aktive Noten; deshalb sofort neu ausrichten und nicht stehen bleiben.
Qual tickt alle 2 Sekunden auf die Gruppe, solange Noten aktiv sind; die Intermission daher erzwingen, bevor der Dauerschaden unheilbar wird.
Desintegration als rotierende Beam-Mechanik gemeinsam mitlaufen, statt quer durch Strahlen zu schneiden.
Abyssische Lanze stapelt auf Boss und Tank und triggert bei 3 Stacks einen großen Treffer nach kurzer Verzögerung; diesen Punkt defensiv vorplanen.
{TANK} Abyssische Lanze bei 3 Stacks als klaren Defensive-Pflichtpunkt behandeln, weil der folgende Treffer sonst tödlich spiken kann.
Boss möglichst zentral halten, damit die Gruppe Desintegration sauber umlaufen und Disharmonischer Strahl kontrolliert ausrichten kann.
{DD} Disharmonischer Strahl aktiv als Mechanik-DPS spielen und immer auf eine aktive Note richten, bis alle sechs gesilenced sind.
In der Intermission mit Leere entziehen alle Offensiv-CDs bündeln, weil dort das eigentliche Schadensfenster des Kampfes liegt.
{HEAL} Klagelied der Verzweiflung plus aktive Noten bedeuten permanenten Gruppendruck; CDs daher staffeln statt alles gleichzeitig zu ziehen.
Grimmiger Chor zusammen mit Qual ist euer eskalierendes Fail-Signal; fordert früh Defensives oder Externals, bis die Intermission erreicht ist.
{HC} HC-spezifische Änderungen sind derzeit unspezifiziert; in den priorisierten Quellen war keine verifizierbare HC-exklusive Änderungsliste auffindbar.
]=],
	BOSS_GUIDES_SPELL_NAMES = {
		["Shadow Phalanx"] = { spellID = 1284786, localizedName = "Schattenphalanx" },
		["Dark Barrage"] = "Dunkelsalve",
		["Decimate"] = { spellID = 244579, localizedName = "Dezimieren", aliases = { "Decimate" } },
		["Dezimieren"] = { spellID = 244579, localizedName = "Dezimieren", aliases = { "Decimate" } },
		["Null Palm"] = { spellID = 246134, localizedName = "Hand der Nichtigkeit", aliases = { "Null Palm" }, skipClientLookup = true },
		["Hand der Nichtigkeit"] = { spellID = 246134, localizedName = "Hand der Nichtigkeit", aliases = { "Null Palm" }, skipClientLookup = true },
		["Triefendes Schmettern"] = { spellID = 1263399, localizedName = "Triefendes Schmettern", aliases = { "Oozing Slam", "Triefendes Schmettern" } },
		["Verdichtete Leere"] = { spellID = 244602, localizedName = "Verdichtete Leere", aliases = { "Coalesced Void" } },
		["Hereinbrechende Leere"] = { spellID = 1263297, localizedName = "Hereinbrechende Leere", aliases = { "Crashing Void", "Crushing Void" } },
		["Leerenschlitzer"] = { spellID = 1263440, localizedName = "Leerenschlitzer", aliases = { "Void Slash" } },
		["Leerenschlick"] = { spellID = 244588, localizedName = "Leerenschlick", aliases = { "Void Sludge" } },
		["Dunkler Ausstoß"] = { spellID = 244599, localizedName = "Dunkler Ausstoß", aliases = { "Dark Expulsion" } },
		["Leerenbombe"] = { spellID = 246026, localizedName = "Leerenbombe", aliases = { "Void Bomb", "Leerenbomben" } },
		["Leerenbomben"] = { spellID = 246026, localizedName = "Leerenbomben", aliases = { "Void Bomb" } },
		["Phasenspurt"] = { spellID = 1280067, localizedName = "Phasenspurt", aliases = { "Phase Dash" } },
		["Umbralnova"] = { spellID = 1263508, localizedName = "Umbralnova" },
		["Überladung"] = { spellID = 1263523, localizedName = "Überladung", aliases = { "Overload" } },
		["Triefende Leere"] = { spellID = 1268840, localizedName = "Triefende Leere", aliases = { "Dripping Void" } },
		["Verwundende Leere"] = { spellID = 1266449, localizedName = "Verwundende Leere", aliases = { "Rending Void" } },
		["Schattenhaftes Anspringen"] = { spellID = 245742, localizedName = "Schattenhaftes Anspringen", aliases = { "Shadow Pounce" } },
		["Sturzflug"] = { spellID = 248830, localizedName = "Sturzflug", aliases = { "Swoop" } },
		["Kreischen des Grauens"] = { spellID = 248831, localizedName = "Kreischen des Grauens", aliases = { "Dread Screech" } },
		["Kollabierende Leere"] = { spellID = 1263529, localizedName = "Kollabierende Leere", aliases = { "Collapsing Void" } },
		["Leerensturm"] = { spellID = 1265030, localizedName = "Leerensturm", aliases = { "Void Surge" } },
		["Massenleereninfusion"] = { spellID = 1263542, localizedName = "Massenleereninfusion", aliases = { "Mass Void Infusion" } },
		["Gedankenschinden"] = { spellID = 1268733, localizedName = "Gedankenschinden", aliases = { "Mind Flay" } },
		["Gedankenschlag"] = { spellID = 244750, localizedName = "Gedankenschlag", aliases = { "Mind Blast" } },
		["Abstoßende Kraft"] = { spellID = 1263533, localizedName = "Abstoßende Kraft", aliases = { "Repulse" } },
		["Umbraltentakel"] = { spellID = 1263538, localizedName = "Umbraltentakel", aliases = { "Umbral Tentacles" } },
		["Tore des Abgrunds"] = { spellID = 1277358, localizedName = "Tore des Abgrunds", aliases = { "Gates Of The Abyss" } },
		["Umbralwellen"] = { spellID = 1264257, localizedName = "Umbralwellen", aliases = { "Umbral Waves" } },
		["Noten der Verzweiflung"] = { spellID = 1265419, localizedName = "Noten der Verzweiflung", aliases = { "Notes Of Despair" } },
		["Klagelied der Verzweiflung"] = { spellID = 1265421, localizedName = "Klagelied der Verzweiflung", aliases = { "Dirge Of Despair" } },
		["Disharmonischer Strahl"] = { spellID = 1265464, localizedName = "Disharmonischer Strahl", aliases = { "Discordant Beam" } },
		["Desintegration"] = { spellID = 1264196, localizedName = "Desintegration", aliases = { "Disintegrate" } },
		["Grimmiger Chor"] = { spellID = 1265689, localizedName = "Grimmiger Chor", aliases = { "Grim Chorus" } },
		["Qual"] = { spellID = 1265650, localizedName = "Qual", aliases = { "Anguish" } },
		["Leere entziehen"] = { spellID = 1265999, localizedName = "Leere entziehen", aliases = { "Siphon Void" } },
		["Abyssische Lanze"] = { spellID = 1267207, localizedName = "Abyssische Lanze", aliases = { "Abyssal Lance" } },
		["Tier wiederbeleben"] = {
			spellID = 1249789,
			localizedName = "Tier wiederbeleben",
			aliases = { "Revive Pet" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jin belebt Nekraxx wieder, wodurch sie mit einem großen Teil ihrer Gesundheit zurückkehrt. Beide Bosse deshalb möglichst gleichzeitig besiegen.",
			skipClientLookup = true,
		},
		["Zorn des Wildtiers"] = {
			spellID = 1249948,
			localizedName = "Zorn des Wildtiers",
			aliases = { "Bestial Wrath" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jins Niederlage versetzt Nekraxx in Raserei und erhöht ihren verursachten Schaden regelmäßig. Der Effekt stapelt sich, daher das Finish sofort durchziehen.",
			skipClientLookup = true,
		},
		["Speerfeuer"] = {
			spellID = 1260643,
			localizedName = "Speerfeuer",
			aliases = { "Sperrfeuer" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jin nimmt einen Spieler ins Visier und feuert mehrere giftige Salven in einem frontalen Kegel auf ihn. Treffer verursachen Seuchenschaden und belegen Ziele mit Stich der Blutfratzen.",
			skipClientLookup = true,
		},
		["Eisige Lache"] = {
			spellID = 1243751,
			localizedName = "Eisige Lache",
			aliases = { "Icy Slick" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Mehrere Instanzen von Eiskältefalle hinterlassen eine vereiste Fläche, die regelmäßig Frostschaden verursacht und Spieler rutschen lässt.",
			skipClientLookup = true,
		},
		["Eiskältefalle"] = {
			spellID = 1260731,
			iconID = 135834,
			localizedName = "Eiskältefalle",
			aliases = { "Freezing Trap" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jin wirft Fallen auf Spieler, die lange bestehen bleiben. Wer sie auslöst, wird kurz handlungsunfähig; Schaden kann den Effekt brechen.",
		},
		["Stich der Blutfratzen"] = {
			spellID = 1260709,
			localizedName = "Stich der Blutfratzen",
			aliases = { "Vilebranch Sting" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jins giftüberzogene Pfeile verlangsamen das Ziel mehrere Sekunden lang. Der Effekt ist stapelbar und macht Folge-Mechaniken deutlich schwerer.",
			skipClientLookup = true,
		},
		["Flankenspeer"] = {
			spellID = 1266480,
			localizedName = "Flankenspeer",
			aliases = { "Flanking Spear" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jin springt hinter sein aktuelles Ziel und schleudert einen gewaltigen Speer. Der Treffer stößt zurück und belegt das Ziel mit Offene Wunde.",
			skipClientLookup = true,
		},
		["Offene Wunde"] = {
			spellID = 1266488,
			localizedName = "Offene Wunde",
			aliases = { "Open Wound" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Blutung von Flankenspeer. Verursacht mehrere Sekunden lang regelmäßigen körperlichen Schaden auf dem Tank.",
			skipClientLookup = true,
		},
		["Aasfressersturzflug"] = {
			spellID = 1249479,
			localizedName = "Aasfressersturzflug",
			aliases = { "Carrion Swoop" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Nekraxx stürmt auf ein markiertes Ziel zu, fügt allen Spielern in ihrem Weg Schaden zu und schleudert sie in die Luft. Trifft sie einen in Eiskältefalle gefangenen Spieler, wird die Falle zerstört und Nekraxx betäubt.",
			skipClientLookup = true,
		},
		["Koordinierter Angriff"] = {
			spellID = 1249769,
			localizedName = "Koordinierter Angriff",
			aliases = { "Coordinated Assault" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Muro'jin wirft eine Axt auf Spieler, die durch Aasfressersturzflug in die Luft geschleudert wurden. Der Folgetreffer verursacht zusätzlichen körperlichen Schaden und noch mehr Knock-up.",
			skipClientLookup = true,
		},
		["Fauler Federsturm"] = {
			spellID = 1243900,
			localizedName = "Fauler Federsturm",
			aliases = { "Fetid Quillstorm", "Faulem Federsturm" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Nekraxx springt an eine Position, entfesselt dort dunkle Energie und verschießt Federn. Einschlag und Folgeflächen müssen sofort ausgewichen werden.",
			skipClientLookup = true,
		},
		["Infizierte Flügelspitzen"] = {
			spellID = 1246666,
			localizedName = "Infizierte Flügelspitzen",
			aliases = { "Infected Pinions" },
			tooltipKind = "Bossmechanik",
			tooltipText = "Nekraxx durchbohrt alle Spieler mit eitrigen Federn, die über längere Zeit Seuchenschaden verursachen. Das ist der zentrale Heilcheck des Kampfes.",
			skipClientLookup = true,
		},
		["Phantome entreißen"] = { spellID = 1251204, localizedName = "Phantome entreißen", aliases = { "Wrest Phantoms" } },
		["Nekrotische Konvergenz"] = { spellID = 1250708, localizedName = "Nekrotische Konvergenz", aliases = { "Necrotic Convergence" } },
		["Letzte Verfolgung"] = { spellID = 1251775, localizedName = "Letzte Verfolgung", aliases = { "Final Pursuit" } },
		["Schwelender Schrecken"] = { spellID = 1251813, localizedName = "Schwelender Schrecken", aliases = { "Lingering Dread" } },
		["Todesschleier"] = { spellID = 1251598, localizedName = "Todesschleier", aliases = { "Deathshroud" } },
		["Seelendieb"] = { spellID = 1251554, localizedName = "Seelendieb", aliases = { "Drain Soul" } },
		["Geronnener Tod"] = { spellID = 1252611, localizedName = "Geronnener Tod", aliases = { "Coalesced Death" } },
		["Heimsuchende Überreste"] = { spellID = 1266706, localizedName = "Heimsuchende Überreste", aliases = { "Haunting Remains" } },
		["Seelenfäule"] = { spellID = 1251833, localizedName = "Seelenfäule", aliases = { "Soulrot" } },
		["Verhüllte Präsenz"] = { spellID = 1264974, localizedName = "Verhüllte Präsenz", aliases = { "Veiled Presence" } },
		["Zerrütten"] = { spellID = 1252054, localizedName = "Zerrütten", aliases = { "Unmake" } },
		["Welkendes Miasma"] = { spellID = 1264987, localizedName = "Welkendes Miasma", aliases = { "Withering Miasma" } },
		["Seelen brechen"] = { spellID = 1252676, localizedName = "Seelen brechen", aliases = { "Crush Souls" } },
		["Geistbrecher"] = { spellID = 1251023, localizedName = "Geistbrecher", aliases = { "Spiritbreaker" } },
		["Seelenbindung"] = { spellID = 1252777, localizedName = "Seelenbindung", aliases = { "Soulbind" } },
		["Seelenreißendes Brüllen"] = { spellID = 1253788, localizedName = "Seelenreißendes Brüllen", aliases = { "Soulrending Roar" } },
		["Verdorrende Seele"] = { spellID = 1253844, localizedName = "Verdorrende Seele", aliases = { "Withering Soul" } },
		["Ewiges Leid"] = { spellID = 1254010, localizedName = "Ewiges Leid", aliases = { "Eternal Suffering" } },
		["Spektrale Rückstände"] = { spellID = 1255629, localizedName = "Spektrale Rückstände", aliases = { "Spectral Residue" } },
		["Todesverschlungenes Gefäß"] = { spellID = 1252864, localizedName = "Todesverschlungenes Gefäß", aliases = { "Deathgorged Vessel" } },
		["Kälte des Todes"] = { spellID = 1252816, localizedName = "Kälte des Todes" },
		["Spektraler Verfall"] = { spellID = 1266723, localizedName = "Spektraler Verfall", aliases = { "Spectral Decay" } },
		["Flüchtige Essenz"] = { spellID = 1248980, localizedName = "Flüchtige Essenz", aliases = { "Volatile Essence" } },
		["Schreie der Gefallenen"] = { spellID = 1254175, localizedName = "Schreie der Gefallenen", aliases = { "Cries of the Fallen" } },
		["Seelenausstoß"] = { spellID = 1253909, localizedName = "Seelenausstoß", aliases = { "Soul Expulsion" } },
		["Zerschmettertes Totem"] = { spellID = 1259810, localizedName = "Zerschmettertes Totem", aliases = { "Shattered Totem" } },
		["Keimen"] = { spellID = 388796, localizedName = "Keimen", aliases = { "Germinate" } },
		["Verästeln"] = { spellID = 388623, localizedName = "Verästeln", aliases = { "Branch Out" } },
		["Borkenbrecher"] = { spellID = 388544, localizedName = "Borkenbrecher", aliases = { "Barkbreaker" } },
		["Explosionsartiges Erwachen"] = { spellID = 388923, localizedName = "Explosionsartiges Erwachen", aliases = { "Burst Forth", "Explosionsartige Erwachen" } },
		["Heilende Berührung"] = { spellID = 396640, localizedName = "Heilende Berührung", aliases = { "Healing Touch" } },
		["Peitschergift"] = { spellID = 389033, localizedName = "Peitschergift", aliases = { "Lasher Toxin" } },
		["Splitterborke"] = { spellID = 396716, localizedName = "Splitterborke", aliases = { "Splinterbark" } },
		["Überfluss"] = { spellID = 396721, localizedName = "Überfluss", aliases = { "Abundance" } },
		["Ball spielen!"] = { spellID = 377182, localizedName = "Ball spielen!", aliases = { "Play Ball!", "Score a Goal" } },
		["Feuersturm"] = { spellID = 376448, localizedName = "Feuersturm", aliases = { "Firestorm" } },
		["Sturmkraft"] = { spellID = 376467, localizedName = "Sturmkraft", aliases = { "Power of the Storm" } },
		["Überwältigende Böe"] = { spellID = 377034, localizedName = "Überwältigende Böe" },
		["Wildes Picken"] = { spellID = 376997, localizedName = "Wildes Picken", aliases = { "Ferocious Peck" } },
		["Tor des sengenden Feuers"] = { spellID = 389481, localizedName = "Tor des sengenden Feuers" },
		["Sengendes Feuer"] = { spellID = 1285508, localizedName = "Sengendes Feuer", aliases = { "Scorching Fire" } },
		["Tor der rauschenden Winde"] = { spellID = 389483, localizedName = "Tor der rauschenden Winde" },
		["Umherstreifender Zyklon"] = { spellID = 393211, localizedName = "Umherstreifender Zyklon" },
		["Verwüstende Winde"] = { spellID = 1276752, localizedName = "Verwüstende Winde", aliases = { "Destructive Winds" } },
		["Ohrenbetäubendes Kreischen"] = { spellID = 454341, localizedName = "Ohrenbetäubendes Kreischen", aliases = { "Deafening Screech" } },
		["Arkane Kugeln"] = { spellID = 387691, localizedName = "Arkane Kugeln", aliases = { "Arcane Orbs" } },
		["Aggressives Absorbieren"] = { spellID = 391977, localizedName = "Aggressives Absorbieren", aliases = { "Oversurge" } },
		["Arkanriss"] = { spellID = 388537, localizedName = "Arkanriss", aliases = { "Arcane Fissure" } },
		["Arkaner Ausstoß"] = { spellID = 385958, localizedName = "Arkaner Ausstoß", aliases = { "Arcane Expulsion" } },
		["Manabomben"] = { spellID = 386173, localizedName = "Manabomben", aliases = { "Mana Bombs" } },
		["Verderbtes Mana"] = { spellID = 386201, localizedName = "Verderbtes Mana", aliases = { "Corrupted Mana" } },
		["Arkaner Riss"] = { spellID = 388901, localizedName = "Arkaner Riss", aliases = { "Arcane Rift" } },
		["Überwältigende Kraft"] = { spellID = 389011, localizedName = "Überwältigende Kraft", aliases = { "Overwhelming Power" } },
		["Unkontrollierte Energie"] = { spellID = 388951, localizedName = "Unkontrollierte Energie", aliases = { "Uncontrolled Energy" } },
		["Energie entfesseln"] = { spellID = 439488, localizedName = "Energie entfesseln", aliases = { "Unleash Energy" } },
		["Astralschock"] = { spellID = 1282251, localizedName = "Astralschock", aliases = { "Astral Breath" } },
		["Kraftvakuum"] = { spellID = 388822, localizedName = "Kraftvakuum", aliases = { "Power Vacuum" } },
		["Arkane Geschosse"] = { spellID = 373326, localizedName = "Arkane Geschosse", aliases = { "Arcane Missiles" } },
		["Energiebombe"] = { spellID = 374352, localizedName = "Energiebombe", aliases = { "Energy Bomb" } },
		["Sturmwoge"] = { spellID = 1252691, localizedName = "Sturmwoge", aliases = { "Gale Surge" } },
		["Verdichteter Wind"] = { spellID = 1258140, localizedName = "Verdichteter Wind", aliases = { "Coalesced Wind" } },
		["Windchakram"] = { spellID = 1258152, localizedName = "Windchakram", aliases = { "Wind Chakram", "Windwall" } },
		["Klingenfächer"] = { spellID = 153757, localizedName = "Klingenfächer", aliases = { "Fan of Blades" } },
		["Chakramvortex"] = { spellID = 156793, localizedName = "Chakramvortex", aliases = { "Chakram Vortex" } },
		["Aufladen"] = { spellID = 154139, localizedName = "Aufladen", aliases = { "Energize" } },
		["Solarinfusion"] = { spellID = 1252877, localizedName = "Solarinfusion", aliases = { "Solar Infusion" } },
		["Hitzeausstoß"] = { spellID = 1281874, localizedName = "Hitzeausstoß", aliases = { "Heat Wave" } },
		["Lichtstrahl"] = { spellID = 154150, localizedName = "Lichtstrahl", aliases = { "Light Beam" } },
		["Supernova"] = { spellID = 154135, localizedName = "Supernova" },
		["Feuriges Schmettern"] = { spellID = 154132, localizedName = "Feuriges Schmettern", aliases = { "Fiery Smash", "Smash" } },
		["Verteidigungsprotokoll"] = { spellID = 1283770, localizedName = "Verteidigungsprotokoll", aliases = { "Defensive Protocol" } },
		["Druckwelle"] = { spellID = 1279002, localizedName = "Druckwelle", aliases = { "Blast Wave" } },
		["Sonnenbruch"] = { spellID = 1253510, localizedName = "Sonnenbruch", aliases = { "Sunbreak" } },
		["Flammen des Ruhms"] = { spellID = 1253416, localizedName = "Flammen des Ruhms", aliases = { "Blaze of Glory" } },
		["Brennende Verfolgung"] = { spellID = 1253511, localizedName = "Brennende Verfolgung", aliases = { "Burning Pursuit" } },
		["Schwelendes Ei"] = { spellID = 1253424, localizedName = "Schwelendes Ei", aliases = { "Smoldering Egg" } },
		["Sengende Federn"] = { spellID = 159381, localizedName = "Sengende Federn", aliases = { "Searing Quills" } },
		["Brennende Klauen"] = { spellID = 1253519, localizedName = "Brennende Klauen", aliases = { "Burning Claws" } },
		["Kreischen"] = { spellID = 153898, localizedName = "Kreischen", aliases = { "Screech" } },
		["Hinabwerfen"] = { spellID = 153954, localizedName = "Hinabwerfen", aliases = { "Cast Down", "Hinabstürzen" } },
		["Lichtreflex"] = { spellID = 154044, localizedName = "Lichtreflex", aliases = { "Lens Flare" } },
		["Lodernde Erde"] = { spellID = 154043, localizedName = "Lodernde Erde", aliases = { "Blazing Ground" } },
		["Sengender Strahl"] = { spellID = 1253543, localizedName = "Sengender Strahl", aliases = { "Scorching Ray" } },
		["Solarentladung"] = { spellID = 154396, localizedName = "Solarentladung", aliases = { "Solar Blast", "Sonneneruption" } },
		["Throw Saronite"] = { spellID = 1261299 },
		["Ore Chunks"] = { spellID = 1272433, aliases = { "Ore Chunk" } },
		["Orebreaker"] = { spellID = 1261546 },
		["Glacial Overload"] = { spellID = 1262029 },
		["Cryostomp"] = { spellID = 1261847 },
		["Siphoning Chill"] = { spellID = 1261806 },
		["Necrolink"] = { spellID = 1264192 },
		["Shade Shift"] = { spellID = 1264027 },
		["Shadowbind"] = { spellID = 1264186 },
		["Death Bolt"] = { spellID = 1278893 },
		["Blight Smash"] = { spellID = 1264287 },
		["Plague Explosion"] = { spellID = 1264336 },
		["Get 'em, Ick!"] = { spellID = 1264363 },
		["Rime Blast"] = { spellID = 1262745 },
		["Bone Piles"] = { spellID = 1276357, aliases = { "Bone Pile" } },
		["Army Of The Dead"] = { spellID = 1263406 },
		["Rotting Strikes"] = { spellID = 1262929 },
		["Festering Pulse"] = { spellID = 1262997 },
		["Plague Bolt"] = { spellID = 1262941 },
		["Scourgelord's Brand"] = { spellID = 1262582 },
		["Death's Grasp"] = { spellID = 1263756 },
		["Ice Barrage"] = { spellID = 1276948 },
		["Void Infusion"] = { spellID = 1245960, localizedName = "Leereninfusion" },
		["Dark Uproar"] = { spellID = 1249251, localizedName = "Dunkle Verwerfung" },
		["Black Miasma"] = { spellID = 1275059, localizedName = "Schwarzes Miasma" },
		["Blackening Wounds"] = { spellID = 1265540, localizedName = "Schwärzende Wunden" },
		["Cosmic Shell"] = { spellID = 1280035, localizedName = "Kosmischer Panzer" },
		["Void Marked"] = { spellID = 1280015, localizedName = "Leerenmarkiert" },
		["Schattenvorstoß"] = { spellID = 1251361, localizedName = "Schattenvorstoß" },
		["Ruhm des Imperators"] = { spellID = 1253918, localizedName = "Ruhm des Imperators" },
		["Pitch Bulwark"] = { spellID = 1255702, localizedName = "Bollwerk errichten" },
		["Oblivion's Wrath"] = { spellID = 1260712, localizedName = "Zorn der Vergessenheit", aliases = { "Zorn der Auslöschung" } },
		["Void Fall"] = { spellID = 1258883, localizedName = "Leerenfall", aliases = { "Leerensturz" } },
		["Rising Darkness"] = { spellID = 1255749, localizedName = "Aufziehende Dunkelheit" },
		["Dark Resilience"] = { spellID = 1264164, localizedName = "Dunkle Resilienz" },
		["Overpowering Pulse"] = { spellID = 1244419, localizedName = "Überwältigender Puls" },
		["Blisterburst"] = { spellID = 1259184, localizedName = "Pustelbersten" },
		["Void Breath"] = { spellID = 1256855, localizedName = "Leerenatem" },
		["Primordial Roar"] = { spellID = 1260046, localizedName = "Urzeitliches Brüllen" },
		["Creep Spit"] = { spellID = 1273159, localizedName = "Kriecherspritzer" },
		["Shadowclaw Slash"] = { spellID = 1244012, localizedName = "Schattenklauenhieb" },
		["Dark Goo"] = { spellID = 1243270, localizedName = "Dunkler Schleim", aliases = { "Dunklen Schleim" } },
		["Smashed"] = { spellID = 1241844, localizedName = "Zerschmettert" },
		["Leerenruptur"] = { spellID = 1262036, localizedName = "Leerenruptur" },
		["Dunkles Sperrfeuer"] = { spellID = 1274846, localizedName = "Dunkles Sperrfeuer" },
		["Knirschende Leere"] = { spellID = 1255683, localizedName = "Knirschende Leere" },
		["Humpelnd"] = { spellID = 1267205, localizedName = "Humpelnd" },
		["Lauernde Dunkelheit"] = { spellID = 1280075, localizedName = "Lauernde Dunkelheit" },
		["Abyssischer Malus"] = "Abyssischer Malus",
		["Abyssische Leerenformer"] = "Abyssische Leerenformer",
		["Leerenschlund"] = "Leerenschlund",
		["Nachbeben"] = { spellID = 1273067, localizedName = "Nachbeben" },
		["Blasenkriecher"] = "Blasenkriecher",
		["Parasitenausstoß"] = { spellID = 1254199, localizedName = "Parasitenausstoß" },
		["Dunkle Energie"] = { spellID = 1280101, localizedName = "Dunkle Energie" },
		["Urzeitliche Macht"] = { spellID = 1272937, localizedName = "Urzeitliche Macht" },
		["Torturous Extract"] = { spellID = 1245592, localizedName = "Quälendes Extrakt", aliases = { "Quälender Extrakt" } },
		["Shattering Twilight"] = { spellID = 1253032, localizedName = "Zertrümmerndes Zwielicht", aliases = { "Zerschmetterndes Zwielicht" } },
		["Destabilizing Strikes"] = { spellID = 1271577, localizedName = "Destabilisierende Stöße", aliases = { "Destabilisierende Schläge" } },
		["Concentrated Void"] = "Konzentrierte Leere",
		["Fractured Images"] = "Zersplitterte Abbilder",
		["Void Convergence"] = { spellID = 1247738, localizedName = "Leerenkonvergenz" },
		["Void Exposure"] = { spellID = 1250832, localizedName = "Leerenaussetzung" },
		["Broken Projection"] = { spellID = 1254081, localizedName = "Gebrochene Projektion" },
		["Shadow Fracture"] = { spellID = 1254088, localizedName = "Schattenfraktur" },
		["Entropic Unraveling"] = { spellID = 1246175, localizedName = "Entropische Auflösung" },
		["Umbra Rays"] = { spellID = 1260015, localizedName = "Umbrastrahlen" },
		["Twisting Obscurity"] = { spellID = 1250686, localizedName = "Windende Obskurität" },
		["Despotic Command"] = { spellID = 1248697, localizedName = "Despotischer Befehl" },
		["Oppressive Darkness"] = { spellID = 1248709, localizedName = "Drückende Finsternis", aliases = { "Erdrückende Dunkelheit" } },
		["Dark Radiation"] = { spellID = 1250991, localizedName = "Dunkle Strahlung" },
		["Enduring Void"] = { localizedName = "Beständige Leere", aliases = { "Anhaltende Leere" } },
		["Nexus Shield"] = "Nexusschild",
		["Twilight Bond"] = { spellID = 1270189, localizedName = "Zwielichtbund" },
		["Twilight Fury"] = { spellID = 1270250, localizedName = "Zwielichtfuror" },
		["Tail Swipe"] = { spellID = 1264467, localizedName = "Schwanzpeitscher" },
		["Impale"] = { spellID = 1265152, localizedName = "Durchbohren" },
		["Vaelwing"] = { spellID = 1265131, localizedName = "Vaelschwinge", aliases = { "Vaelflügel" } },
		["Rakfang"] = { spellID = 1245645, localizedName = "Rakzahn" },
		["Nullbeam"] = { spellID = 1262623, localizedName = "Nullstrahl" },
		["Gloom"] = { spellID = 1245391, localizedName = "Düsternis" },
		["Dread Breath"] = { spellID = 1244221, localizedName = "Entsetzlicher Atem" },
		["Radiant Barrier"] = { spellID = 1248847, localizedName = "Strahlende Barriere" },
		["Nullzone"] = { spellID = 1244672, localizedName = "Nullzone" },
		["Shadowmark"] = { spellID = 1270513, localizedName = "Schattenmal" },
		["Nullsnap"] = { spellID = 1244413, localizedName = "Nullbruch" },
		["Midnight Flames"] = { spellID = 1249748, localizedName = "Mitternachtsflammen" },
		["Gloomtouched"] = "Von Düsterkeit berührt",
		["Diminish"] = "Schwächung",
		["Nullscatter"] = { spellID = 1266570, localizedName = "Nullstreu", aliases = { "Nullstreuung" } },
		["Cosmosis"] = "Kosmosis",
		["Retribution"] = "Vergeltung",
		["Judgment"] = { spellID = 1246736, localizedName = "Richturteil" },
		["Exorcism"] = "Exorzismus",
		["Execution Sentence"] = { spellID = 1248983, localizedName = "Todesurteil" },
		["Aura of Wrath"] = { spellID = 1248449, localizedName = "Aura des Zorns" },
		["Aura of Devotion"] = { spellID = 1246162, localizedName = "Aura der Hingabe" },
		["Aura of Peace"] = { spellID = 1248451, localizedName = "Aura des Friedens" },
		["Sacred Shield"] = { spellID = 1248674, localizedName = "Geheiligter Schild", aliases = { "Heiliges Schild" } },
		["Blinding Light"] = { spellID = 1258514, localizedName = "Blendendes Licht" },
		["Divine Hammer"] = { spellID = 1249047, localizedName = "Göttlicher Hammer", aliases = { "Göttliche Hämmer" } },
		["Light Infused"] = { spellID = 1258659, localizedName = "Lichtdurchdrungen", aliases = { "Lichtinfundiert" } },
		["Searing Radiance"] = "Sengende Strahlkraft",
		["Tyr's Wrath"] = { spellID = 1248710, localizedName = "Tyrs Zorn" },
		["Divine Toll"] = { spellID = 1248644, localizedName = "Göttlicher Glockenschlag", aliases = { "Göttliches Läuten", "Heiliges Läuten" } },
		["Consecration"] = "Weihe",
		["Zealous Spirit"] = { spellID = 1276243, localizedName = "Eifernder Geist", aliases = { "Eifergeist" } },
		["Divine Consecration"] = "Göttliche Weihe",
		["Echoing Darkness"] = { spellID = 1233778, localizedName = "Hallende Dunkelheit", aliases = { "Widerhallende Dunkelheit" }, tooltipKind = "Bossmechanik", tooltipText = "P1-Aura der Wächter. Stapelt hoch, wenn die Wächter nicht sauber im Nahkampf gebunden und kontrolliert werden." },
		["Empowering Darkness"] = { spellID = 1237251, localizedName = "Ermächtigende Dunkelheit", aliases = { "Verstärkende Dunkelheit" }, tooltipKind = "Bossmechanik", tooltipText = "Buff in P2. Entsteht, wenn Boss und Klon nicht sauber getrennt werden." },
		["Rift Slash"] = { spellID = 1246461, localizedName = "Risshieb", tooltipKind = "Bossmechanik", tooltipText = "Tanktreffer in P2. Regelmäßig spotten, damit Stapel und eingehender Schaden beherrschbar bleiben." },
		["Silverstrike"] = { spellID = 1233602, localizedName = "Silberschlagpfeil", aliases = { "Silberschlag" }, tooltipKind = "Bossmechanik", tooltipText = "Silberpfeil-Mechanik des Kampfes. Reinigt Leereffekte, senkt Immunitäten und unterstützt Ziele sowie Adds." },
		["Cosmic Barrier"] = { spellID = 1246918, localizedName = "Kosmische Barriere", tooltipKind = "Bossmechanik", tooltipText = "Schild in P2. Muss sofort gebrochen werden, bevor der Gruppenschaden außer Kontrolle gerät." },
		["Coalesced Form"] = { spellID = 1238672, localizedName = "Verschmolzene Form", aliases = { "Koaleszierte Form" }, tooltipKind = "Bossmechanik", tooltipText = "Gefährlicher Zustand der Leerenbrut. Adds müssen vorher kontrolliert und rechtzeitig getötet werden." },
		["Null Corona"] = { spellID = 1233865, localizedName = "Nullkorona", tooltipKind = "Bossmechanik", tooltipText = "Dispellbarer Debuff. Nur kontrolliert entfernen, nicht wahllos, damit der Raid nicht unnötig belastet wird." },
		["Voidstalker Sting"] = { spellID = 1237038, localizedName = "Leerenpirscherstich", aliases = { "Leerenpirscherstachel" }, tooltipKind = "Bossmechanik", tooltipText = "Großer Heilungscheck. Kann je nach Plan auch über Pfeil-Mechaniken entfernt werden." },
		["Devouring Cosmos"] = { spellID = 1238843, localizedName = "Verschlingender Kosmos", tooltipKind = "Bossmechanik", tooltipText = "P3-Bewegungsmechanik. Mit Feder rechtzeitig in die nächste Scheibe wechseln und nicht zu spät rotieren." },
		["Void Expulsion"] = { spellID = 1255368, localizedName = "Leerenausstoß", tooltipKind = "Bossmechanik", tooltipText = "Zielmechanik, die nach außen gelegt wird. Auf höheren Schwierigkeitsgraden trifft sie zusätzliche Spieler." },
		["Barrage"] = { spellID = 1260000, localizedName = "Sperrfeuer der Leere", aliases = { "Sperrfeuer" }, tooltipKind = "Bossmechanik", tooltipText = "Zwischenphasen-Mechanik mit festen Ansagen. Linien und Pfeilwege müssen sauber gespielt werden." },
		["Silver Residue"] = { spellID = 1233689, localizedName = "Silberrückstände", aliases = { "Silberrückstand" }, tooltipKind = "Bossmechanik", tooltipText = "Effekt auf Wächterzielen, den die Gruppe aktiv mit Silberpfeilen nutzt, um den Phasenablauf zu optimieren." },
		["Grasp of Emptiness"] = { spellID = 1232467, localizedName = "Griff des Nichts", aliases = { "Griff der Leere" }, tooltipKind = "Bossmechanik", tooltipText = "Zielmechanik, die weg vom Raid gelegt wird. Fehlerhafte Platzierung bestraft die Gruppe sofort." },
		["Berstendes Nichts"] = { spellID = 1255378, localizedName = "Berstendes Nichts" },
		["Leerenüberreste"] = { spellID = 1242553, localizedName = "Leerenüberreste" },
		["Unterbrechendes Beben"] = { spellID = 1243743, localizedName = "Unterbrechendes Beben" },
		["Unersättlicher Abgrund"] = { spellID = 1243753, localizedName = "Unersättlicher Abgrund" },
		["Umbralverbindung"] = { spellID = 1233470, localizedName = "Umbralverbindung" },
		["Silberschlagbeschuss"] = { spellID = 1234564, localizedName = "Silberschlagbeschuss" },
		["Umkreisende Materie"] = { spellID = 1245874, localizedName = "Umkreisende Materie" },
		["Ruf der Leere"] = { spellID = 1237837, localizedName = "Ruf der Leere" },
		["Mal des Waldläuferhauptmanns"] = { spellID = 1237614, localizedName = "Mal des Waldläuferhauptmanns", aliases = { "Jägerhauptmannszeichen" } },
		["Silberschlagquerschläger"] = { spellID = 1237729, localizedName = "Silberschlagquerschläger" },
		["Upheaval"] = { spellID = 1246827, localizedName = "Alnstaubaufruhr", aliases = { "Aufruhr", "Alnstaub-Aufruhr" } },
		["Colossal Horrors"] = "Kolossale Schrecken",
		["Alnshroud"] = { spellID = 1270820, localizedName = "Alnschleier" },
		["Fearsome Cry"] = { spellID = 1249017, localizedName = "Furchterregender Schrei", aliases = { "Furchterregenden Schrei", "Fürchterlicher Schrei" } },
		["Essence Bolt"] = { spellID = 1261997, localizedName = "Essenzblitz" },
		["Ravenous Dive"] = { spellID = 1245406, localizedName = "Gefräßiger Sturzflug" },
		["Rift Sickness"] = { spellID = 1250953, localizedName = "Risskrankheit" },
		["Caustic Phlegm"] = { spellID = 1246621, localizedName = "Ätzender Auswurf", aliases = { "Ätzender Schleim", "Ätzenden Schleim", "Ätzenden Auswurf" } },
		["Cannibalized Essence"] = { spellID = 1245844, localizedName = "Verschlungene Essenz", aliases = { "Kannibalisierte Essenz" } },
		["Consuming Miasma"] = { spellID = 1257087, localizedName = "Zehrendes Miasma", aliases = { "Verzehrendes Miasma" } },
		["Alndust Essence"] = { spellID = 1245919, localizedName = "Alnstaubessenz" },
		["Rift Madness"] = { spellID = 1264780, localizedName = "Risswahn", aliases = { "Risswahnsinn" } },
		["Dissonance"] = { spellID = 1267201, localizedName = "Dissonanz" },
		["Leerenlichtkonvergenz"] = { spellID = 1242515, localizedName = "Leerenlichtkonvergenz" },
		["Lichtfeder"] = { spellID = 1241162, localizedName = "Lichtfeder" },
		["Leerenfeder"] = { spellID = 1241163, localizedName = "Leerenfeder" },
		["Lichtsturzschlag"] = { spellID = 1241292, localizedName = "Lichtsturzschlag" },
		["Leerensturzschlag"] = { spellID = 1241339, localizedName = "Leerensturzschlag" },
		["Funken von Belo'ren"] = { spellID = 1241282, localizedName = "Funken von Belo'ren" },
		["Lichteruption"] = { spellID = 1243852, localizedName = "Lichteruption" },
		["Leereneruption"] = { spellID = 1243854, localizedName = "Leereneruption" },
		["Strahlende Echos"] = { spellID = 1242981, localizedName = "Strahlende Echos" },
		["Edikt des Wächters"] = { spellID = 1260763, localizedName = "Edikt des Wächters" },
		["Lichtedikt"] = { spellID = 1241646, localizedName = "Lichtedikt" },
		["Leerenedikt"] = { spellID = 1261218, localizedName = "Leerenedikt" },
		["Ewige Verbrennungen"] = { spellID = 1244344, localizedName = "Ewige Verbrennungen" },
		["Todessturz"] = { spellID = 1246709, localizedName = "Todessturz" },
		["Wiedergeburt"] = { spellID = 1241313, localizedName = "Wiedergeburt" },
		["Aschener Segen"] = { spellID = 1262573, localizedName = "Aschener Segen" },
		["Erfüllte Federkiele"] = { spellID = 1242260, localizedName = "Erfüllte Federkiele" },
		["Brennendes Herz"] = { spellID = 1283067, localizedName = "Brennendes Herz" },
		["Zwielichtkristalle"] = "Zwielichtkristalle",
		["Mitternachtskristalle"] = "Mitternachtskristalle",
		["Dämmerkristall"] = "Dämmerkristall",
		["Kosmische Fraktur"] = "Kosmische Fraktur",
		["Klagelied des Todes"] = "Klagelied des Todes",
		["Totale Finsternis"] = "Totale Finsternis",
		["Lanze des Himmels"] = "Lanze des Himmels",
		["Aufgespießt"] = "Aufgespießt",
		["Dunkelrune"] = "Dunkelrune",
		["Tränen von L'ura"] = { localizedName = "Tränen von L'ura", aliases = { "Tränen von L’ura" } },
		["Naarutrauer"] = "Naarutrauer",
		["Überlastungsladung"] = "Überlastungsladung",
		["Verdunkelt"] = { spellID = 1262055, localizedName = "Verdunkelt" },
		["Lichtentzug"] = { spellID = 1266810, localizedName = "Lichtentzug" },
		["Donnernder Brunnen"] = { spellID = 1254644, localizedName = "Donnernder Brunnen" },
		["Zerschmetterter Himmel"] = { spellID = 1249796, localizedName = "Zerschmetterter Himmel" },
		["Umbral Collapse"] = { spellID = 1249262, localizedName = "Umbralkollaps" },
		["March of the Endless"] = { spellID = 1251583, localizedName = "Marsch der Unendlichen" },
		["Leerenheulen"] = { spellID = 1244917, localizedName = "Leerenheulen" },
		["Leereninfusion"] = { spellID = 1245960, localizedName = "Leereninfusion" },
		["Leerenaussetzung"] = { spellID = 1250832, localizedName = "Leerenaussetzung" },
		["Gebrochene Projektion"] = { spellID = 1254081, localizedName = "Gebrochene Projektion" },
		["Schattenfraktur"] = { spellID = 1254088, localizedName = "Schattenfraktur" },
		["Quälendes Extrakt"] = { spellID = 1245592, localizedName = "Quälendes Extrakt", aliases = { "Quälender Extrakt" } },
		["Destabilisierende Stöße"] = { spellID = 1271577, localizedName = "Destabilisierende Stöße", aliases = { "Destabilisierende Schläge" } },
		["Zertrümmerndes Zwielicht"] = { spellID = 1253032, localizedName = "Zertrümmerndes Zwielicht", aliases = { "Zerschmetterndes Zwielicht" } },
		["Zwielichtstacheln"] = { spellID = 1251213, localizedName = "Zwielichtstacheln" },
		["Umbrastrahlen"] = { spellID = 1260015, localizedName = "Umbrastrahlen" },
		["Entsetzlicher Atem"] = "Entsetzlicher Atem",
		["Nullzonenimplosion"] = { spellID = 1252157, localizedName = "Nullzonenimplosion", aliases = { "Nullzonen-Explosion" } },
		["Strahlende Barriere"] = "Strahlende Barriere",
		["Leerenblitz"] = { spellID = 1245175, localizedName = "Leerenblitz" },
		["Ungebundener Schatten"] = { spellID = 1251686, localizedName = "Ungebundener Schatten" },
		["Düsternisberührt"] = { spellID = 1245554, localizedName = "Düsternisberührt" },
		["Mitternachtsmanifestation"] = { spellID = 1255763, localizedName = "Mitternachtsmanifestation" },
		["Geschwächt"] = { spellID = 1270852, localizedName = "Geschwächt" },
		["Kosmose"] = { spellID = 1263623, localizedName = "Kosmose" },
		["Windende Obskurität"] = { spellID = 1250686, localizedName = "Windende Obskurität" },
		["Despotischer Befehl"] = { spellID = 1248697, localizedName = "Despotischer Befehl" },
		["Drückende Finsternis"] = { spellID = 1248709, localizedName = "Drückende Finsternis", aliases = { "Erdrückende Dunkelheit" } },
		["Dunkle Strahlung"] = { spellID = 1250991, localizedName = "Dunkle Strahlung" },
		["Finales Urteil"] = { spellID = 1251812, localizedName = "Letztes Urteil", aliases = { "Finales Urteil" } },
		["Schild der Rechtschaffenen"] = { spellID = 1251859, localizedName = "Schild der Rechtschaffenen" },
		["Schild des Rächers"] = { spellID = 1246485, localizedName = "Schild des Rächers" },
		["Heiliges Läuten"] = { spellID = 1248644, localizedName = "Heiliges Läuten", aliases = { "Göttlicher Glockenschlag", "Göttliches Läuten" } },
		["Heiliger Tribut"] = { spellID = 1246749, localizedName = "Heiliger Tribut" },
		["Göttlicher Sturm"] = "Göttlicher Sturm",
		["Elekkansturm"] = "Elekkansturm",
		["Mythische Weihe"] = "Mythische Weihe",
		["Verderbende Essenz"] = { spellID = 1241520, localizedName = "Verderbende Essenz" },
		["Singularitätsausbruch"] = { spellID = 1235622, localizedName = "Singularitätsausbruch" },
		["Gravitationskollaps"] = { spellID = 1239089, localizedName = "Gravitationskollaps", aliases = { "Schwerkraftkollaps" } },
		["Dunkle Hand"] = { spellID = 1233787, localizedName = "Dunkle Hand" },
		["Flüchtiger Riss"] = { spellID = 1238206, localizedName = "Flüchtiger Riss", aliases = { "Flüchtige Risse" } },
		["Jägerhauptmannszeichen"] = { spellID = 1237614, localizedName = "Jägerhauptmannszeichen", aliases = { "Mal des Waldläuferhauptmanns" } },
		["Leerenfeuerstoß"] = "Leerenfeuerstoß",
		["Aspekt des Endes"] = { spellID = 1239080, localizedName = "Aspekt des Endes" },
		["Stellaremission"] = { spellID = 1234569, localizedName = "Stellaremission", aliases = { "Sternenemission" } },
		["Dunkler Rausch"] = { spellID = 1238708, localizedName = "Dunkler Rausch" },
		["Alnsicht"] = { spellID = 1245698, localizedName = "Alnsicht" },
		["Rissvulnerabilität"] = { spellID = 1253744, localizedName = "Rissvulnerabilität", aliases = { "Rissanfälligkeit" } },
		["Reißendes Schlitzen"] = { spellID = 1272689, localizedName = "Reißendes Schlitzen" },
		["Verschlingen"] = { spellID = 1245396, localizedName = "Verschlingen", aliases = { "Verzehren" } },
		["Verderbte Vernichtung"] = { spellID = 1245452, localizedName = "Verderbte Vernichtung", aliases = { "Verderbte Verwüstung" } },
		["Arkanes Schocken"] = { spellID = 1250553, localizedName = "Arkanes Schocken" },
		["Leylinienmatrix"] = { spellID = 1251626, localizedName = "Leylinienmatrix" },
		["Ladungsrückstoß"] = { spellID = 1251772, localizedName = "Ladungsrückstoß" },
		["Fluxkollaps"] = { spellID = 1264040, localizedName = "Fluxkollaps" },
		["Arkanfleck"] = { spellID = 1262630, localizedName = "Arkanfleck" },
		["Kernfunkendetonation"] = { spellID = 1257509, localizedName = "Kernfunkendetonation" },
		["Funkenbrand"] = { spellID = 1276485, localizedName = "Funkenbrand" },
		["Verdunkelnder Schritt"] = { spellID = 1249014, localizedName = "Verdunkelnder Schritt" },
		["Nullvorhut"] = { spellID = 1252703, localizedName = "Nullvorhut" },
		["Neutralisieren"] = { spellID = 1282722, localizedName = "Neutralisieren" },
		["Dämmerschrecken"] = { spellID = 1282723, localizedName = "Dämmerschrecken" },
		["Umbralpeitsche"] = { spellID = 1247937, localizedName = "Umbralpeitsche" },
		["Leerenschnitt"] = { spellID = 1252828, localizedName = "Leerenschnitt" },
		["Lichtgezeichnete Flamme"] = { spellID = 1247976, localizedName = "Lichtgezeichnete Flamme" },
		["Sengende Verwundung"] = { spellID = 1253950, localizedName = "Sengende Verwundung" },
		["Strahlende Narbe"] = { spellID = 1255389, localizedName = "Strahlende Narbe" },
		["Strahlende Zerstreuung"] = { spellID = 1253848, localizedName = "Strahlende Zerstreuung" },
		["Gespiegeltes Verwunden"] = { spellID = 1266713, localizedName = "Gespiegeltes Verwunden" },
		["Göttliche List"] = { spellID = 1257613, localizedName = "Göttliche List" },
		["Kernbelastung"] = { spellID = 1271511, localizedName = "Kernbelastung" },
		["Aufladeprotokoll"] = { spellID = 474345, localizedName = "Aufladeprotokoll" },
		["Energiekugeln"] = { spellID = 474396, localizedName = "Energiekugeln", aliases = { "Energiekugel" } },
		["Arkane Ermächtigung"] = { spellID = 474407, localizedName = "Arkane Ermächtigung" },
		["Instabile Energie"] = { spellID = 1243905, localizedName = "Instabile Energie" },
		["Arkane Überreste"] = { spellID = 1214089, localizedName = "Arkane Überreste" },
		["Unterdrückungsbereich"] = { spellID = 1224903, localizedName = "Unterdrückungsbereich" },
		["Runenmal"] = { spellID = 1225792, localizedName = "Runenmal" },
		["Rückkopplung"] = { spellID = 1225135, localizedName = "Rückkopplung" },
		["Welle der Stille"] = { spellID = 1225193, localizedName = "Welle der Stille" },
		["Beschleunigender Zauberschutz"] = { spellID = 1248689, localizedName = "Beschleunigender Zauberschutz" },
		["Nullreaktion"] = { spellID = 1246446, localizedName = "Nullreaktion" },
		["Verdreifachung"] = { spellID = 1223847, localizedName = "Verdreifachung" },
		["Astraler Griff"] = { spellID = 1224299, localizedName = "Astraler Griff" },
		["Kosmische Strahlung"] = { spellID = 1224401, localizedName = "Kosmische Strahlung" },
		["Kosmischer Stich"] = { spellID = 1284958, localizedName = "Kosmischer Stich" },
		["Leerenabsonderung"] = { spellID = 1224100, localizedName = "Leerenabsonderung" },
		["Neurale Verbindung"] = { spellID = 1253707, localizedName = "Neurale Verbindung" },
		["Instabile Leerenessenz"] = { spellID = 1215087, localizedName = "Instabile Leerenessenz" },
		["Leerenzerstörung"] = { spellID = 1215161, localizedName = "Leerenzerstörung" },
		["Verschlingende Entropie"] = { spellID = 1215897, localizedName = "Verschlingende Entropie" },
		["Entropiekugeln"] = { spellID = 1269631, localizedName = "Entropiekugeln", aliases = { "Entropiekugel" } },
		["Wuchtiges Fragment"] = { spellID = 1280113, localizedName = "Wuchtiges Fragment" },
		["Umbralsplitter"] = { spellID = 1284627, localizedName = "Umbralsplitter" },
		["Flammender Aufwind"] = { spellID = 466556, localizedName = "Flammender Aufwind" },
		["Flammender Wirbelsturm"] = { spellID = 469633, localizedName = "Flammender Wirbelsturm" },
		["Brennende Bö"] = { spellID = 465904, localizedName = "Brennende Bö" },
		["Sengender Schnabel"] = { spellID = 466064, localizedName = "Sengender Schnabel" },
		["Feueratem"] = { spellID = 1217762, localizedName = "Feueratem" },
		["Zerrissenes Band"] = { spellID = 1219551, localizedName = "Zerrissenes Band" },
		["Entkräftendes Kreischen"] = { spellID = 472736, localizedName = "Entkräftendes Kreischen" },
		["Fluch der Dunkelheit"] = { spellID = 474105, localizedName = "Fluch der Dunkelheit" },
		["Versammelndes Gebrüll"] = { spellID = 472043, localizedName = "Versammelndes Gebrüll" },
		["Klingensturm"] = { spellID = 470963, localizedName = "Klingensturm" },
		["Schildwall"] = { spellID = 1250851, localizedName = "Schildwall" },
		["Toben"] = { spellID = 467620, localizedName = "Toben" },
		["Tollkühner Sprung"] = { spellID = 472081, localizedName = "Tollkühner Sprung" },
		["Fallendes Geröll"] = { spellID = 1283357, localizedName = "Fallendes Geröll" },
		["Drohruf"] = { spellID = 1253026, localizedName = "Drohruf" },
		["Zielscheibenwindstoß"] = { spellID = 468429, localizedName = "Zielscheibenwindstoß" },
		["Wogender Wind"] = { spellID = 468442, localizedName = "Wogender Wind" },
		["Pfeilhagel"] = { spellID = 472556, localizedName = "Pfeilhagel" },
		["Turbulente Pfeile"] = { spellID = 1253977, localizedName = "Turbulente Pfeile", aliases = { "Turbulenter Pfeil" } },
		["Sturmschlitzer"] = { spellID = 472662, localizedName = "Sturmschlitzer" },
		["Blitzbö"] = { spellID = 474528, localizedName = "Blitzbö" },
		["Böenschuss"] = { spellID = 1253986, localizedName = "Böenschuss" },
		["Stürmischer Seelenquell"] = { spellID = 1282932, localizedName = "Stürmischer Seelenquell" },
		["Sturmböensprung"] = { spellID = 1216042, localizedName = "Sturmböensprung" },
	},
	STREAMER_PLANNER_TITLE = "Gruppenplaner",
	STREAMER_PLANNER_DESC = "Ein kleines transparentes Overlay für Stream-Situationen, in dem du Zusagen schnell auf feste Dungeon- oder Raid-Slots verteilen kannst.",
	STREAMER_PLANNER_USAGE_HINT = "Klick in Vorschau oder Overlay auf einen Slot, trage den Namen ein und bestätige mit Enter. Rechtsklick auf einen Slot leert ihn direkt wieder.",
	STREAMER_PLANNER_PREVIEW_HINT = "Die Vorschau spiegelt dieselben Daten wie das Overlay. Du kannst beide Ansichten direkt zum Eintragen verwenden.",
	STREAMER_PLANNER_SETTINGS_HINT = "Hier steuerst du Modus, Sichtbarkeit und Position des Planungs-Overlays für den Stream.",
	STREAMER_PLANNER_SHOW_OVERLAY = "Planungs-Overlay anzeigen",
	STREAMER_PLANNER_SHOW_OVERLAY_HINT = "Blendet das transparente Overlay ein oder aus, ohne die eingetragenen Namen zu verlieren.",
	STREAMER_PLANNER_LOCK_OVERLAY = "Planungs-Overlay fixieren",
	STREAMER_PLANNER_LOCK_OVERLAY_HINT = "Sperrt das Overlay an seiner aktuellen Position, damit es im Stream nicht versehentlich verschoben wird.",
	STREAMER_PLANNER_MODE = "Planungsmodus",
	STREAMER_PLANNER_MODE_HINT = "Wechselt zwischen einem 5er-Dungeonaufbau und vier Raid-Gruppen mit je fünf Plätzen.",
	STREAMER_PLANNER_MODE_DUNGEON = "Dungeon",
	STREAMER_PLANNER_MODE_RAID = "Raid",
	STREAMER_PLANNER_DESTINATION = "Ziel",
	STREAMER_PLANNER_DESTINATION_HINT = "Hier schreibst du direkt rein, wohin es geht, zum Beispiel den Raidnamen, die Instanz oder einen Treffpunkt.",
	STREAMER_PLANNER_DESTINATION_EMPTY = "Noch kein Ziel eingetragen",
	STREAMER_PLANNER_DESTINATION_MANUAL = "Manuell eingeben",
	STREAMER_PLANNER_DESTINATION_CATEGORY = "Pool",
	STREAMER_PLANNER_DESTINATION_SUGGESTION = "Vorschlag",
	STREAMER_PLANNER_DESTINATION_CATEGORY_S1 = "S1",
	STREAMER_PLANNER_DESTINATION_CATEGORY_DELVES = "Tiefen",
	STREAMER_PLANNER_DESTINATION_CATEGORY_MIDNIGHT = "Midnight",
	STREAMER_PLANNER_DESTINATION_CATEGORY_RAIDS = "Raids",
	STREAMER_PLANNER_DESTINATION_EDIT = "Ziel bearbeiten",
	STREAMER_PLANNER_DESTINATION_EDIT_HINT = "Trage hier ein, wohin die Gruppe oder der Raid geplant ist.",
	STREAMER_PLANNER_DESTINATION_KEYSTONE = "Keystufe",
	STREAMER_PLANNER_DESTINATION_S1_MAGISTERS_TERRACE = "Magisterterrasse",
	STREAMER_PLANNER_DESTINATION_S1_MAISARA_CAVERNS = "Maisara-Höhlen",
	STREAMER_PLANNER_DESTINATION_S1_NEXUS_POINT_XENAS = "Nexuspunkt Xenas",
	STREAMER_PLANNER_DESTINATION_S1_WINDRUNNER_SPIRE = "Windläuferturm",
	STREAMER_PLANNER_DESTINATION_S1_ALGETHAR_ACADEMY = "Akademie von Algeth'ar",
	STREAMER_PLANNER_DESTINATION_S1_PIT_OF_SARON = "Grube von Saron",
	STREAMER_PLANNER_DESTINATION_S1_SEAT_OF_THE_TRIUMVIRATE = "Sitz des Triumvirats",
	STREAMER_PLANNER_DESTINATION_S1_SKYREACH = "Himmelsnadel",
	STREAMER_PLANNER_DESTINATION_DELVE_ATAL_AMAN = "Atal'Aman",
	STREAMER_PLANNER_DESTINATION_DELVE_COLLEGIATE_CALAMITY = "Akademisches Chaos",
	STREAMER_PLANNER_DESTINATION_DELVE_DEN_OF_ECHOES = "Hort der Echos",
	STREAMER_PLANNER_DESTINATION_DELVE_PARHELION_PLAZA = "Parhelionplatz",
	STREAMER_PLANNER_DESTINATION_DELVE_SHADOWGUARD_POINT = "Schattenwachtposten",
	STREAMER_PLANNER_DESTINATION_DELVE_SUNKILLER_SANCTUM = "Sonnenkillersanktum",
	STREAMER_PLANNER_DESTINATION_DELVE_THE_DARKWAY = "Der Dunkelgang",
	STREAMER_PLANNER_DESTINATION_DELVE_THE_GRUDGE_PIT = "Die Grollgrube",
	STREAMER_PLANNER_DESTINATION_DELVE_THE_GULF_OF_MEMORY = "Der Golf der Erinnerung",
	STREAMER_PLANNER_DESTINATION_DELVE_THE_SHADOW_ENCLAVE = "Die Schattenenklave",
	STREAMER_PLANNER_DESTINATION_DELVE_TORMENTS_RISE = "Turm der Qualen",
	STREAMER_PLANNER_DESTINATION_DELVE_TWILIGHT_CRYPTS = "Zwielichtkrypten",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_WINDRUNNER_SPIRE = "Windläuferturm",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_MAGISTERS_TERRACE = "Magisterterrasse",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_MURDER_ROW = "Mördergasse",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_DEN_OF_NALORAKK = "Hort von Nalorakk",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_MAISARA_CAVERNS = "Maisara-Höhlen",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_THE_BLINDING_VALE = "Das blendende Tal",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_VOIDSCAR_ARENA = "Arena der Leerennarbe",
	STREAMER_PLANNER_DESTINATION_MIDNIGHT_NEXUS_POINT_XENAS = "Nexuspunkt Xenas",
	STREAMER_PLANNER_DESTINATION_RAID_VOIDSPIRE = "Leerspitz",
	STREAMER_PLANNER_DESTINATION_RAID_DREAMRIFT = "Traumriss",
	STREAMER_PLANNER_DESTINATION_RAID_MARCH_ON_QUEL_DANAS = "Marsch auf Quel'Danas",
	STREAMER_PLANNER_CLASS = "Klasse",
	STREAMER_PLANNER_CLASS_NONE = "Keine Klasse",
	STREAMER_PLANNER_SPEC = "Spezialisierung",
	STREAMER_PLANNER_SPEC_NONE = "Keine Spec",
	STREAMER_PLANNER_SCALE = "Overlay-Skalierung",
	STREAMER_PLANNER_SCALE_HINT = "Passt die Größe des transparenten Overlays an, ohne Einträge oder Positionen zu verändern.",
	STREAMER_PLANNER_TIMER_DURATION = "Timerdauer",
	STREAMER_PLANNER_TIMER_DURATION_VALUE = "%d Min.",
	STREAMER_PLANNER_TIMER_DURATION_HINT = "Legt fest, mit welcher Dauer der Stream-Timer startet und worauf Reset zurücksetzt.",
	STREAMER_PLANNER_RESET_POSITION_HINT = "Setzt das Overlay zurück in die Ausgangsposition nahe der Bildschirmmitte.",
	STREAMER_PLANNER_CLEAR_LAYOUT = "Aktuelles Layout leeren",
	STREAMER_PLANNER_CLEAR_LAYOUT_HINT = "Entfernt alle Namen nur aus dem aktuell gewählten Dungeon- oder Raid-Modus.",
	STREAMER_PLANNER_CLEAR_ALL = "Alles leeren",
	STREAMER_PLANNER_CLEAR_ALL_HINT = "Löscht Dungeon- und Raid-Planung komplett, falls du einen frischen Stand brauchst.",
	STREAMER_PLANNER_OVERLAY_CLEAR_ALL = "Alle leeren",
	STREAMER_PLANNER_EDIT_HINT = "Tipp: Linksklick bearbeitet einen Slot, Rechtsklick leert ihn sofort. So kannst du Meldungen aus dem Stream ohne Umwege sortieren.",
	STREAMER_PLANNER_OVERLAY_TITLE = "Gruppenplaner",
	STREAMER_PLANNER_OVERLAY_CLOSE_TOOLTIP = "Overlay ausblenden",
	STREAMER_PLANNER_OVERLAY_CLOSE_TOOLTIP_HINT = "Blendet den Gruppenplaner aus. Über die Modulseite kannst du ihn jederzeit wieder einblenden.",
	STREAMER_PLANNER_OVERLAY_SETTINGS_BUTTON = "Menü",
	STREAMER_PLANNER_OVERLAY_SETTINGS_TOOLTIP = "Moduleinstellungen öffnen",
	STREAMER_PLANNER_OVERLAY_SETTINGS_TOOLTIP_HINT = "Springt direkt zur Gruppenplaner-Seite im Addonfenster.",
	STREAMER_PLANNER_TIMER = "Timer",
	STREAMER_PLANNER_TIMER_START = "Start",
	STREAMER_PLANNER_TIMER_PAUSE = "Pause",
	STREAMER_PLANNER_TIMER_RESET = "Reset",
	STREAMER_PLANNER_TIMER_RUNNING = "Läuft",
	STREAMER_PLANNER_TIMER_PAUSED = "Pausiert",
	STREAMER_PLANNER_TIMER_EXPIRED = "Zeit abgelaufen: Randoms suchen",
	STREAMER_PLANNER_EMPTY_SLOT = "frei",
	STREAMER_PLANNER_SLOT_EDIT = "Slot bearbeiten",
	STREAMER_PLANNER_SLOT_EDIT_HINT = "Trage hier den Namen oder eine kurze Notiz für diesen Platz ein.",
	STREAMER_PLANNER_SAVE_SLOT = "Speichern",
	STREAMER_PLANNER_CLEAR_SLOT = "Leeren",
	STREAMER_PLANNER_ROLE_TANK = "Tank",
	STREAMER_PLANNER_ROLE_HEALER = "Heiler",
	STREAMER_PLANNER_ROLE_DPS1 = "DPS 1",
	STREAMER_PLANNER_ROLE_DPS2 = "DPS 2",
	STREAMER_PLANNER_ROLE_DPS3 = "DPS 3",
	STREAMER_PLANNER_RAID_SUMMARY = "Tanks: %d   Heiler: %d   DDs: %d",
	STREAMER_PLANNER_RAID_GROUP = "Gruppe %d",
	STREAMER_PLANNER_RAID_SLOT = "G%d / %d",
	STREAMER_PLANNER_QUEUE_TITLE = "Whisper-Queue",
	STREAMER_PLANNER_QUEUE_HINT = "Nur Whisper mit !enter oder !inv landen hier. Rolle und Spec werden ergänzt, wenn passende Daten verfügbar sind. Rechtsklick entfernt Whisper-Einträge. AutoInv greift in Dungeon und Raid, aber nur wenn der Spieler bereits per !enter bekannt ist. FullInv bleibt Raid-only.",
	STREAMER_PLANNER_AUTO_INVITE_WHISPER = "!inv automatisch einladen",
	STREAMER_PLANNER_FULL_INVITE = "FullInv",
	STREAMER_PLANNER_QUEUE_EMPTY = "Noch keine Whisper-Einträge vorhanden.",
	STREAMER_PLANNER_SPEC_PROMPT_TITLE = "Spec auswählen",
	STREAMER_PLANNER_SPEC_PROMPT_HINT = "Jemand möchte per !enter in die Planung. Wähle die Spezialisierung aus, damit der passende Slot gesetzt wird.",
	STREAMER_PLANNER_SPEC_PROMPT_CLASS = "Klasse: %s",
	STREAMER_PLANNER_SPEC_PROMPT_LATER = "Später",
	STREAMER_PLANNER_SPEC_PROMPT_REMOVE = "Entfernen",
	STREAMER_PLANNER_SOURCE_LFG = "LFG",
	STREAMER_PLANNER_SOURCE_WHISPER_ENTER = "Whisper !enter",
	STREAMER_PLANNER_SOURCE_WHISPER_INV = "Whisper !inv",
	STREAMER_PLANNER_STATUS_GROUPED = "In Gruppe",
	STREAMER_PLANNER_STATUS_INVITED = "Eingeladen",
	STREAMER_PLANNER_STATUS_WHISPER_ENTER = "Wartet auf Invite",
	STREAMER_PLANNER_STATUS_WHISPER_INV = "Will Invite",
	MARKER_BAR_DESC = "Eine kompakte Overlay-Leiste für Zielmarkierungen und Bodenmarker. Normaler Klick markiert dein aktuelles Ziel, Shift-Klick setzt die passende Bodenmarke.",
	MARKER_BAR_USAGE_HINT = "Normalklick setzt die Zielmarkierung. Shift-Klick aktiviert die passende Bodenmarke. Die Leiste bleibt bewusst klein, transparent und direkt im Blickfeld.",
	MARKER_BAR_PERMISSION_HINT = "Hinweis: Markierungen funktionieren nur, wenn dir die Gruppe oder der Schlachtzug das Setzen von Markern erlaubt.",
	MARKER_BAR_SHOW_OVERLAY = "Markerleiste anzeigen",
	MARKER_BAR_LOCK_OVERLAY = "Markerleiste fixieren",
	MARKER_BAR_INSTANCE_ONLY = "Nur in Dungeon/Raid anzeigen",
	MARKER_BAR_INSTANCE_ONLY_HINT = "Blendet die Markerleiste automatisch aus, solange du nicht in einem Dungeon oder Schlachtzug bist.",
	MARKER_BAR_SCALE = "Skalierung",
	MARKER_BAR_SCALE_HINT = "Passt die Größe der transparenten Leiste an, ohne die Belegung der Marker zu verändern.",
	MARKER_BAR_RESET_POSITION = "Leistenposition zurücksetzen",
	MARKER_BAR_OVERLAY_HINT = "Klick = Ziel markieren | Shift = Bodenmarker",
	MARKER_BAR_DRAG_HINT = "Zum Verschieben die Leiste entsperren und am Rand ziehen.",
	CAMERA_DISTANCE_HINT = "Setzt die maximale Kamera-Distanz auf den Standardwert oder auf den maximalen Wert und zieht die Einstellung nach dem Einloggen erneut nach.",
	CURRENT_SETTING = "Aktuelle Einstellung:",
	CAMERA_DISTANCE_MAX = "Max Distance",
	CAMERA_DISTANCE_QUESTION = "?",
	CAMERA_DISTANCE_MODE_MAX = "max",
	CAMERA_DISTANCE_MODE_STANDARD = "standard",
	CAMERA_DISTANCE_MODE_CUSTOM = "custom",
	CAMERA_DISTANCE_MODE_UNKNOWN = "unknown",
	CAMERA_DISTANCE_STATUS_MAX = "Max Distance (%s)",
	CAMERA_DISTANCE_STATUS_STANDARD = "Standard (%s)",
	CAMERA_DISTANCE_STATUS_CUSTOM = "Benutzerdefiniert (%s)",
	CAMERA_DISTANCE_STATUS_UNKNOWN = "Unbekannt",
	AUTOREPAIR_GUILD_DONE = "Beavis QoL: Reparatur über die Gilde durchgeführt.",
	AUTOREPAIR_DONE = "Beavis QoL: Reparatur für %s durchgeführt.",
	AUTOSELL_UNKNOWN_ITEM = "Unbekanntes Item",
	AUTOSELL_SUMMARY = "Beavis QoL: %d Junk-Item(s) verkauft für %s.",
	STANDARD = "Standard",

	VERSIONS_INFO_TITLE = "%s - Versionsinfos",
	VERSIONS_INFO_DESC = "Hier findest du die wichtigsten Infos zur installierten Version und einen Ingame-Hinweis, wenn dir jemand mit einer höheren BeavisQoL-Version begegnet.",
	CURRENT_VERSION = "Aktuelle Version",
	RELEASE_DATE = "Release-Datum",
	PROGRAMMER = "Programmierer",
	SUPPORTED_GAME_VERSION = "Unterstützte Spielversion",
	TOC_VERSION = "TOC Version",
	VERSION_CHECK = "Versionsabgleich",
	VERSION_CHECK_AVAILABLE = "Neue Version verfügbar: %s",
	VERSION_CHECK_SEEN_AT = "Gesehen bei %s über %s. Installiert ist derzeit %s.",
	VERSION_CHECK_CHANNEL = "einen Gruppenkanal",
	VERSION_CHECK_HINT = "Hinweis: Der Vergleich funktioniert über Gruppe, Raid, Instanzchat oder Gilde und nicht direkt über GitHub.",
	VERSION_CHECK_CURRENT = "Aktuell",
	VERSION_CHECK_CURRENT_TEXT = "Sobald ein Update verfügbar ist, bekommst du hier eine Information.",
	VERSION_CHECK_CURRENT_SUBTEXT = "Installiert: %s | Release-Datum: %s",
	VERSION_COMPARE_NOW = "Jetzt abgleichen",
	VERSION_RELEASE_LINK = "Release-Link",
	CONTACT_TITLE = "Mithelfen & Kontakt",
	CONTACT_TEXT = "Wenn du Feedback geben oder neue Ideen einreichen möchtest, kannst du direkt über die Beavismania-Webseite Kontakt aufnehmen.",
	SEND_FEEDBACK = "Feedback senden",
	SUBMIT_IDEA = "Idee einschicken",
	RELEASES_POPUP = "BeavisQoL Releases",
	FEEDBACK_POPUP = "Feedback senden",
	IDEA_POPUP = "Idee einschicken",

	DAMAGE_TEXT_DESC = "Hier kannst du die Blizzard-Schadenszahlen optisch anpassen. Schrift und Bewegungsverhalten werden direkt über die vorhandenen Combat-Text-Systeme umgestellt.",
	DAMAGE_TEXT_CONFLICT = "Konflikt: NiceDamage ist geladen und kann deinen Kampftext überschreiben. Bitte NiceDamage für diesen Charakter deaktivieren, wenn du Beavis QoL nutzen willst.",
	DAMAGE_TEXT_ENABLE_TITLE = "Eigene Kampftextanpassungen verwenden",
	DAMAGE_TEXT_ENABLE_HINT = "Ersetzt die Blizzard-Kampftext-Schrift und passt die Bewegung der Schadenszahlen über Scale, Gravity und Ramp Duration an.",
	DAMAGE_TEXT_APPEARANCE_HINT = "Eigene Fonts können manuell über den Fonts-Ordner des Addons hinzugefügt werden und stehen danach direkt in der Auswahl zur Verfügung.",
	DAMAGE_TEXT_RESTART_HINT = "Nach einem Font-Wechsel muss das Spiel komplett beendet und neu gestartet werden, damit die Änderung sicher übernommen wird.",

	LFG_DESC = "Hier findest du Komfortfunktionen für die Premade-Gruppensuche.",
	FLAGS_TITLE = "Länderflaggen",
	FLAGS_HINT = "Zeigt in der Premade-Gruppensuche neben Bewerbern eine kleine Flagge auf Basis ihres Realms an.",
	LFG_LISTING_PRESET_TITLE = "Listing-Presets",
	LFG_LISTING_PRESET_HINT = "Speichert Vorgaben für deine eigene Gruppenanzeige. Das Dropdown wird automatisch gesetzt; für Name und Details blendet BeavisQoL Kopierknöpfe neben den geschützten Blizzard-Textfeldern ein.",
	LFG_LISTING_PRESET_ENABLE = "Listing-Preset-Helfer aktivieren",
	LFG_LISTING_PRESET_ENABLE_HINT = "Wenn aktiv, setzt BeavisQoL die gespeicherte Dropdown-Vorgabe und zeigt Kopierknöpfe für die geschützten Textfelder im Blizzard-Erstellfenster.",
	LFG_LISTING_NAME_SUFFIX = "Name-Presets",
	LFG_LISTING_NAME_SUFFIX_HINT = "Speichert Texte, die an den vom Spiel vorbefüllten Namen angehängt werden. Im Erstellfenster öffnet der Blatt-Knopf die Presets per Menü.",
	LFG_LISTING_DETAILS = "Details-Presets",
	LFG_LISTING_DETAILS_HINT = "Speichert Detail-Blöcke als Vorlagen. Im Erstellfenster öffnet der Blatt-Knopf die Presets per Menü.",
	LFG_LISTING_PRESET_SLOT = "Preset %d",
	LFG_LISTING_PRESET_MENU_LABEL = "Preset %d: %s",
	LFG_LISTING_COPY_NAME_LABEL = "Name-Preset",
	LFG_LISTING_COPY_DETAILS_LABEL = "Details-Preset",
	LFG_LISTING_COPY_NAME_TOOLTIP = "Name-Preset kopieren",
	LFG_LISTING_COPY_NAME_TOOLTIP_DESC = "Öffnet den aktuellen Gruppennamen inklusive gespeicherter Ergänzung in einem markierten Copy-Feld. Danach mit Strg+C kopieren und im Blizzard-Feld einfügen.",
	LFG_LISTING_COPY_DETAILS_TOOLTIP = "Details-Preset kopieren",
	LFG_LISTING_COPY_DETAILS_TOOLTIP_DESC = "Öffnet deinen gespeicherten Detail-Block in einem markierten Copy-Feld. Danach mit Strg+C kopieren und im Blizzard-Feld einfügen.",
	LFG_LISTING_COPY_DIALOG_TITLE = "%s kopieren",
	LFG_LISTING_COPY_DIALOG_HINT = "Der Text ist markiert. Drücke Strg+C zum Kopieren und füge ihn danach im Blizzard-Feld ein.",
	LFG_LISTING_COPY_EMPTY = "Kein Preset-Text zum Kopieren gespeichert.",
	LFG_LISTING_SETTINGS_BUTTON_TOOLTIP = "BeavisQoL-Presets",
	LFG_LISTING_SETTINGS_BUTTON_TOOLTIP_DESC = "Öffnet direkt die Gruppensuche-Einstellungen für Name-, Details- und Dropdown-Presets.",
	LFG_LISTING_PLAYSTYLE = "Dropdown-Vorgabe",
	LFG_LISTING_PLAYSTYLE_HINT = "Wählt beim Erstellen automatisch die hier gespeicherte Dropdown-Option aus. \"Keine Vorgabe\" lässt das Blizzard-Standardverhalten unverändert.",
	LFG_LISTING_PLAYSTYLE_NONE = "Keine Vorgabe",
	LFG_LISTING_PLAYSTYLE_LEARNING = "Lernen",
	LFG_LISTING_PLAYSTYLE_RELAXED = "Entspannt",
	LFG_LISTING_PLAYSTYLE_COMPETITIVE = "Kompetitiv",
	LFG_LISTING_PLAYSTYLE_EXPERT = "Beförderung angeboten",
	EASY_LFG_TITLE = "SmartLFG",
	EASY_LFG_HINT = "Blendet für deine eigene Gruppenanzeige ein kleines transparentes Applicant-Overlay ein, damit du Bewerber ohne das große Blizzard-Fenster sehen und einladen kannst.",
	EASY_LFG_SHOW_OVERLAY = "SmartLFG-Overlay aktivieren",
	EASY_LFG_SHOW_OVERLAY_HINT = "Zeigt das kompakte Applicant-Fenster automatisch an, sobald deine eigene Gruppe aktiv ist.",
	EASY_LFG_LOCK_OVERLAY = "SmartLFG-Overlay fixieren",
	EASY_LFG_LOCK_OVERLAY_HINT = "Sperrt die Position des kleinen Applicant-Fensters, damit es nicht versehentlich verschoben wird.",
	EASY_LFG_SCALE = "Overlay-Skalierung",
	EASY_LFG_SCALE_HINT = "Passt die Größe des SmartLFG-Fensters an, ohne Einträge oder Position zu verändern.",
	EASY_LFG_BACKGROUND_ALPHA = "Hintergrund-Transparenz",
	EASY_LFG_TEXT_SCALE = "Text-Skalierung",
	EASY_LFG_TEXT_SCALE_HINT = "Passt nur die Schriftgröße im SmartLFG-Overlay an, unabhängig von der Fenstergröße.",
	EASY_LFG_BACKGROUND_ALPHA_HINT = "Steuert, wie deutlich der Hintergrund des Applicant-Fensters sichtbar bleibt.",
	EASY_LFG_RESET_HINT = "Setzt das SmartLFG-Fenster zurück in seine Startposition rechts neben deiner Figur.",
	INVITE_TIMER_TITLE = "Einladungs-Timer",
	INVITE_TIMER_HINT = "Fügt direkt in Bereitschaftsfenstern wie Dungeonbrowser, LFR, Arena und Schlachtfeld eine kleine Countdown-Leiste mit Sekundenanzeige ein.",
	INVITE_TIMER_ENABLED = "Einladungs-Timer anzeigen",
	INVITE_TIMER_ENABLED_HINT = "Zeigt in unterstützten Einladungsfenstern eine kompakte Countdown-Leiste, bis die Einladung abläuft.",
	INVITE_TIMER_COUNTDOWN_SOUND = "Countdown-Sound ab 5 Sekunden",
	INVITE_TIMER_COUNTDOWN_SOUND_HINT = "Spielt für die letzten fünf Sekunden eine Sprachansage mit five, four, three, two, one ab.",
	EASY_LFG_OVERLAY_TITLE = "SmartLFG",
	EASY_LFG_OVERLAY_SUMMARY = "%d Bewerber | %d Spieler",
	EASY_LFG_OVERLAY_EMPTY = "Noch keine Bewerber in der Warteschlange.",
	EASY_LFG_OVERLAY_NO_GROUP = "SmartLFG erscheint automatisch, sobald deine eigene Gruppe aktiv ist.",
	EASY_LFG_OVERLAY_NO_GROUP_SHORT = "Keine aktive Gruppe",
	EASY_LFG_OVERLAY_MORE = "+%d weitere Spieler nicht angezeigt",
	EASY_LFG_OVERLAY_RESIZE_HINT = "Unten rechts ziehen zum Skalieren der Fläche.",
	EASY_LFG_OVERLAY_CLOSE_TOOLTIP = "SmartLFG ausblenden",
	EASY_LFG_OVERLAY_CLOSE_TOOLTIP_HINT = "Blendet das Overlay für die aktuelle aktive Gruppe aus. Bei der nächsten eigenen Listung erscheint es wieder automatisch.",
	EASY_LFG_OVERLAY_PIN = "Pin",
	EASY_LFG_OVERLAY_UNPIN = "Lösen",
	EASY_LFG_OVERLAY_PIN_TOOLTIP = "Overlay fixieren",
	EASY_LFG_OVERLAY_UNPIN_TOOLTIP = "Fixierung lösen",
	EASY_LFG_OVERLAY_PIN_TOOLTIP_HINT = "Sperrt oder entsperrt die Position des SmartLFG-Overlays.",
	EASY_LFG_OVERLAY_EDIT = "Bearb.",
	EASY_LFG_OVERLAY_EDIT_TOOLTIP = "Gruppe bearbeiten",
	EASY_LFG_OVERLAY_EDIT_TOOLTIP_HINT = "Öffnet die Blizzard-Bearbeitung deiner aktuellen LFG-Listung.",
	EASY_LFG_OVERLAY_DELIST = "Abmelden",
	EASY_LFG_OVERLAY_DELIST_TOOLTIP = "Gruppe abmelden",
	EASY_LFG_OVERLAY_DELIST_TOOLTIP_HINT = "Entfernt deine aktuelle LFG-Listung direkt aus dem Gruppenbrowser.",
	EASY_LFG_OVERLAY_RIO = "RIO",
	EASY_LFG_OVERLAY_RIO_SHOW_TOOLTIP = "Raider.IO ausklappen",
	EASY_LFG_OVERLAY_RIO_HIDE_TOOLTIP = "Raider.IO einklappen",
	EASY_LFG_OVERLAY_RIO_TOOLTIP_HINT = "Blendet rechts neben SmartLFG das Raider.IO-Profil ein. Solange das Panel offen ist, wechselt es beim Überfahren eines Bewerbers.",
	EASY_LFG_OVERLAY_RIO_SCORE = "Raider.IO M+ Wertung",
	EASY_LFG_OVERLAY_RIO_BEST_RUN = "Bester Durchlauf",
	EASY_LFG_OVERLAY_RIO_TOP_DUNGEONS = "Beste Durchläufe",
	EASY_LFG_OVERLAY_RIO_RAID_PROGRESS = "Schlachtzugsfortschritt",
	EASY_LFG_OVERLAY_RIO_NO_PROFILE = "Für diesen Bewerber wurden keine verwertbaren Raider.IO-Daten gefunden.",
	EASY_LFG_OVERLAY_RIO_RENDER_HINT = "Wenn Raider.IO das normale Profil nicht direkt rendert, zeigt BeavisQoL hier eine kompakte Vorschau an.",
	EASY_LFG_DECLINE = "Ablehnen",
	EASY_LFG_INVITE = "Einladen",
	EASY_LFG_ITEM_LEVEL = "ilvl %s",
	EASY_LFG_SCORE = "Score %d",
	EASY_LFG_GROUP_BADGE = "%d Spieler",
	EASY_LFG_MEMBER_INDEX = "%d/%d",
	EASY_LFG_STATUS_APPLIED = "Beworben",
	EASY_LFG_STATUS_INVITED = "Eingeladen",
	EASY_LFG_STATUS_INVITE_ACCEPTED = "Invite angenommen",
	EASY_LFG_STATUS_DECLINED = "Abgelehnt",
	EASY_LFG_STATUS_INVITE_DECLINED = "Invite abgelehnt",
	EASY_LFG_STATUS_INACTIVE = "Inaktiv",

	PET_STUFF_DESC = "Hier findest du kleine Komfortfunktionen rund um Begleiter und Pets.",
	AUTO_RESPAWN_PET_TITLE = "Haustieroptionen",
	AUTO_RESPAWN_PET_HINT = "Beschwört dein zuletzt aktives Begleiter-Pet nach dem Auf- und Abmounten automatisch erneut. Das Rufen ist nur außerhalb des Kampfes möglich.",

	ITEM_GUIDE_EYEBROW = "Fortschritt",
	ITEM_GUIDE_TITLE = "Midnight S1 Itemlevel-Kompass",
	ITEM_GUIDE_SUBTITLE = "Upgradepfade, Crafting, Dungeons, Raid und Tiefen kompakt auf einer Seite.",
	ITEM_GUIDE_DESC = "Die Werte sind als schnelle Saisonreferenz gedacht. Besonders die Raid-Itemlevel sind bewusst als Richtwerte markiert, damit die Seite im Alltag wie ein ruhiges Nachschlagewerk funktioniert und nicht wie eine gequetschte Zahlenliste.",
	SEASON_REFERENCE = "Saison-Referenz",
	ITEM_GUIDE_BADGE_TEXT = "20 Wappen pro Rang\nRaidwerte = ca.-Angaben",
	ITEM_GUIDE_LEGEND = "|cff45ff6eAbenteurer|r  -  |cff2e94ffVeteran|r  -  |cffba57ffChampion|r  -  |cffff9220Held|r  -  |cffffe033Mythisch|r",
	ITEM_GUIDE_UPGRADE_CARD_TITLE = "Wappenpfade",
	ITEM_GUIDE_UPGRADE_CARD_SUBTITLE = "Upgradepfade und Wappen",
	ITEM_GUIDE_UPGRADE_CARD_NOTE = "20 Wappen pro Rang, Sparstellen direkt markiert.",
	ITEM_GUIDE_PATH_ADVENTURER = "Abenteurer",
	ITEM_GUIDE_PATH_VETERAN = "Veteran",
	ITEM_GUIDE_PATH_CHAMPION = "Champion",
	ITEM_GUIDE_PATH_HERO = "Held",
	ITEM_GUIDE_PATH_MYTH = "Mythisch",
	ITEM_GUIDE_SAVE_VETERAN = "auf Veteran sparen",
	ITEM_GUIDE_SAVE_CHAMPION = "auf Champion sparen",
	ITEM_GUIDE_SAVE_HERO = "auf Held sparen",
	ITEM_GUIDE_SAVE_MYTH = "auf Mythisch sparen",
	ITEM_GUIDE_SAVE_FOR_RUNED = "auf Runenwappen sparen",
	ITEM_GUIDE_SAVE_FOR_GILDED = "auf Vergoldete sparen",
	ITEM_GUIDE_HEADER_PATH_RANK = "Pfad / Rang",
	ITEM_GUIDE_HEADER_CRESTS = "Wappen",
	ITEM_GUIDE_HEADER_QUALITY = "Qualität",
	ITEM_GUIDE_HEADER_SOURCE = "Quelle",
	ITEM_GUIDE_HEADER_END_REWARD = "Endbelohnung",
	ITEM_GUIDE_HEADER_GREAT_VAULT = "Große Schatzkammer",
	ITEM_GUIDE_HEADER_DIFFICULTY = "Schwierigkeit",
	ITEM_GUIDE_HEADER_EARLY = "Früh",
	ITEM_GUIDE_HEADER_MID = "Mitte",
	ITEM_GUIDE_HEADER_LATE = "Spät",
	ITEM_GUIDE_HEADER_END = "Ende",
	ITEM_GUIDE_HEADER_LEVEL = "Stufe",
	ITEM_GUIDE_HEADER_MAP_DROP = "Karten-Drop",
	ITEM_GUIDE_LABEL_HEROIC = "Heroisch",
	ITEM_GUIDE_LABEL_MYTHIC = "Mythisch",
	ITEM_GUIDE_LABEL_RAID_FINDER = "Schlachtzugsbrowser",
	ITEM_GUIDE_LABEL_NORMAL = "Normal",
	ITEM_GUIDE_ABBR_ADVENTURER = "Abent.",
	ITEM_GUIDE_ABBR_VETERAN = "Vet.",
	ITEM_GUIDE_ABBR_CHAMPION = "Champ.",
	ITEM_GUIDE_ABBR_HERO = "Held",
	ITEM_GUIDE_ABBR_MYTH = "Myth",
	ITEM_GUIDE_CRAFTED_CARD_TITLE = "Crafting",
	ITEM_GUIDE_CRAFTED_CARD_SUBTITLE = "Hergestellte Itemlevel",
	ITEM_GUIDE_CRAFTED_CARD_NOTE = "Qualität und Zielpfad in einer kompakten Matrix.",
	ITEM_GUIDE_DUNGEON_CARD_TITLE = "Instanzen",
	ITEM_GUIDE_DUNGEON_CARD_SUBTITLE = "Dungeon und Große Schatzkammer",
	ITEM_GUIDE_DUNGEON_CARD_NOTE = "Heroisch, Mythisch und M+ auf einen Blick.",
	ITEM_GUIDE_RAID_CARD_TITLE = "Schlachtzug",
	ITEM_GUIDE_RAID_CARD_SUBTITLE = "Raid-Richtwerte",
	ITEM_GUIDE_RAID_CARD_NOTE = "Frühe bis späte Bosse als grobe Saisonreferenz.",
	ITEM_GUIDE_DELVE_CARD_TITLE = "Tiefen",
	ITEM_GUIDE_DELVE_CARD_SUBTITLE = "Tiefen und Wochenkiste",
	ITEM_GUIDE_DELVE_CARD_NOTE = "Endbelohnung, Karten-Drop und Große Schatzkammer.",
	ITEM_GUIDE_UPGRADE_FOOTNOTE = "Die roten Hinweise markieren Stellen, an denen sich die nächste Wappenfarbe meist besser aufhebt.",
	ITEM_GUIDE_RAID_FOOTNOTE = "Raid-Werte sind bewusst als ca.-Angaben formuliert und können je Boss leicht schwanken.",
	ITEM_GUIDE_FOOTER = "Ziel dieser Seite: schnelle Entscheidungen im Alltag. Ein Blick genügt, um Upgradepfad, Dungeon-Ziel oder Crafting-Stufe zu vergleichen.",

	LEVELTIME_TOOLTIP_TITLE = "Levelzeit-Tracker",
	LEVELTIME_TOOLTIP_TEXT = "Der Levelzeit-Tracker zählt nur die tatsächlich gespielte Zeit, während das Addon aktiv ist.",
	LEVEL_LABEL = "Level %d",
	CURRENT_LEVEL = "Aktuelles Level",
	TIME_ON_CURRENT_LEVEL = "Zeit auf aktuellem Level",
	TOTAL_TIME = "Gesamtzeit",
	TRACKED_LEVEL_TIMES = "Erfasste Levelzeiten",
	LEVEL_RUNNING = "läuft gerade",
	MAX_LEVEL_REACHED = "Maximallevel erreicht",
	MAX_LEVEL_CONGRATS = "Glückwunsch, du hast das Maximallevel erreicht.",

	QUESTCHECK_TITLE = "Quest Check",
	QUESTCHECK_DESC = "Prüft, ob eine Quest bereits erledigt ist. Du kannst direkt eine Quest-ID, einen WoWHead-Link oder einen exakten Questnamen eingeben.",
	QUEST_SEARCH = "Quest suchen",
	QUEST_SEARCH_HINT = "Beispiele: Quest ID 12345, ein exakter Questname oder https://www.wowhead.com/quest=12345",
	CHECK_QUEST = "Quest prüfen",
	RESULT = "Ergebnis",
	QUESTCHECK_RESULT_HINT = "Hier erscheint nach der Suche der Abschlussstatus der Quest.",
	QUESTCHECK_NO_SEARCH = "Noch keine Suche ausgeführt.",
	QUESTCHECK_READY_TO_SEARCH = "Bereit zur Suche",
	WOWHEAD_LINK = "WoWHead-Link",
	WOWHEAD_SEARCH = "WoWHead-Suche",
	LINKS_COPY_DIALOG = "Links werden im Copy-Dialog angezeigt.",
	QUESTCHECK_INPUT_MISSING = "Bitte eine Quest-ID, einen exakten Questnamen oder einen WoWHead-Link eingeben.",
	QUESTCHECK_SEARCH_RUNNING = "Suche läuft",
	QUESTCHECK_SCANNING = "Der Questname wird gegen lokal bekannte Questtitel geprüft. Das kann beim ersten Durchlauf einen Moment dauern.",
	QUESTCHECK_SCAN_PROGRESS = "Questnamen werden lokal durchsucht: %.0f%%",
	QUEST_DONE = "|cff55dd55Erledigt|r",
	QUEST_NOT_DONE = "|cffff6666Nicht erledigt|r",
	QUEST_IN_LOG = "im Questlog",
	QUEST_WARBAND_DONE = "warbandweit erledigt",
	QUEST_ID_LABEL = "Quest-ID %d",
	QUEST_RESULT_LINE = "[%d] %s - %s%s",
	QUEST_MORE_RESULTS = "|cffbfbfbf+ %d weitere Treffer|r",
	QUEST_SINGLE_SOURCE_ID = "Direkter ID-Check",
	QUEST_SINGLE_SOURCE_NAME = "Namenssuche",
	QUEST_SINGLE_TEXT = "Quest \"%s\" (ID %d) | %s",
	QUEST_SINGLE_CHAT = "Quest \"%s\" (ID %d) ist %s.",
	QUEST_SINGLE_CHAT_ACTIVE = " Sie ist aktuell im Questlog.",
	QUEST_SINGLE_CHAT_WARBAND = " Warbandweit ist sie bereits erledigt.",
	QUEST_WOWHEAD_TITLE = "Quest auf WoWHead",
	QUEST_MULTIPLE_STATE = "%d Treffer",
	QUEST_MULTIPLE_TEXT = "Mehrere Quests mit exakt diesem Namen wurden lokal gefunden. Bitte die passende Quest-ID aus der Liste wählen.",
	QUEST_MULTIPLE_CHAT = "%d Quests mit dem Namen \"%s\" gefunden. Details stehen im Quest Check Modul.",
	QUEST_UNRESOLVED_TEXT = "Der Questname konnte lokal nicht eindeutig auf eine Quest-ID aufgelöst werden. Mit Quest-ID ist die Prüfung am verlässlichsten.",
	QUEST_UNRESOLVED_TIPS = "Tipps:\n- exakten Questnamen verwenden\n- alternativ direkt eine Quest-ID oder einen WoWHead-Link einfügen",
	QUEST_UNRESOLVED_CHAT = "Questname \"%s\" konnte lokal nicht aufgelöst werden. Mit der Quest-ID ist der Check am sichersten.",
	QUEST_INPUT_MISSING_STATE = "Eingabe fehlt",
	QUEST_NOT_DONE_PLAIN = "nicht erledigt",
	QUEST_DONE_PLAIN = "erledigt",
	QUEST_ABANDON_TITLE = "Quest-Abbruch",
	QUEST_ABANDON_LIST_TITLE = "Questliste",
	QUEST_ABANDON_DESC = "Wähle gezielt aus, welche sichtbaren aktiven Quests abgebrochen werden sollen. Die Aktion wirkt sofort auf dein aktuelles Questlog und fragt vor dem Abbruch noch einmal nach.",
	QUEST_ABANDON_SELECT_ALL = "Alle markieren",
	QUEST_ABANDON_CLEAR_ALL = "Alle demarkieren",
	QUEST_ABANDON_SELECTED = "Markierte abbrechen",
	QUEST_ABANDON_UNAVAILABLE = "Quest-Abbruch ist über die aktuelle API hier nicht verfügbar.",
	QUEST_ABANDON_NONE = "Derzeit sind keine aktiven Quests im Questlog.",
	QUEST_ABANDON_SELECTION_COUNT = "%d von %d Quests markiert",
	QUEST_ABANDON_SELECTED_NONE = "Es sind keine Quests zum Abbrechen markiert.",
	QUEST_ABANDON_CONFIRM = "Sollen wirklich %d markierte Quest(s) abgebrochen werden?",
	QUEST_ABANDON_DONE = "%d Quest(s) wurden abgebrochen.",
	LIVE_PREVIEW = "Live-Vorschau",
	DISPLAY_POSITION = "Anzeige und Position",
	WINDOW_SCALE = "Fenster-Skalierung",
	BACKGROUND_ALPHA = "Hintergrund-Deckkraft",
	FONT_SIZE_OVERLAY = "Schriftgröße im Overlay",
	RESET_POSITION_HINT = "Setzt das Overlay wieder nach unten rechts an seine Startposition.",
	SHOW_OVERLAY = "Overlay anzeigen",
	LOCK_OVERLAY = "Overlay fixieren",

	STATS_TITLE = "Stats",
	STATS_DESC = "Zeigt deine wichtigsten Sekundärwerte in einem kleinen, dezenten Ingame-Fenster an. Die Vorschau unten nutzt bereits dein aktuelles Gear, Buffs und Procs.",
	STATS_PREVIEW_HINT = "So wirkt das kleine Stats-Fenster im Spiel: kompakt, sauber und bewusst unaufdringlich.",
	STATS_PREVIEW_FOOTER = "Schriftgröße, Skalierung und Transparenz greifen direkt in die Live-Vorschau ein.",
	STATS_SETTINGS_HINT = "Das Stats-Fenster ist frei beweglich, transparent und bewusst kompakt. Schriftgröße und Skalierung lassen sich getrennt anpassen.",
	STATS_SHOW_OVERLAY = "Stats-Fenster anzeigen",
	STATS_SHOW_OVERLAY_HINT = "Blendet außerhalb des Hauptfensters ein kleines Fenster mit deinen aktuellen Werten ein.",
	STATS_LOCK_OVERLAY = "Stats-Fenster fixieren",
	STATS_LOCK_OVERLAY_HINT = "Sperrt das freie Verschieben, sobald die Position für dich passt.",
	STATS_FONT_SIZE = "Schriftgröße im Stats-Fenster",
	STATS_RESET_HINT = "Setzt das kleine Stats-Fenster wieder an die Standardposition unten rechts.",

	WEEKLY_KEYS_DESC = "Zeigt dir die 8 höchsten Weekly-Keys in einem transparenten, fensterfreien Overlay. Auf den Zeilen 1, 4 und 8 steht direkt der jeweilige Weekly-Loot-Itemlevel.",
	WEEKLY_KEYS_PREVIEW_HINT = "Die Vorschau zeigt denselben cleanen Stil wie das Overlay im Spiel, aber absichtlich ohne sichtbaren Fensterrahmen.",
	WEEKLY_KEYS_PREVIEW_FOOTER = "Schriftgröße, Skalierung und Transparenz greifen direkt in die Live-Vorschau ein.",
	WEEKLY_KEYS_SETTINGS_HINT = "Das Overlay ist bewusst rahmenlos und dezent. Schriftgröße und Skalierung lassen sich getrennt anpassen, damit es kompakter wirken kann.",
	WEEKLY_KEYS_SHOW_OVERLAY = "Weekly-Keys-Overlay anzeigen",
	WEEKLY_KEYS_SHOW_OVERLAY_HINT = "Blendet außerhalb des Hauptfensters die Top-8-Keys mit Weekly-Loot-Hinweisen ein.",
	WEEKLY_KEYS_LOCK_OVERLAY = "Overlay fixieren",
	WEEKLY_KEYS_LOCK_OVERLAY_HINT = "Sperrt das freie Verschieben, sobald deine Position passt.",
	WEEKLY_KEYS_HIDE_IN_RAID = "In Schlachtzügen ausblenden",
	WEEKLY_KEYS_HIDE_IN_RAID_HINT = "Blendet das Weekly-Keys-Overlay automatisch aus, sobald du in einer Raid-Gruppe bist.",
	WEEKLY_KEYS_RESET_HINT = "Setzt das Overlay wieder nach unten rechts an seine Startposition.",
	WEEKLY_KEYS_HEROIC = "HC",
	WEEKLY_KEYS_MYTHIC = "Mythisch",
	WEEKLY_KEYS_HEROIC_RECORDED = "HC-Dungeon erfasst",
	WEEKLY_KEYS_MYTHIC_RECORDED = "Mythischer Dungeon erfasst",
	WEEKLY_KEYS_NAMELESS = "Dungeon ohne Namen erfasst",
	UNKNOWN_DUNGEON = "Unbekannter Dungeon",
	WEEKLY_KEYS_PLACEHOLDER = "Dungeon ohne Namen erfasst",
	WEEKLY_KEYS_NONE_THIS_WEEK = "Noch kein Dungeon in dieser Woche",
	WEEKLY_KEYS_NONE_WEEKLY = "Noch kein Weekly-Dungeon abgeschlossen",
	WEEKLY_KEYS_MORE_NEEDED = "Noch %d %s bis Weekly-Slot",
	DUNGEON_SINGULAR = "Dungeon",
	DUNGEON_PLURAL = "Dungeons",
	WEEKLY_KEYS_SUMMARY = "%d/8 Dungeons | Weekly-Loot %s / %s / %s",
	WEEKLY_KEYS_GROUP_KEYS_BUTTON = "GRP-Keys",
	WEEKLY_KEYS_GROUP_KEYS_HINT = "Fragt die aktuell in der Tasche befindlichen Mythic+-Schlüssel deiner Gruppenmitglieder ab. Zuerst antwortet BeavisQoL direkt; für fehlende oder unbekannte Antworten wird automatisch Details als Fallback geprüft, falls verfügbar.",
	WEEKLY_KEYS_GROUP_KEYS_HEADER = "GRP-Keys in deiner Gruppe:",
	WEEKLY_KEYS_GROUP_KEYS_ENTRY = "%s - %s",
	WEEKLY_KEYS_GROUP_KEYS_NONE = "kein Key in der Tasche",
	WEEKLY_KEYS_GROUP_KEYS_NO_RESPONSE = "keine Antwort",
	WEEKLY_KEYS_GROUP_KEYS_NO_GROUP = "GRP-Keys funktioniert nur in einer aktiven Gruppe.",
	WEEKLY_KEYS_GROUP_KEYS_UNAVAILABLE = "GRP-Keys wird von diesem Client gerade nicht unterstützt.",

	LOGGING_DESC = "Kompakte Logs für Einnahmen, Ausgaben, Reparaturen und Währungen. Gesamtverlauf über Verlauf.",
	LOGGING_CLEANUP = "Zeitraum löschen",
	LOGGING_RETENTION_HINT = "Reparaturen 30 Tage, Gold und Währungen 1 Jahr.",
	LOGGING_CLEANUP_TITLE = "Log-Zeitraum löschen",
	LOGGING_CLEANUP_HINT = "Entfernt Einträge, die älter sind als der gewählte Zeitraum. Reparaturen bleiben zusätzlich automatisch auf 30 Tage begrenzt.",
	LOGGING_SALES_TITLE = "Verkaufslog",
	LOGGING_SALES_HINT = "Zeigt die letzten Händlerverkäufe an, inklusive Automatisch Verkaufen. Einträge mit Itemdaten lassen sich per Klick aufklappen.",
	LOGGING_REPAIRS_TITLE = "Reparaturkosten",
	LOGGING_REPAIRS_HINT = "Letzte 10 Tage. Gesamtverlauf über Verlauf.",
	LOGGING_INCOME_TITLE = "Einnahmen mit Quelle",
	LOGGING_INCOME_HINT = "Letzte 10 Einnahmen. Gesamtverlauf über Verlauf.",
	LOGGING_EXPENSE_TITLE = "Ausgaben mit Ziel",
	LOGGING_EXPENSE_HINT = "Letzte 10 Ausgaben. Gesamtverlauf über Verlauf.",
	LOGGING_CURRENCY_TITLE = "Andere Währungen",
	LOGGING_CURRENCY_HINT = "Letzte 10 Änderungen. Gesamtverlauf über Verlauf.",
	LOGGING_HISTORY = "Verlauf",
	LOGGING_HISTORY_TITLE = "Gesamtverlauf",
	LOGGING_HISTORY_HINT = "Suche im Verlauf oder wechsle zwischen den Kategorien.",
	LOGGING_HISTORY_EMPTY = "Noch kein Verlauf vorhanden.",
	LOGGING_HISTORY_TAB_INCOME = "Einnahmen",
	LOGGING_HISTORY_TAB_EXPENSE = "Ausgaben",
	LOGGING_HISTORY_TAB_REPAIRS = "Reparaturen",
	LOGGING_HISTORY_TAB_CURRENCY = "Währungen",
	LOGGING_HISTORY_SEARCH = "Suche",
	LOGGING_HISTORY_LOAD_MORE = "Mehr laden",
	LOGGING_HISTORY_NO_MATCHES = "Keine Treffer im aktiven Verlauf.",
	LOGGING_OVERVIEW_NO_MATCHES = "Keine Treffer für diese Suche.",
	LOGGING_HISTORY_SHOWING = "%d Einträge sichtbar.",
	LOGGING_HISTORY_SHOWING_MORE = "%d Einträge sichtbar. Weitere Einträge können geladen werden.",
	LOGGING_STORED_SALES = "Gespeicherte Verkäufe: %d",
	LOGGING_TOTAL_SALES_GOLD = "Gesamtgold aus Verkäufen: %s",
	LOGGING_STORED_REPAIRS = "Gespeicherte Reparaturen: %d",
	LOGGING_TOTAL_REPAIRS = "Gesamte Reparaturkosten: %s",
	LOGGING_DAILY_EXPAND_HINT = "Tagessummen lassen sich aufklappen.",
	LOGGING_NO_REPAIRS = "Noch keine Reparaturen protokolliert.",
	LOGGING_STORED_INCOME = "Gespeicherte Einnahmen: %d",
	LOGGING_TOTAL_INCOME = "Gesamtsumme: %s",
	LOGGING_STORED_EXPENSES = "Gespeicherte Ausgaben: %d",
	LOGGING_TOTAL_EXPENSES = "Gesamtsumme: %s",
	LOGGING_STORED_CURRENCY_CHANGES = "Gespeicherte Währungsänderungen: %d",
	LOGGING_LATEST_ENTRIES = "Letzte Einträge:",
	DAYS_7 = "7 Tage",
	DAYS_30 = "30 Tage",
	DAYS_90 = "90 Tage",
	DAYS_365 = "1 Jahr",
	ALL = "Alles",
	DAILY = "Daily",
	WEEKLY = "Weekly",
	VAULT = "Vault",
	NO_ENTRIES = "Noch keine Einträge vorhanden.",
	UNKNOWN_ITEM = "Unbekanntes Item",
	LOGGING_SALE = "Verkauf",
	LOGGING_VENDOR_SALE = "Händler",
	LOGGING_MAIL = "Post",
	LOGGING_MAILBOX = "Postfach",
	LOGGING_AUCTIONHOUSE = "Auktionshaus",
	LOGGING_TRADE = "Handel",
	LOGGING_QUEST = "Quest",
	LOGGING_QUEST_REWARD = "Questbelohnung",
	LOGGING_LOOT = "Beute",
	LOGGING_PICKED_UP = "Aufgesammelt",
	LOGGING_MISC = "Sonstiges",
	LOGGING_FLIGHTMASTER = "Flugmeister",
	LOGGING_VENDOR = "Händler",
	LOGGING_TRAINER = "Trainer",
	LOGGING_REPAIR = "Reparatur",
	LOGGING_OWN_GOLD = "Eigenes Gold",
	LOGGING_GUILD = "Gilde",
	LOGGING_AUTOSELL = "Automatisch Verkaufen",
	LOGGING_COSTS = "Kosten",
	LOGGING_SALE_TO = "Verkauf an %s",
	LOGGING_ITEM = "Item",
	LOGGING_ITEMS = "Items",
	LOGGING_REPAIRS = "Reparaturen",
	LOGGING_SELF_PAID = "Selbst bezahlt",
	LOGGING_ENTRY = "Eintrag",
	ITEMS_LABEL = "Items",
	PET_STUFF_TITLE = "Pet Stuff",
	SEASON_NAME_MIDNIGHT = "Midnight",
	CHECKLIST_DESC = "Behalte tägliche, wöchentliche und eigene Aufgaben kompakt im Blick, auf Wunsch auch im separaten Tracker-Fenster.",
	CHECKLIST_SUMMARY = "%d / %d erledigt",
	CHECKLIST_INTRO_SUMMARY_DEFAULT = "0 / 0 erledigt",
	CHECKLIST_INTRO_HINT = "Die vorgegebenen Aufgaben sind bereits einsortiert. Eigene Aufgaben kannst du darunter als Daily oder Weekly ergänzen.",
	CHECKLIST_WATCH = "Im Blick halten",
	CHECKLIST_WATCH_SHORT = "Im Blick",
	CHECKLIST_WATCH_HINT = "Langfristige Punkte ohne automatischen Reset, die du einfach im Auge behalten möchtest.",
	CHECKLIST_EMPTY_WATCH = "Aktuell keine Aufgaben in dieser Kategorie vorhanden.",
	CHECKLIST_DAILY_HINT = "Alle Aufgaben, die sich beim täglichen EU-Reset zurücksetzen. Vorgegebene Aufgaben können rechts deaktiviert werden.",
	CHECKLIST_EMPTY_DAILY = "Aktuell keine Daily-Aufgaben vorhanden.",
	CHECKLIST_WEEKLY_HINT = "Alle Aufgaben, die sich beim wöchentlichen EU-Reset zurücksetzen.",
	CHECKLIST_EMPTY_WEEKLY = "Aktuell keine Weekly-Aufgaben vorhanden.",
	CHECKLIST_MANUAL_ADD_TITLE = "Manuelle Aufgabe hinzufügen",
	CHECKLIST_MANUAL_ADD_HINT = "Hier können manuelle Aufgaben nach Kategorie hinzugefügt werden. Anhand der Kategorie wird ein automatischer Reset durchgeführt.",
	CHECKLIST_MANUAL_ADD_LABEL = "Neue manuelle Aufgabe",
	CHECKLIST_MANUAL_CATEGORY_HINT = "Tipp: Du kannst die Kategorie später nachträglich ändern.",
	CHECKLIST_APPEARANCE = "Anzeige und Optik",
	CHECKLIST_APPEARANCE_HINT = "Für das Tracking hast du ein Fenster im Interface, das hier manuell konfiguriert werden kann.",
	CHECKLIST_SHOW_TRACKER = "Tracker-Fenster anzeigen",
	CHECKLIST_SHOW_TRACKER_HINT = "Blendet außerhalb des Hauptfensters ein kleines Checklisten-Fenster ein.",
	CHECKLIST_SHOW_BUILTIN = "Vorgegebene Aufgaben im Tracker zeigen",
	CHECKLIST_SHOW_BUILTIN_HINT = "Zeigt die feste Starterliste auch im kleinen Tracker-Fenster an.",
	CHECKLIST_SHOW_MANUAL = "Manuelle Aufgaben im Tracker zeigen",
	CHECKLIST_SHOW_MANUAL_HINT = "Zeigt deine eigenen Aufgaben ebenfalls im kleinen Tracker-Fenster an.",
	CHECKLIST_HIDE_COMPLETED = "Erledigte To-Dos im Tracker ausblenden",
	CHECKLIST_HIDE_COMPLETED_HINT = "Praktisch für eine ruhigere Ingame-Ansicht, wenn nur offene Aufgaben sichtbar sein sollen.",
	CHECKLIST_TRACKER_FONT_SIZE = "Schriftgröße im Tracker",
	CHECKLIST_RESET_CHECKS = "Alle Haken zurücksetzen",
	CHECKLIST_RESET_BUILTIN = "Vorgegebene zurücksetzen",
	CHECKLIST_RESET_TRACKER = "Tracker-Fenster zurücksetzen",
	CHECKLIST_TRACKER_EMPTY_OPEN = "Keine To-Dos für den Tracker sichtbar.",
	CHECKLIST_TRACKER_EMPTY_HIDDEN = "Keine offenen To-Dos für den Tracker sichtbar.",
	CHECKLIST_TRACKER_TITLE = "Checkliste %d/%d",
	CHECKLIST_TRACKER_LOCKED = "Tracker fixiert",
	CHECKLIST_TRACKER_LOCKED_HINT = "Ziehen und Größenänderung sind gesperrt. Klick zum Lösen.",
	CHECKLIST_TRACKER_UNLOCKED = "Tracker frei",
	CHECKLIST_TRACKER_UNLOCKED_HINT = "Ziehen und Größenänderung sind möglich. Klick zum Fixieren.",
	CHECKLIST_SETTINGS_BUTTON = "Einst.",
	CHECKLIST_SETTINGS_TOOLTIP = "Checklisten-Einstellungen",
	CHECKLIST_SETTINGS_TOOLTIP_HINT = "Öffnet die Checklisten-Seite direkt beim Einstellungsblock.",
	CHECKLIST_ADD_BUTTON = "Add",
	CHECKLIST_ADD_TOOLTIP = "Aufgabe hinzufügen",
	CHECKLIST_ADD_TOOLTIP_HINT = "Öffnet ein kleines Fenster, um schnell eine manuelle Aufgabe anzulegen.",
	CHECKLIST_VAULT_TOOLTIP = "Weekly Vault",
	CHECKLIST_VAULT_TOOLTIP_HINT = "Öffnet oder schließt das Weekly-Rewards-Fenster.",
	CHECKLIST_VAULT_ERROR = "Beavis QoL: Das Vault-Fenster konnte gerade nicht geöffnet werden.",
	CHECKLIST_EXPAND = "Tracker ausklappen",
	CHECKLIST_EXPAND_HINT = "Zeigt die komplette Checkliste wieder an.",
	CHECKLIST_COLLAPSE = "Tracker einklappen",
	CHECKLIST_COLLAPSE_HINT = "Blendet die Checkliste aus und lässt nur den Header sichtbar.",
	CHECKLIST_CLOSE = "Tracker schließen",
	CHECKLIST_CLOSE_HINT = "Blendet das Tracker-Fenster aus. Über die Einstellungen kannst du es wieder einblenden.",
	CHECKLIST_NEW_TASK = "Neue Aufgabe",
	CHECKLIST_NEW_TASK_HINT = "Manuelle Aufgabe direkt im Tracker anlegen.",
	ADD_SHORT = "Hinzuf.",
	ADD = "Hinzufügen",
	FIX = "Fix",
	UNLOCK = "Lösen",
	CHECKLIST_TODO_WEEKLY_VAULT = "+10 oder höher für die Weekly Vault",
	CHECKLIST_TODO_WEEKLY_RAID = "Raid für Vault und BiS-Items",
	CHECKLIST_TODO_WEEKLY_PVP_QUESTS = "Wöchentliche PvP-Quests",
	CHECKLIST_TODO_WEEKLY_HUNTS = "Alptraum-Beutejagden abgeschlossen",
	CHECKLIST_TODO_WEEKLY_OPTIONAL_HUNTS = "Optionale Beutejagden abgeschlossen",
	CHECKLIST_TODO_WEEKLY_SOIREE = "Soiree für Wochenbelohnungen",
	CHECKLIST_TODO_WEEKLY_OVERFLOW = "Überfluss für Wochenbelohnungen",
	CHECKLIST_TODO_WEEKLY_STORMARION = "Sturmarion-Angriff für Wochenbelohnungen",
	CHECKLIST_TODO_WEEKLY_HARANDIR = "Harandir-Event für Wochenbelohnungen",
	CHECKLIST_TODO_WEEKLY_HOUSING_QUEST = "Wöchentliche Housing-Quest",
	CHECKLIST_TODO_WEEKLY_VOIDSTORM = "Leerensturm: 3 Weltquests für Rüstmeister-Belohnung",
	CHECKLIST_TODO_WEEKLY_DELVE_PROGRESS = "Wöchentlicher Tiefenfortschritt",
	CHECKLIST_TODO_WEEKLY_DELVE_HERO_MAP = "Wöchentliche Tiefen-Held-Karte",
	CHECKLIST_TODO_DAILY_DELVES = "4 Aufgestiegene Tiefen für tägliche Belohnungen",
	CHECKLIST_TODO_DAILY_WORLDQUESTS = "Weltquests für Ruf und Währungen",
	CHECKLIST_TODO_DAILY_HARANDIR = "Harandir-Tagesquest für täglichen Fortschritt",
	CHECKLIST_TODO_WATCH_TIER = "4er-Set-Fortschritt",
	CHECKLIST_TODO_WEEKLY_PROFESSION = "Max. Wöchentliche Berufspunkte farmen (%s)",
	STREAMER_PLANNER_ROLE = "Rolle",
	STREAMER_PLANNER_ROLE_AUTO = "Auto",
	STREAMER_PLANNER_SPEC_PROMPT_HINT_CLASS = "Klasse wählen",
	STREAMER_PLANNER_SPEC_PROMPT_HINT_ROLE = "Rolle wählen",
	STREAMER_PLANNER_SELF_ROLE_TITLE = "Eigene Rolle auswählen",
	STREAMER_PLANNER_SELF_ROLE_HINT = "Hier legst du fest, mit welcher Rolle dein Charakter im Dungeon-Planer einsortiert wird. Das ist unabhängig von deinem aktuellen Spec.",
	STREAMER_PLANNER_APPLY = "Übernehmen",
}
