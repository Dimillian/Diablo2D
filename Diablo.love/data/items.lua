local Items = {}

Items.rarities = {
    common = {
        id = "common",
        label = "Common",
        weight = 80,
        prefixCount = 0,
        suffixCount = 0,
    },
    uncommon = {
        id = "uncommon",
        label = "Uncommon",
        weight = 20,
        prefixCount = 1,
        suffixCount = 1,
    },
    rare = {
        id = "rare",
        label = "Rare",
        weight = 7,
        prefixCount = 1,
        suffixCount = 1,
    },
    epic = {
        id = "epic",
        label = "Epic",
        weight = 3,
        prefixCount = 2,
        suffixCount = 1,
    },
    legendary = {
        id = "legendary",
        label = "Legendary",
        weight = 1,
        prefixCount = 2,
        suffixCount = 2,
    },
}

Items.types = {
    sword = {
        id = "sword",
        label = "Sword",
        slot = "weapon",
        base = {
            damage = { min = 6, max = 10 },
            defense = 0,
        },
    },
    axe = {
        id = "axe",
        label = "Axe",
        slot = "weapon",
        base = {
            damage = { min = 8, max = 12 },
            defense = 0,
        },
    },
    hammer = {
        id = "hammer",
        label = "Hammer",
        slot = "weapon",
        base = {
            damage = { min = 10, max = 14 },
            defense = 0,
        },
    },
    dagger = {
        id = "dagger",
        label = "Dagger",
        slot = "weapon",
        base = {
            damage = { min = 4, max = 7 },
            defense = 0,
            critChance = 0.05,
        },
    },
    helmet = {
        id = "helmet",
        label = "Helmet",
        slot = "head",
        base = {
            damage = { min = 0, max = 0 },
            defense = { min = 3, max = 5 },
        },
    },
    chest = {
        id = "chest",
        label = "Chest Armor",
        slot = "chest",
        base = {
            damage = { min = 0, max = 0 },
            defense = { min = 6, max = 10 },
        },
    },
    boots = {
        id = "boots",
        label = "Boots",
        slot = "feet",
        base = {
            damage = { min = 0, max = 0 },
            defense = { min = 2, max = 4 },
            moveSpeed = 0.05,
        },
    },
    gloves = {
        id = "gloves",
        label = "Gloves",
        slot = "gloves",
        base = {
            damage = { min = 0, max = 0 },
            defense = { min = 2, max = 4 },
        },
    },
    ring = {
        id = "ring",
        label = "Ring",
        slot = "ring",
        base = {
            damage = { min = 0, max = 0 },
            defense = 0,
        },
    },
    amulet = {
        id = "amulet",
        label = "Amulet",
        slot = "amulet",
        base = {
            damage = { min = 0, max = 0 },
            defense = 0,
        },
    },
    health_potion = {
        id = "health_potion",
        label = "Health Potion",
        slot = "consumable",
        consumable = true,
        restoreHealth = 25,
        base = {
            damage = { min = 0, max = 0 },
            defense = 0,
        },
        excludeFromRandom = true,
    },
    mana_potion = {
        id = "mana_potion",
        label = "Mana Potion",
        slot = "consumable",
        consumable = true,
        restoreMana = 15,
        base = {
            damage = { min = 0, max = 0 },
            defense = 0,
        },
        excludeFromRandom = true,
    },
}

