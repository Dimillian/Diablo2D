---Helpers for loading and saving world state to disk.
---Centralizes save file details so scenes can share load/save logic.
local ComponentDefaults = require("data.component_defaults")
local Leveling = require("modules.leveling")
local LifetimeStats = require("modules.lifetime_stats")
local Json = require("vendor.json")

local WorldState = {}

WorldState.VERSION = 1
WorldState.DEFAULT_SLOT = "slot1"

local SAVE_DIR = "saves"
local SAVE_EXTENSION = ".json"

local function getSlotPath(slotName)
    slotName = slotName or WorldState.DEFAULT_SLOT
    return string.format("%s/%s%s", SAVE_DIR, slotName, SAVE_EXTENSION)
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, entry in pairs(value) do
        result[key] = deepCopy(entry)
    end
    return result
end

local function copyArray(list)
    local result = {}
    for index, entry in ipairs(list or {}) do
        result[index] = deepCopy(entry)
    end
    return result
end

local function copyMap(map)
    local result = {}
    for key, value in pairs(map or {}) do
        result[key] = deepCopy(value)
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
            transition = deepCopy(chunk.transition)
            if chunk.transition.neighbors then
                transition.neighbors = copyArray(chunk.transition.neighbors)
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
                foes = copyArray(chunk.descriptors and chunk.descriptors.foes or {}),
                structures = copyArray(chunk.descriptors and chunk.descriptors.structures or {}),
            },
            props = copyArray(chunk.props or {}),
            defeatedFoes = copyMap(chunk.defeatedFoes),
            lootedStructures = copyMap(chunk.lootedStructures),
            spawnedEntities = {},
            bossPackId = chunk.bossPackId,
        }
    end

    return restored
end

local function normalizeResource(component, defaultMax)
    local max = defaultMax
    local current = defaultMax
    if component then
        if component.max ~= nil then
            max = component.max
        end
        if component.current ~= nil then
            current = component.current
        else
            current = max
        end
    end

    return {
        current = current,
        max = max,
    }
end

---Normalize player save payloads to protect against missing fields.
---@param persisted table|nil
---@return table|nil
function WorldState.normalizePlayer(persisted)
    if not persisted then
        return nil
    end

    local experience = persisted.experience or {}
    local level = experience.level or 1
    local potions = persisted.potions or {}

    return {
        id = persisted.id or "player",
        position = {
            x = persisted.position and persisted.position.x or 0,
            y = persisted.position and persisted.position.y or 0,
        },
        movement = persisted.movement and {
            speed = persisted.movement.speed,
        } or nil,
        combat = persisted.combat and {
            range = persisted.combat.range,
        } or nil,
        baseStats = copyMap(persisted.baseStats or {}),
        health = normalizeResource(persisted.health, ComponentDefaults.PLAYER_STARTING_HEALTH),
        mana = normalizeResource(persisted.mana, ComponentDefaults.PLAYER_STARTING_MANA),
        potions = {
            healthPotionCount = potions.healthPotionCount ~= nil
                and potions.healthPotionCount
                or ComponentDefaults.HEALTH_POTION_STARTING_COUNT,
            maxHealthPotionCount = potions.maxHealthPotionCount ~= nil
                and potions.maxHealthPotionCount
                or ComponentDefaults.MAX_HEALTH_POTION_COUNT,
            manaPotionCount = potions.manaPotionCount ~= nil
                and potions.manaPotionCount
                or ComponentDefaults.MANA_POTION_STARTING_COUNT,
            maxManaPotionCount = potions.maxManaPotionCount ~= nil
                and potions.maxManaPotionCount
                or ComponentDefaults.MAX_MANA_POTION_COUNT,
            cooldownDuration = potions.cooldownDuration ~= nil
                and potions.cooldownDuration
                or ComponentDefaults.POTION_COOLDOWN_DURATION,
            cooldownRemaining = potions.cooldownRemaining or 0,
        },
        inventory = {
            items = copyArray(persisted.inventory and persisted.inventory.items or {}),
            capacity = (persisted.inventory and persisted.inventory.capacity) or ComponentDefaults.INVENTORY_CAPACITY,
            gold = persisted.inventory and persisted.inventory.gold or 0,
        },
        equipment = copyMap(persisted.equipment or {}),
        skills = {
            equipped = copyArray(persisted.skills and persisted.skills.equipped or {}),
            availablePoints = persisted.skills and persisted.skills.availablePoints or 0,
            allocations = copyMap(persisted.skills and persisted.skills.allocations or {}),
        },
        experience = {
            level = level,
            currentXP = experience.currentXP or 0,
            xpForNextLevel = experience.xpForNextLevel or Leveling.getXPRequiredForNextLevel(level),
            unallocatedPoints = experience.unallocatedPoints or 0,
        },
    }
