local ChunkManager = require("modules.world.chunk_manager")
local biomes = require("data.biomes")

local renderSystem = {}

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function mixColor(color, brighten)
    if not color then
        return { 0.2, 0.2, 0.2 }
    end

    brighten = brighten or 0
    local r = clamp01(color[1] + brighten)
    local g = clamp01(color[2] + brighten)
    local b = clamp01(color[3] + brighten)
    return { r, g, b }
end

local function drawForestGround(bounds, colors, rng, worldTime)
    if not colors then
        return
    end

    worldTime = worldTime or 0
    local accent = colors.accent or colors.secondary or colors.primary
    local secondary = colors.secondary or colors.primary

    love.graphics.setLineWidth(1)

    for i = 1, 70 do
        local baseX = bounds.x + rng:random() * bounds.w
        local baseY = bounds.y + rng:random() * bounds.h
        local height = 8 + rng:random() * 14

        -- Create wind animation using sine waves
        -- Each blade has a unique phase based on its position and index
        local phase = (baseX * 0.01) + (baseY * 0.005) + (i * 0.1)
        local windSpeed = 1.2 -- Wind animation speed
        local windStrength = 2.5 -- How much the grass sways
        local windWave = math.sin(worldTime * windSpeed + phase) * windStrength

        -- Base sway plus wind effect
        local baseSway = (rng:random() - 0.5) * 3
        local sway = baseSway + windWave

        local alpha = 0.25 + rng:random() * 0.3
        local color = mixColor(accent, rng:random() * 0.05)
        love.graphics.setColor(color[1], color[2], color[3], alpha)

        -- Main grass blade with wind animation
        love.graphics.line(baseX, baseY, baseX + sway, baseY - height)
        -- Secondary blade with slightly different wind phase
        local secondaryPhase = phase + 0.5
        local secondaryWindWave = math.sin(worldTime * windSpeed + secondaryPhase) * windStrength * 0.7
        love.graphics.line(baseX, baseY, baseX - (baseSway * 0.6 + secondaryWindWave), baseY - height * 0.7)
    end

    for _ = 1, 45 do
        local x = bounds.x + rng:random() * bounds.w
        local y = bounds.y + rng:random() * bounds.h
        local radius = 2 + rng:random() * 2
        local alpha = 0.08 + rng:random() * 0.12
        local color = mixColor(secondary, rng:random() * 0.04)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, radius)
    end

    love.graphics.setLineWidth(1)
end

-- luacheck: ignore 212/worldTime
local function drawDesertGround(bounds, colors, rng, worldTime)
    if not colors then
        return
    end

    local accent = colors.accent or colors.secondary or colors.primary
    local secondary = colors.secondary or colors.primary
    local stripeCount = 10
    local segmentCount = 7

    for i = 1, stripeCount do
        local y = bounds.y + (i / (stripeCount + 1)) * bounds.h
        local amplitude = 2 + rng:random() * 6
        local points = {}
        for segment = 0, segmentCount - 1 do
            local progress = segment / (segmentCount - 1)
            local px = bounds.x + progress * bounds.w
            local wave = math.sin((progress * math.pi * 2) + rng:random() * math.pi) * amplitude
            local py = y + wave
            points[#points + 1] = px
            points[#points + 1] = py
        end

        local alpha = 0.18 + rng:random() * 0.15
        local color = mixColor(accent, rng:random() * 0.08)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(points)
    end

    love.graphics.setLineWidth(1)

    for _ = 1, 55 do
        local x = bounds.x + rng:random() * bounds.w
        local y = bounds.y + rng:random() * bounds.h
        local radius = 1 + rng:random() * 2.5
        local alpha = 0.1 + rng:random() * 0.1
        local color = mixColor(secondary, rng:random() * 0.05)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, radius)
    end
end

-- luacheck: ignore 212/worldTime
local function drawTundraGround(bounds, colors, rng, worldTime)
    if not colors then
        return
    end

    local accent = colors.accent or colors.secondary or colors.primary
    local secondary = colors.secondary or colors.primary

    for _ = 1, 80 do
        local x = bounds.x + rng:random() * bounds.w
        local y = bounds.y + rng:random() * bounds.h
        local radius = 1.5 + rng:random() * 2.5
        local alpha = 0.12 + rng:random() * 0.15
        local color = mixColor(secondary, rng:random() * 0.08)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, radius)
    end

    for _ = 1, 24 do
        local x = bounds.x + rng:random() * bounds.w
        local y = bounds.y + rng:random() * bounds.h
        local length = 12 + rng:random() * 18
        local angle = (rng:random() - 0.5) * 0.8
        local dx = math.cos(angle) * (length / 2)
        local dy = math.sin(angle) * (length / 2)
        local alpha = 0.22 + rng:random() * 0.15
        local color = mixColor(accent, rng:random() * 0.05)
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(x - dx, y - dy, x + dx, y + dy)
    end

    love.graphics.setLineWidth(1)
