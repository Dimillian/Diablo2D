local Spells = {}

Spells.types = {
    fireball = {
        id = "fireball",
        label = "Fireball",
        description = "Launch a blazing fireball that scorches foes.",
        manaCost = 10,
        damage = { min = 15, max = 25 },
        projectileSpeed = 300,
        projectileSize = 12,
        projectileColor = { 1.0, 0.4, 0.1, 1 },
        projectileRenderKind = "fireball",
        projectileImpactDuration = 0.2,
        icon = "resources/skills/fireball.png",
        lifetime = 2.5,
        skillTree = {
            nodes = {
                ignition_core = {
                    id = "ignition_core",
                    label = "Ignition Core",
                    description = "Invest points to amplify Fireball's raw damage.",
                    maxPoints = 20,
                    effects = {
                        { type = "damage_flat", perPoint = 3 },
                    },
                    position = { x = 0.5, y = 0.18 },
                },
                searing_burst = {
                    id = "searing_burst",
                    label = "Searing Burst",
                    description = "Unlocks a larger blast radius for Fireball.",
                    maxPoints = 10,
                    requirements = {
                        { nodeId = "ignition_core", points = 5 },
                    },
                    effects = {
                        { type = "projectile_size", perPoint = 2 },
                    },
                    position = { x = 0.5, y = 0.5 },
                },
                blazing_comet = {
                    id = "blazing_comet",
                    label = "Blazing Comet",
                    description = "Accelerate the fireball into a blistering comet.",
                    maxPoints = 10,
                    requirements = {
                        { nodeId = "searing_burst", points = 5 },
                    },
                    effects = {
                        { type = "projectile_speed", perPoint = 35 },
                    },
                    position = { x = 0.5, y = 0.82 },
                },
            },
            edges = {
                { from = "ignition_core", to = "searing_burst" },
                { from = "searing_burst", to = "blazing_comet" },
            },
        },
    },
    thunder = {
        id = "thunder",
        label = "Thunder",
        description = "Call down a searing bolt of lightning at your cursor.",
        manaCost = 14,
        damage = { min = 18, max = 30 },
        projectileSpeed = 900,
        projectileSize = 44,
        projectileColor = { 0.55, 0.75, 1.0, 1 },
        projectileSecondaryColor = { 0.3, 0.6, 1.0, 0.9 },
        projectileCoreColor = { 0.9, 0.95, 1.0, 1 },
        projectileRenderKind = "thunder",
        projectileImpactDuration = 0.35,
        projectileBoltLength = 240,
        projectileSpawn = "sky",
        projectileSpawnHeight = 220,
        targeting = "cursor",
        icon = "resources/skills/fireball.png",
        lifetime = 0.6,
    },
}

---Return an ordered array of spell definitions.
---@return table
function Spells.getAll()
    local list = {}
    for _, spell in pairs(Spells.types) do
        list[#list + 1] = spell
    end
    table.sort(list, function(a, b)
        return a.label < b.label
    end)
    return list
end

return Spells