end

---Normalize persisted world payloads.
---@param persisted table|nil
---@return table|nil
function WorldState.normalizeWorld(persisted)
    if not persisted then
        return nil
    end

    return {
        worldSeed = persisted.worldSeed,
        chunkSize = persisted.chunkSize or 512,
        activeRadius = persisted.activeRadius or 4,
        startBiomeId = persisted.startBiomeId,
        startBiomeRadius = persisted.startBiomeRadius,
        startBiomeCenter = persisted.startBiomeCenter
            and {
                chunkX = persisted.startBiomeCenter.chunkX,
                chunkY = persisted.startBiomeCenter.chunkY,
            }
            or nil,
        forceStartBiome = persisted.forceStartBiome,
        bossPacks = copyMap(persisted.bossPacks),
        minimapState = (function()
            local visible = true
            if persisted.minimapState and persisted.minimapState.visible ~= nil then
                visible = persisted.minimapState.visible
            end

            return {
                visible = visible,
                zoom = persisted.minimapState and persisted.minimapState.zoom or 1,
            }
        end)(),
        visitedChunks = copyMap(persisted.visitedChunks),
        generatedChunks = WorldState.normalizeChunks(persisted.generatedChunks),
        spawnSafeZone = persisted.spawnSafeZone
            and {
                chunkKey = persisted.spawnSafeZone.chunkKey,
                centerX = persisted.spawnSafeZone.centerX,
                centerY = persisted.spawnSafeZone.centerY,
                radius = persisted.spawnSafeZone.radius,
            }
            or nil,
        starterGearGenerated = persisted.starterGearGenerated or false,
    }
end

local function buildMetadata(payload)
    local player = payload and payload.player or nil
    local world = payload and payload.world or nil
    local position = player and player.position or nil

    local metadata = {
        worldSeed = world and world.worldSeed or nil,
        playerLevel = player and player.experience and player.experience.level or nil,
        playerPosition = position
            and {
                x = position.x,
                y = position.y,
            }
            or nil,
    }

    return metadata
end

---Capture the current player state from the world for persistence.
---@param world table|nil
---@return table|nil
function WorldState.capturePlayer(world)
    if not world or not world.getPlayer then
        return nil
    end

    local player = world:getPlayer()
    if not player then
        return nil
    end

    return {
        id = player.id,
        position = player.position and {
            x = player.position.x,
            y = player.position.y,
        } or nil,
        movement = player.movement and {
            speed = player.movement.speed,
        } or nil,
        combat = player.combat and {
            range = player.combat.range,
        } or nil,
        baseStats = copyMap(player.baseStats or {}),
        health = player.health
            and {
                current = player.health.current,
                max = player.health.max,
            }
            or nil,
        mana = player.mana
            and {
                current = player.mana.current,
                max = player.mana.max,
            }
            or nil,
        potions = player.potions
            and {
                healthPotionCount = player.potions.healthPotionCount,
                maxHealthPotionCount = player.potions.maxHealthPotionCount,
                manaPotionCount = player.potions.manaPotionCount,
                maxManaPotionCount = player.potions.maxManaPotionCount,
                cooldownDuration = player.potions.cooldownDuration,
                cooldownRemaining = player.potions.cooldownRemaining,
            }
            or nil,
        inventory = player.inventory
            and {
                items = copyArray(player.inventory.items),
                capacity = player.inventory.capacity,
                gold = player.inventory.gold,
            }
            or nil,
        equipment = player.equipment and copyMap(player.equipment) or nil,
        skills = player.skills
            and {
                equipped = copyArray(player.skills.equipped),
                availablePoints = player.skills.availablePoints,
                allocations = copyMap(player.skills.allocations),
            }
            or nil,
        experience = player.experience
            and {
                level = player.experience.level,
                currentXP = player.experience.currentXP,
                xpForNextLevel = player.experience.xpForNextLevel,
                unallocatedPoints = player.experience.unallocatedPoints,
            }
            or nil,
    }
end

