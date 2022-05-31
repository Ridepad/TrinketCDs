local ADDON_NAME = "TrinketCDs"
local DB = _G.TrinketCDsDB
local SETTINGS = DB.DEFAULT_SETTINGS
local CHICKEN = 10725

local ADDON_PROFILE = ADDON_NAME .. "Profile"
local ADDON_NAME_COLOR = format("|cFFFFFF00[%s]|r: ", ADDON_NAME)

local ADDON_MEDIA = "Interface\\Addons\\" .. ADDON_NAME .. "\\Media\\%s"
local FONT = ADDON_MEDIA:format("Emblem.ttf")
local BORDER_TEXTURE = ADDON_MEDIA:format("BigBorder.blp")

local FRAMES = {}
local ITEMS_CACHE = {}

local ADDON = CreateFrame("Frame")
_G[ADDON_NAME] = ADDON
ADDON.FRAMES = FRAMES
ADDON.SETTINGS = SETTINGS
ADDON.ITEM_GROUP = DB.ITEM_GROUP
ADDON.ITEMS_TO_TRACK = {13, 14, 6, 8, 10, 11, 15, 16}

SLASH_RIDEPAD_TRINKETS1 = "/tcdp"
SlashCmdList["RIDEPAD_TRINKETS"] = function()
    UpdateAddOnCPUUsage()
    local msg = ADDON_NAME_COLOR .. "Total seconds in addon:"
    msg = format("%s\n%.3fs", msg, GetAddOnCPUUsage(ADDON_NAME) / 1000)
    for _, frame in pairs(FRAMES) do
        local t, c = GetFrameCPUUsage(frame)
        msg = format("%s\n%.3fs | %d function calls", msg, t / 1000, c)
    end
    print(msg)
end

local newTrinket = function(itemID)
    local _, _, itemQuality, itemLevel, _, _, _, _, _, texture = GetItemInfo(itemID)
    local buffID = DB.TRINKET_PROC_ID[itemID]
    local stacksID = DB.TRINKET_PROC_STACKS[buffID]
    local buffIDs = DB.TRINKET_PROC_MULTIBUFF[itemID]
    local procInDB = (buffID or buffIDs) and true
    local itemCD = procInDB and (DB.TRINKET_PROC_CD[itemID] or 45)

    local item = {
        ID = itemID,
        CD = itemCD,
        icon = texture,
        ilvl = itemLevel,
        quality = itemQuality,
        spellID = buffID,
        spellIDs = buffIDs,
        stacksID = stacksID,
        procInDB = procInDB,
    }
    ITEMS_CACHE[itemID] = item
    return item
end

local newNotTrinket = function(itemID, buffID)
    if not buffID then return end
    local _, _, itemQuality, itemLevel, _, _, _, _, _, texture = GetItemInfo(itemID)

    local item = {
        ID = itemID,
        CD = 60,
        icon = texture,
        ilvl = itemLevel,
        quality = itemQuality,
        spellID = buffID,
        procInDB = true,
    }
    ITEMS_CACHE[itemID] = item
    return item
end

local newItem = function(self)
    local itemID = GetInventoryItemID("player", self.slot_ID)
    if not itemID then return end

    local item = ITEMS_CACHE[itemID]
    if item then return item end

    if self.item_proc_type == "trinket" then
        return newTrinket(itemID)
    elseif self.item_proc_type == "ring" then
        local buffID = DB.ASHEN_RINGS[itemID]
        if not buffID then -- check other ring
            local slot_ID = self.slot_ID == 11 and 12 or 11
            itemID = GetInventoryItemID("player", slot_ID)
            buffID = DB.ASHEN_RINGS[itemID]
            if buffID then
                self.slot_ID = slot_ID
            end
        end
        return newNotTrinket(itemID, buffID)
    elseif self.item_proc_type == "enchant_usable" then
        local itemLink = GetInventoryItemLink("player", self.slot_ID)
        local enchID = itemLink:match("%d:(%d+)")
        local buffID = DB.enchants[enchID]
        return newNotTrinket(itemID, buffID)
    end
end

local ResetFrame = function(self)
    self.cooldown_current_end = nil
    self.stacks_text:SetText()
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
    self:ToggleVisibility()
end

local ApplyItemCD = function(self, dur)
    dur = dur or self.item.CD
    self.stacks_text:SetText()
    self.texture:SetDesaturated(1)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(self.item.cd_start, dur)
    self.cooldown_current_end = self.item.cd_start + dur
    self:ToggleVisibility()
end

local ItemUsedCheck = function(self)
    if not self.is_usable then return end

    local cdStart, cdDur = GetInventoryItemCooldown("player", self.slot_ID)
    if cdDur == 0 then return end

    if cdDur > 30 then
        self.item.CD = cdDur
        if self.item.ID == CHICKEN and
        self.old_item_ID
        and cdStart+cdDur-GetTime() > 60 then
            EquipItemByName(self.old_item_ID, self.slot_ID)
        end
    end

    self.item.cd_start = cdStart
    self.item.cd_end = cdStart + cdDur
    if not self.item.applied then
        self:ApplyItemCD(cdDur)
    end
end

local ItemBuffApplied = function(self, duration, expirationTime)
    local cd_start = expirationTime - duration
    local item = self.item
    item.applied = true
    item.cd_start = cd_start
    item.buff_end = expirationTime
    item.cd_end = self.no_swap_cd and expirationTime or cd_start + item.CD
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
    self.cooldown_current_end = expirationTime
    self:ToggleVisibility()
    -- self:ToggleVisibility('ItemBuffApplied')
end

local ItemBuffFaded = function(self)
    self.item.applied = false
    if self.no_swap_cd then
        self:ResetFrame()
    elseif self.is_usable then
        self:ItemUsedCheck()
    else
        self:ApplyItemCD()
    end
end

local playerBuff = function(spellID)
    local buff_name = GetSpellInfo(spellID)
    local _, _, _, stacks, _, duration, expirationTime, _, _, _, buffSpellID = UnitBuff("player", buff_name)
    if buffSpellID == spellID then
        return stacks, duration, expirationTime
    end
end

local check_proc = function(item)
    if item.spellID then
        local stacks, duration, expirationTime = playerBuff(item.spellID)
        if item.stacksID then
            stacks = playerBuff(item.stacksID)
        end
        return stacks, duration, expirationTime
    elseif item.spellIDs then
        for _, spellID in pairs(item.spellIDs) do
            local stacks, duration, expirationTime = playerBuff(spellID)
            if duration then
                return stacks, duration, expirationTime
            end
        end
    end
end

local AuraCheck = function(self, swapped)
    if not self.item then return end

    local buffStacks, buffDur, buffExp = check_proc(self.item)
    if buffDur == 0 then
        self.item.applied = true
        self.stacks_text:SetText(buffStacks)
    elseif buffDur then
        if buffStacks ~= 0 then
            self.stacks_text:SetText(buffStacks)
        end
        if swapped or buffExp ~= self.item.buff_end then
            self:ItemBuffApplied(buffDur, buffExp)
        end
    elseif self.item.applied then
        self:ItemBuffFaded()
    end
end

local OnUpdate = function(self)
    if self.item.cd_end and GetTime() > self.item.cd_end then
        self.item.cd_end = nil
        self.item.applied = false
        self.texture:SetDesaturated(0)
        if SETTINGS.SWITCHES.HIDE_READY ~= 0 then
            self:Hide()
        end
    end
end

local ItemUpdate = function(self)
    local item = newItem(self)
    self.old_item_ID = self.item and self.item.ID
    self.item = item
    if not item then return self:Hide() end

    self.texture:SetTexture(item.icon)
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

local ItemChanged = function(self)
    if not self.item
    or self.item.applied
    or self.no_swap_cd
    or self.is_usable
    or not self.item.procInDB then return end

    local now = GetTime()
    if SETTINGS.SWITCHES.FORCE30 == 0 then
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

local OnMouseDown = function(self, button)
    if InCombatLockdown() then
        print(ADDON_NAME_COLOR .. "Leave combat to swap items")
        return
    end
    if IsShiftKeyDown() then
        if button ~= "LeftButton" then return end
        -- Shift+left mouse swaps trinkets to force cooldown of both
        if self.slot_ID == 13 then
            EquipItemByName(self.item.ID, 14)
        elseif self.slot_ID == 14 then
            EquipItemByName(self.item.ID, 13)
        end
    elseif IsAltKeyDown() then
        if button ~= "LeftButton" then return end
        -- Alt+left mouse swaps to an item with the same name: pnl 277 <-> 264
        local item_name = GetItemInfo(self.item.ID)
        EquipItemByName(item_name, self.slot_ID)
    elseif IsControlKeyDown() then
        -- Ctrl+left mouse reequips item to force it's cooldown
        if button == "LeftButton" then
            self.swap_back_trigger = true
            PickupInventoryItem(self.slot_ID)
            PutItemInBackpack()
        elseif button == "RightButton" then
            if not self.is_button then
                print(ADDON_NAME_COLOR .. "To enable chicken swap, activate 'Click item to use' in options")
                return
            elseif self.item.ID == CHICKEN then
                if not self.old_item_ID then return end
                EquipItemByName(self.old_item_ID, self.slot_ID)
            else
                EquipItemByName(CHICKEN, self.slot_ID)
            end
        end
    end
end

local OnEvent = function(self, event, arg1, arg2)
    if event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        self:AuraCheck()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:ItemUsedCheck()
    elseif event == "ITEM_UNLOCKED" then
        if not self.swap_back_trigger then return end
        EquipItemByName(self.old_item_ID, self.slot_ID)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if DB.ITEM_GROUP[arg1] ~= self.item_group then return end
        self:ItemUpdate()
        self:ItemChanged()
        if self.swap_back_trigger and arg2 then
            self.swap_back_trigger = false
        end
    elseif event == "PLAYER_ENTERING_WORLD"
    or event == "GET_ITEM_INFO_RECEIVED" then
        if self.item then return end
        self:ItemUpdate()
    elseif event == "PLAYER_ALIVE" then
        if not self.first_check then return end
        self.first_check = false
        self:ItemChanged()
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

