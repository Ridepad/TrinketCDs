local ADDON_NAME = "TrinketCDs"
local DB = _G.TrinketCDsDB
local TRINKET_CD = DB.trinket_CDs
local TRINKET_BUFFS = DB.trinket_buffs
local MULTIBUFF = DB.multibuff
local WITH_STACKS = DB.buffs_with_stacks
local FRAMES = {}
local SETTINGS = {
    POS_X = 115,
    POS_Y = -155,
    ICON_SIZE = 40,
    SPACING = 2,
    ZOOM = 0,
    BORDER_MARGIN = 0,
    EDGE_SIZE = 10,
    TRINKET13 = 1,
    TRINKET14 = 1,
    FORCE30 = 0,
}

local ADDON = CreateFrame("Frame")
_G[ADDON_NAME] = ADDON
ADDON.SETTINGS = SETTINGS
ADDON.FRAMES = FRAMES

local ADDON_MEDIA = "Interface\\Addons\\" .. ADDON_NAME .. "\\Media\\%s"
local FONT = ADDON_MEDIA:format("Emblem.ttf")
local BORDER_TEXTURE = ADDON_MEDIA:format("BigBorder.blp")

local ADDON_PROFILE = ADDON_NAME .. "Profile"
local ADDON_NAME_COLOR = format("|cFFFFFF00[%s]|r: ", ADDON_NAME)

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

local ResetFrame = function(self)
    self.stacksText:SetText()
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(0, 0)
end

local ApplyItemCD = function(self, dur)
    dur = dur or self.item.CD
    self.stacksText:SetText()
    self.texture:SetDesaturated(1)
    self.cooldown:SetReverse(false)
    self.cooldown:SetCooldown(self.item.cd_start, dur)
end

local newItem = function(itemID)
    local _, _, itemQuality, itemLevel, _, _, _, _, _, texture = GetItemInfo(itemID)
    local buffID = TRINKET_BUFFS[itemID]
    local stacksBuff = WITH_STACKS[buffID]
    local buffIDs = MULTIBUFF[itemID]
    local procInDB = (buffID or buffIDs) and true
    local itemCD = procInDB and (TRINKET_CD[itemID] or 45)
    local item = {
        ID = itemID,
        CD = itemCD,
        icon = texture,
        ilvl = itemLevel,
        quality = itemQuality,
        spellID = buffID,
        spellIDs = buffIDs,
        procInDB = procInDB,
        stacksBuff = stacksBuff,
    }
    ITEMS_CACHE[itemID] = item
    return item
end

local CheckItemUsed = function(self)
    if not self.usable then return end
    local cdStart, cdDur = GetInventoryItemCooldown("player", self.slotID)
    if cdDur == 0 then return end
    if cdDur > 30 then
        self.item.CD = cdDur
    end
    self.item.cd_start = cdStart
    self.item.cd_end = cdStart + cdDur
    if not self.item.applied then
        self:ApplyItemCD(cdDur)
    end
end

local ItemBuffApplied = function(self, duration, expirationTime)
    local item = self.item
    item.applied = true
    local cd_start = expirationTime - duration
    item.cd_start = cd_start
    item.buff_end = expirationTime
    item.cd_end = self.no_swap_cd and expirationTime or cd_start + item.CD
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
end

local ItemBuffFaded = function(self)
    self.item.applied = false
    if self.no_swap_cd then
        self:ResetFrame()
    elseif self.usable then
        self:CheckItemUsed()
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

local check_buff = function(self)
    if self.item.spellID then
        local stacks, duration, expirationTime = playerBuff(self.item.spellID)
        if self.item.stacksBuff then
            stacks = playerBuff(self.item.stacksBuff)
        end
        return stacks, duration, expirationTime
    elseif self.item.spellIDs then
        for _, spellID in pairs(self.item.spellIDs) do
            local stacks, duration, expirationTime = playerBuff(spellID)
            if duration then
                return stacks, duration, expirationTime
            end
        end
    end
end

local CheckAura = function(self, swapped)
    if not self.item then return end

    local buffStacks, buffDur, buffExp = check_buff(self)
    if buffDur == 0 then
        self.item.applied = true
        self.stacksText:SetText(buffStacks)
    elseif buffDur then
        if buffStacks ~= 0 then
            self.stacksText:SetText(buffStacks)
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
        self.item.applied = false
        self.texture:SetDesaturated(0)
    end
end