---Build a full save payload combining world and player state.
---@param world table|nil
---@param slotName string|nil
---@return table|nil
function WorldState.buildSave(world, slotName)
    if not world or not world.serializeState then
        return nil
    end

    local payload = {
        version = WorldState.VERSION,
        savedAt = os.time(),
        slot = slotName or WorldState.DEFAULT_SLOT,
        world = WorldState.normalizeWorld(world:serializeState()),
        player = WorldState.normalizePlayer(WorldState.capturePlayer(world)),
        lifetimeStats = LifetimeStats.normalize(world.lifetimeStats),
    }
    payload.metadata = buildMetadata(payload)

    return payload
end

---Load world state from disk.
---@param slotName string|nil
---@return table|nil
function WorldState.load(slotName)
    local path = getSlotPath(slotName)
    if not love.filesystem.getInfo(path) then
        return nil
    end

    local contents = love.filesystem.read(path)
    if not contents or contents == "" then
        return nil
    end

    local success, decoded = pcall(Json.decode, contents)
    if not success then
        return nil
    end

    local wrapped = decoded
    wrapped.slot = decoded.slot or slotName or WorldState.DEFAULT_SLOT
    if not decoded.world and decoded.worldSeed then
        wrapped = {
            version = decoded.version or 0,
            savedAt = decoded.savedAt or decoded.timestamp,
            slot = wrapped.slot,
            world = decoded,
        }
    end

    wrapped.world = WorldState.normalizeWorld(wrapped.world)
    wrapped.player = WorldState.normalizePlayer(wrapped.player)
    wrapped.lifetimeStats = LifetimeStats.normalize(wrapped.lifetimeStats)
    wrapped.version = wrapped.version or 0
    wrapped.savedAt = wrapped.savedAt or os.time()
    wrapped.metadata = buildMetadata(wrapped)

    return wrapped
end

---Persist world state to disk.
---@param state table
---@param slotName string|nil
---@return boolean, string|nil
function WorldState.save(state, slotName)
    if not state then
        return false, "missing state"
    end

    state.version = state.version or WorldState.VERSION
    state.savedAt = state.savedAt or os.time()
    state.slot = slotName or state.slot or WorldState.DEFAULT_SLOT

    local success, encodedOrErr = pcall(Json.encode, state)
    if not success then
        return false, encodedOrErr or "encode failed"
    end

    local encoded = encodedOrErr
    if not encoded or encoded == "" then
        return false, "encode produced empty output"
    end

    love.filesystem.createDirectory(SAVE_DIR)
    local bytesWrittenOrOk, err = love.filesystem.write(getSlotPath(state.slot), encoded)
    if not bytesWrittenOrOk then
        return false, err or "write failed"
    end

    return true, nil
end

---Return basic metadata for all save slots on disk.
---@return table
function WorldState.listSlots()
    local saves = {}
    local info = love.filesystem.getInfo(SAVE_DIR)
    if info and info.type == "directory" then
        for _, filename in ipairs(love.filesystem.getDirectoryItems(SAVE_DIR)) do
            if filename:sub(-#SAVE_EXTENSION) == SAVE_EXTENSION then
                local slotName = filename:sub(1, #filename - #SAVE_EXTENSION)
                local entry = WorldState.load(slotName)
                if entry then
                    saves[#saves + 1] = {
                        slot = slotName,
                        savedAt = entry.savedAt,
                        version = entry.version,
                        metadata = entry.metadata,
                    }
                end
            end
        end
    end

    return saves
end

---Convert a normalized save payload into options for world creation.
---@param save table|nil
---@return table|nil
function WorldState.buildWorldOptions(save)
    if not save then
        return nil
    end

    local world = save.world or {}
    local player = save.player

    return {
        worldSeed = world.worldSeed,
        chunkSize = world.chunkSize,
        activeRadius = world.activeRadius,
        startBiomeId = world.startBiomeId,
        startBiomeRadius = world.startBiomeRadius,
        startBiomeCenter = world.startBiomeCenter,
        forceStartBiome = world.forceStartBiome,
        generatedChunks = world.generatedChunks,
        visitedChunks = world.visitedChunks,
        minimapState = world.minimapState,
        spawnSafeZone = world.spawnSafeZone,
        starterGearGenerated = world.starterGearGenerated or player ~= nil,
        bossPacks = world.bossPacks,
        playerState = player,
        playerX = player and player.position and player.position.x or nil,
        playerY = player and player.position and player.position.y or nil,
        lifetimeStats = LifetimeStats.normalize(save.lifetimeStats),
    }
end

---Check if a save slot exists on disk.
---@param slotName string|nil
---@return boolean
function WorldState.slotExists(slotName)
    return love.filesystem.getInfo(getSlotPath(slotName)) ~= nil
end

return WorldState
