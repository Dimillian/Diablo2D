local vector = require("modules.vector")
local Targeting = require("system_helpers.targeting")
local createRecentlyDamaged = require("components.recently_damaged")
local createDead = require("components.dead")

local combatSystem = {}

local function ensureEventQueue(world)
    world.pendingCombatEvents = world.pendingCombatEvents or {}
    return world.pendingCombatEvents
end

local function pushCombatEvent(world, payload)
    local events = ensureEventQueue(world)
    events[#events + 1] = payload
end

local function getEntityCenter(entity)
    if not entity or not entity.position then
        return nil, nil
    end

    local x = entity.position.x
    local y = entity.position.y

    if entity.size then
        x = x + (entity.size.w or 0) / 2
        y = y + (entity.size.h or 0) / 2
    end

    return x, y
end

local function computeDamage(attacker)
    local combat = attacker.combat
    local stats = attacker.stats and attacker.stats.total or nil

    local minDamage = combat.baseDamageMin or 1
    local maxDamage = combat.baseDamageMax or minDamage

    if stats then
        if stats.damageMin and stats.damageMin > 0 then
            minDamage = stats.damageMin
        end
        if stats.damageMax and stats.damageMax >= minDamage then
            maxDamage = stats.damageMax
        end
    end

    if maxDamage < minDamage then
        maxDamage = minDamage
    end

    local damage = minDamage
    if maxDamage > minDamage then
        damage = math.floor(minDamage + math.random() * (maxDamage - minDamage + 1))
    end

    damage = math.max(1, damage)

    local critChance = (stats and stats.critChance) or combat.critChance or 0
    local isCrit = false
    if critChance > 0 and math.random() < critChance then
        isCrit = true
        damage = math.max(1, math.floor(damage * 1.5 + 0.5))
    end

    return damage, isCrit
end

local function markRecentlyDamaged(world, target)
    if target.recentlyDamaged then
        target.recentlyDamaged.timer = target.recentlyDamaged.maxTimer or target.recentlyDamaged.timer
        return
    end

    local component = createRecentlyDamaged()
    world:addComponent(target.id, "recentlyDamaged", component)
end

local function handleDeath(world, target, attacker, position)
    if not target then
        return
    end

    local targetId = target.id

    local componentsToRemove = {}
    for componentName, component in pairs(target) do
        if componentName ~= "id" and type(component) == "table" and component.removeOnDeath then
            componentsToRemove[#componentsToRemove + 1] = componentName
        end
    end

    for _, componentName in ipairs(componentsToRemove) do
        world:removeComponent(targetId, componentName)
    end

    if not target.dead then
        local deadComponent = createDead()
        world:addComponent(targetId, "dead", deadComponent)
    end

    pushCombatEvent(world, {
        type = "death",
        targetId = targetId,
        sourceId = attacker and attacker.id or nil,
        position = position and { x = position.x, y = position.y } or nil,
        time = world.time or 0,
    })

    if world.currentTargetId == targetId then
        Targeting.clear(world)
    end

    world:removeEntity(targetId)
end

function combatSystem.update(world, dt)
    ensureEventQueue(world)

    local combatants = world:queryEntities({ "combat" })
    for _, entity in ipairs(combatants) do
        local combat = entity.combat
        local queued = combat.queuedAttack
        if not queued then
            goto continue
        end

        local target = world:getEntity(queued.targetId)
        if not target or not target.health or target.health.current <= 0 or target.dead then
            combat.queuedAttack = nil
            goto continue
        end

        local attackerX, attackerY = getEntityCenter(entity)
        local targetX, targetY = getEntityCenter(target)
        if not attackerX or not targetX then
            combat.queuedAttack = nil
            goto continue
        end

        local range = combat.range or queued.range or 120
        local distance = vector.distance(attackerX, attackerY, targetX, targetY)
        if distance > range then
            combat.queuedAttack = nil
            goto continue
        end

        local damage, isCrit = computeDamage(entity)

        target.health.current = math.max(0, (target.health.current or 0) - damage)

        markRecentlyDamaged(world, target)

        pushCombatEvent(world, {
            type = "damage",
            sourceId = entity.id,
            targetId = target.id,
            amount = damage,
            crit = isCrit,
            position = { x = targetX, y = targetY },
            time = world.time or 0,
        })

        if target.health.current <= 0 then
            handleDeath(world, target, entity, { x = targetX, y = targetY })
        end

        combat.queuedAttack = nil

        ::continue::
    end

    if dt and dt > 0 then
        local damagedEntities = world:queryEntities({ "recentlyDamaged" })
        for _, entity in ipairs(damagedEntities) do
            local marker = entity.recentlyDamaged
            marker.timer = (marker.timer or 0) - dt
            if marker.timer <= 0 then
                world:removeComponent(entity.id, "recentlyDamaged")
            end
        end
    end
end

return combatSystem
