local ADDON_NAME = "TrinketCDs"
local ADDON_OPTIONS = "TrinketCDsOptions"
local ADDON = _G[ADDON_NAME]
local FRAMES = ADDON.FRAMES
local SWITCHES = ADDON.SETTINGS.SWITCHES
local SLIDER_NAME = ADDON_OPTIONS .. "%sSlider%s"
local EDITBOX_NAME = ADDON_OPTIONS .. "%sEditBox%s"

local OPTIONS_FRAME = CreateFrame("Frame")
ADDON.OPTIONS = OPTIONS_FRAME

local MARGIN = 16
local SLIDERS = {
    ICON_SIZE = {
        row = 1,
        label = "Icon size",
        min = 20, max = 75,
    },
    POS_X = {
        row = 2,
        label = "Icon X",
        min = -2000, max = 2000,
        func = function(self)
            local w = floor(GetScreenWidth() / 2)
            self:SetMinMaxValues(-w, w)
            self.EditBox:Show()
        end
    },
    POS_Y = {
        row = 3,
        label = "Icon Y",
        min = -2000, max = 2000,
        func = function(self)
            local h = floor(GetScreenHeight() / 2)
            self:SetMinMaxValues(-h, h)
            self.EditBox:Show()
        end
    },
    ZOOM = {
        row = 4,
        label = "Icon zoom %",
        min = -200, max = 300, step = 5,
    },
    BORDER_MARGIN = {
        row = 5,
        label = "Border margin",
        min = -5, max = 5,
    },
    EDGE_SIZE = {
        row = 6,
        label = "Border edge",
        min = 1, max = 30,
    },
    ILVL_SIZE = {
        row = 7,
        label = "Item level font size",
        min = 0, max = 100, step = 5,
    },
    STACKS_SIZE = {
        row = 8,
        label = "Stacks font size",
        min = 0, max = 100, step = 5,
    },
    CD_SIZE = {
        row = 9,
        label = "Cooldown font size",
        min = 0, max = 100, step = 5,
    },
}

local CB_DEFAULTS_MAIN = {
    USE_ON_CLICK = {
        row = 1,
        label = "Enable item activation with mouse",
    },
    HIDE_READY = {
        row = 2,
        label = "Hide if ready (overwrites option above, requires reload)",
    },
    COMBAT_ONLY = {
        row = 3,
        label = "Hide out of combat",
    },
    STACKS_BOTTOM = {
        row = 4,
        label = "Move stacks to the bottom of the frame",
    },
    SHOW_DECIMALS = {
        row = 5,
        label = "Show cooldown decimal (for built-in cooldown)",
        skip = true,
    },
    FORCE30 = {
        row = 6,
        label = "Force 30 seconds iCD on swap",
        skip = true,
    },
}

local show_slider_edit_box = function(self)
    self.EditBox:Show()
end

local function new_check_box(parent, frame_ID, row)
    local cb_id = frame_ID * 10 + row
    local name = parent.name .. "CheckBox" .. cb_id
    local checkBox = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    local y = MARGIN * 2 * row
    checkBox:SetPoint("TOPLEFT", MARGIN, -y)
    checkBox.label = _G[name.."Text"]
    checkBox.item_frame = parent.item_frame
    return checkBox
end

local function cb_toggle_item_visibility(self)
    self.item_frame.settings.SHOW = self:GetChecked() and 1 or 0
    self.item_frame:ToggleVisibility()
end

local function cb_toggle_ilvl_visibility(self)
    if self:GetChecked() then
        self.item_frame.settings.SHOW_ILVL = 1
        self.item_frame.ilvl_text:Show()
    else
        self.item_frame.settings.SHOW_ILVL = 0
        self.item_frame.ilvl_text:Hide()
    end
end

local function edit_box_visual_bug_fix(slider, custom_func)
    slider.EditBox:Hide()
    slider:SetScript("OnShow", custom_func or show_slider_edit_box)
    slider.EditBox:SetScript("OnShow", function(f)
        f:SetText(slider:GetValue())
    end)
end

