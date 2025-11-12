local DeathHelper = require("systems.helpers.death")
local foeTypes = require("data.foe_types")

local deathDetectionSystem = {}

local function ensureEventQueue(world)
    world.pendingCombatEvents = world.pendingCombatEvents or {}
    return world.pendingCombatEvents
end

local function pushCombatEvent(world, payload)
    local events = ensureEventQueue(world)
    events[#events + 1] = payload
end

---Detect entities that should be dead and handle their death
---Runs after damage systems to catch any entities with health <= 0
---@param world table World scene
---@param dt number Delta time
function deathDetectionSystem.update(world, dt) -- luacheck: ignore 212/dt
    -- Query entities with health but not already dead
    local entitiesWithHealth = world:queryEntities({ "health" })

    for _, entity in ipairs(entitiesWithHealth) do
        if entity.inactive and entity.inactive.isInactive then
            goto continue
        end

        -- Skip if already dead or dying
        if entity.dead or entity.deathAnimation then
            goto continue
        end

        -- Check if health is at or below zero
        local health = entity.health
        if health and health.current and health.current <= 0 then
            -- Find the attacker from recent combat events if available
            local attacker = nil
            local deathPosition = nil

            -- Try to find the most recent damage event for this entity
            if world.pendingCombatEvents then
                for i = #world.pendingCombatEvents, 1, -1 do
                    local event = world.pendingCombatEvents[i]
                    if event.type == "damage" and event.targetId == entity.id then
                        attacker = world:getEntity(event.sourceId)
                        deathPosition = event.position
                        break
                    end
                end
            end

            -- Handle death
            DeathHelper.handleDeath(world, entity, attacker, deathPosition)

            -- Push death event
            local foeLevel = entity.level or 1
            local foeTypeId = entity.foeTypeId or (entity.foe and entity.foe.typeId)
            local foeExperience = 0
            if foeTypeId then
                local config = foeTypes.getConfig(foeTypeId)
                if config and config.experience then
                    foeExperience = config.experience
                end
            end

            pushCombatEvent(world, {
                type = "death",
                targetId = entity.id,
                sourceId = attacker and attacker.id or nil,
                position = deathPosition,
                foeLevel = foeLevel,
                foeTypeId = foeTypeId,
                foeExperience = foeExperience,
                time = world.time or 0,
            })
        end

        ::continue::
    end
end

return deathDetectionSystem
