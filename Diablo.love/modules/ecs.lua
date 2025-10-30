---ECS (Entity Component System) module for managing entities and components.
---Provides efficient entity queries using component sets.
local ECS = {}
ECS.__index = ECS

-- Fields that should not be treated as components
local METADATA_FIELDS = {
    id = true,
    __index = true,
    __newindex = true,
    __metatable = true,
}

---Check if a field should be treated as a component.
---@param fieldName string
---@param fieldValue any
---@return boolean
local function isComponent(fieldName, fieldValue)
    -- Skip metadata fields
    if METADATA_FIELDS[fieldName] then
        return false
    end
    
    -- Skip functions (methods)
    if type(fieldValue) == "function" then
        return false
    end
    
    -- Components are typically tables, but allow other types too
    -- (e.g., boolean flags, numbers, strings)
    return true
end

---Update component sets for a specific entity.
---@param self table ECS instance
---@param entityId string
---@param entity table
local function updateComponentSets(self, entityId, entity)
    if not entity then
        return
    end
    
    -- Add entity to component sets for all its components
    for componentName, componentValue in pairs(entity) do
        if isComponent(componentName, componentValue) then
            if not self.componentSets[componentName] then
                self.componentSets[componentName] = {}
            end
            self.componentSets[componentName][entityId] = true
        end
    end
end

---Remove entity from component sets.
---@param self table ECS instance
---@param entityId string
---@param entity table|nil If provided, only remove components that exist on this entity
local function removeFromComponentSets(self, entityId, entity)
    if entity then
        -- Remove only components that exist on this entity
        for componentName, _ in pairs(entity) do
            if isComponent(componentName, entity[componentName]) then
                if self.componentSets[componentName] then
                    self.componentSets[componentName][entityId] = nil
                end
            end
        end
    else
        -- Remove entity from all component sets
        for componentName, componentSet in pairs(self.componentSets) do
            componentSet[entityId] = nil
        end
    end
end

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
        return false
    end

    self.entities[entity.id] = entity
    updateComponentSets(self, entity.id, entity)
    return true
end

---Remove an entity from the ECS and update component sets.
---@param entityId string
---@return boolean True if entity was removed, false if it didn't exist
function ECS:removeEntity(entityId)
    local entity = self.entities[entityId]
    if not entity then
        return false
    end

    removeFromComponentSets(self, entityId, entity)
    self.entities[entityId] = nil
    return true
end

---Add a component to an entity and update component sets.
---@param entityId string
---@param componentName string
---@param componentValue any
---@return boolean True if component was added, false if entity doesn't exist
function ECS:addComponent(entityId, componentName, componentValue)
    local entity = self.entities[entityId]
    if not entity then
        return false
    end
    
    -- Skip if it's not a valid component name
    if not isComponent(componentName, componentValue) then
        return false
    end
    
    -- Add component to entity
    entity[componentName] = componentValue
    
    -- Update component set
    if not self.componentSets[componentName] then
        self.componentSets[componentName] = {}
    end
    self.componentSets[componentName][entityId] = true
    
    return true
end

---Remove a component from an entity and update component sets.
---@param entityId string
---@param componentName string
---@return boolean True if component was removed, false if entity or component doesn't exist
function ECS:removeComponent(entityId, componentName)
    local entity = self.entities[entityId]
    if not entity then
        return false
    end
    
    if entity[componentName] == nil then
        return false
    end
    
    -- Remove component from entity
    entity[componentName] = nil
    
    -- Update component set
    if self.componentSets[componentName] then
        self.componentSets[componentName][entityId] = nil
    end
    
    return true
end

---Refresh component sets for an entity (useful if components were modified externally).
---@param entityId string
---@return boolean True if entity was refreshed, false if it doesn't exist
function ECS:refreshEntity(entityId)
    local entity = self.entities[entityId]
    if not entity then
        return false
    end
    
    -- Remove from all component sets first
    removeFromComponentSets(self, entityId, entity)
    -- Then re-add based on current entity state
    updateComponentSets(self, entityId, entity)
    
    return true
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
    local entity = self.entities[entityId]
    if not entity then
        return false
    end
    
    -- Check both the entity and component set for consistency
    local hasOnEntity = entity[componentName] ~= nil
    local componentSet = self.componentSets[componentName]
    local hasInSet = componentSet ~= nil and componentSet[entityId] == true
    
    -- If there's a mismatch, refresh the entity
    if hasOnEntity ~= hasInSet then
        self:refreshEntity(entityId)
        return entity[componentName] ~= nil
    end
    
    return hasOnEntity
end

---Get count of entities in the ECS.
---@return number
function ECS:getEntityCount()
    local count = 0
    for _ in pairs(self.entities) do
        count = count + 1
    end
    return count
end

---Get all component names that exist in the ECS.
---@return table Array of component name strings
function ECS:getComponentTypes()
    local types = {}
    for componentName, _ in pairs(self.componentSets) do
        table.insert(types, componentName)
    end
    return types
end

return ECS
