local Leveling = require("modules.leveling")
local notificationBus = require("modules.notification_bus")
local Spells = require("data.spells")

local experienceSystem = {}

local LEVEL_UP_BODY_LINES = {
    "+5 Health",
    "+5 Mana",
    "+1 Min Damage",
    "+1 Max Damage",
    "+1 Defense",
}

local LEVEL_UP_ICON_PATH = "resources/icons/book.png"

local function queueLevelUpNotification(world, newLevel)
    if not world then
        return
    end

    notificationBus.queue(world, {
        category = "level_up",
        priority = 100,
        title = ("Level %d"):format(newLevel),
        bodyLines = LEVEL_UP_BODY_LINES,
        iconPath = LEVEL_UP_ICON_PATH,
    })
end

local function applyLevelUpBonuses(world, player)
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
                player.baseStats.mana = (player.baseStats.mana or 25) + 5
            end

            if player.health then
                player.health.current = player.health.max
            end
            if player.mana then
                player.mana.current = player.mana.max
            end

            queueLevelUpNotification(world, exp.level)
        else
            break
        end
    end

    exp.xpForNextLevel = Leveling.getXPRequiredForNextLevel(exp.level)
end

local function awardExperience(world, player, event)
    if not player or not player.experience then
        return
    end

    local exp = player.experience
    local xpGain = Leveling.getFoeXP(event.foeLevel or 1, exp.level or 1)
    if xpGain <= 0 then
        return
    end

    exp.currentXP = (exp.currentXP or 0) + xpGain
    applyLevelUpBonuses(world, player)
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
                awardExperience(world, player, event)
                event._xpAwarded = true
            elseif event.type == "death" and not event._xpAwarded then
                event._xpAwarded = true
            end
        end
    end

    exp.xpForNextLevel = Leveling.getXPRequiredForNextLevel(exp.level)
end

return experienceSystem