local UpdateFrame = function(self)
    local itemID = GetInventoryItemID("player", self.slotID)
    if not itemID then return self:Hide() end

    local item = ITEMS_CACHE[itemID] or newItem(itemID)
    self.item = item
    self:ResetFrame()
    self.no_swap_cd = item.CD == 0
    if self.no_swap_cd then
        self:SetScript("OnUpdate", nil)
    else
        self:SetScript("OnUpdate", OnUpdate)
    end

    self.stacksText:SetText()
    self.texture:SetTexture(item.icon)
    self.ilvl_text:SetText(item.ilvl)
    self.ilvl_text:SetTextColor(unpack(ITEM_QUALITY[item.quality]))

    local _, _, is_usable = GetInventoryItemCooldown("player", self.slotID)
    self.usable = is_usable == 1

    self:CheckAura(true)
    self:CheckItemUsed()
    if SETTINGS[self.nameID] == 1 then
        self:Show()
    end
end

local InventoryUpdated = function(self)
    if not self.item
    or self.item.applied
    or self.no_swap_cd
    or self.usable
    or not self.item.procInDB then return end

    local now = GetTime()
    if SETTINGS.FORCE30 == 0 then
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

local OnEvent = function(self, event, arg1, arg2)
    if event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        self:CheckAura()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        self:CheckItemUsed()
    elseif event == "ITEM_UNLOCKED" then
        if not self.swap_back_trigger then return end
        EquipItemByName(self.item.ID, self.slotID)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if arg1 ~= self.slotID then return end
        self:UpdateFrame()
        self:InventoryUpdated()
        if self.swap_back_trigger and arg2 then
            self.swap_back_trigger = false
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateFrame()
    elseif event == "PLAYER_DEAD" then
        self.first_check = false
    elseif event == "PLAYER_ALIVE" then
        if not self.first_check then return end
        self.first_check = false
        self:InventoryUpdated()
    end
end

local OnMouseDown = function(self, button)
    if button ~= "LeftButton" then return end
    if UnitAffectingCombat("player") then
        print(ADDON_NAME_COLOR .. "Leave combat to swap trinkets")
        return
    end
    if IsShiftKeyDown() then
        -- shift+left mouse swaps trinkets
        local slotID = self.slotID == 13 and 14 or 13
        EquipItemByName(self.item.ID, slotID)
    elseif IsAltKeyDown() then
        -- alt+left mouse swaps trinkets with same name: pnl 277 <-> 264
        local item_name = GetItemInfo(self.item.ID)
        EquipItemByName(item_name, self.slotID)
    elseif IsControlKeyDown() then
        -- ctrl+left mouse reequips current equipped trinket
        self.swap_back_trigger = true
        PickupInventoryItem(self.slotID)
        PutItemInBackpack()
    end
end

local newFontOverlay = function(parent)
    local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(1, -1)
    return font
end

local AddTextLayer = function(self)
    self.itemText = CreateFrame("Frame", nil, self)
    self.itemText:SetAllPoints()

    self.stacksText = newFontOverlay(self.itemText)
    self.stacksText:SetPoint("TOP", 0, floor(SETTINGS.ICON_SIZE/3))
    self.stacksText:SetWidth(SETTINGS.ICON_SIZE)
	self.stacksText:SetJustifyH("CENTER")

    self.ilvl_text = newFontOverlay(self.itemText)
    self.ilvl_text:SetPoint("BOTTOMRIGHT", 0, 2)
end

local RedrawFrame = function(self)
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

local create_new_item = function(slotID)
    local self = CreateFrame("Frame", ADDON_NAME..slotID)

    self.texture = self:CreateTexture(nil, "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")

    self.cooldown = CreateFrame("Cooldown", "Trinket"..slotID.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()

    self.border = CreateFrame("Frame", nil, self)
    self.border:SetFrameStrata("MEDIUM")

    AddTextLayer(self)

    self.slotID = slotID
    self.nameID = "TRINKET"..slotID
    self.first_check = true
    self.UpdateFrame = UpdateFrame
    self.ApplyItemCD = ApplyItemCD
    self.InventoryUpdated = InventoryUpdated
    self.ResetFrame = ResetFrame
    self.CheckAura = CheckAura
    self.CheckItemUsed = CheckItemUsed
    self.ItemBuffFaded = ItemBuffFaded
    self.ItemBuffApplied = ItemBuffApplied
    self.RedrawFrame = RedrawFrame

    self:RedrawFrame()

    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("ITEM_UNLOCKED")
    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("UNIT_AURA")
    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnMouseDown", OnMouseDown)
    self:EnableMouse(true)

    if SETTINGS[self.nameID] == 0 then
        self:Hide()
    end

    return self
end


function ADDON:OnEvent(event, arg1)
	if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end

        local t = _G[ADDON_PROFILE]
        if t then
            for key, _ in pairs(SETTINGS) do
                SETTINGS[key] = t[key] == true and 1 or t[key] or 0
            end
        end
        _G[ADDON_PROFILE] = SETTINGS

        FRAMES[13] = create_new_item(13)
        FRAMES[14] = create_new_item(14)
	end
end

ADDON:RegisterEvent("ADDON_LOADED")
ADDON:SetScript("OnEvent", ADDON.OnEvent)
