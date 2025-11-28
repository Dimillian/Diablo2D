local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")

local renderWindowChrome = require("systems.render.window.chrome")
local renderWorldMap = require("systems.render.world_map")

local WorldMapScene = {}
WorldMapScene.__index = WorldMapScene
local ZOOM_CONFIG = {
    minZoom = 0.5,
    maxZoom = 2.5,
    step = 0.2,
}

local function clampZoom(value)
    if value < ZOOM_CONFIG.minZoom then
        return ZOOM_CONFIG.minZoom
    end
    if value > ZOOM_CONFIG.maxZoom then
        return ZOOM_CONFIG.maxZoom
    end
    return value
end

function WorldMapScene.new(opts)
    opts = opts or {}
    local world = assert(opts.world, "WorldMapScene requires world reference")

    local scene = {
        world = world,
        kind = SceneKinds.WORLD_MAP,
        title = opts.title or "World Map",
        windowLayoutOptions = {
            widthRatio = 0.8,
            heightRatio = 0.8,
            headerHeight = 80,
            padding = 0,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderWorldMap.draw,
            },
        },
        zoom = clampZoom(opts.zoom or 1),
        minZoom = ZOOM_CONFIG.minZoom,
        maxZoom = ZOOM_CONFIG.maxZoom,
        zoomStep = ZOOM_CONFIG.step,
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
    self.zoom = clampZoom(self.zoom or 1)
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

function WorldMapScene:wheelmoved(_x, y)
    if y == 0 then
        return
    end

    local zoom = self.zoom or 1
    zoom = zoom + (self.zoomStep or ZOOM_CONFIG.step) * y
    self.zoom = clampZoom(zoom)
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
