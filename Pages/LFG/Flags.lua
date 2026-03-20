local ADDON_NAME, BeavisQoL = ...

BeavisQoL.LFG = BeavisQoL.LFG or {}
local LFG = BeavisQoL.LFG

-- Dieses Modul liest Realm-Namen aus dem Group Finder, ordnet sie einem Land zu
-- und rendert kleine Flaggen direkt mit WoW-Texturen statt mit externen Bildern.

-- Applicant- und Suchergebnis-Hooks kommen getrennt rein, weil Blizzard beides zu unterschiedlichen Zeitpunkten laden kann.
local applicantHookInstalled = false
local searchResultHookInstalled = false

-- Realm -> Flagge.
-- Blizzard liefert uns kein direktes "Land", also leiten wir es hier über den Realm ab.
local EU_REALM_FLAGS = {
    ["Aegwynn"] = "DE",
    ["Alexstrasza"] = "DE",
    ["Alleria"] = "DE",
    ["Antonidas"] = "DE",
    ["Arthas"] = "DE",
    ["Azshara"] = "DE",
    ["Baelgun"] = "DE",
    ["Blackhand"] = "DE",
    ["Blackmoore"] = "DE",
    ["Blackrock"] = "DE",
    ["Destromath"] = "DE",
    ["Die Aldor"] = "DE",
    ["Die Arguswacht"] = "DE",
    ["Dun Morogh"] = "DE",
    ["Eredar"] = "DE",
    ["Forscherliga"] = "DE",
    ["Frostwolf"] = "DE",
    ["Gilneas"] = "DE",
    ["Gul'dan"] = "DE",
    ["Kel'Thuzad"] = "DE",
    ["Khaz'goroth"] = "DE",
    ["Kult der Verdammten"] = "DE",
    ["Lothar"] = "DE",
    ["Madmortem"] = "DE",
    ["Mal'Ganis"] = "DE",
    ["Mannoroth"] = "DE",
    ["Nefarian"] = "DE",
    ["Nera'thor"] = "DE",
    ["Nozdormu"] = "DE",
    ["Rajaxx"] = "DE",
    ["Rexxar"] = "DE",
    ["Rubinwacht"] = "DE",
    ["Sen'jin"] = "DE",
    ["Thrall"] = "DE",
    ["Tirion"] = "DE",
    ["Todeswache"] = "DE",
    ["Ulduar"] = "DE",
    ["Un'Goro"] = "DE",
    ["Vek'lor"] = "DE",
    ["Wrathbringer"] = "DE",
    ["Zirkel des Cenarius"] = "DE",
    ["Argent Dawn"] = "GB",
    ["Draenor"] = "GB",
    ["Kazzak"] = "GB",
    ["Ravencrest"] = "GB",
    ["Silvermoon"] = "GB",
    ["Stormscale"] = "GB",
    ["Sylvanas"] = "GB",
    ["Tarren Mill"] = "GB",
    ["Twisting Nether"] = "GB",
    ["Outland"] = "GB",
    ["Ragnaros"] = "GB",
    ["Sanguino"] = "ES",
    ["C'Thun"] = "ES",
    ["Dun Modr"] = "ES",
    ["Exodar"] = "ES",
    ["Los Errantes"] = "ES",
    ["Minahonda"] = "ES",
    ["Tyrande"] = "ES",
    ["Uldum"] = "ES",
    ["Aggra (Portuguese)"] = "PT",
    ["Aggra (Portugues)"] = "PT",
    ["Nemesis"] = "IT",
}

local US_REALM_FLAGS = {
    ["Azralon"] = "BR",
    ["Gallywix"] = "BR",
    ["Goldrinn"] = "BR",
    ["Nemesis"] = "BR",
    ["Tol Barad"] = "BR",
    ["Aman'Thul"] = "AU",
    ["Barthilas"] = "AU",
    ["Caelestrasz"] = "AU",
    ["Dreadmaul"] = "AU",
    ["Frostmourne"] = "AU",
    ["Gundrak"] = "AU",
    ["Jubei'Thos"] = "AU",
    ["Khaz'goroth"] = "AU",
    ["Nagrand"] = "AU",
    ["Saurfang"] = "AU",
    ["Thaurissan"] = "AU",
}

