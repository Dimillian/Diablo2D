local ChunkManager = require("modules.world.chunk_manager")
local biomes = require("data.biomes")

local minimapSystem = {}

local CONFIG = {
    size = 200,
    padding = 16,
    borderColor = { 0.1, 0.1, 0.1, 0.8 },
    backgroundColor = { 0, 0, 0, 0.45 },
}

local function drawChunk(world, chunk, centerX, centerY, scale, chunkPixelSize)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local playerX = player.position.x
    local playerY = player.position.y

    local bounds = ChunkManager.computeChunkBounds(world.chunkManager, chunk.chunkX, chunk.chunkY)
    local centerWorldX = bounds.x + bounds.w / 2
    local centerWorldY = bounds.y + bounds.h / 2
    local dx = (centerWorldX - playerX) * scale
    local dy = (centerWorldY - playerY) * scale

    local chunkCenterX = centerX + dx
    local chunkCenterY = centerY + dy

    local biome = biomes.getById(chunk.biomeId)
    local color = biome and biome.tileColors.primary or { 0.3, 0.3, 0.3, 1 }
    local visited = world.visitedChunks and world.visitedChunks[chunk.key]
    local alpha = visited and 0.9 or 0.2

    love.graphics.setColor(color[1], color[2], color[3], alpha)
    local halfSize = chunkPixelSize / 2
    local rectX = chunkCenterX - halfSize
    local rectY = chunkCenterY - halfSize
    love.graphics.rectangle("fill", rectX, rectY, chunkPixelSize, chunkPixelSize)

    if visited then
        local accent = biome and biome.tileColors.accent or { 1, 1, 1, 1 }
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.3)
        love.graphics.rectangle("line", rectX, rectY, chunkPixelSize, chunkPixelSize)
    end
end

local function drawChunkContent(world, chunk, centerX, centerY, scale)
    if not (world.visitedChunks and world.visitedChunks[chunk.key]) then
        return
    end

    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local playerX = player.position.x
    local playerY = player.position.y

    love.graphics.push("all")

    local defeatedFoes = chunk.defeatedFoes or {}
    local spawnedEntities = chunk.spawnedEntities or {}
    local liveFoeDescriptors = {}

    for descriptorId, entityId in pairs(spawnedEntities) do
        if not defeatedFoes[descriptorId] then
            local entity = world:getEntity(entityId)
            local position = entity and entity.position
            if position then
                local mapX = centerX + (position.x - playerX) * scale
                local mapY = centerY + (position.y - playerY) * scale
                love.graphics.setColor(0.85, 0.2, 0.2, 0.9)
                love.graphics.circle("fill", mapX, mapY, 3)
                liveFoeDescriptors[descriptorId] = true
            end
        end
    end

    for _, descriptor in ipairs(chunk.descriptors.foes or {}) do
        if not defeatedFoes[descriptor.id] and not liveFoeDescriptors[descriptor.id] then
            local mapX = centerX + (descriptor.x - playerX) * scale
            local mapY = centerY + (descriptor.y - playerY) * scale
            love.graphics.setColor(0.85, 0.2, 0.2, 0.9)
            love.graphics.circle("fill", mapX, mapY, 3)
        end
    end

    for _, descriptor in ipairs(chunk.descriptors.structures or {}) do
        if not chunk.lootedStructures[descriptor.id] then
            local mapX = centerX + (descriptor.x - playerX) * scale
            local mapY = centerY + (descriptor.y - playerY) * scale
            love.graphics.setColor(0.9, 0.9, 0.6, 0.85)
            love.graphics.rectangle("fill", mapX - 3, mapY - 3, 6, 6)
        end
    end

    love.graphics.pop()
end

function minimapSystem.draw(world)
    if not world.chunkManager then
        return
    end

    local minimapState = world.minimapState or { visible = true, zoom = 1 }
    if not minimapState.visible then
        return
    end

    local width = love.graphics.getWidth()
    local mapSize = CONFIG.size
    local x = width - mapSize - CONFIG.padding
    local y = CONFIG.padding
    local centerX = x + mapSize / 2
    local centerY = y + mapSize / 2

    love.graphics.push("all")
    love.graphics.setColor(CONFIG.backgroundColor)
    love.graphics.rectangle("fill", x, y, mapSize, mapSize, 6, 6)

    love.graphics.setScissor(x, y, mapSize, mapSize)
    local manager = world.chunkManager
    local chunkSize = manager.chunkSize
    local radius = manager.activeRadius or 0
    local displayRadius = math.max(0, radius - 2)
    local scale = (mapSize / (chunkSize * (displayRadius * 2 + 1))) * (minimapState.zoom or 1)
    local chunkPixelSize = chunkSize * scale

    for _, chunk in pairs(world.generatedChunks or {}) do
        drawChunk(world, chunk, centerX, centerY, scale, chunkPixelSize)
    end

    for _, chunk in pairs(world.generatedChunks or {}) do
        drawChunkContent(world, chunk, centerX, centerY, scale)
    end

    local player = world:getPlayer()
    if player and player.position then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
        love.graphics.circle("fill", centerX, centerY, 4)
    end

    love.graphics.setScissor()
    love.graphics.setColor(CONFIG.borderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, mapSize, mapSize, 6, 6)

    love.graphics.pop()
end

return minimapSystem
