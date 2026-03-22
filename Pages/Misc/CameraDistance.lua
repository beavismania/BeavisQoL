local ADDON_NAME, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L

-- Kameraweite ist kein klassisches Toggle-Feature, sondern ein kleines
-- CVar-Steuermodul mit zwei Zielmodi: Standard oder Max Distance.

-- Dieses Modul kümmert sich nur um eine Sache:
-- den Kamera-CVar sauber über die Misc-Seite setzen, den gewünschten Zustand
-- speichern und ihn nach Login / Reload wieder anwenden.

-- Je nach Client liegen dieselben CVar-Helfer entweder unter C_CVar oder noch
-- als globale Funktionen. Mit dem kleinen Fallback bleibt das Modul robuster.
local GetCVarValue = (C_CVar and C_CVar.GetCVar) or rawget(_G, "GetCVar")
local SetCVarValue = (C_CVar and C_CVar.SetCVar) or rawget(_G, "SetCVar")

local CAMERA_DISTANCE_CVAR = "cameraDistanceMaxZoomFactor"
local CAMERA_DISTANCE_CVAR_LOWER = string.lower(CAMERA_DISTANCE_CVAR)
-- 1.9 entspricht dem üblichen Standardwert, 2.6 dem bekannten "weiter rauszoomen"-Wert.
local CAMERA_DISTANCE_STANDARD = 1.9
local CAMERA_DISTANCE_MAX = 2.6
-- CVars kommen teils als String zurück und können kleine Rundungsabweichungen haben.
-- Deshalb vergleichen wir nicht stumpf mit ==.
local CAMERA_DISTANCE_TOLERANCE = 0.001

-- Wenn wir selbst gerade einen neuen Wert setzen, merken wir ihn uns kurz.
-- So können wir das nächste CVAR_UPDATE als "kommt von uns" erkennen und
-- vermeiden unnötiges Hin-und-her.
local pendingCameraDistanceValue = nil

-- Kleine Hilfsfunktion für numerische Vergleiche mit Toleranz.
local function IsSameCameraDistance(leftValue, rightValue)
    if not leftValue or not rightValue then
        return false
    end

    return math.abs(leftValue - rightValue) <= CAMERA_DISTANCE_TOLERANCE
end

-- Liest den aktuell aktiven CVar-Wert aus dem Client und wandelt ihn direkt in
-- eine Zahl um, damit der Rest des Moduls nicht mit Strings arbeiten muss.
local function GetCurrentCameraDistanceValue()
    if not GetCVarValue then
        return nil
    end

    return tonumber(GetCVarValue(CAMERA_DISTANCE_CVAR))
end

-- Für die Anzeige in der UI reicht eine Nachkommastelle völlig aus.
local function FormatCameraDistanceValue(value)
    if not value then
        return L("CAMERA_DISTANCE_QUESTION")
    end

    return string.format("%.1f", value)
end

-- Übersetzt den gespeicherten Modus in den tatsächlichen Zahlenwert,
-- den Blizzard im CVar erwartet.
local function GetCameraDistanceValueForMode(mode)
    if mode == "max" then
        return CAMERA_DISTANCE_MAX
    end

    if mode == "standard" then
        return CAMERA_DISTANCE_STANDARD
    end

    return nil
end

-- Nur bekannte Modi dürfen aus der DB zurückkommen.
-- Alles andere behandeln wir so, als gäbe es keinen gespeicherten Wunschzustand.
local function GetSavedCameraDistanceMode()
    local mode = Misc.GetMiscDB().cameraDistanceMode

    if mode == "max" or mode == "standard" then
        return mode
    end

    return nil
end

-- Die UI-Seite soll sich nach Änderungen sofort aktualisieren, aber nur dann,
-- wenn die Misc-Seite überhaupt existiert und gerade sichtbar ist.
local function RefreshMiscPageState()
    local miscPage = BeavisQoL.Pages and BeavisQoL.Pages.Misc

    if miscPage and miscPage:IsShown() and miscPage.RefreshState then
        miscPage:RefreshState()
    end
end

-- Zentrale Anwenderfunktion:
-- liest den gespeicherten Wunschmodus, prüft den Ist-Zustand und setzt den
-- CVar nur dann neu, wenn wirklich etwas geändert werden muss.
local function ApplySavedCameraDistanceMode()
    local mode = GetSavedCameraDistanceMode()
    local targetValue = GetCameraDistanceValueForMode(mode)

    -- Ohne gültigen Zielwert oder ohne CVar-API gibt es hier nichts zu tun.
    if not targetValue or not SetCVarValue then
        RefreshMiscPageState()
        return
    end

    local currentValue = GetCurrentCameraDistanceValue()
    -- Wenn der Client schon auf dem gewünschten Wert steht, sparen wir uns
    -- ein erneutes Setzen und räumen nur unseren Pending-Status auf.
    if IsSameCameraDistance(currentValue, targetValue) then
        pendingCameraDistanceValue = nil
        RefreshMiscPageState()
        return
    end

    -- Ab hier kommt die Änderung bewusst von uns.
    -- Das merken wir uns, damit das folgende CVAR_UPDATE nicht als "externe"
    -- Änderung interpretiert wird.
    pendingCameraDistanceValue = targetValue
    SetCVarValue(CAMERA_DISTANCE_CVAR, targetValue)
    RefreshMiscPageState()
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

    -- Das Kamera-Modul speichert keinen simplen true/false-Schalter,
    -- sondern bewusst den gewünschten Zielmodus.
    -- Falls einmal etwas Unerwartetes in der DB landet, normalisieren wir es hier.
    if BeavisQoLDB.misc.cameraDistanceMode ~= nil
        and BeavisQoLDB.misc.cameraDistanceMode ~= "standard"
        and BeavisQoLDB.misc.cameraDistanceMode ~= "max" then
        BeavisQoLDB.misc.cameraDistanceMode = nil
    end

    return BeavisQoLDB.misc