function LFG.GetLFGDB()
    BeavisQoLDB = BeavisQoLDB or {}
    BeavisQoLDB.lfg = BeavisQoLDB.lfg or {}

    if BeavisQoLDB.lfg.flagsEnabled == nil then
        BeavisQoLDB.lfg.flagsEnabled = false
    end

    return BeavisQoLDB.lfg
end

function LFG.IsFlagsEnabled()
    return LFG.GetLFGDB().flagsEnabled == true
end

-- Manche Blizzard-Felder kommen inzwischen als "secret value" rein.
-- Solche Werte dürfen wir nicht wie normale Strings behandeln.
local function IsSecretValue(value)
    if not issecretvalue then
        return false
    end

    local ok, isSecret = pcall(issecretvalue, value)
    return ok and isSecret or false
end

local function IsUsablePlainString(value)
    if IsSecretValue(value) then
        return false
    end

    local ok, isUsable = pcall(function()
        return type(value) == "string" and value ~= ""
    end)

    return ok and isUsable or false
end

-- Realmnamen kommen je nach Quelle mit Bindestrich oder etwas seltsamen Leerzeichen rein.
local function NormalizeRealmName(realmName)
    if not IsUsablePlainString(realmName) then
        return nil
    end

    realmName = realmName:gsub("%s+", " ")
    realmName = realmName:gsub("^%s+", "")
    realmName = realmName:gsub("%s+$", "")

    return realmName
end

-- Applicant-Namen kommen als "Name-Realm". Für denselben Realm wie wir selbst gibt es nicht immer einen Bindestrich.
local function GetRealmNameFromFullName(fullName)
    if not IsUsablePlainString(fullName) then
        return nil
    end

    local realmName = fullName:match("%-(.+)$")
    if IsUsablePlainString(realmName) then
        return NormalizeRealmName(realmName)
    end

    if GetRealmName then
        return NormalizeRealmName(GetRealmName())
    end
end

-- Fallback, falls ein Realm noch nicht in unserer Liste steht.
local function GetDefaultFlagForRegion()
    if not GetCurrentRegion then
        return nil
    end

    local region = GetCurrentRegion()
    if region == 3 then
        return "GB"
    end

    if region == 1 then
        return "US"
    end
end

-- Die eigentliche Zuordnung läuft absichtlich separat, damit man die Realm-Listen später leichter erweitern kann.
function LFG.GetCountryCodeForRealm(realmName)
    realmName = NormalizeRealmName(realmName)
    if not realmName then
        return nil
    end

    if GetCurrentRegion and GetCurrentRegion() == 3 then
        return EU_REALM_FLAGS[realmName] or GetDefaultFlagForRegion()
    end

    if GetCurrentRegion and GetCurrentRegion() == 1 then
        return US_REALM_FLAGS[realmName] or GetDefaultFlagForRegion()
    end

    return nil
end

-- Vor jedem Rendern setzen wir den Flaggen-Frame wieder komplett in einen neutralen Zustand.
local function HideFlagParts(flagFrame)
    flagFrame.Background:Hide()

    for _, texture in ipairs(flagFrame.Parts) do
        texture:Hide()
        texture:ClearAllPoints()
        texture:SetRotation(0)
    end
end

local function SetTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], 1)
end

-- Kleine Bauhelfer für simple Flaggen, die nur aus Streifen bestehen.
local function DrawHorizontalStripes(flagFrame, colors, ratios)
    local totalRatio = 0
    for _, ratio in ipairs(ratios) do
        totalRatio = totalRatio + ratio
    end

    local offsetY = 0
    for index, color in ipairs(colors) do
        local texture = flagFrame.Parts[index]
        local height = flagFrame:GetHeight() * (ratios[index] / totalRatio)

        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, -offsetY)
        texture:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, -offsetY)
        texture:SetHeight(height)
        SetTextureColor(texture, color)
        texture:Show()

        offsetY = offsetY + height
    end
