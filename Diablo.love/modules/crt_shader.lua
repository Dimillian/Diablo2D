local CRTShader = {}

local shader = nil
local canvas = nil
local timeUniform = 0
local shaderPath = "shaders/crt.glsl"
local enabled = true

local settings = {
    curvature = 0.005,
    scanStrength = 0.20,
    vignetteStrength = 0.50,
    noiseStrength = 0.10,
    sharpStrength = 2,
    glowStrength = 0.50,
    glowThreshold = 0.35,
    glowRadius = 3.0,
}

local function loadShaderSource()
    local source, err = love.filesystem.read(shaderPath)
    if not source then
        print(string.format("CRT shader missing (%s): %s", shaderPath, err))
        return nil
    end
    return source
end

local function sendStaticUniforms()
    if not shader then
        return
    end

    shader:send("curvature", settings.curvature)
    shader:send("scanStrength", settings.scanStrength)
    shader:send("vignetteStrength", settings.vignetteStrength)
    shader:send("noiseStrength", settings.noiseStrength)
    shader:send("sharpStrength", settings.sharpStrength)
    shader:send("glowStrength", settings.glowStrength)
    shader:send("glowThreshold", settings.glowThreshold)
    shader:send("glowRadius", settings.glowRadius)
end

local function ensureCanvas(width, height)
    if canvas and canvas:getWidth() == width and canvas:getHeight() == height then
        return
    end

    canvas = love.graphics.newCanvas(width, height)

    if shader then
        shader:send("resolution", { width, height })
        shader:send("rgbOffset", 1.5 / math.max(width, 1))
    end
end

function CRTShader.load()
    local source = loadShaderSource()
    if not source then
        return
    end

    local ok, compiledOrError = pcall(love.graphics.newShader, source)
    if not ok then
        print("Failed to compile CRT shader: " .. tostring(compiledOrError))
        return
    end

    shader = compiledOrError
    timeUniform = 0
    ensureCanvas(love.graphics.getWidth(), love.graphics.getHeight())
    sendStaticUniforms()
end

function CRTShader.resize(width, height)
    if not shader then
        return
    end

    ensureCanvas(width, height)
end

function CRTShader.update(dt)
    if not shader then
        return
    end

    timeUniform = timeUniform + dt
    shader:send("time", timeUniform)
end

function CRTShader.draw(drawFunc)
    local canPostProcess = enabled and shader and canvas
    if type(drawFunc) ~= "function" then
        return
    end

    if not canPostProcess then
        drawFunc()
        return
    end

    love.graphics.push("all")
    love.graphics.setCanvas({ canvas, stencil = true })
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()
    drawFunc()
    love.graphics.setCanvas()

    shader:send("resolution", { canvas:getWidth(), canvas:getHeight() })

    love.graphics.setShader(shader)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.setShader()
    love.graphics.pop()
end

function CRTShader.isEnabled()
    return enabled
end

function CRTShader.setEnabled(state)
    state = state ~= false
    enabled = state
end

function CRTShader.toggle()
    CRTShader.setEnabled(not enabled)
end

return CRTShader
