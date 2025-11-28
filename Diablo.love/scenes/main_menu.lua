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
local FIRE_PARTICLE_START = { 1.0, 0.96, 0.65, 1.0 }
local FIRE_PARTICLE_END = { 1.0, 0.4, 0.08, 0.0 }
local FIRE_PARTICLE_RATE = 42
local PANEL_FIRE_PARTICLE_RATE = 32
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

local FIRE_SHADER = [[
extern number time;
extern vec2 resolution;
extern vec2 origin;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    vec2 pos = (px - origin) / resolution;
    pos = clamp(pos, 0.0, 1.0);
    pos.y = 1.0 - pos.y;

    float pixelate = 110.0;
    pos = floor(pos * pixelate) / pixelate;

    float t = time * 0.7;
    float n1 = noise(vec2(pos.x * 9.0, pos.y * 6.0 + t * 1.4));
    float n2 = noise(vec2(pos.x * 16.0 + t * 0.4, pos.y * 12.0 - t * 1.2));
    float column = sin((pos.x + n1 * 0.08) * 18.0 + t * 2.0) * 0.08;

    float base = pow(pos.y, 2.0);
    float intensity = clamp(base * 1.1 + n1 * 0.45 + n2 * 0.35 + column, 0.0, 1.2);

    float taper = smoothstep(0.12, 0.35, pos.y) * (1.0 - smoothstep(0.72, 0.95, pos.y));
    float edge = smoothstep(0.05, 0.2, pos.x) * smoothstep(0.95, 0.8, pos.x);
    float alpha = clamp(intensity * taper * edge, 0.0, 1.0);

    vec3 cold = vec3(0.14, 0.04, 0.04);
    vec3 warm = vec3(0.85, 0.28, 0.07);
    vec3 hot = vec3(1.0, 0.82, 0.45);
    float heat = clamp(intensity * 1.3 + pos.y * 0.3, 0.0, 1.0);
    vec3 flame = mix(warm, hot, heat);
    vec3 finalColor = mix(cold, flame, clamp(pos.y * 1.25, 0.0, 1.0));

    return vec4(finalColor * color.rgb, alpha * color.a);
}
]]

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

    local persisted = WorldState.load(WorldState.DEFAULT_SLOT)
    local hasSave = WorldState.slotExists(WorldState.DEFAULT_SLOT)

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
        fireParticles = {},
        panelFireParticles = {},
        fireSpawnTimer = 0,
        panelFireSpawnTimer = 0,
        fireShader = love.graphics.newShader(FIRE_SHADER),
        time = 0,
    }

    scene.selectedIndex = firstEnabledIndex(scene.menuItems)

    return setmetatable(scene, MainMenuScene)
end

local function getTitleLayout(scene)
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

local function getMenuBounds(items)
    if #items == 0 then
        return { x = 0, y = 0, w = 0, h = 0 }
    end

    local minX = items[1].rect.x
    local maxX = items[1].rect.x + items[1].rect.w
    local minY = items[1].rect.y
    local maxY = items[1].rect.y + items[1].rect.h

    for _, item in ipairs(items) do
        minX = math.min(minX, item.rect.x)
        maxX = math.max(maxX, item.rect.x + item.rect.w)
        minY = math.min(minY, item.rect.y)
        maxY = math.max(maxY, item.rect.y + item.rect.h)
    end

    return {
        x = minX,
        y = minY,
        w = maxX - minX,
        h = maxY - minY,
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

local function drawFireBackdrop(scene, x, y, w, h)
    if not scene.fireShader then
        return
    end

    love.graphics.push("all")
    love.graphics.setShader(scene.fireShader)
    scene.fireShader:send("time", scene.time or 0)
    scene.fireShader:send("resolution", { w, h })
    scene.fireShader:send("origin", { x, y })
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.pop()
end

local function drawFireParticles(particles)
    if not particles then
        return
    end

    love.graphics.push("all")
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, particle in ipairs(particles) do
        local t = 1 - (particle.life / particle.maxLife)
        local color = mixColor(FIRE_PARTICLE_START, FIRE_PARTICLE_END, t)
        love.graphics.setColor(color)
        love.graphics.rectangle(
            "fill",
            math.floor(particle.x + 0.5) - particle.size,
            math.floor(particle.y + 0.5) - particle.size,
            math.ceil(particle.size * 2.2),
            math.ceil(particle.size * 2.2)
        )
        love.graphics.setColor(color[1], color[2], color[3], color[4] * 0.8)
        love.graphics.rectangle(
            "fill",
            math.floor(particle.x + 0.5) - particle.size / 2,
            math.floor(particle.y + 0.5) - particle.size / 2,
            math.ceil(particle.size),
            math.ceil(particle.size)
        )
    end
    love.graphics.pop()
end

local function drawRetroTitle(scene, layout)
    love.graphics.setFont(layout.font)

    -- Banner base
    love.graphics.setColor(0.08, 0.04, 0.04, 0.94)
    love.graphics.rectangle("fill", layout.bannerX, layout.bannerY, layout.bannerW, layout.bannerH, 10, 10)

    -- Banner highlight band
    love.graphics.setColor(0.25, 0.12, 0.12, 0.7)
    love.graphics.rectangle("fill", layout.bannerX, layout.bannerY, layout.bannerW, layout.bannerH * 0.45, 10, 10)

    -- Inner border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.85, 0.45, 0.25, 0.8)
    love.graphics.rectangle(
        "line",
        layout.bannerX + 2,
        layout.bannerY + 2,
        layout.bannerW - 4,
        layout.bannerH - 4,
        8,
        8
    )

    -- Shadow pass
    love.graphics.setColor(TITLE_SHADOW)
    love.graphics.printf(layout.text, 0, layout.y + 3, love.graphics.getWidth(), "center")
    love.graphics.printf(layout.text, 2, layout.y + 1, love.graphics.getWidth(), "center")

    -- Main text
    love.graphics.setColor(TITLE_PRIMARY)
    love.graphics.printf(layout.text, 0, layout.y, love.graphics.getWidth(), "center")

    -- Glow overlay
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(TITLE_GLOW)
    love.graphics.printf(layout.text, 0, layout.y - 1, love.graphics.getWidth(), "center")

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

    local options = WorldState.buildWorldOptions(self.persistedState)
    if not options then
        self.statusMessage = "Save data is corrupted."
        return
    end

    options.sceneManager = self.sceneManager
    if not options.worldSeed then
        options.worldSeed = love.math.random(1, 1000000)
    end

    local world = WorldScene.new(options)

    self.sceneManager:pop()
    self.sceneManager:push(world)
