local ADDON_NAME = "TrinketCDs"
local DB = _G.TrinketCDsDB
local SETTINGS = DB.DEFAULT_SETTINGS
local SWITCHES = SETTINGS.SWITCHES

local ADDON_PROFILE = ADDON_NAME .. "Profile"
local ADDON_NAME_COLOR = format("|cFFFFFF00[%s]|r: ", ADDON_NAME)

local ADDON_MEDIA = "Interface\\Addons\\" .. ADDON_NAME .. "\\Media\\%s"
local FONT = ADDON_MEDIA:format("Emblem.ttf")
local BORDER_TEXTURE = ADDON_MEDIA:format("BigBorder.blp")

local CHICKEN = 10725
local BORDER_WEAK = {edgeFile = BORDER_TEXTURE}
local PRECISION_FORMAT = {[0] = "%d", [1] = "%.1f"}

local FRAMES = {}
local ITEMS_CACHE = {}
local SPELLS_CACHE = {}

local ADDON = CreateFrame("Frame")
_G[ADDON_NAME] = ADDON
ADDON.FRAMES = FRAMES
ADDON.SETTINGS = SETTINGS
ADDON.ITEM_GROUP = DB.ITEM_GROUP
ADDON.ITEMS_TO_TRACK = {13, 14, 6, 8, 10, 11, 15, 16}

local function newTrinket(item_ID)
    local _, _, item_quality, item_level, _, _, _, _, _, item_texture = GetItemInfo(item_ID)
    local buff_ID = DB.TRINKET_PROC_ID[item_ID]
    local stacks_ID = DB.TRINKET_PROC_STACKS[buff_ID]
    local buff_IDs = DB.TRINKET_PROC_MULTIBUFF[item_ID]
    local proc_in_DB = (buff_ID or buff_IDs) and true
    local itemCD = proc_in_DB and (DB.TRINKET_PROC_CD[item_ID] or 45)

    local item = {
        ID = item_ID,
        CD = itemCD,
        ilvl = item_level,
        quality = item_quality,
        texture = item_texture,
        spell_ID = buff_ID,
        spell_IDs = buff_IDs,
        stacks_ID = stacks_ID,
        proc_in_DB = proc_in_DB,
    }
    ITEMS_CACHE[item_ID] = item
    return item
end

local function newNotTrinket(item_ID, buff_ID)
    if not buff_ID then return end
    local _, _, item_quality, item_level, _, _, _, _, _, item_texture = GetItemInfo(item_ID)

    local item = {
        ID = item_ID,
        CD = 60,
        ilvl = item_level,
        quality = item_quality,
        texture = item_texture,
        spell_ID = buff_ID,
        proc_in_DB = true,
    }
    ITEMS_CACHE[item_ID] = item
    return item
end

local function check_other_ring(self)
    local slot_ID = self.slot_ID == 11 and 12 or 11
    local item_ID = GetInventoryItemID("player", slot_ID)
    local buff_ID = DB.ASHEN_RINGS[item_ID]
    if buff_ID then
        self.slot_ID = slot_ID
        return item_ID, buff_ID
    end
end

local function newItem(self)
    local item_ID = GetInventoryItemID("player", self.slot_ID)
    if not item_ID then return end

    local item = ITEMS_CACHE[item_ID]
    if item then return item end

    if self.item_proc_type == "trinket" then
        return newTrinket(item_ID)
    elseif self.item_proc_type == "ring" then
        local buff_ID = DB.ASHEN_RINGS[item_ID]
        if not buff_ID then
            item_ID, buff_ID = check_other_ring(self)
        end
        return newNotTrinket(item_ID, buff_ID)
    elseif self.item_proc_type == "enchant_usable" then
        local item_link = GetInventoryItemLink("player", self.slot_ID)
        local ench_ID = item_link:match("%d:(%d+)")
        local buff_ID = DB.enchants[ench_ID]
        return newNotTrinket(item_ID, buff_ID)
    end
end

local function ResetFrame(self)
    self.cooldown_current_end = nil
    self.stacks_text:SetText()
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
    self:ToggleVisibility()
end

local function ApplyItemCD(self, dur)
    if self.item.applied then return end

    dur = dur or self.item.CD
    self.stacks_text:SetText()
    self.texture:SetDesaturated(1)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(self.item.cd_start, dur)
    self.cooldown_current_end = self.item.cd_start + dur
    self:ToggleVisibility()
end

local function ItemUsedCheck(self)
    if not self.is_usable then return end

    local cdStart, cdDur = GetInventoryItemCooldown("player", self.slot_ID)
    if cdDur == 0 then return end

    if cdDur > 30 then
        self.item.CD = cdDur
        if self.item.ID == CHICKEN and self.item_ID_before_chicken
        and GetTime() - cdStart < 5 then
            EquipItemByName(self.item_ID_before_chicken, self.slot_ID)
        end
    end

    self.item.cd_start = cdStart
    self.item.cd_end = cdStart + cdDur
    self:ApplyItemCD(cdDur)
end

local function get_spell_name(spell_ID)
    local spell_name = SPELLS_CACHE[spell_ID]
    if not spell_name then
        spell_name = GetSpellInfo(spell_ID)
        SPELLS_CACHE[spell_ID] = spell_name
    end
    return spell_name
end

local function player_buff(spell_ID)
    local buff_name = get_spell_name(spell_ID)
    local _, _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = UnitBuff("player", buff_name)
    if buffSpellID == spell_ID then
        return stacks, duration, expirationTime
    end
end

local function check_proc(item)
    if item.spell_ID then
        local stacks, duration, expirationTime = player_buff(item.spell_ID)
        if item.stacks_ID then
            stacks = player_buff(item.stacks_ID)
        end
        return stacks, duration, expirationTime
    elseif item.spell_IDs then
        for _, spell_ID in pairs(item.spell_IDs) do
            local stacks, duration, expirationTime = player_buff(spell_ID)
            if duration then
                return stacks, duration, expirationTime
            end
        end
    end
end

local function ItemBuffApplied(self, duration, expirationTime)
    local cd_start = expirationTime - duration
    local item = self.item
    item.applied = true
    if not item.cd_start or cd_start > item.cd_start then
        item.cd_start = cd_start
        item.buff_end = expirationTime
        item.cd_end = self.no_swap_cd and expirationTime or cd_start + item.CD
    end
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
    self.cooldown_current_end = expirationTime
    self:ToggleVisibility()
end

local function ItemBuffFaded(self)
    self.item.applied = false
    if self.no_swap_cd then
        self:ResetFrame()
    elseif self.is_usable then
        self:ItemUsedCheck()
    else
        self:ApplyItemCD()
    end
end

local function AuraCheck(self, swapped)
    if not self.item then return end

    local _stacks, _duration, _expiration = check_proc(self.item)
    if _duration == 0 then
        self.item.applied = true
        self.stacks_text:SetText(_stacks)
    elseif _duration then
        if _stacks ~= 0 then
            self.stacks_text:SetText(_stacks)
        end
        if swapped or _expiration ~= self.item.buff_end then
            self:ItemBuffApplied(_duration, _expiration)
        end
    elseif self.item.applied then
        self:ItemBuffFaded()
    end
end

local function OnUpdate(self)
    if self.item.cd_end and GetTime() > self.item.cd_end then
        self.item.cd_end = nil
        self.cooldown_current_end = nil
        self.texture:SetDesaturated(0)
        if SWITCHES.HIDE_READY ~= 0 then
            self:Hide()
        end
    end
end

local function ItemUpdate(self)
    local old_ID = self.item and self.item.ID
    if old_ID and old_ID ~= CHICKEN then
        self.item_ID_before_chicken = old_ID
    end

    local item = newItem(self)
    self.item = item
    if not item then return self:Hide() end

    self.texture:SetTexture(item.texture)
    self.ilvl_text:SetText(item.ilvl)
    self.ilvl_text:SetTextColor(unpack(DB.ITEM_QUALITY[item.quality]))

    self.no_swap_cd = item.CD == 0
    self:SetScript("OnUpdate", item.CD ~= 0 and OnUpdate or nil)

    local _, _, is_usable = GetInventoryItemCooldown("player", self.slot_ID)
    self.is_usable = is_usable == 1

    self:ResetFrame()
    self:AuraCheck(true)
    self:ItemUsedCheck()
end

local function ItemChanged(self)
    if not self.item
    or self.no_swap_cd
    or self.is_usable
    or not self.item.proc_in_DB then return end

    local now = GetTime()
    if SWITCHES.FORCE30 == 0 then
        self.item.cd_start = now
        self.item.cd_end = now + self.item.CD
        self:ApplyItemCD()
    elseif self.item.cd_end and self.item.cd_end - now > 30 then
        self:ApplyItemCD()
    else
        self.item.cd_start = now
        self.item.cd_end = now + 30
        self:ApplyItemCD(30)
    end
end

