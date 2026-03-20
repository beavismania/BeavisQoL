local ADDON_NAME, BeavisAddon = ...

BeavisAddon.Pages = BeavisAddon.Pages or {}

SLASH_BEAVIS1 = "/beavis"
SlashCmdList["BEAVIS"] = function(msg)
    if not BeavisAddon.Frame then
        return
    end

    if BeavisAddon.Frame:IsShown() then
        BeavisAddon.Frame:Hide()
    else
        BeavisAddon.Frame:Show()
    end
end