end

-- Für die UI unterscheiden wir vier Zustände:
-- max / standard = exakt einer unserer Presets
-- custom = ein anderer gültiger Wert
-- unknown = nichts Lesbares vom Client bekommen
function Misc.GetCurrentCameraDistanceMode()
    local currentValue = GetCurrentCameraDistanceValue()

    if IsSameCameraDistance(currentValue, CAMERA_DISTANCE_MAX) then
        return "max"
    end

    if IsSameCameraDistance(currentValue, CAMERA_DISTANCE_STANDARD) then
        return "standard"
    end

    if currentValue then
        return "custom"
    end

    return "unknown"
end

-- Baut den gut lesbaren Status-Text für die Misc-Seite.
function Misc.GetCameraDistanceStatusText()
    local currentMode = Misc.GetCurrentCameraDistanceMode()
    local currentValue = GetCurrentCameraDistanceValue()
    local valueText = FormatCameraDistanceValue(currentValue)

    if currentMode == "max" then
        return L("CAMERA_DISTANCE_STATUS_MAX"):format(valueText)
    end

    if currentMode == "standard" then
        return L("CAMERA_DISTANCE_STATUS_STANDARD"):format(valueText)
    end

    if currentMode == "custom" then
        return L("CAMERA_DISTANCE_STATUS_CUSTOM"):format(valueText)
    end

    return L("CAMERA_DISTANCE_STATUS_UNKNOWN")
end

-- Öffentliche Set-Funktion für die UI-Buttons.
-- Sie speichert zuerst den Wunschzustand und wendet ihn danach direkt an.
function Misc.SetCameraDistanceMode(mode)
    local db = Misc.GetMiscDB()

    -- Alles außerhalb unserer beiden Button-Modi behandeln wir defensiv:
    -- gespeicherten Wunsch löschen, Pending-Status vergessen, UI neu zeichnen.
    if mode ~= "max" and mode ~= "standard" then
        db.cameraDistanceMode = nil
        pendingCameraDistanceValue = nil
        RefreshMiscPageState()
        return
    end

    db.cameraDistanceMode = mode
    ApplySavedCameraDistanceMode()
end

-- Der Watcher deckt die drei wichtigen Momente ab:
-- PLAYER_LOGIN / PLAYER_ENTERING_WORLD = gespeicherten Wunsch wieder anlegen
-- CVAR_UPDATE = Änderungen am betroffenen CVar mitbekommen, egal ob von uns
-- oder von außen.
local CameraDistanceWatcher = CreateFrame("Frame")
CameraDistanceWatcher:RegisterEvent("PLAYER_LOGIN")
CameraDistanceWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
CameraDistanceWatcher:RegisterEvent("CVAR_UPDATE")

CameraDistanceWatcher:SetScript("OnEvent", function(_, event, cvarName)
    -- Beim Login und beim Betreten der Welt ziehen wir den gespeicherten Zustand
    -- noch einmal nach. Das ist der sicherste Moment, um den CVar wieder
    -- in unseren gewünschten Zustand zu bringen.
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ApplySavedCameraDistanceMode()
        return
    end

    -- Uns interessieren hier nur Updates genau dieses Kamera-CVars.
    -- Die Lowercase-Prüfung macht das Ganze unempfindlicher gegen API-Details.
    if event ~= "CVAR_UPDATE" or string.lower(cvarName or "") ~= CAMERA_DISTANCE_CVAR_LOWER then
        return
    end

    local currentValue = GetCurrentCameraDistanceValue()
    -- Wenn das Update genau den Wert bestätigt, den wir eben selbst gesetzt haben,
    -- müssen wir nichts weiter tun außer den Pending-Merker zurückzusetzen.
    if pendingCameraDistanceValue and IsSameCameraDistance(currentValue, pendingCameraDistanceValue) then
        pendingCameraDistanceValue = nil
        RefreshMiscPageState()
        return
    end

    -- Wurde der CVar von außen verändert, aber wir haben einen gespeicherten
    -- Wunschmodus, setzen wir unseren gewünschten Zustand wieder durch.
    if GetSavedCameraDistanceMode() then
        ApplySavedCameraDistanceMode()
        return
    end

    -- Falls kein gespeicherter Wunschzustand existiert, reicht ein UI-Refresh.
    RefreshMiscPageState()
end)
