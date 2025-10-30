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
    }

    return setmetatable(entity, Player)
end

return Player