end

local function DrawVerticalStripes(flagFrame, colors, ratios)
    local totalRatio = 0
    for _, ratio in ipairs(ratios) do
        totalRatio = totalRatio + ratio
    end

    local offsetX = 0
    for index, color in ipairs(colors) do
        local texture = flagFrame.Parts[index]
        local width = flagFrame:GetWidth() * (ratios[index] / totalRatio)

        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", offsetX, 0)
        texture:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", offsetX, 0)
        texture:SetWidth(width)
        SetTextureColor(texture, color)
        texture:Show()

        offsetX = offsetX + width
    end
end

-- Die komplexeren Flaggen bauen wir bewusst selbst aus Texturen auf,
-- damit wir keine externen Assets mitschleppen müssen.
local function DrawUnionJack(flagFrame)
    local angle = math.atan(12 / 18)

    flagFrame.Background:SetColorTexture(0.0, 0.16, 0.53, 1)
    flagFrame.Background:Show()

    local diagWhiteA = flagFrame.Parts[1]
    diagWhiteA:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagWhiteA:SetSize(24, 3)
    diagWhiteA:SetRotation(angle)
    SetTextureColor(diagWhiteA, { 1, 1, 1 })
    diagWhiteA:Show()

    local diagWhiteB = flagFrame.Parts[2]
    diagWhiteB:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagWhiteB:SetSize(24, 3)
    diagWhiteB:SetRotation(-angle)
    SetTextureColor(diagWhiteB, { 1, 1, 1 })
    diagWhiteB:Show()

    local crossWhiteH = flagFrame.Parts[3]
    crossWhiteH:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossWhiteH:SetSize(flagFrame:GetWidth(), 4)
    SetTextureColor(crossWhiteH, { 1, 1, 1 })
    crossWhiteH:Show()

    local crossWhiteV = flagFrame.Parts[4]
    crossWhiteV:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossWhiteV:SetSize(4, flagFrame:GetHeight())
    SetTextureColor(crossWhiteV, { 1, 1, 1 })
    crossWhiteV:Show()

    local diagRedA = flagFrame.Parts[5]
    diagRedA:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagRedA:SetSize(24, 1)
    diagRedA:SetRotation(angle)
    SetTextureColor(diagRedA, { 0.78, 0.0, 0.13 })
    diagRedA:Show()

    local diagRedB = flagFrame.Parts[6]
    diagRedB:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diagRedB:SetSize(24, 1)
    diagRedB:SetRotation(-angle)
    SetTextureColor(diagRedB, { 0.78, 0.0, 0.13 })
    diagRedB:Show()

    local crossRedH = flagFrame.Parts[7]
    crossRedH:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossRedH:SetSize(flagFrame:GetWidth(), 2)
    SetTextureColor(crossRedH, { 0.78, 0.0, 0.13 })
    crossRedH:Show()

    local crossRedV = flagFrame.Parts[8]
    crossRedV:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    crossRedV:SetSize(2, flagFrame:GetHeight())
    SetTextureColor(crossRedV, { 0.78, 0.0, 0.13 })
    crossRedV:Show()
end

local function DrawUSFlag(flagFrame)
    DrawHorizontalStripes(flagFrame, {
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
        { 1.00, 1.00, 1.00 },
        { 0.70, 0.13, 0.20 },
    }, { 1, 1, 1, 1, 1, 1, 1 })

    local canton = flagFrame.Parts[8]
    canton:ClearAllPoints()
    canton:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    canton:SetSize(8, 6)
    SetTextureColor(canton, { 0.16, 0.21, 0.58 })
    canton:Show()
