local addonName, ns = ...
local L = ns.L -- [L10n]
local LSM = LibStub("LibSharedMedia-3.0", true)

ns.configCategories = {}
ns.optionWidgets = {} 

function ns:RefreshOptionsUI()
    for _, widget in ipairs(ns.optionWidgets) do
        if widget.LoadValue then widget:LoadValue() end
    end
end

StaticPopupDialogs["ATS_CONFIRM_RESET_PROFILE"] = {
    text = L["Reset Confirm Body"],
    button1 = L["Confirm"],
    button2 = L["Cancel"],
    OnAccept = function() ns:ResetProfile() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ATS_CONFIRM_DELETE_PROFILE"] = {
    text = L["Delete Confirm Body"],
    button1 = L["Confirm"],
    button2 = L["Cancel"],
    OnAccept = function() ns:DeleteProfile(ns.currentProfileName) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ATS_ALERT_DEFAULT_PROFILE"] = {
    text = L["Default Cannot Delete"],
    button1 = L["Confirm"],
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ATS_CONFIRM_CREATE_PROFILE"] = {
    text = L["Create Confirm Body"],
    button1 = L["Copy Settings"],
    button3 = L["Create Default"],
    button2 = L["Cancel"],
    OnAccept = function(self) ns:CreateProfile(ns.pendingProfileName, true) end,
    OnAlt = function(self) ns:CreateProfile(ns.pendingProfileName, false) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ATS_CONFIRM_COPY_PROFILE"] = {
    text = L["Copy Confirm Body"],
    button1 = L["Confirm"],
    button2 = L["Cancel"],
    OnAccept = function() ns:CopyProfileFrom(ns.pendingCopySource) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- [[ UI 헬퍼 함수들 ]] --
local function CreateSectionHeader(parent, text, x, y, resetCallback)
    local t = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    local font, _, outline = GameFontNormalLarge:GetFont()
    t:SetFont(font, 20, outline)
    t:SetPoint("TOPLEFT", x, y)
    t:SetText(text)

    if resetCallback then
        local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, y) 
        btn:SetText(L["Initialize"])
        btn:SetScript("OnClick", function() if resetCallback then resetCallback() end end)
    end
    
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", x, y - 30)
    line:SetPoint("RIGHT", -20, 0)
    return t
end

local function CreateCheckbox(parent, label, dbKey, x, y, callback)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    cb.LoadValue = function() cb:SetChecked(ns.db[dbKey]) end
    cb:LoadValue()
    cb:SetScript("OnClick", function(self)
        ns.db[dbKey] = self:GetChecked()
        ns:UpdateFontCache()
        ns:UpdateAllButtons()
        if callback then callback(self:GetChecked()) end
    end)
    table.insert(ns.optionWidgets, cb)
    return cb
end

local function CreateSlider(parent, label, dbKey, minVal, maxVal, x, y, width, callback)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(width or 180)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    if slider.Text then slider.Text:SetText(label) end
    if slider.Low then slider.Low:SetText("") end
    if slider.High then slider.High:SetText("") end
    local valueText = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    
    slider.LoadValue = function() 
        slider:SetValue(ns.db[dbKey]) 
        valueText:SetText(ns.db[dbKey])
    end
    slider:LoadValue()
    slider:SetScript("OnValueChanged", function(self, value)
        ns.db[dbKey] = value
        valueText:SetText(value)
        ns:UpdateFontCache()
        ns:UpdateAllButtons()
        if callback then callback() end
    end)
    table.insert(ns.optionWidgets, slider)
    return slider
end

local function CreatePosSlider(parent, label, dbKey, x, y)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(150)
    slider:SetMinMaxValues(-50, 50) 
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    
    if slider.Text then slider.Text:ClearAllPoints(); slider.Text:SetPoint("RIGHT", slider, "LEFT", -10, 0); slider.Text:SetText(label) end
    if slider.Low then slider.Low:SetText("") end
    if slider.High then slider.High:SetText("") end
    local val = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    val:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    slider.valueText = val
    slider.LoadValue = function() slider:SetValue(ns.db[dbKey]); val:SetText(ns.db[dbKey]) end
    slider:LoadValue()
    slider:SetScript("OnValueChanged", function(self, value)
        ns.db[dbKey] = value
        val:SetText(value)
        ns:UpdateAllButtons()
    end)
    table.insert(ns.optionWidgets, slider)
    return slider
end

