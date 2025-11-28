local SceneKinds = require("modules.scene_kinds")
local WorldScene = require("scenes.world")
local WorldState = require("modules.world_state")

local MainMenuScene = {}
MainMenuScene.__index = MainMenuScene

local BUTTON_WIDTH = 320
local BUTTON_HEIGHT = 56
local BUTTON_SPACING = 18

local TITLE_COLOR = { 0.9, 0.85, 0.75, 1 }
local BACKGROUND_TOP = { 0.08, 0.05, 0.05, 1 }
local BACKGROUND_BOTTOM = { 0.06, 0.04, 0.08, 1 }
local BUTTON_COLOR = { 0.18, 0.12, 0.12, 0.85 }
local BUTTON_HOVER = { 0.4, 0.2, 0.2, 0.9 }
local BUTTON_DISABLED = { 0.14, 0.1, 0.1, 0.6 }
local BUTTON_OUTLINE = { 0.85, 0.4, 0.3, 0.95 }

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function mixColor(a, b, t)
    return {
        lerp(a[1], b[1], t),
        lerp(a[2], b[2], t),
        lerp(a[3], b[3], t),
        lerp(a[4] or 1, b[4] or 1, t),
    }
end

local function makeMenuItems(hasSave)
    return {
        {
            id = "continue",
            label = "Continue",
            disabled = not hasSave,
        },
        {
            id = "new",
            label = "New Game",
        },
        {
            id = "options",
            label = "Options (coming soon)",
            disabled = true,
        },
        {
            id = "exit",
            label = "Exit",
        },
    }
end

local function firstEnabledIndex(items)
    for index, item in ipairs(items) do
        if not item.disabled then
            return index
        end
    end
    return 1
end

function MainMenuScene.new(opts)
    opts = opts or {}

    local persisted = WorldState.load()
    local hasSave = persisted ~= nil

    local scene = {
        kind = SceneKinds.MAIN_MENU,
        sceneManager = opts.sceneManager,
        persistedState = persisted,
        menuItems = makeMenuItems(hasSave),
        selectedIndex = 1,
        statusMessage = nil,
        titleFont = love.graphics.newFont(44),
        buttonFont = love.graphics.newFont(22),
        smallFont = love.graphics.newFont(14),
    }

    scene.selectedIndex = firstEnabledIndex(scene.menuItems)

    return setmetatable(scene, MainMenuScene)
end

local function computeLayout(items)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    local totalHeight = #items * BUTTON_HEIGHT + (#items - 1) * BUTTON_SPACING
    local startY = height / 2 - totalHeight / 2
    local startX = width / 2 - BUTTON_WIDTH / 2

    for index, item in ipairs(items) do
        item.rect = {
            x = startX,
            y = startY + (index - 1) * (BUTTON_HEIGHT + BUTTON_SPACING),
            w = BUTTON_WIDTH,
            h = BUTTON_HEIGHT,
        }
    end
end

local function drawBackground()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    local steps = 120
    for step = 0, steps do
        local t = step / math.max(steps, 1)
        local color = mixColor(BACKGROUND_TOP, BACKGROUND_BOTTOM, t)
        love.graphics.setColor(color)
        local y = t * height
        local nextY = (step + 1) / math.max(steps, 1) * height
        love.graphics.rectangle("fill", 0, y, width, math.max(1, nextY - y))
    end
end

local function pointInRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.w
        and y >= rect.y
        and y <= rect.y + rect.h
end

local function clampSelection(items, index, direction)
    local count = #items
    if count == 0 then
        return 0
    end

    local nextIndex = index
    for _ = 1, count do
        nextIndex = nextIndex + direction
        if nextIndex < 1 then
            nextIndex = count
        elseif nextIndex > count then
            nextIndex = 1
        end

        if not items[nextIndex].disabled then
            return nextIndex
        end
    end

    return index
end

function MainMenuScene:activate(item)
    if item.disabled then
        return
    end

    if item.id == "new" then
        self:startNewGame()
        return
    end

    if item.id == "continue" then
        self:startContinue()
        return
    end

    if item.id == "exit" then
        love.event.quit()
        return
    end
