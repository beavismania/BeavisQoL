local ADDON_NAME = ...

-- Diese Datei ist nur eine kleine Font-Liste.
-- Andere Module, vor allem Combat Text, lesen sie ein und bauen daraus die
-- auswählbaren Schriftarten auf.
local fontBasePath = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\fonts\\"
-- Der Pfad wird absichtlich ueber ADDON_NAME aufgebaut.
-- Damit bleiben die Font-Eintraege korrekt, auch wenn der Addon-Ordner oder
-- die TOC-Datei spaeter noch einmal umbenannt werden.

-- Für Combat Text funktionieren klassische Addon-Fontpfade in WoW am zuverlässigsten.
-- Darum zeigen alle Einträge auf den separaten fonts-Ordner im Addon.
BeavisQoL_CustomFonts = {
    { key = "alte_haas_grotesk", label = "Alte Haas Grotesk", path = fontBasePath .. "AlteHaasGroteskBold.ttf" },
    { key = "bangers", label = "Bangers", path = fontBasePath .. "Bangers.ttf" },
    { key = "big_noodle_titling", label = "Big Noodle Titling", path = fontBasePath .. "bignoodletitling.ttf" },
    { key = "denmark", label = "Denmark", path = fontBasePath .. "Denmark.ttf" },
    { key = "die_die_die", label = "Die Die Die", path = fontBasePath .. "DIEDIEDI.TTF" },
    { key = "expressway", label = "Expressway", path = fontBasePath .. "Expressway.ttf" },
    { key = "ginko", label = "Ginko", path = fontBasePath .. "Ginko.ttf" },
    { key = "gotham_narrow_ultra", label = "Gotham Narrow Ultra", path = fontBasePath .. "Gotham Narrow Ultra.otf" },
    { key = "lifecraft", label = "LifeCraft", path = fontBasePath .. "LifeCraft_Font.ttf" },
    { key = "pepsi_cursive", label = "Pepsi Cursive", path = fontBasePath .. "pepsi_cursive.ttf" },
    { key = "pepsi_modern", label = "Pepsi Modern", path = fontBasePath .. "pepsi_modern.ttf" },
    { key = "pf_tempesta_seven", label = "Pf Tempesta Seven", path = fontBasePath .. "pf_tempesta_seven.ttf" },
    { key = "prototype", label = "Prototype", path = fontBasePath .. "Prototype.ttf" },
    { key = "roboto_bold", label = "Roboto Bold", path = fontBasePath .. "Roboto-Bold.ttf" },
    { key = "yikes", label = "Yikes", path = fontBasePath .. "yikes.ttf" },
    { key = "zero_cool", label = "Zero Cool", path = fontBasePath .. "ZeroCool.ttf" },
}
