local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

-- Diese Datei enthaelt nur die eigentliche Verkaufs-Automatik.
-- Anzeige und Schalter dafuer liegen auf der Komfort-Seite.

-- Die kleinen API-Fallbacks halten das Modul robuster gegen Blizzard-Umstellungen:
-- Je nach Client-Version liegen dieselben Infos teils unter C_* APIs,
-- teils noch unter den aelteren globalen Funktionen.
local GetItemDetails = (C_Item and C_Item.GetItemInfo) or rawget(_G, "GetItemInfo")
local GetCoinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")

-- Alle Misc-Module greifen auf dieselbe kleine Unter-DB zu.
-- Die Defaults bleiben deshalb absichtlich an mehreren Stellen gleich aufgebaut.
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

function Misc.IsAutoSellJunkEnabled()
    return Misc.GetMiscDB().autoSellJunk == true
end

function Misc.SetAutoSellJunkEnabled(value)
    Misc.GetMiscDB().autoSellJunk = value and true or false
end

-- Wir verkaufen die Items bewusst selbst aus den Bags heraus.
-- Das ist verlaesslicher, als sich komplett auf eine Komfort-API des MerchantFrames zu verlassen.
function Misc.SellAllJunk()
    if not Misc.IsAutoSellJunkEnabled() then
        return
    end

    local logging = BeavisQoL.Logging
    local totalEarned = 0
    local itemsSold = 0
    local soldItemEntries = {}
    local soldItemLookup = {}

    if logging then
        logging.suspendMerchantCapture = true
    end

    local function AddSoldItem(itemLabel, quantity, unitAmount)
        local cleanLabel = itemLabel or L("AUTOSELL_UNKNOWN_ITEM")
        local cleanQuantity = math.max(1, tonumber(quantity) or 1)
        local cleanUnitAmount = math.max(0, tonumber(unitAmount) or 0)
        local existingEntry = soldItemLookup[cleanLabel]

        if existingEntry then
            existingEntry.quantity = existingEntry.quantity + cleanQuantity
            existingEntry.amount = existingEntry.amount + (cleanUnitAmount * cleanQuantity)
            existingEntry.unitAmount = cleanUnitAmount > 0 and cleanUnitAmount or existingEntry.unitAmount
            return
        end

        local newEntry = {
            label = cleanLabel,
            quantity = cleanQuantity,
            amount = cleanUnitAmount * cleanQuantity,
            unitAmount = cleanUnitAmount > 0 and cleanUnitAmount or nil,
        }

        soldItemLookup[cleanLabel] = newEntry
        soldItemEntries[#soldItemEntries + 1] = newEntry
    end

    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            -- quality == 0 entspricht grauen Items.
            if itemInfo and itemInfo.hyperlink and itemInfo.quality == 0 then
                -- GetItemInfo/GetItemDetails liefert sehr viele Werte zurueck.
                -- Wir lesen hier Name und Vendor-Preis in einem Schritt aus.
                local itemName, _, _, _, _, _, _, _, _, _, sellPrice = GetItemDetails(itemInfo.hyperlink)

                if sellPrice > 0 then
                    local stackCount = itemInfo.stackCount or 1

                    totalEarned = totalEarned + (sellPrice * stackCount)
                    itemsSold = itemsSold + 1
                    AddSoldItem(itemName or itemInfo.hyperlink, stackCount, sellPrice)
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end

    if itemsSold > 0 then
        if logging and logging.RecordVendorSale then
            local soldItems = {}

            for _, entry in ipairs(soldItemEntries) do
                soldItems[#soldItems + 1] = {
                    label = entry.label,
                    quantity = entry.quantity,
                    amount = entry.amount,
                    unitAmount = entry.unitAmount,
                }
            end

            logging.RecordVendorSale(totalEarned, itemsSold, L("AUTOSELL_JUNK"), soldItems)
        end

        print(L("AUTOSELL_SUMMARY"):format(itemsSold, GetCoinText(totalEarned)))
    end

    if logging then
        logging.suspendMerchantCapture = false
    end
end

-- Ein einziges Merchant-Event reicht hier. Alles Weitere entscheidet die Funktion selbst.
local MerchantWatcher = CreateFrame("Frame")
MerchantWatcher:RegisterEvent("MERCHANT_SHOW")

MerchantWatcher:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        Misc.SellAllJunk()
    end
end)
