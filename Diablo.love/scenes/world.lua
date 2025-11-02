local Player = require("entities.player")
local playerInputSystem = require("systems.player_input")
local mouseLookSystem = require("systems.mouse_look")
local mouseMovementSystem = require("systems.mouse_movement")
local playerAttackSystem = require("systems.player_attack")
local movementSystem = require("systems.movement")
local renderSystem = require("systems.render")
local renderLootSystem = require("systems.render_loot")
local renderEquipmentSystem = require("systems.render_equipment")
local renderMouseLookSystem = require("systems.render_mouse_look")
local renderHealthSystem = require("systems.render_health")
local renderDamageNumbersSystem = require("systems.render_damage_numbers")
local wanderSystem = require("systems.wander")
local detectionSystem = require("systems.detection")
local chaseSystem = require("systems.chase")
local foeAttackSystem = require("systems.foe_attack")
local spawnSystem = require("systems.spawn")
local cullingSystem = require("systems.culling")
local uiPlayerStatus = require("systems.ui_player_status")
local cameraSystem = require("systems.camera")
local applyStatsSystem = require("systems.apply_stats")
local starterGearSystem = require("systems.starter_gear")
local combatSystem = require("systems.combat")
local lootPickupSystem = require("systems.loot_pickup")
local lootDropSystem = require("systems.loot_drops")
local uiTargetSystem = require("systems.ui_target")
local lootTooltipSystem = require("systems.loot_tooltip")
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
        time = 0,
        lastUpdateDt = 0,
        pendingCombatEvents = {},
        currentTargetId = nil,
        targetDisplayTimer = 0,
        systemHelpers = {
            coordinates = require("system_helpers.coordinates"),
        },
        systems = {
            update = {
                starterGearSystem.update,
                applyStatsSystem.update,
                playerInputSystem.update,
                mouseLookSystem.update,
                mouseMovementSystem.update,
                playerAttackSystem.update,
                lootPickupSystem.update,
                spawnSystem.update,
                cullingSystem.update,
                detectionSystem.update,
                wanderSystem.update,
                chaseSystem.update,
                foeAttackSystem.update,
                combatSystem.update,
                lootDropSystem.update,
                movementSystem.update,
                cameraSystem.update,
            },
            draw = {
                renderSystem.draw,
                renderLootSystem.draw,
                renderEquipmentSystem.draw,
                renderMouseLookSystem.draw,
                renderHealthSystem.draw,
                renderDamageNumbersSystem.draw,
                uiPlayerStatus.draw,
                uiTargetSystem.draw,
                lootTooltipSystem.draw,
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
        combat = {
            range = 170, -- Extended range for player (longer than foes)
        },
    })

    scene.playerId = player.id
    scene:addEntity(player)

    -- Spawn initial groups of foes around the player
    spawnSystem.spawnInitialGroups(scene)

    return scene
end

function WorldScene:update(dt)
    dt = dt or 0
    self.lastUpdateDt = dt
    self.time = (self.time or 0) + dt
    self.pendingCombatEvents = self.pendingCombatEvents or {}

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

    self.pendingCombatEvents = {}
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
