local POS_X = 125
local POS_Y = -155
local ICON_SIZE = 28
local POS_MARGIN = 7
local ZOOM = 0.1

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
        POS_X,
        POS_Y,
        ICON_SIZE
    },
    [14] = {
        POS_X + ICON_SIZE + POS_MARGIN,
        POS_Y,
        ICON_SIZE
    },
}

local TrinketsData = _G.TrinketsData
local trinket_CDs = TrinketsData.trinket_CDs
local trinket_buffs = TrinketsData.trinket_buffs
local multibuff = TrinketsData.multibuff

SLASH_RIDEPAD_TRINKETS1 = "/tcdp"
SlashCmdList["RIDEPAD_TRINKETS"] = function()
    UpdateAddOnCPUUsage()
    local msg = "[TrinketCDs] Total seconds in addon:"
    msg = string.format("%s\n%.3f", msg, GetAddOnCPUUsage("TrinketCDs") / 1000)
    for _, frame in pairs(FRAMES) do
        local t, c = GetFrameCPUUsage(frame)
        msg = string.format("%s\n%.3f %d", msg, t / 1000, c)
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
        quality = itemQuality,
        ilvl = itemLevel,
        spellID = trinket_buffs[itemID],
        cd = trinket_CDs[itemID] or 45,
        cd_finish = 0,
    }
    ITEMS_CACHE[itemID] = item
    return item
end

local reset_frame = function(self)
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

local get_cd = function(self)
    if not self.active then
        return GetTime(), 30
    end
    local start, duration = GetInventoryItemCooldown("player", self.slotID)
    return start, duration
end

local apply_swap_cd = function(self)
    if self.no_swap_cd then
        return reset_frame(self)
    end
    local start, duration = get_cd(self)
    self.item.cd_start = start
    self.item.cd_finish = start + duration
    self:apply_cd(duration)
end

local check_cd = function(slotID)
    local self = FRAMES[slotID]
    if not self or not self.active then return end
    if self.item.applied then return end
    local start, duration = GetInventoryItemCooldown("player", slotID)
    if start == 0 then return end
    self.item.cd_start = start
    self.item.cd_finish = start + duration
    self:apply_cd(duration)
end

local hands_applied
local HANDS = GetSpellInfo(54758)
local check_hands_buff = function()
    if UnitBuff("player", HANDS) then
        if not hands_applied then
            hands_applied = true
            check_cd(13)
            check_cd(14)
            return true
        end
    elseif hands_applied then
        hands_applied = false
    end
end

local bbbuff = function(spellID)
    local buff_name = GetSpellInfo(spellID)
    local stacks, _, duration, expirationTime = select(4, UnitBuff("player", buff_name))
    return stacks, duration, expirationTime
end

local check_buff = function(itemID, spellID)
    local stacks, duration, expirationTime
    local buffs = multibuff[itemID]
    if buffs then
        for _, buffID in pairs(buffs) do
            stacks, duration, expirationTime = bbbuff(buffID)
            if duration then break end
        end
    elseif spellID then
        stacks, duration, expirationTime = bbbuff(spellID)
    end
    return stacks, duration, expirationTime
end

local buff_applied = function(self, duration, expirationTime)
    local item = self.item
    item.ready = false
    item.applied = true
    item.on_cd = false
    local cd_start = expirationTime - duration
    item.cd_start = cd_start
    item.cd_finish = self.no_swap_cd and expirationTime or cd_start + item.cd
    self.texture:SetDesaturated(0)
    self.cooldown:SetReverse(true)
    self.cooldown:SetCooldown(cd_start, duration)
    local other_slot_id = self.slotID == 13 and 14 or 13
    check_cd(other_slot_id)
end

local buff_faded = function(self)
    if self.no_swap_cd then
        self.item.ready = true
        self.item.applied = false
        self:reset_frame()
    elseif self.active then
        local start, duration = GetInventoryItemCooldown("player", self.slotID)
        self.item.cd = duration
        self.item.cd_finish = start + duration
        self:apply_cd(duration)
    else
        self:apply_cd(self.item.cd)
    end
end

local check_new_aura = function(self)
    if check_hands_buff() then return end

    local stacks, duration, expirationTime = check_buff(self.itemID, self.item.spellID)
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

local update_frame = function(self)
    local itemID = GetInventoryItemID("player", self.slotID)
    if not itemID then return self:Hide() end

    local item = get_item(itemID)
    local _, _, is_active = GetInventoryItemCooldown("player", self.slotID)
    self.item = item
    self.itemID = itemID
    self.active = is_active == 1
    self.no_swap_cd = item.cd == 0
    self.texture:SetTexture(item.icon)
    self.stacksText:SetText()
    self.ilvl_text:SetText(item.ilvl)
    self.ilvl_text:SetTextColor(unpack(ITEM_QUALITY[item.quality]))
    self:Show()
end

local function OnEvent(self, event, arg1)
    if self.first_check then
        self.first_check = false
        self:update_frame()
        if event == "PLAYER_ALIVE" then
            self:apply_swap_cd()
        end
    elseif arg1 == "player" and event == "UNIT_AURA" then
        self:check_new_aura()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if self.slotID ~= arg1 then return end
        self:update_frame()
        if self.item.on_cd and GetTime() + 30 < self.item.cd_finish then
            self:apply_cd(self.item.cd)
        else
            self:apply_swap_cd()
        end
    end
end

local function OnUpdate(self)
    local item = self.item
    if item and item.on_cd and GetTime() > item.cd_finish then
        item.ready = true
        item.applied = false
        item.on_cd = false
        self.texture:SetDesaturated(0)
    end
end

local function OnMouseDown(self, button)
    if UnitAffectingCombat("player") then
        print('Leave combat to swap trinkets')
        return
    end
    if button ~= "LeftButton" then return end
    -- shift+left mouse swaps trinkets
    if IsShiftKeyDown() then
        local slotID = self.slotID ~= 13 and 13 or 14
        EquipItemByName(self.itemID, slotID)
    -- alt+left mouse swaps trinkets with same name: pnl 277 <-> 264
    elseif IsAltKeyDown() then
        local item_name = GetItemInfo(self.itemID)
        EquipItemByName(item_name, self.slotID)
    end
end

local function add_text(self)
    self.itemText = CreateFrame("Frame", nil, self)
    self.itemText:SetAllPoints()

    self.stacksText = self.itemText:CreateFontString(nil, "OVERLAY")
    self.stacksText:SetFont("Fonts/FRIZQT__.ttf", floor(ICON_SIZE/2), "OUTLINE")
    self.stacksText:SetPoint("TOP", self, "TOP", 0, floor(ICON_SIZE/3))

    self.ilvl_text = self.itemText:CreateFontString(nil, "OVERLAY")
    self.ilvl_text:SetFont("Fonts/FRIZQT__.ttf", 8, "OUTLINE")
    self.ilvl_text:SetPoint("BOTTOMLEFT")
end

local function create_new_item(slotID)
    local x, y, size = unpack(COORDS[slotID])
    local self = CreateFrame("Frame", "Trinket"..slotID)
    self:SetSize(size, size)
    self:SetPoint("CENTER", x, y)

    local mooz = 1 - ZOOM
    self.texture = self:CreateTexture(nil, "OVERLAY")
    self.texture:SetAllPoints()
    self.texture:SetTexture("Interface/Icons/Trade_Engineering")
    self.texture:SetTexCoord(ZOOM, ZOOM, ZOOM, mooz, mooz, ZOOM, mooz, mooz)

    self.cooldown = CreateFrame("Cooldown", "Trinket"..slotID.."Cooldown", self, "CooldownFrameTemplate")
    self.cooldown:SetAllPoints()

    local margin = (size/8-size%1)
    self.border = CreateFrame("Frame", nil, self)
    self.border:SetPoint("TOPLEFT", self, -margin, margin)
    self.border:SetPoint("BOTTOMRIGHT", self, margin, -margin)
    self.border:SetFrameStrata("MEDIUM")
    self.border:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        edgeSize = size/2,
    })
    self.border:SetBackdropBorderColor(0,0,0,1)

    self.slotID = slotID
    self.first_check = true
    self.apply_cd = apply_cd
    self.apply_swap_cd = apply_swap_cd
    self.reset_frame = reset_frame
    self.update_frame = update_frame
    self.check_new_aura = check_new_aura
    self.buff_faded = buff_faded
    self.buff_applied = buff_applied
    self.get_cd = get_cd

    self:RegisterEvent("PLAYER_ALIVE")
    self:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    self:RegisterEvent("UNIT_AURA")
    self:SetScript("OnEvent", OnEvent)
    self:SetScript("OnUpdate", OnUpdate)
    self:SetScript("OnMouseDown", OnMouseDown)
    self:EnableMouse(true)

    return self
end

for i=13,14 do
    local f = create_new_item(i)
    add_text(f)
    FRAMES[i] = f
end
