local DB = {}
_G.TrinketCDsDB = DB

local trinket_CDs = {}
DB.trinket_CDs = trinket_CDs

local _CDs = {
    --  Heroic  Normal
    [0] = {
        47059,  47041, -- Solace of the Defeated
        47432,  47271, -- Solace of the Fallen
        47188,  47182, -- Reign of the Unliving
        47477,  47316, -- Reign of the Dead
        50345,  50340, -- Muradin's Spyglass
        50706,  50351, -- Tiny Abomination in a Jar
        50344,  50341, -- Unidentifiable Organ
                37111, -- Soul Preserver
                40430, -- Majestic Dragon Figurine
                40431, -- Fury of the Five Flights
                40432, -- Illustration of the Dragon Soul
                42989, -- Darkmoon Card: Berserker!
                45308, -- Eye of the Broodmother
                50355, -- Herkuml War Token
    },
    [50] = {
        54588,  54572, -- Charred Twilight Scale
    },
    [100] = {
        50365,  50360, -- Phylactery of the Nameless Lich
    },
    [105] = {
        50363,  50362, -- Deathbringer's Will
    },
}
for cd_duration, itemIDs in pairs(_CDs) do
    for _, itemID in ipairs(itemIDs) do
        trinket_CDs[itemID] = cd_duration
    end
end

