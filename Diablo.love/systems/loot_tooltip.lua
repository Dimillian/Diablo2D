local tooltips = require("system_helpers.tooltips")
local coordinates = require("system_helpers.coordinates")

local lootTooltipSystem = {}

function lootTooltipSystem.draw(world)
    local lootEntities = world:queryEntities({ "lootable", "position", "size" })

    if #lootEntities == 0 then
        return
    end

    -- Get mouse position in screen coordinates
    local screenX, screenY = love.mouse.getPosition()

    -- Convert to world coordinates
    local camera = world.camera or { x = 0, y = 0 }
    local worldX, worldY = coordinates.toWorldFromScreen(camera, screenX, screenY)

    -- Find hovered loot entity
    local hoveredEntity = nil

    for _, entity in ipairs(lootEntities) do
        if entity.inactive or entity.dead then
            goto continue
        end

        local pos = entity.position
        local size = entity.size

        -- Check if mouse is within loot bounds
        if worldX >= pos.x and worldX <= pos.x + size.w and worldY >= pos.y and worldY <= pos.y + size.h then
            hoveredEntity = entity
            break
        end

        ::continue::
    end

    -- Draw tooltip if hovering
    if hoveredEntity and hoveredEntity.lootable and hoveredEntity.lootable.item then
        tooltips.drawItemTooltip(hoveredEntity.lootable.item, screenX, screenY)
    end
end

return lootTooltipSystem
