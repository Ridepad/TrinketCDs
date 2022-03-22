local SETTINGS = {
    POS_X = 123,
    POS_Y = -155,
    ICON_SIZE = 40,
    SPACING = 2,
    ZOOM = 0,
    BORDER_MARGIN = 0,
    EDGE_SIZE = 10,
    TRINKET13 = true,
    TRINKET14 = true,
}

local ADDON_NAME = "TrinketCDs"
local ADDON_NAME_COLOR = "|cFFFFFF00[TrinketCDs]|r: "
-- local FONT = "Fonts/FRIZQT__.ttf"
local FONT = "Interface\\Addons\\TrinketCDs\\Media\\Emblem.ttf"
-- local BORDER_TEXTURE = "Interface/Tooltips/UI-Tooltip-Border"
local BORDER_TEXTURE = "Interface\\Addons\\TrinketCDs\\Media\\BigBorder.blp"

local FRAMES = {}
local ITEMS_CACHE = {}
local ITEM_QUALITY = {
    [1] = {1.00, 1.00, 1.00},
    [2] = {0.12, 1.00, 0.00},
    [3] = {0.00, 0.44, 0.87},
    [4] = {0.66, 0.33, 1.00},
    [7] = {0.90, 0.80, 0.50},
}
local COORDS = {
    [13] = {
        x = function() return SETTINGS.POS_X end,
        y = function() return SETTINGS.POS_Y end,
    },
    [14] = {
        x = function() return SETTINGS.POS_X + SETTINGS.ICON_SIZE + SETTINGS.SPACING end,
        y = function() return SETTINGS.POS_Y end,
    },
}
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

local TrinketsData = _G.TrinketsData
local TRINKET_CD = TrinketsData.trinket_CDs
local TRINKET_BUFFS = TrinketsData.trinket_buffs
local MULTIPROC = TrinketsData.multibuff

SLASH_RIDEPAD_TRINKETS1 = "/tcdp"
SlashCmdList["RIDEPAD_TRINKETS"] = function()
    UpdateAddOnCPUUsage()
    local msg = ADDON_NAME_COLOR .. "Total seconds in addon:"
    msg = string.format("%s\n%.3fs", msg, GetAddOnCPUUsage(ADDON_NAME) / 1000)
    for _, frame in pairs(FRAMES) do
        local t, c = GetFrameCPUUsage(frame)
        msg = string.format("%s\n%.3fs | %d function calls", msg, t / 1000, c)
    end
    print(msg)
end


local get_item = function(itemID)
    local item = ITEMS_CACHE[itemID]
    if item then return item end

    local _, _, itemQuality, itemLevel, _, _, _, _, _, texture = GetItemInfo(itemID)
    item = {
        ready = true,
        icon = texture,
        ilvl = itemLevel,
        quality = itemQuality,
        spellID = TRINKET_BUFFS[itemID],
        cd = TRINKET_CD[itemID] or 45,
        cd_finish = 0,
    }
    ITEMS_CACHE[itemID] = item
    return item
end

local update_frame = function(self)
    local itemID = GetInventoryItemID("player", self.slotID)
    if not itemID then return self:Hide() end

    local item = get_item(itemID)
    local start, duration, is_active = GetInventoryItemCooldown("player", self.slotID)
    if duration > 0 then
        item.on_cd = true
        item.cd_start = start
        item.cd_finish = start + duration
    end
    self.item = item
    self.itemID = itemID
    self.active = is_active == 1
    self.no_swap_cd = item.cd == 0
    self.texture:SetTexture(item.icon)
    self.stacksText:SetText()
    self.ilvl_text:SetText(item.ilvl)
    self.ilvl_text:SetTextColor(unpack(ITEM_QUALITY[item.quality]))
    if SETTINGS[self.nameID] then
        self:Show()
    end
end

local reset_frame = function(self)
    self.item.ready = true
    self.item.applied = false
    self.item.on_cd = false
    self.stacksText:SetText()
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
end

local apply_cd = function(self, dur)
    self.item.ready = false
    self.item.applied = false
    self.item.on_cd = true
    self.stacksText:SetText()
    self.texture:SetDesaturated(1)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(self.item.cd_start, dur)
end

local cd_after_swap_or_login = function(self)
    if self.no_swap_cd then
        return self:reset_frame()
    end
    local start, duration, active = GetInventoryItemCooldown("player", self.slotID)
    if active == 0 then
        start, duration = GetTime(), 30
    end
    self.item.cd_start = start
    self.item.cd_finish = start + duration
    self:apply_cd(duration)
end

local item_used_cd = function(self)
    if not self.active then return end
    local start, duration = GetInventoryItemCooldown("player", self.slotID)
    if duration == 0 then return end
    if duration > 30 then
        self.item.cd = duration
    end
    self.item.cd_start = start
    self.item.cd_finish = start + duration
    if self.item.applied then return end
    self:apply_cd(duration)
