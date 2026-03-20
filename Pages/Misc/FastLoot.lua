local ADDON_NAME, BeavisAddon = ...

BeavisAddon.Misc = BeavisAddon.Misc or {}
local Misc = BeavisAddon.Misc

-- Gemeinsame Misc-DB mit allen Defaults an einer Stelle pro Modul.
function Misc.GetMiscDB()
    BeavisAddonDB = BeavisAddonDB or {}
    BeavisAddonDB.misc = BeavisAddonDB.misc or {}

    if BeavisAddonDB.misc.autoSellJunk == nil then
        BeavisAddonDB.misc.autoSellJunk = false
    end

    if BeavisAddonDB.misc.autoRepair == nil then
        BeavisAddonDB.misc.autoRepair = false
    end

    if BeavisAddonDB.misc.autoRepairGuild == nil then
        BeavisAddonDB.misc.autoRepairGuild = false
    end

    if BeavisAddonDB.misc.easyDelete == nil then
        BeavisAddonDB.misc.easyDelete = false
    end

    if BeavisAddonDB.misc.fastLoot == nil then
        BeavisAddonDB.misc.fastLoot = false
    end

    return BeavisAddonDB.misc
end

function Misc.IsFastLootEnabled()
    return Misc.GetMiscDB().fastLoot == true
end

function Misc.SetFastLootEnabled(value)
    Misc.GetMiscDB().fastLoot = value and true or false
end

-- Den Blizzard-Autoloot-Modifier respektieren wir bewusst, damit das Standardverhalten nicht "falsch" wirkt.
local function ShouldFastLoot()
    return Misc.IsFastLootEnabled() and not IsModifiedClick("AUTOLOOTTOGGLE")
end

-- Wir looten rückwärts durch die Slots, damit das Entfernen eines Eintrags die noch offenen Indizes nicht verschiebt.
function Misc.TryFastLoot()
    if not ShouldFastLoot() then
        return
    end

    for slot = GetNumLootItems(), 1, -1 do
        local _, _, _, _, _, locked = GetLootSlotInfo(slot)

        if not locked then
            LootSlot(slot)
        end
    end
end

-- LOOT_READY für das eigentliche Loopen, LOOT_OPENED für das direkte Verstecken des Frames.
local FastLootWatcher = CreateFrame("Frame")
FastLootWatcher:RegisterEvent("LOOT_READY")
FastLootWatcher:RegisterEvent("LOOT_OPENED")

FastLootWatcher:SetScript("OnEvent", function(_, event)
    if event == "LOOT_READY" then
        Misc.TryFastLoot()
        return
    end

    if event == "LOOT_OPENED" and ShouldFastLoot() and LootFrame and LootFrame:IsShown() then
        LootFrame:Hide()
    end
end)
