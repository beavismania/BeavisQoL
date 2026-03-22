local ADDON_NAME, BeavisQoL = ...

local Content = BeavisQoL.Content
local L = BeavisQoL.L

BeavisQoL.Logging = BeavisQoL.Logging or {}
local Logging = BeavisQoL.Logging

--[[
Logging.lua ist ein Sammelmodul fuer mehrere Gold- und Handelsprotokolle.

Die Datei besteht grob aus drei Schichten:
1. Datenspeicherung und Aufraeumen
2. Laufzeit-Erkennung von Geld- und Item-Aenderungen
3. Darstellung im Logging-Modul des Hauptfensters

Beim Lesen am besten in genau dieser Reihenfolge vorgehen.
]]

local GetCoinText = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or rawget(_G, "GetCoinTextureString")
local GetItemDetails = (C_Item and C_Item.GetItemInfo) or rawget(_G, "GetItemInfo")

local SECONDS_PER_DAY = 86400
local SALES_LOG_RETENTION_SECONDS = 30 * SECONDS_PER_DAY
local REPAIR_LOG_RETENTION_SECONDS = 30 * SECONDS_PER_DAY
local MONEY_LOG_RETENTION_SECONDS = 365 * SECONDS_PER_DAY

local MAX_SALES_LOG_ENTRIES = 10000
local MAX_REPAIR_LOG_ENTRIES = 10000
local MAX_MONEY_LOG_ENTRIES = 50000
local MAX_REPAIR_DAY_ENTRIES = 400

local PageLogging

local SalesPanel
local RepairPanel
local IncomePanel
local ExpensePanel
local CleanupPopup

local trackedMoney = nil
local lastRepairAllCostSeen = 0
local isMerchantOpen = false
local isMailOpen = false
local isAuctionOpen = false
local isTradeOpen = false
local isTaxiOpen = false
local isTrainerOpen = false
local recentQuestUntil = 0
local recentLootUntil = 0
local moneySuppressions = {}
local pendingAuctionPost = {
    timestamp = 0,
    amount = 0,
    note = nil,
    items = nil,
}
local pendingVendorSale = {
    entries = {},
}
local recentAuctionMailLoot = {
    index = 0,
    expiresAt = 0,
}
local expandedSalesEntries = {}
local expandedRepairDays = {}

local function GetTimestamp()
    -- Bevorzugt Serverzeit, damit die Logzeiten nicht von der lokalen
    -- Rechneruhr des Spielers abhaengen.
    if GetServerTime then
        return GetServerTime()
    end

    return time()
end

local function GetNow()
    if GetTime then
        return GetTime()
    end

    return 0
end

local function FormatCoins(amount)
    if not amount or amount <= 0 then
        return "0"
    end

    if GetCoinText then
        return GetCoinText(amount)
    end

    return tostring(amount)
end

local function FormatTimestamp(timestamp)
    return date("%d.%m.%Y %H:%M", timestamp or GetTimestamp())
end

local function FormatDayKey(dayKey)
    local year, month, day = string.match(dayKey or "", "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not year then
        return dayKey or "-"
    end

    return string.format("%s.%s.%s", day, month, year)
end

local function FormatClockTime(timestamp)
    return date("%H:%M", timestamp or GetTimestamp())
end

local function GetDayKey(timestamp)
    return date("%Y-%m-%d", timestamp or GetTimestamp())
end

local function TrimArray(array, maxEntries)
    while #array > maxEntries do
        table.remove(array, 1)
    end
end

local function PruneTimestampedEntries(entries, cutoffTimestamp)
    if type(entries) ~= "table" then
        return
    end

    for index = #entries, 1, -1 do
        local entry = entries[index]
        if type(entry) ~= "table" or type(entry.timestamp) ~= "number" or entry.timestamp < cutoffTimestamp then
            table.remove(entries, index)
        end
    end
end

local function RequestLoggingPageRefresh()
    if PageLogging and PageLogging.RefreshState and PageLogging:IsShown() then
        PageLogging:RefreshState()
    end
end

local function ClearExpandedLoggingRows()
    expandedSalesEntries = {}
    expandedRepairDays = {}
end

local function RebuildRepairDailyTotalsFromLog(db)
    db.repairDailyTotals = {}

    for _, entry in ipairs(db.repairLog) do
        local dayKey = GetDayKey(entry.timestamp)

        db.repairDailyTotals[dayKey] = db.repairDailyTotals[dayKey] or {
            total = 0,
            personal = 0,
        }

        db.repairDailyTotals[dayKey].total = db.repairDailyTotals[dayKey].total + (entry.amount or 0)

        if (entry.source or L("LOGGING_OWN_GOLD")) ~= L("LOGGING_GUILD") then
            db.repairDailyTotals[dayKey].personal = db.repairDailyTotals[dayKey].personal + (entry.amount or 0)
        end
    end
end

local function PruneRepairDailyTotals(db)
    local keys = {}
    local oldestAllowedDayKey = GetDayKey(GetTimestamp() - REPAIR_LOG_RETENTION_SECONDS)

    for dayKey in pairs(db.repairDailyTotals) do
        if dayKey < oldestAllowedDayKey then
            db.repairDailyTotals[dayKey] = nil
        else
            keys[#keys + 1] = dayKey
        end
    end

    table.sort(keys)

    while #keys > MAX_REPAIR_DAY_ENTRIES do
        db.repairDailyTotals[keys[1]] = nil
        table.remove(keys, 1)
    end
end

local function NormalizeAndPruneDB(db)
    -- Alle automatischen Aufraeumregeln laufen zentral hier zusammen.
    local now = GetTimestamp()

    PruneTimestampedEntries(db.salesLog, now - SALES_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.repairLog, now - REPAIR_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.incomeLog, now - MONEY_LOG_RETENTION_SECONDS)
    PruneTimestampedEntries(db.expenseLog, now - MONEY_LOG_RETENTION_SECONDS)

    TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
    TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)
    TrimArray(db.incomeLog, MAX_MONEY_LOG_ENTRIES)
    TrimArray(db.expenseLog, MAX_MONEY_LOG_ENTRIES)

    RebuildRepairDailyTotalsFromLog(db)
    PruneRepairDailyTotals(db)
end

function Logging.ClearLogsOlderThanDays(days)
    -- Manueller Aufraeumbefehl fuer das Popup auf der Logging-Seite.
    local db = Logging.GetDB()

    if days == "all" or days == 0 then
        db.salesLog = {}
        db.repairLog = {}
        db.incomeLog = {}
        db.expenseLog = {}
        db.repairDailyTotals = {}
    else
        local numericDays = tonumber(days)
        if not numericDays or numericDays < 0 then
            return
        end

        local cutoffTimestamp = GetTimestamp() - (numericDays * SECONDS_PER_DAY)

        PruneTimestampedEntries(db.salesLog, cutoffTimestamp)
        PruneTimestampedEntries(db.repairLog, cutoffTimestamp)
        PruneTimestampedEntries(db.incomeLog, cutoffTimestamp)
        PruneTimestampedEntries(db.expenseLog, cutoffTimestamp)

        TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
        TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)
        TrimArray(db.incomeLog, MAX_MONEY_LOG_ENTRIES)
        TrimArray(db.expenseLog, MAX_MONEY_LOG_ENTRIES)

        RebuildRepairDailyTotalsFromLog(db)
        PruneRepairDailyTotals(db)
    end

    ClearExpandedLoggingRows()
    RequestLoggingPageRefresh()
end

function Logging.GetDB()
    -- Zentraler Einstieg fuer die Logging-SavedVariables.
    -- Diese Funktion sorgt dafuer, dass alle benoetigten Tabellen existieren,
    -- bevor andere Funktionen auf sie zugreifen.
    BeavisQoLCharDB = BeavisQoLCharDB or {}
    BeavisQoLCharDB.logging = BeavisQoLCharDB.logging or {}

    local db = BeavisQoLCharDB.logging

    if type(db.salesLog) ~= "table" then
        db.salesLog = {}
    end

    if type(db.repairLog) ~= "table" then
        db.repairLog = {}
    end

    if type(db.incomeLog) ~= "table" then
        db.incomeLog = {}
    end

    if type(db.expenseLog) ~= "table" then
        db.expenseLog = {}
    end

    if type(db.repairDailyTotals) ~= "table" then
        db.repairDailyTotals = {}
    end

    NormalizeAndPruneDB(db)
    return db
end

