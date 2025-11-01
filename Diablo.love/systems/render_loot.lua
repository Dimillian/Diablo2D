local Resources = require("modules.resources")

local rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local renderLootSystem = {}

function renderLootSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local lootEntities = world:queryEntities({ "lootable", "position", "size" })

    for _, entity in ipairs(lootEntities) do
        -- Skip inactive entities
        if entity.inactive then
            goto continue
        end

        local pos = entity.position
        local size = entity.size
        local lootable = entity.lootable
        local item = lootable.item

        if not item then
            goto continue
        end

        -- Get rarity color
        local rarityColor = rarityColors[item.rarity] or rarityColors.common

        -- Draw colored border instead of filled rectangle
        local borderWidth = 3
        local centerX = pos.x + size.w / 2
        local centerY = pos.y + size.h / 2

        love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3], rarityColor[4] or 1)
        love.graphics.setLineWidth(borderWidth)
        love.graphics.rectangle("line", pos.x, pos.y, size.w, size.h, 4, 4)

        -- Draw item sprite in the middle
        if item.spritePath then
            local sprite = Resources.loadImageSafe(item.spritePath)
            if sprite then
                local spriteSize = math.min(size.w, size.h) * 0.8 -- Slightly smaller than loot entity size
                local spriteX = centerX - spriteSize / 2
                local spriteY = centerY - spriteSize / 2

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(
                    sprite,
                    spriteX,
                    spriteY,
                    0,
                    spriteSize / sprite:getWidth(),
                    spriteSize / sprite:getHeight()
                )
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderLootSystem
