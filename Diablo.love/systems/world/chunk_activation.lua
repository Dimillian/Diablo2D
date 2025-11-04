local ChunkManager = require("modules.world.chunk_manager")
local Foe = require("entities.foe")
local foeTypes = require("data.foe_types")
local StructureFactory = require("entities.structures.factory")

local chunkActivationSystem = {}

local function ensureTables(world)
    world.activeChunkKeys = world.activeChunkKeys or {}
    world.visitedChunks = world.visitedChunks or {}
end

local function instantiateFoe(world, chunk, descriptor)
    if chunk.defeatedFoes[descriptor.id] then
        return
    end

    local config = foeTypes.getConfig(descriptor.foeType)
    local foe = Foe.new({
        id = descriptor.id,
        x = descriptor.x,
        y = descriptor.y,
        width = 20,
        height = 20,
        config = config,
    })

    foe.chunkResident = {
        chunkKey = chunk.key,
        descriptorId = descriptor.id,
        kind = "foe",
    }

    world:addEntity(foe)
    chunk.spawnedEntities[descriptor.id] = foe.id
end

local function instantiateStructure(world, chunk, descriptor)
    if chunk.lootedStructures[descriptor.id] then
        return
    end

    local structure = StructureFactory.build({
        id = descriptor.id,
        structureId = descriptor.structureId,
        x = descriptor.x,
        y = descriptor.y,
        rotation = descriptor.rotation,
    })

    structure.chunkResident = {
        chunkKey = chunk.key,
        descriptorId = descriptor.id,
        kind = "structure",
    }

    world:addEntity(structure)
    chunk.spawnedEntities[descriptor.id] = structure.id
end

local function activateChunk(world, chunk)
    chunk.spawnedEntities = chunk.spawnedEntities or {}

    for _, descriptor in ipairs(chunk.descriptors.foes or {}) do
        if not chunk.spawnedEntities[descriptor.id] then
            instantiateFoe(world, chunk, descriptor)
        end
    end

    for _, descriptor in ipairs(chunk.descriptors.structures or {}) do
        if not chunk.spawnedEntities[descriptor.id] then
            instantiateStructure(world, chunk, descriptor)
        end
    end

    world.visitedChunks[chunk.key] = true
end

local function deactivateChunk(world, chunk)
    if not chunk or not chunk.spawnedEntities then
        return
    end

    for descriptorId, entityId in pairs(chunk.spawnedEntities) do
        if entityId and world:getEntity(entityId) then
            world:removeEntity(entityId)
        end
        chunk.spawnedEntities[descriptorId] = nil
    end
end

function chunkActivationSystem.update(world, _dt)
    if not world.chunkManager then
        return
    end

    ensureTables(world)

    local manager = world.chunkManager
    local activeChunks = ChunkManager.iterateActiveChunks(manager, world)
    local nextActiveKeys = {}

    for _, chunk in ipairs(activeChunks) do
        nextActiveKeys[chunk.key] = true
        activateChunk(world, chunk)
    end

    for chunkKey in pairs(world.activeChunkKeys) do
        if not nextActiveKeys[chunkKey] then
            deactivateChunk(world, world.generatedChunks and world.generatedChunks[chunkKey])
        end
    end

    world.activeChunkKeys = nextActiveKeys
end

return chunkActivationSystem
