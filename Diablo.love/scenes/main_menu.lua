local SceneKinds = require("modules.scene_kinds")
local WorldScene = require("scenes.world")
local WorldState = require("modules.world_state")

local MainMenuScene = {}
MainMenuScene.__index = MainMenuScene

local BUTTON_WIDTH = 320
local BUTTON_HEIGHT = 56
local BUTTON_SPACING = 18

local TITLE_PRIMARY = { 0.95, 0.78, 0.32, 1 }
local TITLE_SHADOW = { 0.08, 0.02, 0.02, 0.9 }
local TITLE_GLOW = { 0.7, 0.15, 0.05, 0.5 }
local TITLE_SPARK_COLOR = { 0.95, 0.4, 0.2, 0.8 }
local TITLE_SPARK_FADE = { 0.95, 0.6, 0.3, 0.0 }
local TITLE_SPARK_COUNT = 14
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
        titleFont = love.graphics.newFont(54),
        buttonFont = love.graphics.newFont(22),
        smallFont = love.graphics.newFont(14),
        titleSparks = {},
        time = 0,
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

local function drawRetroTitle(scene)
    local width = love.graphics.getWidth()
    local titleText = "DIABLO 2D"
    local font = scene.titleFont
    love.graphics.setFont(font)

    local textWidth = font:getWidth(titleText)
    local centerX = width / 2
    local y = love.graphics.getHeight() * 0.18
    local bannerPaddingX = 32
    local bannerPaddingY = 16
    local bannerX = centerX - textWidth / 2 - bannerPaddingX
    local bannerY = y - bannerPaddingY
    local bannerW = textWidth + bannerPaddingX * 2
    local bannerH = font:getHeight() + bannerPaddingY * 2

    -- Banner base
    love.graphics.setColor(0.08, 0.04, 0.04, 0.94)
    love.graphics.rectangle("fill", bannerX, bannerY, bannerW, bannerH, 10, 10)

    -- Banner highlight band
    love.graphics.setColor(0.25, 0.12, 0.12, 0.7)
    love.graphics.rectangle("fill", bannerX, bannerY, bannerW, bannerH * 0.45, 10, 10)

    -- Inner border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.85, 0.45, 0.25, 0.8)
    love.graphics.rectangle("line", bannerX + 2, bannerY + 2, bannerW - 4, bannerH - 4, 8, 8)

    -- Shadow pass
    love.graphics.setColor(TITLE_SHADOW)
    love.graphics.printf(titleText, 0, y + 3, width, "center")
    love.graphics.printf(titleText, 2, y + 1, width, "center")

    -- Main text
    love.graphics.setColor(TITLE_PRIMARY)
    love.graphics.printf(titleText, 0, y, width, "center")

    -- Glow overlay
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(TITLE_GLOW)
    love.graphics.printf(titleText, 0, y - 1, width, "center")

    -- Animated sparkles around the banner edges
    love.graphics.setColor(1, 1, 1, 1)
    local now = scene.time or 0
    for _, spark in ipairs(scene.titleSparks or {}) do
        local life = math.max(0, spark.start + spark.duration - now)
        if life > 0 then
            local t = life / spark.duration
            local size = spark.size * (0.6 + 0.4 * t)
            local alphaColor = mixColor(TITLE_SPARK_COLOR, TITLE_SPARK_FADE, 1 - t)
            love.graphics.setColor(alphaColor)
            love.graphics.circle("fill", spark.x, spark.y, size)
        end
    end

    love.graphics.setBlendMode("alpha")
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

local function seedSpark(scene)
    local width = love.graphics.getWidth()
    local font = scene.titleFont
    local titleText = "DIABLO 2D"
    local textWidth = font:getWidth(titleText)
    local centerX = width / 2
    local y = love.graphics.getHeight() * 0.18
    local bannerPaddingX = 32
    local bannerPaddingY = 16
    local bannerX = centerX - textWidth / 2 - bannerPaddingX
    local bannerY = y - bannerPaddingY
    local bannerW = textWidth + bannerPaddingX * 2
    local bannerH = font:getHeight() + bannerPaddingY * 2

    scene.titleSparks = scene.titleSparks or {}
    if #scene.titleSparks < TITLE_SPARK_COUNT then
        local edge = love.math.random(1, 4)
        local x, yPos
        if edge == 1 then
            x = love.math.random(bannerX, bannerX + bannerW)
            yPos = bannerY
        elseif edge == 2 then
            x = love.math.random(bannerX, bannerX + bannerW)
            yPos = bannerY + bannerH
        elseif edge == 3 then
            x = bannerX
            yPos = love.math.random(bannerY, bannerY + bannerH)
        else
            x = bannerX + bannerW
            yPos = love.math.random(bannerY, bannerY + bannerH)
        end

        scene.titleSparks[#scene.titleSparks + 1] = {
            x = x,
            y = yPos,
            size = love.math.random(3, 6),
            duration = love.math.random() * 0.8 + 0.4,
            start = scene.time,
        }
    end
end

function MainMenuScene:update(dt)
    self.time = (self.time or 0) + (dt or 0)
    -- Remove expired sparks and replenish to target count for continuous effect
    local alive = {}
    for _, spark in ipairs(self.titleSparks or {}) do
        if self.time < spark.start + spark.duration then
            alive[#alive + 1] = spark
        end
    end
    self.titleSparks = alive

    while #self.titleSparks < TITLE_SPARK_COUNT do
        seedSpark(self)
    end

    computeLayout(self.menuItems)
end

function MainMenuScene:draw()
    computeLayout(self.menuItems)
    drawBackground()

    drawRetroTitle(self)

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
