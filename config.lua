local addonName, ns = ...
local L = ns.L -- [L10n]
local locale = GetLocale() -- 클라이언트 언어 확인

-- [[ 1. 기본 설정값 (Defaults) ]] --
ns.defaults = {
    -- [단축키 스타일]
    fontName = "Default", fontSize = 16, fontOutline = "OUTLINE",
    textAlignment = "TOPRIGHT", xOffset = -2, yOffset = -2,
    enableShadow = true,
    
    -- [단축키 색상]
    colorNormal = {1, 1, 1, 1},
    colorRange = {0.8, 0.1, 0.1, 1},
    colorMana = {0.5, 0.5, 1.0, 1},
    colorUnusable = {0.5, 0.5, 0.5, 1},

    -- [스택 스타일]
    stackFontName = "Default", stackFontSize = 16, stackFontOutline = "OUTLINE",
    stackTextAlignment = "BOTTOMRIGHT", stackXOffset = -2, stackYOffset = 2,
    stackEnableShadow = true, stackColor = {1, 1, 1, 1}, stackUseHotkeyColor = false,

    -- [매크로 스타일]
    macroFontName = "Default", macroFontSize = 12, macroFontOutline = "OUTLINE",
    macroTextAlignment = "BOTTOMLEFT", macroXOffset = 2, macroYOffset = 2,
    macroEnableShadow = true, macroColor = {1, 1, 1, 1}, macroUseHotkeyColor = false,

    -- [텍스트 변경]
    enableShorten = true,
    allowEmptyText = false,
    textShift = "s", textAlt = "a", textCtrl = "c",
    
    -- [방향키 추가 복구 완료]
    textUpArrow = (locale == "koKR") and "▲" or "UA",
    textDownArrow = (locale == "koKR") and "▼" or "DA",
    textLeftArrow = (locale == "koKR") and "◀" or "LA",
    textRightArrow = (locale == "koKR") and "▶" or "RA",
    
    -- [다국어 지원]
    textMouseWheelUp = (locale == "koKR") and "M▲" or "MU",
    textMouseWheelDown = (locale == "koKR") and "M▼" or "MD",
    textPageUp = (locale == "koKR") and "P▲" or "PU",
    textPageDown = (locale == "koKR") and "P▼" or "PD",
    
    textMiddleMouse = "M3",
    textButton4 = "M4", textButton5 = "M5",
    textButton6 = "M6", textButton7 = "M7", textButton8 = "M8", textButton9 = "M9",
    textCapslock = "CL", textNumLock = "NL",
    textInsert = "Ins", textHome = "Hm", textEnd = "End",
    textDelete = "Del",
    textSpace = "Sp", textTab = "Tab", textBackspace = "BS", textEnter = "Ent",
    textNumPad0 = "N0", textNumPad1 = "N1", textNumPad2 = "N2", textNumPad3 = "N3",
    textNumPad4 = "N4", textNumPad5 = "N5", textNumPad6 = "N6", textNumPad7 = "N7",
    textNumPad8 = "N8", textNumPad9 = "N9",
}

-- [숨기기 기본값 자동 생성]
for _, bar in ipairs({
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button", "PetActionButton"
}) do
    ns.defaults["hide_"..bar.."_HotKey"] = false
    ns.defaults["hide_"..bar.."_Count"] = false
    ns.defaults["hide_"..bar.."_Name"] = false
end

-- [[ 2. 액션바 목록 ]] --
ns.actionBars = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button", "PetActionButton"
}

-- [[ 3. 바 이름 매핑 ]] --
ns.barNames = {
    ["ActionButton"] = L["Bar 1"],
    ["MultiBarBottomLeftButton"] = L["Bar 2"],
    ["MultiBarBottomRightButton"] = L["Bar 3"],
    ["MultiBarRightButton"] = L["Bar 4"],
    ["MultiBarLeftButton"] = L["Bar 5"],
    ["MultiBar5Button"] = L["Bar 6"],
    ["MultiBar6Button"] = L["Bar 7"],
    ["MultiBar7Button"] = L["Bar 8"],
    ["PetActionButton"] = L["Pet Bar"],
}

-- [[ 4. 키 매핑 데이터 ]] --
ns.keyMap = {
    { "KEY_UP", "textUpArrow" }, { "KEY_DOWN", "textDownArrow" },
    { "KEY_LEFT", "textLeftArrow" }, { "KEY_RIGHT", "textRightArrow" },
    { "KEY_MOUSEWHEELUP", "textMouseWheelUp" }, { "KEY_MOUSEWHEELDOWN", "textMouseWheelDown" },
    { "KEY_BUTTON3", "textMiddleMouse" }, { "KEY_MIDDLEMOUSE", "textMiddleMouse" },
    { "KEY_BUTTON4", "textButton4" }, { "KEY_BUTTON5", "textButton5" },
    { "KEY_BUTTON6", "textButton6" }, { "KEY_BUTTON7", "textButton7" },
    { "KEY_BUTTON8", "textButton8" }, { "KEY_BUTTON9", "textButton9" },
    { "KEY_SPACE", "textSpace" }, { "KEY_DELETE", "textDelete" },
    { "KEY_INSERT", "textInsert" }, { "KEY_HOME", "textHome" }, { "KEY_END", "textEnd" },
    { "KEY_PAGEUP", "textPageUp" }, { "KEY_PAGEDOWN", "textPageDown" },
    { "KEY_CAPSLOCK", "textCapslock" }, { "KEY_NUMLOCK", "textNumLock" }, 
    { "KEY_TAB", "textTab" }, { "KEY_BACKSPACE", "textBackspace" }, { "KEY_ENTER", "textEnter" },
    { "KEY_NUMPAD0", "textNumPad0" }, { "KEY_NUMPAD1", "textNumPad1" }, { "KEY_NUMPAD2", "textNumPad2" },
    { "KEY_NUMPAD3", "textNumPad3" }, { "KEY_NUMPAD4", "textNumPad4" }, { "KEY_NUMPAD5", "textNumPad5" },
    { "KEY_NUMPAD6", "textNumPad6" }, { "KEY_NUMPAD7", "textNumPad7" }, { "KEY_NUMPAD8", "textNumPad8" },
    { "KEY_NUMPAD9", "textNumPad9" },
    
    -- Hardcoded safety (예외 문자열 처리 - 방향키 추가 복구 완료)
    { "Caps Lock", "textCapslock" }, { "Capslock", "textCapslock" },
    { "Mouse Wheel Up", "textMouseWheelUp" }, { "MouseWheelUp", "textMouseWheelUp" },
    { "Mouse Wheel Down", "textMouseWheelDown" }, { "MouseWheelDown", "textMouseWheelDown" },
    { "Middle Mouse", "textMiddleMouse" }, { "Button 3", "textMiddleMouse" },
    { "Button 4", "textButton4" }, { "Button 5", "textButton5" },
    { "Spacebar", "textSpace" }, { "Space", "textSpace" },
    { "Delete", "textDelete" }, { "Del", "textDelete" },
    { "Page Up", "textPageUp" }, { "Page Down", "textPageDown" },
    { "Up Arrow", "textUpArrow" }, { "Down Arrow", "textDownArrow" }, 
    { "Left Arrow", "textLeftArrow" }, { "Right Arrow", "textRightArrow" },
    { "위쪽 화살표", "textUpArrow" }, { "아래쪽 화살표", "textDownArrow" }, 
    { "왼쪽 화살표", "textLeftArrow" }, { "오른쪽 화살표", "textRightArrow" },
}