DB.trinket_buffs = {
    [54588] = 75473, -- Charred Twilight Scale
    [54572] = 75466,
    [54590] = 75456, -- Sharpened Twilight Scale
    [54569] = 75458,
    [54591] = 75480, -- Petrified Twilight Scale
    [54571] = 75477,
    [50365] = 71636, -- Phylactery of the Nameless Lich
    [50360] = 71605,
    [50348] = 71644, -- Dislodged Foreign Object
    [50353] = 71601,
    [50345] = 71572, -- Muradin's Spyglass
    [50340] = 71570,
    [47432] = 67750, -- Solace of the Fallen
    [47271] = 67696,
    [47059] = 67750, -- Solace of the Defeated
    [47041] = 67696,
    [50706] = 71432, -- Tiny Abomination in a Jar
    [50351] = 71432,
    [50343] = 71541, -- Whispering Fanged Skull
    [50342] = 71401,
    [50344] = 71577, -- Unidentifiable Organ
    [50341] = 71575,
    [47477] = 67759, -- Reign of the Dead
    [47316] = 67713,
    [47188] = 67759, -- Reign of the Unliving
    [47182] = 67713,
    [50349] = 71639, -- Corpse Tongue Coin
    [50352] = 71633,

    [47213] = 67669, -- Abyssal Rune
    [47214] = 67671, -- Banner of Victory
    [50358] = 71584, -- Purified Lunar Dust
    [47216] = 67631, -- The Black Heart
    [40371] = 60443, -- Bandit's Insignia
    [45866] = 65004, -- Elemental Focus Stone
    [50355] = 71396, -- Herkuml War Token
    [44912] = 60064, -- Flow of Knowledge
    [40682] = 60064, -- Sundial of the Exiled
    [49076] = 60064, -- Mithril Pocketwatch
    [44914] = 60065, -- Anvil of Titans
    [40684] = 60065, -- Mirror of Truth
    [49074] = 60065, -- Coren's Chromium Coaster
    [37111] = 60515, -- Soul Preserver
    [40430] = 60525, -- Majestic Dragon Figurine
    [40431] = 60314, -- Fury of the Five Flights
    [40432] = 60486, -- Illustration of the Dragon Soul
    [45308] = 65006, -- Eye of the Broodmother
    [42989] = 60196, -- Darkmoon Card: Berserker!
    [37660] = 60479, -- Forge Ember
    [37657] = 60520, -- Spark of Life
    [45490] = 64741, -- Pandora's Plea
    [45286] = 65014, -- Pyrite Infuser
    [45929] = 65003, -- Sif's Remembrance
    [46038] = 65024, -- Dark Matter
    [45518] = 64713, -- Flare of the Heavens
    [45609] = 64772, -- Comet's Trail
    [40255] = 60494, -- Dying Curse
    [45131] = 63250, -- Jouster's Fury
    [45219] = 63250, -- Jouster's Fury
    [37390] = 60302, -- Meteorite Whetstone
    [40865] = 54808, -- Noise Machine
    [37264] = 60483, -- Pendulum of Telluric Currents
    [38675] = 52424, -- Signet of the Dark Brotherhood
    [40767] = 55018, -- Sonic Booster
    [38674] = 52419, -- Soul Harvester's Charm
    [37064] = 60307, -- Vestige of Haldor
    [39229] = 60492, -- Embrace of the Spider
    [43573] = 58904, -- Tears of Bitter Anguish
    [37835] = 49623, -- Je'Tze's Bell
    [37220] = 60218, -- Essence of Gossamer
    [40685] = 60062, -- The Egg of Mortal Essence
    [49078] = 60062, -- Ancient Pickled Egg
    [47215] = 67666, -- Tears of the Vanquished
    [40382] = 60538, -- Soul of the Dead
    [40256] = 60437, -- Grim Troll
    [40258] = 60530, -- Forethought Talisman
    [40373] = 60488, -- Extract of Necromantic Power
    [45507] = 64765, -- The General's Heart
    [45931] = 65019, -- Mjolnir Runestone
    [45522] = 64790, -- Blood of the Old God
    [50198] = 71403, -- Needle-Encrusted Scorpion
    [45535] = 64739, -- Show of Faith

    [54589] = 75495, -- Glowing Twilight Scale
    [54573] = 75490,
    [50364] = 71638, -- Sindragosa's Flawless Fang
    [50361] = 71635,
    [47451] = 67753, -- Juggernaut's Vitality
    [47290] = 67699,
    [47088] = 67753, -- Satrina's Impeding Scarab
    [47080] = 67699,
    [47879] = 67735, -- Fetish of Volatile Power
    [48018] = 67743,
    [47726] = 67735, -- Talisman of Volatile Power
    [47946] = 67743,
    [48021] = 67741, -- Eitrigg's Oath
    [47882] = 67727,
    [47949] = 67741, -- Fervor of the Frostborn
    [47727] = 67727,
    [48020] = 67746, -- Vengeance of the Forsaken
    [47881] = 67737,
    [47948] = 67746, -- Victor's Call
    [47725] = 67737,
    [48019] = 67739, -- Binding Stone
    [47880] = 67723,
    [47947] = 67739, -- Binding Light
    [47728] = 67723,

    [42128] = 55915, -- Battlemaster's Hostility
    [42129] = 55915, -- Battlemaster's Accuracy
    [42130] = 55915, -- Battlemaster's Avidity
    [42131] = 55915, -- Battlemaster's Conviction
    [42132] = 55915, -- Battlemaster's Bravery
    [42133] = 67596, -- Battlemaster's Fury
    [42134] = 67596, -- Battlemaster's Precision
    [42135] = 67596, -- Battlemaster's Vivacity
    [42136] = 67596, -- Battlemaster's Rage
    [42137] = 67596, -- Battlemaster's Ruination
    [50356] = 71586, -- Corroded Skeleton Key
    [50259] = 71564, -- Nevermelting Ice Crystal
    [48724] = 67684, -- Talisman of Resurgence
    [50260] = 71568, -- Ephemeral Snowflake
    [46051] = 64999, -- Meteorite Crystal
    [47734] = 67695, -- Mark of Supremacy
    [50235] = 71569, -- Ick's Rotting Thumb
    [49080] = 68443, -- Brawler's Souvenir
    [50357] = 71579, -- Maghia's Misguided Quill
    [38080] = 51978, -- Automated Weapon Coater
    [39811] = 62088, -- Badge of the Infiltrator
    [39819] = 48875, -- Bloodbinder's Runestone
    [35937] = 47217, -- Braxley's Backyard Moonshine
    [44013] = 59657, -- Cannoneer's Fuselighter
    [44015] = 59657, -- Cannoneer's Morale
    [43829] = 59345, -- Crusader's Locket
    [42988] = 57350, -- Darkmoon Card: Illusion
    [38212] = 54696, -- Death Knight's Anguish
    [40257] = 60286, -- Defender's Code
    [45292] = 65008, -- Energy Siphon
    [44014] = 59658, -- Fezzik's Pocketwatch
    [38070] = 51985, -- Foresight's Anticipation
    [45313] = 65011, -- Furnace Stone
    [37562] = 48868, -- Fury of the Crimson Drake
    [38763] = 61426, -- Futuresight Rune
    [47735] = 67694, -- Glyph of Indomitability
    [38213] = 48846, -- Harbinger's Wrath
    [45158] = 64763, -- Heart of Iron
    [39889] = 55747, -- Horn of Argent Fury
    [37723] = 60299, -- Incisor Fragment
    [35935] = 47215, -- Infused Coldstone Rune
    [38762] = 48875, -- Insignia of Bloody Fire
    [37872] = 60215, -- Lavanthor's Talisman
    [45148] = 64712, -- Living Flame
    [39257] = 60439, -- Loatheb's Shadow
    [40531] = 60319, -- Mark of Norgannon
    [37873] = 60480, -- Mark of the War Prisoner
    [38760] = 48875, -- Mendicant's Charm
    [37638] = 60180, -- Offering of Sacrifice
    [46086] = 64524, -- Platinum Disks of Battle
    [46087] = 64525, -- Platinum Disks of Sorcery
    [46088] = 64527, -- Platinum Disks of Swiftness
    [39292] = 60180, -- Repelling Charge
    [46021] = 65012, -- Royal Seal of King Llane
    [38764] = 61427, -- Rune of Finite Variation
    [38765] = 61428, -- Rune of Infinite Power
    [40372] = 60258, -- Rune of Repulsion
    [45466] = 64707, -- Scale of Fates
    [38081] = 51987, -- Scarab of Isanoth
    [36993] = 60214, -- Seal of the Pantheon
    [37559] = 54738, -- Serrah's Star
    [48722] = 67683, -- Shard of the Crystal Heart
    [43837] = 61617, -- Softly Glowing Orb
    [37166] = 60305, -- Sphere of Red Dragon's Blood
    [39388] = 60527, -- Spirit-World Glass
    [39821] = 48875, -- Spiritist's Focus
    [37556] = 48847, -- Talisman of the Tundra
    [37734] = 60517, -- Talisman of Troll Divinity
    [38761] = 61778, -- Talon of Hatred
    [43836] = 61620, -- Thorny Rose Brooch
    [37558] = 48855, -- Tidal Boon
    [36972] = 60471, -- Tome of Arcane Phenomena
    [38071] = 54839, -- Valonforth's Remembrance
    [40683] = 60054, -- Valor Medal of the First War
    [37560] = 48865, -- Vial of Renewal
    [37557] = 48848, -- Warsong's Fervor
    [37555] = 48846, -- Warsong's Wrath
    [38073] = 33662, -- Will of the Red Dragonflight
    [37844] = 60521, -- Winged Talisman
    [45263] = 64800, -- Wrathstone
    [42341] = 56121, -- Figurine - Ruby Hare
    [42395] = 68351, -- Figurine - Twilight Serpent
    [42413] = 56187, -- Figurine - Sapphire Owl
    [42418] = 56188, -- Figurine - Emerald Boar
    [44063] = 59757, -- Figurine - Monarch Crab
    [36871] = 47806, -- Fury of the Encroaching Storm
    [36872] = 47807, -- Mender of the Oncoming Dawn
    [36874] = 47816, -- Horn of the Herald
    [38257] = 47816, -- Strike of the Seas
    [38258] = 50261, -- Sailor's Knotted Charm
    [38259] = 50263, -- First Mate's Pocketwatch
    [24125] = 31039, -- Figurine - Dawnstone Crab
    [24126] = 31040, -- Figurine - Living Ruby Serpent
    [24127] = 48986, -- Figurine - Talasite Owl
    [24128] = 31047, -- Figurine - Nightseye Panther
    [37254] = 48333, -- Super Simian Sphere
    [19288] = 23684, -- Darkmoon Card: Blue Dragon (Vanilla)
}