local newFontOverlay = function(parent)
    local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(1, -1)
    return font
end

local AddCooldownText = function(self)
    local PRECISION_FORMAT = {
        [0] = "%d",
        [1] = "%.1f",
    }
    self.cooldown.text = newFontOverlay(self.cooldown)
    self.cooldown.text:SetPoint("CENTER")
	self.cooldown.text:SetJustifyH("CENTER")
    self.cooldown:SetScript("OnUpdate", function()
        if not self.cooldown_current_end then return end
        local diff = self.cooldown_current_end - GetTime()
        if diff < 0 then
            self.cooldown_current_end = nil
            self.cooldown.text:SetText()
        else
            self.cooldown.text:SetFormattedText(PRECISION_FORMAT[SETTINGS.SWITCHES.SHOW_DECIMALS], diff)
        end
    end)
end

local AddTextLayer = function(self)
    self.itemText = CreateFrame("Frame", nil, self)
    self.itemText:SetAllPoints()

    self.stacks_text = newFontOverlay(self.itemText)
    self.stacks_text:SetPoint("TOP", 0, floor(self.settings.ICON_SIZE/3))
    self.stacks_text:SetWidth(self.settings.ICON_SIZE)
	self.stacks_text:SetJustifyH("CENTER")

    self.ilvl_text = newFontOverlay(self.itemText)
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
end

local setnewfont = function(text, settings, key)
    if not text then return end
    local fontsize = settings.ICON_SIZE / 100 * (settings[key]) + 1
    text:SetFont(FONT, floor(fontsize), "OUTLINE")
end

local RedrawFrame = function(self)
    self:SetSize(self.settings.ICON_SIZE, self.settings.ICON_SIZE)
    self:SetPoint("CENTER", self.settings.POS_X, self.settings.POS_Y)

    local zoom = self.settings.ZOOM / 100
    local mooz = 1 - zoom
    self.texture:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    local border_margin = self.settings.BORDER_MARGIN
    self.border:SetPoint("TOPLEFT", self, -border_margin, border_margin)
    self.border:SetPoint("BOTTOMRIGHT", self, border_margin, -border_margin)
    self.border:SetBackdrop({
        edgeFile = BORDER_TEXTURE,
        tile = true,
        edgeSize = self.settings.EDGE_SIZE,
    })
    self.border:SetBackdropBorderColor(0, 0, 0, 1)

    setnewfont(self.cooldown.text, self.settings, "CD_SIZE")
    setnewfont(self.stacks_text, self.settings, "STACKS_SIZE")
    setnewfont(self.ilvl_text, self.settings, "ILVL_SIZE")

    if self.settings.SHOW_ILVL ~= 0 then
        self.ilvl_text:Show()
    else
        self.ilvl_text:Hide()
    end

    self:ToggleVisibility()
    -- self:ToggleVisibility('RedrawFrame')
end

local PlayerInCombat = function()
    return UnitAffectingCombat("player") or UnitGUID("boss1")
end

local ToggleVisibility = function(self)
    if not self.item or self.is_button and InCombatLockdown() then return end

    if self.settings.SHOW == 0
    or SETTINGS.SWITCHES.COMBAT_ONLY ~= 0 and not PlayerInCombat()
    or SETTINGS.SWITCHES.HIDE_READY ~= 0 and not self.cooldown_current_end and not self.is_button then
        self:Hide()
    else
        self:Show()
    end
end

local AddFunctions = function(self)
    self.ApplyItemCD = ApplyItemCD
    self.AuraCheck = AuraCheck
    self.ItemUsedCheck = ItemUsedCheck
    self.ItemChanged = ItemChanged
    self.ItemBuffApplied = ItemBuffApplied
    self.ItemBuffFaded = ItemBuffFaded
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

local create_new_item = function(slot_ID)
    local self
    if SETTINGS.SWITCHES.USE_ON_CLICK ~= 0 then
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

    FRAMES[slot_ID] = self

    return self
end

local update_table = function(new_table, old_table, is_bool)
    if not new_table then return end
    for old_table_key, _ in pairs(old_table) do
        local new_table_value = new_table[old_table_key]
        if new_table_value then
            old_table[old_table_key] = is_bool and new_table_value ~= 0 and 1 or new_table_value
        end
    end
end

function ADDON:OnEvent(event, arg1)
	if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end

        local svars = _G[ADDON_PROFILE]
        if svars then
            for item_slot_id, settings_item in pairs(SETTINGS.ITEMS) do
                update_table(svars.ITEMS[item_slot_id], settings_item)
            end
            update_table(svars.SWITCHES, SETTINGS.SWITCHES, true)
        end
        _G[ADDON_PROFILE] = SETTINGS

        for _, slot_ID in ipairs(self.ITEMS_TO_TRACK) do
            create_new_item(slot_ID)
        end
	end
end

ADDON:RegisterEvent("ADDON_LOADED")
ADDON:SetScript("OnEvent", ADDON.OnEvent)
