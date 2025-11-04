local vector = require("modules.vector")

local Targeting = {
    keepAlive = 1.5,
}

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

local function ensureSceneTargetState(scene)
    if scene.currentTargetId == nil then
        return
    end

    if not scene:getEntity(scene.currentTargetId) then
        scene.currentTargetId = nil
        scene.targetDisplayTimer = 0
    end
end

function Targeting.resolveMouseTarget(scene, opts)
    opts = opts or {}
    local checkPlayerRange = opts.checkPlayerRange ~= false
    local clearOnNoTarget = opts.clearOnNoTarget == true

    local player = scene:getPlayer()
    if not player then
        return nil
    end

    local camera = scene.camera or { x = 0, y = 0 }
    local coordsHelper = scene.systemHelpers and scene.systemHelpers.coordinates
    if not coordsHelper or not coordsHelper.toWorldFromScreen then
        return nil
    end

    local combat = player.combat
    local range = opts.range or (combat and combat.range) or 120

    local mouseX, mouseY = love.mouse.getPosition()
    local worldX, worldY = coordsHelper.toWorldFromScreen(camera, mouseX, mouseY)

    local foes = scene:queryEntities({ "foe", "position" })
    local bestEntity = nil
    local bestDistance = nil

    local playerX, playerY = getEntityCenter(player)

    for _, foe in ipairs(foes) do
        if foe.health and (not foe.dead) and foe.health.current > 0 then
            local foeX, foeY = getEntityCenter(foe)
            if foeX and foeY then
                local distanceToMouse = vector.distance(worldX, worldY, foeX, foeY)

                if distanceToMouse and (range <= 0 or distanceToMouse <= range * 1.25) then
                    local distanceToPlayer = playerX and vector.distance(playerX, playerY, foeX, foeY) or math.huge
                    local inRange = not checkPlayerRange or distanceToPlayer <= range

                    if inRange then
                        if not bestDistance or distanceToMouse < bestDistance then
                            bestDistance = distanceToMouse
                            bestEntity = foe
                        end
                    end
                end
            end
        end
    end

    if bestEntity then
        scene.currentTargetId = bestEntity.id
        scene.targetDisplayTimer = Targeting.keepAlive
        return bestEntity
    end

    if clearOnNoTarget then
        Targeting.clear(scene)
    else
        ensureSceneTargetState(scene)
    end
    return nil
end

function Targeting.getCurrentTarget(scene)
    if not scene.currentTargetId then
        return nil
    end

    local target = scene:getEntity(scene.currentTargetId)
    if target and target.health and target.health.current > 0 then
        return target
    end

    scene.currentTargetId = nil
    scene.targetDisplayTimer = 0
    return nil
end

function Targeting.clear(scene)
    scene.currentTargetId = nil
    scene.targetDisplayTimer = 0
end

function Targeting.tick(scene, dt)
    if scene.targetDisplayTimer then
        scene.targetDisplayTimer = math.max((scene.targetDisplayTimer or 0) - dt, 0)
        if scene.targetDisplayTimer <= 0 then
            Targeting.clear(scene)
        end
    end
end

return Targeting
