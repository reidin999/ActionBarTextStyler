local addonName, ns = ...
local L = ns.L -- [L10n]
local LSM = LibStub("LibSharedMedia-3.0", true)
local _G = _G
local gsub = string.gsub
local pairs, ipairs = pairs, ipairs

SLASH_ATS1 = "/ats"
SLASH_HKS1 = "/hks"

ns.textCache = {}
ns.fontCache = {}

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
    print("|cff00ff00[ActionBar Text Styler]|r " .. L["Open Config"])
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
        ActionBarTextStylerDB.profiles[currentProfileName] = CopyTable(ns.defaults)
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

function ns:SetProfile(profileName)
    if not ActionBarTextStylerDB.profiles[profileName] then
        ActionBarTextStylerDB.profiles[profileName] = CopyTable(ns.defaults)
    end
    local charKey = UnitName("player") .. " - " .. GetRealmName()
    ActionBarTextStylerDB.profileKeys[charKey] = profileName
    ns.db = ActionBarTextStylerDB.profiles[profileName]
    ns.currentProfileName = profileName
    
    ns:InitializePatterns()
    ns:UpdateFontCache()
    ns:UpdateAllButtons()
    if ns.RefreshOptionsUI then ns:RefreshOptionsUI() end
    
    print("|cff00ff00[ATS]|r " .. L["Profile Changed"]:format(profileName))
end

function ns:CreateProfile(profileName, copyCurrent)
    if ActionBarTextStylerDB.profiles[profileName] then
        print("|cffff0000[ATS]|r " .. L["Profile Name Exists"])
        return
    end
    local newData = copyCurrent and CopyTable(ns.db) or CopyTable(ns.defaults)
    ActionBarTextStylerDB.profiles[profileName] = newData
    ns:SetProfile(profileName)
end

function ns:CopyProfileFrom(sourceProfileName)
    if not sourceProfileName or not ActionBarTextStylerDB.profiles[sourceProfileName] then return end
    table.wipe(ns.db)
    local sourceData = ActionBarTextStylerDB.profiles[sourceProfileName]
    for k, v in pairs(sourceData) do
        if type(v) == "table" then ns.db[k] = CopyTable(v) else ns.db[k] = v end
    end
    ns:InitializePatterns()
    ns:UpdateFontCache()
    ns:UpdateAllButtons()
    if ns.RefreshOptionsUI then ns:RefreshOptionsUI() end
    print("|cff00ff00[ATS]|r " .. L["Profile Copied"]:format(sourceProfileName))
end

function ns:ResetProfile()
    if not ns.db then return end
    table.wipe(ns.db)
    for k, v in pairs(ns.defaults) do ns.db[k] = v end
    ns:InitializePatterns()
    ns:UpdateFontCache()
    ns:UpdateAllButtons()
    if ns.RefreshOptionsUI then ns:RefreshOptionsUI() end
    print("|cff00ff00[ATS]|r " .. L["Profile Reset"])
end

function ns:DeleteProfile(profileName)
    if profileName == "Default" then return end
    ActionBarTextStylerDB.profiles[profileName] = nil
    print("|cff00ff00[ATS]|r " .. L["Profile Deleted"]:format(profileName))
    
    if profileName == ns.currentProfileName then
        ns:SetProfile("Default")
    elseif ns.RefreshOptionsUI then
        ns:RefreshOptionsUI()
    end
end

ns.replacePatterns = {}

function ns:InitializePatterns()
    table.wipe(ns.replacePatterns)
    table.wipe(ns.textCache)
    local modifiers = {
        { "Shift%-", "textShift" }, { "SHIFT%-", "textShift" }, { "[sS]%-", "textShift" },
        { "Alt%-", "textAlt" },     { "ALT%-", "textAlt" },     { "[aA]%-", "textAlt" },
        { "Ctrl%-", "textCtrl" },   { "CTRL%-", "textCtrl" },   { "[cC]%-", "textCtrl" },
    }
    for _, m in ipairs(modifiers) do table.insert(ns.replacePatterns, m) end
    for _, map in ipairs(ns.keyMap) do
        local localizedText = _G[map[1]] or map[1]
        if localizedText and localizedText ~= "" then
            local safePattern = localizedText:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
            table.insert(ns.replacePatterns, { safePattern, map[2] })
        end
    end
end

-- 텍스트 축약 로직
local function GetShortenedText(text)
    local db = ns.db
    if not db then return text end 
    
    if not text or text == "" then return "" end
    if text == RANGE_INDICATOR or text == "●" then return "" end
    if not db.enableShorten then return text end
    if ns.textCache[text] then return ns.textCache[text] end

    local original = text
    for _, pat in ipairs(ns.replacePatterns) do
        local replaceStr = db[pat[2]]
        if replaceStr == nil then replaceStr = ns.defaults[pat[2]] end
        if replaceStr == nil then replaceStr = "" end
        text = gsub(text, pat[1], replaceStr)
    end
    ns.textCache[original] = text
    return text
