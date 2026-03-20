local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
-- FastLoot lebt komplett event-getrieben:
-- LOOT_READY = Beute einsammeln
-- LOOT_OPENED = Fenster bei Bedarf direkt wieder ausblenden.

-- Gemeinsame Misc-DB mit allen Defaults an einer Stelle pro Modul.
function Misc.GetMiscDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.misc = BeavisQoLDB.misc or {}

    if BeavisQoLDB.misc.autoSellJunk == nil then
        BeavisQoLDB.misc.autoSellJunk = false
    end

    if BeavisQoLDB.misc.autoRepair == nil then
        BeavisQoLDB.misc.autoRepair = false
    end

    if BeavisQoLDB.misc.autoRepairGuild == nil then
        BeavisQoLDB.misc.autoRepairGuild = false
    end

    if BeavisQoLDB.misc.easyDelete == nil then
        BeavisQoLDB.misc.easyDelete = false
    end

    if BeavisQoLDB.misc.fastLoot == nil then
        BeavisQoLDB.misc.fastLoot = false
    end

    return BeavisQoLDB.misc
end

function Misc.IsFastLootEnabled()
    return Misc.GetMiscDB().fastLoot == true
end

function Misc.SetFastLootEnabled(value)
    Misc.GetMiscDB().fastLoot = value and true or false
end

-- Die kleine Guard-Funktion buendelt das Schalter-Setting mit dem
-- Blizzard-Autoloot-Modifier, damit das Standardverhalten respektiert wird.

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
