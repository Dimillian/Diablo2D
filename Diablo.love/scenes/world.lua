local Player = require("entities.player")
local Foe = require("entities.foe")
local playerInputSystem = require("systems.player_input")
local movementSystem = require("systems.movement")
local renderSystem = require("systems.render")
local wanderSystem = require("systems.wander")
local detectionSystem = require("systems.detection")
local chaseSystem = require("systems.chase")
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
        debugMode = false, -- Debug toggle flag
        systems = {
            update = {
                playerInputSystem.update,
                detectionSystem.update,
                wanderSystem.update,
                chaseSystem.update,
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

    -- Spawn a basic foe entity to validate ECS flow.
    local foe = Foe.new({
        id = "foe_1",
        x = 300,
        y = 200,
        width = 20,
        height = 20,
        speed = 80,
        wanderInterval = 0.01,
        detectionRange = 150, -- Standard detection range
    })

    scene:addEntity(foe)

    -- Spawn a faster foe to demonstrate different foe configurations.
    local fastFoe = Foe.new({
        id = "foe_2",
        x = 400,
        y = 300,
        width = 20,
        height = 20,
        speed = 150,
        wanderInterval = 0.01,
        detectionRange = 250, -- Bigger detection range for faster foe
        renderable = {
            kind = "rect",
            color = { 1, 0.5, 0, 1 }, -- Orange color to distinguish from slower foe
        },
    })

    scene:addEntity(fastFoe)

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

function WorldScene:keypressed(key)
    if key == "t" then
        self.debugMode = not self.debugMode
    end
end

return WorldScene
