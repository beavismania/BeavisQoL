local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

-- Hier merken wir uns die Blizzard-Originale, damit sich der Eingriff jederzeit sauber rückgängig machen lässt.
local OriginalDeleteDialogs = {}
-- Statt einzelne Popup-Frames zu hooken, arbeiten wir hier eine Ebene tiefer:
-- Blizzard liest sein Verhalten aus StaticPopupDialogs. Wenn wir diese
-- Definitionen austauschen, gilt die Aenderung automatisch überall dort,
-- wo später dieselben Delete-Popups erzeugt werden.

local function CaptureOriginalDeleteDialogs()
    if not StaticPopupDialogs then
        return
    end

    if not OriginalDeleteDialogs.DELETE_GOOD_ITEM and StaticPopupDialogs["DELETE_GOOD_ITEM"] then
        OriginalDeleteDialogs.DELETE_GOOD_ITEM = StaticPopupDialogs["DELETE_GOOD_ITEM"]
    end

    if not OriginalDeleteDialogs.DELETE_GOOD_QUEST_ITEM and StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] then
        OriginalDeleteDialogs.DELETE_GOOD_QUEST_ITEM = StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"]
    end
end

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

function Misc.IsEasyDeleteEnabled()
    return Misc.GetMiscDB().easyDelete == true
end

-- Statt das Popup neu zu bauen, tauschen wir einfach die "strenge" Variante gegen die normale Delete-Bestätigung.
function Misc.ApplyEasyDelete()
    if not StaticPopupDialogs then
        return
    end

    CaptureOriginalDeleteDialogs()

    if Misc.IsEasyDeleteEnabled() then
        -- Wir ersetzen nur die "guten" Delete-Dialoge durch ihre weniger strenge
        -- Standard-Variante. Das Verhalten bleibt also Blizzard-nah, nur die
        -- Texteingabe wird umgangen.
        if StaticPopupDialogs["DELETE_ITEM"] then
            StaticPopupDialogs["DELETE_GOOD_ITEM"] = StaticPopupDialogs["DELETE_ITEM"]
        end

        if StaticPopupDialogs["DELETE_QUEST_ITEM"] then
            StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] = StaticPopupDialogs["DELETE_QUEST_ITEM"]
        end

        return
    end

    if OriginalDeleteDialogs.DELETE_GOOD_ITEM then
        StaticPopupDialogs["DELETE_GOOD_ITEM"] = OriginalDeleteDialogs.DELETE_GOOD_ITEM
    end

    if OriginalDeleteDialogs.DELETE_GOOD_QUEST_ITEM then
        StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] = OriginalDeleteDialogs.DELETE_GOOD_QUEST_ITEM
    end
end

function Misc.SetEasyDeleteEnabled(value)
    Misc.GetMiscDB().easyDelete = value and true or false
    Misc.ApplyEasyDelete()
end

-- Beim Login einmal nachziehen, falls das Setting schon gespeichert war.
local EasyDeleteWatcher = CreateFrame("Frame")
EasyDeleteWatcher:RegisterEvent("PLAYER_LOGIN")

EasyDeleteWatcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Misc.ApplyEasyDelete()
    end
end)
