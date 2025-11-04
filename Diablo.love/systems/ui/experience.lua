local Leveling = require("modules.leveling")

local uiExperienceSystem = {}

function uiExperienceSystem.draw(world)
    local player = world:getPlayer()
    if not player or not player.experience then
        return
    end

    local exp = player.experience
    local level = exp.level or 1
    local currentXP = exp.currentXP or 0

    local totalXPForCurrentLevel = Leveling.getXPForLevel(level)
    local totalXPForNextLevel = Leveling.getXPForLevel(level + 1)
    local xpProgress = currentXP - totalXPForCurrentLevel
    local xpRequired = totalXPForNextLevel - totalXPForCurrentLevel

    xpProgress = math.max(0, xpProgress)
    xpRequired = math.max(0, xpRequired)

    local ratio = xpRequired > 0 and math.min(1, xpProgress / xpRequired) or 1

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local barHeight = 20
    local barWidth = screenWidth - 32
    local barX = 16
    local barY = screenHeight - barHeight - 8

    love.graphics.push("all")

    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4, 4)

    love.graphics.setColor(0.2, 0.6, 1.0, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight, 4, 4)

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 4, 4)

    love.graphics.setColor(1, 1, 1, 1)
    local displayProgress = math.floor(xpProgress + 0.5)
    local displayRequired = xpRequired > 0 and math.floor(xpRequired + 0.5) or 0
    local text = string.format("Level %d | %d / %d XP", level, displayProgress, displayRequired)
    love.graphics.printf(text, barX, barY + (barHeight / 2) - 6, barWidth, "center")

    love.graphics.pop()
end

return uiExperienceSystem