local function CreateEditBox(parent, label, dbKey, width, x, y)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 30)
    eb:SetPoint("TOPLEFT", x, y)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb.dbKey = dbKey 
    
    eb.LoadValue = function() 
        local v = ns.db[dbKey]
        if v == nil then v = ns.defaults[dbKey] end
        eb:SetText(v)
        eb:SetCursorPosition(0) 
    end
    eb:LoadValue()
    
    eb:SetScript("OnTextChanged", function(self)
        local v = self:GetText()
        if v == "" and not ns.db.allowEmptyText then 
            v = ns.defaults[dbKey] 
        end
        ns.db[dbKey] = v
    end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:LoadValue() end)
    local lbl = eb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("BOTTOMLEFT", eb, "TOPLEFT", -5, 0)
    lbl:SetText(label)
    table.insert(ns.optionWidgets, eb)
    return eb
end

-- [ 통합 스타일 패널 생성 함수 ] --
local function BuildStylePanel(content, prefix, titleText)
    local p = prefix or ""
    
    local function GetKey(base)
        if p == "" then return base end
        return p .. base:gsub("^%l", string.upper)
    end
    
    local fontBtn, outlineCb, thickCb, sizeSl, alignBtn, previewText
    
    local function UpdatePreview()
        local fontPath = GameFontNormal:GetFont()
        local dbFont = ns.db[GetKey("fontName")]
        if LSM and dbFont ~= "Default" then
            fontPath = LSM:Fetch("font", dbFont) or fontPath
        end
        previewText:SetFont(fontPath, ns.db[GetKey("fontSize")], ns.db[GetKey("fontOutline")])
        
        if prefix == "stack" or prefix == "macro" then
            if ns.db[GetKey("useHotkeyColor")] then
                previewText:SetTextColor(1, 1, 1, 1)
            else
                local r, g, b, a = unpack(ns.db[GetKey("color")])
                previewText:SetTextColor(r, g, b, a)
            end
        end
    end
    table.insert(ns.optionWidgets, { LoadValue = UpdatePreview })

    local function ResetStyle()
        for k, v in pairs(ns.defaults) do
            if prefix == "" then
                if not k:find("^stack") and not k:find("^macro") and not k:find("^hide") and not k:find("^text") and k~="enableShorten" then ns.db[k] = v end
            else
                if k:find("^"..prefix) then ns.db[k] = v end
            end
        end
        ns:UpdateFontCache(); ns:RefreshOptionsUI(); ns:UpdateAllButtons()
        print("|cff00ff00[ATS]|r " .. L["Style Reset Msg"]:format(titleText))
    end

    CreateSectionHeader(content, titleText, 16, -16, ResetStyle)
    
    previewText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    previewText:SetText(prefix == "stack" and L["Preview Stack"] or (prefix == "macro" and L["Preview Macro"] or L["Preview Hotkey"]))
    
    local startY = -80
    fontBtn = CreateFrame("Button", nil, content, "UIMenuButtonStretchTemplate")
    fontBtn:SetPoint("TOPLEFT", 20, startY)
    fontBtn:SetSize(200, 30)
    local flbl = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    flbl:SetPoint("BOTTOMLEFT", fontBtn, "TOPLEFT", 0, 5)
    flbl:SetText(L["Font Select"])
    
    fontBtn.LoadValue = function() 
        local val = ns.db[GetKey("fontName")]
        if val == "Default" then val = L["Default Font"] end
        fontBtn:SetText(val) 
    end
    fontBtn:LoadValue()
    table.insert(ns.optionWidgets, fontBtn)

    fontBtn:SetScript("OnClick", function(self)
        if not MenuUtil then return end
        MenuUtil.CreateContextMenu(self, function(owner, root)
            root:CreateButton(L["Default Font"], function()
                ns.db[GetKey("fontName")] = "Default"
                self:SetText(L["Default Font"])
                ns:UpdateFontCache(); ns:UpdateAllButtons(); UpdatePreview()
            end)
            if LSM then
                local fonts = LSM:List("font"); table.sort(fonts)
                for _, f in ipairs(fonts) do
                    root:CreateButton(f, function()
                        ns.db[GetKey("fontName")] = f; self:SetText(f)
                        ns:UpdateFontCache(); ns:UpdateAllButtons(); UpdatePreview()
                    end)
                end
            end
        end)
    end)
    
    previewText:ClearAllPoints()
    previewText:SetPoint("RIGHT", content, "TOPRIGHT", -40, startY - 15)
    
    local row2Y = startY - 60
    sizeSl = CreateSlider(content, L["Font Size"], GetKey("fontSize"), 8, 32, 20, row2Y, 150, UpdatePreview)
    
    outlineCb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
    outlineCb:SetPoint("LEFT", sizeSl, "RIGHT", 20, 0)
    outlineCb.Text:SetText(L["Outline"])
    
    thickCb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
    thickCb:SetPoint("LEFT", outlineCb.Text, "RIGHT", 20, 0)
    thickCb.Text:SetText(L["Thick Outline"])
    
    local shadowCb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
    shadowCb:SetPoint("LEFT", thickCb.Text, "RIGHT", 20, 0)
    shadowCb.Text:SetText(L["Shadow"])
    
    local function RefreshOutline()
        local outline = ns.db[GetKey("fontOutline")]
        outlineCb:SetChecked(outline ~= "NONE")
        thickCb:SetChecked(outline == "THICKOUTLINE")
        if outline == "NONE" then thickCb:Disable(); thickCb.Text:SetTextColor(0.5, 0.5, 0.5) else thickCb:Enable(); thickCb.Text:SetTextColor(1, 1, 1) end
    end
    table.insert(ns.optionWidgets, { LoadValue = RefreshOutline })
    RefreshOutline()

    local function UpdateOutlineLogic()
        local isOutline = outlineCb:GetChecked()
        local isThick = thickCb:GetChecked()
        if not isOutline then ns.db[GetKey("fontOutline")] = "NONE" else if isThick then ns.db[GetKey("fontOutline")] = "THICKOUTLINE" else ns.db[GetKey("fontOutline")] = "OUTLINE" end end
        RefreshOutline(); ns:UpdateFontCache(); ns:UpdateAllButtons(); UpdatePreview()
    end
    outlineCb:SetScript("OnClick", UpdateOutlineLogic)
    thickCb:SetScript("OnClick", UpdateOutlineLogic)
    
    shadowCb.LoadValue = function() shadowCb:SetChecked(ns.db[GetKey("enableShadow")]) end
    shadowCb:LoadValue()
    shadowCb:SetScript("OnClick", function(self)
        ns.db[GetKey("enableShadow")] = self:GetChecked()
        ns:UpdateFontCache()
        ns:UpdateAllButtons()
    end)
    table.insert(ns.optionWidgets, shadowCb)

    local boxY = row2Y - 60
    local posBox = CreateFrame("Frame", nil, content)
    posBox:SetPoint("TOPLEFT", 20, boxY)
    posBox:SetSize(300, 160)
    local boxTitle = posBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    local font, _, outline = GameFontNormal:GetFont()
    boxTitle:SetFont(font, 15, outline)
    boxTitle:SetPoint("TOPLEFT", 5, -5) 
    boxTitle:SetText(L["Position"])
    local vLine = posBox:CreateTexture(nil, "ARTWORK")
    vLine:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    vLine:SetWidth(1)
    vLine:SetPoint("TOPLEFT", 270, -5) 
    vLine:SetPoint("BOTTOMLEFT", 270, 20)
    alignBtn = CreateFrame("Button", nil, posBox, "UIMenuButtonStretchTemplate")
    alignBtn:SetSize(150, 25)
    alignBtn:SetPoint("TOPLEFT", 60, -35)
    
    local alignMap = {
        ["TOPLEFT"]=L["TOPLEFT"], ["TOP"]=L["TOP"], ["TOPRIGHT"]=L["TOPRIGHT"],
        ["LEFT"]=L["LEFT"], ["CENTER"]=L["CENTER"], ["RIGHT"]=L["RIGHT"],
        ["BOTTOMLEFT"]=L["BOTTOMLEFT"], ["BOTTOM"]=L["BOTTOM"], ["BOTTOMRIGHT"]=L["BOTTOMRIGHT"]
    }
    if prefix == "" then alignMap["TOPRIGHT"] = L["TOPRIGHT"] .. L["Default"]
    elseif prefix == "stack" then alignMap["BOTTOMRIGHT"] = L["BOTTOMRIGHT"] .. L["Default"]
    elseif prefix == "macro" then alignMap["BOTTOMLEFT"] = L["BOTTOMLEFT"] .. L["Default"] end

    alignBtn.LoadValue = function() alignBtn:SetText(alignMap[ns.db[GetKey("textAlignment")]] or ns.db[GetKey("textAlignment")]) end
    table.insert(ns.optionWidgets, alignBtn)
    
    local alignOrder = {"TOPLEFT","TOP","TOPRIGHT","LEFT","CENTER","RIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT"}
    alignBtn:SetScript("OnClick", function(self)
        if not MenuUtil then return end
        MenuUtil.CreateContextMenu(self, function(owner, root)
            for _, key in ipairs(alignOrder) do
                root:CreateButton(alignMap[key], function() ns.db[GetKey("textAlignment")] = key; self:SetText(alignMap[key]); ns:UpdateAllButtons() end)
            end
        end)
    end)
    CreatePosSlider(posBox, L["X Offset"], GetKey("xOffset"), 60, -65)
    CreatePosSlider(posBox, L["Y Offset"], GetKey("yOffset"), 60, -95)
    
    local colorBox = CreateFrame("Frame", nil, content)
    colorBox:SetPoint("LEFT", posBox, "LEFT", 280, 0) 
    colorBox:SetSize(250, 160)
    local colorTitle = colorBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    colorTitle:SetFont(font, 15, outline)
    colorTitle:SetPoint("TOPLEFT", 10, -5)
    colorTitle:SetText(L["Text Color"])
    
    local function CreateColorPicker(label, dbKey, x, y)
        local f = CreateFrame("Button", nil, colorBox)
        f:SetSize(20, 20)
        f:SetPoint("TOPLEFT", x, y)
        f.tex = f:CreateTexture(nil, "OVERLAY")
        f.tex:SetAllPoints()
        f:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
        local lbl = colorBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        lbl:SetPoint("LEFT", f, "RIGHT", 10, 0)
        lbl:SetText(label)
        f.label = lbl
        f.LoadValue = function() 
            local c = ns.db[dbKey]
            f.tex:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
            if prefix ~= "" then
                local useKey = GetKey("useHotkeyColor")
                if ns.db[useKey] then f:Disable(); f:SetAlpha(0.5); f.label:SetTextColor(0.5,0.5,0.5) 
                else f:Enable(); f:SetAlpha(1); f.label:SetTextColor(1,1,1) end
            end
        end
        table.insert(ns.optionWidgets, f)
        f:SetScript("OnClick", function()
            if not f:IsEnabled() then return end
            local r, g, b, a = unpack(ns.db[dbKey])
            if not a then a = 1 end
            local info = {
                r = r, g = g, b = b, opacity = a, hasOpacity = true,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = ColorPickerFrame:GetColorAlpha()
                    ns.db[dbKey] = {nr, ng, nb, na}
                    f.tex:SetColorTexture(nr, ng, nb, na)
                    ns:UpdateAllButtons(); UpdatePreview()
                end,
                opacityFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    local na = ColorPickerFrame:GetColorAlpha()
                    ns.db[dbKey] = {nr, ng, nb, na}
                    f.tex:SetColorTexture(nr, ng, nb, na)
                    ns:UpdateAllButtons(); UpdatePreview()
                end,
                cancelFunc = function()
                    ns.db[dbKey] = {r, g, b, a}
                    f.tex:SetColorTexture(r, g, b, a)
                    ns:UpdateAllButtons(); UpdatePreview()
                end,
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)
        return f
    end

    if prefix == "" then
        CreateColorPicker(L["Color Normal"], "colorNormal", 20, -35)
        CreateColorPicker(L["Color OOR"], "colorRange", 140, -35)
        CreateColorPicker(L["Color No Mana"], "colorMana", 20, -65)
        CreateColorPicker(L["Color Unusable"], "colorUnusable", 140, -65)
    else
        CreateColorPicker(L["Color Normal"], GetKey("color"), 20, -35)
        CreateCheckbox(colorBox, L["Use Hotkey Color"], GetKey("useHotkeyColor"), 20, -65, function(checked)
            ns:RefreshOptionsUI(); UpdatePreview()
        end)
    end
end

function ns:RegisterConfig()
    if ns.configCategories["Main"] then return end

    local mainPanel = CreateFrame("Frame", "ATS_MainPanel", UIParent)
    mainPanel.name = "ActionBar Text Styler"

    local logo = mainPanel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(64, 64)
    logo:SetPoint("TOP", 0, -60)
    logo:SetTexture("Interface\\AddOns\\ActionBarTextStyler\\assets\\logo.tga")

    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    local font, _, outline = GameFontNormalHuge:GetFont()
    title:SetFont(font, 36, outline) 
    title:SetPoint("TOP", logo, "BOTTOM", 0, -20)
    title:SetText("ActionBar Text Styler")
    title:SetTextColor(1, 0.9, 0)

    local getVersion = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local versionStr = getVersion(addonName, "Version") or "1.0.0"
    local version = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    version:SetPoint("TOP", title, "BOTTOM", 0, -10)
    version:SetText("Ver " .. versionStr)

    local desc1 = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    desc1:SetPoint("TOP", version, "BOTTOM", 0, -50)
    desc1:SetText(L["AddOn Description"])

    local desc2 = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    desc2:SetPoint("TOP", desc1, "BOTTOM", 0, -20)
    desc2:SetText(L["Select Menu Instruction"])

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
        Settings.RegisterAddOnCategory(category)
        ns.configCategories["Main"] = category
    else
        InterfaceOptions_AddCategory(mainPanel)
        ns.configCategories["Main"] = mainPanel
    end

    -- =========================================
    -- [1] 프로필 관리
    -- =========================================
    local profilePanel = CreateFrame("Frame", "ATS_ProfilePanel", UIParent)
    profilePanel.name = L["Profile Management"]
    profilePanel.parent = "ActionBar Text Styler"
    local function InitProfilePanel()
        local content = profilePanel
        
        profilePanel:SetScript("OnShow", function()
            ns:RefreshOptionsUI()
        end)

        CreateSectionHeader(content, L["Profile Management"], 16, -16, nil)
        local sub = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        sub:SetPoint("TOPLEFT", 16, -55)
        sub:SetText(L["Profile Desc"])
        local currentLbl = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        currentLbl:SetPoint("TOPLEFT", 16, -90)
        
        local function UpdateCurrentLabel()
            currentLbl:SetText(L["Current Profile"]:format("|cff00ff00" .. (ns.currentProfileName or "Default") .. "|r"))
            if ns.currentProfileName == "Default" then ns.profileDelBtn:Disable(); ns.profileDelNote:Show()
            else ns.profileDelBtn:Enable(); ns.profileDelNote:Hide() end
        end
        
        local dropBtn = CreateFrame("Button", nil, content, "UIMenuButtonStretchTemplate")
        dropBtn:SetSize(200, 25)
        dropBtn:SetPoint("TOPLEFT", 16, -115)
        dropBtn:SetText(L["Select Profile"])
        dropBtn:SetScript("OnClick", function(self)
            if not MenuUtil then return end
            MenuUtil.CreateContextMenu(self, function(owner, root)
                for name, _ in pairs(ActionBarTextStylerDB.profiles) do
                    root:CreateButton(name, function() ns:SetProfile(name); UpdateCurrentLabel() end)
                end
            end)
        end)
        
        local yPos = -160
        local subTitle = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        local sFont, _, sOutline = GameFontNormal:GetFont()
        subTitle:SetFont(sFont, 15, sOutline)
        subTitle:SetPoint("TOPLEFT", 16, yPos)
        subTitle:SetText(L["Create New Profile"])
        local subLine = content:CreateTexture(nil, "ARTWORK")
        subLine:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        subLine:SetHeight(1)
        subLine:SetPoint("TOPLEFT", 16, yPos - 20)
        subLine:SetPoint("RIGHT", -30, 0)
        yPos = yPos - 40
        
        local easyLbl = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        easyLbl:SetPoint("TOPLEFT", 20, yPos - 5)
        easyLbl:SetText(L["Easy Profile Create"])
        local charProfileName = UnitName("player") .. " - " .. GetRealmName()
        local easyBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        easyBtn:SetPoint("LEFT", easyLbl, "RIGHT", 20, 0)
        easyBtn:SetHeight(22)
        local btnText = L["Create Profile Format"]:format(charProfileName)
        easyBtn:SetText(btnText)
        easyBtn:SetWidth(easyBtn:GetFontString():GetStringWidth() + 30)
        easyBtn:SetScript("OnClick", function() ns.pendingProfileName = charProfileName; StaticPopup_Show("ATS_CONFIRM_CREATE_PROFILE", charProfileName) end)
        
        yPos = yPos - 40
        local customLbl = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        customLbl:SetPoint("TOPLEFT", 20, yPos - 5)
        customLbl:SetText(L["Custom Profile Create"])
        local newEdit = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        newEdit:SetSize(150, 30)
        newEdit:SetPoint("LEFT", customLbl, "RIGHT", 15, 0)
        newEdit:SetAutoFocus(false)
        local newBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        newBtn:SetSize(60, 22)
        newBtn:SetPoint("LEFT", newEdit, "RIGHT", 5, 0)
        newBtn:SetText(L["Create"])
        newBtn:SetScript("OnClick", function()
            local name = newEdit:GetText()
            if name and name ~= "" then
                ns.pendingProfileName = name
                StaticPopup_Show("ATS_CONFIRM_CREATE_PROFILE", name)
                newEdit:SetText(""); newEdit:ClearFocus()
            end
        end)
        
        yPos = yPos - 55
        local subTitle2 = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        subTitle2:SetFont(sFont, 15, sOutline)
        subTitle2:SetPoint("TOPLEFT", 16, yPos)
        subTitle2:SetText(L["Copy Profile"])
        local subLine2 = content:CreateTexture(nil, "ARTWORK")
        subLine2:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        subLine2:SetHeight(1)
        subLine2:SetPoint("TOPLEFT", 16, yPos - 20)
        subLine2:SetPoint("RIGHT", -30, 0)
        yPos = yPos - 35
        local copySourceBtn = CreateFrame("Button", nil, content, "UIMenuButtonStretchTemplate")
        copySourceBtn:SetSize(180, 25)
        copySourceBtn:SetPoint("TOPLEFT", 20, yPos)
        copySourceBtn:SetText(L["Select Profile To Copy"])
        ns.pendingCopySource = nil
        copySourceBtn:SetScript("OnClick", function(self)
            if not MenuUtil then return end
            MenuUtil.CreateContextMenu(self, function(owner, root)
                for name, _ in pairs(ActionBarTextStylerDB.profiles) do
                    if name ~= ns.currentProfileName then
                        root:CreateButton(name, function() ns.pendingCopySource = name; self:SetText(name) end)
                    end
                end
            end)
        end)
        local copyBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        copyBtn:SetSize(160, 22)
        copyBtn:SetPoint("LEFT", copySourceBtn, "RIGHT", 10, 0)
        copyBtn:SetText(L["Copy From Selected"])
        copyBtn:SetScript("OnClick", function()
            if ns.pendingCopySource then StaticPopup_Show("ATS_CONFIRM_COPY_PROFILE", ns.pendingCopySource)
            else print("|cffff0000[ATS]|r " .. L["Select Source First"]) end
        end)
        
        yPos = yPos - 60
        local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        resetBtn:SetPoint("TOPLEFT", 16, yPos)
        resetBtn:SetHeight(22)
        resetBtn:SetText(L["Reset Current Profile"])
        resetBtn:SetWidth(resetBtn:GetFontString():GetStringWidth() + 30)
        resetBtn:SetScript("OnClick", function() StaticPopup_Show("ATS_CONFIRM_RESET_PROFILE") end)
        
        local delBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        delBtn:SetPoint("LEFT", resetBtn, "RIGHT", 20, 0)
        delBtn:SetHeight(22)
        delBtn:SetText(L["Delete Current Profile"])
        delBtn:SetWidth(delBtn:GetFontString():GetStringWidth() + 30)
        ns.profileDelBtn = delBtn
        delBtn:SetScript("OnClick", function()
            if ns.currentProfileName == "Default" then return end
            StaticPopup_Show("ATS_CONFIRM_DELETE_PROFILE")
        end)
        
        local delNote = content:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
        delNote:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -10)
        delNote:SetText(L["Default Cannot Delete"])
        ns.profileDelNote = delNote
        
        table.insert(ns.optionWidgets, { LoadValue = UpdateCurrentLabel })
        table.insert(ns.optionWidgets, { LoadValue = function() copySourceBtn:SetText(L["Select Profile To Copy"]); ns.pendingCopySource = nil end })
    end
    InitProfilePanel()
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        local sub = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], profilePanel, profilePanel.name)
        ns.configCategories["Profile"] = sub
    else InterfaceOptions_AddCategory(profilePanel) end

    -- =========================================
    -- [2]~[5] 스타일 패널들
    -- =========================================
    local stylePanel = CreateFrame("Frame", "ATS_StylePanel", UIParent)
    stylePanel.name = L["Hotkey Style"]
    stylePanel.parent = "ActionBar Text Styler"
    BuildStylePanel(stylePanel, "", L["Hotkey Style"])
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        ns.configCategories["Style"] = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], stylePanel, stylePanel.name)
    else InterfaceOptions_AddCategory(stylePanel) end

    local textPanel = CreateFrame("Frame", "ATS_TextPanel", UIParent)
    textPanel.name = L["Text Replace"]
    textPanel.parent = "ActionBar Text Styler"
    
    local function InitTextPanel()
        local footerHeight = 40
        
        local reloadBtn = CreateFrame("Button", nil, textPanel, "UIPanelButtonTemplate")
        reloadBtn:SetSize(100, 25)
        reloadBtn:SetPoint("BOTTOMRIGHT", -15, 10)
        reloadBtn:SetText(L["Reload UI"])
        reloadBtn:SetScript("OnClick", ReloadUI)

        local applyBtn = CreateFrame("Button", nil, textPanel, "UIPanelButtonTemplate")
        applyBtn:SetSize(100, 25)
        applyBtn:SetPoint("RIGHT", reloadBtn, "LEFT", -10, 0)
        applyBtn:SetText(L["Apply Settings"])
        applyBtn:SetScript("OnClick", function() ns:UpdateAllButtons(); print("|cff00ff00[ActionBar Text Styler]|r " .. L["Text Replace Msg"]) end)

        local note = textPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("LEFT", textPanel, "BOTTOMLEFT", 15, 22)
        note:SetText(L["Text Replace Note"])

        local footerLine = textPanel:CreateTexture(nil, "ARTWORK")
        footerLine:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        footerLine:SetHeight(1)
        footerLine:SetPoint("BOTTOMLEFT", 10, footerHeight + 5)
        footerLine:SetPoint("BOTTOMRIGHT", -10, footerHeight + 5)

        local scrollFrame = CreateFrame("ScrollFrame", nil, textPanel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -10)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, footerHeight + 10)
        
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(600, 1000)
        scrollFrame:SetScrollChild(content)
        
        local function ResetText()
            for k in pairs(ns.defaults) do if k:find("text") or k == "enableShorten" or k == "allowEmptyText" then ns.db[k] = ns.defaults[k] end end
            ns:RefreshOptionsUI(); print("|cff00ff00[ATS]|r " .. L["Text Replace Msg"])
        end
        CreateSectionHeader(content, L["Text Replace"], 10, -10, ResetText)
        
        local yPos = -60 
        CreateCheckbox(content, L["Enable Text Replace"], "enableShorten", 20, yPos)
        
        local allowEmptyCb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
        allowEmptyCb:SetPoint("TOPLEFT", 220, yPos)
        allowEmptyCb.Text:SetText(L["Allow Empty Text"])
        allowEmptyCb.LoadValue = function() allowEmptyCb:SetChecked(ns.db.allowEmptyText) end
        allowEmptyCb:LoadValue()
        allowEmptyCb:SetScript("OnClick", function(self)
            ns.db.allowEmptyText = self:GetChecked()
            if not ns.db.allowEmptyText then
                for k, _ in pairs(ns.defaults) do
                    if k:find("text") and ns.db[k] == "" then
                        ns.db[k] = ns.defaults[k]
                    end
                end
            end
            ns:UpdateAllButtons()
            ns:RefreshOptionsUI()
        end)
        table.insert(ns.optionWidgets, allowEmptyCb)

        local infoIconFrame = CreateFrame("Frame", nil, content)
        infoIconFrame:SetSize(18, 18)
        infoIconFrame:SetPoint("LEFT", allowEmptyCb.Text, "RIGHT", 10, 0)
        
        local infoTex = infoIconFrame:CreateTexture(nil, "ARTWORK")
        infoTex:SetTexture("Interface\\common\\help-i")
        infoTex:SetAllPoints()
        infoTex:SetAlpha(0.6) 
        
        infoIconFrame:SetScript("OnEnter", function(self)
            infoTex:SetAlpha(1.0)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Allow Empty Tooltip"], 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        infoIconFrame:SetScript("OnLeave", function(self)
            infoTex:SetAlpha(0.6)
            GameTooltip_Hide()
        end)

        yPos = yPos - 50
        
        local function CreateCategoryBlock(title, itemsTable)
            local t = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            local font, _, outline = GameFontNormal:GetFont()
            t:SetFont(font, 15, outline)
            t:SetPoint("TOPLEFT", 15, yPos)
            t:SetText(title)
            local l = content:CreateTexture(nil, "ARTWORK")
            l:SetColorTexture(0.5, 0.5, 0.5, 0.5)
            l:SetHeight(1)
            l:SetPoint("TOPLEFT", 15, yPos - 20)
            l:SetPoint("RIGHT", -30, 0)
            yPos = yPos - 45
            local startX, colGap, rowGap = 20, 110, 50
            local colCount = 0
            for _, item in ipairs(itemsTable) do
                CreateEditBox(content, item[1], item[2], 80, startX + (colCount * colGap), yPos)
                colCount = colCount + 1
                if colCount >= 5 then colCount = 0; yPos = yPos - rowGap end
            end
            if colCount > 0 then yPos = yPos - rowGap end
            yPos = yPos - 10
        end
        
        local catModifiers = { { "Shift", "textShift" }, { "Ctrl", "textCtrl" }, { "Alt", "textAlt" } }
        CreateCategoryBlock(L["Modifiers"], catModifiers)
        
        local catMouse = { 
            { L["Mouse Wheel Up"], "textMouseWheelUp" }, 
            { L["Mouse Wheel Down"], "textMouseWheelDown" }, 
            { L["Mouse 3"], "textMiddleMouse" }, 
            { L["Mouse 4"], "textButton4" }, 
            { L["Mouse 5"], "textButton5" }, 
            { L["Mouse 6"], "textButton6" }, 
            { L["Mouse 7"], "textButton7" }, 
            { L["Mouse 8"], "textButton8" }, 
            { L["Mouse 9"], "textButton9" } 
        }
        CreateCategoryBlock(L["Mouse"], catMouse)
        
        -- [방향키 카테고리 복구 완료]
        local catArrow = { { L["Up Arrow"], "textUpArrow" }, { L["Down Arrow"], "textDownArrow" }, { L["Left Arrow"], "textLeftArrow" }, { L["Right Arrow"], "textRightArrow" } }
        CreateCategoryBlock(L["Arrow Keys"], catArrow)

        local catFunc = { { "Space", "textSpace" }, { "Backspace", "textBackspace" }, { "Tab", "textTab" }, { "Enter", "textEnter" }, { "Caps Lock", "textCapslock" }, { "Insert", "textInsert" }, { "Delete", "textDelete" }, { "Home", "textHome" }, { "End", "textEnd" }, { "Page Up", "textPageUp" }, { "Page Down", "textPageDown" } }
        CreateCategoryBlock(L["Function Keys"], catFunc)
        
        local catKeypad = { { "Num Lock", "textNumLock" }, { "Num 0", "textNumPad0" }, { "Num 1", "textNumPad1" }, { "Num 2", "textNumPad2" }, { "Num 3", "textNumPad3" }, { "Num 4", "textNumPad4" }, { "Num 5", "textNumPad5" }, { "Num 6", "textNumPad6" }, { "Num 7", "textNumPad7" }, { "Num 8", "textNumPad8" }, { "Num 9", "textNumPad9" } }
        CreateCategoryBlock(L["Keypad"], catKeypad)
        
        content:SetHeight(math.abs(yPos) + 20)
    end
    InitTextPanel()
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        ns.configCategories["Text"] = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], textPanel, textPanel.name)
    else InterfaceOptions_AddCategory(textPanel) end

    local stackPanel = CreateFrame("Frame", "ATS_StackPanel", UIParent)
    stackPanel.name = L["Stack Style"]
    stackPanel.parent = "ActionBar Text Styler"
    BuildStylePanel(stackPanel, "stack", L["Stack Style"])
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        ns.configCategories["Stack"] = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], stackPanel, stackPanel.name)
    else InterfaceOptions_AddCategory(stackPanel) end

    local macroPanel = CreateFrame("Frame", "ATS_MacroPanel", UIParent)
    macroPanel.name = L["Macro Style"]
    macroPanel.parent = "ActionBar Text Styler"
    BuildStylePanel(macroPanel, "macro", L["Macro Style"])
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        ns.configCategories["Macro"] = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], macroPanel, macroPanel.name)
    else InterfaceOptions_AddCategory(macroPanel) end

    -- =========================================
    -- [6] 텍스트 숨기기
    -- =========================================
    local hidePanel = CreateFrame("Frame", "ATS_HidePanel", UIParent)
    hidePanel.name = L["Hide Text"]
    hidePanel.parent = "ActionBar Text Styler"
    
    local function InitHidePanel()
        local content = hidePanel 
        local hideCheckboxes = {}
        local function ResetHide()
            for _, barName in ipairs(ns.actionBars) do
                ns.db["hide_"..barName.."_HotKey"] = false
                ns.db["hide_"..barName.."_Count"] = false
                ns.db["hide_"..barName.."_Name"] = false
            end
            ns:RefreshOptionsUI(); ns:UpdateAllButtons()
            print("|cff00ff00[ATS]|r " .. L["Hide Reset Msg"])
        end
        CreateSectionHeader(content, L["Hide Text"], 10, -10, ResetHide)
        
        local yPos = -60
        local h1 = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h1:SetPoint("TOPLEFT", 155, yPos); h1:SetText(L["Hotkey"])
        local h2 = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h2:SetPoint("TOPLEFT", 255, yPos); h2:SetText(L["Stack"])
        local h3 = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        h3:SetPoint("TOPLEFT", 355, yPos); h3:SetText(L["Macro"])
        
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", 20, yPos - 20)
        line:SetPoint("RIGHT", -30, 0)
        yPos = yPos - 35

        for _, barName in ipairs(ns.actionBars) do
            local label = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("TOPLEFT", 20, yPos - 7)
            label:SetText(ns.barNames[barName] or barName)
            
            local function MakeCB(typeSuffix, x)
                local dbKey = "hide_" .. barName .. "_" .. typeSuffix
                local cb = CreateFrame("CheckButton", nil, content, "InterfaceOptionsCheckButtonTemplate")
                cb:SetPoint("TOPLEFT", x, yPos)
                cb.Text:SetText("")
                cb.LoadValue = function() cb:SetChecked(ns.db[dbKey]) end
                cb:LoadValue()
                cb:SetScript("OnClick", function(self) ns.db[dbKey] = self:GetChecked(); ns:UpdateAllButtons() end)
                table.insert(ns.optionWidgets, cb)
                return cb
            end
            MakeCB("HotKey", 150); MakeCB("Count", 250); MakeCB("Name", 350)
            yPos = yPos - 30
        end
    end
    InitHidePanel()
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        ns.configCategories["Hide"] = Settings.RegisterCanvasLayoutSubcategory(ns.configCategories["Main"], hidePanel, hidePanel.name)
    else InterfaceOptions_AddCategory(hidePanel) end
end