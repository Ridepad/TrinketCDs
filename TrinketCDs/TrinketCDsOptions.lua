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
        min = -500, max = 500,
    },
    ZOOM = {
        label = "Change icon zoom %",
        min = -200, max = 200, step = 5,
    },
    BORDER_MARGIN = {
        label = "Change border margin",
        min = -5, max = 5,
    },
    EDGE_SIZE = {
        label = "Change border edge",
        min = 1, max = 30,
    },
}

local optionsFrame = CreateFrame("Frame")
ADDON.OPTIONS = optionsFrame

local RedrawAll = function()
    for _, frame in pairs(FRAMES) do
        frame:RedrawFrame()
    end
end

local toggleTrinket = function(self)
    local itemFrame = FRAMES[self.id]
    local checked = self:GetChecked()
    SETTINGS[itemFrame.nameID] = checked or 0
    if checked then
        itemFrame:Show()
    else
        itemFrame:Hide()
    end
end

function optionsFrame:newCheckBox(id, y)
    local name = ADDON_NAME .. "CheckBox" .. id
    local checkBox = CreateFrame("CheckButton", name, self.childFrame, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", 0, y)
    checkBox.text = _G[name.."Text"]
    checkBox.id = id
    return checkBox
end

function optionsFrame:TrinketCheckbox(id, y)
    local checkBox = self:newCheckBox(id, y)
    checkBox:SetChecked(SETTINGS["TRINKET" .. id])
    checkBox:SetScript("OnClick", toggleTrinket)
    checkBox.text:SetText("Show trinket " .. id)
end

function optionsFrame:newSlider(option_name)
    local data = SLIDERS[option_name]
    local id = ADDON_NAME .. "Slider" .. option_name
    local slider = CreateFrame("Slider", id, self.childFrame, "OptionsSliderTemplate")

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

function optionsFrame:OnEvent(event, arg1)
	if event ~= "ADDON_LOADED" or arg1 ~= ADDON_NAME then return end
    self.name = ADDON_NAME
    self.childFrame = CreateFrame("Frame", nil, self)
    self.childFrame:SetPoint("TOPLEFT", 15, -15)
    self.childFrame:SetPoint("BOTTOMRIGHT", -15, 15)
    self.childFrame:Hide()

    self:SetScript("OnShow", function()
        self.childFrame:Show()
    end)
    self:SetScript("OnHide", function()
        self.childFrame:Hide()
    end)

    local title = self.childFrame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", self.childFrame)
    title:SetText(ADDON_NAME)

    self:TrinketCheckbox(13, -30)
    self:TrinketCheckbox(14, -60)

    local force30cb = self:newCheckBox(1, -90)
    force30cb:SetChecked(SETTINGS["FORCE30"])
    force30cb:SetScript("OnClick", function()
        local checked = force30cb:GetChecked()
        SETTINGS["FORCE30"] = checked or 0
    end)
    force30cb.text:SetText("Force 30 sec swap CD instead of iCD")

    for row, option_name in pairs(SLIDERS_ORDER) do
        local slider = self:newSlider(option_name)
        slider:SetPoint("TOPLEFT", 0, -100 - row * 35)
    end

    InterfaceOptions_AddCategory(self)
end

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", optionsFrame.OnEvent)
