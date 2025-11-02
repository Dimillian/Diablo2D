local Resources = require("modules.resources")

local renderEquipmentSystem = {}

---Get slot-specific offsets relative to entity size
---@param size table Entity size {w, h}
---@return table Offsets table
local function getSlotOffsets(size)
    return {
        weapon = { x = size.w * 2.2, y = 8 }, -- Forward (right)
        head = { x = 0, y = -size.h * 1 }, -- Up
        chest = { x = 0, y = 0 }, -- Center
        feet = { x = 0, y = size.h * 1 }, -- Down
        feetLeft = { x = -size.w * 0.6, y = size.h * 1 }, -- Left foot
        feetRight = { x = size.w * 0.6, y = size.h * 1 }, -- Right foot
        glovesLeft = { x = -size.w * 1.5, y = 0.5 }, -- Left side
        glovesRight = { x = size.w * 1.5, y = 0.5 }, -- Right side
    }
end

---Draw a sprite at the specified position with optional rotation and scaling
---@param sprite userdata Love2D Image object
---@param x number X position
---@param y number Y position
---@param rotation number|nil Rotation angle in radians (default: 0)
---@param scaleX number|nil X scale factor (default: 1)
---@param scaleY number|nil Y scale factor (default: 1)
---@param originX number|nil Rotation origin X relative to sprite (default: 0)
---@param originY number|nil Rotation origin Y relative to sprite (default: 0)
local function drawSprite(sprite, x, y, rotation, scaleX, scaleY, originX, originY)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        sprite,
        x,
        y,
        rotation or 0,
        scaleX or 1,
        scaleY or 1,
        originX or 0,
        originY or 0
    )
end

---Render gloves (both left and right)
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offsets table Offsets table
local function renderGloves(sprite, spriteSize, centerX, centerY, offsets)
    local leftOffset = offsets.glovesLeft or { x = 0, y = 0 }
    local rightOffset = offsets.glovesRight or { x = 0, y = 0 }

    -- Left glove (flipped horizontally, on left side)
    local leftSpriteX = centerX - spriteSize / 2 + leftOffset.x + spriteSize
    local leftSpriteY = centerY - spriteSize / 2 + leftOffset.y
    drawSprite(
        sprite,
        leftSpriteX,
        leftSpriteY,
        0,
        -spriteSize / sprite:getWidth(), -- Negative scaleX to flip horizontally
        spriteSize / sprite:getHeight()
    )

    -- Right glove (normal, on right side)
    local rightSpriteX = centerX - spriteSize / 2 + rightOffset.x
    local rightSpriteY = centerY - spriteSize / 2 + rightOffset.y
    drawSprite(
        sprite,
        rightSpriteX,
        rightSpriteY,
        0,
        spriteSize / sprite:getWidth(),
        spriteSize / sprite:getHeight()
    )
end

---Render feet (both left and right boots)
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offsets table Offsets table
local function renderFeet(sprite, spriteSize, centerX, centerY, offsets)
    local leftOffset = offsets.feetLeft or { x = 0, y = 0 }
    local rightOffset = offsets.feetRight or { x = 0, y = 0 }

    -- Left boot (flipped horizontally, on left side)
    local leftSpriteX = centerX - spriteSize / 2 + leftOffset.x + spriteSize
    local leftSpriteY = centerY - spriteSize / 2 + leftOffset.y
    drawSprite(
        sprite,
        leftSpriteX,
        leftSpriteY,
        0,
        -spriteSize / sprite:getWidth(), -- Negative scaleX to flip horizontally
        spriteSize / sprite:getHeight()
    )

    -- Right boot (normal, on right side)
    local rightSpriteX = centerX - spriteSize / 2 + rightOffset.x
    local rightSpriteY = centerY - spriteSize / 2 + rightOffset.y
    drawSprite(
        sprite,
        rightSpriteX,
        rightSpriteY,
        0,
        spriteSize / sprite:getWidth(),
        spriteSize / sprite:getHeight()
    )
end

---Calculate swing animation rotation angle
---@param combat table|nil Combat component
---@return number|nil Rotation angle in radians, or nil if not swinging
local function calculateSwingAnimation(combat)
    if not combat or not combat.swingTimer or combat.swingTimer <= 0 then
        return nil
    end

    local swingDuration = combat.swingDuration or 0.35
    local ratio = math.max(0, math.min(combat.swingTimer / swingDuration, 1))
    local progress = 1 - ratio

    -- Swing arc: start from 0 (default sprite position), swing down
    -- Small downward swing: rotate from 0 to +45 degrees
    local swingArcStart = 0  -- Start at default position (no rotation)
    local swingArcEnd = math.pi / 4  -- +45 degrees (swinging down)

    -- Use smooth easing for more natural swing motion
    local easedProgress = progress * progress * (3 - 2 * progress) -- smoothstep
    local swingAngle = swingArcStart + (swingArcEnd - swingArcStart) * easedProgress

    return swingAngle
end

