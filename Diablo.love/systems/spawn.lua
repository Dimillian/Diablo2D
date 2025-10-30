local spawnSystem = {}

local Foe = require("entities.foe")
local foeTypes = require("data.foe_types")

-- Spawn configuration
local SPAWN_CONFIG = {
    minDistanceFromPlayer = 400, -- Minimum distance from player to spawn
    maxDistanceFromPlayer = 800, -- Maximum distance from player to spawn
    groupSpreadRadius = 60, -- How spread out foes in a group are
    minGroupsAtStart = 3,
    maxGroupsAtStart = 8,
    minFoesPerGroup = 1,
    maxFoesPerGroup = 5,
    respawnDistance = 600, -- Distance player needs to move before spawning new groups
}

local function calcDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function getRandomPositionAroundPlayer(playerX, playerY, minDist, maxDist)
    local angle = math.random() * math.pi * 2
    local distance = math.random(minDist, maxDist)
    local x = playerX + math.cos(angle) * distance
    local y = playerY + math.sin(angle) * distance
    return x, y
end

local function spawnGroup(world, centerX, centerY, foeType)
    local config = foeTypes.getConfig(foeType)
    local groupSize = math.random(SPAWN_CONFIG.minFoesPerGroup, SPAWN_CONFIG.maxFoesPerGroup)
    local foes = {}

    for i = 1, groupSize do
        -- Spread foes around the group center
        local spreadAngle = (i / groupSize) * math.pi * 2
        local spreadDist = math.random(0, SPAWN_CONFIG.groupSpreadRadius)
        local x = centerX + math.cos(spreadAngle) * spreadDist
        local y = centerY + math.sin(spreadAngle) * spreadDist

        local foe = Foe.new({
            x = x,
            y = y,
            width = 20,
            height = 20,
            speed = config.speed,
            detectionRange = config.detectionRange,
            wanderInterval = config.wanderInterval,
            renderable = {
                kind = "rect",
                color = config.color,
            },
        })

        world:addEntity(foe)
        table.insert(foes, foe)
    end

    return foes
end

function spawnSystem.spawnInitialGroups(world)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local playerX = player.position.x
    local playerY = player.position.y

    local numGroups = math.random(SPAWN_CONFIG.minGroupsAtStart, SPAWN_CONFIG.maxGroupsAtStart)
    local spawnPoints = {}

    for _ = 1, numGroups do
        local foeType = foeTypes.getRandomType()
        local x, y = getRandomPositionAroundPlayer(
            playerX,
            playerY,
            SPAWN_CONFIG.minDistanceFromPlayer,
            SPAWN_CONFIG.maxDistanceFromPlayer
        )

        -- Ensure spawn points aren't too close to each other
        local tooClose = false
        for _, point in ipairs(spawnPoints) do
            if calcDistance(x, y, point.x, point.y) < SPAWN_CONFIG.minDistanceFromPlayer * 0.5 then
                tooClose = true
                break
            end
        end

        if not tooClose then
            spawnGroup(world, x, y, foeType)
            table.insert(spawnPoints, { x = x, y = y })
        end
    end

    -- Store spawn points for respawn checking
    world.spawnPoints = spawnPoints
    world.lastSpawnPlayerX = playerX
    world.lastSpawnPlayerY = playerY
end

function spawnSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local playerX = player.position.x
    local playerY = player.position.y

    -- Initialize spawn tracking if needed
    if not world.lastSpawnPlayerX then
        world.lastSpawnPlayerX = playerX
        world.lastSpawnPlayerY = playerY
        return
    end

    -- Check if player has moved far enough to spawn new groups
    local distMoved = calcDistance(
        playerX,
        playerY,
        world.lastSpawnPlayerX,
        world.lastSpawnPlayerY
    )

    if distMoved >= SPAWN_CONFIG.respawnDistance then
        -- Spawn 1-3 new groups
        local numGroups = math.random(1, 3)

        for _ = 1, numGroups do
            local foeType = foeTypes.getRandomType()
            local x, y = getRandomPositionAroundPlayer(
                playerX,
                playerY,
                SPAWN_CONFIG.minDistanceFromPlayer,
                SPAWN_CONFIG.maxDistanceFromPlayer
            )

            spawnGroup(world, x, y, foeType)
        end

        -- Update last spawn position
        world.lastSpawnPlayerX = playerX
        world.lastSpawnPlayerY = playerY
    end
end

return spawnSystem