end

local BIOME_GROUND_RENDERERS = {
    forest = drawForestGround,
    desert = drawDesertGround,
    tundra = drawTundraGround,
}

local PROP_STYLES = {
    shrub = { color = { 0.18, 0.45, 0.22, 0.8 }, kind = "circle" },
    stone = { color = { 0.4, 0.4, 0.42, 0.8 }, kind = "rect" },
    dune = { color = { 0.76, 0.62, 0.34, 0.6 }, kind = "polygon" },
    dry_brush = { color = { 0.7, 0.5, 0.2, 0.7 }, kind = "line" },
    snow_drift = { color = { 0.9, 0.95, 1, 0.7 }, kind = "circle" },
    ice_rock = { color = { 0.74, 0.82, 0.92, 0.7 }, kind = "rect" },
}

local function drawChunkBase(world, chunk)
    local manager = world.chunkManager
    if not manager then
        return
    end

    local biome = biomes.getById(chunk.biomeId)
    local colors = biome and biome.tileColors or nil
    local bounds = ChunkManager.computeChunkBounds(manager, chunk.chunkX, chunk.chunkY)

    love.graphics.setColor((colors and colors.primary) or { 0.15, 0.15, 0.15, 1 })
    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h)

    if colors then
        local renderer = BIOME_GROUND_RENDERERS[chunk.biomeId]
        if renderer then
            local rng = love.math.newRandomGenerator(chunk.seed or 0)
            local worldTime = world.time or 0
            -- luacheck: ignore 191
            renderer(bounds, colors, rng, worldTime)
        end
    end

    if chunk.transition and chunk.transition.transitionStrength and colors and colors.secondary then
        local alpha = math.min(0.7, chunk.transition.transitionStrength + 0.1)
        love.graphics.setColor(colors.secondary[1], colors.secondary[2], colors.secondary[3], alpha)
        love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.w, bounds.h)
    end
end

local function drawChunkProps(world, chunk)
    if not (world.visitedChunks and world.visitedChunks[chunk.key]) then
        return
    end

    for _, prop in ipairs(chunk.props or {}) do
        local style = PROP_STYLES[prop.kind] or PROP_STYLES.shrub
        local color = style.color
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)

        if style.kind == "circle" then
            love.graphics.circle("fill", prop.x, prop.y, (prop.radius or 12) * 0.6)
        elseif style.kind == "rect" then
            local size = (prop.radius or 14)
            love.graphics.rectangle("fill", prop.x - size / 2, prop.y - size / 2, size, size)
        elseif style.kind == "polygon" then
            local r = (prop.radius or 20) * 0.9
            love.graphics.polygon(
                "fill",
                prop.x - r,
                prop.y + r * 0.4,
                prop.x + r,
                prop.y + r * 0.4,
                prop.x,
                prop.y - r
            )
        elseif style.kind == "line" then
            love.graphics.setLineWidth(2)
            love.graphics.line(prop.x - 6, prop.y + 6, prop.x + 6, prop.y - 6)
            love.graphics.line(prop.x - 2, prop.y + 7, prop.x + 8, prop.y - 5)
        end
    end
end

local function drawChunkBounds(world)
    if not world.debugChunks then
        return
    end

    local manager = world.chunkManager
    if not manager then
        return
    end

    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.setLineWidth(1)

    for _, chunk in pairs(world.generatedChunks or {}) do
        local bounds = ChunkManager.computeChunkBounds(manager, chunk.chunkX, chunk.chunkY)
        love.graphics.rectangle("line", bounds.x, bounds.y, bounds.w, bounds.h)
    end
end

