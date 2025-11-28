---Helpers for loading and saving world state to disk.
---Centralizes save file details so scenes can share load/save logic.
local WorldState = {}

local SAVE_FILE = "world_state.json"

local function copyList(list)
    local result = {}
    for index, entry in ipairs(list or {}) do
        result[index] = {}
        for key, value in pairs(entry) do
            result[index][key] = value
        end
    end
    return result
end

local function copyMap(map)
    local result = {}
    for key, value in pairs(map or {}) do
        result[key] = value
    end
    return result
end

---Normalize persisted chunk tables into the runtime format expected by ChunkManager.
---@param persisted table|nil
---@return table
function WorldState.normalizeChunks(persisted)
    local restored = {}
    for key, chunk in pairs(persisted or {}) do
        local transition = nil
        if chunk.transition then
            transition = {}
            for k, v in pairs(chunk.transition) do
                transition[k] = v
            end
            if chunk.transition.neighbors then
                transition.neighbors = {}
                for index, neighbor in ipairs(chunk.transition.neighbors) do
                    transition.neighbors[index] = {}
                    for k, v in pairs(neighbor) do
                        transition.neighbors[index][k] = v
                    end
                end
            end
        end

        restored[key] = {
            key = chunk.key or key,
            chunkX = chunk.chunkX,
            chunkY = chunk.chunkY,
            biomeId = chunk.biomeId,
            biomeLabel = chunk.biomeLabel,
            zoneName = chunk.zoneName,
            transition = transition,
            descriptors = {
                foes = copyList(chunk.descriptors and chunk.descriptors.foes or {}),
                structures = copyList(chunk.descriptors and chunk.descriptors.structures or {}),
            },
            props = copyList(chunk.props or {}),
            defeatedFoes = copyMap(chunk.defeatedFoes),
            lootedStructures = copyMap(chunk.lootedStructures),
            spawnedEntities = {},
        }
    end

    return restored
end

---Load world state from disk.
---@return table|nil
function WorldState.load()
    if not love.filesystem.getInfo(SAVE_FILE) then
        return nil
    end

    local contents = love.filesystem.read(SAVE_FILE)
    if not contents or contents == "" then
        return nil
    end

    local success, decoded = pcall(love.data.decode, "string", "json", contents)
    if not success then
        return nil
    end

    return decoded
end

---Persist world state to disk.
---@param state table
---@return boolean
function WorldState.save(state)
    if not state then
        return false
    end

    local success, encoded = pcall(love.data.encode, "string", "json", state)
    if not success then
        return false
    end

    local ok = love.filesystem.write(SAVE_FILE, encoded)
    return ok
end

return WorldState
