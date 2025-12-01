local createDead = require("components.dead")
local createDeathAnimation = require("components.death_animation")
local Targeting = require("systems.helpers.targeting")
local foeTypes = require("data.foe_types")

local DeathHelper = {}

---Handle entity death: remove components, add death animation, push events
---@param world table World scene
---@param target table Entity that died
---@param attacker table|nil Entity that caused the death
---@param position table|nil Position where death occurred {x, y}
function DeathHelper.handleDeath(world, target, attacker, position) -- luacheck: ignore 212/attacker 212/position
    if not target then
        return
    end

    local targetId = target.id

    -- Skip if already dying
    if target.deathAnimation then
        return
    end

    -- Remove components marked for removal on death
    local componentsToRemove = {}
    for componentName, component in pairs(target) do
        if componentName ~= "id" and type(component) == "table" and component.removeOnDeath then
            componentsToRemove[#componentsToRemove + 1] = componentName
        end
    end

    for _, componentName in ipairs(componentsToRemove) do
        world:removeComponent(targetId, componentName)
    end

    -- Remove AI components so foe stops moving/attacking
    world:removeComponent(targetId, "chase")
    world:removeComponent(targetId, "wander")
    world:removeComponent(targetId, "detection")
    world:removeComponent(targetId, "combat")

    -- Add dead component
    if not target.dead then
        world:addComponent(targetId, "dead", createDead())
    end

    -- Add death animation component
    -- Get death frame count from foe type config if available
    local totalFrames = 8 -- Default for backward compatibility
    if target.foe and target.foe.typeId then
        local config = foeTypes.getConfig(target.foe.typeId)
        if config and config.spriteColumns and config.spriteColumns.death then
            totalFrames = config.spriteColumns.death
        end
    end

    local deathAnimation = createDeathAnimation({
        timer = 0,
        animationDuration = 0.5,
        holdDuration = 20.0, -- Hold last frame for 20 seconds
        totalFrames = totalFrames,
        started = true,
    })
    world:addComponent(targetId, "deathAnimation", deathAnimation)

    -- Set animation state to dying
    if target.renderable then
        target.renderable.animationState = "dying"
    end

    -- Note: Caller should push combat event - we don't have access to ensureEventQueue here
    -- This is handled by the calling system

    -- Clear targeting if this was the current target
    Targeting.clearIfMatches(world, targetId)

    -- Update chunk state
    if target.chunkResident then
        local chunkKey = target.chunkResident.chunkKey
        local chunk = world.generatedChunks and world.generatedChunks[chunkKey]
        if chunk then
            if target.chunkResident.kind == "foe" then
                chunk.defeatedFoes[target.chunkResident.descriptorId] = true
            elseif target.chunkResident.kind == "structure" then
                chunk.lootedStructures[target.chunkResident.descriptorId] = true
            end

            if chunk.spawnedEntities then
                chunk.spawnedEntities[target.chunkResident.descriptorId] = nil
            end

            if chunk.bossPackId and world and world.bossPacks then
                local packInfo = chunk.zoneName and world.bossPacks[chunk.zoneName]
                if packInfo and packInfo.chunkKey == chunk.key and not packInfo.defeated then
                    local allDefeated = true
                    for _, descriptor in ipairs(chunk.descriptors and chunk.descriptors.foes or {}) do
                        if descriptor.packId == chunk.bossPackId and not chunk.defeatedFoes[descriptor.id] then
                            allDefeated = false
                            break
                        end
                    end

                    if allDefeated then
                        packInfo.defeated = true
                    end
                end
            end
        end
    end

    -- Don't remove entity immediately - let death animation system handle cleanup
end

return DeathHelper
