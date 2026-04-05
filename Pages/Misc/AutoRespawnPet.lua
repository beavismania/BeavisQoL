local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc

local lastKnownActivePetGUID = nil
local respawnQueued = false
local respawnWanted = false
local lastSummonAttemptAt = 0

local function GetAutoRespawnPetDB()
    local db
    local legacyDB

    BeavisQoLDB = BeavisQoLDB or {}
    legacyDB = type(BeavisQoLDB.petStuff) == "table" and BeavisQoLDB.petStuff or nil

    if Misc.GetMiscDB then
        db = Misc.GetMiscDB()
    else
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.autoRespawnPet == nil then
        if legacyDB and legacyDB.autoRespawnPet ~= nil then
            db.autoRespawnPet = legacyDB.autoRespawnPet == true
        else
            db.autoRespawnPet = false
        end
    end

    if db.lastPetGUID == nil and legacyDB and type(legacyDB.lastPetGUID) == "string" and legacyDB.lastPetGUID ~= "" then
        db.lastPetGUID = legacyDB.lastPetGUID
    end

    return db
end

function Misc.IsAutoRespawnPetEnabled()
    return GetAutoRespawnPetDB().autoRespawnPet == true
end

local function GetSummonedPetGUID()
    if C_PetJournal and C_PetJournal.GetSummonedPetGUID then
        return C_PetJournal.GetSummonedPetGUID()
    end
end

local function GetSavedPetGUID()
    local petGUID = GetAutoRespawnPetDB().lastPetGUID
    if type(petGUID) == "string" and petGUID ~= "" then
        return petGUID
    end
end

local function SaveLastPetGUID(petGUID)
    if type(petGUID) == "string" and petGUID ~= "" then
        lastKnownActivePetGUID = petGUID
        GetAutoRespawnPetDB().lastPetGUID = petGUID
    end
end

local function HasSavedPet(petGUID)
    if not petGUID or petGUID == "" then
        return false
    end

    if C_PetJournal and C_PetJournal.GetPetInfoByPetID then
        local speciesID = C_PetJournal.GetPetInfoByPetID(petGUID)
        return speciesID ~= nil
    end

    return true
end

local function GetDesiredPetGUID()
    return lastKnownActivePetGUID or GetSavedPetGUID()
end

local function CanSummonPetNow()
    if not Misc.IsAutoRespawnPetEnabled() then
        return false
    end

    if IsMounted and IsMounted() then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        return false
    end

    if UnitOnTaxi and UnitOnTaxi("player") then
        return false
    end

    if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then
        return false
    end

    return C_PetJournal and C_PetJournal.SummonPetByGUID
end

local function QueueEnsurePet(delay)
    if respawnQueued then
        return
    end

    respawnQueued = true

    C_Timer.After(delay or 0.25, function()
        respawnQueued = false
        Misc.EnsureLastPetActive()
    end)
end

function Misc.EnsureLastPetActive()
    local currentPetGUID = GetSummonedPetGUID()
    if currentPetGUID and currentPetGUID ~= "" then
        SaveLastPetGUID(currentPetGUID)
        respawnWanted = false
        return
    end

    local petGUID = GetDesiredPetGUID()
    if not HasSavedPet(petGUID) then
        lastKnownActivePetGUID = nil
        GetAutoRespawnPetDB().lastPetGUID = nil
        respawnWanted = false
        return
    end

    respawnWanted = true

    if not CanSummonPetNow() then
        return
    end

    local now = GetTime and GetTime() or 0
    if now > 0 and (now - lastSummonAttemptAt) < 1.5 then
        return
    end

    lastSummonAttemptAt = now
    C_PetJournal.SummonPetByGUID(petGUID)
end

function Misc.TryRespawnLastPet()
    Misc.EnsureLastPetActive()
end

function Misc.SetAutoRespawnPetEnabled(value)
    GetAutoRespawnPetDB().autoRespawnPet = value and true or false

    if value then
        lastKnownActivePetGUID = lastKnownActivePetGUID or GetSavedPetGUID()
        respawnWanted = GetDesiredPetGUID() ~= nil
        QueueEnsurePet(0.1)
    else
        respawnWanted = false
    end
end

local PetWatcher = CreateFrame("Frame")
PetWatcher:RegisterEvent("PLAYER_LOGIN")
PetWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
PetWatcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
PetWatcher:RegisterEvent("COMPANION_UPDATE")
PetWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
PetWatcher:RegisterEvent("PLAYER_CONTROL_GAINED")
PetWatcher:RegisterEvent("PLAYER_ALIVE")
PetWatcher:RegisterEvent("PLAYER_UNGHOST")

PetWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        local petGUID = GetSummonedPetGUID()

        if petGUID and petGUID ~= "" then
            SaveLastPetGUID(petGUID)
            respawnWanted = false
        else
            lastKnownActivePetGUID = GetSavedPetGUID()
            respawnWanted = GetDesiredPetGUID() ~= nil
            QueueEnsurePet(event == "PLAYER_ENTERING_WORLD" and 1.0 or 0.25)
        end

        return
    end

    if event == "COMPANION_UPDATE" then
        local companionType = ...
        if companionType and companionType ~= "CRITTER" then
            return
        end

        local petGUID = GetSummonedPetGUID()

        if petGUID and petGUID ~= "" then
            SaveLastPetGUID(petGUID)
            respawnWanted = false
        else
            lastKnownActivePetGUID = lastKnownActivePetGUID or GetSavedPetGUID()
            respawnWanted = GetDesiredPetGUID() ~= nil
            if not (IsMounted and IsMounted()) then
                QueueEnsurePet(0.35)
            end
        end

        return
    end

    if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        if IsMounted and IsMounted() then
            respawnWanted = GetDesiredPetGUID() ~= nil
        else
            QueueEnsurePet(0.35)
        end

        return
    end

    if event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_CONTROL_GAINED"
        or event == "PLAYER_ALIVE"
        or event == "PLAYER_UNGHOST" then
        if respawnWanted or not GetSummonedPetGUID() then
            QueueEnsurePet(0)
        end
    end
end)