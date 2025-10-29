local Player = require("entities.player")
local createMovementComponent = require("components.movement")
local createRenderableComponent = require("components.renderable")
local createPlayerControlledComponent = require("components.player_controlled")
local createWanderComponent = require("components.wander")
local createHealthComponent = require("components.health")
local createPositionComponent = require("components.position")
local createSizeComponent = require("components.size")
local playerInputSystem = require("systems.player_input")
local movementSystem = require("systems.movement")
local renderSystem = require("systems.render")
local wanderSystem = require("systems.wander")
local uiPlayerStatus = require("systems.ui_player_status")
local cameraSystem = require("systems.camera")

local WorldScene = {}
WorldScene.__index = WorldScene

---Create a world scene that owns entities like the player.
---@param opts table|nil
---@return WorldScene
function WorldScene.new(opts)
    opts = opts or {}

    local scene = {
        entities = {},
        kind = "world",
        camera = { x = 0, y = 0 },
        components = {
            movement = {},
            renderable = {},
            playerControlled = {},
            wander = {},
            health = {},
        },
        systems = {
            update = {
                playerInputSystem.update,
                wanderSystem.update,
                movementSystem.update,
                cameraSystem.update,
            },
            draw = {
                renderSystem.draw,
                uiPlayerStatus.draw,
            },
        },
    }

    -- Instantiate the player entity as part of the world setup.
    local player = Player.new({
        x = opts.playerX or 100,
        y = opts.playerY or 100,
        width = opts.playerWidth,
        height = opts.playerHeight,
    })

    scene.playerId = player.id
    scene.entities[player.id] = player
    scene.components.movement[player.id] = createMovementComponent({
        speed = opts.playerSpeed,
    })
    scene.components.renderable[player.id] = createRenderableComponent({
        kind = "rect",
        color = { 1, 1, 1, 1 },
    })
    scene.components.playerControlled[player.id] = createPlayerControlledComponent()
    scene.components.health[player.id] = createHealthComponent({
        max = opts.playerMaxHealth or 50,
        current = opts.playerHealth or opts.playerMaxHealth or 50,
    })

    -- Spawn a basic enemy entity to validate ECS flow.
    local enemyId = "enemy_1"
    local enemy = {
        id = enemyId,
        position = createPositionComponent({
            x = 300,
            y = 200,
        }),
        size = createSizeComponent({
            w = 20,
            h = 20,
        }),
    }

    scene.entities[enemyId] = enemy
    scene.components.movement[enemyId] = createMovementComponent({
        speed = 80,
    })
    scene.components.renderable[enemyId] = createRenderableComponent({
        kind = "rect",
        color = { 1, 0, 0, 1 },
    })
    scene.components.wander[enemyId] = createWanderComponent({
        interval = 0.01,
    })

    return setmetatable(scene, WorldScene)
end

function WorldScene:update(dt)
    for _, system in ipairs(self.systems.update) do
        system(self, dt)
    end
end

function WorldScene:draw()
    if not self.systems.draw then
        return
    end

    for _, system in ipairs(self.systems.draw) do
        system(self)
    end
end

function WorldScene:getEntity(entityId)
    if not entityId then
        return nil
    end
    return self.entities[entityId]
end

function WorldScene:getPlayer()
    return self:getEntity(self.playerId)
end

return WorldScene
