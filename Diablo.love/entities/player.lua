local Player = {}
Player.__index = Player

---Create a player entity with position and size defaults.
---@param opts table|nil
---@return Player
function Player.new(opts)
    opts = opts or {}

    local createInventory = require("components.inventory")
    local createEquipment = require("components.equipment")
    local createBaseStats = require("components.base_stats")
    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createPlayerControlled = require("components.player_controlled")
    local createHealth = require("components.health")
    local createMana = require("components.mana")
    local createCombat = require("components.combat")
    local createPotions = require("components.potions")
    local createSkills = require("components.skills")
    local createExperience = require("components.experience")

    local entity = {
        id = opts.id or "player",
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = opts.width,
            h = opts.height,
        }),
        inventory = createInventory(opts.inventory),
        equipment = createEquipment(opts.equipment),
        baseStats = createBaseStats(opts.baseStats),
        movement = createMovement(opts.movement),
        renderable = createRenderable(opts.renderable),
        playerControlled = createPlayerControlled(opts.playerControlled),
        health = createHealth(opts.health),
        mana = createMana(opts.mana),
        combat = createCombat(opts.combat),
        potions = createPotions(opts.potions or {
            healthPotionCount = 3,
            manaPotionCount = 2,
        }),
        skills = createSkills(opts.skills),
        experience = createExperience(opts.experience or {
            level = 1,
            currentXP = 0,
        }),
    }

    return setmetatable(entity, Player)
end

return Player
