local Resources = require("modules.resources")

local spriteRenderer = {}

local spriteSheetCache = {}

local function createSpriteGrid(image, gridCols, gridRows)
    local imageW, imageH = image:getDimensions()
    local cellW = math.floor(imageW / gridCols)
    local cellH = math.floor(imageH / gridRows)

    local spriteGrid = {}
    for row = 0, gridRows - 1 do
        spriteGrid[row] = {}
        for col = 0, gridCols - 1 do
            spriteGrid[row][col] = love.graphics.newQuad(
                col * cellW,
                row * cellH,
                cellW,
                cellH,
                imageW,
                imageH
            )
        end
    end

    return spriteGrid
end

function spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, gridCols)
    gridCols = gridCols or 8

    if not spriteSheetCache[spriteSheetPath] then
        local image = Resources.loadImage(spriteSheetPath)
        if not image then
            return nil, nil
        end

        local gridRows = 4
        local spriteGrid = createSpriteGrid(image, gridCols, gridRows)

        spriteSheetCache[spriteSheetPath] = {
            image = image,
            grid = spriteGrid,
            gridCols = gridCols,
        }
    end

    local cached = spriteSheetCache[spriteSheetPath]
    if not cached or not cached.grid[row] or not cached.grid[row][col] then
        return nil, nil
    end

    return cached.image, cached.grid[row][col]
end

function spriteRenderer.getAnimationFrame(animationState, walkTime, attackTime, swingDuration, totalFrames)
    walkTime = walkTime or 0
    attackTime = attackTime or 0
    swingDuration = swingDuration or 0.3
    totalFrames = totalFrames or 8

    if animationState == "attacking" then
        local attackProgress = math.min(attackTime / swingDuration, 1.0)
        local frameIndex = math.floor(attackProgress * totalFrames)
        return math.min(frameIndex, totalFrames - 1)
    elseif animationState == "walking" then
        local frameIndex = math.floor((walkTime * 8) % totalFrames)
        return frameIndex
    else
        local frameIndex = math.floor((walkTime * 2) % totalFrames)
        return frameIndex
    end
end

function spriteRenderer.clearCache(spriteSheetPath)
    if spriteSheetPath then
        spriteSheetCache[spriteSheetPath] = nil
    else
        spriteSheetCache = {}
    end
end

return spriteRenderer
