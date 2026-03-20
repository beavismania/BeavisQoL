local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
-- Die kleinen API-Fallbacks halten das Modul robuster gegen Blizzard-Umstellungen:
-- je nach Client-Version liegen dieselben Infos teils unter C_* APIs,
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
-- Das ist verlässlicher, als sich komplett auf eine Komfort-API des MerchantFrames zu verlassen.
function Misc.SellAllJunk()
    if not Misc.IsAutoSellJunkEnabled() then
        return
    end

    local totalEarned = 0
    local itemsSold = 0

    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            -- quality == 0 entspricht grauen Items.
            if itemInfo and itemInfo.hyperlink and itemInfo.quality == 0 then
                -- GetItemInfo/GetItemDetails liefert sehr viele Werte zurueck.
                -- Mit select(11, ...) greifen wir gezielt den Vendor-Preis ab.
                local sellPrice = select(11, GetItemDetails(itemInfo.hyperlink)) or 0

                if sellPrice > 0 then
                    totalEarned = totalEarned + (sellPrice * (itemInfo.stackCount or 1))
                    itemsSold = itemsSold + 1
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end

    if itemsSold > 0 then
        print("Beavis QoL: " .. itemsSold .. " Junk-Item(s) verkauft für " .. GetCoinText(totalEarned) .. ".")
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
