local potionConsumptionSystem = {}

local function getPlayerPotions(world)
    local player = world and world:getPlayer()
    if not player or not player.potions then
        return nil, nil
    end
    return player, player.potions
end

local function isOnCooldown(potions)
    return (potions.cooldownRemaining or 0) > 0
end

local function startCooldown(world, potions)
    potions.cooldownRemaining = potions.cooldownDuration or 0
    if potions.cooldownRemaining <= 0 then
        potions.cooldownRemaining = 0.5
    end
    if world and world.time then
        potions.lastUseTime = world.time
    elseif love and love.timer and love.timer.getTime then
        potions.lastUseTime = love.timer.getTime()
    end
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function consumeHealthPotion(world, player, potions)
    if potions.healthPotionCount <= 0 then
        return false
    end

    local health = player.health
    if not health or health.current >= health.max then
        return false
    end

    if isOnCooldown(potions) then
        return false
    end

    health.current = clamp(health.current + 25, 0, health.max)
    potions.healthPotionCount = math.max(0, potions.healthPotionCount - 1)
    startCooldown(world, potions)
    potions.lastUsedType = "health"
    return true
end

local function consumeManaPotion(world, player, potions)
    if potions.manaPotionCount <= 0 then
        return false
    end

    local mana = player.mana
    if not mana or mana.current >= mana.max then
        return false
    end

    if isOnCooldown(potions) then
        return false
    end

    mana.current = clamp(mana.current + 15, 0, mana.max)
    potions.manaPotionCount = math.max(0, potions.manaPotionCount - 1)
    startCooldown(world, potions)
    potions.lastUsedType = "mana"
    return true
end

local function consume(world, potionType)
    local player, potions = getPlayerPotions(world)
    if not player then
        return false
    end

    if potionType == "health" then
        return consumeHealthPotion(world, player, potions)
    elseif potionType == "mana" then
        return consumeManaPotion(world, player, potions)
    end

    return false
end

function potionConsumptionSystem.update(world, dt)
    local _, potions = getPlayerPotions(world)
    if not potions then
        return
    end

    if potions.cooldownRemaining and potions.cooldownRemaining > 0 then
        potions.cooldownRemaining = math.max(0, potions.cooldownRemaining - (dt or 0))
        if potions.cooldownRemaining == 0 then
            potions.lastUsedType = nil
        end
    end
end

function potionConsumptionSystem.handleKeypress(world, key)
    if key == "5" then
        return consume(world, "health")
    elseif key == "6" then
        return consume(world, "mana")
    end

    return false
end

function potionConsumptionSystem.handleClick(world, potionType)
    return consume(world, potionType)
end

return potionConsumptionSystem
