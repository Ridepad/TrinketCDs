local DB = {}
_G.TrinketCDsDB = DB

local TRINKET_PROC_CD = {}
DB.TRINKET_PROC_CD = TRINKET_PROC_CD

local procs_grouped_by_CD = {
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
                38072, -- Thunder Capacitor
                32496, -- Memento of Tyrande
                28727, -- Pendant of the Violet Eye
                28785, -- The Lightning Capacitor
                31856, -- Darkmoon Card: Crusade
                31857, -- Darkmoon Card: Wrath
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
for cd_duration, itemIDs in pairs(procs_grouped_by_CD) do
    for _, itemID in pairs(itemIDs) do
        TRINKET_PROC_CD[itemID] = cd_duration
    end
end

DB.TRINKET_PROC_ID = {
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
    [40430] = 60525, -- Majestic Dragon Figurine
    [40431] = 60314, -- Fury of the Five Flights
    [40432] = 60486, -- Illustration of the Dragon Soul
    [45308] = 65006, -- Eye of the Broodmother
    [42989] = 60196, -- Darkmoon Card: Berserker!
    [45490] = 64741, -- Pandora's Plea
    [45286] = 65014, -- Pyrite Infuser
    [45929] = 65003, -- Sif's Remembrance
    [46038] = 65024, -- Dark Matter
    [45518] = 64713, -- Flare of the Heavens
    [45609] = 64772, -- Comet's Trail
    [40255] = 60494, -- Dying Curse
    [38675] = 52424, -- Signet of the Dark Brotherhood
    [38674] = 52419, -- Soul Harvester's Charm
    [39229] = 60492, -- Embrace of the Spider
    [43573] = 58904, -- Tears of Bitter Anguish
    [37835] = 49623, -- Je'Tze's Bell
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
    [42988] = 57350, -- Darkmoon Card: Illusion

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
    [40257] = 60286, -- Defender's Code
    [45292] = 65008, -- Energy Siphon
    [45313] = 65011, -- Furnace Stone
    [47735] = 67694, -- Glyph of Indomitability
    [45158] = 64763, -- Heart of Iron
    [45148] = 64712, -- Living Flame
    [39257] = 60439, -- Loatheb's Shadow
    [40531] = 60319, -- Mark of Norgannon
    [46086] = 64524, -- Platinum Disks of Battle
    [46087] = 64525, -- Platinum Disks of Sorcery
    [46088] = 64527, -- Platinum Disks of Swiftness
    [39292] = 60180, -- Repelling Charge
    [46021] = 65012, -- Royal Seal of King Llane
    [40372] = 60258, -- Rune of Repulsion
    [45466] = 64707, -- Scale of Fates
    [48722] = 67683, -- Shard of the Crystal Heart
    [39388] = 60527, -- Spirit-World Glass
    [40683] = 60054, -- Valor Medal of the First War
    [45263] = 64800, -- Wrathstone
    [37254] = 48333, -- Super Simian Sphere

    [37166] = 60305, -- Sphere of Red Dragon's Blood
    [37220] = 60218, -- Essence of Gossamer
    [37264] = 60483, -- Pendulum of Telluric Currents
    [37390] = 60302, -- Meteorite Whetstone
    [37638] = 60180, -- Offering of Sacrifice
    [37657] = 60520, -- Spark of Life
    [37660] = 60479, -- Forge Ember
    [37723] = 60299, -- Incisor Fragment
    [37734] = 60517, -- Talisman of Troll Divinity
    [37844] = 60521, -- Winged Talisman
    [37872] = 60215, -- Lavanthor's Talisman
    [37873] = 60480, -- Mark of the War Prisoner
    [42341] = 56121, -- Figurine - Ruby Hare
    [42395] = 68351, -- Figurine - Twilight Serpent
    [42413] = 56186, -- Figurine - Sapphire Owl
    [44063] = 59757, -- Figurine - Monarch Crab
    [45131] = 63250, -- Jouster's Fury
    [45219] = 63250, -- Jouster's Fury
    [36972] = 60471, -- Tome of Arcane Phenomena
    [36993] = 60214, -- Seal of the Pantheon
    [37064] = 60307, -- Vestige of Haldor
    [37111] = 60515, -- Soul Preserver
    [44013] = 59657, -- Cannoneer's Fuselighter
    [44014] = 59658, -- Fezzik's Pocketwatch
    [44015] = 59657, -- Cannoneer's Morale
    [40767] = 55018, -- Sonic Booster
    [40865] = 55019, -- Noise Machine
    [36871] = 47806, -- Fury of the Encroaching Storm
    [36872] = 47807, -- Mender of the Oncoming Dawn
    [36874] = 47816, -- Horn of the Herald
    [38257] = 47816, -- Strike of the Seas
    [38258] = 50261, -- Sailor's Knotted Charm
    [38259] = 50263, -- First Mate's Pocketwatch

    -- 174
    [38763] = 61426, -- Futuresight Rune
    [38764] = 61427, -- Rune of Finite Variation
    [38765] = 61428, -- Rune of Infinite Power
    [43829] = 59345, -- Crusader's Locket
    [43836] = 61620, -- Thorny Rose Brooch
    [43837] = 61617, -- Softly Glowing Orb
    [43838] = 61618, -- Chuchu's Tiny Box of Horrors
    -- 158
    [39811] = 62088, -- Badge of the Infiltrator
    [39819] = 48875, -- Bloodbinder's Runestone
    [39821] = 48875, -- Spiritist's Focus
    [39889] = 55747, -- Horn of Argent Fury
    -- 154
    [38760] = 48875, -- Mendicant's Charm
    [38761] = 61778, -- Talon of Hatred
    [38762] = 48875, -- Insignia of Bloody Fire
    -- 146
    [38070] = 51985, -- Foresight's Anticipation
    [38071] = 54839, -- Valonforth's Remembrance
    [38072] = 54842, -- Thunder Capacitor
    [38073] = 33662, -- Will of the Red Dragonflight
    [38080] = 51978, -- Automated Weapon Coater
    [38081] = 51987, -- Scarab of Isanoth
    -- 138
    [35935] = 47215, -- Infused Coldstone Rune
    [35937] = 47217, -- Braxley's Backyard Moonshine
    [37555] = 48846, -- Warsong's Wrath
    [37556] = 48847, -- Talisman of the Tundra
    [37557] = 48848, -- Warsong's Fervor
    [37558] = 48855, -- Tidal Boon
    [37559] = 54738, -- Serrah's Star
    [37560] = 48865, -- Vial of Renewal
    [37562] = 48868, -- Fury of the Crimson Drake
    [38212] = 54696, -- Death Knight's Anguish
    [38213] = 48846, -- Harbinger's Wrath

    -- TBC
    [44073] = 59821, -- Frenzyheart Insignia of Fury
    [44074] = 59789, -- Oracle Talisman of Ablution
    [41587] = 44055, -- Battlemaster's Celerity
    [41588] = 44055, -- Battlemaster's Aggression
    [41589] = 44055, -- Battlemaster's Resolve
    [41590] = 44055, -- Battlemaster's Courage
    [34427] = 45040, -- Blackened Naaru Sliver
    [34428] = 45049, -- Steely Naaru Sliver
    [34429] = 45042, -- Shifting Naaru Sliver
    [34430] = 45052, -- Glimmering Naaru Sliver
    [32483] = 40396, -- The Skull of Gul'dan
    [32496] = 37656, -- Memento of Tyrande
    [32485] = 40459, -- Ashtongue Talisman of Valor
    [32487] = 40487, -- Ashtongue Talisman of Swiftness
    [32488] = 40483, -- Ashtongue Talisman of Insight
    [32492] = 40461, -- Ashtongue Talisman of Lethality
    [32493] = 40480, -- Ashtongue Talisman of Shadows
    [32501] = 40464, -- Shadowmoon Insignia
    [32505] = 40477, -- Madness of the Betrayer
    [33828] = 43710, -- Tome of Diabolic Remedy
    [33829] = 43712, -- Hex Shrunken Head
    [33830] = 43713, -- Ancient Aqir Artifact
    [33831] = 43716, -- Berserker's Call
    [30446] = 58157, -- Solarian's Sapphire
    [30447] = 37198, -- Tome of Fiery Redemption
    [30448] = 37508, -- Talon of Al'ar
    [30450] = 37174, -- Warp-Spring Coil
    [30620] = 38325, -- Spyglass of the Hidden Fleet
    [30626] = 38348, -- Sextant of Unstable Currents
    [30627] = 42084, -- Tsunami Talisman
    [30629] = 38351, -- Scarab of Displacement
    [30665] = 40402, -- Earring of Soulful Meditation
    [28789] = 34747, -- Eye of Magtheridon
    [28830] = 34775, -- Dragonspine Trophy
    [35693] = 46780, -- Figurine - Empyrean Tortoise
    [35700] = 46783, -- Figurine - Crimson Serpent
    [35702] = 46784, -- Figurine - Shadowsong Panther
    [35703] = 46785, -- Figurine - Seaspray Albatross
    [28528] = 34519, -- Moroes' Lucky Pocket Watch
    [28590] = 38332, -- Ribbon of Sacrifice
    [28727] = 35095, -- Pendant of the Violet Eye
    [28785] = 37658, -- The Lightning Capacitor
    [34472] = 45053, -- Shard of Contempt
    [29370] = 35163, -- Icon of the Silver Crescent
    [29376] = 35165, -- Essence of the Martyr
    [29383] = 35166, -- Bloodlust Brooch
    [29387] = 35169, -- Gnomeregan Auto-Blocker 600
    [31856] = 39439, -- Darkmoon Card: Crusade
    [31857] = 39443, -- Darkmoon Card: Wrath

    [24125] = 31039, -- Figurine - Dawnstone Crab
    [24126] = 31040, -- Figurine - Living Ruby Serpent
    [24127] = 31045, -- Figurine - Talasite Owl
    [24128] = 31047, -- Figurine - Nightseye Panther
    [27529] = 33089, -- Figurine of the Colossus
    [27683] = 33370, -- Quagmirran's Eye
    [27770] = 39228, -- Argussian Compass
    [27828] = 33400, -- Warp-Scarab Brooch
    [28121] = 34106, -- Icon of Unyielding Courage
    [28190] = 33370, -- Scarab of the Infinite Cycle
    [28223] = 34000, -- Arcanist's Stone
    [28288] = 33807, -- Abacus of Violent Odds
    [28370] = 38346, -- Bangle of Endless Blessings
    [28418] = 34321, -- Shiffar's Nexus-Horn
    [29132] = 35337, -- Scryer's Bloodgem
    [29179] = 35337, -- Xi'ri's Gift
    [32534] = 40538, -- Brooch of the Immortal King
    [32654] = 40724, -- Crystalforged Trinket
    [32658] = 40729, -- Badge of Tenacity
    [27891] = 33479, -- Adamantine Figurine
    [28034] = 33649, -- Hourglass of the Unraveller
    [30300] = 36372, -- Dabiri's Enigma
    [24376] = 31771, -- Runed Fungalcap
    [28040] = 33662, -- Vengeance of the Illidari
    [28041] = 33667, -- Bladefist's Breadth
    [28042] = 33668, -- Regal Protectorate
    [21473] = 26166, -- Eye of Moam
    [24390] = 31794, -- Auslese's Light Channeler
    [21488] = 26168, -- Fetish of Chitinous Spikes

    [30340] = 36432, -- Starkiller's Bauble
    [30293] = 36347, -- Heavenly Inspiration
    [29776] = 35733, -- Core of Ar'kelos
    [25634] = 32367, -- Oshu'gun Relic
    [25628] = 32362, -- Ogre Mauler's Badge
    [25633] = 32362, -- Uniting Charm
    [31615] = 33662, -- Ancient Draenei Arcane Relic
    [31617] = 33667, -- Ancient Draenei War Talisman
    [25936] = 39201, -- Terokkar Tablet of Vim
    [25937] = 39200, -- Terokkar Tablet of Precision
    [25619] = 32355, -- Glowing Crystal Insignia
    [25620] = 32355, -- Ancient Crystal Talisman
    [25787] = 32600, -- Charm of Alacrity
    [25994] = 32955, -- Rune of Force
    [25995] = 32956, -- Star of Sha'naar
    [25996] = 32957, -- Emblem of Perseverance
    -- Classic
    [15867] = 19638, -- Prismcharm
    [21777] = 26600, -- Figurine - Emerald Owl
    [17774] = 21970, -- Mark of the Chosen
    [18951] = 12438, -- Evonice's Landin' Pilla
    [2820]  = 14530, -- Nifty Stopwatch
    [21756] = 26571, -- Figurine - Golden Hare
    [21748] = 26551, -- Figurine - Jade Owl
    [5079]  =  1139, -- Cold Basilisk Eye
    [4397]  =  4079, -- Gnomish Cloaking Device
    [21758] = 26576, -- Figurine - Black Pearl Panther
    [21760] = 26581, -- Figurine - Truesilver Crab
}

--                 STR    AGI    INT    SPI
local DARKMOON = {60229, 60233, 60234, 60235}
local DEATH_HEROIC = {67772, 67773}
local DEATH_NORMAL = {67703, 67708}
local DBW_HEROIC = {
    71556, -- agility
    71557, -- arp
    71558, -- ap
    71559, -- crit
    71560, -- haste
    71561, -- strength
}
local DBW_NORMAL = {
    71484, -- strength
    71485, -- agility
    71486, -- ap
    71487, -- arp
    71491, -- crit
    71492, -- haste
}

DB.TRINKET_PROC_MULTIBUFF = {
    [42987] = DARKMOON, -- Strength
    [44253] = DARKMOON, -- Agility
    [44254] = DARKMOON, -- Spirit
    [44255] = DARKMOON, -- Intellect
    [47464] = DEATH_HEROIC,
    [47131] = DEATH_HEROIC,
    [47303] = DEATH_NORMAL,
    [47115] = DEATH_NORMAL,
    [50363] = DBW_HEROIC,
    [50362] = DBW_NORMAL,
}

DB.TRINKET_PROC_STACKS = {
    [71644] = 71643,
    [71601] = 71600,
    [64999] = 65000,
    [45040] = 45041,
    [45042] = 45043,
}

DB.ASHEN_RINGS = {
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

DB.ENCHANTS = {
    ["3601"] = 54793, -- Frag Belt
    ["3604"] = 54758, -- Hyperspeed Accelerators
    ["3606"] = 54861, -- Nitro Boosts
    ["3722"] = 55637, -- Lightweave
    ["3730"] = 55775, -- Swordguard
    ["3790"] = 59626, -- Black Magic
    ["3789"] = 59620, -- Berserking
    ["2673"] = 28093, -- Mongoose
    ["3870"] = 64568, -- Blood Draining
    ["1900"] = 20007, -- Crusader
    ["3225"] = 42976, -- Executioner
    -- ["3728"] = 55767, -- Darkglow
}

DB.ENCHANT_PROC_CD = {
    [55637] = 60, -- Lightweave
    [55775] = 55, -- Swordguard
    [59626] = 35, -- Black Magic
    [20007] = 0,  -- Crusader
    [28093] = 0,  -- Mongoose
    [42976] = 0,  -- Executioner
    [59620] = 0,  -- Berserking
    [64568] = 0,  -- Blood Draining
    -- [55767] = 45, -- Darkglow
}

DB.ITEM_QUALITY = {
    [1] = {1.00, 1.00, 1.00},
    [2] = {0.12, 1.00, 0.00},
    [3] = {0.00, 0.44, 0.87},
    [4] = {0.66, 0.33, 1.00},
    [7] = {0.90, 0.80, 0.50},
}

DB.ITEM_PROC_TYPES = {
    [6] = "enchant",
    [8] = "enchant",
    [10] = "enchant",
    [11] = "ring",
    [12] = "ring",
    [13] = "trinket",
    [14] = "trinket",
    [15] = "enchant",
    [16] = "enchant",
}

DB.ITEM_GROUP = {
    [6] = "Belt",
    [8] = "Boots",
    [10] = "Hands",
    [11] = "Ring",
    [12] = "Ring",
    [13] = "Trinket1",
    [14] = "Trinket2",
    [15] = "Cloak",
    [16] = "Weapon",
}

local default_item_settings_table = function(x, y, size, edge, ilvl)
    return {
        SHOW = 1,
        SHOW_ILVL = ilvl,
        POS_X = x,
        POS_Y = y,
        ICON_SIZE = size,
        ZOOM = 0,
        BORDER_MARGIN = 0,
        EDGE_SIZE = edge,
        CD_SIZE = 40,
        ILVL_SIZE = 25,
        STACKS_SIZE = 50,
    }
end

DB.DEFAULT_SETTINGS = {
    ITEMS = {
        [13] = default_item_settings_table(128, -172, 44, 10, 1),
        [14] = default_item_settings_table(174, -172, 44, 10, 1),

         [6] = default_item_settings_table(121,  -70, 30,  7, 0),
        [10] = default_item_settings_table(151,  -70, 30,  7, 0),
         [8] = default_item_settings_table(181,  -70, 30,  7, 0),
        [11] = default_item_settings_table(136, -100, 30,  7, 0),
        [15] = default_item_settings_table(166, -100, 30,  7, 0),
        [16] = default_item_settings_table(150, -130, 30,  7, 0),
    },
    SWITCHES = {
        USE_ON_CLICK = 0,
        HIDE_READY = 0,
        COMBAT_ONLY = 0,
        STACKS_BOTTOM = 0,
        SHOW_DECIMALS = 0,
        FORCE30 = 0,
    },
}
