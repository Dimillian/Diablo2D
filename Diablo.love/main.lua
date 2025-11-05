---@diagnostic disable: undefined-global
-- luacheck: globals love

local WorldScene = require("scenes.world")
local SceneManager = require("modules.scene_manager")

local sceneManager = SceneManager.new()

local SAVE_FILE = "world_state.json"

local function loadWorldState()
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

local function normalizeChunks(persisted)
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

local function saveWorldState(state)
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

function love.load()
    math.randomseed(os.time())

    local persisted = loadWorldState()
    local opts = { sceneManager = sceneManager }

    if persisted then
        opts.worldSeed = persisted.worldSeed
        opts.chunkSize = persisted.chunkSize
        opts.activeRadius = persisted.activeRadius
        opts.startBiomeId = persisted.startBiomeId
        opts.startBiomeRadius = persisted.startBiomeRadius
        opts.startBiomeCenter = persisted.startBiomeCenter
        opts.forceStartBiome = persisted.forceStartBiome
        opts.generatedChunks = normalizeChunks(persisted.generatedChunks)
        opts.visitedChunks = persisted.visitedChunks
        opts.minimapState = persisted.minimapState
    end

    if not opts.worldSeed then
        opts.worldSeed = love.math.random(1, 1000000)
    end

    sceneManager:push(WorldScene.new(opts))
end

function love.update(dt)
    local scene = sceneManager:current()
    if scene and scene.update then
        scene:update(dt)
    end
end

function love.draw()
    for _, scene in sceneManager:each() do
        if scene.draw then
            scene:draw()
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        sceneManager:toggleInventory(key)
        sceneManager:toggleSkills(key)
        return
    end

    if key == "i" then
        sceneManager:toggleInventory(key)
        return
    end

    if key == "k" then
        sceneManager:toggleSkills(key)
        return
    end

    local scene = sceneManager:current()
    if scene and scene.keypressed then
        scene:keypressed(key)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    local scene = sceneManager:current()
    if scene and scene.mousepressed then
        scene:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    local scene = sceneManager:current()
    if scene and scene.mousereleased then
        scene:mousereleased(x, y, button, istouch, presses)
    end
end

function love.quit()
    local scene = sceneManager:current()
    if scene and scene.kind == "world" and scene.serializeState then
        saveWorldState(scene:serializeState())
    end
end
