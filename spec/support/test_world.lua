local TestWorld = {}
TestWorld.__index = TestWorld

---Create a lightweight ECS-like world for unit testing systems.
---@return table
function TestWorld.new()
    local world = {
        entities = {},
        nextEntityIndex = 0,
    }

    return setmetatable(world, TestWorld)
end

function TestWorld:addEntity(entity)
    self.entities[entity.id] = entity
    self.nextEntityIndex = self.nextEntityIndex + 1
end

function TestWorld:removeEntity(entityId)
    self.entities[entityId] = nil
end

function TestWorld:getEntity(entityId)
    return self.entities[entityId]
end

function TestWorld:addComponent(entityId, componentName, component)
    local entity = self.entities[entityId]
    if not entity then
        error(("Unknown entity '%s'"):format(tostring(entityId)))
    end

    entity[componentName] = component
end

function TestWorld:removeComponent(entityId, componentName)
    local entity = self.entities[entityId]
    if entity then
        entity[componentName] = nil
    end
end

function TestWorld:queryEntities(componentNames)
    local results = {}

    for _, entity in pairs(self.entities) do
        local matches = true

        for _, name in ipairs(componentNames) do
            if not entity[name] then
                matches = false
                break
            end
        end

        if matches then
            results[#results + 1] = entity
        end
    end

    return results
end

return TestWorld
