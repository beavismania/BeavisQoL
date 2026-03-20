local ADDON_NAME, BeavisQoL = ...

-- Hier sammeln die Seiten-Dateien ihre Frames ein.
BeavisQoL.Pages = BeavisQoL.Pages or {}

-- Blizzard liest Slash-Commands ueber genau diese beiden Globals aus:
-- SLASH_<NAME><nummer> definiert die Befehle
-- SlashCmdList["<NAME>"] hinterlegt die Funktion dazu.
SLASH_BEAVIS1 = "/beavis"
SlashCmdList["BEAVIS"] = function(msg)
    -- Der Slash-Command macht nur das Fenster auf und zu. Alles andere läuft über die UI.
    if not BeavisQoL.Frame then
        return
    end

    if BeavisQoL.Frame:IsShown() then
        BeavisQoL.Frame:Hide()
    else
        BeavisQoL.Frame:Show()
    end
end