end

local function DrawBrazilFlag(flagFrame)
    flagFrame.Background:SetColorTexture(0.0, 0.61, 0.28, 1)
    flagFrame.Background:Show()

    local diamond = flagFrame.Parts[1]
    diamond:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    diamond:SetSize(10, 10)
    diamond:SetRotation(math.rad(45))
    SetTextureColor(diamond, { 1.0, 0.87, 0.0 })
    diamond:Show()

    local orb = flagFrame.Parts[2]
    orb:SetPoint("CENTER", flagFrame, "CENTER", 0, 0)
    orb:SetSize(4, 4)
    SetTextureColor(orb, { 0.0, 0.15, 0.55 })
    orb:Show()
end

local function DrawAustraliaFlag(flagFrame)
    flagFrame.Background:SetColorTexture(0.0, 0.16, 0.53, 1)
    flagFrame.Background:Show()

    local star = flagFrame.Parts[1]
    star:SetPoint("CENTER", flagFrame, "CENTER", 4, -1)
    star:SetSize(3, 3)
    SetTextureColor(star, { 1, 1, 1 })
    star:Show()

    local cantonH = flagFrame.Parts[2]
    cantonH:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    cantonH:SetSize(8, 2)
    SetTextureColor(cantonH, { 1, 1, 1 })
    cantonH:Show()

    local cantonV = flagFrame.Parts[3]
    cantonV:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 3, 0)
    cantonV:SetSize(2, 6)
    SetTextureColor(cantonV, { 1, 1, 1 })
    cantonV:Show()

    local cantonRedH = flagFrame.Parts[4]
    cantonRedH:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    cantonRedH:SetSize(8, 1)
    SetTextureColor(cantonRedH, { 0.78, 0.0, 0.13 })
    cantonRedH:Show()

    local cantonRedV = flagFrame.Parts[5]
    cantonRedV:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 3, 0)
    cantonRedV:SetSize(1, 6)
    SetTextureColor(cantonRedV, { 0.78, 0.0, 0.13 })
    cantonRedV:Show()
end

