local ADDON_NAME, BeavisAddon = ...

-- Erstelle Hauptfenster
local BeavisFrame = CreateFrame("Frame", "BeavisMainFrame", UIParent, "BasicFrameTemplateWithInset")
BeavisFrame:SetSize(UIParent:GetWidth() * 0.7, UIParent:GetHeight() * 0.7)
BeavisFrame:RegisterForDrag("LeftButton")
BeavisFrame:SetScript("OnDragStart", BeavisFrame.StartMoving)
BeavisFrame:SetScript("OnDragStop", BeavisFrame.StopMovingOrSizing)
BeavisFrame:SetMovable(true)
BeavisFrame:EnableMouse(true)
BeavisFrame:SetPoint("CENTER")
BeavisFrame:SetToplevel(true)
BeavisFrame:SetFrameStrata("HIGH")
BeavisFrame:Hide()

BeavisAddon.Frame = BeavisFrame

-- Funktion zum Updaten der Fenstergröße bei Bildschirmänderungen
local function UpdateBeavisFrameSize()
    local width = UIParent:GetWidth() * 0.7
    local height = UIParent:GetHeight() * 0.7
    BeavisFrame:SetSize(width, height)
end

-- Ausführen der Funktion beim Laden des Addons
UpdateBeavisFrameSize()

-- Event-Listener für Bildschirmänderungen
local resizeWatcher = CreateFrame("Frame")
resizeWatcher:RegisterEvent("UI_SCALE_CHANGED")
resizeWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
resizeWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Aktualisieren der Fenstergröße bei den entsprechenden Events
resizeWatcher:SetScript("OnEvent", function()
    UpdateBeavisFrameSize()
end)

-- Laden der Meta Infos 
local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "Unbekannt"
local name = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Unbekannt"


-- Erstellen von Header Container
local Header = CreateFrame("Frame", nil, BeavisFrame)
Header:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 8, -28)
Header:SetPoint("TOPRIGHT", BeavisFrame, "TOPRIGHT", -8, -28)
Header:SetHeight(72)

BeavisAddon.Header = Header

-- Hintergrund für Header
local HeaderBorder = Header:CreateTexture(nil, "ARTWORK")
HeaderBorder:SetPoint("BOTTOMLEFT", Header, "BOTTOMLEFT", 0, 0)
HeaderBorder:SetPoint("BOTTOMRIGHT", Header, "BOTTOMRIGHT", 0, 0)
HeaderBorder:SetHeight(1)
HeaderBorder:SetColorTexture(1, 0.82, 0, 0.9)

-- Erstellen von Logo im Header
local Logo = Header:CreateTexture(nil, "ARTWORK")
Logo:SetSize(64, 64)
Logo:SetPoint("LEFT", Header, "LEFT", 12, 0)
Logo:SetTexture("Interface\\AddOns\\BeavisAddon\\Media\\logo.tga")

-- Erstellen von Titel im Header
local Title = Header:CreateFontString(nil, "OVERLAY")
Title:SetPoint("LEFT", Logo, "RIGHT", 12, 0)
Title:SetFontObject(GameFontNormalHuge)
Title:SetTextColor(1, 0.82, 0, 1) 
Title:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
Title:SetText(name)

-- Erstellen der Sidebar
local Sidebar = CreateFrame("Frame", nil, BeavisFrame)
Sidebar:SetPoint("TOPLEFT", BeavisFrame, "TOPLEFT", 8, -110)
Sidebar:SetPoint("BOTTOMLEFT", BeavisFrame, "BOTTOMLEFT", 8, 8)
Sidebar:SetWidth(180)

BeavisAddon.Sidebar = Sidebar

-- Hintergrund für Sidebar
local SidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
SidebarBg:SetAllPoints()
SidebarBg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

-- Trennlinie rechts für Sidebar
local SidebarRightBorder = Sidebar:CreateTexture(nil, "ARTWORK")
SidebarRightBorder:SetPoint("TOPRIGHT", Sidebar, "TOPRIGHT", 0, 0)
SidebarRightBorder:SetPoint("BOTTOMRIGHT", Sidebar, "BOTTOMRIGHT", 0, 0)
SidebarRightBorder:SetWidth(1)
SidebarRightBorder:SetColorTexture(1, 0.82, 0, 0.9)

-- Inhaltsbereich
local Content = CreateFrame("Frame", nil, BeavisFrame)
Content:SetPoint("TOPLEFT", Sidebar, "TOPRIGHT", 8, 0)
Content:SetPoint("BOTTOMRIGHT", BeavisFrame, "BOTTOMRIGHT", -8, 8)

BeavisAddon.Content = Content

local ContentBg = Content:CreateTexture(nil, "BACKGROUND")
ContentBg:SetAllPoints()
ContentBg:SetColorTexture(0.08, 0.08, 0.08, 0.65)