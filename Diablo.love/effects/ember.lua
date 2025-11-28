local EmberEffect = {}

local DEFAULT_START_COLOR = { 1.0, 0.96, 0.65, 1.0 }
local DEFAULT_END_COLOR = { 1.0, 0.4, 0.08, 0.0 }

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

local flameShader = love.graphics.newShader(FIRE_SHADER)

local function createBaseEmitter(opts)
    opts = opts or {}
    return {
        mode = opts.mode or "band",
        band = opts.band or { x = opts.x or 0, y = opts.y or 0, w = opts.w or 0, h = opts.h or 0 },
        anchorX = opts.anchorX or opts.x or 0,
        anchorY = opts.anchorY or opts.y or 0,
        radius = opts.radius or 16,
        spawnInset = opts.spawnInset or 8,
        spawnYOffset = opts.spawnYOffset or 4,
        rate = opts.rate or 30,
        sizeMin = opts.sizeMin or 6,
        sizeMax = opts.sizeMax or 10,
        lifeBase = opts.lifeBase or 0.5,
        speedMin = opts.speedMin or 60,
        speedMax = opts.speedMax or 110,
        driftMin = opts.driftMin or -20,
        driftMax = opts.driftMax or 20,
        pixelScale = opts.pixelScale or 1.0,
        startColor = opts.startColor or DEFAULT_START_COLOR,
        endColor = opts.endColor or DEFAULT_END_COLOR,
        particles = {},
        timer = 0,
    }
end

function EmberEffect.createBandEmitter(opts)
    local emitter = createBaseEmitter(opts)
    emitter.mode = "band"
    return emitter
end

function EmberEffect.createRadialEmitter(opts)
    local emitter = createBaseEmitter(opts)
    emitter.mode = "radial"
    emitter.radius = opts.radius or 16
    return emitter
end

function EmberEffect.setBandArea(emitter, x, y, w, h)
    if not emitter then
        return
    end
    emitter.band = emitter.band or {}
    emitter.band.x = x or emitter.band.x or 0
    emitter.band.y = y or emitter.band.y or 0
    emitter.band.w = w or emitter.band.w or 0
    emitter.band.h = h or emitter.band.h or 0
end

function EmberEffect.setAnchor(emitter, x, y)
    if not emitter then
        return
    end
    emitter.anchorX = x or emitter.anchorX or 0
    emitter.anchorY = y or emitter.anchorY or 0
end

local function spawnParticle(emitter)
    local spawnX
    local spawnY
    if emitter.mode == "band" then
        local band = emitter.band or { x = 0, y = 0, w = 0, h = 0 }
        local xMin = band.x + emitter.spawnInset
        local xMax = band.x + math.max(band.w - emitter.spawnInset, emitter.spawnInset)
        spawnX = love.math.random(xMin, xMax)
        spawnY = band.y + (band.h or 0) - emitter.spawnYOffset
    else
        local angle = love.math.random() * math.pi * 2
        local radius = (emitter.radius or 0) * math.sqrt(love.math.random())
        spawnX = emitter.anchorX + math.cos(angle) * radius
        spawnY = emitter.anchorY + math.sin(angle) * radius
    end

    local speedRange = math.max(0, (emitter.speedMax or 0) - (emitter.speedMin or 0))
    local speed = (emitter.speedMin or 0) + love.math.random() * speedRange
    local drift = love.math.random(emitter.driftMin or -10, emitter.driftMax or 10)

    local dirX = 0
    local dirY = -1
    if emitter.mode == "radial" then
        local lift = -0.6
        local radialAngle = love.math.random() * math.pi * 2
        dirX = math.cos(radialAngle) * 0.4
        dirY = math.sin(radialAngle) * 0.25 + lift
        local len = math.sqrt(dirX * dirX + dirY * dirY)
        if len > 0 then
            dirX = dirX / len
            dirY = dirY / len
        end
    end

    return {
        x = spawnX,
        y = spawnY,
        vx = (dirX * speed) + drift,
        vy = dirY * speed,
        size = love.math.random(emitter.sizeMin or 4, emitter.sizeMax or 8),
        maxLife = love.math.random() * 0.5 + (emitter.lifeBase or 0.5),
        life = 0,
    }
end

function EmberEffect.update(emitter, dt)
    if not emitter or not dt or dt <= 0 then
        return
    end

    local particles = {}
    for _, particle in ipairs(emitter.particles or {}) do
        local life = particle.life + dt
        if life < particle.maxLife then
            particle.life = life
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.size = particle.size * (1 - dt * 0.2)
            particle.vy = particle.vy * (1 - dt * 0.08)
            particles[#particles + 1] = particle
        end
    end
    emitter.particles = particles

    emitter.timer = (emitter.timer or 0) + dt
    local rate = emitter.rate or 0
    if rate > 0 then
        local spawnInterval = 1 / rate
        while emitter.timer >= spawnInterval do
            emitter.timer = emitter.timer - spawnInterval
            emitter.particles[#emitter.particles + 1] = spawnParticle(emitter)
        end
    else
        emitter.timer = 0
    end
end

function EmberEffect.drawBand(emitter, time, alpha)
    if not emitter or emitter.mode ~= "band" then
        return
    end

    local band = emitter.band or { x = 0, y = 0, w = 0, h = 0 }
    love.graphics.push("all")
    love.graphics.setShader(flameShader)
    flameShader:send("time", time or 0)
    flameShader:send("resolution", { band.w or 0, band.h or 0 })
    flameShader:send("origin", { band.x or 0, band.y or 0 })
    love.graphics.setColor(1, 1, 1, alpha or 0.8)
    love.graphics.rectangle("fill", band.x or 0, band.y or 0, band.w or 0, band.h or 0)
    love.graphics.pop()
end

function EmberEffect.drawParticles(emitter)
    if not emitter or not emitter.particles then
        return
    end

    love.graphics.push("all")
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, particle in ipairs(emitter.particles) do
        local t = particle.life / particle.maxLife
        local color = mixColor(emitter.startColor, emitter.endColor, t)
        local baseSize = particle.size * (emitter.pixelScale or 1)
        local px = math.floor(particle.x + 0.5)
        local py = math.floor(particle.y + 0.5)
        love.graphics.setColor(color)
        love.graphics.rectangle(
            "fill",
            px - baseSize,
            py - baseSize,
            math.ceil(baseSize * 2.2),
            math.ceil(baseSize * 2.2)
        )
        love.graphics.setColor(color[1], color[2], color[3], color[4] * 0.8)
        love.graphics.rectangle(
            "fill",
            px - baseSize / 2,
            py - baseSize / 2,
            math.ceil(baseSize),
            math.ceil(baseSize)
        )
    end
    love.graphics.pop()
end

return EmberEffect
