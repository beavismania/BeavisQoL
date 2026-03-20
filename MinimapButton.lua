local ADDON_NAME, BeavisQoL = ...

-- Die beiden LDB-Bibliotheken sind die Grundlage für den Minimap-Button.
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

-- Ohne beide Libraries gibt es hier nichts zu tun.
if not LDB or not LDBIcon then
    return
end

local addonTitle = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or ADDON_NAME

-- Position und Sichtbarkeit sollen zwischen Sessions erhalten bleiben.
-- Genau diese Struktur erwartet LibDBIcon später für sein internes Speichern.
BeavisQoLDB = BeavisQoLDB or {}
BeavisQoLDB.minimap = BeavisQoLDB.minimap or {
    hide = false,
}

-- Slash-Command und Minimap-Button sollen sich gleich verhalten.
local function ToggleMainWindow()
    if not BeavisQoL.Frame then
        return
    end

    if BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Hide()
    else
        BeavisQoL.Frame:Show()
    end
end

-- Linksklick öffnet das Fenster, Shift-Klick lädt die UI neu.
local launcher = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = addonTitle,
    icon = "Interface\\AddOns\\BeavisQoL\\Media\\logo.tga",

    OnClick = function(_, button)
        -- Shift wird hier bewusst als globaler Schnellbefehl priorisiert.
        -- So funktioniert das Reloaden unabhängig von der Maustaste immer gleich.
        -- Shift hat Vorrang, damit der schnelle Reload immer klappt.
        if IsShiftKeyDown() then
            ReloadUI()
        elseif button == "LeftButton" then
            ToggleMainWindow()
        end
    end,

    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
            return
        end

        -- Der Tooltip zeigt nur die drei Aktionen, die der Button wirklich kann.
        tooltip:AddLine(addonTitle, 1, 0.82, 0)
        tooltip:AddLine(" ")
        tooltip:AddLine("Linksklick: Fenster öffnen / schließen", 1, 1, 1)
        tooltip:AddLine("Shift-Klick: UI neu laden", 1, 1, 1)
        tooltip:AddLine("Drag: Position ändern", 1, 1, 1)
    end,
})

-- LibDBIcon kümmert sich um Position, Anzeigen und Verstecken.
LDBIcon:Register(ADDON_NAME, launcher, BeavisQoLDB.minimap)

-- Die Referenzen behalten wir, falls später noch Einstellungen dazukommen.
BeavisQoL.MinimapLauncher = launcher
BeavisQoL.MinimapIcon = LDBIcon
