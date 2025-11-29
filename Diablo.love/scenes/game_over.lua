local SceneKinds = require("modules.scene_kinds")
local MainMenuScene = require("scenes.main_menu")
local EmberEffect = require("effects.ember")
local LifetimeStats = require("modules.lifetime_stats")

local GameOverScene = {}
GameOverScene.__index = GameOverScene

local TITLE_COLOR = { 0.95, 0.8, 0.45, 1 }
local TITLE_GLOW = { 0.92, 0.36, 0.12, 0.5 }
local TITLE_SHADOW = { 0.05, 0.01, 0.01, 0.9 }
local BACKGROUND_TOP = { 0.05, 0.04, 0.05, 1 }
local BACKGROUND_BOTTOM = { 0.03, 0.02, 0.04, 1 }
local PANEL_COLOR = { 0.08, 0.05, 0.05, 0.78 }
local PANEL_OUTLINE = { 0.5, 0.18, 0.12, 0.9 }
local BUTTON_COLOR = { 0.24, 0.12, 0.12, 0.9 }
local BUTTON_HOVER = { 0.5, 0.24, 0.16, 0.95 }
local BUTTON_OUTLINE = { 0.95, 0.5, 0.26, 0.95 }

local FIRE_PARTICLE_START = { 1.0, 0.96, 0.65, 1.0 }
local FIRE_PARTICLE_END = { 1.0, 0.4, 0.08, 0.0 }

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

local function formatNumber(value)
    value = value or 0
    return string.format("%d", math.floor(value + 0.5))
end

local function getTitleLayout(scene)
    local width = love.graphics.getWidth()
    local font = scene.titleFont
    local titleText = "GAME OVER"
    local textWidth = font:getWidth(titleText)
    local centerX = width / 2
    local y = love.graphics.getHeight() * 0.24
    local paddingX = 24
    local paddingY = 12
    local bannerX = centerX - textWidth / 2 - paddingX
    local bannerY = y - paddingY
    local bannerW = textWidth + paddingX * 2
    local bannerH = font:getHeight() + paddingY * 2

    return {
        text = titleText,
        font = font,
        centerX = centerX,
        y = y,
        bannerX = bannerX,
        bannerY = bannerY,
        bannerW = bannerW,
        bannerH = bannerH,
    }
end

local function getPanelLayout()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    local panelW = math.min(width * 0.7, 640)
    local panelH = math.min(height * 0.55, 460)
    local panelX = width / 2 - panelW / 2
    local panelY = height * 0.36

    local buttonW = math.min(panelW * 0.6, 360)
    local buttonH = 56
    local buttonX = width / 2 - buttonW / 2
    local buttonY = panelY + panelH - buttonH - 42

    return {
        x = panelX,
        y = panelY,
        w = panelW,
        h = panelH,
        button = {
            x = buttonX,
            y = buttonY,
            w = buttonW,
            h = buttonH,
        },
    }
end

local function getBottomFireArea()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local fireH = math.min(height * 0.22, 180)
    local fireY = height - fireH

    return {
        x = 0,
        y = fireY,
        w = width,
        h = fireH,
    }
end

function GameOverScene.new(opts)
    opts = opts or {}

    local scene = {
        kind = SceneKinds.GAME_OVER,
        sceneManager = opts.sceneManager,
        world = opts.world,
        time = 0,
        titleFont = love.graphics.newFont(58),
        bodyFont = love.graphics.newFont(22),
        bottomFire = EmberEffect.createBandEmitter({
            rate = 38,
            sizeMin = 7,
            sizeMax = 13,
            lifeBase = 1.4,
            spawnInset = 10,
            spawnYOffset = 6,
            pixelScale = 1.0,
            startColor = FIRE_PARTICLE_START,
            endColor = FIRE_PARTICLE_END,
        }),
        titleFire = EmberEffect.createBandEmitter({
            rate = 28,
            sizeMin = 5,
            sizeMax = 11,
            lifeBase = 0.9,
            spawnInset = 6,
            spawnYOffset = 4,
            pixelScale = 0.9,
            startColor = FIRE_PARTICLE_START,
            endColor = FIRE_PARTICLE_END,
        }),
        buttonHot = false,
        lifetimeStats = LifetimeStats.ensure(nil, opts.lifetimeStats or (opts.world and opts.world.lifetimeStats)),
    }

    return setmetatable(scene, GameOverScene)
end

local function pointInRect(x, y, rect)
    if not rect then
        return false
    end

    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

