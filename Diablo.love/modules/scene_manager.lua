---Scene Manager module for managing scene stack and transitions.
---Handles scene lifecycle (enter/exit) and provides utilities for finding scenes by kind.
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

return SceneManager
