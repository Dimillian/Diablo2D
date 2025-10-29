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

    local entity = {
        id = opts.id or "player",
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = {
            w = opts.width or 16,
            h = opts.height or 24,
        },
        inventory = createInventory(opts.inventory),
        equipment = createEquipment(opts.equipment),
        baseStats = createBaseStats(opts.baseStats),
    }

    return setmetatable(entity, Player)
end

return Player
