local spriteDirection = require("systems.helpers.sprite_direction")
local spriteRenderer = require("systems.helpers.sprite_renderer")
local Resources = require("modules.resources")

local renderFoeSystem = {}

function renderFoeSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "foe", "renderable", "position", "size", "movement" })

    for _, entity in ipairs(entities) do
        if entity.inactive then
            goto continue
        end

        local renderable = entity.renderable
        if not renderable.spritePrefix then
            goto continue
        end

        local lookDir = entity.movement.lookDirection or { x = 0, y = 1 }
        local row = spriteDirection.getSpriteRow(lookDir)
        local walkTime = entity.movement.walkAnimationTime or 0
        local animationState = renderable.animationState or "idle"

        local spriteSheetPath
        local totalFrames

        if animationState == "attacking" then
            spriteSheetPath = Resources.getFoeSpritePath(renderable.spritePrefix, "attack")
            totalFrames = 8
            local attackTime = entity.combat and entity.combat.attackAnimationTime or 0
            local swingDuration = entity.combat and entity.combat.swingDuration or 0.3
            -- luacheck: ignore
            local col = spriteRenderer.getAnimationFrame(animationState, walkTime, attackTime, swingDuration, totalFrames)
            local image, quad = spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, 8)

            if image and quad then
                -- luacheck: no unused
                local qx, qy, qw, qh = quad:getViewport()
                local centerX = entity.position.x + (entity.size.w / 2)
                local centerY = entity.position.y + (entity.size.h / 2)

                if entity.recentlyDamaged then
                    love.graphics.setColor(1, 0.3, 0.3, 1)
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end

                love.graphics.push()
                love.graphics.translate(centerX, centerY)
                love.graphics.scale(1.5, 1.5)
                love.graphics.translate(-centerX, -centerY)

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

                love.graphics.pop()
            end
        else
            spriteSheetPath = Resources.getFoeSpritePath(renderable.spritePrefix, "walk")
            totalFrames = 6
            local col = spriteRenderer.getAnimationFrame(animationState, walkTime, 0, 0, totalFrames)
            local image, quad = spriteRenderer.getSpriteQuad(spriteSheetPath, row, col, 6)

            if image and quad then
                -- luacheck: no unused
                local qx, qy, qw, qh = quad:getViewport()
                local centerX = entity.position.x + (entity.size.w / 2)
                local centerY = entity.position.y + (entity.size.h / 2)

                if entity.recentlyDamaged then
                    love.graphics.setColor(1, 0.3, 0.3, 1)
                else
                    love.graphics.setColor(1, 1, 1, 1)
                end

                love.graphics.push()
                love.graphics.translate(centerX, centerY)
                love.graphics.scale(1.5, 1.5)
                love.graphics.translate(-centerX, -centerY)

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

                love.graphics.pop()
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderFoeSystem
