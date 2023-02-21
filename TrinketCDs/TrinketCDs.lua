local ADDON_NAME = "TrinketCDs"
local ADDON = CreateFrame("Frame")
_G[ADDON_NAME] = ADDON

local DB = _G.TrinketCDsDB
local SETTINGS = DB.DEFAULT_SETTINGS
local SWITCHES = SETTINGS.SWITCHES
ADDON.FRAMES = {}
ADDON.SETTINGS = SETTINGS
ADDON.ITEM_GROUP = DB.ITEM_GROUP
ADDON.SORTED_ITEMS = {13, 14, 11, 15, 16, 10, 8, 6}

local ITEMS_CACHE = {}
local SPELLS_CACHE = {}
local CHICKEN_ID = 10725
local PRECISION_FORMAT = {[0] = "%d", [1] = "%.1f"}
local CAN_BE_ACTIVATED = {[13]=true, [14]=true, [10]=true, [8]=true, [6]=true}
local ADDON_PROFILE = format("%sProfile", ADDON_NAME)
local ADDON_NAME_COLOR = format("|cFFFFFF00[%s]|r: ", ADDON_NAME)
local ADDON_MEDIA = format("Interface\\Addons\\%s\\Media\\%%s", ADDON_NAME)
local FONT = ADDON_MEDIA:format("Emblem.ttf")
local BORDER_TEXTURE = ADDON_MEDIA:format("BigBorder.blp")

-- global functions used in combat
local GetTime = GetTime
local UnitGUID = UnitGUID
local GetSpellInfo = GetSpellInfo
local InCombatLockdown = InCombatLockdown
local IsModifierKeyDown = IsModifierKeyDown
local UnitAffectingCombat = UnitAffectingCombat
local GetInventoryItemCooldown = GetInventoryItemCooldown

-- fk blzrd
local GetContainerNumFreeSlots = GetContainerNumFreeSlots or C_Container and C_Container.GetContainerNumFreeSlots

local function new_trinket(item_ID)
    if not item_ID then return end
    local _, _, item_quality, item_level, _, _, _, _, _, item_texture = GetItemInfo(item_ID)
    if not item_quality then return end

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

