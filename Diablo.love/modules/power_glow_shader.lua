local PowerGlowShader = {}

local shader = nil
local shaderPath = "shaders/power_glow.glsl"

local defaultSettings = {
    intensity = 0.5,
    pulseSpeed = 0.5,
    glowRadius = 0.6,
    distortionStrength = 1.5,
}

local function loadShader()
    if shader then
        return shader
    end

    local source, err = love.filesystem.read(shaderPath)
    if not source then
        print(string.format("Power glow shader missing (%s): %s", shaderPath, err))
        return nil
    end

    local ok, compiledOrError = pcall(love.graphics.newShader, source)
    if not ok then
        print("Failed to compile power glow shader: " .. tostring(compiledOrError))
        return nil
    end

    shader = compiledOrError
    return shader
end

function PowerGlowShader.getShader()
    return loadShader()
end

function PowerGlowShader.apply(entity, world, outlineColor, drawFunc)
    local rarityId = entity.foe and entity.foe.rarity
    local isPowerful = rarityId == "elite" or rarityId == "boss"

    if not isPowerful or not drawFunc then
        drawFunc()
        return
    end

    local shaderInstance = loadShader()
    if not shaderInstance then
        drawFunc()
        return
    end

    local time = world.time or 0
    local glowColor = outlineColor or { 1.0, 0.8, 0.2 }

    -- Send uniforms
    shaderInstance:send("time", time)
    shaderInstance:send("intensity", defaultSettings.intensity)
    shaderInstance:send("glowColor", glowColor)
    shaderInstance:send("pulseSpeed", defaultSettings.pulseSpeed)
    shaderInstance:send("glowRadius", defaultSettings.glowRadius)
    shaderInstance:send("distortionStrength", defaultSettings.distortionStrength)

    love.graphics.setShader(shaderInstance)
    drawFunc()
    love.graphics.setShader()
end

return PowerGlowShader
