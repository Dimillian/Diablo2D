local FoeRarities = require("data.foe_rarities")

local renderHealthSystem = {}

function renderHealthSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    -- Query foes with health (only show health bars for foes, not player)
    local entities = world:queryEntities({ "foe", "health", "position" })

    for _, entity in ipairs(entities) do
        if (entity.inactive and entity.inactive.isInactive) or entity.dead then
            goto continue
        end

        local health = entity.health
        local pos = entity.position
        local size = entity.size or { w = 20, h = 20 }
        local rarityId = entity.foe and entity.foe.rarity
        local rarity = rarityId and FoeRarities.getById(rarityId) or nil

        local maxHealth = health.max or 1
        local current = math.max(0, math.min(health.current or 0, maxHealth))

        -- Always show bar for elites/bosses; otherwise only when damaged
        local shouldShow = rarityId == "elite" or rarityId == "boss" or current < maxHealth
        if not shouldShow then
            goto continue
        end

        local ratio = maxHealth > 0 and (current / maxHealth) or 0

        local barWidth = math.max(size.w, 36)
        if rarityId == "boss" then
            barWidth = math.max(size.w * 1.1, 44)
        elseif rarityId == "elite" then
            barWidth = math.max(size.w * 1.05, 40)
        end
        local barHeight = 6
        local barX = pos.x + (size.w - barWidth) / 2
        local barY = pos.y - 26

        love.graphics.push("all")

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4, 3, 3)

        if rarityId == "boss" then
            love.graphics.setColor(0.2, 0.12, 0.25, 0.95)
        elseif rarityId == "elite" then
            love.graphics.setColor(0.12, 0.16, 0.25, 0.95)
        else
            love.graphics.setColor(0.15, 0.15, 0.18, 0.9)
        end
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 3, 3)

        love.graphics.setColor(0.85, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight, 3, 3)

        local frameColor = { 0.9, 0.85, 0.65, 1 }
        if rarity and rarity.tint then
            frameColor = { rarity.tint[1], rarity.tint[2], rarity.tint[3], 1 }
        end

        love.graphics.setColor(frameColor)
        love.graphics.setLineWidth(1.2)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 3, 3)

        love.graphics.pop()

        ::continue::
    end

    love.graphics.pop()
end

return renderHealthSystem
