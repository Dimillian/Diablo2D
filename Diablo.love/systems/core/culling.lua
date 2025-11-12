local vector = require("modules.vector")
local createInactive = require("components.inactive")

local function setInactiveState(world, entity, isInactive)
    if not entity then
        return
    end

    if not entity.inactive then
        if not entity.id then
            return
        end
        world:addComponent(entity.id, "inactive", createInactive({ isInactive = isInactive }))
        return
    end

    entity.inactive.isInactive = isInactive
end

local cullingSystem = {}

-- Configuration
local CULLING_CONFIG = {
    -- Distance beyond which entities become inactive (stop updating)
    inactiveDistance = 1000,
    -- Distance beyond which entities are despawned (removed entirely)
    despawnDistance = 1500,
    -- Check every N seconds instead of every frame for performance
    checkInterval = 0.5,
}

local INACTIVE_DISTANCE_SQUARED = CULLING_CONFIG.inactiveDistance * CULLING_CONFIG.inactiveDistance
local DESPAWN_DISTANCE_SQUARED = CULLING_CONFIG.despawnDistance * CULLING_CONFIG.despawnDistance

function cullingSystem.update(world, dt)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    -- Update check timer
    world.cullingTimer = (world.cullingTimer or 0) + dt
    if world.cullingTimer < CULLING_CONFIG.checkInterval then
        return
    end
    world.cullingTimer = 0

    local playerX = player.position.x
    local playerY = player.position.y

    -- Query all entities (except player)
    local allEntities = {}
    for id, entity in pairs(world.entities) do
        if id ~= world.playerId then
            table.insert(allEntities, entity)
        end
    end

    local entitiesToRemove = {}

    for _, entity in ipairs(allEntities) do
        if not entity.position then
            goto continue
        end

        local distSquared = vector.distanceSquared(
            playerX,
            playerY,
            entity.position.x,
            entity.position.y
        )

        if entity.chunkResident then
            if distSquared > INACTIVE_DISTANCE_SQUARED then
                setInactiveState(world, entity, true)
            else
                setInactiveState(world, entity, false)
            end
            goto continue
        end

        -- Despawn entities that are very far away
        if distSquared > DESPAWN_DISTANCE_SQUARED then
            table.insert(entitiesToRemove, entity.id)
            goto continue
        end

        -- Mark entities as active/inactive based on distance
        if distSquared > INACTIVE_DISTANCE_SQUARED then
            setInactiveState(world, entity, true)
        else
            setInactiveState(world, entity, false)
        end

        ::continue::
    end

    -- Remove despawned entities
    for _, entityId in ipairs(entitiesToRemove) do
        world:removeEntity(entityId)
    end
end

return cullingSystem
