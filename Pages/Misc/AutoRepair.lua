local ADDON_NAME, BeavisAddon = ...

BeavisAddon.Misc = BeavisAddon.Misc or {}
local Misc = BeavisAddon.Misc
local GetCoinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")

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

    -- Wenn gewünscht, bekommt die Gilde den ersten Versuch.
    if db.autoRepairGuild and CanGuildBankRepair and CanGuildBankRepair() then
        RepairAllItems(true)
        print("Beavis QoL: Reparatur über die Gilde durchgeführt.")
        return
    end

    if GetMoney() >= repairCost then
        RepairAllItems(false)
        print("Beavis QoL: Reparatur für " .. GetCoinText(repairCost) .. " durchgeführt.")
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

