local biomes = require("data.biomes")

local worldMapRenderer = {}

local MAP_CONFIG = {
    padding = 0,
    backgroundColor = { 0.05, 0.05, 0.05, 0.92 },
    borderColor = { 0.4, 0.35, 0.25, 0.9 },
    unexploredAlpha = 0.35,
    exploredAlpha = 0.9,
    gridColor = { 0.2, 0.2, 0.2, 0.65 },
    playerFill = { 0.18, 0.82, 0.28, 1 },
    playerOutline = { 0.05, 0.28, 0.05, 1 },
    baseChunkPixelSize = 40,
}

local ZONE_HASH_X = 73856093
local ZONE_HASH_Y = 19349663

local function resolveZoom(scene)
    if not scene then
        return 1
    end

    local zoom = scene.zoom or 1
    local minZoom = scene.minZoom or 0.5
    local maxZoom = scene.maxZoom or 2.5

    if zoom < minZoom then
        return minZoom
    end
    if zoom > maxZoom then
        return maxZoom
    end
    return zoom
end

local function computeChunkBounds(chunks)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, chunk in pairs(chunks or {}) do
        if chunk.chunkX and chunk.chunkY then
            if chunk.chunkX < minX then
                minX = chunk.chunkX
            end
            if chunk.chunkX > maxX then
                maxX = chunk.chunkX
            end
            if chunk.chunkY < minY then
                minY = chunk.chunkY
            end
            if chunk.chunkY > maxY then
                maxY = chunk.chunkY
            end
        end
    end

    if minX == math.huge then
        return nil
    end

    return {
        minX = minX,
        maxX = maxX,
        minY = minY,
        maxY = maxY,
        width = maxX - minX + 1,
        height = maxY - minY + 1,
    }
end

