local ADDON_NAME, BeavisQoL = ...

--[[
Core.lua ist bewusst sehr klein gehalten.

Diese Datei hat nur zwei Aufgaben:
1. eine gemeinsame Sammelstelle für alle Seiten-Frames vorbereiten
2. den Slash-Command `/beavis` registrieren

Alles, was sichtbar gebaut wird, passiert später in UI.lua und den
einzelnen Seiten-Dateien.
]]

-- Hier sammeln die Seiten-Dateien ihre Frames ein.
BeavisQoL.Pages = BeavisQoL.Pages or {}

function BeavisQoL.RefreshLocale()
    if BeavisQoL.UpdateUI then
        BeavisQoL.UpdateUI()
    end

    if BeavisQoL.UpdateTree then
        BeavisQoL.UpdateTree()
    end

    if BeavisQoL.UpdateHome then
        BeavisQoL.UpdateHome()
    end

    if BeavisQoL.UpdateVersion then
        BeavisQoL.UpdateVersion()
    end

    if BeavisQoL.UpdateSettings then
        BeavisQoL.UpdateSettings()
    end

    if BeavisQoL.UpdateLevelTime then
        BeavisQoL.UpdateLevelTime()
    end

    if BeavisQoL.UpdateItemLevelGuide then
        BeavisQoL.UpdateItemLevelGuide()
    end

    if BeavisQoL.UpdateQuestCheck then
        BeavisQoL.UpdateQuestCheck()
    end

    local refreshablePages = {
        BeavisQoL.Pages.Misc,
        BeavisQoL.Pages.LFG,
        BeavisQoL.Pages.PetStuff,
        BeavisQoL.Pages.DamageText,
        BeavisQoL.Pages.Stats,
        BeavisQoL.Pages.WeeklyKeys,
        BeavisQoL.Pages.Logging,
        BeavisQoL.Pages.Checklist,
    }

    for _, page in ipairs(refreshablePages) do
        if page and page.RefreshState then
            page:RefreshState()
        end
    end
end

-- Initialisiere SavedVariables nach dem Laden
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == ADDON_NAME then
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.settings = BeavisQoLDB.settings or {
            lockWindow = false,
            hideMinimap = false,
        }
        BeavisQoLDB.minimap = BeavisQoLDB.minimap or {}
        BeavisQoLDB.minimap.hide = BeavisQoLDB.settings.hideMinimap or BeavisQoLDB.minimap.hide or false
        BeavisQoLCharDB = BeavisQoLCharDB or {}

        -- Aktualisiere die Settings-Checkboxen
        if BeavisQoL.UpdateSettings then
            BeavisQoL.UpdateSettings()
        end

        if BeavisQoL.RefreshLocale then
            BeavisQoL.RefreshLocale()
        end

        -- Erzwinge Minimap-Button-Status bei jedem Addon-Load:
        if BeavisQoL.MinimapIcon then
            BeavisQoL.MinimapIcon:Refresh(ADDON_NAME, BeavisQoLDB.minimap)
        end
    end
end)

-- Blizzard liest Slash-Commands über genau diese beiden Globals aus:
-- SLASH_<NAME><nummer> definiert die Befehle
-- SlashCmdList["<NAME>"] hinterlegt die Funktion dazu.
SLASH_BEAVIS1 = "/beavis"
SlashCmdList["BEAVIS"] = function(msg)
    -- Der Slash-Command macht nur das Fenster auf und zu. Alles andere läuft über die UI.
    -- `msg` wäre der Text hinter `/beavis`, wird aktuell aber noch nicht gebraucht.
    if not BeavisQoL.Frame then
        return
    end

    if BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Hide()
    else
        BeavisQoL.Frame:Show()
    end
end