end

local function GetButtonColor(btn)
    local db = ns.db
    local action = btn.action
    if not action then return db.colorNormal end
    
    local inRange = IsActionInRange(action)
    if inRange == false then return db.colorRange end
    
    local isUsable, noMana = IsUsableAction(action)
    if not isUsable and not noMana then return db.colorUnusable end
    if noMana then return db.colorMana end
    
    return db.colorNormal
end

-- [핵심] 와우 시스템에 의존하지 않는 무결점 단축키 스캐너
local function GetTrueHotkey(btn)
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
            if btnName:match("MultiBarBottomLeft") then prefix = "MULTIACTIONBAR1BUTTON"
            elseif btnName:match("MultiBarBottomRight") then prefix = "MULTIACTIONBAR2BUTTON"
            elseif btnName:match("MultiBarRight") then prefix = "MULTIACTIONBAR3BUTTON"
            elseif btnName:match("MultiBarLeft") then prefix = "MULTIACTIONBAR4BUTTON"
            elseif btnName:match("MultiBar5") then prefix = "MULTIACTIONBAR5BUTTON"
            elseif btnName:match("MultiBar6") then prefix = "MULTIACTIONBAR6BUTTON"
            elseif btnName:match("MultiBar7") then prefix = "MULTIACTIONBAR7BUTTON"
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

-- 폰트, 크기, 위치 세팅
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
            hotkey:SetFont(ns.fontCache.hotkey, db.fontSize, db.fontOutline)
            if db.enableShadow then
                hotkey:SetShadowOffset(1, -1); hotkey:SetShadowColor(0, 0, 0, 1)
            else
                hotkey:SetShadowColor(0, 0, 0, 0)
            end
            hotkey:ClearAllPoints()
            local align = db.textAlignment or "TOPRIGHT"
            local justify = "CENTER"
            if align:find("LEFT") then justify = "LEFT" elseif align:find("RIGHT") then justify = "RIGHT" end
            hotkey:SetJustifyH(justify)
            hotkey:SetPoint(align, btn, align, db.xOffset, db.yOffset)
            hotkey:SetWidth(0)
        end
    end

    local count = btn.Count
    if count then
        if db["hide_" .. barPrefix .. "_Count"] then
            count:SetAlpha(0)
        else
            count:SetAlpha(1)
            count:SetFont(ns.fontCache.stack, db.stackFontSize, db.stackFontOutline)
            if db.stackEnableShadow then
                count:SetShadowOffset(1, -1); count:SetShadowColor(0, 0, 0, 1)
            else
                count:SetShadowColor(0, 0, 0, 0)
            end
            count:ClearAllPoints()
            local stackAlign = db.stackTextAlignment or "BOTTOMRIGHT"
            local stackJustify = "CENTER"
            if stackAlign:find("LEFT") then stackJustify = "LEFT" elseif stackAlign:find("RIGHT") then stackJustify = "RIGHT" end
            count:SetJustifyH(stackJustify)
            count:SetPoint(stackAlign, btn, stackAlign, db.stackXOffset, db.stackYOffset)
        end
    end

    local name = btn.Name
    if name then
        if db["hide_" .. barPrefix .. "_Name"] then
            name:SetAlpha(0)
        else
            name:SetAlpha(1)
            name:SetFont(ns.fontCache.macro, db.macroFontSize, db.macroFontOutline)
            if db.macroEnableShadow then
                name:SetShadowOffset(1, -1); name:SetShadowColor(0, 0, 0, 1)
            else
                name:SetShadowColor(0, 0, 0, 0)
            end
            name:ClearAllPoints()
            local macroAlign = db.macroTextAlignment or "BOTTOMLEFT"
            local macroJustify = "CENTER"
            if macroAlign:find("LEFT") then macroJustify = "LEFT" elseif macroAlign:find("RIGHT") then macroJustify = "RIGHT" end
            name:SetJustifyH(macroJustify)
            name:SetPoint(macroAlign, btn, macroAlign, db.macroXOffset, db.macroYOffset)
        end
    end
end

