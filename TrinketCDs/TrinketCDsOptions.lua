local ADDON_NAME = "TrinketCDs"
local ADDON = _G[ADDON_NAME]
local SETTINGS = ADDON['SETTINGS']
local FRAMES = ADDON['FRAMES']

local SLIDERS_ORDER = {"ICON_SIZE", "POS_X", "POS_Y", "SPACING", "ZOOM", "BORDER_MARGIN", "EDGE_SIZE"}
local SLIDERS = {
    ICON_SIZE = {
        label = "Change icon size",
        min = 20, max = 50,
    },
    POS_X = {
        label = "Change icon X",
        min = -2000, max = 2000,
    },
    POS_Y = {
        label = "Change icon Y",
        min = -2000, max = 2000,
    },
    SPACING = {
        label = "Change icon spacing",
        min = 0, max = 20,
    },
    ZOOM = {
        label = "Change icon zoom",
        min = -200, max = 200, step = 5,
    },
    BORDER_MARGIN = {
        label = "Change border margin",
        min = -5, max = 5,
    },
    EDGE_SIZE = {
        label = "Change border edge",
        min = 1, max = 20,
    },
}

local RedrawAll = function()
    for _, frame in pairs(FRAMES) do
        frame:RedrawFrame()
    end
end

local toggleTrinket = function(self)
    local itemFrame = FRAMES[self.id]
    local checked = self:GetChecked()
    SETTINGS[itemFrame.nameID] = checked
    if checked then
        itemFrame:Show()
    else
        itemFrame:Hide()
    end
end

function ADDON:newCheckBox(id)
    local name = ADDON_NAME .. "CheckBox" .. id
    local cb = CreateFrame("CheckButton", name, self.OPTIONS.childFrame, "InterfaceOptionsCheckButtonTemplate")
    cb:SetChecked(SETTINGS["TRINKET"..id])
    cb.text = _G[name.."Text"]
    cb.text:SetText("Show trinket "..id)
    cb.id = id
    cb:SetScript("OnClick", toggleTrinket)
    return cb
end

function ADDON:newSlider(option_name)
    local data = SLIDERS[option_name]
    local id = ADDON_NAME .. "Slider" .. option_name
    local slider = CreateFrame("Slider", id, self.OPTIONS.childFrame, "OptionsSliderTemplate")

    slider:SetSize(200, 15)
    slider:SetMinMaxValues(data.min, data.max)
    slider:SetValueStep(data.step or 1)
    slider:SetValue(SETTINGS[option_name])

    slider.InfoText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.InfoText:SetPoint("TOP", slider, 0, 20)
    slider.InfoText:SetSize(200, 20)
	slider.InfoText:SetJustifyH("CENTER")
    slider.InfoText:SetText(data.label)

    slider.EditBox = CreateFrame("EditBox", id.."EditBox", slider, "InputBoxTemplate")
	slider.EditBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
	slider.EditBox:SetSize(50, 20)
    slider.EditBox:SetMaxLetters(5)
    slider.EditBox:SetJustifyH("RIGHT")
    slider.EditBox:SetMultiLine(false)
    slider.EditBox:SetAutoFocus(false)
    slider.EditBox:ClearFocus()
    slider.EditBox:SetText(SETTINGS[option_name])

    slider.EditBox:SetScript("OnEscapePressed", function(f)
        f:ClearFocus()
    end)

    slider.EditBox:SetScript("OnEnterPressed", function(f)
        local value = f:GetText()
        if tonumber(value) then
            slider:SetValue(value)
            f:ClearFocus()
        else
            f:SetText(SETTINGS[option_name])
        end
    end)

    slider:SetScript("OnValueChanged", function(f, value)
        SETTINGS[option_name] = value
        f.EditBox:SetText(value)
        RedrawAll()
    end)

    return slider
end

ADDON.OPTIONS = CreateFrame("Frame")
ADDON.OPTIONS.name = ADDON_NAME

ADDON.OPTIONS.childFrame = CreateFrame("Frame", nil, ADDON.OPTIONS)
ADDON.OPTIONS.childFrame:SetPoint("TOPLEFT", 15, -15)
ADDON.OPTIONS.childFrame:SetPoint("BOTTOMRIGHT", -15, 15)
ADDON.OPTIONS.childFrame:Hide()

ADDON.OPTIONS:SetScript("OnShow", function()
    ADDON.OPTIONS.childFrame:Show()
end)
ADDON.OPTIONS:SetScript("OnHide", function()
    ADDON.OPTIONS.childFrame:Hide()
end)

local title = ADDON.OPTIONS.childFrame:CreateFontString(nil, nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT", ADDON.OPTIONS.childFrame)
title:SetText(ADDON_NAME)

local t13toggle = ADDON:newCheckBox(13)
t13toggle:SetPoint("TOPLEFT", 0, -30)

local t14toggle = ADDON:newCheckBox(14)
t14toggle:SetPoint("TOPLEFT", 0, -60)

for row, option_name in pairs(SLIDERS_ORDER) do
    local slider = ADDON:newSlider(option_name)
    slider:SetPoint("TOPLEFT", 0, -100 - row * 35)
end

InterfaceOptions_AddCategory(ADDON.OPTIONS)