end

function MainMenuScene:startNewGame()
    if not self.sceneManager then
        return
    end

    local world = WorldScene.new({
        sceneManager = self.sceneManager,
        worldSeed = love.math.random(1, 1000000),
    })

    self.sceneManager:pop()
    self.sceneManager:push(world)
end

function MainMenuScene:startContinue()
    if not self.sceneManager then
        return
    end

    if not self.persistedState then
        self.statusMessage = "No save found to load."
        return
    end

    local persisted = self.persistedState
    local options = {
        sceneManager = self.sceneManager,
        worldSeed = persisted.worldSeed,
        chunkSize = persisted.chunkSize,
        activeRadius = persisted.activeRadius,
        startBiomeId = persisted.startBiomeId,
        startBiomeRadius = persisted.startBiomeRadius,
        startBiomeCenter = persisted.startBiomeCenter,
        forceStartBiome = persisted.forceStartBiome,
        generatedChunks = WorldState.normalizeChunks(persisted.generatedChunks),
        visitedChunks = persisted.visitedChunks,
        minimapState = persisted.minimapState,
    }

    if not options.worldSeed then
        options.worldSeed = love.math.random(1, 1000000)
    end

    local world = WorldScene.new(options)

    self.sceneManager:pop()
    self.sceneManager:push(world)
end

function MainMenuScene:updateSelectionFromMouse(x, y)
    for index, item in ipairs(self.menuItems) do
        if pointInRect(x, y, item.rect) and not item.disabled then
            self.selectedIndex = index
            return
        end
    end
end

function MainMenuScene:update(_dt)
    computeLayout(self.menuItems)
end

function MainMenuScene:draw()
    computeLayout(self.menuItems)
    drawBackground()

    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(TITLE_COLOR)
    local width = love.graphics.getWidth()
    love.graphics.printf("Diablo 2D", 0, love.graphics.getHeight() * 0.22, width, "center")

    love.graphics.setFont(self.buttonFont)
    for index, item in ipairs(self.menuItems) do
        local rect = item.rect
        local isSelected = index == self.selectedIndex
        local color = item.disabled and BUTTON_DISABLED or BUTTON_COLOR
        local outline = BUTTON_OUTLINE

        if isSelected and not item.disabled then
            color = BUTTON_HOVER
        end

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 12, 12)

        if isSelected then
            love.graphics.setColor(outline)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 12, 12)
        end

        love.graphics.setColor(1, 1, 1, item.disabled and 0.6 or 1)
        love.graphics.printf(item.label, rect.x, rect.y + rect.h / 2 - 12, rect.w, "center")
    end

    if self.statusMessage then
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.9, 0.8, 0.8, 0.9)
        love.graphics.printf(
            self.statusMessage,
            0,
            love.graphics.getHeight() * 0.78,
            love.graphics.getWidth(),
            "center"
        )
    end

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.6, 0.5, 0.5, 0.9)
    love.graphics.printf(
        "Use arrows/W-S or mouse to navigate. Enter/click to select.",
        0,
        love.graphics.getHeight() - 36,
        love.graphics.getWidth(),
        "center"
    )
end

function MainMenuScene:keypressed(key)
    if key == "up" or key == "w" then
        self.selectedIndex = clampSelection(self.menuItems, self.selectedIndex, -1)
        return
    end

    if key == "down" or key == "s" then
        self.selectedIndex = clampSelection(self.menuItems, self.selectedIndex, 1)
        return
    end

    if key == "return" or key == "space" then
        local item = self.menuItems[self.selectedIndex]
        if item then
            self:activate(item)
        end
        return
    end

    if key == "escape" then
        love.event.quit()
    end
end

function MainMenuScene:mousepressed(x, y, button, _istouch, _presses)
    if button ~= 1 then
        return
    end

    self:updateSelectionFromMouse(x, y)
    local item = self.menuItems[self.selectedIndex]
    if item and pointInRect(x, y, item.rect) then
        self:activate(item)
    end
end

return MainMenuScene