local function OnMouseDown(self, button)
    if InCombatLockdown() then
        print(ADDON_NAME_COLOR .. "Leave combat to swap items")
    elseif button == "LeftButton" then
        if IsControlKeyDown() then
            -- Ctrl+left mouse reequips item to force it's cooldown
            self.swap_back_item_id = self.item.ID
            PickupInventoryItem(self.slot_ID)
            PutItemInBackpack()
        elseif IsShiftKeyDown() then
            -- Shift+left mouse swaps trinkets to force cooldown of both
            if self.slot_ID == 13 then
                EquipItemByName(self.item.ID, 14)
            elseif self.slot_ID == 14 then
                EquipItemByName(self.item.ID, 13)
            end
        elseif IsAltKeyDown() then
            -- Alt+left mouse swaps to an item with the same name: pnl 277 <-> 264
            local item_name = GetItemInfo(self.item.ID)
            EquipItemByName(item_name, self.slot_ID)
        end
    elseif button == "RightButton" then
        if IsControlKeyDown() then
            if not self.is_button then
                print(ADDON_NAME_COLOR .. "To enable chicken swap, activate 'Click item to use' in options")
            elseif self.item.ID == CHICKEN then
                if not self.item_ID_before_chicken then return end
                EquipItemByName(self.item_ID_before_chicken, self.slot_ID)
            else
                EquipItemByName(CHICKEN, self.slot_ID)
            end
        end
    end
end

local function OnEvent(self, event, arg1, arg2)
    if event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        self:AuraCheck()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:ItemUsedCheck()
    elseif event == "ITEM_UNLOCKED" then
        if not self.swap_back_item_id then return end
        EquipItemByName(self.swap_back_item_id, self.slot_ID)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if DB.ITEM_GROUP[arg1] ~= self.item_group then return end
        self:ItemUpdate()
        self:ItemChanged()
        if self.swap_back_item_id and arg2 == 1 then
            self.swap_back_item_id = false
        end
    elseif event == "PLAYER_ENTERING_WORLD"
    or event == "GET_ITEM_INFO_RECEIVED" then
        if self.item then return end
        self:ItemUpdate()
    elseif event == "PLAYER_ALIVE" then
        if self.first_check then
            self.first_check = false
            self:ItemChanged()
        else
            self:ToggleVisibility()
        end
    elseif event == "PLAYER_DEAD" then
        self.first_check = false
    elseif event == "MODIFIER_STATE_CHANGED" then
        local mouse_is_down = arg2 == 1
        self:SetScript("OnMouseDown", mouse_is_down and OnMouseDown or nil)
        if not self.is_button then
            self:EnableMouse(mouse_is_down)
        end
    elseif event == "PLAYER_REGEN_DISABLED"
    or event == "PLAYER_REGEN_ENABLED" then
        self:ToggleVisibility()
    end
end

local function newFontOverlay(parent)
    local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(1, -1)
    return font
end

local function AddCooldownText(self)
    self.cooldown.text = newFontOverlay(self.cooldown)
    self.cooldown.text:SetPoint("CENTER")
    self.cooldown:SetScript("OnUpdate", function()
        if not self.cooldown_current_end then return end
        local diff = self.cooldown_current_end - GetTime()
        if diff > 99 then
            self.cooldown.text:SetFormattedText("%dm", diff/60)
        elseif diff < 0.1 then
            self.cooldown_current_end = nil
            self.cooldown.text:SetText()
        else
            self.cooldown.text:SetFormattedText(PRECISION_FORMAT[SWITCHES.SHOW_DECIMALS], diff)
        end
    end)
end

local function AddTextLayer(self)
    self.text_overlay = CreateFrame("Frame", nil, self)
    self.text_overlay:SetAllPoints()

    self.stacks_text = newFontOverlay(self.text_overlay)
    self.stacks_text:SetWidth(self.settings.ICON_SIZE)

    self.ilvl_text = newFontOverlay(self.text_overlay)
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
end

local function setnewfont(text, settings, key)
    if not text then return end
    local fontsize = settings.ICON_SIZE / 100 * (settings[key]) + 1
    text:SetFont(FONT, floor(fontsize), "OUTLINE")
end

local function RedrawFrame(self)
    self:SetSize(self.settings.ICON_SIZE, self.settings.ICON_SIZE)
    self:SetPoint("CENTER", self.settings.POS_X, self.settings.POS_Y)

    local zoom = self.settings.ZOOM / 100
    local mooz = 1 - zoom
    self.texture:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    local border_margin = self.settings.BORDER_MARGIN
    self.border:SetPoint("TOPLEFT", self, -border_margin, border_margin)
    self.border:SetPoint("BOTTOMRIGHT", self, border_margin, -border_margin)
    BORDER_WEAK.edgeSize = self.settings.EDGE_SIZE
    self.border:SetBackdrop(BORDER_WEAK)
    self.border:SetBackdropBorderColor(0, 0, 0, 1)

    setnewfont(self.stacks_text, self.settings, "STACKS_SIZE")
    setnewfont(self.ilvl_text, self.settings, "ILVL_SIZE")
    setnewfont(self.cooldown.text, self.settings, "CD_SIZE")

    if self.settings.SHOW_ILVL ~= 0 then
        self.ilvl_text:Show()
    else
        self.ilvl_text:Hide()
    end

    if SWITCHES.STACKS_BOTTOM ~= 0 then
        self.stacks_text:SetPoint("CENTER", 0, -self.settings.ICON_SIZE/2)
    else
        self.stacks_text:SetPoint("CENTER", 0, self.settings.ICON_SIZE/2)
    end

    self:ToggleVisibility()