end

function MainMenuScene:updateSelectionFromMouse(x, y)
    local hoveredIndex = nil

    for index, item in ipairs(self.menuItems) do
        if pointInRect(x, y, item.rect) and not item.disabled then
            hoveredIndex = index
            break
        end
    end

    if hoveredIndex then
        self.selectedIndex = hoveredIndex
    end
end

local function seedSpark(scene)
    local layout = getTitleLayout(scene)
    local bannerX = layout.bannerX
    local bannerY = layout.bannerY
    local bannerW = layout.bannerW
    local bannerH = layout.bannerH

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

local function updateFireParticlesSet(currentParticles, timer, spawnArea, dt, rate)
    local particles = {}
    for _, particle in ipairs(currentParticles or {}) do
        local life = particle.life - dt
        if life > 0 then
            particle.life = life
            particle.y = particle.y - particle.speed * dt
            particle.x = particle.x + particle.drift * dt
            particle.size = particle.size * (1 - dt * 0.25)
            particle.speed = particle.speed * (1 - dt * 0.08)
            particles[#particles + 1] = particle
        end
    end

    timer = (timer or 0) + dt

    local spawnInterval = 1 / rate
    while timer >= spawnInterval do
        timer = timer - spawnInterval
        local x = love.math.random(spawnArea.xMin, spawnArea.xMax)
        local y = spawnArea.y
        local size = love.math.random(spawnArea.sizeMin, spawnArea.sizeMax)
        local life = love.math.random() * 0.5 + spawnArea.lifeBase

        particles[#particles + 1] = {
            x = x,
            y = y,
            size = size,
            maxLife = life,
            life = life,
            speed = love.math.random() * 60 + 80,
            drift = love.math.random() * 22 - 11,
        }
    end

    return particles, timer
end

function MainMenuScene:update(dt)
    self.time = (self.time or 0) + (dt or 0)
    local layout = getTitleLayout(self)
    computeLayout(self.menuItems)
    local bottomArea = getBottomFireArea()
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

    local titleSpawn = {
        xMin = layout.bannerX + 8,
        xMax = layout.bannerX + layout.bannerW - 8,
        y = layout.bannerY + layout.bannerH - 4,
        sizeMin = 7,
        sizeMax = 12,
        lifeBase = 0.6,
    }
    local bottomSpawn = {
        xMin = bottomArea.x + 12,
        xMax = bottomArea.x + bottomArea.w - 12,
        y = bottomArea.y + bottomArea.h - 4,
        sizeMin = 7,
        sizeMax = 13,
        lifeBase = 0.6,
    }

    self.fireParticles, self.fireSpawnTimer = updateFireParticlesSet(
        self.fireParticles,
        self.fireSpawnTimer,
        titleSpawn,
        dt or 0,
        FIRE_PARTICLE_RATE
    )

    self.panelFireParticles, self.panelFireSpawnTimer = updateFireParticlesSet(
        self.panelFireParticles,
        self.panelFireSpawnTimer,
        bottomSpawn,
        dt or 0,
        PANEL_FIRE_PARTICLE_RATE
    )

    -- Hover should mirror keyboard selection highlight
    local mouseX, mouseY = love.mouse.getPosition()
    self:updateSelectionFromMouse(mouseX, mouseY)
end

function MainMenuScene:draw()
    computeLayout(self.menuItems)
    local layout = getTitleLayout(self)
    local bottomArea = getBottomFireArea()
    drawBackground()

    drawFireBackdrop(self, bottomArea.x, bottomArea.y, bottomArea.w, bottomArea.h)

    local titleFireH = layout.bannerH * 0.95
    local titleFireY = layout.bannerY + layout.bannerH - titleFireH
    drawFireBackdrop(self, layout.bannerX, titleFireY, layout.bannerW, titleFireH)
    drawRetroTitle(self, layout)
    drawFireParticles(self.fireParticles)

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

    drawFireParticles(self.panelFireParticles)

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
