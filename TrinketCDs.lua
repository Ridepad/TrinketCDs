local POS_X = 125
local POS_Y = -140
local POS_MARGIN = 0
local ICON_SIZE = 28

local TRINKETS_CACHE = {}
local FRAMES = {}
local hands = GetSpellInfo(54758)
local hands_applied = false

local ITEM_QUALITY = {
    [3] = function() return 0.00, 0.44, 0.87 end,
    [4] = function() return 0.64, 0.21, 0.93 end,
}

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

local ashen_rings = {
    [50397] = 72416, -- SP DD
    [50398] = 72416,
    [50399] = 72418, -- SP Heal
    [50400] = 72418,
    [50401] = 72412, -- ATK AGI
    [50402] = 72412,
    [52571] = 72412, -- ATK STR
    [52572] = 72412,
    [50403] = 72414, -- TANK
    [50404] = 72414,
}

local cloaks = {
    [3722] = 55637, -- Lightweave
    [3730] = 55775, -- Swordguard
    [3728] = 55767, -- Darkglow
}

local trinket_CDs = {}
do
    local _CDs = {
        [0] = {
            37111,        -- Soul Preserver
            40432,        -- Illustration of the Dragon Soul
            45308,        -- Eye of the Broodmother
            50345, 50340, -- Muradin's Spyglass
            47432, 47271, -- Solace of the Fallen
            47059, 47041, -- Solace of the Defeated
            50706, 50351, -- Tiny Abomination in a Jar
            47477, 47316, -- Reign of the Dead
            47188, 47182, -- Reign of the Unliving
        },
        [45] = {
            47216,        -- The Black Heart
            50358,        -- Purified Lunar Dust
            54590, 54569, -- Sharpened Twilight Scale
            54591, 54571, -- Petrified Twilight Scale
            50348, 50353, -- Dislodged Foreign Object
        },
        [50] = {
            54588, 54572, -- Charred Twilight Scale
        },
        [100] = {
            50365, 50360, -- Phylactery of the Nameless Lich
        },
        [120] = {
            54589, 54573, -- Glowing Twilight Scale
            48724,        -- Talisman of Resurgence
            50260,        -- Ephemeral Snowflake
        },
    }
    for cd_duration, IDs in pairs(_CDs) do
        for _, item_id in ipairs(IDs) do
            trinket_CDs[item_id] = cd_duration
        end
    end
end

local trinket_buffs = {
    [54588] = 75473, -- Charred Twilight Scale
    [54572] = 75466,

    [54589] = 75495, -- Glowing Twilight Scale
    [54573] = 75490,

    [54590] = 75456, -- Sharpened Twilight Scale
    [54569] = 75458,

    [54591] = 75480, -- Petrified Twilight Scale
    [54571] = 75477,

    [50365] = 71636, -- Phylactery of the Nameless Lich
    [50360] = 71605,

    [50348] = 71644, -- Dislodged Foreign Object
    [50353] = 71601,

    [50345] = 71572, -- Muradin's Spyglass
    [50340] = 75473,

    [47432] = 67750, -- Solace of the Fallen
    [47271] = 67696,

    [47059] = 67750, -- Solace of the Defeated
    [47041] = 67696,

    [50706] = 71432, -- Tiny Abomination in a Jar
    [50351] = 71432,

    [47477] = 67759, -- Reign of the Dead
    [47316] = 67713,

    [47188] = 67759, -- Reign of the Unliving
    [47182] = 67713,

    [40432] = 60486, -- Illustration of the Dragon Soul
    [47213] = 67669, -- Abyssal Rune
    [44912] = 60064, -- Flow of Knowledge
    [40682] = 60064, -- Sundial of the Exiled
    [49076] = 60064, -- Mithril Pocketwatch
    [45308] = 65006, -- Eye of the Broodmother
    [50358] = 71584, -- Purified Lunar Dust
    [48724] = 67684, -- Talisman of Resurgence
    [37111] = 60515, -- Soul Preserver
    [47216] = 67631, -- The Black Heart
    [50260] = 71568, -- Ephemeral Snowflake
}

local items_without_swap_cd = {
    [40432] = true, -- Illustration of the Dragon Soul
    [37111] = true, -- Soul Preserver
    [50340] = true, -- Muradin's Spyglass
    [50345] = true,
    [50706] = true, -- Tiny Abomination in a Jar
    [50351] = true,
    [47432] = true, -- Solace of the Fallen
    [47271] = true,
    [47059] = true, -- Solace of the Defeated
    [47041] = true,
    [47477] = true, -- Reign of the Dead
    [47316] = true,
    [47188] = true, -- Reign of the Unliving
    [47182] = true,
}

local items_with_active = {
    [54589] = true,
    [54573] = true,
    [48724] = true,
}

local function get_trinket(item_id)
    local trink = TRINKETS_CACHE[item_id]
    if trink then return trink end
    local _, _, itemQuality, itemLevel, _, _, _, _, _, itemTexture = GetItemInfo(item_id)
    trink = {
        icon = itemTexture,
        ready = true,
        cd_finish = 0,
        cd = trinket_CDs[item_id],
        spell_id = trinket_buffs[item_id],
        quality = itemQuality,
        ilvl = itemLevel,
    }
    TRINKETS_CACHE[item_id] = trink
    return trink
end

local function apply_cd(self, trink, dur)
    trink.ready = false
    trink.applied = false
    trink.on_cd = true
    self.tex:SetDesaturated(1)
    self.stacks_text:SetText(nil)
    self.trinkCooldown:SetReverse(false)
    self.trinkCooldown:SetCooldown(trink.cd_start, dur)
end

local function reset_frame(self)
    self.tex:SetDesaturated(0)
    self.stacks_text:SetText(nil)
    self.trinkCooldown:SetReverse(false)
    self.trinkCooldown:SetCooldown(0, 0)
end

local function apply_swap_cd(self)
    local item_id = self.item_id
    if items_without_swap_cd[item_id] then
        return reset_frame(self)
    end
    local start, duration
    if items_with_active[item_id] then
        start, duration = GetInventoryItemCooldown("player", self.slot_id)
    end
    start = start or GetTime()
    duration = duration or 30
    local trink = get_trinket(item_id)
    trink.cd_start = start
    trink.cd_finish = start + duration
    apply_cd(self, trink, duration)
end

local function check_cd(slot_id)
    local frame = FRAMES[slot_id]
    if not frame then return end
    if not items_with_active[frame.item_id] then return end
    local trink = get_trinket(frame.item_id)
    if trink.applied then return end
    local start, duration = GetInventoryItemCooldown("player", slot_id)
    if start == 0 then return end
    trink.cd_start = start
    trink.cd_finish = start + duration
    apply_cd(frame, trink, duration)
end

local function trinket_buff_applied(self, duration, expirationTime)
    local trink = TRINKETS_CACHE[self.item_id]
    trink.ready = false
    trink.applied = true
    trink.on_cd = false
    local cd_start = expirationTime - duration
    trink.cd_start = cd_start
    if trink.cd == 0 then
        trink.cd_finish = expirationTime
    else
        trink.cd_finish = cd_start + trink.cd
    end
    self.tex:SetDesaturated(0)
    self.trinkCooldown:SetReverse(true)
    self.trinkCooldown:SetCooldown(cd_start, duration)
    local other_slot_id = self.slot_id == 13 and 14 or 13
    check_cd(other_slot_id)
end

local function trinket_buff_faded(self)
    local trink = get_trinket(self.item_id)
    if trink.cd ~= 0 and GetTime() < trink.cd_finish then
        apply_cd(self, trink, trink.cd)
    else
        trink.ready = true
        trink.applied = false
        reset_frame(self)
    end
end

local function check_hands()
    if UnitBuff("player", hands) then
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

local function check_if_trink_proc(self)
    if check_hands() then return end

    local trink = get_trinket(self.item_id)
    if not trink or trink.on_cd or not trink.spell_id then return end
    local buff_name = GetSpellInfo(trink.spell_id)
    local stacks, _, duration, expirationTime = select(4, UnitBuff("player", buff_name))
    if duration == 0 then
        trink.applied = true
        self.tex:SetDesaturated(0)
        self.stacks_text:SetText(stacks)
    elseif duration then
        if trink.cd_finish == expirationTime
        or trink.applied and stacks == 0 then return end
        trinket_buff_applied(self, duration, expirationTime)
        if stacks ~= 0 then
            self.stacks_text:SetText(stacks)
        end
    elseif trink.applied then
        trinket_buff_faded(self)
    end
end

local function update_frame(self)
    local item_id = GetInventoryItemID("player", self.slot_id)
    if not item_id then
        self:Hide()
        return
    end
    local trink = get_trinket(item_id)
    self.tex:SetTexture(trink.icon)
    self.stacks_text:SetText(nil)
    self.item_id = item_id
    self.ilvl_text:SetText(trink.ilvl)
    self.ilvl_text:SetTextColor(ITEM_QUALITY[trink.quality]())
    self:Show()
    return trink
