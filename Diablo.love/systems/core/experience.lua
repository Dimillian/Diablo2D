local Leveling = require("modules.leveling")

local experienceSystem = {}

local function applyLevelUpBonuses(player)
    local exp = player.experience
    if not exp then
        return
    end

    while true do
        local totalXPForNextLevel = Leveling.getXPForLevel((exp.level or 1) + 1)
        if exp.currentXP and exp.currentXP >= totalXPForNextLevel then
            exp.level = (exp.level or 1) + 1

            if player.baseStats then
                player.baseStats.damageMin = (player.baseStats.damageMin or 5) + 1
                player.baseStats.damageMax = (player.baseStats.damageMax or 8) + 1
                player.baseStats.defense = (player.baseStats.defense or 2) + 1
                player.baseStats.health = (player.baseStats.health or 50) + 5
            end
        else
            break
        end
    end

    exp.xpForNextLevel = Leveling.getXPRequiredForNextLevel(exp.level)
end

local function awardExperience(player, event)
    if not player or not player.experience then
        return
    end

    local exp = player.experience
    local xpGain = Leveling.getFoeXP(event.foeLevel or 1, exp.level or 1)
    if xpGain <= 0 then
        return
    end

    exp.currentXP = (exp.currentXP or 0) + xpGain
    applyLevelUpBonuses(player)
end

function experienceSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.experience then
        return
    end

    local exp = player.experience
    exp.level = exp.level or 1
    exp.currentXP = exp.currentXP or 0

    local events = world.pendingCombatEvents
    if events and #events > 0 then
        for _, event in ipairs(events) do
            if event.type == "death" and not event._xpAwarded and event.sourceId == player.id then
                awardExperience(player, event)
                event._xpAwarded = true
            elseif event.type == "death" and not event._xpAwarded then
                event._xpAwarded = true
            end
        end
    end

    exp.xpForNextLevel = Leveling.getXPRequiredForNextLevel(exp.level)
end

return experienceSystem