end

local hands_applied
local HANDS = GetSpellInfo(54758)
local check_hands_buff = function()
    if UnitBuff("player", HANDS) then
        if not hands_applied then
            hands_applied = true
            return true
        end
    elseif hands_applied then
        hands_applied = false
    end
end

local playerBuff = function(spellID)
    local buff_name = GetSpellInfo(spellID)
    local stacks, _, duration, expirationTime = select(4, UnitBuff("player", buff_name))
    return stacks, duration, expirationTime
end

local check_buff = function(self)
    local stacks, duration, expirationTime
    local procs = MULTIPROC[self.itemID]
    if procs then
        for _, spellID in pairs(procs) do
            stacks, duration, expirationTime = playerBuff(spellID)
            if duration then
                return stacks, duration, expirationTime
            end
        end
    elseif self.item.spellID then
        stacks, duration, expirationTime = playerBuff(self.item.spellID)
        return stacks, duration, expirationTime
    end
end

local buff_applied = function(self, duration, expirationTime)
    local item = self.item
    item.ready = false
    item.applied = true
    item.on_cd = true
    local cd_start = expirationTime - duration
    item.cd_start = cd_start
    item.cd_finish = self.no_swap_cd and expirationTime or cd_start + item.cd
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
end

local buff_faded = function(self)
    if self.no_swap_cd then
        return self:reset_frame()
    elseif self.active then
        local start, duration = GetInventoryItemCooldown("player", self.slotID)
        self.item.cd = duration
        self.item.cd_finish = start + duration
    end
    self:apply_cd(self.item.cd)
end

local check_aura = function(self)
    if check_hands_buff() then return end

    local stacks, duration, expirationTime = check_buff(self)
    if duration == 0 then
        self.item.applied = true
        self.texture:SetDesaturated(0)
        self.stacksText:SetText(stacks)
    elseif duration then
        if self.item.cd_finish == expirationTime
        or self.item.applied and stacks == 0 then return end

        self:buff_applied(duration, expirationTime)
        if stacks ~= 0 then
            self.stacksText:SetText(stacks)
        end
    elseif self.item.applied then
        self:buff_faded()
    end
end

local function OnEvent(self, event, arg1)
    if event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        self:check_aura()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:item_used_cd()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if arg1 ~= self.slotID then return end
        self:update_frame()
        if self.item.on_cd and self.item.cd_finish - GetTime() > 30 then
            self:apply_cd(self.item.cd)
        else
            self:cd_after_swap_or_login()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:update_frame()
    elseif self.first_check and event == "PLAYER_ALIVE" then
        self.first_check = false
        self:UnregisterEvent("PLAYER_ALIVE")
        self:cd_after_swap_or_login()
    end
end

local function OnUpdate(self)
    local item = self.item
    if item and item.on_cd and item.on_cd and GetTime() > item.cd_finish then
        item.ready = true
        item.applied = false
        item.on_cd = false
        self.texture:SetDesaturated(0)
    end
end

local function OnMouseDown(self, button)
    if button ~= "LeftButton" then return end
    if UnitAffectingCombat("player") then
        print(ADDON_NAME_COLOR .. "Leave combat to swap trinkets")
        return
    end
    if IsShiftKeyDown() then
        -- shift+left mouse swaps trinkets
        local slotID = self.slotID == 13 and 14 or 13
        EquipItemByName(self.itemID, slotID)
    elseif IsAltKeyDown() then
        -- alt+left mouse swaps trinkets with same name: pnl 277 <-> 264
        local item_name = GetItemInfo(self.itemID)
        EquipItemByName(item_name, self.slotID)
    end
end

local function add_text(self)
    self.itemText = CreateFrame("Frame", nil, self)
    self.itemText:SetAllPoints()

    self.stacksText = self.itemText:CreateFontString(nil, "OVERLAY")
    self.stacksText:SetPoint("TOP", 0, floor(SETTINGS.ICON_SIZE/3))
	self.stacksText:SetShadowColor(0, 0, 0, 1)
	self.stacksText:SetShadowOffset(1, -1)
    self.stacksText:SetWidth(SETTINGS.ICON_SIZE)
	self.stacksText:SetJustifyH("CENTER")

    self.ilvl_text = self.itemText:CreateFontString(nil, "OVERLAY")
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
	self.ilvl_text:SetShadowColor(0, 0, 0, 1)
	self.ilvl_text:SetShadowOffset(1, -1)
end