end

local function PlayerInCombat()
    return UnitAffectingCombat("player") or UnitGUID("boss1")
end

local function ToggleVisibility(self)
    if not self.item or self.is_button and InCombatLockdown() then return end

    if self.settings.SHOW == 0
    or SWITCHES.COMBAT_ONLY ~= 0 and not PlayerInCombat()
    or SWITCHES.HIDE_READY ~= 0 and not self.is_button and not self.cooldown_current_end then
        self:Hide()
    else
        self:Show()
    end
end

local function AddFunctions(self)
    self.ApplyItemCD = ApplyItemCD
    self.AuraCheck = AuraCheck
    self.ItemBuffApplied = ItemBuffApplied
    self.ItemBuffFaded = ItemBuffFaded
    self.ItemChanged = ItemChanged
    self.ItemUsedCheck = ItemUsedCheck
    self.ItemUpdate = ItemUpdate
    self.RedrawFrame = RedrawFrame
    self.ResetFrame = ResetFrame
    self.ToggleVisibility = ToggleVisibility

    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    self:RegisterEvent("ITEM_UNLOCKED")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_AURA")

    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnMouseDown", OnMouseDown)
end

local function CreateNewItemFrame(slot_ID)
    local self
    if SWITCHES.USE_ON_CLICK ~= 0 then
        self = CreateFrame("Button", ADDON_NAME..slot_ID, UIParent, "SecureActionButtonTemplate")
        self:SetAttribute("type1", "macro")
        self:SetAttribute("macrotext1", "/use " .. slot_ID)
        self.is_button = true
    else
        self = CreateFrame("Frame", ADDON_NAME..slot_ID, UIParent)
    end

    self.slot_ID = slot_ID
    self.item_group = DB.ITEM_GROUP[slot_ID]
    self.item_proc_type = DB.ITEM_PROC_TYPE[slot_ID]
    self.first_check = true
    self.settings = SETTINGS.ITEMS[slot_ID]

    self.texture = self:CreateTexture(nil, "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")

    self.cooldown = CreateFrame("Cooldown", "Trinket"..slot_ID.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()
    if not OmniCC then AddCooldownText(self) end

    self.border = CreateFrame("Frame", nil, self)
    self.border:SetFrameStrata("MEDIUM")

    AddTextLayer(self)
    AddFunctions(self)
    RedrawFrame(self)

    return self
end

local function update_settings(svars_table, settings_table)
    if not svars_table then return end

    for old_table_key in pairs(settings_table) do
        local new_table_value = svars_table[old_table_key]
        if new_table_value then
            settings_table[old_table_key] = new_table_value
        end
    end
end

local function update_nested_settings(svars, key)
    local _svars = svars[key]
    if not _svars then return end

    for item_slot_id, settings_item in pairs(SETTINGS[key]) do
        update_settings(_svars[item_slot_id], settings_item)
    end
end

function ADDON:OnEvent(event, arg1)
	if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end

        local svars = _G[ADDON_PROFILE]
        if svars then
            update_nested_settings(svars, "ITEMS")
            update_settings(svars.SWITCHES, SWITCHES)
        end
        _G[ADDON_PROFILE] = SETTINGS

        for _, slot_ID in ipairs(self.ITEMS_TO_TRACK) do
            FRAMES[slot_ID] = CreateNewItemFrame(slot_ID)
        end
	end
end

ADDON:RegisterEvent("ADDON_LOADED")
ADDON:SetScript("OnEvent", ADDON.OnEvent)

SLASH_RIDEPAD_TRINKETS1 = "/tcd"
function SlashCmdList.RIDEPAD_TRINKETS(arg)
    if arg == "p" or arg == "cpu" then
        if GetCVarInfo('scriptProfile') == "0" then
            print(ADDON_NAME_COLOR .. "To check cpu usage, enable scriptProfile and reload")
            return
        end
        UpdateAddOnCPUUsage()
        local msg = ADDON_NAME_COLOR .. "Total seconds in addon:"
        msg = format("%s\n%.3fs", msg, GetAddOnCPUUsage(ADDON_NAME) / 1000)
        for _, frame in pairs(FRAMES) do
            local t, c = GetFrameCPUUsage(frame)
            msg = format("%s\n%.3fs | %d function calls", msg, t / 1000, c)
        end
        print(msg)
    end
end
