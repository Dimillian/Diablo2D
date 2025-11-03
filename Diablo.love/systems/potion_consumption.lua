local potionConsumptionSystem = {}

function potionConsumptionSystem.update(world, dt)
    local player = world:getPlayer()
    if not player or not player.potions then
        return
    end

    -- Decrement cooldown each frame
    if player.potions.cooldownRemaining and player.potions.cooldownRemaining > 0 then
        player.potions.cooldownRemaining = math.max(0, player.potions.cooldownRemaining - dt)
    end
end

function potionConsumptionSystem.handleKeypress(world, key)
    local player = world:getPlayer()
    if not player or not player.potions then
        return
    end

    -- Handle health potion (key "1")
    if key == "1" then
        if player.potions.healthPotionCount <= 0 then
            return
        end

        if not player.health then
            return
        end

        if player.potions.cooldownRemaining and player.potions.cooldownRemaining > 0 then
            return
        end

        -- Restore health
        local Items = require("data.items")
        local potionType = Items.types.health_potion
        local restoreAmount = potionType.restoreHealth or 25
        player.health.current = math.min(player.health.max, player.health.current + restoreAmount)

        -- Decrement count
        player.potions.healthPotionCount = player.potions.healthPotionCount - 1

        -- Set cooldown
        player.potions.cooldownRemaining = 0.5
    end

    -- Handle mana potion (key "2")
    if key == "2" then
        if player.potions.manaPotionCount <= 0 then
            return
        end

        if not player.mana then
            return
        end

        if player.potions.cooldownRemaining and player.potions.cooldownRemaining > 0 then
            return
        end

        -- Restore mana
        local Items = require("data.items")
        local potionType = Items.types.mana_potion
        local restoreAmount = potionType.restoreMana or 15
        player.mana.current = math.min(player.mana.max, player.mana.current + restoreAmount)

        -- Decrement count
        player.potions.manaPotionCount = player.potions.manaPotionCount - 1

        -- Set cooldown
        player.potions.cooldownRemaining = 0.5
    end
end

function potionConsumptionSystem.handleClick(world, x, y)
    local player = world:getPlayer()
    if not player or not player.potions then
        return false
    end

    -- Check health potion icon click
    if world.bottomBarHealthPotionRect then
        local rect = world.bottomBarHealthPotionRect
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            potionConsumptionSystem.handleKeypress(world, "1")
            return true
        end
    end

    -- Check mana potion icon click
    if world.bottomBarManaPotionRect then
        local rect = world.bottomBarManaPotionRect
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            potionConsumptionSystem.handleKeypress(world, "2")
            return true
        end
    end

    return false
end

return potionConsumptionSystem
