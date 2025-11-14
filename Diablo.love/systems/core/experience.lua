local Leveling = require("modules.leveling")
local notificationBus = require("modules.notification_bus")

local experienceSystem = {}

local LEVEL_UP_ICON_PATH = "resources/icons/book.png"
local ATTRIBUTE_POINTS_PER_LEVEL = 15
local SKILL_POINTS_PER_LEVEL = 1

---Returns the level-up bonuses payload containing notification about attribute and skill points.
---@param attributePoints integer|nil
---@param skillPoints integer|nil
---@return table payload Contains bodyLines field
local function getLevelUpBonusesPayload(attributePoints, skillPoints)
    local lines = {}
    local attributes = attributePoints or ATTRIBUTE_POINTS_PER_LEVEL
    lines[#lines + 1] = string.format("%d attribute points available", attributes)

    local skills = skillPoints or SKILL_POINTS_PER_LEVEL
    if skills > 0 then
        local label = skills == 1 and "skill point" or "skill points"
        lines[#lines + 1] = string.format("%d %s available", skills, label)
    end

    return {
        bodyLines = lines,
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

    while true do
        local totalXPForNextLevel = Leveling.getXPForLevel((exp.level or 1) + 1)
        if exp.currentXP and exp.currentXP >= totalXPForNextLevel then
            exp.level = (exp.level or 1) + 1

            -- Grant 15 unallocated attribute points
            exp.unallocatedPoints = (exp.unallocatedPoints or 0) + ATTRIBUTE_POINTS_PER_LEVEL

            if player.skills then
                player.skills.availablePoints = (player.skills.availablePoints or 0) + SKILL_POINTS_PER_LEVEL
            end

            -- Restore health and mana to max on level up
            if player.health then
                player.health.current = player.health.max
            end
            if player.mana then
                player.mana.current = player.mana.max
            end

            local bonusesPayload = getLevelUpBonusesPayload(ATTRIBUTE_POINTS_PER_LEVEL, SKILL_POINTS_PER_LEVEL)
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

---Trigger a level up for the player by setting XP to required amount and applying bonuses.
---@param world WorldScene The world scene
---@param player table The player entity
function experienceSystem.triggerLevelUp(world, player)
    if not player or not player.experience then
        return
    end

    local exp = player.experience
    local currentLevel = exp.level or 1
    local nextLevel = currentLevel + 1
    local totalXPForNextLevel = Leveling.getXPForLevel(nextLevel)

    -- Set current XP to the required amount for next level
    exp.currentXP = totalXPForNextLevel

    -- Apply level up bonuses (this will increment level and grant points)
    applyLevelUpBonuses(world, player)
end

return experienceSystem
