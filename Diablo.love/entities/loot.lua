local Loot = {}
Loot.__index = Loot

---Create a loot entity
---@param opts table|nil
---@return Loot
function Loot.new(opts)
    opts = opts or {}

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createLootable = require("components.lootable")

    local entity = {
        id = opts.id or ("loot_" .. math.random(10000, 99999)),
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = opts.width or 24,
            h = opts.height or 24,
        }),
        lootable = createLootable(opts.lootable),
    }

    return setmetatable(entity, Loot)
end

return Loot
