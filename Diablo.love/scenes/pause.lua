local renderPauseMenu = require("systems.render.pause.menu")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")
local MainMenuScene = require("scenes.main_menu")
local WorldState = require("modules.world_state")
local CRTShader = require("modules.crt_shader")

local PauseScene = {}
PauseScene.__index = PauseScene

function PauseScene.new(opts)
    opts = opts or {}

    local scene = {
        world = opts.world,
        kind = SceneKinds.PAUSE,
        title = "Pause Menu",
        systems = {
            draw = {
                renderPauseMenu.draw,
            },
        },
        statusMessage = nil,
    }

    scene.windowChromeConfig = {
        title = scene.title,
        layout = {
            widthRatio = 0.38,
            heightRatio = 0.75,
            headerHeight = 64,
            padding = 28,
        },
    }
    scene.windowLayoutOptions = scene.windowChromeConfig.layout

    return setmetatable(scene, PauseScene)
end

function PauseScene:enter()
    self.menuRects = {}
end

-- luacheck: ignore 212/self
function PauseScene:exit()
end

-- luacheck: ignore 212/self
function PauseScene:update(_dt)
end

function PauseScene:draw()
    love.graphics.push("all")

    -- Reset rects for click detection
    self.menuRects = {}

    -- Iterate through all render systems
    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

function PauseScene:keypressed(key)
    local action = InputManager.getActionForKey(key)
    if action == InputActions.CLOSE_MODAL then
        if self.world and self.world.sceneManager then
            self.world.sceneManager:pop()
        end
    end
end

function PauseScene:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if self.windowRects and self.windowRects.close then
        local rect = self.windowRects.close
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if self.world and self.world.sceneManager then
                self.world.sceneManager:pop()
            end
            return
        end
    end

    local rects = self.menuRects or {}

    -- Resume button
    if rects.resume then
        local rect = rects.resume
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if self.world and self.world.sceneManager then
                self.world.sceneManager:pop()
            end
            return
        end
    end

    -- Controls button
    if rects.controls then
        local rect = rects.controls
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if self.world and self.world.sceneManager then
                local ControlsScene = require("scenes.controls")
                self.world.sceneManager:push(
                    ControlsScene.new({
                        world = self.world,
                    })
                )
            end
            return
        end
    end

    -- Save button
    if rects.save then
        local rect = rects.save
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self:saveGame()
            return
        end
    end

    -- Load button
    if rects.load then
        local rect = rects.load
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self:loadGame()
            return
        end
    end

    -- CRT toggle
    if rects.crt then
        local rect = rects.crt
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self:toggleCRT()
            return
        end
    end

    -- Return to main menu
    if rects.mainMenu then
        local rect = rects.mainMenu
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self:returnToMainMenu()
            return
        end
    end

    -- Quit button
    if rects.quit then
        local rect = rects.quit
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            love.event.quit()
            return
        end
    end
end

function PauseScene:isCRTEnabled()
    return CRTShader.isEnabled()
end

function PauseScene:toggleCRT()
    CRTShader.toggle()
end

function PauseScene:saveGame()
    if not self.world then
        self.statusMessage = "No world to save."
        return
    end

    local payload = WorldState.buildSave(self.world)
    if not payload then
        self.statusMessage = "Unable to build save data."
        return
    end

    local ok, err = WorldState.save(payload)
    if ok then
        self.statusMessage = "Game saved."
    else
        self.statusMessage = err or "Save failed."
    end
end

function PauseScene:loadGame()
    local manager = self.world and self.world.sceneManager
    if not manager then
        self.statusMessage = "No scene manager available."
        return
    end

    local save = WorldState.load(WorldState.DEFAULT_SLOT)
    if not save then
        self.statusMessage = "No save found."
        return
    end

    local options = WorldState.buildWorldOptions(save)
    if not options then
        self.statusMessage = "Save data invalid."
        return
    end

    options.sceneManager = manager
    if not options.worldSeed then
        options.worldSeed = love.math.random(1, 1000000)
    end

    local WorldScene = require("scenes.world")
    local newWorld = WorldScene.new(options)

    -- Remove pause menu itself
    manager:pop()

    -- Replace current world (if present) with loaded one
    local current = manager:current()
    if current and current.kind == SceneKinds.WORLD then
        manager:pop()
    end

    manager:push(newWorld)
end

function PauseScene:returnToMainMenu()
    local manager = self.world and self.world.sceneManager
    if not manager then
        return
    end

    -- Pop pause menu itself
    manager:pop()

    -- Pop world scene if present
    local current = manager:current()
    if current and current.kind == SceneKinds.WORLD then
        manager:pop()
    end

    -- Push a fresh main menu
    manager:push(
        MainMenuScene.new({
            sceneManager = manager,
        })
    )
end

return PauseScene
