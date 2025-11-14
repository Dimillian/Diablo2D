local Leveling = require("modules.leveling")
local notificationBus = require("modules.notification_bus")

local experienceSystem = {}

local LEVEL_UP_ICON_PATH = "resources/icons/book.png"

---Returns the level-up bonuses payload containing notification about attribute points.
---@return table payload Contains bodyLines field
local function getLevelUpBonusesPayload()
    return {
        bodyLines = {
            "15 attribute points available",
            "Click to open inventory",
        },
    }
end

local function queueLevelUpNotification(world, newLevel, bonusesPayload)
    if not world then
        return
    end

    bonusesPayload = bonusesPayload or getLevelUpBonusesPayload()

    notificationBus.queue(world, {
        category = "level_up",
        priority = 100,
        title = ("Level %d"):format(newLevel),
        bodyLines = bonusesPayload.bodyLines,
        iconPath = LEVEL_UP_ICON_PATH,
        onClickAction = "open_inventory",
    })
end

local function applyLevelUpBonuses(world, player)
    local exp = player.experience
    if not exp then
        return
    end

    local bonusesPayload = getLevelUpBonusesPayload()

    while true do
        local totalXPForNextLevel = Leveling.getXPForLevel((exp.level or 1) + 1)
        if exp.currentXP and exp.currentXP >= totalXPForNextLevel then
            exp.level = (exp.level or 1) + 1

            -- Grant 15 unallocated attribute points
            exp.unallocatedPoints = (exp.unallocatedPoints or 0) + 15

            -- Restore health and mana to max on level up
            if player.health then
                player.health.current = player.health.max
            end
            if player.mana then
                player.mana.current = player.mana.max
            end

            queueLevelUpNotification(world, exp.level, bonusesPayload)
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
    local xpGain = event.foeExperience or 0
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
    exp.unallocatedPoints = exp.unallocatedPoints or 0

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
