---@diagnostic disable: undefined-global
-- luacheck: globals love pcall

local MainMenuScene = require("scenes.main_menu")
local SceneManager = require("modules.scene_manager")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")
local WorldState = require("modules.world_state")
local CRTShader = require("modules.crt_shader")

local sceneManager = SceneManager.new()

function love.load()
    math.randomseed(os.time())

    local menu = MainMenuScene.new({
        sceneManager = sceneManager,
    })

    sceneManager:push(menu)
    CRTShader.load()
end

function love.update(dt)
    InputManager.update()
    CRTShader.update(dt)

    local scene = sceneManager:current()
    if scene and scene.update then
        scene:update(dt)
    end
end

function love.draw()
    CRTShader.draw(function()
        for _, scene in sceneManager:each() do
            if scene.draw then
                scene:draw()
            end
        end
    end)
end

function love.resize(width, height)
    CRTShader.resize(width, height)
end

function love.keypressed(key)
    InputManager.registerPress(key)

    local action = InputManager.getActionForKey(key)

    -- Handle pause menu first (only if no other windows are open)
    if action == InputActions.CLOSE_MODAL then
        local currentScene = sceneManager:current()

        -- If pause menu is open, close it
        if currentScene and currentScene.kind == SceneKinds.PAUSE then
            sceneManager:pop()
            return
        end

        -- If controls window is open, close it
        if currentScene and currentScene.kind == SceneKinds.CONTROLS then
            sceneManager:pop()
            return
        end

        -- Check if inventory or skills windows are open
        local hasOtherWindows = false
        for _, scene in sceneManager:each() do
            if scene.kind == SceneKinds.INVENTORY
                or scene.kind == SceneKinds.SKILLS
                or scene.kind == SceneKinds.CONTROLS
                or scene.kind == SceneKinds.WORLD_MAP
            then
                hasOtherWindows = true
                break
            end
        end

        -- If on world scene and no other windows, open pause menu
        if currentScene and currentScene.kind == SceneKinds.WORLD and not hasOtherWindows then
            local PauseScene = require("scenes.pause")
            sceneManager:push(
                PauseScene.new({
                    world = currentScene,
                })
            )
            return
        end

        -- Otherwise, close inventory/skills windows
        sceneManager:toggleInventory(key)
        sceneManager:toggleSkills(key)
        sceneManager:toggleWorldMap(key)
        return
    end

    if action == InputActions.TOGGLE_INVENTORY then
        sceneManager:toggleInventory(key)
        return
    end

    if action == InputActions.TOGGLE_SKILLS then
        sceneManager:toggleSkills(key)
        return
    end

    if action == InputActions.TOGGLE_WORLD_MAP then
        sceneManager:toggleWorldMap(key)
        return
    end

    local scene = sceneManager:current()
    if scene and scene.keypressed then
        scene:keypressed(key)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    InputManager.registerPress(button)

    local scene = sceneManager:current()
    if scene and scene.mousepressed then
        scene:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    InputManager.registerRelease(button)

    local scene = sceneManager:current()
    if scene and scene.mousereleased then
        scene:mousereleased(x, y, button, istouch, presses)
    end
end

function love.wheelmoved(x, y)
    local scene = sceneManager:current()
    if scene and scene.wheelmoved then
        scene:wheelmoved(x, y)
    end
end

function love.quit()
    local scene = sceneManager:current()
    if scene and scene.kind == SceneKinds.WORLD then
        local payload = WorldState.buildSave(scene)
        if payload then
            WorldState.save(payload)
        end
    end
end
