local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")

local renderWindowChrome = require("systems.render.window.chrome")
local renderWorldMap = require("systems.render.world_map")

local WorldMapScene = {}
WorldMapScene.__index = WorldMapScene

function WorldMapScene.new(opts)
    opts = opts or {}
    local world = assert(opts.world, "WorldMapScene requires world reference")

    local scene = {
        world = world,
        kind = SceneKinds.WORLD_MAP,
        title = opts.title or "World Map",
        windowLayoutOptions = {
            widthRatio = 0.9,
            heightRatio = 0.9,
            headerHeight = 80,
            padding = 32,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderWorldMap.draw,
            },
        },
    }

    scene.windowChromeConfig = {
        title = scene.title,
        icon = "scroll",
    }

    return setmetatable(scene, WorldMapScene)
end

function WorldMapScene:enter()
    self.windowRects = {}
    self.windowLayout = nil
    if not self.zoneNameFont then
        self.zoneNameFont = love.graphics.newFont(18)
    end
    if not self.detailFont then
        self.detailFont = love.graphics.newFont(14)
    end
end

-- luacheck: ignore 212/self
function WorldMapScene:exit()
end

-- luacheck: ignore 212/self
function WorldMapScene:update(_dt)
end

function WorldMapScene:draw()
    love.graphics.push("all")

    self.windowRects = {}

    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

function WorldMapScene:keypressed(key)
    local action = InputManager.getActionForKey(key)
    if action ~= InputActions.TOGGLE_WORLD_MAP and action ~= InputActions.CLOSE_MODAL then
        return
    end

    if self.world and self.world.sceneManager then
        self.world.sceneManager:toggleWorldMap(key)
    end
end

function WorldMapScene:mousepressed(x, y, button)
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
    end
end

return WorldMapScene
