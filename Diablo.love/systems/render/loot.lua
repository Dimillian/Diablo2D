local Resources = require("modules.resources")

local renderLootSystem = {}

function renderLootSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "renderable", "lootable", "position", "size" })

    for _, entity in ipairs(entities) do
        if entity.inactive and entity.inactive.isInactive then
            goto continue
        end

        local renderable = entity.renderable
        if not renderable or renderable.kind ~= "loot" then
            goto continue
        end

        local lootable = entity.lootable
        if not lootable then
            goto continue
        end

        local hasItem = lootable.item ~= nil
        local hasGold = lootable.gold and lootable.gold > 0
        if not hasItem and not hasGold then
            goto continue
        end

        local pos = entity.position
        local size = entity.size
        local x = pos.x
        local y = pos.y
        local w = size.w
        local h = size.h

        local color = renderable.color or { 1, 1, 1, 1 }

        love.graphics.push("all")

        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x, y, w, h, 4, 4)

        love.graphics.setColor(color)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, w, h, 4, 4)

        local item = lootable.item
        local spritePath = lootable.iconPath or (item and item.spritePath)

        if spritePath then
            local sprite = Resources.loadImageSafe(spritePath)
            if sprite then
                local spriteWidth = sprite:getWidth()
                local spriteHeight = sprite:getHeight()

                local innerPadding = 8
                local scale = math.min((w - innerPadding) / spriteWidth, (h - innerPadding) / spriteHeight)
                local drawX = x + (w - spriteWidth * scale) / 2
                local drawY = y + (h - spriteHeight * scale) / 2

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(sprite, drawX, drawY, 0, scale, scale)
            end
        end

        love.graphics.pop()

        ::continue::
    end

    love.graphics.pop()
end

return renderLootSystem
