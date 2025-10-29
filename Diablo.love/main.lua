---@diagnostic disable: undefined-global
-- luacheck: globals love

local WorldScene = require("scenes.world")
local InventoryScene = require("scenes.inventory")

local SceneManager = {}
SceneManager.__index = SceneManager

function SceneManager.new()
    return setmetatable({ stack = {} }, SceneManager)
end

function SceneManager:current()
    return self.stack[#self.stack]
end

function SceneManager:push(scene)
    table.insert(self.stack, scene)
    if scene.enter then
        scene:enter()
    end
end

function SceneManager:pop()
    local scene = table.remove(self.stack)
    if scene and scene.exit then
        scene:exit()
    end
    return scene
end

function SceneManager:each()
    return ipairs(self.stack)
end

function SceneManager:findByKind(kind)
    for idx = #self.stack, 1, -1 do
        local scene = self.stack[idx]
        if scene.kind == kind then
            return scene
        end
    end
end

function SceneManager:toggleInventory(key)
    local top = self:current()

    if key == "escape" then
        if top and top.kind == "inventory" then
            self:pop()
        end
        return
    end

    if key ~= "i" then
        return
    end

    if top and top.kind == "inventory" then
        self:pop()
        return
    end

    local world = self:findByKind("world")
    if not world then
        return
    end

    self:push(
        InventoryScene.new({
            world = world,
        })
    )
end

local sceneManager = SceneManager.new()

function love.load()
    math.randomseed(os.time())
    sceneManager:push(WorldScene.new())
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
