local Player = require("entities.player")
local mouseInputSystem = require("systems.input.mouse_input")
local playerInputSystem = require("systems.input.player_input")
local mouseLookSystem = require("systems.input.mouse_look")
local mouseMovementSystem = require("systems.input.mouse_movement")
local playerAttackSystem = require("systems.combat.player_attack")
local skillCastSystem = require("systems.skills.cast")
local movementSystem = require("systems.core.movement")
local renderSystem = require("systems.render.render_world")
local renderLootSystem = require("systems.render.loot")
local renderEquipmentSystem = require("systems.render.equipment")
local renderProjectileSystem = require("systems.render.projectile")
local renderMouseLookSystem = require("systems.render.mouse_look")
local renderHealthSystem = require("systems.render.health")
local renderDamageNumbersSystem = require("systems.render.damage_numbers")
local wanderSystem = require("systems.ai.wander")
local detectionSystem = require("systems.ai.detection")
local chaseSystem = require("systems.ai.chase")
local foeAttackSystem = require("systems.combat.foe_attack")
local spawnSystem = require("systems.ai.spawn")
local cullingSystem = require("systems.core.culling")
local uiPlayerStatus = require("systems.ui.player_status")
local uiBottomBar = require("systems.ui.bottom_bar")
local uiSkillsBar = require("systems.ui.skills_bar")
local cameraSystem = require("systems.core.camera")
local applyStatsSystem = require("systems.core.apply_stats")
local starterGearSystem = require("systems.core.starter_gear")
local combatSystem = require("systems.combat.combat")
local projectileMovementSystem = require("systems.projectile.movement")
local projectileCollisionSystem = require("systems.projectile.collision")
local lootPickupSystem = require("systems.core.loot_pickup")
local lootDropSystem = require("systems.core.loot_drops")
local uiTargetSystem = require("systems.ui.target")
local lootTooltipSystem = require("systems.core.loot_tooltip")
local potionConsumptionSystem = require("systems.core.potion_consumption")
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
        sceneManager = opts.sceneManager, -- Reference to scene manager for opening inventory
        systemHelpers = {
            coordinates = require("systems.helpers.coordinates"),
        },
        input = {
            mouse = {
                primary = {
                    held = false,
                    pressed = false,
                    released = false,
                    clickId = 0,
                    consumedClickId = nil,
                    _pressedFrame = false,
                    _releasedFrame = false,
                },
            },
        },
        systems = {
            update = {
                mouseInputSystem.update,
                starterGearSystem.update,
                applyStatsSystem.update,
                playerInputSystem.update,
                potionConsumptionSystem.update,
                mouseLookSystem.update,
                mouseMovementSystem.update,
                lootPickupSystem.update,
                playerAttackSystem.update,
                skillCastSystem.update,
                projectileMovementSystem.update,
                spawnSystem.update,
                cullingSystem.update,
                detectionSystem.update,
                wanderSystem.update,
                chaseSystem.update,
                foeAttackSystem.update,
                combatSystem.update,
                projectileCollisionSystem.update,
                lootDropSystem.update,
                movementSystem.update,
                cameraSystem.update,
            },
            draw = {
                renderSystem.draw,
                renderLootSystem.draw,
                renderEquipmentSystem.draw,
                renderProjectileSystem.draw,
                renderMouseLookSystem.draw,
                renderHealthSystem.draw,
                renderDamageNumbersSystem.draw,
                uiPlayerStatus.draw,
                uiBottomBar.draw,
                uiSkillsBar.draw,
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
            range = 100, -- Extended range for player (longer than foes)
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
        return
    end

    local handledSkill = false
    if key == "1" or key == "2" or key == "3" or key == "4" then
        handledSkill = skillCastSystem.handleKeypress(self, key)
    end

    if (key == "1" or key == "2") and not handledSkill then
        potionConsumptionSystem.handleKeypress(self, key)
    end
end

function WorldScene:mousepressed(x, y, button, _istouch, _presses)
    if button == 1 then
        local function pointInRect(rect)
            return rect
                and x >= rect.x
                and x <= rect.x + rect.w
                and y >= rect.y
                and y <= rect.y + rect.h
        end

        if pointInRect(self.bottomBarHealthPotionRect) then
            potionConsumptionSystem.handleClick(self, "health")
            return
        end

        if pointInRect(self.bottomBarManaPotionRect) then
            potionConsumptionSystem.handleClick(self, "mana")
            return
        end

        if pointInRect(self.bottomBarBookRect) then
            if self.sceneManager then
                self.sceneManager:toggleSkills("s")
            end
            return
        end

        -- Check if bag button was clicked
        if self.bottomBarBagRect then
            local rect = self.bottomBarBagRect
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                -- Open inventory via scene manager
                if self.sceneManager then
                    self.sceneManager:toggleInventory("i")
                end
                return
            end
        end

        mouseInputSystem.queuePress(self)
    end
end

function WorldScene:mousereleased(_x, _y, button, _istouch, _presses)
    if button == 1 then
        mouseInputSystem.queueRelease(self)
    end
end

return WorldScene