local function new_not_trinket(item_ID, buff_ID)
    if not buff_ID then return end
    local _, _, item_quality, item_level, _, _, _, _, _, item_texture = GetItemInfo(item_ID)
    if not item_quality then return end

    local item = {
        ID = item_ID,
        CD = DB.ENCHANT_PROC_CD[buff_ID] or 60,
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

local function new_item(self)
    local item_ID = GetInventoryItemID("player", self.slot_ID)
    local item = ITEMS_CACHE[item_ID]

    if self.item_proc_type == "enchant" then
        local item_link = GetInventoryItemLink("player", self.slot_ID)
        if not item_link then return end
        local ench_ID = item_link:match("%d:(%d+)")
        local buff_ID = DB.ENCHANTS[ench_ID]
        if item and item.spell_ID == buff_ID then return item end
        return new_not_trinket(item_ID, buff_ID)

    elseif item then return item

    elseif self.item_proc_type == "trinket" then
        return new_trinket(item_ID)

    elseif self.item_proc_type == "ring" then
        local buff_ID = DB.ASHEN_RINGS[item_ID]
        if not buff_ID then
            item_ID, buff_ID = check_other_ring(self)
        end
        return new_not_trinket(item_ID, buff_ID)
    end
end

local function ResetFrame(self)
    self.cooldown_current_end = nil
    self.stacks_text:SetText()
    self.texture:SetDesaturated(false)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
    self:ToggleVisibility()
end

local function ApplyItemCD(self, dur)
    if self.item.applied then return end

    dur = dur or self.item.CD
    self.stacks_text:SetText()
    self.texture:SetDesaturated(true)
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
        if self.item.ID == CHICKEN_ID and self.item_ID_before_chicken
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

local player_buff = (function()
    if AuraUtil and AuraUtil.FindAuraByName then
        local FindAuraByName = AuraUtil and AuraUtil.FindAuraByName
        return function(spell_ID)
            local buff_name = get_spell_name(spell_ID)
            local _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = FindAuraByName(buff_name, "player")
            if buffSpellID == spell_ID then
                return stacks, duration, expirationTime
            end
        end
    else
        local UnitBuff = UnitBuff
        return function(spell_ID)
            local buff_name = get_spell_name(spell_ID)
            local _, _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = UnitBuff("player", buff_name)
            if buffSpellID == spell_ID then
                return stacks, duration, expirationTime
            end
        end
    end
end)()

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
    self.texture:SetDesaturated(false)
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

    local stacks, duration, expiration = check_proc(self.item)
    if duration == 0 then
        self.item.applied = true
        self.stacks_text:SetText(stacks)
    elseif duration then
        if stacks ~= 0 then
            self.stacks_text:SetText(stacks)
        end
        if swapped or expiration ~= self.item.buff_end then
            self:ItemBuffApplied(duration, expiration)
        end
    elseif self.item.applied then
        self:ItemBuffFaded()
    end
end

local function OnUpdate(self)
    if self.item.cd_end and GetTime() > self.item.cd_end then
        self.item.cd_end = nil
        self.cooldown_current_end = nil
        self.texture:SetDesaturated(false)
        if SWITCHES.HIDE_READY ~= 0 then
            self:Hide()
        end
    end
end

local function ToggleButton(self)
    if not self.button then return end

    if SWITCHES.USE_ON_CLICK ~= 0 and self.is_usable
    or self.item and self.item.ID == CHICKEN_ID then
        self.button:Show()
    else
        self.button:Hide()
    end
end

local function ItemUpdate(self)
    local old_ID = self.item and self.item.ID
    if old_ID and old_ID ~= CHICKEN_ID then
        self.item_ID_before_chicken = old_ID
    end

    local item = new_item(self)
    if item and item == self.item then return end
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
    self:ToggleButton()
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
    self = self.parent or self
    if InCombatLockdown() then
        if not IsModifierKeyDown() then return end
        print(ADDON_NAME_COLOR .. "Leave combat to swap items")
    elseif button == "LeftButton" then
        if IsControlKeyDown() then
            -- Ctrl+left mouse reequips item to force it's cooldown
            self.swap_back_item_id = self.item.ID
            for i=0,4 do
                local free_slots, bag_type = GetContainerNumFreeSlots(i)
                if bag_type == 0 and free_slots > 0 then
                    PickupInventoryItem(self.slot_ID)
                    return i == 0 and PutItemInBackpack() or PutItemInBag(i+CONTAINER_BAG_OFFSET)
                end
            end

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
            if self.item.ID == CHICKEN_ID then
                if not self.item_ID_before_chicken then return end
                EquipItemByName(self.item_ID_before_chicken, self.slot_ID)
            else
                EquipItemByName(CHICKEN_ID, self.slot_ID)
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
    elseif event == "MODIFIER_STATE_CHANGED" then
        if self.button and self.button:IsVisible() then return end
        self:EnableMouse(arg2 == 1)
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        self:ToggleVisibility()
    elseif event == "ITEM_UNLOCKED" then
        if not self.swap_back_item_id then return end
        EquipItemByName(self.swap_back_item_id, self.slot_ID)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if DB.ITEM_GROUP[arg1] ~= self.item_group then return end
        if self.swap_back_item_id == GetInventoryItemID("player", self.slot_ID) then
            self.swap_back_item_id = false
        end
        local item = self.item
        local slot = self.slot_ID
        self:ItemUpdate()
        if item == self.item and slot == self.slot_ID then return end
        self:ItemChanged()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if self.item then return end
        self:ItemUpdate()
    elseif event == "UNIT_NAME_UPDATE" then
        if arg1 ~= "player" then return end
        if not self.item then
            self:ItemUpdate()
        end
        self:ItemChanged()
    end
end

local function new_font_overlay(parent)
    local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(1, -1)
    return font
end

local function AddCooldownText(self)
    if OmniCC then return end
    self.cooldown.text = new_font_overlay(self.cooldown)
    self.cooldown.text:SetPoint("CENTER")
    self.cooldown:SetScript("OnUpdate", function()
        if not self.cooldown_current_end then return end
        local diff = self.cooldown_current_end - GetTime()
        if diff > 100 then
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

    self.stacks_text = new_font_overlay(self.text_overlay)
    self.stacks_text:SetWidth(self.settings.ICON_SIZE)

    self.ilvl_text = new_font_overlay(self.text_overlay)
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
end

local function set_new_font(text, settings, key)
    if not text then return end
    local fontsize = settings.ICON_SIZE / 100 * (settings[key]) + 1
    text:SetFont(FONT, floor(fontsize), "OUTLINE")
end

local function RedrawFrame(self)
    local zoom = self.settings.ZOOM / 100
    local mooz = 1 - zoom
    self.texture:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    local border_margin = self.settings.BORDER_MARGIN
    self.border:SetPoint("TOPLEFT", self, -border_margin, border_margin)
    self.border:SetPoint("BOTTOMRIGHT", self, border_margin, -border_margin)
    self.border:SetBackdrop({edgeFile=BORDER_TEXTURE, edgeSize=self.settings.EDGE_SIZE})
    self.border:SetBackdropBorderColor(0, 0, 0, 1)

    if self.settings.SHOW_ILVL ~= 0 then
        self.ilvl_text:Show()
    else
        self.ilvl_text:Hide()
    end

    local stacks_pos = SWITCHES.STACKS_BOTTOM == 0 and 1 or -1
    self.stacks_text:SetPoint("CENTER", 0, self.settings.ICON_SIZE/2 * stacks_pos)

    if self.button and InCombatLockdown() then return end

    set_new_font(self.stacks_text, self.settings, "STACKS_SIZE")
    set_new_font(self.ilvl_text, self.settings, "ILVL_SIZE")
    set_new_font(self.cooldown.text, self.settings, "CD_SIZE")

    self:SetSize(self.settings.ICON_SIZE, self.settings.ICON_SIZE)
    self:SetPoint("CENTER", self.settings.POS_X, self.settings.POS_Y)

    self:ToggleButton()
    self:ToggleVisibility()
end

local function PlayerInCombat()
    return UnitAffectingCombat("player") or UnitGUID("boss1")
end

local function ToggleVisibility(self)
    if not self.item or self.button and InCombatLockdown() then return end

    if self.settings.SHOW == 0
    or SWITCHES.COMBAT_ONLY ~= 0 and not PlayerInCombat()
    or SWITCHES.HIDE_READY ~= 0 and not self.cooldown_current_end then
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
    self.ToggleButton = ToggleButton

    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("ITEM_UNLOCKED")
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("UNIT_NAME_UPDATE")

    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnMouseDown", OnMouseDown)
end

local function CreateNewItemFrame(slot_ID)
    local self = CreateFrame("Frame", ADDON_NAME..slot_ID, UIParent)

    if SWITCHES.HIDE_READY == 0 and CAN_BE_ACTIVATED[slot_ID] then
        self.button = CreateFrame("Button", ADDON_NAME..slot_ID.."Button", self, "SecureActionButtonTemplate")
        self.button:SetAttribute("type1", "macro")
        self.button:SetAttribute("macrotext1", "/use " .. slot_ID)
        self.button:SetAllPoints()
        self.button:SetScript("OnMouseDown", OnMouseDown)
        self.button.parent = self
    end

    self.slot_ID = slot_ID
    self.item_group = DB.ITEM_GROUP[slot_ID]
    self.item_proc_type = DB.ITEM_PROC_TYPES[slot_ID]
    self.settings = SETTINGS.ITEMS[slot_ID]

    self.texture = self:CreateTexture(ADDON_NAME..slot_ID.."Background", "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")

    self.border = CreateFrame("Frame", ADDON_NAME..slot_ID.."Border", self, BackdropTemplateMixin and "BackdropTemplate")
    self.border:SetFrameStrata("MEDIUM")

    self.cooldown = CreateFrame("Cooldown", ADDON_NAME..slot_ID.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()
    if self.cooldown.SetEdgeScale then self.cooldown:SetEdgeScale(0) end

    AddCooldownText(self)
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

        for _, slot_ID in ipairs(self.SORTED_ITEMS) do
            self.FRAMES[slot_ID] = CreateNewItemFrame(slot_ID)
        end
	end
end

ADDON:RegisterEvent("ADDON_LOADED")
ADDON:SetScript("OnEvent", ADDON.OnEvent)

SLASH_RIDEPAD_TRINKETS1 = "/tcd"
function SlashCmdList.RIDEPAD_TRINKETS(arg)
    if arg == "p" or arg == "cpu" then
        if GetCVarInfo('scriptProfile') == "0" then
            print(ADDON_NAME_COLOR .. "To check cpu usage, type in chat and reload\n|cFFFFFF00/console scriptProfile 1|r")
            return
        end
        UpdateAddOnCPUUsage()
        local msg = ADDON_NAME_COLOR .. "Total seconds in addon:"
        msg = format("%s\n%.3fs", msg, GetAddOnCPUUsage(ADDON_NAME) / 1000)
        for _, frame in pairs(ADDON.FRAMES) do
            local t, c = GetFrameCPUUsage(frame)
            msg = format("%s\n%.3fs | %d function calls", msg, t / 1000, c)
        end
        print(msg)
    elseif arg == "o" or arg == "opt" or arg == "options" or arg == "config" then
		InterfaceOptionsFrame_OpenToCategory(ADDON_NAME)
    else
        print(ADDON_NAME_COLOR .. "Available commands:")
        print("|cFFFFFF00o|r || |cFFFFFF00opt|r || |cFFFFFF00options|r || |cFFFFFF00config|r - opens options window")
        print("|cFFFFFF00p|r || |cFFFFFF00cpu|r - prints cpu usage")
    end
end
