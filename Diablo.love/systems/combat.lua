local EquipmentHelper = require("system_helpers.equipment")
local vector = require("modules.vector")
local ItemGenerator = require("items.generator")
local createDeadComponent = require("components.dead")
local createRecentlyDamagedComponent = require("components.recently_damaged")
local createFloatingDamageComponent = require("components.floating_damage")
local createPosition = require("components.position")
local createSize = require("components.size")
local createLootableComponent = require("components.lootable")

local combatSystem = {}

function combatSystem.update(scene, _dt)
    -- Initialize pending events queue if not exists
    if not scene.pendingCombatEvents then
        scene.pendingCombatEvents = {}
    end

    local combatants = scene:queryEntities({ "combat" })

    for _, combatant in ipairs(combatants) do
        local combat = combatant.combat

        if combat.queuedAttack then
            local target = scene:getEntity(combat.queuedAttack.targetId)

            -- Validate target
            if target and target.health and target.health.current > 0 then
                -- Check if target is within range
                local combatantCenterX = combatant.position.x + (combatant.size and combatant.size.w / 2 or 0)
                local combatantCenterY = combatant.position.y + (combatant.size and combatant.size.h / 2 or 0)
                local targetCenterX = target.position.x + (target.size and target.size.w / 2 or 0)
                local targetCenterY = target.position.y + (target.size and target.size.h / 2 or 0)

                local dist = vector.distance(combatantCenterX, combatantCenterY, targetCenterX, targetCenterY)

                if dist <= combat.range then
                    -- Compute damage
                    local totalStats = EquipmentHelper.computeTotalStats(combatant)
                    local damageMin = totalStats.damageMin or 0
                    local damageMax = totalStats.damageMax or 0

                    if damageMin > 0 or damageMax > 0 then
                        local damage = math.random(damageMin, damageMax)

                        -- Check for critical hit
                        local critChance = totalStats.critChance or 0
                        local isCrit = math.random() < critChance
                        if isCrit then
                            damage = math.floor(damage * 1.5)
                        end

                        -- Apply damage
                        target.health.current = math.max(0, target.health.current - damage)

                        -- Push damage event
                        table.insert(scene.pendingCombatEvents, {
                            type = "damage",
                            targetId = target.id,
                            damage = damage,
                            isCritical = isCrit,
                            position = {
                                x = targetCenterX,
                                y = targetCenterY,
                            },
                        })

                        -- Add recently damaged component or reset timer
                        if not target.recentlyDamaged then
                            scene:addComponent(
                                target.id,
                                "recentlyDamaged",
                                createRecentlyDamagedComponent({ timer = 2.0 })
                            )
                        else
                            target.recentlyDamaged.timer = 2.0
                        end

                        -- Check for death
                        if target.health.current <= 0 then
                            -- Push death event
                            table.insert(scene.pendingCombatEvents, {
                                type = "death",
                                entityId = target.id,
                                position = {
                                    x = targetCenterX,
                                    y = targetCenterY,
                                },
                            })

                            -- Mark as dead
                            scene:addComponent(target.id, "dead", createDeadComponent())

                            -- Remove AI components
                            scene:removeComponent(target.id, "chase")
                            scene:removeComponent(target.id, "detection")
                            scene:removeComponent(target.id, "wander")

                            -- Clear target if dead entity was current target
                            if scene.currentTargetId == target.id then
                                scene.currentTargetId = nil
                            end
                        end
                    end
                end
            end

            -- Clear queued attack
            combat.queuedAttack = nil
        end
    end

    -- Process combat events (spawn damage numbers, loot, etc.)
    for _, event in ipairs(scene.pendingCombatEvents) do
        if event.type == "damage" then
            -- Spawn floating damage number
            local damageEntity = {
                id = "damage_" .. math.random(10000, 99999),
                position = createPosition({
                    x = event.position.x,
                    y = event.position.y,
                }),
                floatingDamage = createFloatingDamageComponent({
                    damage = event.damage,
                    velocity = {
                        x = math.random(-20, 20),
                        y = -60,
                    },
                    timer = 1.5,
                    color = event.isCritical and { 1, 1, 0, 1 } or { 1, 0, 0, 1 },
                    isCritical = event.isCritical,
                }),
            }
            scene:addEntity(damageEntity)
        elseif event.type == "death" then
            -- Spawn loot
            local lootItem = ItemGenerator.roll()

            if lootItem then
                local lootEntity = {
                    id = "loot_" .. math.random(10000, 99999),
                    position = createPosition({
                        x = event.position.x + math.random(-10, 10),
                        y = event.position.y + math.random(-10, 10),
                    }),
                    size = createSize({
                        w = 24,
                        h = 24,
                    }),
                    lootable = createLootableComponent({
                        item = lootItem,
                        pickupRadius = 40,
                        source = "drop",
                    }),
                }
                scene:addEntity(lootEntity)
            end

            -- Remove dead entity after a short delay (allow loot to spawn first)
            -- We'll handle this in a cleanup pass or let systems skip dead entities
            -- For now, dead entities are marked and systems skip them
        end
    end

    -- Clear events queue after processing
    scene.pendingCombatEvents = {}
end

return combatSystem