local redraw = function(self)
    self:SetSize(SETTINGS.ICON_SIZE, SETTINGS.ICON_SIZE)

    local pos = COORDS[self.slotID]
    self:SetPoint("CENTER", pos.x(), pos.y())

    local zoom = SETTINGS.ZOOM / 100
    local mooz = 1 - zoom
    self.texture:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    local border_margin = SETTINGS.BORDER_MARGIN
    self.border:SetPoint("TOPLEFT", self, -border_margin, border_margin)
    self.border:SetPoint("BOTTOMRIGHT", self, border_margin, -border_margin)
    self.border:SetBackdrop({
        edgeFile = BORDER_TEXTURE,
        tile = true,
        edgeSize = SETTINGS.EDGE_SIZE,
    })
    self.border:SetBackdropBorderColor(0, 0, 0, 1)

    self.stacksText:SetFont(FONT, floor(SETTINGS.ICON_SIZE/2), "OUTLINE")
    self.ilvl_text:SetFont(FONT, floor(SETTINGS.ICON_SIZE/4), "OUTLINE")
end

local redraw_all = function()
    for _, frame in pairs(FRAMES) do
        redraw(frame)
    end
end

local function create_new_item(slotID)
    local self = CreateFrame("Frame", ADDON_NAME..slotID)

    self.texture = self:CreateTexture(nil, "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")

    self.cooldown = CreateFrame("Cooldown", "Trinket"..slotID.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()

    self.border = CreateFrame("Frame", nil, self)
    self.border:SetFrameStrata("MEDIUM")

    self.slotID = slotID
    self.nameID = "TRINKET"..slotID
    self.first_check = true
    self.update_frame = update_frame
    self.apply_cd = apply_cd
    self.cd_after_swap_or_login = cd_after_swap_or_login
    self.reset_frame = reset_frame
    self.check_aura = check_aura
    self.item_used_cd = item_used_cd
    self.buff_faded = buff_faded
    self.buff_applied = buff_applied

    add_text(self)
    redraw(self)

    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("UNIT_AURA")
    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnUpdate", OnUpdate)
    self:SetScript("OnMouseDown", OnMouseDown)
    self:EnableMouse(true)

    if not SETTINGS[self.nameID] then
        self:Hide()
    end

    return self
end


local mainFrame = CreateFrame("Frame")

function mainFrame:OnEvent(event, addOnName)
	if addOnName == ADDON_NAME then
        local t = _G.TrinketCDsProfile
        if t then
            for key, _ in pairs(SETTINGS) do
                SETTINGS[key] = t[key]
            end
        end
        _G.TrinketCDsProfile = SETTINGS

        FRAMES[13] = create_new_item(13)
        FRAMES[14] = create_new_item(14)
		self:SetupOptions()
	end
end

mainFrame:RegisterEvent("ADDON_LOADED")
mainFrame:SetScript("OnEvent", mainFrame.OnEvent)

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

function mainFrame:newCheckBox(id)
    local name = "TrinketCDsCheckBox" .. id
    local cb = CreateFrame("CheckButton", name, self.childFrame, "InterfaceOptionsCheckButtonTemplate")
    cb:SetChecked(SETTINGS["TRINKET"..id])
    cb.text = _G[name.."Text"]
    cb.text:SetText("Toggle trinket "..id)
    cb.id = 13
    return cb
end

function mainFrame:newSlider(option_name)
    local data = SLIDERS[option_name]
    local id = "TrinketCDsSlider"..option_name
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

    slider:SetScript("OnValueChanged", function(f, value)
        SETTINGS[option_name] = value
        redraw_all()
        f.EditBox:SetText(value)
    end)

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

    return slider
end

function mainFrame:SetupOptions()
    self.panel = CreateFrame("Frame")
    self.panel.name = ADDON_NAME

    self.childFrame = CreateFrame("Frame", nil, self.panel)
    self.childFrame:SetPoint("TOPLEFT", 15, -15)
    self.childFrame:SetPoint("BOTTOMRIGHT", -15, 15)
    self.childFrame:Hide()

    self.panel:SetScript("OnShow", function()
        self.childFrame:Show()
    end)
    self.panel:SetScript("OnHide", function()
        self.childFrame:Hide()
    end)

    local title = self.childFrame:CreateFontString(nil, nil, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", self.childFrame)
    title:SetText(ADDON_NAME)

	local t13toggle = self:newCheckBox(13)
	t13toggle:SetPoint("TOPLEFT", 0, -30)
    t13toggle.text:SetText("Show trinket 13")
    t13toggle:SetScript("OnClick", toggleTrinket)

	local t14toggle = self:newCheckBox(14)
	t14toggle:SetPoint("TOPLEFT", 0, -60)
    t14toggle.text:SetText("Show trinket 14")
    t14toggle:SetScript("OnClick", toggleTrinket)

    for row, option_name in pairs(SLIDERS_ORDER) do
        local slider = self:newSlider(option_name)
        slider:SetPoint("TOPLEFT", 0, -100 - row * 35)
    end

	InterfaceOptions_AddCategory(self.panel)
end