local function drawStructure(entity)
    local renderable = entity.renderable
    local shape = renderable.shape
    local x = entity.position.x
    local y = entity.position.y
    local w = entity.size.w
    local h = entity.size.h

    if shape == "tree_cluster" then
        love.graphics.setColor(0.35, 0.2, 0.05, 1)
        love.graphics.rectangle("fill", x + w / 2 - 8, y + h - 24, 16, 24, 4, 4)
        love.graphics.setColor(renderable.color)
        love.graphics.circle("fill", x + w / 2, y + h - 24, w * 0.45)
        love.graphics.circle("fill", x + w / 2 - 14, y + h - 30, w * 0.35)
        love.graphics.circle("fill", x + w / 2 + 14, y + h - 28, w * 0.3)
    elseif shape == "forest_hut" then
        love.graphics.setColor(renderable.color)
        love.graphics.rectangle("fill", x, y + h * 0.35, w, h * 0.65)
        love.graphics.setColor(0.6, 0.4, 0.18, 1)
        love.graphics.polygon("fill", x - 4, y + h * 0.35, x + w / 2, y, x + w + 4, y + h * 0.35)
    elseif shape == "desert_rock" then
        love.graphics.setColor(renderable.color)
        love.graphics.polygon("fill", x, y + h, x + w * 0.2, y + h * 0.25, x + w * 0.85, y + h * 0.15, x + w, y + h)
    elseif shape == "ruined_obelisk" then
        love.graphics.setColor(renderable.color)
        love.graphics.rectangle("fill", x + w * 0.35, y, w * 0.3, h)
        love.graphics.setColor(0.7, 0.65, 0.55, 0.8)
        love.graphics.polygon("fill", x + w * 0.35, y, x + w * 0.5, y - h * 0.2, x + w * 0.65, y)
    elseif shape == "ice_spike" then
        love.graphics.setColor(renderable.color)
        love.graphics.polygon("fill", x + w / 2, y, x + w, y + h, x, y + h)
    elseif shape == "frozen_ruin" then
        love.graphics.setColor(renderable.color)
        love.graphics.rectangle("fill", x, y + h * 0.3, w, h * 0.7)
        love.graphics.setColor(0.85, 0.9, 0.95, 0.7)
        love.graphics.rectangle("line", x + 4, y + h * 0.35, w - 8, h * 0.55)
    end
end

function renderSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    if world.chunkManager then
        for _, chunk in pairs(world.generatedChunks or {}) do
            drawChunkBase(world, chunk)
        end

        for _, chunk in pairs(world.generatedChunks or {}) do
            drawChunkProps(world, chunk)
        end
    end

    drawChunkBounds(world)

    -- Draw detection circles for entities with detection component (debug only)
    if world.debugMode then
        local entitiesWithDetection = world:queryEntities({ "detection", "position" })
        for _, entity in ipairs(entitiesWithDetection) do
            -- Skip inactive entities
            if entity.inactive and entity.inactive.isInactive then
                goto continue
            end

            local detection = entity.detection
            local pos = entity.position

            -- Draw detection circle (debug visualization)
            love.graphics.setColor(1, 1, 0, 0.3) -- Yellow, semi-transparent
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", pos.x, pos.y, detection.range)
            -- If chasing, draw a more visible ring
            if entity.chase then
                love.graphics.setColor(1, 0, 0, 0.5) -- Red when chasing
                love.graphics.circle("line", pos.x, pos.y, detection.range)
            end

            -- Visualize forced aggro leash when active
            if detection.forceAggro then
                local leashRadius = detection.leashRange or ((detection.range or 0) + (detection.leashExtension or 0))
                if leashRadius and leashRadius > 0 then
                    love.graphics.setColor(0, 0.7, 1, 0.35) -- Cyan-ish leash range
                    love.graphics.circle("line", pos.x, pos.y, leashRadius)
                end
            end

            ::continue::
        end
    end

    -- Draw entities
    local entities = world:queryEntities({ "renderable", "position", "size" })

    for _, entity in ipairs(entities) do
        if entity.structure then
            drawStructure(entity)
            goto continue
        end

        -- Skip inactive entities (too far from player)
        if entity.inactive and entity.inactive.isInactive then
            goto continue
        end

        local renderable = entity.renderable
        if entity.playerControlled then
            goto continue
        end

        if entity.foe then
            goto continue
        end

        if renderable.kind == "rect" then
            -- Skip rendering base rectangle if entity has armor equipped
            local hasArmor = false
            if entity.equipment then
                local armorSlots = { "head", "chest", "gloves", "feet" }
                for _, slotId in ipairs(armorSlots) do
                    if entity.equipment[slotId] then
                        hasArmor = true
                        break
                    end
                end
            end

            -- Only render base rectangle if no armor is equipped
            if not hasArmor then
                -- Tint entity when recently damaged (visual strike indicator)
                local color = renderable.color
                if entity.recentlyDamaged then
                    -- Flash red tint when damaged
                    color = { 1, 0.3, 0.3, color[4] or 1 }
                end

                love.graphics.setColor(color)
                love.graphics.rectangle(
                    "fill",
                    entity.position.x,
                    entity.position.y,
                    entity.size.w,
                    entity.size.h
                )
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderSystem
