local ADDON_NAME, BeavisAddon = ...

BeavisAddon.PetStuff = BeavisAddon.PetStuff or {}
local PetStuff = BeavisAddon.PetStuff

local lastKnownActivePetGUID = nil
local respawnQueued = false
local respawnWanted = false
local lastSummonAttemptAt = 0

function PetStuff.GetPetStuffDB()
    BeavisAddonDB = BeavisAddonDB or {}
    BeavisAddonDB.petStuff = BeavisAddonDB.petStuff or {}

    if BeavisAddonDB.petStuff.autoRespawnPet == nil then
        BeavisAddonDB.petStuff.autoRespawnPet = false
    end

    return BeavisAddonDB.petStuff
end

function PetStuff.IsAutoRespawnPetEnabled()
    return PetStuff.GetPetStuffDB().autoRespawnPet == true
end

-- Die Blizzard-API liefert die GUID des aktuell beschworenen Begleiters, wenn einer aktiv ist.
local function GetSummonedPetGUID()
    if C_PetJournal and C_PetJournal.GetSummonedPetGUID then
        return C_PetJournal.GetSummonedPetGUID()
    end
end

local function GetSavedPetGUID()
    local petGUID = PetStuff.GetPetStuffDB().lastPetGUID
    if type(petGUID) == "string" and petGUID ~= "" then
        return petGUID
    end
end

-- Das zuletzt bekannte Pet wird direkt in der DB gehalten.
-- So überlebt es auch Reloads und komplette Neustarts.
local function SaveLastPetGUID(petGUID)
    if type(petGUID) == "string" and petGUID ~= "" then
        lastKnownActivePetGUID = petGUID
        PetStuff.GetPetStuffDB().lastPetGUID = petGUID
    end
end

-- Falls das gespeicherte Pet irgendwann nicht mehr existiert, wollen wir nicht endlos darauf casten.
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

-- SummonPetByGUID ist in einigen Situationen gesperrt.
-- Die Guards sparen hier nur sinnlose Fehlversuche.
local function CanSummonPetNow()
    if not PetStuff.IsAutoRespawnPetEnabled() then
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
        PetStuff.EnsureLastPetActive()
    end)
end

-- Hier steckt die eigentliche "halte das letzte Pet draussen"-Logik drin.
function PetStuff.EnsureLastPetActive()
    local currentPetGUID = GetSummonedPetGUID()
    if currentPetGUID and currentPetGUID ~= "" then
        SaveLastPetGUID(currentPetGUID)
        respawnWanted = false
        return
    end

    local petGUID = GetDesiredPetGUID()
    if not HasSavedPet(petGUID) then
        lastKnownActivePetGUID = nil
        PetStuff.GetPetStuffDB().lastPetGUID = nil
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

function PetStuff.TryRespawnLastPet()
    PetStuff.EnsureLastPetActive()
end

function PetStuff.SetAutoRespawnPetEnabled(value)
    PetStuff.GetPetStuffDB().autoRespawnPet = value and true or false

    if value then
        lastKnownActivePetGUID = lastKnownActivePetGUID or GetSavedPetGUID()
        respawnWanted = GetDesiredPetGUID() ~= nil
        QueueEnsurePet(0.1)
    else
        respawnWanted = false
    end
end

-- Die Event-Kombi ist bewusst breiter als nur Mount/Dismount:
-- Wir merken uns das letzte Pet dauerhaft und holen es nach Reloads, Zonenwechseln
-- oder anderen Dismiss-Situationen wieder zurück, sobald Blizzard es erlaubt.
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
        -- Uns interessieren hier nur Begleiter, nicht Mount-Updates.
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

    -- Alles, was uns die Kontrolle über den Charakter zurückgibt,
    -- ist ein guter Moment für einen erneuten Versuch.
    if event == "PLAYER_REGEN_ENABLED"
        or event == "PLAYER_CONTROL_GAINED"
        or event == "PLAYER_ALIVE"
        or event == "PLAYER_UNGHOST" then
        if respawnWanted or not GetSummonedPetGUID() then
            QueueEnsurePet(0)
        end
    end
end)
