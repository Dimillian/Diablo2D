local renderSystem = {}

local function drawGridBackground(camera)
    local gridSize = 32
    local cameraX = camera.x or 0
    local cameraY = camera.y or 0
    -- Calculate visible area in world coordinates
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    -- Calculate which grid lines should be visible (in world space)
    local worldGridStartX = math.floor(cameraX / gridSize) * gridSize - gridSize
    local worldGridStartY = math.floor(cameraY / gridSize) * gridSize - gridSize
    local worldGridEndX = worldGridStartX + screenWidth + gridSize * 3
    local worldGridEndY = worldGridStartY + screenHeight + gridSize * 3
    -- Draw grid lines at world coordinates (graphics context is already translated)
    love.graphics.setColor(0.15, 0.15, 0.15, 1) -- Dark gray grid
    -- Vertical lines
    for x = worldGridStartX, worldGridEndX, gridSize do
        love.graphics.line(x, worldGridStartY, x, worldGridEndY)
    end
    -- Horizontal lines
    for y = worldGridStartY, worldGridEndY, gridSize do
        love.graphics.line(worldGridStartX, y, worldGridEndX, y)
    end
end

function renderSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw grid background first
    drawGridBackground(camera)

    -- Draw detection circles for entities with detection component (debug only)
    if world.debugMode then
        local entitiesWithDetection = world:queryEntities({ "detection", "position" })
        for _, entity in ipairs(entitiesWithDetection) do
            -- Skip inactive entities
            if entity.inactive then
                goto continue
            end

            local detection = entity.detection
            local pos = entity.position

            -- Draw detection circle (debug visualization)
            love.graphics.setColor(1, 1, 0, 0.3) -- Yellow, semi-transparent
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", pos.x, pos.y, detection.range)
            -- If chasing, draw a more visible ring
            if entity.chase then
                love.graphics.setColor(1, 0, 0, 0.5) -- Red when chasing
                love.graphics.circle("line", pos.x, pos.y, detection.range)
            end

            ::continue::
        end
    end

    -- Draw entities
    local entities = world:queryEntities({ "renderable", "position", "size" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            goto continue
        end

        local renderable = entity.renderable
        if renderable.kind == "rect" then
            -- Skip rendering base rectangle if entity has armor equipped
            local hasArmor = false
            if entity.equipment then
                local armorSlots = { "head", "chest", "gloves", "feet" }
                for _, slotId in ipairs(armorSlots) do
                    if entity.equipment[slotId] then
                        hasArmor = true
                        break
                    end
                end
            end

            -- Only render base rectangle if no armor is equipped
            if not hasArmor then
                -- Tint player when recently damaged (visual strike indicator)
                local color = renderable.color
                if entity.recentlyDamaged then
                    -- Flash red tint when damaged
                    color = { 1, 0.3, 0.3, color[4] or 1 }
                end

                love.graphics.setColor(color)
                love.graphics.rectangle(
                    "fill",
                    entity.position.x,
                    entity.position.y,
                    entity.size.w,
                    entity.size.h
                )
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderSystem
