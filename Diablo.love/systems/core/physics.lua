local Physics = require("modules.physics")

local physicsSystem = {}

function physicsSystem.update(world, dt)
    Physics.updateWorld(world, dt)

    if not world.queryEntities then
        return
    end

    local entities = world:queryEntities({ "physicsBody", "position", "size" })

    for _, entity in ipairs(entities) do
        Physics.syncEntityPositionFromBody(entity)
    end
end

return physicsSystem
