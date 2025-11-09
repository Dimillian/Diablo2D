---Scene Manager module for managing scene stack and transitions.
---Handles scene lifecycle (enter/exit) and provides utilities for finding scenes by kind.
local InventoryScene = require("scenes.inventory")
local SkillsScene = require("scenes.skills")
local WorldMapScene = require("scenes.world_map")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")

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
    local action = InputManager.getActionForKey(key)

    if action == InputActions.CLOSE_MODAL then
        if top and top.kind == SceneKinds.INVENTORY then
            self:pop()
        end
        return
    end

    if action ~= InputActions.TOGGLE_INVENTORY then
        return
    end

    if top and top.kind == SceneKinds.INVENTORY then
        self:pop()
        return
    end

    local world = self:findByKind(SceneKinds.WORLD)
    if not world then
        return
    end

    self:push(
        InventoryScene.new({
            world = world,
        })
    )
end

function SceneManager:toggleSkills(key)
    local top = self:current()
    local action = InputManager.getActionForKey(key)

    if action == InputActions.CLOSE_MODAL then
        if top and top.kind == SceneKinds.SKILLS then
            self:pop()
        end
        return
    end

    if action ~= InputActions.TOGGLE_SKILLS then
        return
    end

    if top and top.kind == SceneKinds.SKILLS then
        self:pop()
        return
    end

    local world = self:findByKind(SceneKinds.WORLD)
    if not world then
        return
    end

    self:push(
        SkillsScene.new({
            world = world,
        })
    )
end

function SceneManager:togglePause(key)
    local top = self:current()
    local action = InputManager.getActionForKey(key)

    if action == InputActions.CLOSE_MODAL then
        if top and top.kind == SceneKinds.PAUSE then
            self:pop()
        end
        return
    end
end

function SceneManager:toggleWorldMap(key)
    local top = self:current()
    local action = InputManager.getActionForKey(key)

    if action == InputActions.CLOSE_MODAL then
        if top and top.kind == SceneKinds.WORLD_MAP then
            self:pop()
        end
        return
    end

    if action ~= InputActions.TOGGLE_WORLD_MAP then
        return
    end

    if top and top.kind == SceneKinds.WORLD_MAP then
        self:pop()
        return
    end

    local world = self:findByKind(SceneKinds.WORLD)
    if not world then
        return
    end

    self:push(
        WorldMapScene.new({
            world = world,
        })
    )
end

function SceneManager:wheelmoved(x, y)
    local scene = self:current()
    if scene and scene.wheelmoved then
        scene:wheelmoved(x, y)
    end
end

return SceneManager
