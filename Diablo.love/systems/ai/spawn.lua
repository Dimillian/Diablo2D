local ChunkManager = require("modules.world.chunk_manager")

local spawnSystem = {}

local function ensurePlayerChunkLoaded(world)
    if not world or not world.chunkManager then
        return
    end

    local player
    if world.getPlayer then
        player = world:getPlayer()
    end
    local position = player and player.position
    if not position then
        return
    end

    local chunkX, chunkY = ChunkManager.getChunkCoords(world.chunkManager, position.x, position.y)
    ChunkManager.ensureChunkLoaded(world.chunkManager, world, chunkX, chunkY)
end

---Initialize deterministic chunk data around the player.
---@param world table
function spawnSystem.spawnInitialGroups(world)
    ensurePlayerChunkLoaded(world)
end

---Spawn system now delegates to chunk streaming; keep hook for future logic.
---@param world table
---@param _dt number
function spawnSystem.update(world, _dt)
    ensurePlayerChunkLoaded(world)
end

return spawnSystem