local function new_slider(parent_frame, option_name, properties)
    local settings = parent_frame.item_frame.settings
    local sliderID = SLIDER_NAME:format(parent_frame.name, option_name)
    local slider = CreateFrame("Slider", sliderID, parent_frame, "OptionsSliderTemplate")

    local y = (properties.row + 2.5) * MARGIN * 2
    slider:SetPoint("TOPLEFT", MARGIN, -y)
    slider:SetSize(250, 15)
    slider:SetMinMaxValues(properties.min, properties.max)
    slider:SetValueStep(properties.step or 1)
    slider:SetValue(settings[option_name])

    slider.InfoText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slider.InfoText:SetPoint("TOP", slider, 0, 20)
    slider.InfoText:SetSize(250, 20)
	slider.InfoText:SetJustifyH("CENTER")
    slider.InfoText:SetText(properties.label)

    local EditBoxID = EDITBOX_NAME:format(parent_frame.name, option_name)
    slider.EditBox = CreateFrame("EditBox", EditBoxID, slider, "InputBoxTemplate")
	slider.EditBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
	slider.EditBox:SetSize(50, 20)
    slider.EditBox:SetMaxLetters(5)
    slider.EditBox:SetJustifyH("RIGHT")
    slider.EditBox:SetMultiLine(false)
    slider.EditBox:SetAutoFocus(false)
    slider.EditBox:ClearFocus()
    edit_box_visual_bug_fix(slider, properties.func)

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
        parent_frame.item_frame:RedrawFrame()
    end)

    return slider
end

local function redraw_all()
    for _, frame in pairs(FRAMES) do
        frame:RedrawFrame()
    end
end

local function main_setup_cd(cb, key)
    local properties = CB_DEFAULTS_MAIN[key]
    cb.label:SetText(properties.label)
    cb:SetChecked(SWITCHES[key] ~= 0)

    cb:SetScript("OnClick", function(self)
        SWITCHES[key] = self:GetChecked() and 1 or 0
        if not properties.skip then redraw_all() end
    end)
end

function OPTIONS_FRAME:add_main_settings()
    local frame_ID = 0
    local config_frame = CreateFrame("Frame", nil, self)
    config_frame.name = ADDON_NAME

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(ADDON_NAME)

    for key, values in pairs(CB_DEFAULTS_MAIN) do
        local cb = new_check_box(config_frame, frame_ID, values.row)
        main_setup_cd(cb, key)
    end

    InterfaceOptions_AddCategory(config_frame)
    self.main_options = config_frame
end

function OPTIONS_FRAME:add_item_settings(itemID)
    local config_frame = CreateFrame("Frame", nil, self)
    config_frame.item_frame = FRAMES[itemID]

    local options_name = config_frame.item_frame.item_group
    config_frame.name = options_name
    config_frame.parent = self.main_options.name

    local title = config_frame:CreateFontString(nil, nil, "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    title:SetText(options_name)

    local cb_show = new_check_box(config_frame, itemID, 1)
    cb_show.label:SetText("Show")
    cb_show:SetChecked(config_frame.item_frame.settings.SHOW ~= 0)
    cb_show:SetScript("OnClick", cb_toggle_item_visibility)

    local cb_show_lvl = new_check_box(config_frame, itemID, 2)
    cb_show_lvl.label:SetText("Show item level")
    cb_show_lvl:SetChecked(config_frame.item_frame.settings.SHOW_ILVL ~= 0)
    cb_show_lvl:SetScript("OnClick", cb_toggle_ilvl_visibility)

    for option_name, properties in pairs(SLIDERS) do
        new_slider(config_frame, option_name, properties)
    end

    InterfaceOptions_AddCategory(config_frame)
end

function OPTIONS_FRAME:OnEvent(event, arg1)
    if arg1 ~= ADDON_NAME then return end
    self:add_main_settings()
    for _, slot_ID in ipairs(ADDON.SORTED_ITEMS) do
        self:add_item_settings(slot_ID)
    end
end

OPTIONS_FRAME:RegisterEvent("ADDON_LOADED")
OPTIONS_FRAME:SetScript("OnEvent", OPTIONS_FRAME.OnEvent)