end

local function cd_more_than_30(trink)
    return trink.on_cd and GetTime() + 30 < trink.cd_finish
end

local function OnEvent(self, event, arg1)
    if self.first_check then
        self.first_check = false
        update_frame(self)
        if event == "PLAYER_ALIVE" then
            apply_swap_cd(self)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if self.slot_id ~= arg1 then return end
        local trink = update_frame(self)
        if not trink then return end
        if cd_more_than_30(trink) then
            apply_cd(self, trink, trink.cd)
        else
            apply_swap_cd(self)
        end
    elseif event == "UNIT_AURA" then
        if arg1 ~= "player" then return end
        check_if_trink_proc(self)
    end
end

local function check_if_ready(self)
    local trink = TRINKETS_CACHE[self.item_id]
    if not trink
    or not trink.on_cd
    or GetTime() < trink.cd_finish
    then return end
    trink.ready = true
    trink.applied = false
    trink.on_cd = false
    self.tex:SetDesaturated(0)
end

local function swap_trinkets_slots(self)
    if UnitAffectingCombat("player") then return end
    -- shift+left mouse swaps trinkets
    if IsShiftKeyDown() then
        local slot_id = self.slot_id ~= 13 and 13 or 14
        EquipItemByName(self.item_id, slot_id)
    -- alt+left mouse swaps trinkets with same name line pnl
    elseif IsAltKeyDown() then
        local item_name = GetItemInfo(self.item_id)
        EquipItemByName(item_name, self.slot_id)
    end
end

local function create_new_frame(slot_id)
    local new_frame = CreateFrame("Frame")
    new_frame:SetSize(ICON_SIZE, ICON_SIZE)
    local x = slot_id == 13 and POS_X or POS_X + 35 + POS_MARGIN
    new_frame:SetPoint("CENTER", x, POS_Y)

    new_frame.slot_id = slot_id
    new_frame.first_check = true

    new_frame:RegisterEvent("PLAYER_ALIVE")
    new_frame:RegisterEvent("LFG_LOCK_INFO_RECEIVED")
    new_frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    new_frame:RegisterEvent("UNIT_AURA")
    new_frame:SetScript("OnEvent", OnEvent)

    new_frame:SetScript("OnUpdate", check_if_ready)

    new_frame:EnableMouse(true)
    new_frame:SetScript("OnMouseDown", swap_trinkets_slots)

    local zoom = 0.1
    local mooz = 1 - zoom
    new_frame.tex = new_frame:CreateTexture(nil, "BACKGROUND")
    new_frame.tex:SetAllPoints(new_frame)
    new_frame.tex:SetTexture("Interface/Icons/Trade_Engineering")
    new_frame.tex:SetTexCoord(zoom, zoom, zoom, mooz, mooz, zoom, mooz, mooz)

    new_frame.trinkCooldown = CreateFrame("Cooldown", "trinkCooldown", new_frame, "CooldownFrameTemplate")
    new_frame.trinkCooldown:SetAllPoints()

    local margin = 4
    new_frame.border = CreateFrame("Frame", nil, new_frame)
    new_frame.border:SetPoint("TOPLEFT", new_frame, -margin, margin)
    new_frame.border:SetPoint("BOTTOMRIGHT", new_frame, margin, -margin)
    new_frame.border:SetFrameStrata("LOW")
    new_frame.border:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        edgeSize = 16,
    })
    new_frame.border:SetBackdropBorderColor(0,0,0,1)

    new_frame.stacks_text = new_frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    new_frame.stacks_text:SetFont("Fonts/FRIZQT__.ttf", 14, "OUTLINE")
    new_frame.stacks_text:SetPoint("CENTER", 0, 18)

    new_frame.ilvl_text = new_frame:CreateFontString(nil, "OVERLAY")
    new_frame.ilvl_text:SetFont("Fonts/FRIZQT__.ttf", 8, "OUTLINE")
    new_frame.ilvl_text:SetPoint("CENTER", 7, -10)

    return new_frame
end
-- /run local x = GetInventoryItemLink('player', 15) local w = x:match("%d:(%d+)") print(w)
FRAMES[13] = create_new_frame(13)
FRAMES[14] = create_new_frame(14)