-- Jeder Applicant-Row bekommt genau einen wiederverwendbaren Flaggen-Frame.
local function EnsureFlagFrame(parent)
    if parent.BeavisCountryFlag then
        return parent.BeavisCountryFlag
    end

    -- Der Frame wird nur einmal erzeugt und danach für spätere Updates
    -- wiederverwendet. Das spart Arbeit bei jeder Listen-Aktualisierung.
    local flagFrame = CreateFrame("Frame", nil, parent)
    flagFrame:SetSize(18, 12)
    flagFrame:Hide()

    flagFrame.Background = flagFrame:CreateTexture(nil, "BACKGROUND")
    flagFrame.Background:SetAllPoints()
    flagFrame.Background:Hide()

    flagFrame.Parts = {}
    for index = 1, 8 do
        local texture = flagFrame:CreateTexture(nil, "ARTWORK")
        texture:Hide()
        flagFrame.Parts[index] = texture
    end

    local borderTop = flagFrame:CreateTexture(nil, "OVERLAY")
    borderTop:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, 0)
    borderTop:SetHeight(1)
    borderTop:SetColorTexture(0, 0, 0, 0.9)

    local borderBottom = flagFrame:CreateTexture(nil, "OVERLAY")
    borderBottom:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", flagFrame, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetColorTexture(0, 0, 0, 0.9)

    local borderLeft = flagFrame:CreateTexture(nil, "OVERLAY")
    borderLeft:SetPoint("TOPLEFT", flagFrame, "TOPLEFT", 0, 0)
    borderLeft:SetPoint("BOTTOMLEFT", flagFrame, "BOTTOMLEFT", 0, 0)
    borderLeft:SetWidth(1)
    borderLeft:SetColorTexture(0, 0, 0, 0.9)

    local borderRight = flagFrame:CreateTexture(nil, "OVERLAY")
    borderRight:SetPoint("TOPRIGHT", flagFrame, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", flagFrame, "BOTTOMRIGHT", 0, 0)
    borderRight:SetWidth(1)
    borderRight:SetColorTexture(0, 0, 0, 0.9)

    parent.BeavisCountryFlag = flagFrame
    return flagFrame
end

-- Hier landet die Auswahl der Flaggen-Optik.
local function RenderFlag(flagFrame, countryCode)
    HideFlagParts(flagFrame)

    if countryCode == "DE" then
        DrawHorizontalStripes(flagFrame, {
            { 0.0, 0.0, 0.0 },
            { 0.87, 0.0, 0.0 },
            { 1.0, 0.81, 0.0 },
        }, { 1, 1, 1 })
    elseif countryCode == "GB" then
        DrawUnionJack(flagFrame)
    elseif countryCode == "ES" then
        DrawHorizontalStripes(flagFrame, {
            { 0.67, 0.0, 0.12 },
            { 1.0, 0.80, 0.0 },
            { 0.67, 0.0, 0.12 },
        }, { 1, 2, 1 })
    elseif countryCode == "PT" then
        DrawVerticalStripes(flagFrame, {
            { 0.0, 0.40, 0.18 },
            { 0.82, 0.0, 0.0 },
        }, { 2, 3 })
    elseif countryCode == "IT" then
        DrawVerticalStripes(flagFrame, {
            { 0.0, 0.57, 0.27 },
            { 1.0, 1.0, 1.0 },
            { 0.81, 0.0, 0.0 },
        }, { 1, 1, 1 })
    elseif countryCode == "US" then
        DrawUSFlag(flagFrame)
    elseif countryCode == "BR" then
        DrawBrazilFlag(flagFrame)
    elseif countryCode == "AU" then
        DrawAustraliaFlag(flagFrame)
    else
        flagFrame:Hide()
        return
    end

    flagFrame:Show()
end

local function GetFontStringByKeys(frame, preferredKeys)
    for _, key in ipairs(preferredKeys) do
        local region = frame[key]
        if region and region.GetObjectType and region:GetObjectType() == "FontString" then
            return region
        end
    end
end

local function GetAllFontStrings(frame)
    local fontStrings = {}

    -- Blizzard benennt Text-Regionen nicht in jeder Ansicht gleich.
    -- Darum sammeln wir rekursiv alle FontStrings eines Frame-Baums ein.
    local function CollectFontStrings(owner)
        for _, region in ipairs({ owner:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                table.insert(fontStrings, region)
            end
        end

        for _, child in ipairs({ owner:GetChildren() }) do
            CollectFontStrings(child)
        end
    end

    CollectFontStrings(frame)
    return fontStrings
end

-- Der Blizzard-Applicant-Row ist nicht super konsistent benannt.
-- Deshalb suchen wir zuerst nach bekannten Keys und fallen dann auf die Regionen des Frames zurück.
local function GetApplicantNameRegion(memberFrame)
    local preferredKeys = {
        "Name",
        "name",
        "MemberName",
        "PlayerName",
    }

    local region = GetFontStringByKeys(memberFrame, preferredKeys)
    if region then
        return region
    end

    for _, fontString in ipairs(GetAllFontStrings(memberFrame)) do
        local text = fontString.GetText and fontString:GetText()
        if IsUsablePlainString(text) and text ~= INVITE then
            return fontString
        end
    end
end

-- Bei Suchergebnissen hängen wir die Flagge an den sichtbaren Gruppentitel.
local function GetSearchResultNameRegion(resultFrame)
    local preferredKeys = {
        "Name",
        "name",
        "Title",
        "TitleText",
        "NameString",
        "ActivityName",
        "LeaderName",
    }

    local region = GetFontStringByKeys(resultFrame, preferredKeys)
    if region then
        return region
    end

    for _, fontString in ipairs(GetAllFontStrings(resultFrame)) do
        return fontString
    end

    return resultFrame
end

-- Je nach Blizzard-Version oder Hook-Signatur liegt die SearchResult-ID an
-- unterschiedlichen Stellen. Diese Funktion normalisiert alle Varianten.
local function GetSearchResultID(resultFrame, ...)
    local function ReturnIfNumber(value)
        if type(value) == "number" then
            return value
        end
    end

    local searchResultID = ReturnIfNumber(resultFrame.searchResultID)
    if searchResultID then
        return searchResultID
    end

    local resultID = ReturnIfNumber(resultFrame.resultID)
    if resultID then
        return resultID
    end

    if resultFrame.data then
        searchResultID = ReturnIfNumber(resultFrame.data.searchResultID)
        if searchResultID then
            return searchResultID
        end

        resultID = ReturnIfNumber(resultFrame.data.resultID)
        if resultID then
            return resultID
        end
    end

    if resultFrame.searchResultInfo then
        searchResultID = ReturnIfNumber(resultFrame.searchResultInfo.searchResultID)
        if searchResultID then
            return searchResultID
        end

        resultID = ReturnIfNumber(resultFrame.searchResultInfo.resultID)
        if resultID then
            return resultID
        end
    end

    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "number" then
            return value
        end

        if type(value) == "table" then
            if type(value.searchResultID) == "number" then
                return value.searchResultID
            end

            if type(value.resultID) == "number" then
                return value.resultID
            end

            if value.data and type(value.data.searchResultID) == "number" then
                return value.data.searchResultID
            end
        end
    end
end

-- Diese Funktion hängt die Flagge konkret an einen Bewerber-Row.
function LFG.ApplyFlagToApplicantMember(memberFrame, applicantID, memberIdx)
    if not memberFrame then
        return
    end

    local flagFrame = EnsureFlagFrame(memberFrame)
    memberFrame.BeavisApplicantID = applicantID
    memberFrame.BeavisMemberIdx = memberIdx

    if not LFG.IsFlagsEnabled() then
        flagFrame:Hide()
        return
    end

    if not applicantID or not memberIdx then
        flagFrame:Hide()
        return
    end

    local fullName = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx)
    local realmName = GetRealmNameFromFullName(fullName)
    local countryCode = LFG.GetCountryCodeForRealm(realmName)
    local nameRegion = GetApplicantNameRegion(memberFrame)

    if not countryCode or not nameRegion then
        flagFrame:Hide()
        return
    end

    flagFrame:ClearAllPoints()
    -- Der negative Offset zieht die Flagge leicht in den Namensbereich, damit sie optisch wie im Blizzard-Layout sitzt.
    flagFrame:SetPoint("LEFT", nameRegion, "RIGHT", -14, 0)
    RenderFlag(flagFrame, countryCode)
end

-- Auch die eigentliche Suchergebnis-Liste kann eine Flagge bekommen, weil Blizzard uns dort den leaderName mitliefert.
function LFG.ApplyFlagToSearchResult(resultFrame, ...)
    if not resultFrame then
        return
    end

    local flagFrame = EnsureFlagFrame(resultFrame)
    local searchResultID = GetSearchResultID(resultFrame, ...)
    resultFrame.BeavisSearchResultID = searchResultID

    if not LFG.IsFlagsEnabled() then
        flagFrame:Hide()
        return
    end

    if not searchResultID or not C_LFGList or not C_LFGList.GetSearchResultInfo then
        flagFrame:Hide()
        return
    end

    local searchResultInfo = C_LFGList.GetSearchResultInfo(searchResultID)
    if type(searchResultInfo) ~= "table" then
        flagFrame:Hide()
        return
    end

    -- leaderName kann inzwischen als Secret geliefert werden. Dann dürfen wir ihn nicht zerlegen.
    if IsSecretValue(searchResultInfo.leaderName) then
        flagFrame:Hide()
        return
    end

    local realmName = GetRealmNameFromFullName(searchResultInfo.leaderName)
    local countryCode = LFG.GetCountryCodeForRealm(realmName)
    local nameRegion = GetSearchResultNameRegion(resultFrame)

    if not countryCode or not nameRegion then
        flagFrame:Hide()
        return
    end

    flagFrame:ClearAllPoints()
    flagFrame:SetPoint("LEFT", nameRegion, "RIGHT", 6, 0)
    RenderFlag(flagFrame, countryCode)
end

-- Kleiner Tiefenlauf durch den Frame-Baum.
-- Den brauchen wir, um bereits sichtbare Zeilen später gezielt zu aktualisieren.
local function VisitFrameTree(frame, callback)
    if not frame then
        return
    end

    callback(frame)

    for _, child in ipairs({ frame:GetChildren() }) do
        VisitFrameTree(child, callback)
    end
end

-- Wenn sich die Applicant-Liste ändert, ziehen wir über alle sichtbaren Rows und aktualisieren nur unsere Extras.
local function RefreshVisibleApplicantFlags()
    local applicationViewer = LFGListFrame and LFGListFrame.ApplicationViewer
    if not applicationViewer then
        return
    end

    VisitFrameTree(applicationViewer, function(frame)
        if frame.BeavisCountryFlag and frame.BeavisApplicantID and frame.BeavisMemberIdx then
            LFG.ApplyFlagToApplicantMember(frame, frame.BeavisApplicantID, frame.BeavisMemberIdx)
        end
    end)
end

-- Dasselbe Prinzip für die Suchergebnis-Liste: nur sichtbare Zeilen anfassen, nichts neu aufbauen.
local function RefreshVisibleSearchResultFlags()
    local searchPanel = LFGListFrame and LFGListFrame.SearchPanel
    if not searchPanel then
        return
    end

    VisitFrameTree(searchPanel, function(frame)
        if frame.BeavisCountryFlag and frame.BeavisSearchResultID then
            LFG.ApplyFlagToSearchResult(frame, frame.BeavisSearchResultID)
        end
    end)
end

-- Wir hooken bewusst die Blizzard-Update-Funktion statt selbst die ganze Liste nachzubauen.
local function TryInstallHooks()
    if not applicantHookInstalled and type(LFGListApplicationViewer_UpdateApplicantMember) == "function" then
        -- hooksecurefunc haengt unser Verhalten nur an Blizzard an und ersetzt
        -- keine Originalfunktion. Das ist für UI-Addons deutlich robuster.
        hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(memberFrame, applicantID, memberIdx)
            LFG.ApplyFlagToApplicantMember(memberFrame, applicantID, memberIdx)
        end)

        applicantHookInstalled = true
    end

    if not searchResultHookInstalled and type(LFGListSearchEntry_Update) == "function" then
        hooksecurefunc("LFGListSearchEntry_Update", function(resultFrame, ...)
            LFG.ApplyFlagToSearchResult(resultFrame, ...)
        end)

        searchResultHookInstalled = true
    end
end

function LFG.SetFlagsEnabled(value)
    LFG.GetLFGDB().flagsEnabled = value and true or false
    TryInstallHooks()
    RefreshVisibleApplicantFlags()
    RefreshVisibleSearchResultFlags()
end

-- Die Events sind nur dazu da, den Hook im richtigen Moment zu setzen und sichtbare Einträge nachzuziehen.
local FlagWatcher = CreateFrame("Frame")
FlagWatcher:RegisterEvent("PLAYER_LOGIN")
FlagWatcher:RegisterEvent("ADDON_LOADED")
FlagWatcher:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
FlagWatcher:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
FlagWatcher:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
FlagWatcher:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")

FlagWatcher:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "Blizzard_GroupFinder" then
            return
        end
    end

    TryInstallHooks()

    if LFG.IsFlagsEnabled() then
        RefreshVisibleApplicantFlags()
        RefreshVisibleSearchResultFlags()
    end
end)