-- 색상 세팅
function ns:UpdateColor(btn)
    local db = ns.db
    if not db then return end
    local barPrefix = btn:GetName() and btn:GetName():gsub("%d+$", "") or ""

    if btn.HotKey and not db["hide_" .. barPrefix .. "_HotKey"] then
        local color = GetButtonColor(btn)
        btn.HotKey:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end

    if btn.Count and not db["hide_" .. barPrefix .. "_Count"] then
        if db.stackUseHotkeyColor then
            local color = GetButtonColor(btn)
            btn.Count:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        else
            local c = db.stackColor
            btn.Count:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        end
    end

    if btn.Name and not db["hide_" .. barPrefix .. "_Name"] then
        if db.macroUseHotkeyColor then
            local color = GetButtonColor(btn)
            btn.Name:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        else
            local c = db.macroColor
            btn.Name:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        end
    end
end

-- 완벽한 감시 카메라(훅) 설치
local hookedButtons = {}

function ns:InstallHooks(btn)
    if hookedButtons[btn] then return end
    hookedButtons[btn] = true

    local barPrefix = btn:GetName() and btn:GetName():gsub("%d+$", "") or ""

    if btn.HotKey then
        hooksecurefunc(btn.HotKey, "SetText", function(self, text)
            if self._atsUpdating then return end
            
            local parent = self:GetParent()
            -- 1. 무조건 데이터베이스 직거래 스캐너로 단축키 캐오기
            local trueKey = parent and GetTrueHotkey(parent) or ""
            
            -- 2. 스캐너가 실패하면 와우가 넘겨준 텍스트를 사용 (점 기호는 차단)
            if trueKey == "" and text and text ~= "" and text ~= RANGE_INDICATOR and text ~= "●" then
                trueKey = text
            end
            
            local newText = ""
            if trueKey ~= "" then
                newText = ns.db and GetShortenedText(trueKey) or trueKey
            end
            
            self._atsUpdating = true
            self:SetText(newText)
            self._atsUpdating = false
            
            if ns.db and not ns.db["hide_" .. barPrefix .. "_HotKey"] then
                self:Show()
            end
            
            -- 3. 와우가 글자를 쓰며 레이아웃을 부수면 0.001초 만에 즉시 복구!
            if parent and ns.db then
                pcall(ns.SetupLayout, ns, parent)
                pcall(ns.UpdateColor, ns, parent)
            end
        end)
        
        hooksecurefunc(btn.HotKey, "Hide", function(self)
            if ns.db and not ns.db["hide_" .. barPrefix .. "_HotKey"] then
                self:Show()
            end
        end)
    end

    local function stateHook(self) 
        if not ns.db then return end
        -- 레이아웃 초기화 완벽 방어막
        pcall(ns.SetupLayout, ns, self) 
        pcall(ns.UpdateColor, ns, self) 
        
        if self.HotKey and not ns.db["hide_" .. barPrefix .. "_HotKey"] then
            self.HotKey:Show()
        end
    end

    if btn.UpdateUsable then hooksecurefunc(btn, "UpdateUsable", stateHook) end
    if btn.UpdateRangeIndicator then hooksecurefunc(btn, "UpdateRangeIndicator", stateHook) end
    if btn.UpdateCount then hooksecurefunc(btn, "UpdateCount", stateHook) end
    if btn.Update then hooksecurefunc(btn, "Update", stateHook) end
    if btn.UpdateHotkeys then hooksecurefunc(btn, "UpdateHotkeys", stateHook) end 
end

-- 전체 업데이트 실행기 (위험한 강제 찌르기 영구 삭제!)
function ns:UpdateAllButtons()
    if not ns.db then return end 

    for _, barName in ipairs(ns.actionBars) do
        for i = 1, 12 do
            local btn = _G[barName..i]
            if btn then
                ns:InstallHooks(btn)
                
                if btn.HotKey then
                    local trueKey = GetTrueHotkey(btn)
                    if trueKey == "" then
                        local t = btn.HotKey:GetText()
                        if t and t ~= RANGE_INDICATOR and t ~= "●" then trueKey = t end
                    end
                    
                    local newText = (trueKey ~= "") and GetShortenedText(trueKey) or ""
                    
                    btn.HotKey._atsUpdating = true
                    btn.HotKey:SetText(newText)
                    btn.HotKey._atsUpdating = false
                    
                    local barPrefix = barName:gsub("%d+$", "")
                    if ns.db["hide_" .. barPrefix .. "_HotKey"] then
                        btn.HotKey:Hide()
                    else
                        btn.HotKey:Show()
                    end
                end
                
                ns:SetupLayout(btn)
                ns:UpdateColor(btn)
            end
        end
    end
end

-- 이벤트 핸들러
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
        
        -- 로딩 지연 방어 타이머 (강제 찌르기 없이 자체 텍스트만 안전하게 덮어쓰기)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(2.0, function()
                if ns.db then
                    ns:UpdateAllButtons()
                end
            end)
        end
    end
end)