Items.prefixes = {
    {
        name = "Furious",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            damage = { flat = { 2, 4 } },
        },
    },
    {
        name = "Jagged",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            damage = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "Precise",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            critChance = { flat = { 0.03, 0.07 } },
        },
    },
    {
        name = "Guarded",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            defense = { flat = { 2, 4 } },
        },
    },
    {
        name = "Swift",
        slots = { "feet" },
        maxRarity = "uncommon",
        stats = {
            moveSpeed = { percent = { 0.05, 0.1 } },
        },
    },
    {
        name = "Bloodthirsty",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            lifeSteal = { percent = { 0.01, 0.04 } },
        },
    },
    {
        name = "Balanced",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            attackSpeed = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "Stalwart",
        slots = { "head", "chest", "gloves" },
        maxRarity = "uncommon",
        stats = {
            health = { flat = { 15, 30 } },
        },
    },
    {
        name = "Reinforced",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            defense = { percent = { 0.1, 0.2 } },
        },
    },
    {
        name = "Windrunner",
        slots = { "feet" },
        minRarity = "uncommon",
        stats = {
            moveSpeed = { percent = { 0.12, 0.2 } },
            dodgeChance = { flat = { 0.02, 0.05 } },
        },
    },
    {
        name = "Swift Strikes",
        slots = { "gloves" },
        maxRarity = "uncommon",
        stats = {
            attackSpeed = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "Enchanted",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            critChance = { flat = { 0.02, 0.08 } },
            attackSpeed = { percent = { 0.03, 0.07 } },
        },
    },
    {
        name = "Fortified",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            health = { flat = { 25, 45 } },
            defense = { flat = { 3, 6 } },
        },
    },
    {
        name = "Warding",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            resistAll = { percent = { 0.04, 0.08 } },
            dodgeChance = { flat = { 0.02, 0.04 } },
        },
    },
    -- Rare tier prefixes (higher stats)
    {
        name = "Savage",
        slots = { "weapon" },
        minRarity = "rare",
        stats = {
            damage = { flat = { 6, 10 } },
            critChance = { flat = { 0.05, 0.1 } },
        },
    },
    {
        name = "Titanic",
        slots = { "head", "chest", "gloves" },
        minRarity = "rare",
        stats = {
            health = { flat = { 40, 65 } },
            defense = { flat = { 5, 8 } },
        },
    },
    {
        name = "Stonewall",
        slots = { "head", "chest", "feet" },
        minRarity = "rare",
        stats = {
            defense = { percent = { 0.14, 0.22 } },
            health = { flat = { 30, 55 } },
        },
    },
    {
        name = "Spellward",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "rare",
        stats = {
            resistAll = { percent = { 0.12, 0.18 } },
            dodgeChance = { flat = { 0.03, 0.06 } },
        },
    },
    {
        name = "Celerity",
        slots = { "feet" },
        minRarity = "rare",
        stats = {
            moveSpeed = { percent = { 0.15, 0.25 } },
            dodgeChance = { flat = { 0.06, 0.1 } },
        },
    },
    {
        name = "Venomous",
        slots = { "weapon" },
        minRarity = "rare",
        stats = {
            damage = { percent = { 0.15, 0.25 } },
            lifeSteal = { percent = { 0.04, 0.08 } },
        },
    },
    {
        name = "Warlord",
        slots = { "weapon" },
        minRarity = "rare",
        stats = {
            damage = { flat = { 8, 12 } },
            attackSpeed = { percent = { 0.12, 0.2 } },
        },
    },
    {
        name = "Razorclaw",
        slots = { "gloves" },
        minRarity = "rare",
        stats = {
            critChance = { flat = { 0.06, 0.1 } },
            attackSpeed = { percent = { 0.1, 0.16 } },
        },
    },
    {
        name = "Sanctified",
        slots = { "ring", "amulet" },
        minRarity = "rare",
        stats = {
            resistAll = { percent = { 0.1, 0.18 } },
            health = { flat = { 35, 60 } },
        },
    },
    -- Epic tier prefixes (even higher stats, some with 3 stats)
    {
        name = "Annihilating",
        slots = { "weapon" },
        minRarity = "epic",
        stats = {
            damage = { flat = { 12, 18 } },
            critChance = { flat = { 0.08, 0.15 } },
            attackSpeed = { percent = { 0.15, 0.25 } },
        },
    },
    {
        name = "Impervious",
        slots = { "head", "chest", "feet" },
        minRarity = "epic",
        stats = {
            defense = { flat = { 8, 12 } },
            resistAll = { percent = { 0.12, 0.2 } },
            health = { flat = { 50, 80 } },
        },
    },
    {
        name = "Aegisforged",
        slots = { "head", "chest", "feet" },
        minRarity = "epic",
        stats = {
            defense = { percent = { 0.22, 0.3 } },
            resistAll = { percent = { 0.14, 0.22 } },
            health = { flat = { 45, 70 } },
        },
    },
    {
        name = "Soulguard",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "epic",
        stats = {
            health = { flat = { 60, 90 } },
            resistAll = { percent = { 0.12, 0.18 } },
            dodgeChance = { flat = { 0.06, 0.1 } },
        },
    },
    {
        name = "Transcendent",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            critChance = { flat = { 0.1, 0.18 } },
            attackSpeed = { percent = { 0.12, 0.2 } },
            lifeSteal = { percent = { 0.05, 0.1 } },
        },
    },
    {
        name = "Ethereal",
        slots = { "feet" },
        minRarity = "epic",
        stats = {
            moveSpeed = { percent = { 0.2, 0.3 } },
            dodgeChance = { flat = { 0.1, 0.15 } },
            resistAll = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "Stormfist",
        slots = { "gloves" },
        minRarity = "epic",
        stats = {
            attackSpeed = { percent = { 0.16, 0.24 } },
            critChance = { flat = { 0.08, 0.14 } },
            lifeSteal = { percent = { 0.04, 0.07 } },
        },
    },
    {
        name = "Vengeful",
        slots = { "weapon" },
        minRarity = "epic",
        stats = {
            damage = { percent = { 0.2, 0.35 } },
            critChance = { flat = { 0.1, 0.15 } },
            lifeSteal = { percent = { 0.06, 0.12 } },
        },
    },
    -- Legendary tier prefixes (highest stats, some with 4 stats)
    {
        name = "Worldbreaker",
        slots = { "weapon" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            damage = { flat = { 16, 24 } },
            critChance = { flat = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.18, 0.3 } },
            lifeSteal = { percent = { 0.06, 0.12 } },
        },
    },
    {
        name = "Godslayer",
        slots = { "weapon" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            damage = { percent = { 0.22, 0.38 } },
            critChance = { flat = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.18, 0.3 } },
        },
    },
    {
        name = "Unbreakable",
        slots = { "head", "chest", "feet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            defense = { flat = { 10, 18 } },
            health = { flat = { 80, 130 } },
            resistAll = { percent = { 0.14, 0.26 } },
            dodgeChance = { flat = { 0.08, 0.16 } },
        },
    },
    {
        name = "Bastion",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            defense = { percent = { 0.24, 0.34 } },
            health = { flat = { 90, 150 } },
            resistAll = { percent = { 0.16, 0.26 } },
            dodgeChance = { flat = { 0.1, 0.16 } },
        },
    },
    {
        name = "Wardbreaker",
        slots = { "head", "chest", "feet" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            defense = { flat = { 12, 20 } },
            resistAll = { percent = { 0.18, 0.28 } },
            health = { flat = { 80, 130 } },
            attackSpeed = { percent = { 0.1, 0.16 } },
        },
    },
    {
        name = "Invincible",
        slots = { "head", "chest", "feet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            defense = { percent = { 0.22, 0.32 } },
            health = { flat = { 90, 150 } },
            resistAll = { percent = { 0.18, 0.3 } },
        },
    },
    {
        name = "Ascendant",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            critChance = { flat = { 0.16, 0.26 } },
            attackSpeed = { percent = { 0.16, 0.28 } },
            lifeSteal = { percent = { 0.08, 0.16 } },
            health = { flat = { 80, 120 } },
        },
    },
    {
        name = "Divine",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            health = { flat = { 90, 140 } },
            resistAll = { percent = { 0.16, 0.28 } },
            dodgeChance = { flat = { 0.1, 0.18 } },
        },
    },
    {
        name = "Celestial",
        slots = { "feet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            moveSpeed = { percent = { 0.24, 0.36 } },
            dodgeChance = { flat = { 0.12, 0.2 } },
            resistAll = { percent = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.08, 0.14 } },
        },
    },
    {
        name = "Overlord",
        slots = { "gloves" },
        minRarity = "legendary",
        weight = 0.5,
        stats = {
            critChance = { flat = { 0.12, 0.18 } },
            attackSpeed = { percent = { 0.18, 0.28 } },
            lifeSteal = { percent = { 0.06, 0.1 } },
            damage = { flat = { 6, 10 } },
        },
    },
    {
        name = "Omnipotent",
        slots = { "weapon", "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            damage = { percent = { 0.12, 0.2 } },
            critChance = { flat = { 0.1, 0.18 } },
            attackSpeed = { percent = { 0.12, 0.22 } },
            health = { flat = { 60, 100 } },
        },
    },
}