---Calculate rotation origin point for weapon swing
---@param offset table Weapon offset {x, y}
---@param sprite userdata Love2D Image object
---@return number Origin X
---@return number Origin Y
local function calculateRotationOrigin(offset, sprite)
    local originX, originY

    if offset.x > 0 then
        -- Weapon offset forward (right), handle is at left edge of sprite
        originX = sprite:getWidth() * 0.05  -- Handle at left edge
        originY = sprite:getHeight() * 0.5  -- Vertical center of handle
    elseif offset.x < 0 then
        -- Weapon offset backward (left), handle is at right edge of sprite
        originX = sprite:getWidth() * 0.95  -- Handle at right edge
        originY = sprite:getHeight() * 0.5  -- Vertical center of handle
    else
        -- Centered weapon, use center as rotation point
        originX = sprite:getWidth() / 2
        originY = sprite:getHeight() / 2
    end

    return originX, originY
end

---Calculate position compensation to keep weapon base fixed during rotation
---@param rotation number Rotation angle in radians
---@param rotationOriginX number Rotation origin X
---@param rotationOriginY number Rotation origin Y
---@param sprite userdata Love2D Image object
---@param spriteSize number Scaled sprite size
---@return number Offset X
---@return number Offset Y
local function calculatePositionCompensation(rotation, rotationOriginX, rotationOriginY, sprite, spriteSize)
    if rotation == 0 then
        return 0, 0
    end

    -- Calculate how much the rotation origin offset affects the visual position
    -- When rotating around a non-center point, we need to adjust the draw position
    local cosR = math.cos(rotation)
    local sinR = math.sin(rotation)
    local originOffsetX = rotationOriginX - sprite:getWidth() / 2
    local originOffsetY = rotationOriginY - sprite:getHeight() / 2

    -- Compensate for the rotation origin offset
    local baseOffsetX = originOffsetX * (1 - cosR) + originOffsetY * sinR
    local baseOffsetY = originOffsetY * (1 - cosR) - originOffsetX * sinR

    -- Scale to sprite size
    return baseOffsetX * (spriteSize / sprite:getWidth()), baseOffsetY * (spriteSize / sprite:getHeight())
end

---Render weapon with swing animation
---@param entity table Entity with equipment and combat components
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offset table Weapon offset {x, y}
local function renderWeapon(entity, sprite, spriteSize, centerX, centerY, offset)
    -- Base sprite position
    local spriteX = centerX - spriteSize / 2 + offset.x
    local spriteY = centerY - spriteSize / 2 + offset.y

    -- Always set rotation origin to weapon base (for consistent pivot point)
    local rotationOriginX, rotationOriginY = calculateRotationOrigin(offset, sprite)

    -- When rotation origin is not at center, we need to adjust sprite position
    -- to keep the base visually in the same place
    local originOffsetX = rotationOriginX - sprite:getWidth() / 2
    local originOffsetY = rotationOriginY - sprite:getHeight() / 2
    spriteX = spriteX - originOffsetX * (spriteSize / sprite:getWidth())
    spriteY = spriteY - originOffsetY * (spriteSize / sprite:getHeight())

    local rotation = 0

    -- Calculate swing animation if active
    local swingAngle = calculateSwingAnimation(entity.combat)
    if swingAngle then
        rotation = swingAngle

        -- Adjust position to keep base fixed during rotation
        local posOffsetX, posOffsetY = calculatePositionCompensation(
            rotation,
            rotationOriginX,
            rotationOriginY,
            sprite,
            spriteSize
        )
        spriteX = spriteX - posOffsetX
        spriteY = spriteY - posOffsetY
    end

    -- Draw weapon
    drawSprite(
        sprite,
        spriteX,
        spriteY,
        rotation,
        spriteSize / sprite:getWidth(),
        spriteSize / sprite:getHeight(),
        rotationOriginX,
        rotationOriginY
    )
end

---Render normal equipment item (head, chest, etc.)
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offset table Item offset {x, y}
local function renderNormalEquipment(sprite, spriteSize, centerX, centerY, offset)
    local spriteX = centerX - spriteSize / 2 + offset.x
    local spriteY = centerY - spriteSize / 2 + offset.y

    drawSprite(
        sprite,
        spriteX,
        spriteY,
        0,
        spriteSize / sprite:getWidth(),
        spriteSize / sprite:getHeight()
    )
end

---Render equipped items on entities that have equipment
function renderEquipmentSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "equipment", "position", "size" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities
        if entity.inactive then
            goto continue
        end

        local pos = entity.position
        local size = entity.size
        local centerX = pos.x + (size.w / 2)
        local centerY = pos.y + (size.h / 2)

        local offsets = getSlotOffsets(size)

        -- Draw equipped items in order: feet (bottom), chest, gloves, head, weapon (top)
        local drawOrder = { "feet", "chest", "gloves", "head", "weapon" }

        for _, slotId in ipairs(drawOrder) do
            local item = entity.equipment[slotId]
            if item and item.spritePath then
                local sprite = Resources.loadImageSafe(item.spritePath)
                if sprite then
                    local spriteSize = math.max(size.w, size.h) * 1.2 -- Slightly larger than entity

                    if slotId == "gloves" then
                        renderGloves(sprite, spriteSize, centerX, centerY, offsets)
                    elseif slotId == "feet" then
                        renderFeet(sprite, spriteSize, centerX, centerY, offsets)
                    elseif slotId == "weapon" then
                        local offset = offsets[slotId] or { x = 1, y = 2 }
                        renderWeapon(entity, sprite, spriteSize, centerX, centerY, offset)
                    else
                        -- Normal equipment (head, chest)
                        local offset = offsets[slotId] or { x = 0, y = 0 }
                        renderNormalEquipment(sprite, spriteSize, centerX, centerY, offset)
                    end
                end
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderEquipmentSystem
