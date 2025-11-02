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

    if not hovered or not hovered.lootable or not hovered.lootable.item then
        return
    end

    Tooltips.drawItemTooltip(hovered.lootable.item, pointerX, pointerY, {
        offsetX = 18,
        offsetY = 18,
        clamp = true,
    })
end

return lootTooltipSystem
