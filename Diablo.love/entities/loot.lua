local Loot = {}
Loot.__index = Loot

function Loot.new(opts)
    opts = opts or {}

    local createPosition = require("components.position")
    local createRenderable = require("components.renderable")
    local createLootable = require("components.lootable")
    local createSize = require("components.size")
    local createLootScatter = require("components.loot_scatter")
    local createInactive = require("components.inactive")

    local entity = {
        id = opts.id or ("loot_" .. math.random(10000, 99999)),
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = opts.width or 16,
            h = opts.height or 16,
        }),
        renderable = createRenderable(opts.renderable or {
            kind = "loot",
            color = { 0.9, 0.8, 0.2, 1 },
        }),
        lootable = createLootable(opts.lootable),
        inactive = createInactive(),
    }

    if opts.hoverable then
        entity.hoverable = opts.hoverable
    end

    if opts.lootScatter then
        entity.lootScatter = createLootScatter(opts.lootScatter)
    end

    return setmetatable(entity, Loot)
end

return Loot