local function drawRetroTitle(layout)
    love.graphics.setFont(layout.font)

    love.graphics.setColor(0.05, 0.02, 0.02, 0.96)
    love.graphics.rectangle("fill", layout.bannerX, layout.bannerY, layout.bannerW, layout.bannerH, 12, 12)

    love.graphics.setColor(TITLE_SHADOW)
    love.graphics.print(layout.text, layout.centerX - layout.font:getWidth(layout.text) / 2 + 2, layout.y + 2)

    love.graphics.setColor(TITLE_GLOW)
    love.graphics.print(layout.text, layout.centerX - layout.font:getWidth(layout.text) / 2, layout.y)

    love.graphics.setColor(TITLE_COLOR)
    love.graphics.print(layout.text, layout.centerX - layout.font:getWidth(layout.text) / 2, layout.y - 2)
end

local function drawPanel(layout)
    love.graphics.setColor(PANEL_COLOR)
    love.graphics.rectangle("fill", layout.x, layout.y, layout.w, layout.h, 12, 12)
    love.graphics.setColor(PANEL_OUTLINE)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", layout.x, layout.y, layout.w, layout.h, 12, 12)
end

local function drawStats(panel, stats, font)
    if not stats then
        return
    end

    love.graphics.setFont(font)
    local startY = panel.y + 96
    local lineHeight = font:getHeight() + 6
    local valueX = panel.x + panel.w - 40
    local valueWidth = math.max(120, panel.w * 0.35)
    local entries = {
        { label = "Foes slain", value = formatNumber(stats.foesKilled) },
        { label = "Damage dealt", value = formatNumber(stats.damageDealt) },
        { label = "XP earned", value = formatNumber(stats.experienceEarned) },
        { label = "Levels gained", value = formatNumber(stats.levelsGained) },
    }

    for index, entry in ipairs(entries) do
        local y = startY + (index - 1) * lineHeight
        love.graphics.setColor(0.95, 0.72, 0.55, 0.96)
        love.graphics.print(entry.label, panel.x + 40, y)
        love.graphics.setColor(1, 0.96, 0.9, 1)
        love.graphics.printf(entry.value, valueX - valueWidth, y, valueWidth, "right")
    end
end

function GameOverScene:update(dt)
    self.time = self.time + (dt or 0)

    local titleLayout = getTitleLayout(self)
    local titleFireH = titleLayout.bannerH * 0.95
    local titleFireY = titleLayout.bannerY + titleLayout.bannerH - titleFireH
    EmberEffect.setBandArea(self.titleFire, titleLayout.bannerX, titleFireY, titleLayout.bannerW, titleFireH)
    EmberEffect.update(self.titleFire, dt or 0)

    local bottomArea = getBottomFireArea()
    EmberEffect.setBandArea(self.bottomFire, bottomArea.x, bottomArea.y, bottomArea.w, bottomArea.h)
    EmberEffect.update(self.bottomFire, dt or 0)

    local panel = getPanelLayout()
    self.buttonRect = panel.button

    local mouseX, mouseY = love.mouse.getPosition()
    self.buttonHot = pointInRect(mouseX, mouseY, self.buttonRect)
end

function GameOverScene:draw()
    love.graphics.push("all")
    drawBackground()

    local panel = getPanelLayout()
    local titleLayout = getTitleLayout(self)

    EmberEffect.drawBand(self.bottomFire, self.time, 0.76)
    EmberEffect.drawBand(self.titleFire, self.time, 0.78)

    drawRetroTitle(titleLayout)
    EmberEffect.drawParticles(self.titleFire)

    drawPanel(panel)

    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(0.92, 0.86, 0.82, 0.92)
    local bodyText = "You have fallen. The darkness creeps closer."
    love.graphics.printf(bodyText, panel.x + 28, panel.y + 34, panel.w - 56, "center")

    drawStats(panel, self.lifetimeStats, self.bodyFont)

    love.graphics.setFont(self.bodyFont)
    local button = panel.button
    local color = self.buttonHot and BUTTON_HOVER or BUTTON_COLOR
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 12, 12)
    love.graphics.setColor(BUTTON_OUTLINE)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 12, 12)

    love.graphics.setColor(1, 0.96, 0.9, 1)
    love.graphics.printf("Return to Main Menu", button.x, button.y + button.h / 2 - 12, button.w, "center")

    EmberEffect.drawParticles(self.bottomFire)
    love.graphics.pop()
end

function GameOverScene:returnToMainMenu()
    local manager = self.sceneManager
    if not manager then
        return
    end

    manager:pop()

    local current = manager:current()
    if current and current.kind == SceneKinds.WORLD then
        manager:pop()
    end

    manager:push(
        MainMenuScene.new({
            sceneManager = manager,
        })
    )
end

function GameOverScene:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if pointInRect(x, y, self.buttonRect) then
        self:returnToMainMenu()
    end
end

function GameOverScene:keypressed(key)
    if key == "return" or key == "space" or key == "escape" then
        self:returnToMainMenu()
    end
end

return GameOverScene
