local ADDON_NAME, BeavisQoL = ...

BeavisQoL.PetStuff = BeavisQoL.PetStuff or {}
local PetStuff = BeavisQoL.PetStuff

-- Diese Datei enthält die komplette Begleiter-Logik für Auto Respawn Pet.
-- Die sichtbare Checkbox dafür sitzt getrennt auf der Pet-Stuff-Seite.

-- Dieses Modul merkt sich den zuletzt aktiven Begleiter und versucht später,
-- ihn nach Login, Ladebildschirm oder Mount-Dismiss wieder zu beschwören.
-- Die Variablen unten leben bewusst nur während der aktuellen Session.
local lastKnownActivePetGUID = nil
local respawnQueued = false
local respawnWanted = false
local lastSummonAttemptAt = 0

-- Zentraler Zugriff auf den Pet-Teil der SavedVariables.
-- Hier werden auch Default-Werte nachgezogen, damit der Rest des Moduls
-- mit einer stabilen Struktur arbeiten kann.
function PetStuff.GetPetStuffDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.petStuff = BeavisQoLDB.petStuff or {}

    if BeavisQoLDB.petStuff.autoRespawnPet == nil then
        BeavisQoLDB.petStuff.autoRespawnPet = false
    end

    return BeavisQoLDB.petStuff
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

-- Wir bevorzugen die frischere Laufzeit-Kopie und fallen nur auf die DB zurück,
-- wenn in dieser Session noch kein aktives Pet gesehen wurde.
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

-- Manche Events feuern minimal zu früh, während Blizzard den Pet-Zustand
-- intern noch nachzieht. Ein kurzer Timer macht das Verhalten robuster.
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
        -- Wenn bereits ein Begleiter aktiv ist, merken wir ihn uns nur als
        -- neues Ziel und müssen keinen weiteren Beschwörungsversuch starten.
        SaveLastPetGUID(currentPetGUID)
        respawnWanted = false
        return
    end

    local petGUID = GetDesiredPetGUID()
    if not HasSavedPet(petGUID) then
        -- Ungültige GUIDs werden bewusst aus RAM und DB entfernt, damit wir
        -- nicht bei jedem späteren Event wieder ins Leere beschwören.
        lastKnownActivePetGUID = nil
        PetStuff.GetPetStuffDB().lastPetGUID = nil
        respawnWanted = false
        return
    end

    -- Ab hier wissen wir:
    -- Es gibt kein aktives Pet, aber ein gültiges Wunsch-Pet für den
    -- nächsten erlaubten Beschwörungsversuch.
    respawnWanted = true

    if not CanSummonPetNow() then
        return
    end

    local now = GetTime and GetTime() or 0
    if now > 0 and (now - lastSummonAttemptAt) < 1.5 then
        -- Schutz gegen Event-Bursts und doppelte Summon-Aufrufe kurz hintereinander.
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
        -- Beim Aktivieren übernehmen wir sofort den letzten bekannten Kandidaten
        -- und stossen einen schnellen ersten Sync an.
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
        -- Session-Zustand und gespeicherter Zustand werden hier einmal sauber
        -- abgeglichen, bevor weitere Events dazwischenfunken.
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
        -- Auf dem Mount darf kein Begleiter draussen sein. Darum merken wir uns
        -- währenddessen nur den Wunsch und versuchen es erst danach erneut.
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
