---Example usage of the resource system
---This file demonstrates how to use standalone images vs sprite sheets

--[[
RESOURCE ORGANIZATION RECOMMENDATION:

assets/
  images/
    backgrounds/
      forest_bg.png       -- Standalone: large unique image
      town_bg.png
    ui/
      panel.png           -- Standalone: UI elements
      button.png

  sprites/
    characters.png        -- Sprite sheet: player/monster sprites
    items.png            -- Sprite sheet: all item icons
    tiles.png            -- Sprite sheet: terrain tiles
    animations/
      player_walk.png     -- Sprite sheet: animation frames

  data/
    sprites/
      characters.lua      -- Metadata for characters.png
      items.lua           -- Metadata for items.png

USAGE EXAMPLES:
]]

local Resources = require("modules.resources")

-- Example 1: Load a standalone image (background, UI panel)
local backgroundImage = Resources.loadImage("assets/images/backgrounds/forest_bg.png")

-- Example 2: Load a sprite sheet with uniform grid (auto-generate quads)
-- Creates sprites named "sprite_1", "sprite_2", etc. in left-to-right, top-to-bottom order
local tilesImage, tilesSprites = Resources.loadAtlas(
    "assets/sprites/tiles.png",
    nil,  -- No metadata file
    32    -- 32x32 pixel sprites
)
-- Use: tilesSprites["sprite_1"], tilesSprites["sprite_2"], etc.

-- Example 3: Load a sprite sheet with metadata file
-- metadata file (assets/data/sprites/characters.lua) might look like:
--[[
return {
    player_idle = { x = 0, y = 0, w = 32, h = 32 },
    player_walk_1 = { x = 32, y = 0, w = 32, h = 32 },
    player_walk_2 = { x = 64, y = 0, w = 32, h = 32 },
    goblin_idle = { x = 0, y = 32, w = 32, h = 32 },
    goblin_walk_1 = { x = 32, y = 32, w = 32, h = 32 },
}
]]
local charactersImage, charactersSprites = Resources.loadAtlas(
    "assets/sprites/characters.png",
    "assets/data/sprites/characters"  -- .lua extension added automatically
)
-- Use: charactersSprites["player_idle"], charactersSprites["goblin_idle"], etc.

-- Example 4: Using images in renderable components
local Renderable = require("components.renderable")

-- Standalone image
local imageRenderable = Renderable({
    kind = "image",
    image = backgroundImage,
    color = { 1, 1, 1, 1 },  -- Optional tint
})

-- Sprite from atlas
local spriteRenderable = Renderable({
    kind = "sprite",
    image = charactersImage,
    quad = charactersSprites["player_idle"],
    color = { 1, 1, 1, 1 },
})

--[[
PERFORMANCE TIPS:

1. Use sprite sheets for:
   - Entities that appear frequently (monsters, items, tiles)
   - Animated sprites (all frames in one sheet)
   - Small repeating graphics

2. Use standalone images for:
   - Large backgrounds (fewer texture swaps)
   - Unique UI elements
   - One-off decorative elements

3. Batch rendering: Love2D automatically batches draws of the same texture.
   Using sprite sheets means more entities share the same texture, improving batching.

4. Preload in love.load(): Load all your resources at startup to avoid frame drops.
]]
