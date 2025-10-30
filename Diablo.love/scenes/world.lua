local Player = require("entities.player")
local createMovementComponent = require("components.movement")
local createRenderableComponent = require("components.renderable")
local createWanderComponent = require("components.wander")
local createPositionComponent = require("components.position")
local createSizeComponent = require("components.size")
local playerInputSystem = require("systems.player_input")
local movementSystem = require("systems.movement")
local renderSystem = require("systems.render")
local wanderSystem = require("systems.wander")
local uiPlayerStatus = require("systems.ui_player_status")
local cameraSystem = require("systems.camera")
local ECS = require("modules.ecs")

local WorldScene = {}
WorldScene.__index = WorldScene

---Create a world scene that owns entities like the player.
---@param opts table|nil
---@return WorldScene
function WorldScene.new(opts)
    opts = opts or {}

    local scene = {
        kind = "world",
        camera = { x = 0, y = 0 },
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

    -- Initialize ECS capabilities on the scene
    ECS.init(scene)

    -- Set metatable early so methods are available
    setmetatable(scene, WorldScene)

    -- Instantiate the player entity as part of the world setup.
    local player = Player.new({
        x = opts.playerX or 100,
        y = opts.playerY or 100,
        width = opts.playerWidth,
        height = opts.playerHeight,
        movement = {
            speed = opts.playerSpeed,
        },
        renderable = {
            kind = "rect",
            color = { 1, 1, 1, 1 },
        },
        playerControlled = opts.playerControlled,
        health = {
            max = opts.playerMaxHealth or 50,
            current = opts.playerHealth or opts.playerMaxHealth or 50,
        },
    })

    scene.playerId = player.id
    scene:addEntity(player)

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
        movement = createMovementComponent({
            speed = 80,
        }),
        renderable = createRenderableComponent({
            kind = "rect",
            color = { 1, 0, 0, 1 },
        }),
        wander = createWanderComponent({
            interval = 0.01,
        }),
    }

    scene:addEntity(enemy)

    return scene
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

function WorldScene:getPlayer()
    return self:getEntity(self.playerId)
end

return WorldScene