--                 STR,   AGI,   INT,   SPI
local DARKMOON = {60229, 60233, 60234, 60235}
local DEATHS_HEROIC = {67772, 67773}
local DEATHS_NORMAL = {67703, 67708}
local DBW_HEROIC ={
    71556, -- agility
    71557, -- arp
    71558, -- ap
    71559, -- crit
    71560, -- haste
    71561, -- strength
}
local DBW_NORMAL= {
    71484, -- strength
    71485, -- agility
    71486, -- ap
    71487, -- arp
    71491, -- crit
    71492, -- haste
}

DB.multibuff = {
    [42987] = DARKMOON, -- Strength
    [44253] = DARKMOON, -- Agility
    [44254] = DARKMOON, -- Spirit
    [44255] = DARKMOON, -- Intellect
    [47464] = DEATHS_HEROIC,
    [47131] = DEATHS_HEROIC,
    [47303] = DEATHS_NORMAL,
    [47115] = DEATHS_NORMAL,
    [50363] = DBW_HEROIC,
    [50362] = DBW_NORMAL,
}

DB.buffs_with_stacks = {
    [71644] = 71643,
    [71601] = 71600,
    [64999] = 65000,
}

DB.ashen_rings = {
    [50397] = 72416, -- SP DD
    [50398] = 72416,
    [50399] = 72418, -- SP Heal
    [50400] = 72418,
    [50401] = 72412, -- ATK AGI
    [50402] = 72412,
    [50403] = 72414, -- TANK
    [50404] = 72414,
    [52571] = 72412, -- ATK STR
    [52572] = 72412,
}

DB.enchants = {
    ["3722"] = 55637, -- Lightweave
    ["3728"] = 55767, -- Darkglow
    ["3730"] = 55775, -- Swordguard
    ["3790"] = 59626, -- Black Magic
    ["2673"] = 27984, -- Mongoose
    ["5392"] = 64579, -- Blood Draining
    ["5393"] = 20034, -- Crusader
}