local function drawChunkRectangles(scene, layout)
    local world = scene.world
    local chunks = world and world.generatedChunks or {}
    local bounds = computeChunkBounds(chunks)
    if not bounds then
        love.graphics.setColor(MAP_CONFIG.instructionColor)
        love.graphics.printf(
            "No map data yet. Explore to reveal the world!",
            layout.content.x,
            layout.content.y + layout.content.height / 2 - 12,
            layout.content.width,
            "center"
        )
        return
    end

    local padding = MAP_CONFIG.padding
    local mapX = layout.content.x
    local mapY = layout.content.y + padding
    local mapWidth = layout.content.width
    local mapHeight = layout.content.height - padding - 4 -- Top padding + small bottom padding for border
    if mapWidth <= 0 or mapHeight <= 0 then
        return
    end

    love.graphics.setColor(MAP_CONFIG.backgroundColor)
    love.graphics.rectangle("fill", mapX, mapY, mapWidth, mapHeight, 0, 0)

    local zoom = resolveZoom(scene)
    local chunkPixelSize = (MAP_CONFIG.baseChunkPixelSize or 40) * zoom
    local halfChunk = chunkPixelSize / 2
    local mapCenterX = mapX + mapWidth / 2
    local mapCenterY = mapY + mapHeight / 2

    local player = world:getPlayer()
    local chunkSize = world.chunkManager and world.chunkManager.chunkSize or 1
    local panOffsetX = scene.panOffsetX or 0
    local panOffsetY = scene.panOffsetY or 0

    local playerChunkX = player and player.position and (player.position.x / chunkSize) or nil
    local playerChunkY = player and player.position and (player.position.y / chunkSize) or nil
    local baseCenterX = playerChunkX or ((bounds.minX + bounds.maxX) / 2)
    local baseCenterY = playerChunkY or ((bounds.minY + bounds.maxY) / 2)
    local centerChunkX = baseCenterX + panOffsetX
    local centerChunkY = baseCenterY + panOffsetY

    -- Draw grid lines over the content area; zoom changes chunk spacing, not the container size.
    love.graphics.push("all")
    love.graphics.setScissor(mapX, mapY, mapWidth, mapHeight)
    love.graphics.setColor(MAP_CONFIG.gridColor)
    love.graphics.setLineWidth(1)
    local gridHalfCols = math.ceil(mapWidth / chunkPixelSize / 2) + 1
    local gridHalfRows = math.ceil(mapHeight / chunkPixelSize / 2) + 1

    for column = centerChunkX - gridHalfCols, centerChunkX + gridHalfCols do
        local x = mapCenterX + (column - centerChunkX) * chunkPixelSize - halfChunk
        love.graphics.line(x, mapY, x, mapY + mapHeight)
    end
    for row = centerChunkY - gridHalfRows, centerChunkY + gridHalfRows do
        local y = mapCenterY + (row - centerChunkY) * chunkPixelSize - halfChunk
        love.graphics.line(mapX, y, mapX + mapWidth, y)
    end

    local regions = {}

    for _, chunk in pairs(chunks) do
        local col = chunk.chunkX - bounds.minX
        local row = chunk.chunkY - bounds.minY
        local rectX = mapCenterX + (chunk.chunkX - centerChunkX) * chunkPixelSize - halfChunk
        local rectY = mapCenterY + (chunk.chunkY - centerChunkY) * chunkPixelSize - halfChunk

        local biome = biomes.getById(chunk.biomeId)
        local baseColor = biome and biome.tileColors.primary or { 0.35, 0.35, 0.35, 1 }
        local accent = biome and biome.tileColors.accent or { 0.7, 0.7, 0.7, 1 }
        local visited = world.visitedChunks and world.visitedChunks[chunk.key]
        local alpha = visited and MAP_CONFIG.exploredAlpha or MAP_CONFIG.unexploredAlpha

        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], alpha)
        love.graphics.rectangle("fill", rectX, rectY, chunkPixelSize, chunkPixelSize)

        love.graphics.setColor(accent[1], accent[2], accent[3], alpha * 0.85 + 0.1)
        love.graphics.rectangle("line", rectX, rectY, chunkPixelSize, chunkPixelSize)

        local name = chunk.zoneName or chunk.biomeLabel or chunk.biomeId or "?"
        local zoneSeed = chunk.zoneSeed or chunk.seed or (chunk.chunkX * ZONE_HASH_X + chunk.chunkY * ZONE_HASH_Y)
        local regionKey = tostring(zoneSeed) .. "|" .. (chunk.biomeId or "?")
        local region = regions[regionKey]
        if not region then
            region = {
                name = name,
                biomeId = chunk.biomeId,
                minCol = col,
                maxCol = col,
                minRow = row,
                maxRow = row,
                sumX = 0,
                sumY = 0,
                count = 0,
                visitedCount = 0,
            }
            regions[regionKey] = region
        else
            region.minCol = math.min(region.minCol, col)
            region.maxCol = math.max(region.maxCol, col)
            region.minRow = math.min(region.minRow, row)
            region.maxRow = math.max(region.maxRow, row)
        end

        local centerX = rectX + halfChunk
        local centerY = rectY + halfChunk
        region.sumX = region.sumX + centerX
        region.sumY = region.sumY + centerY
        region.count = region.count + 1
        if visited then
            region.visitedCount = region.visitedCount + 1
        end
    end

    local font = scene.zoneNameFont or love.graphics.getFont()
    love.graphics.setFont(font)

    for _, region in pairs(regions) do
        if region.count > 0 and region.name and region.name ~= "" then
            local centerX = region.sumX / region.count
            local centerY = region.sumY / region.count - font:getHeight() / 2
            local width = math.max(chunkPixelSize, (region.maxCol - region.minCol + 1) * chunkPixelSize)
            local opacity = region.visitedCount > 0 and 1 or 0.5

            love.graphics.setColor(0, 0, 0, opacity * 0.5)
            love.graphics.printf(region.name, centerX - width / 2 + 2, centerY + 2, width, "center")

            love.graphics.setColor(0.95, 0.9, 0.7, opacity)
            love.graphics.printf(region.name, centerX - width / 2, centerY, width, "center")
        end
    end

    if player and player.position then
        local chunkCoordX = player.position.x / chunkSize
        local chunkCoordY = player.position.y / chunkSize
        local centerX = mapCenterX + (chunkCoordX - centerChunkX) * chunkPixelSize
        local centerY = mapCenterY + (chunkCoordY - centerChunkY) * chunkPixelSize
        local radius = math.max(4, chunkPixelSize * 0.08)

        love.graphics.setColor(MAP_CONFIG.playerFill)
        love.graphics.circle("fill", centerX, centerY, radius)
        love.graphics.setColor(MAP_CONFIG.playerOutline)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", centerX, centerY, radius + 2)
    end

    love.graphics.setScissor()
    love.graphics.pop()
end

function worldMapRenderer.draw(scene)
    if not scene or not scene.world then
        return
    end

    local layout = scene.windowLayout
    if not layout then
        return
    end

    -- Override content area to be edge-to-edge for width (with small border padding)
    local borderPadding = 4 -- Account for the 3px border width
    local originalContent = layout.content
    layout.content = {
        x = layout.panelX + borderPadding,
        y = originalContent.y,
        width = layout.panelWidth - borderPadding * 2,
        height = originalContent.height,
    }

    drawChunkRectangles(scene, layout)

    -- Restore original content area
    layout.content = originalContent
end

return worldMapRenderer
