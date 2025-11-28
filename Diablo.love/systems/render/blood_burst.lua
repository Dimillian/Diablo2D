local EmberEffect = require("effects.ember")
local coordinates = require("systems.helpers.coordinates")

local renderBloodBurstSystem = {}

function renderBloodBurstSystem.draw(world)
    local dt = world.lastUpdateDt or 0
    if dt <= 0 then
        dt = 1 / 60
    end

    local entities = world:queryEntities({ "bloodBurst", "position" })
    local toRemove = {}

    love.graphics.push("all")
    local camera = world.camera or { x = 0, y = 0 }
    love.graphics.translate(-camera.x, -camera.y)

    for _, entity in ipairs(entities) do
        local bloodBurst = entity.bloodBurst
        if not bloodBurst or not bloodBurst.emitter then
            goto continue
        end

        -- Update emitter anchor position based on entity's current position
        local centerX, centerY = coordinates.getEntityCenter(entity)
        if centerX and centerY then
            EmberEffect.setAnchor(bloodBurst.emitter, centerX, centerY)
        end

        -- Update and render particles
        EmberEffect.update(bloodBurst.emitter, dt)
        EmberEffect.drawParticles(bloodBurst.emitter)

        -- Decrement time to live
        bloodBurst.timeToLive = bloodBurst.timeToLive - dt

        -- Remove component when expired or particles are gone
        local particles = bloodBurst.emitter.particles or {}
        if bloodBurst.timeToLive <= 0 and #particles == 0 then
            toRemove[#toRemove + 1] = entity.id
        end

        ::continue::
    end

    love.graphics.pop()

    -- Remove components from entities
    for _, id in ipairs(toRemove) do
        world:removeComponent(id, "bloodBurst")
    end
end

return renderBloodBurstSystem
