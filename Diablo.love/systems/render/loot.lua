local Resources = require("modules.resources")

local renderLootSystem = {}

function renderLootSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "renderable", "lootable", "position", "size" })

    for _, entity in ipairs(entities) do
        if entity.inactive then
            goto continue
        end

        local renderable = entity.renderable
        if not renderable or renderable.kind ~= "loot" then
            goto continue
        end

        local lootable = entity.lootable
        if not lootable or not lootable.item then
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
        local spritePath = item and item.spritePath
        local iconName = item and item.iconName

        -- Try sprite path first (for regular items)
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
        -- Try UI icon (for potions and other consumables)
        elseif iconName then
            local icon = Resources.loadUIIcon(iconName)
            if icon then
                local iconWidth = icon:getWidth()
                local iconHeight = icon:getHeight()

                local innerPadding = 8
                local scale = math.min((w - innerPadding) / iconWidth, (h - innerPadding) / iconHeight)
                local drawX = x + (w - iconWidth * scale) / 2
                local drawY = y + (h - iconHeight * scale) / 2

                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(icon, drawX, drawY, 0, scale, scale)
            end
        end

        love.graphics.pop()

        ::continue::
    end

    love.graphics.pop()
end

return renderLootSystem
