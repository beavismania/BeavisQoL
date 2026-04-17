local _, BeavisQoL = ...

BeavisQoL.Misc = BeavisQoL.Misc or {}
local Misc = BeavisQoL.Misc
local L = BeavisQoL.L
local baseGetMiscDB = Misc.GetMiscDB

local CHAT_LINK_HYPERLINK_TYPE = "beavisurl"
local CHAT_LINK_URL_PATTERN = "(https?://%S+)"
local CHAT_LINK_COLOR_CODE = "66ccff"

local chatFiltersInstalled = false
local chatSetItemRefHookInstalled = false
local originalSetItemRef = nil

local CHAT_FILTER_EVENTS = {
    "CHAT_MSG_ACHIEVEMENT",
    "CHAT_MSG_AFK",
    "CHAT_MSG_BATTLEGROUND",
    "CHAT_MSG_BATTLEGROUND_LEADER",
    "CHAT_MSG_BN_CONVERSATION",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_DND",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_GUILD_ACHIEVEMENT",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_MONSTER_EMOTE",
    "CHAT_MSG_MONSTER_PARTY",
    "CHAT_MSG_MONSTER_SAY",
    "CHAT_MSG_MONSTER_WHISPER",
    "CHAT_MSG_MONSTER_YELL",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_SAY",
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_YELL",
}

function Misc.GetMiscDB()
    local db

    if baseGetMiscDB then
        db = baseGetMiscDB()
    else
        BeavisQoLDB = BeavisQoLDB or {}
        BeavisQoLDB.misc = BeavisQoLDB.misc or {}
        db = BeavisQoLDB.misc
    end

    if db.chatLinkCopyEnabled == nil then
        db.chatLinkCopyEnabled = true
    end

    return db
end

function Misc.IsChatLinkCopyEnabled()
    return Misc.GetMiscDB().chatLinkCopyEnabled == true
end

function Misc.SetChatLinkCopyEnabled(value)
    Misc.GetMiscDB().chatLinkCopyEnabled = value == true
end

local function SplitTrailingUrlPunctuation(urlText)
    local workingUrl = tostring(urlText or "")
    local trailingParts = {}

    while workingUrl ~= "" do
        local lastCharacter = string.sub(workingUrl, -1)
        local shouldTrim = lastCharacter == "."
            or lastCharacter == ","
            or lastCharacter == "!"
            or lastCharacter == "?"
            or lastCharacter == ";"
            or lastCharacter == ":"

        if not shouldTrim and lastCharacter == ")" then
            local openCount = select(2, string.gsub(workingUrl, "%(", ""))
            local closeCount = select(2, string.gsub(workingUrl, "%)", ""))
            shouldTrim = closeCount > openCount
        elseif not shouldTrim and lastCharacter == "]" then
            local openCount = select(2, string.gsub(workingUrl, "%[", ""))
            local closeCount = select(2, string.gsub(workingUrl, "%]", ""))
            shouldTrim = closeCount > openCount
        elseif not shouldTrim and lastCharacter == "}" then
            local openCount = select(2, string.gsub(workingUrl, "{", ""))
            local closeCount = select(2, string.gsub(workingUrl, "}", ""))
            shouldTrim = closeCount > openCount
        end

        if not shouldTrim then
            break
        end

        table.insert(trailingParts, 1, lastCharacter)
        workingUrl = string.sub(workingUrl, 1, -2)
    end

    return workingUrl, table.concat(trailingParts)
end

local function BuildChatLinkMarkup(urlText)
    local normalizedUrl, trailingText = SplitTrailingUrlPunctuation(urlText)
    normalizedUrl = tostring(normalizedUrl or "")

    if normalizedUrl == "" then
        return tostring(urlText or ""), false
    end

    normalizedUrl = string.gsub(normalizedUrl, "|", "")

    local hyperlinkText = string.format(
        "|H%s:%s|h|cff%s%s|r|h",
        CHAT_LINK_HYPERLINK_TYPE,
        normalizedUrl,
        CHAT_LINK_COLOR_CODE,
        normalizedUrl
    )

    return hyperlinkText .. trailingText, true
end

local function ConvertUrlsInMessage(message)
    if type(message) ~= "string" or message == "" then
        return message, false
    end

    if string.find(message, "|H" .. CHAT_LINK_HYPERLINK_TYPE .. ":", 1, true) then
        return message, false
    end

    local didReplace = false
    local convertedMessage = string.gsub(message, CHAT_LINK_URL_PATTERN, function(urlText)
        local replacementText, replaced = BuildChatLinkMarkup(urlText)
        didReplace = didReplace or replaced
        return replacementText
    end)

    return convertedMessage, didReplace
end

local function TryHandleChatLink(link)
    if type(link) ~= "string" or link == "" then
        return false
    end

    local linkType, urlText = string.match(link, "^([^:]+):(.*)$")
    if linkType ~= CHAT_LINK_HYPERLINK_TYPE or type(urlText) ~= "string" or urlText == "" then
        return false
    end

    if BeavisQoL.ShowLinkPopup then
        BeavisQoL.ShowLinkPopup(L("CHAT_LINK_COPY_POPUP_TITLE"), urlText)
        return true
    end

    return false
end

local function InstallSetItemRefHook()
    if chatSetItemRefHookInstalled or type(SetItemRef) ~= "function" then
        return
    end

    originalSetItemRef = SetItemRef
    SetItemRef = function(link, text, button, chatFrame, ...)
        if TryHandleChatLink(link) then
            return
        end

        return originalSetItemRef(link, text, button, chatFrame, ...)
    end

    chatSetItemRefHookInstalled = true
end

local function ChatMessageFilter(_, _, message, ...)
    if not Misc.IsChatLinkCopyEnabled() then
        return false
    end

    local convertedMessage, didReplace = ConvertUrlsInMessage(message)
    if not didReplace then
        return false
    end

    return false, convertedMessage, ...
end

local function InstallChatFilters()
    if chatFiltersInstalled or type(ChatFrame_AddMessageEventFilter) ~= "function" then
        return
    end

    for _, eventName in ipairs(CHAT_FILTER_EVENTS) do
        ChatFrame_AddMessageEventFilter(eventName, ChatMessageFilter)
    end

    chatFiltersInstalled = true
end

local ChatLinkWatcher = CreateFrame("Frame")
ChatLinkWatcher:RegisterEvent("PLAYER_LOGIN")
ChatLinkWatcher:SetScript("OnEvent", function()
    InstallSetItemRefHook()
    InstallChatFilters()
end)
