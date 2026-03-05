local addonName, ns = ...
local L = ns.L or {} 
local LSM = LibStub("LibSharedMedia-3.0", true)
local _G = _G
local gsub = string.gsub
local pairs, ipairs = pairs, ipairs

SLASH_ATS1 = "/ats"
SLASH_HKS1 = "/hks"

ns.textCache = ns.textCache or {}
ns.fontCache = ns.fontCache or {}
ns.replacePatterns = ns.replacePatterns or {}

if LSM then
    LSM.RegisterCallback(ns, "LibSharedMedia_Registered", function(_, mediaType)
        if mediaType == "font" then
            ns:UpdateFontCache()
            ns:UpdateAllButtons()
        end
    end)
    LSM.RegisterCallback(ns, "LibSharedMedia_SetGlobal", function()
        ns:UpdateFontCache()
        ns:UpdateAllButtons()
    end)
end

local function OpenConfig()
    if Settings and Settings.OpenToCategory then
        local categoryID = ns.configCategories["Main"] and ns.configCategories["Main"]:GetID()
        if categoryID then Settings.OpenToCategory(categoryID) return end
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("ActionBar Text Styler")
    end
    print("|cff00ff00[ActionBar Text Styler]|r " .. (L["Open Config"] or "설정창 열기"))
end
SlashCmdList["ATS"] = OpenConfig
SlashCmdList["HKS"] = OpenConfig

function ns:InitDB()
    ActionBarTextStylerDB = ActionBarTextStylerDB or {}
    ActionBarTextStylerDB.profiles = ActionBarTextStylerDB.profiles or {}
    ActionBarTextStylerDB.profileKeys = ActionBarTextStylerDB.profileKeys or {}
end

function ns:LoadProfile()
    local charKey = UnitName("player") .. " - " .. GetRealmName()
    local currentProfileName = ActionBarTextStylerDB.profileKeys[charKey]
    
    if not currentProfileName then
        currentProfileName = "Default"
        ActionBarTextStylerDB.profileKeys[charKey] = currentProfileName
    end
    
    if not ActionBarTextStylerDB.profiles[currentProfileName] then
        ActionBarTextStylerDB.profiles[currentProfileName] = CopyTable(ns.defaults or {})
    end
    
    ns.db = ActionBarTextStylerDB.profiles[currentProfileName]
    ns.currentProfileName = currentProfileName
    
    ns:InitializePatterns()
    ns:UpdateFontCache()
    ns:UpdateAllButtons()
end

function ns:UpdateFontCache()
    local db = ns.db
    if not db then return end
    
    local base = GameFontNormal:GetFont()
    
    local function GetFontPath(fontName)
        if LSM and fontName and fontName ~= "Default" then
            local p = LSM:Fetch("font", fontName)
            if p then return p end
        end
        return base
    end

    ns.fontCache.hotkey = GetFontPath(db.fontName)
    ns.fontCache.stack = GetFontPath(db.stackFontName)
    ns.fontCache.macro = GetFontPath(db.macroFontName)
end

function ns:InitializePatterns()
    ns.replacePatterns = ns.replacePatterns or {}
    ns.textCache = ns.textCache or {}
    
    table.wipe(ns.replacePatterns)
    table.wipe(ns.textCache)
    
    local modifiers = {
        { "Shift%-", "textShift" }, { "SHIFT%-", "textShift" }, { "[sS]%-", "textShift" },
        { "Alt%-", "textAlt" },     { "ALT%-", "textAlt" },     { "[aA]%-", "textAlt" },
        { "Ctrl%-", "textCtrl" },   { "CTRL%-", "textCtrl" },   { "[cC]%-", "textCtrl" },
    }
    for _, m in ipairs(modifiers) do table.insert(ns.replacePatterns, m) end
    
    if ns.keyMap then
        for _, map in ipairs(ns.keyMap) do
            local localizedText = _G[map[1]] or map[1]
            if localizedText and localizedText ~= "" then
                local safePattern = localizedText:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
                table.insert(ns.replacePatterns, { safePattern, map[2] })
            end
        end
    end
end

local function GetShortenedText(text)
    local db = ns.db
    if not db then return text end 
    
    if not text or text == "" then return "" end
    if text == RANGE_INDICATOR or text == "●" then return "" end
    if not db.enableShorten then return text end
    
    if ns.textCache[text] then return ns.textCache[text] end

    local original = text
    for _, pat in ipairs(ns.replacePatterns or {}) do
        local replaceStr = db[pat[2]]
        if replaceStr == nil then replaceStr = (ns.defaults and ns.defaults[pat[2]]) or "" end
        text = gsub(text, pat[1], replaceStr)
    end
    ns.textCache[original] = text
    return text
end

-- [[ 핵심 수정: 신구형 프레임 통합 단축키 스캐너 ]] --
function ns:GetTrueHotkey(btn)
    local btnName = btn:GetName()
    if not btnName then return "" end

    local trueKey = nil
    if btn.commandName then
        trueKey = GetBindingKey(btn.commandName)
    end

    if not trueKey then
        local idStr = btnName:match("%d+$")
        local id = tonumber(idStr)
        if id then
            local prefix = "ACTIONBUTTON"
            -- 신형 MultiBarX 및 구형 MultiBarBottomLeft 모두 대응
            if btnName:match("MultiBar2") or btnName:match("MultiBarBottomLeft") then prefix = "MULTIACTIONBAR1BUTTON"
            elseif btnName:match("MultiBar3") or btnName:match("MultiBarBottomRight") then prefix = "MULTIACTIONBAR2BUTTON"
            elseif btnName:match("MultiBar4") or btnName:match("MultiBarRight") then prefix = "MULTIACTIONBAR3BUTTON"
            elseif btnName:match("MultiBar5") or btnName:match("MultiBarLeft") then prefix = "MULTIACTIONBAR4BUTTON"
            elseif btnName:match("MultiBar6") then prefix = "MULTIACTIONBAR5BUTTON"
            elseif btnName:match("MultiBar7") then prefix = "MULTIACTIONBAR6BUTTON"
            elseif btnName:match("PetAction") then prefix = "BONUSACTIONBUTTON"
            end
            trueKey = GetBindingKey(prefix .. id)
        end
    end

    if not trueKey then
        trueKey = GetBindingKey("CLICK " .. btnName .. ":LeftButton")
    end

    return trueKey and GetBindingText(trueKey) or ""
end

function ns:SetupLayout(btn)
    local db = ns.db
    if not db then return end
    
    local btnName = btn:GetName()
    if not btnName then return end
    local barPrefix = btnName:gsub("%d+$", "") 
    
    local hotkey = btn.HotKey
    if hotkey then
        if db["hide_" .. barPrefix .. "_HotKey"] then
            hotkey:SetAlpha(0)
            hotkey:Hide()
        else
            hotkey:SetAlpha(1)
            hotkey:SetFont(ns.fontCache.hotkey or GameFontNormal:GetFont(), db.fontSize, db.fontOutline)
            hotkey:ClearAllPoints()
            local align = db.textAlignment or "TOPRIGHT"
            hotkey:SetPoint(align, btn, align, db.xOffset, db.yOffset)
            hotkey:Show()
        end
    end
    -- [Count, Name 레이아웃 유지]
    local count = btn.Count
    if count and not db["hide_" .. barPrefix .. "_Count"] then
        count:SetAlpha(1); count:SetFont(ns.fontCache.stack or GameFontNormal:GetFont(), db.stackFontSize, db.stackFontOutline)
        count:ClearAllPoints(); count:SetPoint(db.stackTextAlignment or "BOTTOMRIGHT", btn, db.stackTextAlignment or "BOTTOMRIGHT", db.stackXOffset, db.stackYOffset)
    end
    local name = btn.Name
    if name and not db["hide_" .. barPrefix .. "_Name"] then
        name:SetAlpha(1); name:SetFont(ns.fontCache.macro or GameFontNormal:GetFont(), db.macroFontSize, db.macroFontOutline)
        name:ClearAllPoints(); name:SetPoint(db.macroTextAlignment or "BOTTOMLEFT", btn, db.macroTextAlignment or "BOTTOMLEFT", db.macroXOffset, db.macroYOffset)
    end
