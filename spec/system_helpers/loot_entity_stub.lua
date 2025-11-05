local function cloneTable(tbl)
    if not tbl then
        return nil
    end

    local copy = {}
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            copy[key] = cloneTable(value)
        else
            copy[key] = value
        end
    end
    return copy
end

local LootEntity = {}
local lootCounter = 0

function LootEntity.new(opts)
    opts = opts or {}
    lootCounter = lootCounter + 1
    return {
        id = opts.id or ("loot_entity_" .. lootCounter),
        position = { x = opts.x or 0, y = opts.y or 0 },
        size = { w = opts.width or 16, h = opts.height or 16 },
        renderable = cloneTable(opts.renderable),
        lootable = cloneTable(opts.lootable),
        lootScatter = cloneTable(opts.lootScatter),
    }
end

return LootEntity
