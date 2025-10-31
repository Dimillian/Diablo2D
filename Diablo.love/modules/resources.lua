---Resource manager for loading and caching images and sprite sheets.
---Supports both standalone images and sprite atlases with quads.
-- luacheck: globals pcall error
local resources = {}

local cache = {
    images = {},
    quads = {}, -- For sprite sheet regions
    atlases = {}, -- Sprite sheet images with metadata
}

---Load a standalone image (cached)
---@param path string Path to image file
---@return love.Image
function resources.loadImage(path)
    if cache.images[path] then
        return cache.images[path]
    end

    local image = love.graphics.newImage(path)
    cache.images[path] = image
    return image
end

---Load a standalone image safely (cached, with error handling)
---Returns nil if the image cannot be loaded instead of throwing an error
---@param path string|nil Path to image file
---@return love.Image|nil
function resources.loadImageSafe(path)
    if not path then
        return nil
    end

    if cache.images[path] then
        return cache.images[path]
    end

    local success, image = pcall(function()
        return love.graphics.newImage(path)
    end)

    if success and image then
        cache.images[path] = image
        return image
    end

    return nil
end

---Load a sprite atlas (image + metadata)
---The metadata file should be a Lua table mapping sprite names to quad data:
---  { x = 0, y = 0, w = 32, h = 32 }
---@param imagePath string Path to sprite sheet image
---@param metadataPath string|nil Optional path to metadata Lua file
---@param spriteSize number|nil Optional: if metadataPath is nil, creates uniform sprites of this size
---@return love.Image atlas, table sprites Table mapping sprite names to quads
function resources.loadAtlas(imagePath, metadataPath, spriteSize)
    local cacheKey = imagePath .. (metadataPath or "") .. (spriteSize or "")
    if cache.atlases[cacheKey] then
        return cache.atlases[cacheKey].image, cache.atlases[cacheKey].sprites
    end

    local image = resources.loadImage(imagePath)
    local sprites = {}

    if metadataPath then
        -- Load metadata from Lua file
        local metadata = require(metadataPath:gsub("%.lua$", ""):gsub("/", "."))
        for name, data in pairs(metadata) do
            sprites[name] = love.graphics.newQuad(
                data.x,
                data.y,
                data.w or spriteSize or 32,
                data.h or spriteSize or 32,
                image:getDimensions()
            )
        end
    elseif spriteSize then
        -- Auto-generate uniform grid sprites
        local imageW, imageH = image:getDimensions()
        local cols = math.floor(imageW / spriteSize)
        local rows = math.floor(imageH / spriteSize)
        local index = 1

        for y = 0, rows - 1 do
            for x = 0, cols - 1 do
                local spriteName = "sprite_" .. index
                sprites[spriteName] = love.graphics.newQuad(
                    x * spriteSize,
                    y * spriteSize,
                    spriteSize,
                    spriteSize,
                    imageW,
                    imageH
                )
                index = index + 1
            end
        end
    else
        error("loadAtlas requires either metadataPath or spriteSize")
    end

    cache.atlases[cacheKey] = {
        image = image,
        sprites = sprites,
    }

    return image, sprites
end

---Get a quad from a loaded atlas
---@param atlasPath string Path to atlas image
---@param spriteName string Name of sprite in atlas
---@return love.Image|nil, love.Quad|nil
function resources.getAtlasSprite(atlasPath, spriteName)
    -- Find the atlas in cache
    for cacheKey, atlasData in pairs(cache.atlases) do
        if cacheKey:match("^" .. atlasPath) then
            return atlasData.image, atlasData.sprites[spriteName]
        end
    end
    return nil, nil
end

---Clear all cached resources (useful for testing/reloading)
function resources.clearCache()
    cache.images = {}
    cache.quads = {}
    cache.atlases = {}
end

return resources