Items.suffixes = {
    {
        name = "of Vitality",
        slots = { "head", "chest", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            health = { flat = { 10, 20 } },
        },
    },
    {
        name = "of the Fox",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            dodgeChance = { flat = { 0.01, 0.05 } },
        },
    },
    {
        name = "of the Bear",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            defense = { percent = { 0.03, 0.09 } },
        },
    },
    {
        name = "of Greed",
        slots = { "weapon", "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            goldFind = { percent = { 0.1, 0.25 } },
        },
    },
    {
        name = "of Carnage",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            damage = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of Ferocity",
        slots = { "weapon" },
        maxRarity = "uncommon",
        stats = {
            damage = { flat = { 3, 6 } },
        },
    },
    {
        name = "of the Sentinel",
        slots = { "head", "chest", "gloves", "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            health = { flat = { 20, 35 } },
            defense = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of Phasing",
        slots = { "feet" },
        minRarity = "uncommon",
        stats = {
            moveSpeed = { percent = { 0.08, 0.15 } },
            dodgeChance = { flat = { 0.04, 0.08 } },
        },
    },
    {
        name = "of Resolve",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            resistAll = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "of Power",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            critChance = { flat = { 0.03, 0.07 } },
            attackSpeed = { percent = { 0.03, 0.06 } },
        },
    },
    {
        name = "of Regeneration",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            health = { flat = { 30, 50 } },
            lifeSteal = { percent = { 0.02, 0.05 } },
        },
    },
    {
        name = "of Evasion",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            dodgeChance = { flat = { 0.05, 0.1 } },
            moveSpeed = { percent = { 0.05, 0.1 } },
        },
    },
    {
        name = "of the Arcane",
        slots = { "ring", "amulet" },
        maxRarity = "uncommon",
        stats = {
            manaRegen = { flat = { 0.25, 0.5 } },
        },
    },
    {
        name = "of the Mage",
        slots = { "ring", "amulet" },
        minRarity = "uncommon",
        stats = {
            manaRegen = { flat = { 0.2, 0.4 } },
            mana = { flat = { 10, 20 } },
        },
    },
    -- Rare tier suffixes (higher stats)
    {
        name = "of Slaughter",
        slots = { "weapon" },
        minRarity = "rare",
        stats = {
            damage = { flat = { 10, 16 } },
            critChance = { flat = { 0.08, 0.12 } },
        },
    },
    {
        name = "of the Titans",
        slots = { "head", "chest", "gloves" },
        minRarity = "rare",
        stats = {
            health = { flat = { 50, 80 } },
            defense = { percent = { 0.15, 0.25 } },
        },
    },
    {
        name = "of the Wind",
        slots = { "feet" },
        minRarity = "rare",
        stats = {
            moveSpeed = { percent = { 0.2, 0.3 } },
            dodgeChance = { flat = { 0.08, 0.12 } },
        },
    },
    {
        name = "of the Void",
        slots = { "ring", "amulet" },
        minRarity = "rare",
        stats = {
            critChance = { flat = { 0.08, 0.15 } },
            attackSpeed = { percent = { 0.1, 0.18 } },
            lifeSteal = { percent = { 0.04, 0.08 } },
        },
    },
    {
        name = "of the Sage",
        slots = { "ring", "amulet" },
        minRarity = "rare",
        stats = {
            manaRegen = { flat = { 0.5, 1.0 } },
        },
    },
    {
        name = "of the Enchanter",
        slots = { "ring", "amulet" },
        minRarity = "rare",
        stats = {
            manaRegen = { flat = { 0.4, 0.8 } },
            critChance = { flat = { 0.05, 0.1 } },
        },
    },
    {
        name = "of the Wizard",
        slots = { "ring", "amulet" },
        minRarity = "rare",
        stats = {
            manaRegen = { flat = { 0.3, 0.6 } },
            mana = { flat = { 15, 30 } },
            attackSpeed = { percent = { 0.05, 0.1 } },
        },
    },
    {
        name = "of Dominance",
        slots = { "weapon" },
        minRarity = "rare",
        stats = {
            damage = { percent = { 0.18, 0.3 } },
            attackSpeed = { percent = { 0.12, 0.2 } },
        },
    },
    -- Epic tier suffixes (even higher stats, some with 3 stats)
    {
        name = "of Annihilation",
        slots = { "weapon" },
        minRarity = "epic",
        stats = {
            damage = { flat = { 15, 25 } },
            critChance = { flat = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.18, 0.3 } },
        },
    },
    {
        name = "of the Ancients",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "epic",
        stats = {
            defense = { flat = { 12, 18 } },
            health = { flat = { 70, 110 } },
            resistAll = { percent = { 0.15, 0.25 } },
        },
    },
    {
        name = "of Perfection",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            critChance = { flat = { 0.15, 0.25 } },
            attackSpeed = { percent = { 0.15, 0.25 } },
            lifeSteal = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of Immortality",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            health = { flat = { 80, 120 } },
            lifeSteal = { percent = { 0.1, 0.18 } },
            resistAll = { percent = { 0.12, 0.2 } },
        },
    },
    {
        name = "of the Mystic",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            manaRegen = { flat = { 1.0, 1.5 } },
        },
    },
    {
        name = "of the Sorcerer",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            manaRegen = { flat = { 0.8, 1.2 } },
            critChance = { flat = { 0.1, 0.15 } },
            attackSpeed = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of the Adept",
        slots = { "ring", "amulet" },
        minRarity = "epic",
        stats = {
            manaRegen = { flat = { 0.6, 1.0 } },
            mana = { flat = { 25, 45 } },
            health = { flat = { 40, 70 } },
        },
    },
    {
        name = "of Transcendence",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        minRarity = "epic",
        stats = {
            health = { flat = { 60, 100 } },
            defense = { percent = { 0.2, 0.35 } },
            dodgeChance = { flat = { 0.1, 0.18 } },
        },
    },
    -- Legendary tier suffixes (highest stats, some with 4 stats)
    {
        name = "of the End",
        slots = { "weapon" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            damage = { flat = { 18, 28 } },
            critChance = { flat = { 0.14, 0.22 } },
            attackSpeed = { percent = { 0.18, 0.3 } },
            lifeSteal = { percent = { 0.07, 0.12 } },
        },
    },
    {
        name = "of Eternity",
        slots = { "weapon" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            damage = { percent = { 0.24, 0.4 } },
            critChance = { flat = { 0.14, 0.24 } },
            attackSpeed = { percent = { 0.2, 0.32 } },
        },
    },
    {
        name = "of the Immortals",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            defense = { flat = { 16, 24 } },
            health = { flat = { 110, 160 } },
            resistAll = { percent = { 0.18, 0.3 } },
            dodgeChance = { flat = { 0.12, 0.2 } },
        },
    },
    {
        name = "of the Gods",
        slots = { "head", "chest", "feet", "gloves" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            defense = { percent = { 0.28, 0.4 } },
            health = { flat = { 120, 180 } },
            resistAll = { percent = { 0.22, 0.35 } },
        },
    },
    {
        name = "of Infinity",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            critChance = { flat = { 0.18, 0.28 } },
            attackSpeed = { percent = { 0.18, 0.3 } },
            lifeSteal = { percent = { 0.1, 0.18 } },
            health = { flat = { 90, 140 } },
        },
    },
    {
        name = "of the Archmage",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        stats = {
            manaRegen = { flat = { 1.5, 2.5 } },
        },
    },
    {
        name = "of the Magus",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            manaRegen = { flat = { 1.2, 2.0 } },
            critChance = { flat = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.12, 0.22 } },
        },
    },
    {
        name = "of the Eldritch",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            manaRegen = { flat = { 1.0, 1.8 } },
            mana = { flat = { 40, 70 } },
            health = { flat = { 80, 120 } },
            resistAll = { percent = { 0.1, 0.18 } },
        },
    },
    {
        name = "of the Abyss",
        slots = { "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.4,
        stats = {
            health = { flat = { 110, 170 } },
            resistAll = { percent = { 0.18, 0.3 } },
            dodgeChance = { flat = { 0.12, 0.2 } },
            moveSpeed = { percent = { 0.12, 0.22 } },
        },
    },
    {
        name = "of the Archon",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.35,
        stats = {
            defense = { percent = { 0.18, 0.3 } },
            health = { flat = { 80, 130 } },
            resistAll = { percent = { 0.14, 0.26 } },
            critChance = { flat = { 0.08, 0.14 } },
        },
    },
    {
        name = "of Ultimate Power",
        slots = { "weapon", "head", "chest", "feet", "gloves", "ring", "amulet" },
        minRarity = "legendary",
        weight = 0.3,
        stats = {
            damage = { percent = { 0.14, 0.24 } },
            critChance = { flat = { 0.12, 0.2 } },
            attackSpeed = { percent = { 0.16, 0.26 } },
            health = { flat = { 70, 120 } },
        },
    },
}

return Items
