---@diagnostic disable: undefined-global
-- luacheck: globals love

local WorldScene = require("scenes.world")
local SceneManager = require("modules.scene_manager")

local sceneManager = SceneManager.new()

function love.load()
    math.randomseed(os.time())
    sceneManager:push(WorldScene.new({ sceneManager = sceneManager }))
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
    if key == "i" or key == "escape" then
        sceneManager:toggleInventory(key)
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
