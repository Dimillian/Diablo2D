local Player = require("entities.player")
local mouseInputSystem = require("systems.input.mouse_input")
local playerInputSystem = require("systems.input.player_input")
local mouseLookSystem = require("systems.input.mouse_look")
local mouseMovementSystem = require("systems.input.mouse_movement")
local mouseTargetingSystem = require("systems.input.mouse_targeting")
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
local chunkActivationSystem = require("systems.world.chunk_activation")
local cullingSystem = require("systems.core.culling")
local uiMain = require("systems.ui.main")
local uiMinimapSystem = require("systems.ui.ui_minimap")
local cameraSystem = require("systems.core.camera")
local applyStatsSystem = require("systems.core.apply_stats")
local starterGearSystem = require("systems.core.starter_gear")
local combatSystem = require("systems.combat.combat")
local projectileMovementSystem = require("systems.projectile.movement")
local projectileCollisionSystem = require("systems.projectile.collision")
local lootPickupSystem = require("systems.core.loot_pickup")
local lootDropSystem = require("systems.core.loot_drops")
local lootScatterSystem = require("systems.core.loot_scatter")
local experienceSystem = require("systems.core.experience")
local uiTargetSystem = require("systems.ui.target")
local lootTooltipSystem = require("systems.core.loot_tooltip")
local potionConsumptionSystem = require("systems.core.potion_consumption")
local manaRegenSystem = require("systems.core.mana_regen")
local ChunkManager = require("modules.world.chunk_manager")
local SpawnResolver = require("modules.world.spawn_resolver")
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
                manaRegenSystem.update,
                playerInputSystem.update,
                potionConsumptionSystem.update,
                mouseLookSystem.update,
                mouseMovementSystem.update,
                mouseTargetingSystem.update,
                lootPickupSystem.update,
                playerAttackSystem.update,
                skillCastSystem.update,
                projectileMovementSystem.update,
                chunkActivationSystem.update,
                spawnSystem.update,
                cullingSystem.update,
                detectionSystem.update,
                wanderSystem.update,
                chaseSystem.update,
                foeAttackSystem.update,
                combatSystem.update,
                projectileCollisionSystem.update,
                lootDropSystem.update,
                lootScatterSystem.update,
                experienceSystem.update,
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
                uiMain.draw,
                uiMinimapSystem.draw,
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

    scene.worldSeed = opts.worldSeed or love.math.random(0, 1000000)
    scene.generatedChunks = opts.generatedChunks or {}
    scene.visitedChunks = opts.visitedChunks or {}
    scene.chunkConfig = {
        chunkSize = opts.chunkSize or 512,
        activeRadius = opts.activeRadius or 2,
    }

    for _, chunk in pairs(scene.generatedChunks) do
        chunk.spawnedEntities = {}
        chunk.defeatedFoes = chunk.defeatedFoes or {}
        chunk.lootedStructures = chunk.lootedStructures or {}
    end

    scene.spawnResolver = SpawnResolver.new({
        chunkSize = scene.chunkConfig.chunkSize,
    })

    scene.chunkManager = ChunkManager.new({
        chunkSize = scene.chunkConfig.chunkSize,
        activeRadius = scene.chunkConfig.activeRadius,
        worldSeed = scene.worldSeed,
        spawnResolver = scene.spawnResolver,
    })

    local chunkX, chunkY = ChunkManager.getChunkCoords(scene.chunkManager, player.position.x, player.position.y)
    ChunkManager.ensureChunkLoaded(scene.chunkManager, scene, chunkX, chunkY)

    scene.minimapState = opts.minimapState or { visible = true, zoom = 1 }
    if scene.minimapState.visible == nil then
        scene.minimapState.visible = true
    end
    scene.minimapState.zoom = scene.minimapState.zoom or 1

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

local function shallowCopyTable(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function copyDescriptorList(list)
    local result = {}
    for index, descriptor in ipairs(list or {}) do
        if type(descriptor) == "table" then
            result[index] = shallowCopyTable(descriptor)
        else
            result[index] = descriptor
        end
    end
    return result
end

function WorldScene:resetWorld(seed)
    self.worldSeed = seed or love.math.random(0, 1000000)
    self.generatedChunks = {}
    self.visitedChunks = {}
    self.activeChunkKeys = {}
    self.pendingCombatEvents = {}

    self.spawnResolver = SpawnResolver.new({
        chunkSize = self.chunkConfig and self.chunkConfig.chunkSize or 512,
    })

    self.chunkManager = ChunkManager.new({
        chunkSize = self.chunkConfig and self.chunkConfig.chunkSize or 512,
        activeRadius = self.chunkConfig and self.chunkConfig.activeRadius or 2,
        worldSeed = self.worldSeed,
        spawnResolver = self.spawnResolver,
    })

    for id, entity in pairs(self.entities) do
        if id ~= self.playerId then
            self:removeEntity(id)
        end
    end

    local player = self:getPlayer()
    if player and player.position then
        local chunkX, chunkY = ChunkManager.getChunkCoords(self.chunkManager, player.position.x, player.position.y)
        ChunkManager.ensureChunkLoaded(self.chunkManager, self, chunkX, chunkY)
    end
end

function WorldScene:serializeState()
    local state = {
        worldSeed = self.worldSeed,
        chunkSize = self.chunkConfig and self.chunkConfig.chunkSize or 512,
        activeRadius = self.chunkConfig and self.chunkConfig.activeRadius or 2,
        minimapState = {
            visible = self.minimapState and self.minimapState.visible or true,
            zoom = self.minimapState and self.minimapState.zoom or 1,
        },
        visitedChunks = shallowCopyTable(self.visitedChunks or {}),
        generatedChunks = {},
    }

    for key, chunk in pairs(self.generatedChunks or {}) do
        local transitionCopy = nil
        if chunk.transition then
            transitionCopy = shallowCopyTable(chunk.transition)
            if chunk.transition.neighbors then
                transitionCopy.neighbors = copyDescriptorList(chunk.transition.neighbors)
            end
        end

        state.generatedChunks[key] = {
            key = key,
            chunkX = chunk.chunkX,
            chunkY = chunk.chunkY,
            biomeId = chunk.biomeId,
            biomeLabel = chunk.biomeLabel,
            transition = transitionCopy,
            descriptors = {
                foes = copyDescriptorList(chunk.descriptors and chunk.descriptors.foes or {}),
                structures = copyDescriptorList(chunk.descriptors and chunk.descriptors.structures or {}),
            },
            props = copyDescriptorList(chunk.props or {}),
            defeatedFoes = shallowCopyTable(chunk.defeatedFoes or {}),
            lootedStructures = shallowCopyTable(chunk.lootedStructures or {}),
        }
    end

    return state
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

    if key == "f5" then
        self:resetWorld()
        return
    end

    if key == "f7" then
        self.debugChunks = not self.debugChunks
        return
    end

    if key == "m" then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.visible = not self.minimapState.visible
        return
    end

    if key == "[" then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.zoom = math.max(0.5, (self.minimapState.zoom or 1) - 0.1)
        return
    end

    if key == "]" then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.zoom = math.min(2.5, (self.minimapState.zoom or 1) + 0.1)
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
