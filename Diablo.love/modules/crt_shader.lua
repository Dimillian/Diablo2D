local CRTShader = {}
CRTShader.__index = CRTShader

local unpack = table.unpack or unpack

local DEFAULT_CONFIG = {
    scanlineIntensity = 0.35,
    scanlineDensity = 1.0,
    vignetteIntensity = 0.2,
    curvature = 0.08,
    noiseStrength = 0.015,
}

local SHADER_SOURCE = [[
    extern float scanlineIntensity;
    extern float scanlineFrequency;
    extern float vignetteIntensity;
    extern float curvature;
    extern float noiseStrength;
    extern vec2 resolution;
    extern float time;

    float hash(vec2 p) {
        return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    }

    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 pixelCoords) {
        vec2 uv = textureCoords;
        vec2 centered = uv * 2.0 - 1.0;
        float aspect = resolution.x / resolution.y;
        centered.x *= aspect;

        centered.x *= 1.0 + curvature * (centered.y * centered.y);
        centered.y *= 1.0 + curvature * (centered.x * centered.x);

        centered.x /= aspect;
        uv = (centered + 1.0) * 0.5;

        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return vec4(0.0, 0.0, 0.0, 1.0);
        }

        vec4 texColor = Texel(texture, uv);

        float scan = sin((pixelCoords.y / resolution.y) * scanlineFrequency);
        float clampedIntensity = clamp(scanlineIntensity, 0.0, 1.0);
        float scanMix = mix(1.0, 0.5 + 0.5 * scan, clampedIntensity);
        texColor.rgb *= scanMix;

        float dist = length(centered);
        float vignette = smoothstep(0.6, 1.0, dist);
        texColor.rgb *= mix(1.0, 1.0 - vignette, clamp(vignetteIntensity, 0.0, 1.0));

        float noise = hash(pixelCoords + time);
        texColor.rgb += (noise - 0.5) * noiseStrength;
        texColor.rgb = clamp(texColor.rgb, 0.0, 1.0);

        return texColor * color;
    }
]]

---Create a new CRT shader instance.
---@param opts table|nil
---@return CRTShader
function CRTShader.new(opts)
    local instance = setmetatable({}, CRTShader)
    instance.shader = love.graphics.newShader(SHADER_SOURCE)
    instance.canvas = nil
    instance.previousCanvas = nil
    instance.time = 0
    instance.config = {}
    instance:setConfig(opts)

    local width, height = love.graphics.getDimensions()
    instance:resize(width, height)

    return instance
end

---Update the shader timer.
---@param dt number
function CRTShader:update(dt)
    self.time = self.time + dt
end

---Apply configuration overrides.
---@param opts table|nil
function CRTShader:setConfig(opts)
    opts = opts or {}

    self.config.scanlineIntensity = opts.scanlineIntensity or DEFAULT_CONFIG.scanlineIntensity
    self.config.scanlineDensity = opts.scanlineDensity or DEFAULT_CONFIG.scanlineDensity
    self.config.vignetteIntensity = opts.vignetteIntensity or DEFAULT_CONFIG.vignetteIntensity
    self.config.curvature = opts.curvature or DEFAULT_CONFIG.curvature
    self.config.noiseStrength = opts.noiseStrength or DEFAULT_CONFIG.noiseStrength

    if self.shader then
        self:updateUniforms()
    end
end

---Return the current configuration.
---@return table
function CRTShader:getConfig()
    local copy = {}
    for key, value in pairs(self.config) do
        copy[key] = value
    end
    return copy
end

---Rebuild the render canvas to match the window.
---@param width number
---@param height number
function CRTShader:resize(width, height)
    width = math.max(1, math.floor(width))
    height = math.max(1, math.floor(height))

    self.canvas = love.graphics.newCanvas(width, height)
    self.canvas:setFilter("linear", "linear")

    if self.shader then
        self.shader:send("resolution", { width, height })
        self:updateUniforms()
    end
end

---Prepare to draw the world to the CRT canvas.
function CRTShader:beginDraw()
    if not self.canvas then
        local width, height = love.graphics.getDimensions()
        self:resize(width, height)
    end

    self.previousCanvas = { love.graphics.getCanvas() }

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)
end

---Render the CRT canvas to the screen using the shader.
function CRTShader:endDraw()
    if not self.canvas then
        return
    end

    love.graphics.setCanvas()

    love.graphics.push("all")
    self:updateUniforms()
    self.shader:send("time", self.time)
    love.graphics.setShader(self.shader)
    love.graphics.setColor(1, 1, 1, 1)

    local canvasWidth, canvasHeight = self.canvas:getDimensions()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    local scaleX = windowWidth / canvasWidth
    local scaleY = windowHeight / canvasHeight

    love.graphics.draw(self.canvas, 0, 0, 0, scaleX, scaleY)

    love.graphics.pop()

    if self.previousCanvas then
        if #self.previousCanvas > 0 and self.previousCanvas[1] then
            love.graphics.setCanvas(unpack(self.previousCanvas))
        else
            love.graphics.setCanvas()
        end
        self.previousCanvas = nil
    end
end

---Send configuration uniforms to the shader.
function CRTShader:updateUniforms()
    if not self.shader then
        return
    end

    local height = 1
    if self.canvas then
        local _, canvasHeight = self.canvas:getDimensions()
        height = canvasHeight
    else
        _, height = love.graphics.getDimensions()
    end

    local frequency = self.config.scanlineDensity * math.pi * height

    self.shader:send("scanlineIntensity", self.config.scanlineIntensity)
    self.shader:send("scanlineFrequency", frequency)
    self.shader:send("vignetteIntensity", self.config.vignetteIntensity)
    self.shader:send("curvature", self.config.curvature)
    self.shader:send("noiseStrength", self.config.noiseStrength)
end

return CRTShader
