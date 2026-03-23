local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local GetCoinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")

-- Diese Datei enthält nur die eigentliche Reparatur-Automatik.
-- Der sichtbare Schalter dafür sitzt auf der Komfort-Seite in `Pages/Misc.lua`.

-- AutoRepair teilt sich wie die anderen Misc-Module dieselbe Unter-DB.
-- Dadurch kann die Misc-Seite später alle Schalter an einer Stelle lesen.

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

function Misc.IsAutoRepairEnabled()
    return Misc.GetMiscDB().autoRepair == true
end

function Misc.SetAutoRepairEnabled(value)
    local db = Misc.GetMiscDB()
    db.autoRepair = value and true or false

    -- Ohne Auto Repair hat die Gildenoption keinen Sinn und wird direkt mit abgeschaltet.
    if not db.autoRepair then
        db.autoRepairGuild = false
    end
end

function Misc.IsAutoRepairGuildEnabled()
    return Misc.GetMiscDB().autoRepairGuild == true
end

function Misc.SetAutoRepairGuildEnabled(value)
    local db = Misc.GetMiscDB()

    -- Schutz, falls die UI oder ein anderer Aufruf die Reihenfolge einmal nicht einhält.
    if not db.autoRepair then
        db.autoRepairGuild = false
        return
    end

    db.autoRepairGuild = value and true or false
end

-- Die Reparaturlogik lebt komplett hier, damit die UI nur noch einen einfachen Schalter braucht.
function Misc.TryAutoRepair()
    local db = Misc.GetMiscDB()

    if not db.autoRepair then
        return
    end

    if not CanMerchantRepair or not CanMerchantRepair() then
        return
    end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or not repairCost or repairCost <= 0 then
        return
    end
    -- Die Reihenfolge ist absichtlich:
    -- 1. optionaler Guild-Bank-Versuch
    -- 2. sonst eigenes Gold
    -- So wird persönliches Gold nur als Fallback verwendet.

    -- Wenn gewünscht, bekommt die Gilde den ersten Versuch.
    if db.autoRepairGuild and CanGuildBankRepair and CanGuildBankRepair() then
        RepairAllItems(true)
        print(L("AUTOREPAIR_GUILD_DONE"))
        return
    end

    if GetMoney() >= repairCost then
        RepairAllItems(false)
        print(L("AUTOREPAIR_DONE"):format(GetCoinText(repairCost)))
    end
end

-- Ein Merchant-Event reicht hier, weil die Funktion selbst alle nötigen Guards enthält.
local MerchantRepairWatcher = CreateFrame("Frame")
MerchantRepairWatcher:RegisterEvent("MERCHANT_SHOW")

MerchantRepairWatcher:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        Misc.TryAutoRepair()
    end
end)

