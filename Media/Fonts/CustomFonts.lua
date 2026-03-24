local ADDON_NAME = ...

-- Diese Datei ist nur eine kleine Font-Liste.
-- Andere Module, vor allem Combat Text, lesen sie ein und bauen daraus die
-- auswählbaren Schriftarten auf.
local fontBasePath = "Interface\\AddOns\\" .. tostring(ADDON_NAME) .. "\\fonts\\"
-- Der Pfad wird absichtlich über ADDON_NAME aufgebaut.
-- Damit bleiben die Font-Einträge korrekt, auch wenn der Addon-Ordner oder
-- die TOC-Datei später noch einmal umbenannt werden.

-- Für Combat Text funktionieren klassische Addon-Fontpfade in WoW am zuverlässigsten.
-- Darum zeigen alle Einträge auf den separaten fonts-Ordner im Addon.
BeavisQoL_CustomFonts = {
    { key = "anton", label = "Anton", path = fontBasePath .. "Anton-Regular.ttf" },
    { key = "archivo_black", label = "Archivo Black", path = fontBasePath .. "ArchivoBlack-Regular.ttf" },
    { key = "audiowide", label = "Audiowide", path = fontBasePath .. "Audiowide-Regular.ttf" },
    { key = "barlow_condensed_bold", label = "Barlow Condensed Bold", path = fontBasePath .. "BarlowCondensed-Bold.ttf" },
    { key = "bangers", label = "Bangers", path = fontBasePath .. "Bangers.ttf" },
    { key = "bebas_neue", label = "Bebas Neue", path = fontBasePath .. "BebasNeue-Regular.ttf" },
    { key = "black_ops_one", label = "Black Ops One", path = fontBasePath .. "BlackOpsOne-Regular.ttf" },
    { key = "bowlby_one_sc", label = "Bowlby One SC", path = fontBasePath .. "BowlbyOneSC-Regular.ttf" },
    { key = "kanit_bold", label = "Kanit Bold", path = fontBasePath .. "Kanit-Bold.ttf" },
    { key = "pepsi_modern", label = "Pepsi Modern", path = fontBasePath .. "pepsi_modern.ttf" },
    { key = "rajdhani_bold", label = "Rajdhani Bold", path = fontBasePath .. "Rajdhani-Bold.ttf" },
    { key = "righteous", label = "Righteous", path = fontBasePath .. "Righteous-Regular.ttf" },
    { key = "roboto_bold", label = "Roboto Bold", path = fontBasePath .. "Roboto-Bold.ttf" },
    { key = "russo_one", label = "Russo One", path = fontBasePath .. "RussoOne-Regular.ttf" },
    { key = "sturkopf", label = "Sturkopf", path = fontBasePath .. "Sturkopf.ttf" },
    { key = "zero_cool", label = "Zero Cool", path = fontBasePath .. "ZeroCool.ttf" },
}
