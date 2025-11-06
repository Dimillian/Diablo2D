local ChunkManager = require("modules.world.chunk_manager")
local biomes = require("data.biomes")

local renderSystem = {}

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
            if entity.inactive then
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
        if entity.inactive then
            goto continue
        end

        local renderable = entity.renderable
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
                -- Tint player when recently damaged (visual strike indicator)
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
