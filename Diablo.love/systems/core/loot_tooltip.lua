local Tooltips = require("systems.helpers.tooltips")

local lootTooltipSystem = {}

function lootTooltipSystem.draw(world)
    local coordsHelper = world.systemHelpers and world.systemHelpers.coordinates
    if not coordsHelper or not coordsHelper.toWorldFromScreen then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }
    local pointerX, pointerY = love.mouse.getPosition()
    local worldX, worldY = coordsHelper.toWorldFromScreen(camera, pointerX, pointerY)

    local loots = world:queryEntities({ "lootable", "position" })
    local hovered = nil

    for _, loot in ipairs(loots) do
        if loot.inactive then
            goto continue
        end

        local pos = loot.position
        local size = loot.size or { w = 16, h = 16 }

        if worldX >= pos.x and worldX <= pos.x + size.w and worldY >= pos.y and worldY <= pos.y + size.h then
            hovered = loot
            break
        end

        ::continue::
    end

    if not hovered or not hovered.lootable then
        return
    end

    local lootable = hovered.lootable

    if lootable.item then
        Tooltips.drawItemTooltip(lootable.item, pointerX, pointerY, {
            offsetX = 18,
            offsetY = 18,
            clamp = true,
        })
        return
    end

    if lootable.gold and lootable.gold > 0 then
        local padding = 8
        local label = string.format("%d Gold", lootable.gold)
        local font = love.graphics.getFont()
        local width = font:getWidth(label) + padding * 2
        local height = font:getHeight() + padding * 2
        local tooltipX = pointerX + 18
        local tooltipY = pointerY + 18

        local screenWidth, screenHeight = love.graphics.getDimensions()
        if tooltipX + width > screenWidth then
            tooltipX = screenWidth - width - 8
        end
        if tooltipY + height > screenHeight then
            tooltipY = screenHeight - height - 8
        end

        love.graphics.push("all")

        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", tooltipX, tooltipY, width, height, 6, 6)

        love.graphics.setColor(1, 0.9, 0.4, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

        love.graphics.print(label, tooltipX + padding, tooltipY + padding)

        love.graphics.pop()
    end
end

return lootTooltipSystem
