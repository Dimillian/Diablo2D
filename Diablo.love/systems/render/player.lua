local renderEquipmentSystem = require("systems.render.equipment")

local renderPlayerSystem = {}

---Calculate walking wobble rotation for player-controlled entities
---@param entity table Entity with movement component
---@return number Rotation angle in radians
local function calculateWalkWobble(entity)
    if not entity.movement or not entity.playerControlled then
        return 0
    end

    local walkTime = entity.movement.walkAnimationTime or 0
    if walkTime <= 0 then
        return 0
    end

    -- Animation parameters: amplitude 10 degrees (~0.17 radians), frequency 2 Hz (slower wobble)
    local amplitude = math.rad(10) -- 10 degrees in radians
    local frequency = 2.0
    return amplitude * math.sin(frequency * math.pi * 2 * walkTime)
end

---Render the player entity with base rectangle and equipment
function renderPlayerSystem.draw(world)
    local player = world:getPlayer()
    if not player then
        return
    end

    -- Skip inactive player
    if player.inactive and player.inactive.isInactive then
        return
    end

    -- Use lastUpdateDt for smooth animation, default to ~60fps if not available
    local dt = world.lastUpdateDt or 0.016
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local pos = player.position
    local size = player.size

    -- Calculate walking wobble rotation
    local wobbleRotation = calculateWalkWobble(player)

    local centerX = pos.x + (size.w / 2)
    local centerY = pos.y + (size.h / 2)

    -- Calculate flip direction using shared helper from equipment system
    local flipScale = renderEquipmentSystem.calculateFlipDirection(player, dt)

    -- Apply rotation around entity center for walking wobble
    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.rotate(wobbleRotation)
    love.graphics.translate(-centerX, -centerY)

    -- Render base white rectangle only if no armor is equipped
    local hasArmor = false
    if player.equipment then
        local armorSlots = { "head", "chest", "gloves", "feet" }
        for _, slotId in ipairs(armorSlots) do
            if player.equipment[slotId] then
                hasArmor = true
                break
            end
        end
    end

    if not hasArmor then
        local renderable = player.renderable
        if renderable and renderable.kind == "rect" then
            -- Tint player when recently damaged (visual strike indicator)
            local color = renderable.color
            if player.recentlyDamaged then
                -- Flash red tint when damaged
                color = { 1, 0.3, 0.3, color[4] or 1 }
            end

            love.graphics.setColor(color)
            love.graphics.rectangle(
                "fill",
                pos.x,
                pos.y,
                size.w,
                size.h
            )
        end
    end

    -- Render equipment using shared helper from equipment system
    renderEquipmentSystem.renderEntityEquipment(player, centerX, centerY, flipScale)

    -- Pop rotation transform
    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderPlayerSystem
