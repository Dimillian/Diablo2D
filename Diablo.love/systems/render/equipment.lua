local Resources = require("modules.resources")
local ComponentDefaults = require("data.component_defaults")

local renderEquipmentSystem = {}

-- Flip animation state per entity (for smooth transitions)
local flipStates = {}

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
---@param flipScale number Flip scale multiplier (unused, gloves don't flip)
local function renderGloves(sprite, spriteSize, centerX, centerY, offsets, _flipScale)
    local leftOffset = offsets.glovesLeft or { x = 0, y = 0 }
    local rightOffset = offsets.glovesRight or { x = 0, y = 0 }

    -- Gloves always render in the same position, regardless of flip direction
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
---@param flipScale number Flip scale multiplier (unused, boots don't flip)
local function renderFeet(sprite, spriteSize, centerX, centerY, offsets, _flipScale)
    local leftOffset = offsets.feetLeft or { x = 0, y = 0 }
    local rightOffset = offsets.feetRight or { x = 0, y = 0 }

    -- Boots always render in the same position, regardless of flip direction
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

---Calculate flip direction and smooth transition
---@param entity table Entity with movement component
---@param dt number Delta time for smooth animation
---@return number Flip scale (1.0 for right, -1.0 for left, with smooth transition)
local function calculateFlipDirection(entity, dt)
    dt = dt or 0.016 -- Default to ~60fps if dt not provided

    -- Get look direction from movement component
    local lookDirection = entity.movement and entity.movement.lookDirection
    if not lookDirection then
        return 1.0 -- Default to facing right
    end

    -- Determine target flip direction based on lookDirection.x
    -- Negative x = looking left, positive x = looking right
    local targetFlip = (lookDirection.x < 0) and -1.0 or 1.0

    -- Initialize flip state for this entity if needed
    if not flipStates[entity.id] then
        flipStates[entity.id] = 1.0 -- Start facing right
    end

    -- Smoothly interpolate towards target flip direction
    local currentFlip = flipStates[entity.id]
    local flipSpeed = 15.0 -- Speed of flip transition (higher = faster)
    local flipDiff = targetFlip - currentFlip

    if math.abs(flipDiff) > 0.01 then
        -- Lerp towards target
        flipStates[entity.id] = currentFlip + flipDiff * math.min(flipSpeed * dt, 1.0)
    else
        -- Snap to target if close enough
        flipStates[entity.id] = targetFlip
    end

    return flipStates[entity.id]
end

---Calculate stab animation position offset (diagonal upward motion)
---@param combat table|nil Combat component
---@return number|nil Offset X for stab motion
---@return number|nil Offset Y for stab motion (negative = upward)
---@return number|nil Rotation angle in radians (slight tilt for dynamic feel)
local function calculateStabAnimation(combat)
    if not combat or not combat.swingTimer or combat.swingTimer <= 0 then
        return nil, nil, nil
    end

    local swingDuration = combat.swingDuration or ComponentDefaults.COMBAT_SWING_DURATION
    local ratio = math.max(0, math.min(combat.swingTimer / swingDuration, 1))
    local progress = 1 - ratio

    -- Reduced distances for more controlled animation
    local maxStabForward = 12  -- pixels forward (reduced from 24)
    local maxStabUpward = -14  -- pixels upward (reduced from -26)
    local maxStabRotation = math.pi / 12  -- ~15 degrees tilt forward (reduced from ~20)

    -- Two-phase animation: forward (0-0.5) then back (0.5-1.0)
    local phaseProgress
    if progress < 0.5 then
        -- Forward phase: 0 to 0.5 maps to 0 to 1
        phaseProgress = progress * 2
        -- Ease out for snappy forward motion
        phaseProgress = 1 - math.pow(1 - phaseProgress, 2)
    else
        -- Return phase: 0.5 to 1.0 maps to 1 to 0
        phaseProgress = (1 - progress) * 2
        -- Ease in for smooth return
        phaseProgress = math.pow(phaseProgress, 2)
    end

    -- Calculate position offsets (forward then back)
    local stabOffsetX = maxStabForward * phaseProgress
    local stabOffsetY = maxStabUpward * phaseProgress
    -- Rotation follows the same pattern
    local stabRotation = maxStabRotation * phaseProgress

    return stabOffsetX, stabOffsetY, stabRotation
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


---Render weapon with swing animation
---@param entity table Entity with equipment and combat components
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offset table Weapon offset {x, y}
---@param flipScale number Flip scale multiplier (1.0 or -1.0)
local function renderWeapon(entity, sprite, spriteSize, centerX, centerY, offset, flipScale)
    flipScale = flipScale or 1.0

    -- Simple: invert offset.x when flipped left (same distance, opposite direction)
    local adjustedOffset = {
        x = offset.x * flipScale,
        y = offset.y
    }

    -- Base sprite position
    local spriteX = centerX - spriteSize / 2 + adjustedOffset.x
    local spriteY = centerY - spriteSize / 2 + adjustedOffset.y

    -- Set rotation origin to weapon base (for swing animation)
    local rotationOriginX, rotationOriginY = calculateRotationOrigin(adjustedOffset, sprite)

    -- Adjust sprite position to account for rotation origin offset
    local originOffsetX = rotationOriginX - sprite:getWidth() / 2
    local originOffsetY = rotationOriginY - sprite:getHeight() / 2
    spriteX = spriteX - originOffsetX * (spriteSize / sprite:getWidth())
    spriteY = spriteY - originOffsetY * (spriteSize / sprite:getHeight())

    local rotation = 0

    -- Calculate stab animation if active (diagonal upward motion)
    local stabOffsetX, stabOffsetY, stabRotation = calculateStabAnimation(entity.combat)
    if stabOffsetX and stabOffsetY then
        -- Apply stab position offset (diagonal upward)
        -- Adjust direction based on flipScale so stab goes forward relative to character facing
        spriteX = spriteX + stabOffsetX * flipScale
        spriteY = spriteY + stabOffsetY

        -- Apply slight rotation for dynamic stab feel
        if stabRotation then
            rotation = stabRotation * flipScale  -- Rotate in direction of facing
        end
    end

    -- Draw with rotation origin
    -- The offset inversion already positions it correctly, just flip the sprite
    drawSprite(
        sprite,
        spriteX,
        spriteY,
        rotation,
        spriteSize / sprite:getWidth() * flipScale, -- Flip horizontally
        spriteSize / sprite:getHeight(),
        rotationOriginX, -- Rotation origin
        rotationOriginY
    )
end

---Render normal equipment item (head, chest, etc.)
---@param sprite userdata Love2D Image object
---@param spriteSize number Size of sprite to render
---@param centerX number Entity center X
---@param centerY number Entity center Y
---@param offset table Item offset {x, y}
---@param flipScale number Flip scale multiplier (1.0 or -1.0)
local function renderNormalEquipment(sprite, spriteSize, centerX, centerY, offset, flipScale)
    flipScale = flipScale or 1.0

    -- Use sprite center as origin point for flipping to maintain center axis
    local originX = sprite:getWidth() / 2
    local originY = sprite:getHeight() / 2

    -- When origin is (0,0), sprite top-left is at (x, y)
    -- When origin is (width/2, height/2), sprite center is at (x, y)
    -- Original code used: spriteX = centerX - spriteSize/2 + offset.x (top-left positioning)
    -- To maintain same visual position with center origin, we need:
    -- sprite center = centerX - spriteSize/2 + offset.x + spriteSize/2 = centerX + offset.x
    local spriteX = centerX + offset.x
    local spriteY = centerY + offset.y

    drawSprite(
        sprite,
        spriteX,
        spriteY,
        0,
        spriteSize / sprite:getWidth() * flipScale, -- Apply flip direction
        spriteSize / sprite:getHeight(),
        originX, -- Center origin for flip to maintain center axis
        originY
    )
end

---Render equipment for a single entity (helper function for reuse)
---@param entity table Entity with equipment, position, and size components
---@param centerX number Entity center X coordinate
---@param centerY number Entity center Y coordinate
---@param flipScale number Flip scale multiplier (1.0 or -1.0)
local function renderEntityEquipment(entity, centerX, centerY, flipScale)
    if not entity.equipment or not entity.size then
        return
    end

    local size = entity.size
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
                    renderGloves(sprite, spriteSize, centerX, centerY, offsets, flipScale)
                elseif slotId == "feet" then
                    renderFeet(sprite, spriteSize, centerX, centerY, offsets, flipScale)
                elseif slotId == "weapon" then
                    local offset = offsets[slotId] or { x = 1, y = 2 }
                    renderWeapon(entity, sprite, spriteSize, centerX, centerY, offset, flipScale)
                else
                    -- Normal equipment (head, chest)
                    local offset = offsets[slotId] or { x = 0, y = 0 }
                    renderNormalEquipment(sprite, spriteSize, centerX, centerY, offset, flipScale)
                end
            end
        end
    end
end

---Render equipped items on entities that have equipment
function renderEquipmentSystem.draw(world)
    -- Use lastUpdateDt for smooth animation, default to ~60fps if not available
    local dt = world.lastUpdateDt or 0.016
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "equipment", "position", "size" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities
        if entity.inactive and entity.inactive.isInactive then
            goto continue
        end

        -- Skip player-controlled entities (rendered by renderPlayerSystem)
        if entity.playerControlled then
            goto continue
        end

        local pos = entity.position
        local size = entity.size

        -- Calculate walking wobble rotation
        local wobbleRotation = calculateWalkWobble(entity)

        local centerX = pos.x + (size.w / 2)
        local centerY = pos.y + (size.h / 2)

        -- Calculate flip direction based on look direction
        local flipScale = calculateFlipDirection(entity, dt)

        -- Apply rotation around entity center for walking wobble
        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.rotate(wobbleRotation)
        love.graphics.translate(-centerX, -centerY)

        renderEntityEquipment(entity, centerX, centerY, flipScale)

        -- Pop rotation transform after drawing all equipment for this entity
        love.graphics.pop()

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

-- Export helper functions for reuse by other systems
renderEquipmentSystem.renderEntityEquipment = renderEntityEquipment
renderEquipmentSystem.calculateFlipDirection = calculateFlipDirection

return renderEquipmentSystem
