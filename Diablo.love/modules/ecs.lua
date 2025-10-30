---ECS (Entity Component System) module for managing entities and components.
---Provides efficient entity queries using component sets.
local ECS = {}
ECS.__index = ECS

---Create a new ECS instance.
---@return table
function ECS.new()
    return setmetatable({
        entities = {},
        componentSets = {}, -- Maps component name -> set of entity IDs
    }, ECS)
end

---Initialize ECS on an existing object.
---@param target table The object to initialize with ECS capabilities
function ECS.init(target)
    target.entities = target.entities or {}
    target.componentSets = target.componentSets or {}

    -- Mix in ECS methods
    for k, v in pairs(ECS) do
        if k ~= "new" and k ~= "init" and k ~= "__index" then
            target[k] = v
        end
    end

    return target
end

---Add an entity to the ECS and update component sets.
---@param entity table
function ECS:addEntity(entity)
    if not entity or not entity.id then
        return
    end

    self.entities[entity.id] = entity

    -- Update component sets
    for componentName, componentValue in pairs(entity) do
        -- Skip non-component fields (id, methods, etc.)
        if componentName ~= "id" and type(componentValue) == "table" then
            if not self.componentSets[componentName] then
                self.componentSets[componentName] = {}
            end
            self.componentSets[componentName][entity.id] = true
        end
    end
end

---Remove an entity from the ECS and update component sets.
---@param entityId string
function ECS:removeEntity(entityId)
    local entity = self.entities[entityId]
    if not entity then
        return
    end

    -- Remove from component sets
    for componentName, _ in pairs(entity) do
        if componentName ~= "id" and self.componentSets[componentName] then
            self.componentSets[componentName][entityId] = nil
        end
    end

    -- Remove from entities
    self.entities[entityId] = nil
end

---Get an entity by ID.
---@param entityId string
---@return table|nil
function ECS:getEntity(entityId)
    if not entityId then
        return nil
    end
    return self.entities[entityId]
end

---Query entities that have all of the specified components.
---Uses component sets for efficient O(k) queries where k = matching entities.
---@param requiredComponents table Array of component names (strings)
---@return table Array of entities matching the query
function ECS:queryEntities(requiredComponents)
    if not requiredComponents or #requiredComponents == 0 then
        return {}
    end

    local result = {}
    local candidateIds = nil

    -- Find intersection of all component sets
    for _, componentName in ipairs(requiredComponents) do
        local componentSet = self.componentSets[componentName]
        if not componentSet then
            -- No entities have this component
            return {}
        end

        if candidateIds == nil then
            -- First component: use all its entities as candidates
            candidateIds = {}
            for entityId, _ in pairs(componentSet) do
                candidateIds[entityId] = true
            end
        else
            -- Subsequent components: intersect with existing candidates
            local newCandidates = {}
            for entityId, _ in pairs(componentSet) do
                if candidateIds[entityId] then
                    newCandidates[entityId] = true
                end
            end
            candidateIds = newCandidates
        end

        if not next(candidateIds) then
            -- No entities match all components
            return {}
        end
    end

    -- Convert candidate IDs to entity objects
    for entityId, _ in pairs(candidateIds) do
        local entity = self.entities[entityId]
        if entity then
            table.insert(result, entity)
        end
    end

    return result
end

---Check if an entity has a specific component.
---@param entityId string
---@param componentName string
---@return boolean
function ECS:hasComponent(entityId, componentName)
    local componentSet = self.componentSets[componentName]
    return componentSet ~= nil and componentSet[entityId] == true
end

return ECS
