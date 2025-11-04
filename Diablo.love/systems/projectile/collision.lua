local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")
local createRecentlyDamaged = require("components.recently_damaged")
local createDead = require("components.dead")

local collisionSystem = {}

local function ensureEventQueue(world)
    world.pendingCombatEvents = world.pendingCombatEvents or {}
    return world.pendingCombatEvents
end

local function pushCombatEvent(world, payload)
    local events = ensureEventQueue(world)
    events[#events + 1] = payload
end

local function removeProjectile(world, projectile)
    world:removeEntity(projectile.id)
end

local function markRecentlyDamaged(world, target)
    if target.recentlyDamaged then
        target.recentlyDamaged.timer = target.recentlyDamaged.maxTimer or target.recentlyDamaged.timer
        return
    end

    world:addComponent(target.id, "recentlyDamaged", createRecentlyDamaged())
end

local function handleDeath(world, target, attacker, hitPosition)
    if not target then
        return
    end

    local componentsToRemove = {}
    for componentName, component in pairs(target) do
        if componentName ~= "id" and type(component) == "table" and component.removeOnDeath then
            componentsToRemove[#componentsToRemove + 1] = componentName
        end
    end

    for _, componentName in ipairs(componentsToRemove) do
        world:removeComponent(target.id, componentName)
    end

    if not target.dead then
        world:addComponent(target.id, "dead", createDead())
    end

    pushCombatEvent(world, {
        type = "death",
        targetId = target.id,
        sourceId = attacker and attacker.id or nil,
        position = hitPosition,
        time = world.time or 0,
    })

    if world.currentTargetId == target.id then
        world.currentTargetId = nil
        world.targetDisplayTimer = 0
    end

    world:removeEntity(target.id)
end

local function rollDamage(damageRange)
    if not damageRange then
        return 0
    end

    local minDamage = damageRange.min or 0
    local maxDamage = damageRange.max or minDamage
    if maxDamage < minDamage then
        maxDamage = minDamage
    end

    if maxDamage == minDamage then
        return minDamage
    end

    return math.floor(minDamage + math.random() * (maxDamage - minDamage + 1))
end

function collisionSystem.update(world, _dt)
    local projectiles = world:queryEntities({ "projectile", "position", "size" })
    if #projectiles == 0 then
        return
    end

    local foes = world:queryEntities({ "foe", "position", "size", "health" })
    if #foes == 0 then
        return
    end

    for _, projectile in ipairs(projectiles) do
        if projectile.inactive then
            goto continue_projectile
        end

        local projectileComponent = projectile.projectile
        local owner = world:getEntity(projectileComponent.ownerId)
        local projectileCenterX, projectileCenterY = coordinates.getEntityCenter(projectile)
        local projectileRadius = (projectile.size.w or projectile.size.h or 0) / 2

        for _, foe in ipairs(foes) do
            if foe.id == projectileComponent.ownerId then
                goto continue_foe
            end

            if foe.dead or not foe.health or foe.health.current <= 0 then
                goto continue_foe
            end

            local foeCenterX, foeCenterY = coordinates.getEntityCenter(foe)
            if not foeCenterX or not projectileCenterX then
                goto continue_foe
            end

            local foeRadius = (math.max(foe.size.w or 0, foe.size.h or 0)) / 2
            local distance = vector.distance(projectileCenterX, projectileCenterY, foeCenterX, foeCenterY)
            if distance > (projectileRadius + foeRadius) then
                goto continue_foe
            end

            local damage = rollDamage(projectileComponent.damage)
            if damage <= 0 then
                damage = 1
            end

            foe.health.current = math.max(0, (foe.health.current or 0) - damage)
            markRecentlyDamaged(world, foe)

            pushCombatEvent(world, {
                type = "damage",
                sourceId = projectileComponent.ownerId,
                targetId = foe.id,
                amount = damage,
                crit = false,
                position = { x = foeCenterX, y = foeCenterY },
                time = world.time or 0,
            })

            if foe.health.current <= 0 then
                handleDeath(world, foe, owner, { x = foeCenterX, y = foeCenterY })
            end

            removeProjectile(world, projectile)
            goto continue_projectile

            ::continue_foe::
        end

        ::continue_projectile::
    end
end

return collisionSystem
