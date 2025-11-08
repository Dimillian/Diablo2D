local Leveling = {}

function Leveling.getXPForLevel(targetLevel)
    local baseXP = 100
    local multiplier = 1.5

    if not targetLevel or targetLevel <= 1 then
        return 0
    end

    local totalXP = 0
    for level = 2, targetLevel do
        totalXP = totalXP + math.floor(baseXP * (multiplier ^ (level - 2)))
    end

    return totalXP
end

function Leveling.getXPRequiredForNextLevel(currentLevel)
    local baseXP = 100
    local multiplier = 1.5

    if not currentLevel or currentLevel < 1 then
        return baseXP
    end

    return math.floor(baseXP * (multiplier ^ (currentLevel - 1)))
end

return Leveling