local function AddMoneySuppression(direction, amount)
    -- Manche Aktionen erzeugen erst einen gezielten Logeintrag und kurz danach
    -- noch ein allgemeines PLAYER_MONEY-Ereignis. Diese kurze Sperre verhindert
    -- doppelte Erfassung desselben Geldbetrags.
    if amount <= 0 then
        return
    end

    moneySuppressions[#moneySuppressions + 1] = {
        direction = direction,
        amount = amount,
        expiresAt = GetNow() + 2.0,
    }
end

local function ConsumeMoneySuppression(direction, amount)
    local now = GetNow()

    for index = #moneySuppressions, 1, -1 do
        local entry = moneySuppressions[index]

        if now >= entry.expiresAt then
            table.remove(moneySuppressions, index)
        elseif entry.direction == direction and math.abs(entry.amount - amount) <= 1 then
            table.remove(moneySuppressions, index)
            return true
        end
    end

    return false
end

local function ShouldSkipAuctionMailLog(index)
    local now = GetNow()

    if recentAuctionMailLoot.index == index and now < recentAuctionMailLoot.expiresAt then
        return true
    end

    recentAuctionMailLoot.index = index
    recentAuctionMailLoot.expiresAt = now + 1.0
    return false
end

local function GetItemDisplayName(itemReference, fallbackName)
    if type(fallbackName) == "string" and fallbackName ~= "" then
        return fallbackName
    end

    if GetItemDetails and itemReference ~= nil then
        local itemName = GetItemDetails(itemReference)
        if type(itemName) == "string" and itemName ~= "" then
            return itemName
        end
    end

    if type(itemReference) == "number" and C_Item and C_Item.GetItemNameByID then
        local itemName = C_Item.GetItemNameByID(itemReference)
        if type(itemName) == "string" and itemName ~= "" then
            return itemName
        end
    end

    if type(itemReference) == "string" and itemReference ~= "" then
        local bracketName = string.match(itemReference, "%[(.-)%]")
        if bracketName and bracketName ~= "" then
            return bracketName
        end

        return itemReference
    end

    return L("UNKNOWN_ITEM")
end

local function BuildItemText(itemReference, quantity, fallbackName)
    local itemName = GetItemDisplayName(itemReference, fallbackName)
    local itemQuantity = math.max(1, tonumber(quantity) or 1)

    if itemQuantity > 1 then
        return string.format("%s x%d", itemName, itemQuantity)
    end

    return itemName
end

local function NormalizeItemTexts(items)
    -- Die UI soll spaeter immer mit derselben Item-Struktur arbeiten koennen.
    -- Deshalb normalisieren wir freie Texte und Tabellen direkt beim Speichern.
    if type(items) ~= "table" then
        return nil
    end

    local normalized = {}

    for _, itemData in ipairs(items) do
        if type(itemData) == "string" then
            local trimmed = string.match(itemData, "^%s*(.-)%s*$")

            if trimmed and trimmed ~= "" then
                normalized[#normalized + 1] = {
                    label = string.sub(trimmed, 1, 140),
                    quantity = 1,
                }
            end
        elseif type(itemData) == "table" then
            local label = itemData.label or itemData.name or itemData.text
            if type(label) == "string" then
                label = string.match(label, "^%s*(.-)%s*$")
            else
                label = nil
            end

            if label and label ~= "" then
                local quantity = math.max(1, tonumber(itemData.quantity) or 1)
                local amount = math.max(0, math.floor((tonumber(itemData.amount) or 0) + 0.5))
                local unitAmount = tonumber(itemData.unitAmount)

                if unitAmount and unitAmount > 0 then
                    unitAmount = math.floor(unitAmount + 0.5)
                else
                    unitAmount = nil
                end

                normalized[#normalized + 1] = {
                    label = string.sub(label, 1, 140),
                    quantity = quantity,
                    amount = amount > 0 and amount or nil,
                    unitAmount = unitAmount,
                }
            end
        end
    end

    if #normalized == 0 then
        return nil
    end

    return normalized
end

local function GetLogItemLabel(itemData)
    if type(itemData) == "table" then
        local label = itemData.label or itemData.name or itemData.text
        if type(label) == "string" and label ~= "" then
            return label
        end
    elseif type(itemData) == "string" and itemData ~= "" then
        return itemData
    end

    return L("UNKNOWN_ITEM")
end

local function GetLogItemQuantity(itemData)
    if type(itemData) == "table" then
        return math.max(1, tonumber(itemData.quantity) or 1)
    end

    return 1
end

local function GetLogItemAmount(itemData)
    if type(itemData) == "table" then
        local amount = tonumber(itemData.amount) or 0
        if amount > 0 then
            return math.floor(amount + 0.5)
        end
    end

    return nil
end

local function GetLogItemUnitAmount(itemData)
    if type(itemData) == "table" then
        local unitAmount = tonumber(itemData.unitAmount) or 0
        if unitAmount > 0 then
            return math.floor(unitAmount + 0.5)
        end
    end

    return nil
end

local function GetLogItemSummary(itemData)
    local label = GetLogItemLabel(itemData)
    local quantity = GetLogItemQuantity(itemData)

    if quantity > 1 then
        return string.format("%s x%d", label, quantity)
    end

    return label
end

local function BuildItemListSummary(items)
    if type(items) ~= "table" or #items == 0 then
        return nil
    end

    local itemTexts = {}

    for _, itemData in ipairs(items) do
        itemTexts[#itemTexts + 1] = GetLogItemSummary(itemData)
    end

    return table.concat(itemTexts, ", ")
end

local function BuildExpandedItemText(items)
    if type(items) ~= "table" or #items == 0 then
        return nil
    end

    local lines = {}

    for _, itemData in ipairs(items) do
        local quantity = GetLogItemQuantity(itemData)
        local amount = GetLogItemAmount(itemData)
        local unitAmount = GetLogItemUnitAmount(itemData)
        local baseText = GetLogItemSummary(itemData)

        if amount and amount > 0 then
            if quantity > 1 and unitAmount and unitAmount > 0 then
                baseText = string.format("%s | %s gesamt | %s pro Item", baseText, FormatCoins(amount), FormatCoins(unitAmount))
            else
                baseText = string.format("%s | %s", baseText, FormatCoins(amount))
            end
        end

        lines[#lines + 1] = "- " .. baseText
    end

    return table.concat(lines, "\n")
end

local function AppendSalesLog(amount, itemCount, source, timestamp, items)
    -- Verkaufslog und Geldlog bleiben getrennt:
    -- Das Verkaufslog zeigt die Item-Sicht, das Geldlog spaeter die Kategorie-Sicht.
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    db.salesLog[#db.salesLog + 1] = {
        timestamp = timestamp or GetTimestamp(),
        amount = amount,
        itemCount = itemCount or 0,
        source = source or L("LOGGING_SALE"),
        items = NormalizeItemTexts(items),
    }

    TrimArray(db.salesLog, MAX_SALES_LOG_ENTRIES)
end

local function AppendMoneyLog(direction, category, amount, note, timestamp, items)
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    local list = direction == "income" and db.incomeLog or db.expenseLog
    list[#list + 1] = {
        timestamp = timestamp or GetTimestamp(),
        amount = amount,
        category = category or L("LOGGING_MISC"),
        note = note,
        items = NormalizeItemTexts(items),
    }

    TrimArray(list, MAX_MONEY_LOG_ENTRIES)
end

local function AppendRepairLog(amount, source, timestamp)
    if amount <= 0 then
        return
    end

    local db = Logging.GetDB()
    local entryTimestamp = timestamp or GetTimestamp()
    local dayKey = GetDayKey(entryTimestamp)

    db.repairLog[#db.repairLog + 1] = {
        timestamp = entryTimestamp,
        amount = amount,
        source = source or L("LOGGING_OWN_GOLD"),
    }

    TrimArray(db.repairLog, MAX_REPAIR_LOG_ENTRIES)

    db.repairDailyTotals[dayKey] = db.repairDailyTotals[dayKey] or {
        total = 0,
        personal = 0,
    }

    db.repairDailyTotals[dayKey].total = db.repairDailyTotals[dayKey].total + amount

    if source ~= L("LOGGING_GUILD") then
        db.repairDailyTotals[dayKey].personal = db.repairDailyTotals[dayKey].personal + amount
    end

    PruneRepairDailyTotals(db)
end

local function DetermineMoneyCategory(direction)
    -- Wir leiten Kategorien ueber den zuletzt beobachteten Kontext ab:
    -- Haendler offen, Post offen, Quest eben abgegeben usw.
    local now = GetNow()

    if direction == "income" then
        if isMerchantOpen then
            return L("LOGGING_SALE"), L("LOGGING_VENDOR_SALE")
        end

        if isMailOpen then
            return L("LOGGING_MAIL"), L("LOGGING_MAILBOX")
        end

        if isAuctionOpen then
            return L("LOGGING_AUCTIONHOUSE"), L("LOGGING_AUCTIONHOUSE")
        end

        if isTradeOpen then
            return L("LOGGING_TRADE"), L("LOGGING_TRADE")
        end

        if recentQuestUntil > now then
            return L("LOGGING_QUEST"), L("LOGGING_QUEST_REWARD")
        end

        if recentLootUntil > now then
            return L("LOGGING_LOOT"), L("LOGGING_PICKED_UP")
        end

        return L("LOGGING_MISC"), nil
    end

    if isTaxiOpen then
        return L("LOGGING_FLIGHTMASTER"), nil
    end

    if isMerchantOpen then
        return L("LOGGING_VENDOR"), nil
    end

    if isMailOpen then
        return L("LOGGING_MAIL"), nil
    end

    if isAuctionOpen then
        return L("LOGGING_AUCTIONHOUSE"), nil
    end

    if isTradeOpen then
        return L("LOGGING_TRADE"), nil
    end

    if isTrainerOpen then
        return L("LOGGING_TRAINER"), nil
    end

    return L("LOGGING_MISC"), nil
end

local function RefreshRepairCostSnapshot()
    if not isMerchantOpen or not CanMerchantRepair or not CanMerchantRepair() then
        lastRepairAllCostSeen = 0
        return
    end

    local repairCost, canRepair = GetRepairAllCost()
    if canRepair and repairCost and repairCost > 0 then
        lastRepairAllCostSeen = repairCost
    else
        lastRepairAllCostSeen = 0
    end
end

local function ClearPendingVendorSales()
    wipe(pendingVendorSale.entries)
end

local function TrimPendingVendorSales()
    local now = GetNow()

    for index = #pendingVendorSale.entries, 1, -1 do
        local entry = pendingVendorSale.entries[index]
        if now >= (entry.expiresAt or 0) then
            table.remove(pendingVendorSale.entries, index)
        end
    end
end

local function MergePendingVendorItems(targetItems, sourceItems)
    if type(sourceItems) ~= "table" then
        return
    end

    local lookup = {}

    for _, itemData in ipairs(targetItems) do
        local key = string.format(
            "%s|%s",
            GetLogItemLabel(itemData),
            tostring(GetLogItemUnitAmount(itemData) or GetLogItemAmount(itemData) or 0)
        )
        lookup[key] = itemData
    end

    for _, itemData in ipairs(sourceItems) do
        local key = string.format(
            "%s|%s",
            GetLogItemLabel(itemData),
            tostring(GetLogItemUnitAmount(itemData) or GetLogItemAmount(itemData) or 0)
        )
        local existing = lookup[key]

        if existing then
            existing.quantity = GetLogItemQuantity(existing) + GetLogItemQuantity(itemData)

            local existingAmount = GetLogItemAmount(existing) or 0
            local addedAmount = GetLogItemAmount(itemData) or 0
            if existingAmount > 0 or addedAmount > 0 then
                existing.amount = existingAmount + addedAmount
            end

            local unitAmount = GetLogItemUnitAmount(existing) or GetLogItemUnitAmount(itemData)
            if unitAmount and unitAmount > 0 then
                existing.unitAmount = unitAmount
            end
        else
            local normalizedItems = NormalizeItemTexts({ itemData })
            if normalizedItems and normalizedItems[1] then
                local newEntry = normalizedItems[1]
                targetItems[#targetItems + 1] = newEntry
                lookup[key] = newEntry
            end
        end
    end
end

local function QueuePendingVendorSaleItem(itemReference, quantity, unitAmount, fallbackName)
    local cleanUnitAmount = math.max(0, math.floor((tonumber(unitAmount) or 0) + 0.5))
    if cleanUnitAmount <= 0 then
        return
    end

    local cleanQuantity = math.max(1, tonumber(quantity) or 1)
    local normalizedItems = NormalizeItemTexts({
        {
            label = GetItemDisplayName(itemReference, fallbackName),
            quantity = cleanQuantity,
            amount = cleanUnitAmount * cleanQuantity,
            unitAmount = cleanUnitAmount,
        }
    })

    if not normalizedItems or not normalizedItems[1] then
        return
    end

    TrimPendingVendorSales()
    pendingVendorSale.entries[#pendingVendorSale.entries + 1] = {
        expiresAt = GetNow() + 2.0,
        amount = cleanUnitAmount * cleanQuantity,
        itemCount = 1,
        items = normalizedItems,
    }
end

local function ConsumePendingVendorSale(amount)
    -- Versucht, vorher gemerkte Einzelverkaeufe zu einem passenden
    -- Gesamtbetrag aus PLAYER_MONEY zusammenzusetzen.
    TrimPendingVendorSales()

    local cleanAmount = math.max(0, math.floor((tonumber(amount) or 0) + 0.5))
    if cleanAmount <= 0 or #pendingVendorSale.entries == 0 then
        return nil
    end

    local totalAmount = 0
    local totalItemCount = 0
    local consumedIndices = {}
    local mergedItems = {}

    for index, entry in ipairs(pendingVendorSale.entries) do
        totalAmount = totalAmount + (entry.amount or 0)
        totalItemCount = totalItemCount + (entry.itemCount or 0)
        consumedIndices[#consumedIndices + 1] = index
        MergePendingVendorItems(mergedItems, entry.items)

        if math.abs(totalAmount - cleanAmount) <= 1 then
            for removeIndex = #consumedIndices, 1, -1 do
                table.remove(pendingVendorSale.entries, consumedIndices[removeIndex])
            end

            return {
                amount = totalAmount,
                itemCount = totalItemCount,
                items = #mergedItems > 0 and mergedItems or nil,
            }
        end

        if totalAmount > cleanAmount then
            break
        end
    end

    return nil
end

function Logging.RecordVendorSale(amount, itemCount, source, items)
    -- Oeffentliche Schnittstelle fuer itemisierte Haendlerverkaeufe,
    -- z. B. aus Auto Sell Junk oder unseren Vendor-Hooks.
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    local sourceText = source or L("LOGGING_AUTOSELL")

    AppendSalesLog(amount, itemCount, sourceText, timestamp, items)
    AppendMoneyLog("income", L("LOGGING_SALE"), amount, sourceText, timestamp, items)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

local function RecordAuctionHouseIncome(amount, note, items)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    AppendMoneyLog("income", L("LOGGING_AUCTIONHOUSE"), amount, note or L("LOGGING_SALE"), timestamp, items)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

local function RecordAuctionHouseExpense(amount, note, items)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    AppendMoneyLog("expense", L("LOGGING_AUCTIONHOUSE"), amount, note or L("LOGGING_COSTS"), timestamp, items)
    AddMoneySuppression("expense", amount)
    RequestLoggingPageRefresh()
end

local function RecordRepair(amount, source)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()
    local sourceText = source or L("LOGGING_OWN_GOLD")

    AppendRepairLog(amount, sourceText, timestamp)

    if sourceText ~= L("LOGGING_GUILD") then
        AppendMoneyLog("expense", L("LOGGING_REPAIR"), amount, sourceText, timestamp)
        AddMoneySuppression("expense", amount)
    end

    RequestLoggingPageRefresh()
end

local function RecordQuestReward(amount, questTitle)
    if amount <= 0 then
        return
    end

    local timestamp = GetTimestamp()

    AppendMoneyLog("income", L("LOGGING_QUEST"), amount, questTitle or L("LOGGING_QUEST_REWARD"), timestamp)
    AddMoneySuppression("income", amount)
    RequestLoggingPageRefresh()
end

function Logging.GetSalesLog()
    return Logging.GetDB().salesLog
end

function Logging.GetRepairLog()
    return Logging.GetDB().repairLog
end

function Logging.GetIncomeLog()
    return Logging.GetDB().incomeLog
end

function Logging.GetExpenseLog()
    return Logging.GetDB().expenseLog
end

function Logging.GetRepairDailyTotals()
    return Logging.GetDB().repairDailyTotals
end

local MoneyWatcher = CreateFrame("Frame")
MoneyWatcher:RegisterEvent("PLAYER_LOGIN")
MoneyWatcher:RegisterEvent("PLAYER_MONEY")
MoneyWatcher:RegisterEvent("QUEST_TURNED_IN")
MoneyWatcher:RegisterEvent("LOOT_OPENED")
MoneyWatcher:RegisterEvent("LOOT_CLOSED")
MoneyWatcher:RegisterEvent("MERCHANT_SHOW")
MoneyWatcher:RegisterEvent("MERCHANT_CLOSED")
MoneyWatcher:RegisterEvent("MERCHANT_UPDATE")
MoneyWatcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
MoneyWatcher:RegisterEvent("MAIL_SHOW")
MoneyWatcher:RegisterEvent("MAIL_CLOSED")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_SHOW")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_CLOSED")
MoneyWatcher:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
MoneyWatcher:RegisterEvent("TRADE_SHOW")
MoneyWatcher:RegisterEvent("TRADE_CLOSED")
MoneyWatcher:RegisterEvent("TAXIMAP_OPENED")
MoneyWatcher:RegisterEvent("TAXIMAP_CLOSED")
MoneyWatcher:RegisterEvent("TRAINER_SHOW")
MoneyWatcher:RegisterEvent("TRAINER_CLOSED")

MoneyWatcher:SetScript("OnEvent", function(_, event, ...)
    -- Dieser Watcher ist der Laufzeit-Sensor des Logging-Moduls.
    -- Er merkt sich Kontexte und verteilt Geldaenderungen danach in die
    -- richtigen Logs, sobald genug Informationen vorliegen.
    if event == "PLAYER_LOGIN" then
        Logging.GetDB()
        trackedMoney = GetMoney and GetMoney() or 0
        RefreshRepairCostSnapshot()
        return
    end

    if event == "QUEST_TURNED_IN" then
        local questID, _, moneyReward = ...
        recentQuestUntil = GetNow() + 2.5

        if type(moneyReward) == "number" and moneyReward > 0 then
            local questTitle = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
            RecordQuestReward(moneyReward, questTitle)
        end

        return
    end

    if event == "LOOT_OPENED" then
        recentLootUntil = GetNow() + 2.5
        return
    end

    if event == "LOOT_CLOSED" then
        recentLootUntil = math.max(recentLootUntil, GetNow() + 0.5)
        return
    end

    if event == "MERCHANT_SHOW" then
        isMerchantOpen = true
        RefreshRepairCostSnapshot()
        return
    end

    if event == "MERCHANT_CLOSED" then
        isMerchantOpen = false
        lastRepairAllCostSeen = 0
        ClearPendingVendorSales()
        return
    end

    if event == "MERCHANT_UPDATE" or event == "UPDATE_INVENTORY_DURABILITY" then
        RefreshRepairCostSnapshot()
        return
    end

    if event == "MAIL_SHOW" then
        isMailOpen = true
        return
    end

    if event == "MAIL_CLOSED" then
        isMailOpen = false
        return
    end

    if event == "AUCTION_HOUSE_SHOW" then
        isAuctionOpen = true
        return
    end

    if event == "AUCTION_HOUSE_CLOSED" then
        isAuctionOpen = false
        return
    end

    if event == "AUCTION_HOUSE_AUCTION_CREATED" then
        if GetNow() - (pendingAuctionPost.timestamp or 0) <= 5 then
            RecordAuctionHouseExpense(pendingAuctionPost.amount or 0, pendingAuctionPost.note, pendingAuctionPost.items)
        end

        pendingAuctionPost.timestamp = 0
        pendingAuctionPost.amount = 0
        pendingAuctionPost.note = nil
        pendingAuctionPost.items = nil
        return
    end

    if event == "TRADE_SHOW" then
        isTradeOpen = true
        return
    end

    if event == "TRADE_CLOSED" then
        isTradeOpen = false
        return
    end

    if event == "TAXIMAP_OPENED" then
        isTaxiOpen = true
        return
    end

    if event == "TAXIMAP_CLOSED" then
        isTaxiOpen = false
        return
    end

    if event == "TRAINER_SHOW" then
        isTrainerOpen = true
        return
    end

    if event == "TRAINER_CLOSED" then
        isTrainerOpen = false
        return
    end

    if event == "PLAYER_MONEY" then
        local newMoney = GetMoney and GetMoney() or 0

        if trackedMoney == nil then
            trackedMoney = newMoney
            return
        end

        local delta = newMoney - trackedMoney
        trackedMoney = newMoney

        if delta == 0 then
            return
        end

        local direction = delta > 0 and "income" or "expense"
        local amount = math.abs(delta)

        if ConsumeMoneySuppression(direction, amount) then
            return
        end

        local category, note = DetermineMoneyCategory(direction)
        local timestamp = GetTimestamp()

        if direction == "income" and category == L("LOGGING_SALE") then
            local pendingSale = ConsumePendingVendorSale(amount)
            if pendingSale then
                local sourceText = note or L("LOGGING_VENDOR_SALE")
                AppendMoneyLog(direction, category, amount, sourceText, timestamp, pendingSale.items)
                AppendSalesLog(amount, pendingSale.itemCount, sourceText, timestamp, pendingSale.items)
                RequestLoggingPageRefresh()
                return
            end
        end

        AppendMoneyLog(direction, category, amount, note, timestamp)

        if direction == "income" and category == L("LOGGING_SALE") then
            AppendSalesLog(amount, 0, note or L("LOGGING_VENDOR_SALE"), timestamp)
        end

        RequestLoggingPageRefresh()
    end
end)

local function SetPendingAuctionPost(amount, note, items)
    pendingAuctionPost.timestamp = GetNow()
    pendingAuctionPost.amount = amount or 0
    pendingAuctionPost.note = note
    pendingAuctionPost.items = items
end

local function TryRecordAuctionSaleMail(index)
    if ShouldSkipAuctionMailLog(index) then
        return
    end

    local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, count = GetInboxInvoiceInfo(index)
    if invoiceType ~= "seller" then
        return
    end

    local _, _, _, subject, money = GetInboxHeaderInfo(index)
    local amount = money or math.max(0, (bid or 0) + (deposit or 0) - (consignment or 0))
    local saleTarget = playerName and playerName ~= "" and L("LOGGING_SALE_TO"):format(playerName) or L("LOGGING_SALE")
    local items = { BuildItemText(nil, count or 1, itemName or subject) }
    RecordAuctionHouseIncome(amount, saleTarget, items)
end

local function InstallInboxMoneyHooks()
    if type(TakeInboxMoney) == "function" then
        local originalTakeInboxMoney = TakeInboxMoney
        TakeInboxMoney = function(index, ...)
            TryRecordAuctionSaleMail(index)
            return originalTakeInboxMoney(index, ...)
        end
    end

    if type(AutoLootMailItem) == "function" then
        local originalAutoLootMailItem = AutoLootMailItem
        AutoLootMailItem = function(index, ...)
            TryRecordAuctionSaleMail(index)
            return originalAutoLootMailItem(index, ...)
        end
    end
end

local function HookAuctionHouseActions()
    if not hooksecurefunc or not C_AuctionHouse then
        return
    end

    if C_AuctionHouse.PostItem then
        hooksecurefunc(C_AuctionHouse, "PostItem", function(itemLocation, duration, quantity)
            if not C_AuctionHouse.CalculateItemDeposit then
                return
            end

            local deposit = C_AuctionHouse.CalculateItemDeposit(itemLocation, duration, quantity) or 0
            local itemLink = C_Item and C_Item.GetItemLink and C_Item.GetItemLink(itemLocation)
            local items = { BuildItemText(itemLink, quantity) }
            SetPendingAuctionPost(deposit, "Einstellgebühr", items)
        end)
    end

    if C_AuctionHouse.PostCommodity then
        hooksecurefunc(C_AuctionHouse, "PostCommodity", function(itemLocation, duration, quantity)
            if not C_AuctionHouse.CalculateCommodityDeposit then
                return
            end

            local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemLocation, duration, quantity) or 0
            local itemLink = C_Item and C_Item.GetItemLink and C_Item.GetItemLink(itemLocation)
            local items = { BuildItemText(itemLink, quantity) }
            SetPendingAuctionPost(deposit, "Einstellgebühr", items)
        end)
    end

    if C_AuctionHouse.PlaceBid then
        hooksecurefunc(C_AuctionHouse, "PlaceBid", function(auctionID, bidPlaced)
            if not C_AuctionHouse.GetAuctionInfoByID then
                return
            end

            local info = C_AuctionHouse.GetAuctionInfoByID(auctionID)
            if type(info) ~= "table" then
                return
            end

            local buyout = info.buyoutAmount or 0
            if buyout <= 0 or bidPlaced ~= buyout then
                return
            end

            local quantity = info.quantity or 1
            local items = { BuildItemText(info.itemLink or (info.itemKey and info.itemKey.itemID), quantity) }
            RecordAuctionHouseExpense(bidPlaced, "Kauf", items)
        end)
    end

    if C_AuctionHouse.ConfirmCommoditiesPurchase then
        hooksecurefunc(C_AuctionHouse, "ConfirmCommoditiesPurchase", function(itemID, quantity)
            local remaining = quantity or 0
            local totalPrice = 0

            if not C_AuctionHouse.GetNumCommoditySearchResults or not C_AuctionHouse.GetCommoditySearchResultInfo then
                return
            end

            for index = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) do
                local info = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, index)
                if type(info) == "table" then
                    local availableQuantity = math.max(0, (info.quantity or 0) - (info.numOwnerItems or 0))
                    local boughtQuantity = math.min(remaining, availableQuantity)

                    if boughtQuantity > 0 then
                        totalPrice = totalPrice + (boughtQuantity * (info.unitPrice or 0))
                        remaining = remaining - boughtQuantity
                    end
                end

                if remaining <= 0 then
                    break
                end
            end

            if remaining > 0 or totalPrice <= 0 then
                return
            end

            local items = { BuildItemText(itemID, quantity) }
            RecordAuctionHouseExpense(totalPrice, "Kauf", items)
        end)
    end

    if TakeInboxMoney then
        hooksecurefunc("TakeInboxMoney", function(index)
            TryRecordAuctionSaleMail(index)
        end)
    end

    if AutoLootMailItem then
        hooksecurefunc("AutoLootMailItem", function(index)
            TryRecordAuctionSaleMail(index)
        end)
    end
end

local function HookVendorSaleActions()
    if not C_Container or type(C_Container.UseContainerItem) ~= "function" then
        return
    end

    local originalUseContainerItem = C_Container.UseContainerItem
    C_Container.UseContainerItem = function(bag, slot, ...)
        if isMerchantOpen and not Logging.suspendMerchantCapture and C_Container.GetContainerItemInfo then
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)

            if itemInfo and itemInfo.hyperlink then
                local itemName, _, _, _, _, _, _, _, _, _, sellPrice = GetItemDetails(itemInfo.hyperlink)
                if type(sellPrice) == "number" and sellPrice > 0 then
                    QueuePendingVendorSaleItem(itemInfo.hyperlink, itemInfo.stackCount or 1, sellPrice, itemName)
                end
            end
        end

        return originalUseContainerItem(bag, slot, ...)
    end
end

InstallInboxMoneyHooks()
HookAuctionHouseActions()
HookVendorSaleActions()

if hooksecurefunc and RepairAllItems then
    hooksecurefunc("RepairAllItems", function(useGuildBank)
        if lastRepairAllCostSeen and lastRepairAllCostSeen > 0 then
            RecordRepair(lastRepairAllCostSeen, useGuildBank and L("LOGGING_GUILD") or L("LOGGING_OWN_GOLD"))
            lastRepairAllCostSeen = 0
        end
    end)
end

local function CreateLogPanel(parent, anchorFrame, titleText, hintText)
    -- Alle vier Logging-Bereiche teilen sich absichtlich denselben Aufbau.
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -18)
    panel:SetPoint("TOPRIGHT", anchorFrame, "BOTTOMRIGHT", 0, -18)
    panel:SetHeight(220)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

    local border = panel:CreateTexture(nil, "ARTWORK")
    border:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    border:SetHeight(1)
    border:SetColorTexture(1, 0.82, 0, 0.9)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -14)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText(titleText)
    panel.Title = title

    local hint = panel:CreateFontString(nil, "OVERLAY")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    hint:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    hint:SetJustifyH("LEFT")
    hint:SetJustifyV("TOP")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    hint:SetTextColor(0.80, 0.80, 0.80, 1)
    hint:SetText(hintText)
    panel.Hint = hint

    panel.SummaryLines = {}
    panel.Rows = {}

    local emptyText = panel:CreateFontString(nil, "OVERLAY")
    emptyText:SetJustifyH("LEFT")
    emptyText:SetJustifyV("TOP")
    emptyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    emptyText:SetTextColor(0.75, 0.75, 0.75, 1)
    emptyText:SetText(L("NO_ENTRIES"))
    emptyText:Hide()
    panel.EmptyText = emptyText

    return panel
end

local function GetOrCreateSummaryLine(panel, index)
    local line = panel.SummaryLines[index]
    if line then
        return line
    end

    line = panel:CreateFontString(nil, "OVERLAY")
    line:SetJustifyH("LEFT")
    line:SetJustifyV("TOP")
    line:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    line:SetTextColor(0.88, 0.88, 0.88, 1)
    panel.SummaryLines[index] = line
    return line
end

local function GetOrCreateLogRow(panel, index)
    local row = panel.Rows[index]
    if row then
        return row
    end

    row = CreateFrame("Button", nil, panel)
    row:SetHeight(18)
    row:EnableMouse(true)

    local leftText = row:CreateFontString(nil, "OVERLAY")
    leftText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    leftText:SetJustifyH("LEFT")
    leftText:SetJustifyV("TOP")
    leftText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    leftText:SetTextColor(1, 1, 1, 1)
    row.LeftText = leftText

    local rightText = row:CreateFontString(nil, "OVERLAY")
    rightText:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    rightText:SetJustifyH("RIGHT")
    rightText:SetJustifyV("TOP")
    rightText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    rightText:SetTextColor(1, 0.82, 0, 1)
    row.RightText = rightText

    local detailText = row:CreateFontString(nil, "OVERLAY")
    detailText:SetJustifyH("LEFT")
    detailText:SetJustifyV("TOP")
    detailText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    detailText:SetTextColor(0.78, 0.78, 0.78, 1)
    detailText:Hide()
    row.DetailText = detailText

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.04)
    row.Highlight = highlight

    local divider = row:CreateTexture(nil, "BACKGROUND")
    divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    divider:SetHeight(1)
    divider:SetColorTexture(1, 1, 1, 0.04)
    row.Divider = divider

    row:SetScript("OnMouseUp", function(self)
        if self.expandable and type(self.OnRowClick) == "function" then
            self.OnRowClick(self)
        end
    end)

    panel.Rows[index] = row
    return row
end

local function ResetPanelEntries(panel)
    for _, line in ipairs(panel.SummaryLines) do
        line:Hide()
    end

    for _, row in ipairs(panel.Rows) do
        row.expandable = false
        row.OnRowClick = nil
        row:Hide()
    end

    panel.EmptyText:Hide()
end

local function LayoutSummaryLine(panel, index, currentY, text)
    local line = GetOrCreateSummaryLine(panel, index)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
    line:SetPoint("RIGHT", panel, "RIGHT", -18, 0)
    line:SetText(text)
    line:Show()

    return currentY - math.max(14, math.ceil(line:GetStringHeight()) + 2)
end

local function LayoutLogRow(panel, index, currentY, leftText, rightText, options)
    -- Eine Zeile kann optional aufklappbar sein.
    -- Genau das nutzen wir fuer Verkaufseintraege und Reparaturtage.
    local panelWidth = math.max(280, panel:GetWidth())
    local row = GetOrCreateLogRow(panel, index)
    local settings = options or {}
    local isExpandable = settings.expandable == true
    local isExpanded = settings.expanded == true
    local detailsText = settings.detailsText

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, currentY)
    row:SetPoint("RIGHT", panel, "RIGHT", -18, 0)

    row.expandable = isExpandable
    row.OnRowClick = settings.onClick
    row.Highlight:SetShown(isExpandable)

    row.RightText:SetWidth(140)
    row.RightText:SetText(rightText or "")
    row.LeftText:ClearAllPoints()
    row.LeftText:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.LeftText:SetWidth(math.max(120, panelWidth - 196))
    if isExpandable then
        row.LeftText:SetText(string.format("%s %s", isExpanded and "[-]" or "[+]", leftText or ""))
    else
        row.LeftText:SetText(leftText or "")
    end

    if isExpandable and isExpanded and type(detailsText) == "string" and detailsText ~= "" then
        row.DetailText:ClearAllPoints()
        row.DetailText:SetPoint("TOPLEFT", row.LeftText, "BOTTOMLEFT", 16, -4)
        row.DetailText:SetWidth(math.max(120, panelWidth - 212))
        row.DetailText:SetText(detailsText)
        row.DetailText:Show()
    else
        row.DetailText:SetText("")
        row.DetailText:Hide()
    end

    local rowHeight = math.max(18, math.ceil(math.max(row.LeftText:GetStringHeight(), row.RightText:GetStringHeight()) + 4))
    if row.DetailText:IsShown() then
        rowHeight = rowHeight + math.ceil(row.DetailText:GetStringHeight()) + 8
    end

    row:SetHeight(rowHeight)
    row:Show()

    return currentY - rowHeight - 6
end

local function SumAmounts(entries)
    local total = 0

    for _, entry in ipairs(entries) do
        total = total + (entry.amount or 0)
    end

    return total
end

local function BuildSalesEntryKey(entry, index)
    return string.format(
        "%s|%s|%s|%s",
        tostring(index or 0),
        tostring(entry.timestamp or 0),
        tostring(entry.source or ""),
        tostring(entry.amount or 0)
    )
end

local function SalesEntryHasDetails(entry)
    return type(entry.items) == "table" and #entry.items > 0
end

local function BuildSalesEntrySummary(entry)
    local details = entry.source or L("LOGGING_SALE")
    local itemCount = math.max(0, tonumber(entry.itemCount) or 0)

    if itemCount > 0 then
        details = string.format("%s | %d %s", details, itemCount, itemCount == 1 and L("LOGGING_ITEM") or L("LOGGING_ITEMS"))
    end

    return details
end

local function BuildSalesEntryExpandedText(entry)
    if not SalesEntryHasDetails(entry) then
        return nil
    end

    return BuildExpandedItemText(entry.items)
end

local function BuildRepairDayKey(dayEntry)
    return tostring(dayEntry.dayKey or "")
end

local function BuildRepairDaySummary(dayEntry)
    local repairCount = type(dayEntry.entries) == "table" and #dayEntry.entries or 0
    local summary = FormatDayKey(dayEntry.dayKey)

    if repairCount > 0 then
        summary = string.format("%s | %d %s", summary, repairCount, repairCount == 1 and L("LOGGING_REPAIR") or L("LOGGING_REPAIRS"))
    end

    if (dayEntry.personal or 0) < (dayEntry.total or 0) then
        summary = string.format("%s | %s: %s", summary, L("LOGGING_SELF_PAID"), FormatCoins(dayEntry.personal or 0))
    end

    return summary
end

local function BuildRepairDayExpandedText(dayEntry)
    if type(dayEntry.entries) ~= "table" or #dayEntry.entries == 0 then
        return nil
    end

    local lines = {}

    for _, entry in ipairs(dayEntry.entries) do
        lines[#lines + 1] = string.format(
            "- %s | %s | %s",
            FormatClockTime(entry.timestamp),
            entry.source or L("LOGGING_REPAIR"),
            FormatCoins(entry.amount or 0)
        )
    end

    return table.concat(lines, "\n")
end

local function BuildMoneyEntryDetails(entry)
    local details = entry.category or L("LOGGING_ENTRY")

    if type(entry.note) == "string" and entry.note ~= "" and entry.note ~= details then
        details = string.format("%s | %s", details, entry.note)
    end

    local itemSummary = BuildItemListSummary(entry.items)
    if itemSummary then
        details = string.format("%s\n%s: %s", details, L("ITEMS_LABEL"), itemSummary)
    end

    return details
end

local function BuildCategoryTotals(entries)
    local buckets = {}

    for _, entry in ipairs(entries) do
        local category = entry.category or L("LOGGING_MISC")

        buckets[category] = buckets[category] or {
            category = category,
            total = 0,
            count = 0,
            lastTimestamp = 0,
        }

        buckets[category].total = buckets[category].total + (entry.amount or 0)
        buckets[category].count = buckets[category].count + 1
        buckets[category].lastTimestamp = math.max(buckets[category].lastTimestamp, entry.timestamp or 0)
    end

    local ordered = {}
    for _, bucket in pairs(buckets) do
        ordered[#ordered + 1] = bucket
    end

    table.sort(ordered, function(a, b)
        if a.total == b.total then
            return a.category < b.category
        end

        return a.total > b.total
    end)

    return ordered
end

local function BuildDailyRepairTotals()
    local groupedByDay = {}
    local orderedDays = {}

    for dayKey, totals in pairs(Logging.GetRepairDailyTotals()) do
        groupedByDay[dayKey] = {
            dayKey = dayKey,
            total = totals.total or 0,
            personal = totals.personal or 0,
            entries = {},
            hasStoredTotals = true,
        }
        orderedDays[#orderedDays + 1] = dayKey
    end

    for _, entry in ipairs(Logging.GetRepairLog()) do
        local dayKey = GetDayKey(entry.timestamp)
        local dayEntry = groupedByDay[dayKey]

        if not dayEntry then
            dayEntry = {
                dayKey = dayKey,
                total = 0,
                personal = 0,
                entries = {},
                hasStoredTotals = false,
            }
            groupedByDay[dayKey] = dayEntry
            orderedDays[#orderedDays + 1] = dayKey
        end

        dayEntry.entries[#dayEntry.entries + 1] = entry
        if not dayEntry.hasStoredTotals then
            dayEntry.total = dayEntry.total + (entry.amount or 0)

            if (entry.source or L("LOGGING_OWN_GOLD")) ~= L("LOGGING_GUILD") then
                dayEntry.personal = dayEntry.personal + (entry.amount or 0)
            end
        end
    end

    local dayEntries = {}
    local seenDays = {}

    for _, dayKey in ipairs(orderedDays) do
        if not seenDays[dayKey] then
            local dayEntry = groupedByDay[dayKey]
            if dayEntry then
                table.sort(dayEntry.entries, function(a, b)
                    return (a.timestamp or 0) > (b.timestamp or 0)
                end)

                dayEntries[#dayEntries + 1] = dayEntry
                seenDays[dayKey] = true
            end
        end
    end

    table.sort(dayEntries, function(a, b)
        return a.dayKey > b.dayKey
    end)

    return dayEntries
end

PageLogging = CreateFrame("Frame", nil, Content)
PageLogging:SetAllPoints()
PageLogging:Hide()

local PageLoggingScrollFrame = CreateFrame("ScrollFrame", nil, PageLogging, "UIPanelScrollFrameTemplate")
PageLoggingScrollFrame:SetPoint("TOPLEFT", PageLogging, "TOPLEFT", 0, 0)
PageLoggingScrollFrame:SetPoint("BOTTOMRIGHT", PageLogging, "BOTTOMRIGHT", -28, 0)
PageLoggingScrollFrame:EnableMouseWheel(true)

local PageLoggingContent = CreateFrame("Frame", nil, PageLoggingScrollFrame)
PageLoggingContent:SetSize(1, 1)
PageLoggingScrollFrame:SetScrollChild(PageLoggingContent)

local IntroPanel = CreateFrame("Frame", nil, PageLoggingContent)
IntroPanel:SetPoint("TOPLEFT", PageLoggingContent, "TOPLEFT", 20, -20)
IntroPanel:SetPoint("TOPRIGHT", PageLoggingContent, "TOPRIGHT", -20, -20)
IntroPanel:SetHeight(154)

local IntroBg = IntroPanel:CreateTexture(nil, "BACKGROUND")
IntroBg:SetAllPoints()
IntroBg:SetColorTexture(0.07, 0.07, 0.07, 0.92)

local IntroBorder = IntroPanel:CreateTexture(nil, "ARTWORK")
IntroBorder:SetPoint("BOTTOMLEFT", IntroPanel, "BOTTOMLEFT", 0, 0)
IntroBorder:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", 0, 0)
IntroBorder:SetHeight(1)
IntroBorder:SetColorTexture(1, 0.82, 0, 0.9)

local IntroTitle = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroTitle:SetPoint("TOPLEFT", IntroPanel, "TOPLEFT", 18, -16)
IntroTitle:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
IntroTitle:SetTextColor(1, 0.82, 0, 1)
IntroTitle:SetText(L("LOGGING"))

local IntroText = IntroPanel:CreateFontString(nil, "OVERLAY")
IntroText:SetPoint("TOPLEFT", IntroTitle, "BOTTOMLEFT", 0, -10)
IntroText:SetPoint("RIGHT", IntroPanel, "RIGHT", -18, 0)
IntroText:SetJustifyH("LEFT")
IntroText:SetJustifyV("TOP")
IntroText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
IntroText:SetTextColor(1, 1, 1, 1)
IntroText:SetText(L("LOGGING_DESC"))

local CleanupButton = CreateFrame("Button", nil, IntroPanel, "UIPanelButtonTemplate")
CleanupButton:SetSize(150, 24)
CleanupButton:SetPoint("BOTTOMRIGHT", IntroPanel, "BOTTOMRIGHT", -18, 14)
CleanupButton:SetText(L("LOGGING_CLEANUP"))

local RetentionHint = IntroPanel:CreateFontString(nil, "OVERLAY")
RetentionHint:SetPoint("TOPLEFT", IntroText, "BOTTOMLEFT", 0, -12)
RetentionHint:SetPoint("RIGHT", CleanupButton, "LEFT", -12, 0)
RetentionHint:SetJustifyH("LEFT")
RetentionHint:SetJustifyV("TOP")
RetentionHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
RetentionHint:SetTextColor(0.80, 0.80, 0.80, 1)
RetentionHint:SetText(L("LOGGING_RETENTION_HINT"))

local function CreateCleanupChoiceButton(parent, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(126, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

CleanupPopup = CreateFrame("Frame", nil, PageLogging, BackdropTemplateMixin and "BackdropTemplate")
CleanupPopup:SetSize(312, 184)
CleanupPopup:SetPoint("CENTER", PageLogging, "CENTER", 0, 20)
CleanupPopup:SetFrameStrata("DIALOG")
CleanupPopup:EnableMouse(true)
CleanupPopup:SetClampedToScreen(true)
CleanupPopup:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
CleanupPopup:SetBackdropColor(0.05, 0.05, 0.05, 0.96)
CleanupPopup:SetBackdropBorderColor(1, 0.82, 0, 0.95)
CleanupPopup:Hide()

local CleanupPopupTitle = CleanupPopup:CreateFontString(nil, "OVERLAY")
CleanupPopupTitle:SetPoint("TOPLEFT", CleanupPopup, "TOPLEFT", 16, -14)
CleanupPopupTitle:SetPoint("RIGHT", CleanupPopup, "RIGHT", -16, 0)
CleanupPopupTitle:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
CleanupPopupTitle:SetTextColor(1, 0.82, 0, 1)
CleanupPopupTitle:SetText(L("LOGGING_CLEANUP_TITLE"))

local CleanupPopupHint = CleanupPopup:CreateFontString(nil, "OVERLAY")
CleanupPopupHint:SetPoint("TOPLEFT", CleanupPopupTitle, "BOTTOMLEFT", 0, -10)
CleanupPopupHint:SetPoint("RIGHT", CleanupPopup, "RIGHT", -16, 0)
CleanupPopupHint:SetJustifyH("LEFT")
CleanupPopupHint:SetJustifyV("TOP")
CleanupPopupHint:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
CleanupPopupHint:SetTextColor(0.85, 0.85, 0.85, 1)
CleanupPopupHint:SetText(L("LOGGING_CLEANUP_HINT"))

local function CloseCleanupPopup()
    if CleanupPopup then
        CleanupPopup:Hide()
    end
end

local function ApplyCleanupRange(days)
    Logging.ClearLogsOlderThanDays(days)
    CloseCleanupPopup()
end

local CleanupSevenDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_7"), function()
    ApplyCleanupRange(7)
end)
CleanupSevenDaysButton:SetPoint("TOPLEFT", CleanupPopupHint, "BOTTOMLEFT", 0, -16)

local CleanupThirtyDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_30"), function()
    ApplyCleanupRange(30)
end)
CleanupThirtyDaysButton:SetPoint("LEFT", CleanupSevenDaysButton, "RIGHT", 10, 0)

local CleanupNinetyDaysButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_90"), function()
    ApplyCleanupRange(90)
end)
CleanupNinetyDaysButton:SetPoint("TOPLEFT", CleanupSevenDaysButton, "BOTTOMLEFT", 0, -10)

local CleanupOneYearButton = CreateCleanupChoiceButton(CleanupPopup, L("DAYS_365"), function()
    ApplyCleanupRange(365)
end)
CleanupOneYearButton:SetPoint("LEFT", CleanupNinetyDaysButton, "RIGHT", 10, 0)

local CleanupAllButton = CreateCleanupChoiceButton(CleanupPopup, L("ALL"), function()
    ApplyCleanupRange("all")
end)
CleanupAllButton:SetPoint("TOPLEFT", CleanupNinetyDaysButton, "BOTTOMLEFT", 0, -10)

local CleanupCancelButton = CreateCleanupChoiceButton(CleanupPopup, L("CANCEL"), CloseCleanupPopup)
CleanupCancelButton:SetPoint("LEFT", CleanupAllButton, "RIGHT", 10, 0)

CleanupButton:SetScript("OnClick", function()
    if CleanupPopup:IsShown() then
        CleanupPopup:Hide()
    else
        CleanupPopup:Show()
    end
end)

SalesPanel = CreateLogPanel(
    PageLoggingContent,
    IntroPanel,
    L("LOGGING_SALES_TITLE"),
    L("LOGGING_SALES_HINT")
)

RepairPanel = CreateLogPanel(
    PageLoggingContent,
    SalesPanel,
    L("LOGGING_REPAIRS_TITLE"),
    L("LOGGING_REPAIRS_HINT")
)

IncomePanel = CreateLogPanel(
    PageLoggingContent,
    RepairPanel,
    L("LOGGING_INCOME_TITLE"),
    L("LOGGING_INCOME_HINT")
)

ExpensePanel = CreateLogPanel(
    PageLoggingContent,
    IncomePanel,
    L("LOGGING_EXPENSE_TITLE"),
    L("LOGGING_EXPENSE_HINT")
)

function PageLogging:RefreshState()
    -- Baut die komplette Logging-Seite aus den gespeicherten Daten neu auf.
    local salesLog = Logging.GetSalesLog()
    local repairLog = Logging.GetRepairLog()
    local incomeLog = Logging.GetIncomeLog()
    local expenseLog = Logging.GetExpenseLog()
    local repairDays = BuildDailyRepairTotals()
    local incomeCategories = BuildCategoryTotals(incomeLog)
    local expenseCategories = BuildCategoryTotals(expenseLog)

    IntroTitle:SetText(L("LOGGING"))
    IntroText:SetText(L("LOGGING_DESC"))
    CleanupButton:SetText(L("LOGGING_CLEANUP"))
    RetentionHint:SetText(L("LOGGING_RETENTION_HINT"))
    CleanupPopupTitle:SetText(L("LOGGING_CLEANUP_TITLE"))
    CleanupPopupHint:SetText(L("LOGGING_CLEANUP_HINT"))
    CleanupSevenDaysButton:SetText(L("DAYS_7"))
    CleanupThirtyDaysButton:SetText(L("DAYS_30"))
    CleanupNinetyDaysButton:SetText(L("DAYS_90"))
    CleanupOneYearButton:SetText(L("DAYS_365"))
    CleanupAllButton:SetText(L("ALL"))
    CleanupCancelButton:SetText(L("CANCEL"))
    SalesPanel.Title:SetText(L("LOGGING_SALES_TITLE"))
    SalesPanel.Hint:SetText(L("LOGGING_SALES_HINT"))
    SalesPanel.EmptyText:SetText(L("NO_ENTRIES"))
    RepairPanel.Title:SetText(L("LOGGING_REPAIRS_TITLE"))
    RepairPanel.Hint:SetText(L("LOGGING_REPAIRS_HINT"))
    RepairPanel.EmptyText:SetText(L("NO_ENTRIES"))
    IncomePanel.Title:SetText(L("LOGGING_INCOME_TITLE"))
    IncomePanel.Hint:SetText(L("LOGGING_INCOME_HINT"))
    IncomePanel.EmptyText:SetText(L("NO_ENTRIES"))
    ExpensePanel.Title:SetText(L("LOGGING_EXPENSE_TITLE"))
    ExpensePanel.Hint:SetText(L("LOGGING_EXPENSE_HINT"))
    ExpensePanel.EmptyText:SetText(L("NO_ENTRIES"))

    ResetPanelEntries(SalesPanel)
    ResetPanelEntries(RepairPanel)
    ResetPanelEntries(IncomePanel)
    ResetPanelEntries(ExpensePanel)

    do
        local currentY = -72
        local rowIndex = 0

        currentY = LayoutSummaryLine(SalesPanel, 1, currentY, L("LOGGING_STORED_SALES"):format(#salesLog))
        currentY = LayoutSummaryLine(SalesPanel, 2, currentY, L("LOGGING_TOTAL_SALES_GOLD"):format(FormatCoins(SumAmounts(salesLog))))
        currentY = currentY - 10

        for index = #salesLog, math.max(1, #salesLog - 7), -1 do
            local entry = salesLog[index]
            local rowKey = BuildSalesEntryKey(entry, index)
            local detailsText = BuildSalesEntryExpandedText(entry)
            local isExpandable = type(detailsText) == "string" and detailsText ~= ""
            local isExpanded = isExpandable and expandedSalesEntries[rowKey] == true
            rowIndex = rowIndex + 1

            currentY = LayoutLogRow(
                SalesPanel,
                rowIndex,
                currentY,
                string.format("%s | %s", FormatTimestamp(entry.timestamp), BuildSalesEntrySummary(entry)),
                FormatCoins(entry.amount),
                {
                    expandable = isExpandable,
                    expanded = isExpanded,
                    detailsText = detailsText,
                    onClick = function()
                        expandedSalesEntries[rowKey] = not expandedSalesEntries[rowKey]
                        PageLogging:RefreshState()
                    end,
                }
            )
        end

        if rowIndex == 0 then
            SalesPanel.EmptyText:ClearAllPoints()
            SalesPanel.EmptyText:SetPoint("TOPLEFT", SalesPanel, "TOPLEFT", 18, -104)
            SalesPanel.EmptyText:SetPoint("RIGHT", SalesPanel, "RIGHT", -18, 0)
            SalesPanel.EmptyText:Show()
            currentY = currentY - 26
        end

        SalesPanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = -72
        local rowIndex = 0

        currentY = LayoutSummaryLine(RepairPanel, 1, currentY, L("LOGGING_STORED_REPAIRS"):format(#repairLog))
        currentY = LayoutSummaryLine(RepairPanel, 2, currentY, L("LOGGING_DAILY_EXPAND_HINT"))
        currentY = currentY - 10

        if #repairDays == 0 then
            currentY = LayoutSummaryLine(RepairPanel, 3, currentY, L("LOGGING_NO_REPAIRS"))
        else
            for index = 1, math.min(8, #repairDays) do
                local dayEntry = repairDays[index]
                local rowKey = BuildRepairDayKey(dayEntry)
                local detailsText = BuildRepairDayExpandedText(dayEntry)
                local isExpandable = type(detailsText) == "string" and detailsText ~= ""
                local isExpanded = isExpandable and expandedRepairDays[rowKey] == true

                rowIndex = rowIndex + 1
                currentY = LayoutLogRow(
                    RepairPanel,
                    rowIndex,
                    currentY,
                    BuildRepairDaySummary(dayEntry),
                    FormatCoins(dayEntry.total),
                    {
                        expandable = isExpandable,
                        expanded = isExpanded,
                        detailsText = detailsText,
                        onClick = function()
                            expandedRepairDays[rowKey] = not expandedRepairDays[rowKey]
                            PageLogging:RefreshState()
                        end,
                    }
                )
            end
        end

        if rowIndex == 0 and #repairDays > 0 then
            RepairPanel.EmptyText:ClearAllPoints()
            RepairPanel.EmptyText:SetPoint("TOPLEFT", RepairPanel, "TOPLEFT", 18, -144)
            RepairPanel.EmptyText:SetPoint("RIGHT", RepairPanel, "RIGHT", -18, 0)
            RepairPanel.EmptyText:Show()
            currentY = currentY - 26
        end

        RepairPanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = -72
        local rowIndex = 0
        local summaryIndex = 0

        summaryIndex = summaryIndex + 1
        currentY = LayoutSummaryLine(IncomePanel, summaryIndex, currentY, L("LOGGING_STORED_INCOME"):format(#incomeLog))
        summaryIndex = summaryIndex + 1
        currentY = LayoutSummaryLine(IncomePanel, summaryIndex, currentY, L("LOGGING_TOTAL_INCOME"):format(FormatCoins(SumAmounts(incomeLog))))
        currentY = currentY - 10

        for index = 1, math.min(10, #incomeCategories) do
            local entry = incomeCategories[index]
            rowIndex = rowIndex + 1

            currentY = LayoutLogRow(
                IncomePanel,
                rowIndex,
                currentY,
                string.format("%s (%d)", entry.category, entry.count),
                FormatCoins(entry.total)
            )
        end

        if #incomeLog > 0 then
            currentY = currentY - 8
            summaryIndex = summaryIndex + 1
            currentY = LayoutSummaryLine(IncomePanel, summaryIndex, currentY, L("LOGGING_LATEST_ENTRIES"))

            for index = #incomeLog, math.max(1, #incomeLog - 5), -1 do
                local entry = incomeLog[index]
                rowIndex = rowIndex + 1

                currentY = LayoutLogRow(
                    IncomePanel,
                    rowIndex,
                    currentY,
                    string.format("%s | %s", FormatTimestamp(entry.timestamp), BuildMoneyEntryDetails(entry)),
                    FormatCoins(entry.amount)
                )
            end
        end

        if rowIndex == 0 then
            IncomePanel.EmptyText:ClearAllPoints()
            IncomePanel.EmptyText:SetPoint("TOPLEFT", IncomePanel, "TOPLEFT", 18, -104)
            IncomePanel.EmptyText:SetPoint("RIGHT", IncomePanel, "RIGHT", -18, 0)
            IncomePanel.EmptyText:Show()
            currentY = currentY - 26
        end

        IncomePanel:SetHeight((-currentY) + 18)
    end

    do
        local currentY = -72
        local rowIndex = 0
        local summaryIndex = 0

        summaryIndex = summaryIndex + 1
        currentY = LayoutSummaryLine(ExpensePanel, summaryIndex, currentY, L("LOGGING_STORED_EXPENSES"):format(#expenseLog))
        summaryIndex = summaryIndex + 1
        currentY = LayoutSummaryLine(ExpensePanel, summaryIndex, currentY, L("LOGGING_TOTAL_EXPENSES"):format(FormatCoins(SumAmounts(expenseLog))))
        currentY = currentY - 10

        for index = 1, math.min(10, #expenseCategories) do
            local entry = expenseCategories[index]
            rowIndex = rowIndex + 1

            currentY = LayoutLogRow(
                ExpensePanel,
                rowIndex,
                currentY,
                string.format("%s (%d)", entry.category, entry.count),
                FormatCoins(entry.total)
            )
        end

        if #expenseLog > 0 then
            currentY = currentY - 8
            summaryIndex = summaryIndex + 1
            currentY = LayoutSummaryLine(ExpensePanel, summaryIndex, currentY, L("LOGGING_LATEST_ENTRIES"))

            for index = #expenseLog, math.max(1, #expenseLog - 5), -1 do
                local entry = expenseLog[index]
                rowIndex = rowIndex + 1

                currentY = LayoutLogRow(
                    ExpensePanel,
                    rowIndex,
                    currentY,
                    string.format("%s | %s", FormatTimestamp(entry.timestamp), BuildMoneyEntryDetails(entry)),
                    FormatCoins(entry.amount)
                )
            end
        end

        if rowIndex == 0 then
            ExpensePanel.EmptyText:ClearAllPoints()
            ExpensePanel.EmptyText:SetPoint("TOPLEFT", ExpensePanel, "TOPLEFT", 18, -104)
            ExpensePanel.EmptyText:SetPoint("RIGHT", ExpensePanel, "RIGHT", -18, 0)
            ExpensePanel.EmptyText:Show()
            currentY = currentY - 26
        end

        ExpensePanel:SetHeight((-currentY) + 18)
    end

    self:UpdateScrollLayout()
end

function PageLogging:UpdateScrollLayout()
    -- Die Scrollhoehe richtet sich nach den echten Hoehen der vier Panels.
    local contentWidth = math.max(1, PageLoggingScrollFrame:GetWidth())
    local contentHeight = 20
        + IntroPanel:GetHeight()
        + 18 + SalesPanel:GetHeight()
        + 18 + RepairPanel:GetHeight()
        + 18 + IncomePanel:GetHeight()
        + 18 + ExpensePanel:GetHeight()
        + 20

    PageLoggingContent:SetWidth(contentWidth)
    PageLoggingContent:SetHeight(contentHeight)

    local maxScroll = math.max(0, PageLoggingContent:GetHeight() - PageLoggingScrollFrame:GetHeight())
    if PageLoggingScrollFrame:GetVerticalScroll() > maxScroll then
        PageLoggingScrollFrame:SetVerticalScroll(maxScroll)
    end
end

PageLoggingScrollFrame:SetScript("OnSizeChanged", function()
    PageLogging:RefreshState()
end)

PageLoggingScrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local step = 40
    local currentScroll = self:GetVerticalScroll()
    local maxScroll = math.max(0, PageLoggingContent:GetHeight() - self:GetHeight())
    local nextScroll = currentScroll - (delta * step)

    if nextScroll < 0 then
        nextScroll = 0
    elseif nextScroll > maxScroll then
        nextScroll = maxScroll
    end

    self:SetVerticalScroll(nextScroll)
end)

PageLogging:SetScript("OnShow", function()
    PageLogging:RefreshState()
    PageLoggingScrollFrame:SetVerticalScroll(0)
end)

PageLogging:HookScript("OnHide", function()
    CloseCleanupPopup()
end)

PageLogging:RefreshState()

BeavisQoL.Pages.Logging = PageLogging
