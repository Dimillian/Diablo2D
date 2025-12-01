local Targeting = require("systems.helpers.targeting")
local FoeRarities = require("data.foe_rarities")

local uiTargetSystem = {}

function uiTargetSystem.draw(world)
    local target = Targeting.getCurrentTarget(world)
    if not target then
        return
    end

    local health = target.health
    if not health then
        return
    end

    local maxHealth = health.max or 1
    local current = math.max(0, math.min(health.current or 0, maxHealth))
    local ratio = maxHealth > 0 and (current / maxHealth) or 0

    local screenWidth = love.graphics.getWidth()
    local rarityId = target.foe and target.foe.rarity
    local rarity = rarityId and FoeRarities.getById(rarityId) or nil

    local frameWidth = rarityId == "boss" and math.min(screenWidth * 0.65, 420) or math.min(screenWidth * 0.5, 320)
    local frameHeight = 80
    local frameX = (screenWidth - frameWidth) / 2
    local frameY = rarityId == "boss" and 14 or 20

    love.graphics.push("all")

    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", frameX - 6, frameY - 6, frameWidth + 12, frameHeight + 12, 12, 12)

    if rarityId == "boss" then
        love.graphics.setColor(0.15, 0.08, 0.18, 0.95)
    elseif rarityId == "elite" then
        love.graphics.setColor(0.08, 0.1, 0.2, 0.95)
    else
        love.graphics.setColor(0.12, 0.12, 0.16, 0.95)
    end
    love.graphics.rectangle("fill", frameX, frameY, frameWidth, frameHeight, 10, 10)

    local frameColor = { 0.75, 0.7, 0.5, 1 }
    if rarity and rarity.tint then
        frameColor = { rarity.tint[1], rarity.tint[2], rarity.tint[3], 1 }
    end

    love.graphics.setColor(frameColor)
    love.graphics.setLineWidth(2.4)
    love.graphics.rectangle("line", frameX, frameY, frameWidth, frameHeight, 10, 10)

    local padding = 16
    local nameY = frameY + padding
    local barHeight = 18
    local barSpacing = 12
    local barY = frameY + padding + barSpacing + love.graphics.getFont():getHeight()
    local name = target.name or "Unknown"

    local label = rarity and rarity.label
    local showLabel = label and (rarityId == "boss" or rarityId == "elite")
    local showName = true

    love.graphics.setColor(frameColor[1], frameColor[2], frameColor[3], 0.95)
    if showLabel then
        love.graphics.print(label, frameX + padding, nameY)
        if showName then
            love.graphics.setColor(0.95, 0.9, 0.7, 1)
            love.graphics.print(name, frameX + padding, nameY + 18)
            barY = barY + 12
        end
    elseif showName then
        love.graphics.print(name, frameX + padding, nameY)
    end

    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", frameX + padding, barY, frameWidth - padding * 2, barHeight, 6, 6)

    love.graphics.setColor(0.85, 0.25, 0.25, 1)
    love.graphics.rectangle(
        "fill",
        frameX + padding,
        barY,
        (frameWidth - padding * 2) * ratio,
        barHeight,
        6,
        6
    )

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", frameX + padding, barY, frameWidth - padding * 2, barHeight, 6, 6)

    local text = string.format("%d / %d", math.floor(current + 0.5), math.floor(maxHealth + 0.5))
    love.graphics.printf(text, frameX + padding, barY + 2, frameWidth - padding * 2, "center")

    love.graphics.pop()
end

return uiTargetSystem
