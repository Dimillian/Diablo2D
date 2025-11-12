local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")
local ComponentDefaults = require("data.component_defaults")

local Targeting = {}

local function getPlayerTargeting(world)
    if not world or not world.getPlayer then
        return nil, nil
    end

    local player = world:getPlayer()
    if not player then
        return nil, nil
    end

    return player.targeting, player
end

local function getKeepAliveDuration(targeting)
    if not targeting then
        return ComponentDefaults.TARGET_KEEP_ALIVE
    end

    return targeting.keepAlive or ComponentDefaults.TARGET_KEEP_ALIVE
end

local function ensureCurrentTarget(world, targeting)
    if not targeting or not targeting.currentTargetId then
        return
    end

    local target = world:getEntity(targeting.currentTargetId)
    if target and target.health and target.health.current > 0 then
        return
    end

    targeting.currentTargetId = nil
    targeting.displayTimer = 0
end

local function isEntityAttackable(entity)
    if not entity or not entity.health then
        return false
    end

    if entity.dead then
        return false
    end

    if entity.health.current <= 0 then
        return false
    end

    if entity.inactive and entity.inactive.isInactive then
        return false
    end

    return true
end

function Targeting.resolveMouseTarget(world, opts)
    opts = opts or {}
    local checkPlayerRange = opts.checkPlayerRange ~= false
    local clearOnNoTarget = opts.clearOnNoTarget == true

    local targeting, player = getPlayerTargeting(world)
    if not targeting or not player then
        return nil
    end

    local coordsHelper = (world.systemHelpers and world.systemHelpers.coordinates) or coordinates
    if not coordsHelper or not coordsHelper.toWorldFromScreen then
        return nil
    end

    local combat = player.combat
    local range = opts.range or (combat and combat.range) or ComponentDefaults.DEFAULT_COMBAT_RANGE

    local mouseX, mouseY = love.mouse.getPosition()
    local worldX, worldY = coordsHelper.toWorldFromScreen(world.camera or { x = 0, y = 0 }, mouseX, mouseY)

    local foes = world:queryEntities({ "foe", "position" })
    local bestEntity
    local bestDistance

    local playerX, playerY = coordinates.getEntityCenter(player)

    for _, foe in ipairs(foes) do
        if isEntityAttackable(foe) then
            local foeX, foeY = coordinates.getEntityCenter(foe)
            if foeX and foeY then
                local distanceToMouse = vector.distance(worldX, worldY, foeX, foeY)
                if range <= 0 or distanceToMouse <= range * 1.25 then
                    local inRange = true
                    if checkPlayerRange and playerX then
                        local distanceToPlayer = vector.distance(playerX, playerY, foeX, foeY)
                        inRange = distanceToPlayer <= range
                    end

                    if inRange and (not bestDistance or distanceToMouse < bestDistance) then
                        bestDistance = distanceToMouse
                        bestEntity = foe
                    end
                end
            end
        end
    end

    if bestEntity then
        targeting.currentTargetId = bestEntity.id
        targeting.displayTimer = getKeepAliveDuration(targeting)
        return bestEntity
    end

    if clearOnNoTarget then
        Targeting.clear(world)
    else
        ensureCurrentTarget(world, targeting)
    end

    return nil
end

function Targeting.getCurrentTarget(world)
    local targeting = getPlayerTargeting(world)
    if not targeting then
        return nil
    end

    ensureCurrentTarget(world, targeting)

    if not targeting.currentTargetId then
        return nil
    end

    return world:getEntity(targeting.currentTargetId)
end

function Targeting.clear(world)
    local targeting = getPlayerTargeting(world)
    if not targeting then
        return
    end

    targeting.currentTargetId = nil
    targeting.displayTimer = 0
end

function Targeting.clearIfMatches(world, entityId)
    if not entityId then
        return
    end

    local targeting = getPlayerTargeting(world)
    if not targeting then
        return
    end

    if targeting.currentTargetId == entityId then
        targeting.currentTargetId = nil
        targeting.displayTimer = 0
    end
end

function Targeting.tick(world, dt)
    local targeting = getPlayerTargeting(world)
    if not targeting then
        return
    end

    if targeting.displayTimer then
        targeting.displayTimer = math.max((targeting.displayTimer or 0) - dt, 0)
        if targeting.displayTimer <= 0 then
            Targeting.clear(world)
        end
    end
end

return Targeting
