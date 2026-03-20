local ADDON_NAME, BeavisAddon = ...

-- Eingebettete Libraries holen
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Falls eine Library doch nicht geladen wurde, Datei sauber abbrechen
if not LDB or not LDBIcon then
    return
end

-- SavedVariables vorbereiten
BeavisAddonDB = BeavisAddonDB or {}
BeavisAddonDB.minimap = BeavisAddonDB.minimap or {
    hide = false,
}

-- Hilfsfunktion: Hauptfenster umschalten
local function ToggleMainWindow()
    if not BeavisAddon.Frame then
        return
    end

    if BeavisAddon.Frame:IsShown() then
        BeavisAddon.Frame:Hide()
    else
        BeavisAddon.Frame:Show()
    end
end

-- LibDataBroker-Objekt anlegen
local launcher = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = "Beavis Mega Addon",
    icon = "Interface\\AddOns\\BeavisAddon\\Media\\logo.tga",

    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleMainWindow()
        elseif button == "RightButton" then
            print("BeavisAddon: Rechtsklick erkannt")
        end
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end

        tooltip:AddLine("Beavis Mega Addon", 1, 0.82, 0)
        tooltip:AddLine(" ")
        tooltip:AddLine("Linksklick: Fenster öffnen / schließen", 1, 1, 1)
        tooltip:AddLine("Rechtsklick: Platzhalter", 0.8, 0.8, 0.8)
        tooltip:AddLine("Drag: Position ändern", 1, 1, 1)
    end,
})

-- Minimap-Button registrieren
LDBIcon:Register(ADDON_NAME, launcher, BeavisAddonDB.minimap)

-- Referenz im Addon speichern
BeavisAddon.MinimapLauncher = launcher
BeavisAddon.MinimapIcon = LDBIcon