end

function ns:UpdateColor(btn)
    local db = ns.db
    if not db then return end
    local barPrefix = btn:GetName() and btn:GetName():gsub("%d+$", "") or ""

    if btn.HotKey and not db["hide_" .. barPrefix .. "_HotKey"] then
        local action = btn.action
        local r, g, b = unpack(db.colorNormal)
        if action then
            local inRange = IsActionInRange(action)
            if inRange == false then r, g, b = unpack(db.colorRange)
            elseif IsUsableAction(action) == false then r, g, b = unpack(db.colorUnusable) end
        end
        btn.HotKey:SetVertexColor(r, g, b)
    end
end

local hookedButtons = {}

function ns:InstallHooks(btn)
    if hookedButtons[btn] then return end
    hookedButtons[btn] = true

    if btn.HotKey then
        hooksecurefunc(btn.HotKey, "SetText", function(self, text)
            if self._atsUpdating then return end
            
            local parent = self:GetParent()
            local trueKey = parent and ns:GetTrueHotkey(parent) or ""
            
            if trueKey == "" and text and text ~= "" and text ~= RANGE_INDICATOR and text ~= "●" then
                trueKey = text
            end
            
            local newText = (trueKey ~= "") and GetShortenedText(trueKey) or ""
            
            self._atsUpdating = true
            self:SetText(newText)
            self._atsUpdating = false
            
            local barPrefix = parent:GetName():gsub("%d+$", "")
            if ns.db and not ns.db["hide_" .. barPrefix .. "_HotKey"] then self:Show() end
        end)
    end

    local function stateHook(self) 
        if not ns.db then return end
        pcall(ns.SetupLayout, ns, self) 
        pcall(ns.UpdateColor, ns, self) 
    end

    if btn.UpdateUsable then hooksecurefunc(btn, "UpdateUsable", stateHook) end
    if btn.UpdateRangeIndicator then hooksecurefunc(btn, "UpdateRangeIndicator", stateHook) end
    if btn.UpdateCount then hooksecurefunc(btn, "UpdateCount", stateHook) end
    if btn.Update then hooksecurefunc(btn, "Update", stateHook) end
    if btn.UpdateHotkeys then hooksecurefunc(btn, "UpdateHotkeys", stateHook) end 
end

function ns:UpdateAllButtons()
    if not ns.db then return end 

    for _, barName in ipairs(ns.actionBars or {}) do
        for i = 1, 12 do
            local btn = _G[barName..i]
            if btn then
                ns:InstallHooks(btn)
                if btn.HotKey then
                    local trueKey = ns:GetTrueHotkey(btn)
                    if trueKey == "" then
                        local t = btn.HotKey:GetText()
                        if t and t ~= RANGE_INDICATOR and t ~= "●" then trueKey = t end
                    end
                    local newText = (trueKey ~= "") and GetShortenedText(trueKey) or ""
                    btn.HotKey._atsUpdating = true
                    btn.HotKey:SetText(newText)
                    btn.HotKey._atsUpdating = false
                end
                ns:SetupLayout(btn)
                ns:UpdateColor(btn)
            end
        end
    end
end

local eventHandler = CreateFrame("Frame")
eventHandler:RegisterEvent("ADDON_LOADED")
eventHandler:RegisterEvent("PLAYER_LOGIN")
eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
eventHandler:RegisterEvent("UPDATE_BINDINGS") 

eventHandler:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns:InitDB()
    elseif event == "PLAYER_LOGIN" then
        ns:LoadProfile()
        ns:RegisterConfig()
        ns:UpdateAllButtons() 
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UPDATE_BINDINGS" then
        if not ns.db then return end 
        ns:UpdateFontCache()
        ns:UpdateAllButtons()
        if ns.RefreshOptionsUI then ns:RefreshOptionsUI() end
        C_Timer.After(2.0, function() if ns.db then ns:UpdateAllButtons() end end)
    end
end)