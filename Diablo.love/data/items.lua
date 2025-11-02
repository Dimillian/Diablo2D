local Items = {}

Items.rarities = {
    common = {
        id = "common",
        label = "Common",
        weight = 75,
        prefixCount = 0,
        suffixCount = 0,
        statMultiplier = 1.0,
    },
    uncommon = {
        id = "uncommon",
        label = "Uncommon",
        weight = 25,
        prefixCount = 1,
        suffixCount = 1,
        statMultiplier = 1.1,
    },
    rare = {
        id = "rare",
        label = "Rare",
        weight = 10,
        prefixCount = 1,
        suffixCount = 1,
        statMultiplier = 1.25,
    },
    epic = {
        id = "epic",
        label = "Epic",
        weight = 5,
        prefixCount = 2,
        suffixCount = 1,
        statMultiplier = 1.5,
    },
    legendary = {
        id = "legendary",
        label = "Legendary",
        weight = 2,
        prefixCount = 2,
        suffixCount = 2,
        statMultiplier = 1.75,
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
}

Items.prefixes = {
    {
        name = "Furious",
        slots = { "weapon" },
        stats = {
            damage = { flat = { 2, 4 } },
        },
    },
    {
        name = "Jagged",
        slots = { "weapon" },
        stats = {
            damage = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "Precise",
        slots = { "weapon" },
        stats = {
            critChance = { flat = { 0.03, 0.07 } },
        },
    },
    {
        name = "Guarded",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            defense = { flat = { 2, 4 } },
        },
    },
    {
        name = "Swift",
        slots = { "feet" },
        stats = {
            moveSpeed = { percent = { 0.05, 0.1 } },
        },
    },
    {
        name = "Bloodthirsty",
        slots = { "weapon" },
        stats = {
            lifeSteal = { percent = { 0.01, 0.04 } },
        },
    },
    {
        name = "Balanced",
        slots = { "weapon" },
        stats = {
            attackSpeed = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "Stalwart",
        slots = { "head", "chest", "gloves" },
        stats = {
            health = { flat = { 15, 30 } },
        },
    },
    {
        name = "Reinforced",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            defense = { percent = { 0.1, 0.2 } },
        },
    },
    {
        name = "Windrunner",
        slots = { "feet" },
        stats = {
            moveSpeed = { percent = { 0.12, 0.2 } },
            dodgeChance = { flat = { 0.02, 0.05 } },
        },
    },
    {
        name = "Swift Strikes",
        slots = { "gloves" },
        stats = {
            attackSpeed = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "Enchanted",
        slots = { "ring", "amulet" },
        stats = {
            critChance = { flat = { 0.02, 0.08 } },
            attackSpeed = { percent = { 0.03, 0.07 } },
        },
    },
    {
        name = "Fortified",
        slots = { "ring", "amulet" },
        stats = {
            health = { flat = { 25, 45 } },
            defense = { flat = { 3, 6 } },
        },
    },
    {
        name = "Warding",
        slots = { "ring", "amulet" },
        stats = {
            resistAll = { percent = { 0.04, 0.08 } },
            dodgeChance = { flat = { 0.02, 0.04 } },
        },
    },
}

Items.suffixes = {
    {
        name = "of Vitality",
        slots = { "head", "chest", "weapon", "gloves", "ring", "amulet" },
        stats = {
            health = { flat = { 10, 20 } },
        },
    },
    {
        name = "of the Fox",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            dodgeChance = { flat = { 0.03, 0.08 } },
        },
    },
    {
        name = "of the Bear",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            defense = { percent = { 0.06, 0.12 } },
        },
    },
    {
        name = "of Greed",
        slots = { "weapon", "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            goldFind = { percent = { 0.1, 0.25 } },
        },
    },
    {
        name = "of Carnage",
        slots = { "weapon" },
        stats = {
            damage = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of Ferocity",
        slots = { "weapon" },
        stats = {
            damage = { flat = { 3, 6 } },
        },
    },
    {
        name = "of the Sentinel",
        slots = { "head", "chest", "gloves", "ring", "amulet" },
        stats = {
            health = { flat = { 20, 35 } },
            defense = { percent = { 0.08, 0.15 } },
        },
    },
    {
        name = "of Phasing",
        slots = { "feet" },
        stats = {
            moveSpeed = { percent = { 0.08, 0.15 } },
            dodgeChance = { flat = { 0.04, 0.08 } },
        },
    },
    {
        name = "of Resolve",
        slots = { "head", "chest", "feet", "gloves", "ring", "amulet" },
        stats = {
            resistAll = { percent = { 0.05, 0.12 } },
        },
    },
    {
        name = "of Power",
        slots = { "ring", "amulet" },
        stats = {
            critChance = { flat = { 0.03, 0.07 } },
            attackSpeed = { percent = { 0.03, 0.06 } },
        },
    },
    {
        name = "of Regeneration",
        slots = { "ring", "amulet" },
        stats = {
            health = { flat = { 30, 50 } },
            lifeSteal = { percent = { 0.02, 0.05 } },
        },
    },
    {
        name = "of Evasion",
        slots = { "ring", "amulet" },
        stats = {
            dodgeChance = { flat = { 0.05, 0.1 } },
            moveSpeed = { percent = { 0.05, 0.1 } },
        },
    },
}

return Items
