local renderWindowChrome = require("systems.render.window.chrome")
local renderControlsList = require("systems.render.controls.list")
local renderScrollbar = require("systems.render.window.scrollbar")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")

local ControlsScene = {}
ControlsScene.__index = ControlsScene

function ControlsScene.new(opts)
    opts = opts or {}
    local world = assert(opts.world, "ControlsScene requires world reference")

    local scene = {
        world = world,
        kind = SceneKinds.CONTROLS,
        title = "Controls",
        windowLayoutOptions = {
            widthRatio = 0.6,
            heightRatio = 0.80,
            headerHeight = 72,
            padding = 28,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderControlsList.draw,
                renderScrollbar.draw,
            },
        },
    }

    scene.windowChromeConfig = {
        title = scene.title,
        icon = "book",
    }

    return setmetatable(scene, ControlsScene)
end

function ControlsScene:enter()
    self.windowRects = {}
    self.windowLayout = nil
end

-- luacheck: ignore 212/self
function ControlsScene:exit()
end

-- luacheck: ignore 212/self
function ControlsScene:update(_dt)
end

function ControlsScene:draw()
    love.graphics.push("all")

    -- Reset rects for click detection
    self.windowRects = {}

    -- Iterate through all render systems
    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

function ControlsScene:keypressed(key)
    local action = InputManager.getActionForKey(key)
    if action == InputActions.CLOSE_MODAL then
        if self.world and self.world.sceneManager then
            self.world.sceneManager:pop()
        end
    end
end

function ControlsScene:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local closeRect = self.windowRects and self.windowRects.close
    if closeRect
        and x >= closeRect.x
        and x <= closeRect.x + closeRect.w
        and y >= closeRect.y
        and y <= closeRect.y + closeRect.h
    then
        if self.world and self.world.sceneManager then
            self.world.sceneManager:pop()
        end
        return
    end
end

function ControlsScene:wheelmoved(_x, y)
    if self.scrollState then
        local ScrollableContent = require("systems.helpers.scrollable_content")
        ScrollableContent.updateScroll(self.scrollState, y)
    end
end

return ControlsScene
