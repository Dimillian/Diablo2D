local spriteDirection = require("systems.helpers.sprite_direction")
local spriteRenderer = require("systems.helpers.sprite_renderer")
local Resources = require("modules.resources")
local foeTypes = require("data.foe_types")

local renderFoeSystem = {}

local function getDamageFlashProgress(entity)
    local marker = entity.recentlyDamaged
    if not marker then
        return nil
    end

    local maxTimer = marker.maxTimer or 0
    if maxTimer <= 0 then
        return nil
    end

    local timer = math.max(0, marker.timer or 0)
    return math.max(0, math.min(timer / maxTimer, 1))
end

local function getSpriteColumnCount(entity, animationType)
    -- Default column counts for backward compatibility
    local defaults = {
        attack = 8,
        death = 8,
        walk = 6,
    }

    if not entity.foe or not entity.foe.typeId then
        return defaults[animationType] or 8
    end

    local config = foeTypes.getConfig(entity.foe.typeId)
    if config and config.spriteColumns and config.spriteColumns[animationType] then
        return config.spriteColumns[animationType]
    end

    return defaults[animationType] or 8
end

local function drawFoeFrame(entity, image, quad, baseScale)
    local centerX = entity.position.x + (entity.size.w / 2)
    local centerY = entity.position.y + (entity.size.h / 2)
    local _, _, qw, qh = quad:getViewport()

    local flashProgress = getDamageFlashProgress(entity)
    local scale = (baseScale or 1.5)
    if flashProgress then
        scale = scale * (1 + 0.08 * flashProgress)
    end

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-centerX, -centerY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        image,
        quad,
        centerX,
        centerY,
        0,
        1,
        1,
        qw / 2,
        qh / 2
    )

    if flashProgress then
        local flashAlpha = 0.45 + (0.35 * flashProgress)
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(1, 1, 1, flashAlpha)
        love.graphics.draw(
            image,
            quad,
            centerX,
            centerY,
            0,
            1,
            1,
            qw / 2,
            qh / 2
        )
        love.graphics.setBlendMode("alpha")
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

function renderFoeSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "foe", "renderable", "position", "size" })

    for _, entity in ipairs(entities) do
        if entity.inactive then
            goto continue
        end

        local renderable = entity.renderable
        if not renderable.spritePrefix then
            goto continue
        end

        -- Get look direction from movement if available, otherwise use default
        local lookDir = { x = 0, y = 1 }
        if entity.movement and entity.movement.lookDirection then
            lookDir = entity.movement.lookDirection
        end
        local row = spriteDirection.getSpriteRow(lookDir)
        local walkTime = entity.movement and entity.movement.walkAnimationTime or 0
        local animationState = renderable.animationState or "idle"

        local spriteSheetPath
        local totalFrames

        if animationState == "dying" then
            spriteSheetPath = Resources.getFoeSpritePath(renderable.spritePrefix, "death")
            local deathAnim = entity.deathAnimation
            if deathAnim then
                totalFrames = deathAnim.totalFrames or getSpriteColumnCount(entity, "death")

                -- Calculate frame based on animation progress
                local timer = deathAnim.timer or 0

                local col
                if timer >= deathAnim.animationDuration then
                    -- Hold last frame after animation completes
                    col = totalFrames - 1
                else
                    -- Play through frames during animation phase
                    local animProgress = timer / deathAnim.animationDuration
                    col = math.floor(animProgress * totalFrames)
                    col = math.min(col, totalFrames - 1)
                end

                local image, quad = spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, totalFrames)
                if image and quad then
                    drawFoeFrame(entity, image, quad, 1.5)
                end
            end
        elseif animationState == "attacking" then
            spriteSheetPath = Resources.getFoeSpritePath(renderable.spritePrefix, "attack")
            totalFrames = getSpriteColumnCount(entity, "attack")
            local attackTime = entity.combat and entity.combat.attackAnimationTime or 0
            local swingDuration = entity.combat and entity.combat.swingDuration or 0.3
            local col = spriteRenderer.getAnimationFrame(
                animationState, walkTime, attackTime, swingDuration, totalFrames
            )
            local image, quad = spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, totalFrames)

            if image and quad then
                drawFoeFrame(entity, image, quad, 1.5)
            end
        else
            spriteSheetPath = Resources.getFoeSpritePath(renderable.spritePrefix, "walk")
            totalFrames = getSpriteColumnCount(entity, "walk")
            local col = spriteRenderer.getAnimationFrame(animationState, walkTime, 0, 0, totalFrames)
            local image, quad = spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, totalFrames)

            if image and quad then
                drawFoeFrame(entity, image, quad, 1.5)
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderFoeSystem
