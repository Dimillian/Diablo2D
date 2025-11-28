local Player = require("entities.player")
local ComponentDefaults = require("data.component_defaults")
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
local renderPlayerSystem = require("systems.render.player")
local renderFoeSystem = require("systems.render.foe")
local renderProjectileSystem = require("systems.render.projectile")
local renderMouseLookSystem = require("systems.render.mouse_look")
local renderHealthSystem = require("systems.render.health")
local renderBloodBurstSystem = require("systems.render.blood_burst")
local renderDamageNumbersSystem = require("systems.render.damage_numbers")
local wanderSystem = require("systems.ai.wander")
local detectionSystem = require("systems.ai.detection")
local chaseSystem = require("systems.ai.chase")
local foeAttackSystem = require("systems.combat.foe_attack")
local spawnSystem = require("systems.ai.spawn")
local chunkActivationSystem = require("systems.world.chunk_activation")
local cullingSystem = require("systems.core.culling")
local uiNotificationsSystem = require("systems.ui.notifications")
local uiMain = require("systems.ui.main")
local uiMinimapSystem = require("systems.ui.ui_minimap")
local debugMenu = require("systems.ui.debug_menu")
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
local walkingAnimationSystem = require("systems.core.walking_animation")
local foeAnimationSystem = require("systems.core.foe_animation")
local deathAnimationSystem = require("systems.core.death_animation")
local deathDetectionSystem = require("systems.core.death_detection")
local physicsSystem = require("systems.core.physics")
local ChunkManager = require("modules.world.chunk_manager")
local SpawnResolver = require("modules.world.spawn_resolver")
local ECS = require("modules.ecs")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")
local Physics = require("modules.physics")
local GameOverScene

local WorldScene = {}
WorldScene.__index = WorldScene

local function copyList(list)
    local result = {}
    for index, entry in ipairs(list or {}) do
        result[index] = entry
    end
    return result
end

local function copyMap(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

local function applyPlayerState(player, state)
    if not player or not state then
        return
    end

    if state.position and player.position then
        player.position.x = state.position.x or player.position.x
        player.position.y = state.position.y or player.position.y
    end

    if state.baseStats and player.baseStats then
        for key, value in pairs(state.baseStats) do
            player.baseStats[key] = value
        end
    end

    if state.movement and player.movement then
        player.movement.speed = state.movement.speed or player.movement.speed
    end

    if state.combat and player.combat then
        player.combat.range = state.combat.range or player.combat.range
    end

    if state.health and player.health then
        player.health.current = state.health.current or player.health.current
        player.health.max = state.health.max or player.health.max
        player.health.current = math.min(player.health.current, player.health.max)
    end

    if state.mana and player.mana then
        player.mana.current = state.mana.current or player.mana.current
        player.mana.max = state.mana.max or player.mana.max
        player.mana.current = math.min(player.mana.current, player.mana.max)
    end

    if state.potions and player.potions then
        player.potions.healthPotionCount = state.potions.healthPotionCount or player.potions.healthPotionCount
        player.potions.maxHealthPotionCount = state.potions.maxHealthPotionCount or player.potions.maxHealthPotionCount
        player.potions.manaPotionCount = state.potions.manaPotionCount or player.potions.manaPotionCount
        player.potions.maxManaPotionCount = state.potions.maxManaPotionCount or player.potions.maxManaPotionCount
        player.potions.cooldownDuration = state.potions.cooldownDuration or player.potions.cooldownDuration
        player.potions.cooldownRemaining = state.potions.cooldownRemaining or player.potions.cooldownRemaining
    end

    if state.experience and player.experience then
        player.experience.level = state.experience.level or player.experience.level
        player.experience.currentXP = state.experience.currentXP or player.experience.currentXP
        player.experience.xpForNextLevel = state.experience.xpForNextLevel or player.experience.xpForNextLevel
        player.experience.unallocatedPoints = state.experience.unallocatedPoints or player.experience.unallocatedPoints
    end

    if state.inventory and player.inventory then
        player.inventory.capacity = state.inventory.capacity or player.inventory.capacity
        player.inventory.gold = state.inventory.gold or player.inventory.gold
        player.inventory.items = copyList(state.inventory.items)
    end

    if state.equipment and player.equipment then
        player.equipment = copyMap(state.equipment)
    end

    if state.skills and player.skills then
        player.skills.availablePoints = state.skills.availablePoints or player.skills.availablePoints
        player.skills.allocations = copyMap(state.skills.allocations)

        local equipped = {}
        for index, skill in ipairs(state.skills.equipped or {}) do
            equipped[index] = skill
        end
        player.skills.equipped = equipped
    end
end

---Create a world scene that owns entities like the player.
---@param opts table|nil
---@return WorldScene
function WorldScene.new(opts)
    opts = opts or {}

    local scene = {
        kind = SceneKinds.WORLD,
        camera = { x = 0, y = 0 },
        debugMode = false, -- Debug toggle flag
        time = 0,
        lastUpdateDt = 0,
        pendingCombatEvents = {},
        sceneManager = opts.sceneManager, -- Reference to scene manager for opening inventory
        starterGearGenerated = opts.starterGearGenerated or false,
        systemHelpers = {
            coordinates = require("systems.helpers.coordinates"),
        },
        notifications = {},
        gameOverTriggered = false,
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
                uiNotificationsSystem.update,
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
                deathDetectionSystem.update,
                lootDropSystem.update,
                lootScatterSystem.update,
                experienceSystem.update,
                walkingAnimationSystem.update,
                foeAnimationSystem.update,
                deathAnimationSystem.update,
                movementSystem.update,
                physicsSystem.update,
                cameraSystem.update,
            },
            draw = {
                renderSystem.draw,
                renderLootSystem.draw,
                renderFoeSystem.draw,
                renderPlayerSystem.draw,
                renderEquipmentSystem.draw,
                renderProjectileSystem.draw,
                renderMouseLookSystem.draw,
                renderHealthSystem.draw,
                renderBloodBurstSystem.draw,
                renderDamageNumbersSystem.draw,
                uiMain.draw,
                uiMinimapSystem.draw,
                uiNotificationsSystem.draw,
                uiTargetSystem.draw,
                debugMenu.draw,
                lootTooltipSystem.draw,
            },
        },
    }

    -- Initialize ECS capabilities on the scene
    ECS.init(scene)

    Physics.initWorld(scene)

    local originalAddEntity = scene.addEntity
    function scene:addEntity(entity)
        originalAddEntity(self, entity)
        if entity and entity.physicsBody then
            Physics.ensureBody(self, entity)
        end
    end

    local originalRemoveEntity = scene.removeEntity
    function scene:removeEntity(entityId)
        local entity = self.entities and self.entities[entityId]
        if entity and entity.physicsBody then
            Physics.destroyBody(entity)
        end

        originalRemoveEntity(self, entityId)
    end

    local originalAddComponent = scene.addComponent
    function scene:addComponent(entityId, componentName, component)
        originalAddComponent(self, entityId, componentName, component)

        if componentName == "physicsBody" then
            local entity = self.entities and self.entities[entityId]
            if entity then
                Physics.ensureBody(self, entity)
            end
        end
    end

    local originalRemoveComponent = scene.removeComponent
    function scene:removeComponent(entityId, componentName)
        if componentName == "physicsBody" then
            local entity = self.entities and self.entities[entityId]
            if entity then
                Physics.destroyBody(entity)
            end
        end

        originalRemoveComponent(self, entityId, componentName)
    end

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
            max = opts.playerMaxHealth or ComponentDefaults.PLAYER_STARTING_HEALTH,
            current = opts.playerHealth or opts.playerMaxHealth or ComponentDefaults.PLAYER_STARTING_HEALTH,
        },
        combat = {
            range = ComponentDefaults.PLAYER_COMBAT_RANGE, -- Extended range for player (longer than foes)
        },
    })

    scene.playerId = player.id
    scene:addEntity(player)

    scene.worldSeed = opts.worldSeed or love.math.random(0, 1000000)
    scene.generatedChunks = opts.generatedChunks or {}
    scene.visitedChunks = opts.visitedChunks or {}
    scene.chunkConfig = {
        chunkSize = opts.chunkSize or 512,
        activeRadius = opts.activeRadius or 4,
    }
    scene.startBiomeId = opts.startBiomeId or "forest"
    scene.startBiomeRadius = math.max(0, opts.startBiomeRadius or 2)

    local hasPersistedChunks = opts.generatedChunks and next(opts.generatedChunks) ~= nil
    if opts.forceStartBiome ~= nil then
        scene.forceStartBiome = opts.forceStartBiome
    else
        scene.forceStartBiome = not hasPersistedChunks
    end

    local chunkSize = scene.chunkConfig.chunkSize
    local currentChunkX = math.floor(player.position.x / chunkSize)
    local currentChunkY = math.floor(player.position.y / chunkSize)
    if opts.startBiomeCenter then
        scene.startBiomeCenter = {
            chunkX = opts.startBiomeCenter.chunkX,
            chunkY = opts.startBiomeCenter.chunkY,
        }
    else
        scene.startBiomeCenter = {
            chunkX = currentChunkX,
            chunkY = currentChunkY,
        }
    end

    scene.spawnResolver = SpawnResolver.new({
        chunkSize = scene.chunkConfig.chunkSize,
    })

    scene.chunkManager = ChunkManager.new({
        chunkSize = scene.chunkConfig.chunkSize,
        activeRadius = scene.chunkConfig.activeRadius,
        worldSeed = scene.worldSeed,
        spawnResolver = scene.spawnResolver,
        startBiomeId = scene.startBiomeId,
        startBiomeCenter = scene.startBiomeCenter,
        startBiomeRadius = scene.startBiomeRadius,
        forceStartBiome = scene.forceStartBiome,
    })

    for _, chunk in pairs(scene.generatedChunks) do
        chunk.spawnedEntities = {}
        chunk.defeatedFoes = chunk.defeatedFoes or {}
        chunk.lootedStructures = chunk.lootedStructures or {}
        ChunkManager.ensureChunkLoaded(scene.chunkManager, scene, chunk.chunkX, chunk.chunkY)
    end

    local chunkX = currentChunkX
    local chunkY = currentChunkY
    local providedSafeZone = opts.spawnSafeZone
    scene.spawnSafeZone = {
        chunkKey = (providedSafeZone and providedSafeZone.chunkKey)
            or ChunkManager.getChunkKey(scene.chunkManager, chunkX, chunkY),
        centerX = (providedSafeZone and providedSafeZone.centerX) or player.position.x,
        centerY = (providedSafeZone and providedSafeZone.centerY) or player.position.y,
        radius = (providedSafeZone and providedSafeZone.radius) or opts.spawnSafeRadius or 192,
    }
    ChunkManager.ensureChunkLoaded(scene.chunkManager, scene, chunkX, chunkY)

    scene.minimapState = opts.minimapState or { visible = true, zoom = 1 }
    if scene.minimapState.visible == nil then
        scene.minimapState.visible = true
    end
    scene.minimapState.zoom = scene.minimapState.zoom or 1

    if opts.playerState then
        applyPlayerState(player, opts.playerState)
    end

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
    self.gameOverTriggered = false
    self.forceStartBiome = true
    self.startBiomeRadius = math.max(0, self.startBiomeRadius or 2)

    local chunkSize = self.chunkConfig and self.chunkConfig.chunkSize or 512
    local activeRadius = self.chunkConfig and self.chunkConfig.activeRadius or 4
    local player = self:getPlayer()
    local chunkX, chunkY = 0, 0
    if player and player.position then
        chunkX = math.floor(player.position.x / chunkSize)
        chunkY = math.floor(player.position.y / chunkSize)
    end
    self.startBiomeCenter = {
        chunkX = chunkX,
        chunkY = chunkY,
    }

    self.spawnResolver = SpawnResolver.new({
        chunkSize = chunkSize,
    })

    self.chunkManager = ChunkManager.new({
        chunkSize = chunkSize,
        activeRadius = activeRadius,
        worldSeed = self.worldSeed,
        spawnResolver = self.spawnResolver,
        startBiomeId = self.startBiomeId,
        startBiomeCenter = self.startBiomeCenter,
        startBiomeRadius = self.startBiomeRadius,
        forceStartBiome = self.forceStartBiome,
    })

    for id in pairs(self.entities) do
        if id ~= self.playerId then
            self:removeEntity(id)
        end
    end

    player = self:getPlayer()
    if player and player.position then
        self.spawnSafeZone = {
            chunkKey = ChunkManager.getChunkKey(self.chunkManager, chunkX, chunkY),
            centerX = player.position.x,
            centerY = player.position.y,
            radius = (self.spawnSafeZone and self.spawnSafeZone.radius) or 192,
        }
        ChunkManager.ensureChunkLoaded(self.chunkManager, self, chunkX, chunkY)
    end
end

function WorldScene:serializeState()
    local state = {
        worldSeed = self.worldSeed,
        chunkSize = self.chunkConfig and self.chunkConfig.chunkSize or 512,
        activeRadius = self.chunkConfig and self.chunkConfig.activeRadius or 4,
        startBiomeId = self.startBiomeId,
        startBiomeRadius = self.startBiomeRadius,
        startBiomeCenter = self.startBiomeCenter and {
            chunkX = self.startBiomeCenter.chunkX,
            chunkY = self.startBiomeCenter.chunkY,
        } or nil,
        forceStartBiome = self.forceStartBiome,
        minimapState = {
            visible = self.minimapState and self.minimapState.visible or true,
            zoom = self.minimapState and self.minimapState.zoom or 1,
        },
        visitedChunks = shallowCopyTable(self.visitedChunks or {}),
        spawnSafeZone = self.spawnSafeZone
            and {
                chunkKey = self.spawnSafeZone.chunkKey,
                centerX = self.spawnSafeZone.centerX,
                centerY = self.spawnSafeZone.centerY,
                radius = self.spawnSafeZone.radius,
            }
            or nil,
        starterGearGenerated = self.starterGearGenerated or false,
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
            zoneName = chunk.zoneName,
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
    local action = InputManager.getActionForKey(key)

    if action == InputActions.DEBUG_TOGGLE then
        self.debugMode = not self.debugMode
        return
    end

    if action == InputActions.RESET_WORLD then
        self:resetWorld()
        return
    end

    if action == InputActions.DEBUG_CHUNKS then
        self.debugChunks = not self.debugChunks
        return
    end

    if action == InputActions.MINIMAP_TOGGLE then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.visible = not self.minimapState.visible
        return
    end

    if action == InputActions.MINIMAP_ZOOM_OUT then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.zoom = math.max(0.5, (self.minimapState.zoom or 1) - 0.1)
        return
    end

    if action == InputActions.MINIMAP_ZOOM_IN then
        self.minimapState = self.minimapState or { visible = true, zoom = 1 }
        self.minimapState.zoom = math.min(2.5, (self.minimapState.zoom or 1) + 0.1)
        return
    end

    if action == InputActions.SKILL_1
        or action == InputActions.SKILL_2
        or action == InputActions.SKILL_3
        or action == InputActions.SKILL_4
    then
        skillCastSystem.handleKeypress(self, action)
    end

    if action == InputActions.POTION_HEALTH or action == InputActions.POTION_MANA then
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

        -- Handle debug menu clicks
        if debugMenu.handleClick(self, x, y) then
            return
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
                local skillsKey = InputManager.getActionKey(InputActions.TOGGLE_SKILLS)
                self.sceneManager:toggleSkills(skillsKey)
            end
            return
        end

        -- Check if bag button was clicked
        if self.bottomBarBagRect then
            local rect = self.bottomBarBagRect
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                -- Open inventory via scene manager
                if self.sceneManager then
                    local inventoryKey = InputManager.getActionKey(InputActions.TOGGLE_INVENTORY)
                    self.sceneManager:toggleInventory(inventoryKey)
                end
                return
            end
        end

        if pointInRect(self.bottomBarWorldMapRect) then
            if self.sceneManager then
                local worldMapKey = InputManager.getActionKey(InputActions.TOGGLE_WORLD_MAP)
                self.sceneManager:toggleWorldMap(worldMapKey)
            end
            return
        end

        mouseInputSystem.queuePress(self)
    end
end

function WorldScene:mousereleased(_x, _y, button, _istouch, _presses)
    if button == 1 then
        mouseInputSystem.queueRelease(self)
    end
end

function WorldScene:triggerGameOver()
    if self.gameOverTriggered then
        return
    end

    self.gameOverTriggered = true

    local player = self:getPlayer()
    if player then
        if player.inactive then
            player.inactive.isInactive = true
        end

        if player.movement then
            player.movement.vx = 0
            player.movement.vy = 0
        end
    end

    if self.sceneManager then
        GameOverScene = GameOverScene or require("scenes.game_over")
        self.sceneManager:push(
            GameOverScene.new({
                sceneManager = self.sceneManager,
                world = self,
            })
        )
    end
end

return WorldScene
