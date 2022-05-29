local ADDON_NAME = "TrinketCDs"
local ADDON_OPTIONS = "TrinketCDsOptions"
local ADDON = _G[ADDON_NAME]
local FRAMES = ADDON['FRAMES']

local MARGIN = 16
local SLIDERS_ORDER = {"ICON_SIZE", "POS_X", "POS_Y", "ZOOM", "BORDER_MARGIN", "EDGE_SIZE"}
local SLIDERS = {
    ICON_SIZE = {
        label = "Change icon size",
        min = 20, max = 75,
    },
    POS_X = {
        label = "Change icon X",
        min = -2000, max = 2000,
    },
    POS_Y = {
        label = "Change icon Y",
        min = -2000, max = 2000,
    },
    ZOOM = {
        label = "Change icon zoom %",
        min = -200, max = 300, step = 5,
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

local function newCheckBox(parent, frame_ID, row)
    local cb_id = frame_ID*10+row
    local name = parent.name .. "CheckBox" .. cb_id
    local checkBox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", MARGIN, -MARGIN*2*row)
    checkBox.text = _G[name.."Text"]
    checkBox.item_frame = parent.item_frame
    return checkBox
end


local function edit_box_visual_bug_fix(slider)
    slider.EditBox:Hide()
    slider:SetScript("OnShow", function(f)
        f.EditBox:Show()
    end)
    slider.EditBox:SetScript("OnShow", function(f)
        f:SetText(slider:GetValue())
    end)
end

local function newSlider(parent_frame, option_name)
    local sliderID = ADDON_OPTIONS .. parent_frame.name .. "Slider" .. option_name
    local slider = CreateFrame("Slider", sliderID, parent_frame, "OptionsSliderTemplate")

    local _settings = parent_frame.item_frame.settings

    local data = SLIDERS[option_name]
    slider:SetSize(200, 15)
    slider:SetMinMaxValues(data.min, data.max)
    slider:SetValueStep(data.step or 1)
    slider:SetValue(_settings[option_name])

    slider.InfoText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.InfoText:SetPoint("TOP", slider, 0, 20)
    slider.InfoText:SetSize(200, 20)
	slider.InfoText:SetJustifyH("CENTER")
    slider.InfoText:SetText(data.label)

    local EditBoxID = ADDON_OPTIONS .. parent_frame.name .. "EditBox" .. option_name
    slider.EditBox = CreateFrame("EditBox", EditBoxID, slider, "InputBoxTemplate")
	slider.EditBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
	slider.EditBox:SetSize(50, 20)
    slider.EditBox:SetMaxLetters(5)
    slider.EditBox:SetJustifyH("RIGHT")
    slider.EditBox:SetMultiLine(false)
    slider.EditBox:SetAutoFocus(false)
    slider.EditBox:ClearFocus()
    edit_box_visual_bug_fix(slider)

    slider.EditBox:SetScript("OnEscapePressed", slider.EditBox.ClearFocus)

    slider.EditBox:SetScript("OnEnterPressed", function(f)
        local value = f:GetText()
        if tonumber(value) then
            slider:SetValue(value)
            f:ClearFocus()
        else
            f:SetText(slider:GetValue())
        end
    end)

    slider:SetScript("OnValueChanged", function(f, value)
        _settings[option_name] = value
        f.EditBox:SetText(value)
        RedrawAll()
    end)

    return slider
end

local itemnames = {
    [0] = "MainFrame",
    [10] = "Hands",
    [11] = "Ring",
    [12] = "Ring",
    [13] = "Trinket1",
    [14] = "Trinket2",
    [15] = "Cloak",
    [16] = "Weapon",
}

function optionsFrame:new_main_frame()
    local frame_ID = 0
    local config_frame = CreateFrame("Frame", nil, self)

    config_frame.name = ADDON_NAME

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(ADDON_NAME)

    local cb_enable = newCheckBox(config_frame, frame_ID, 1)
    cb_enable.text:SetText("force 30")

    InterfaceOptions_AddCategory(config_frame)
    self.main_options = config_frame
end

local toggle_item = function(self)
    local checked = self:GetChecked()
    self.item_frame.settings.SHOW = checked and 1 or 0
    self.item_frame:ToggleVisibility(checked)
end

local toggle_ilvl = function(self)
    if self:GetChecked() then
        self.item_frame.settings.SHOW_ILVL = 1
        self.item_frame.ilvl_text:Show()
    else
        self.item_frame.settings.SHOW_ILVL = 0
        self.item_frame.ilvl_text:Hide()
    end
end

function optionsFrame:new_sub_frame(itemID)
    local config_frame = CreateFrame("Frame", nil, self)

    local options_name = itemnames[itemID]
    local parent_name = self.main_options.name
    config_frame.name = options_name
    config_frame.parent = parent_name

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(options_name)

    config_frame.item_frame = FRAMES[itemID]

    local cb_enable = newCheckBox(config_frame, itemID, 1)
    cb_enable.text:SetText("Enable")
    cb_enable:SetChecked(config_frame.item_frame.settings.SHOW ~= 0)
    cb_enable:SetScript("OnClick", toggle_item)

    local cb_show_lvl = newCheckBox(config_frame, itemID, 2)
    cb_show_lvl.text:SetText("Show item level")
    cb_show_lvl:SetChecked(config_frame.item_frame.settings.SHOW_ILVL ~= 0)
    cb_show_lvl:SetScript("OnClick", toggle_ilvl)

    for row, option_name in pairs(SLIDERS_ORDER) do
        local slider = newSlider(config_frame, option_name)
        slider:SetPoint("TOPLEFT", MARGIN, - (row+3) * MARGIN * 2)
    end

    InterfaceOptions_AddCategory(config_frame)
end



function optionsFrame:OnEvent(event, arg1)
    if arg1 ~= ADDON_NAME then return end
    self:new_main_frame()
    self:new_sub_frame(13)
    self:new_sub_frame(14)
    self:new_sub_frame(15)
    self:new_sub_frame(11)
    self:new_sub_frame(10)
end


optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", optionsFrame.OnEvent)
