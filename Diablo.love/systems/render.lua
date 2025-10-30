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

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw grid background first
    drawGridBackground(camera)

    -- Draw detection circles for entities with detection component (debug only)
    if world.debugMode then
        local entitiesWithDetection = world:queryEntities({ "detection", "position" })
        for _, entity in ipairs(entitiesWithDetection) do
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
        end
    end

    -- Draw entities
    local entities = world:queryEntities({ "renderable", "position", "size" })

    for _, entity in ipairs(entities) do
        local renderable = entity.renderable
        if renderable.kind == "rect" then
            love.graphics.setColor(renderable.color)
            love.graphics.rectangle(
                "fill",
                entity.position.x,
                entity.position.y,
                entity.size.w,
                entity.size.h
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderSystem
