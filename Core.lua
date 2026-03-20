local ADDON_NAME, BeavisAddon = ...

-- Hier sammeln die Seiten-Dateien ihre Frames ein.
BeavisAddon.Pages = BeavisAddon.Pages or {}

SLASH_BEAVIS1 = "/beavis"
SlashCmdList["BEAVIS"] = function(msg)
    -- Der Slash-Command macht nur das Fenster auf und zu. Alles andere läuft über die UI.
    if not BeavisAddon.Frame then
        return
    end

    if BeavisAddon.Frame:IsShown() then
        BeavisAddon.Frame:Hide()
    else
        BeavisAddon.Frame:Show()
    end
end
