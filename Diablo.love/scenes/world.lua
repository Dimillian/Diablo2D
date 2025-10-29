local Player = require("entities.player")
local createMovementComponent = require("components.movement")
local createRenderableComponent = require("components.renderable")
local createPlayerControlledComponent = require("components.player_controlled")
local createWanderComponent = require("components.wander")
local playerInputSystem = require("systems.player_input")
local movementSystem = require("systems.movement")
local renderSystem = require("systems.render")
local wanderSystem = require("systems.wander")

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
        components = {
            movement = {},
            renderable = {},
            playerControlled = {},
            wander = {},
        },
        systems = {
            update = {
                playerInputSystem.update,
                wanderSystem.update,
                movementSystem.update,
            },
            draw = {
                renderSystem.draw,
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
        width = player.size.w,
        height = player.size.h,
        color = { 1, 1, 1, 1 },
    })
    scene.components.playerControlled[player.id] = createPlayerControlledComponent()

    -- Spawn a basic enemy entity to validate ECS flow.
    local enemyId = "enemy_1"
    local enemy = {
        id = enemyId,
        position = {
            x = 300,
            y = 200,
        },
        size = {
            w = 20,
            h = 20,
        },
        move = player.move, -- reuse player movement helper for now
    }

    scene.entities[enemyId] = enemy
    scene.components.movement[enemyId] = createMovementComponent({
        speed = 80,
    })
    scene.components.renderable[enemyId] = createRenderableComponent({
        kind = "rect",
        width = enemy.size.w,
        height = enemy.size.h,
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

return WorldScene
