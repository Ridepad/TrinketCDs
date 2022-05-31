local ADDON_NAME = "TrinketCDs"
local ADDON_OPTIONS = "TrinketCDsOptions"
local ADDON = _G[ADDON_NAME]
local FRAMES = ADDON.FRAMES
local SWITCHES = ADDON.SETTINGS.SWITCHES

local optionsFrame = CreateFrame("Frame")
ADDON.OPTIONS = optionsFrame

local RedrawAll = function()
    for _, frame in pairs(FRAMES) do
        frame:RedrawFrame()
    end
end

local MARGIN = 16
local SLIDERS_ORDER = {"ICON_SIZE", "POS_X", "POS_Y", "ZOOM", "BORDER_MARGIN", "EDGE_SIZE", "CD_SIZE", "ILVL_SIZE", "STACKS_SIZE"}
local SLIDERS = {
    ICON_SIZE = {
        label = "Icon size",
        min = 20, max = 75,
    },
    POS_X = {
        label = "Icon X",
        min = -2000, max = 2000,
    },
    POS_Y = {
        label = "Icon Y",
        min = -2000, max = 2000,
    },
    ZOOM = {
        label = "Icon zoom %",
        min = -200, max = 300, step = 5,
    },
    BORDER_MARGIN = {
        label = "Border margin",
        min = -5, max = 5,
    },
    EDGE_SIZE = {
        label = "Border edge",
        min = 1, max = 30,
    },
    CD_SIZE = {
        label = "Cooldown font size",
        min = 0, max = 100, step = 5,
    },
    ILVL_SIZE = {
        label = "Item level font size",
        min = 0, max = 100, step = 5,
    },
    STACKS_SIZE = {
        label = "Stacks font size",
        min = 0, max = 100, step = 5,
    },
}

local newCheckBox = function(parent, frame_ID, row)
    local cb_id = frame_ID*10+row
    local name = parent.name .. "CheckBox" .. cb_id
    local checkBox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox:SetPoint("TOPLEFT", MARGIN, -MARGIN*2*row)
    checkBox.text = _G[name.."Text"]
    checkBox.item_frame = parent.item_frame
    return checkBox
end


local edit_box_visual_bug_fix = function(slider)
    slider.EditBox:Hide()
    slider:SetScript("OnShow", function(f)
        f.EditBox:Show()
    end)
    slider.EditBox:SetScript("OnShow", function(f)
        f:SetText(slider:GetValue())
    end)
end

local newSlider = function(parent_frame, option_name)
    local data = SLIDERS[option_name]
    local settings = parent_frame.item_frame.settings
    local sliderID = ADDON_OPTIONS .. parent_frame.name .. "Slider" .. option_name
    local slider = CreateFrame("Slider", sliderID, parent_frame, "OptionsSliderTemplate")

    slider:SetSize(200, 15)
    slider:SetMinMaxValues(data.min, data.max)
    slider:SetValueStep(data.step or 1)
    slider:SetValue(settings[option_name])

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
        settings[option_name] = value
        f.EditBox:SetText(value)
        RedrawAll()
    end)

    return slider
end

local cb_properties = {
    USE_ON_CLICK = {
        row = 1,
        text = "Click item to use (requires reload)",
    },
    HIDE_READY = {
        row = 2,
        text = "Hide if ready (doesn't work with option above)",
        is_protected = true,
    },
    COMBAT_ONLY = {
        row = 3,
        text = "Hide out of combat",
    },
    SHOW_DECIMALS = {
        row = 4,
        text = "Show cooldown decimal",
    },
    FORCE30 = {
        row = 5,
        text = "Force 30 seconds iCD on swap",
    },
}

local main_setup_cd = function(cb, key)
    local properties = cb_properties[key]
    cb.text:SetText(properties.text)
    cb:SetChecked(SWITCHES[key] ~= 0)
    cb:SetScript("OnClick", function()
        SWITCHES[key] = cb:GetChecked() and 1 or 0
        RedrawAll()
    end)
    if properties.is_protected and SWITCHES.USE_ON_CLICK ~= 0 then
        cb:Disable()
    end
end

function optionsFrame:new_main_frame()
    local frame_ID = 0
    local config_frame = CreateFrame("Frame", nil, self)

    config_frame.name = ADDON_NAME

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(ADDON_NAME)

    for key, values in pairs(cb_properties) do
        local cb = newCheckBox(config_frame, frame_ID, values.row)
        main_setup_cd(cb, key)
    end

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

    local options_name = ADDON.ITEM_GROUP[itemID]
    local parent_name = self.main_options.name
    config_frame.name = options_name
    config_frame.parent = parent_name

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(options_name)

    config_frame.item_frame = FRAMES[itemID]

    local cb_show = newCheckBox(config_frame, itemID, 1)
    cb_show.text:SetText("Show")
    cb_show:SetChecked(config_frame.item_frame.settings.SHOW ~= 0)
    cb_show:SetScript("OnClick", toggle_item)

    local cb_show_lvl = newCheckBox(config_frame, itemID, 2)
    cb_show_lvl.text:SetText("Show item level")
    cb_show_lvl:SetChecked(config_frame.item_frame.settings.SHOW_ILVL ~= 0)
    cb_show_lvl:SetScript("OnClick", toggle_ilvl)

    for row, option_name in pairs(SLIDERS_ORDER) do
        local slider = newSlider(config_frame, option_name)
        local y = (row+2.5) * MARGIN * 2
        slider:SetPoint("TOPLEFT", MARGIN, -y)
    end

    InterfaceOptions_AddCategory(config_frame)
end

function optionsFrame:OnEvent(event, arg1)
    if arg1 ~= ADDON_NAME then return end
    self:new_main_frame()
    for _,slot_ID in ipairs(ADDON.ITEMS_TO_TRACK) do
        self:new_sub_frame(slot_ID)
    end
end

optionsFrame:RegisterEvent("ADDON_LOADED")
optionsFrame:SetScript("OnEvent", optionsFrame.OnEvent)
