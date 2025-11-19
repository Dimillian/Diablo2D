local Spells = require("data.spells")
local SkillTree = require("modules.skill_tree")
local ProjectileEntity = require("entities.projectile")
local coordinates = require("systems.helpers.coordinates")
local vector = require("modules.vector")
local Targeting = require("systems.helpers.targeting")
local soundHelper = require("systems.helpers.sound")

local skillCastSystem = {}

local function ensureQueue(world)
    world.pendingSkillCastSlots = world.pendingSkillCastSlots or {}
    return world.pendingSkillCastSlots
end

local function getEntityCenter(entity)
    return coordinates.getEntityCenter(entity)
end

local function getTarget(world)
    return Targeting.getCurrentTarget(world)
end

local function computeTargetPosition(world, projectileTarget, caster, spell)
    if spell and spell.targeting == "cursor" then
        local mx, my = love.mouse.getPosition()
        local camera = world.camera or { x = 0, y = 0 }
        local targetX, targetY = coordinates.toWorldFromScreen(camera, mx, my)
        return targetX, targetY, nil
    end

    if projectileTarget then
        local tx, ty = getEntityCenter(projectileTarget)
        if tx and ty then
            return tx, ty, projectileTarget.id
        end
    end

    if caster and caster.movement and caster.movement.lookDirection then
        local lookDir = caster.movement.lookDirection
        local casterX, casterY = getEntityCenter(caster)
        if casterX and casterY and lookDir.x and lookDir.y then
            local castRange = 500
            local targetX = casterX + (lookDir.x * castRange)
            local targetY = casterY + (lookDir.y * castRange)
            return targetX, targetY, nil
        end
    end
    local mx, my = love.mouse.getPosition()
    local camera = world.camera or { x = 0, y = 0 }
    local targetX, targetY = coordinates.toWorldFromScreen(camera, mx, my)
    return targetX, targetY, nil
end

local function createProjectile(world, caster, spell, targetX, targetY, targetId)
    local casterX, casterY = getEntityCenter(caster)
    if not casterX or not casterY then
        return false
    end

    if not targetX or not targetY then
        return false
    end

    local projectileSize = spell.projectileSize or 12
    local spawnMode = spell.projectileSpawn or "caster"
    local spawnHeight = spell.projectileSpawnHeight or 0

    local spawnX, spawnY
    if spawnMode == "target" then
        spawnX = targetX
        spawnY = targetY
    elseif spawnMode == "sky" then
        spawnX = targetX
        spawnY = targetY - spawnHeight
    else
        spawnX = casterX
        spawnY = casterY
    end

    if not spawnX or not spawnY then
        spawnX = casterX
        spawnY = casterY
    end

    local projectileX = spawnX - (projectileSize / 2)
    local projectileY = spawnY - (projectileSize / 2)

    local startCenterX = projectileX + (projectileSize / 2)
    local startCenterY = projectileY + (projectileSize / 2)

    local dx = targetX - startCenterX
    local dy = targetY - startCenterY
    local ndx, ndy = vector.normalize(dx, dy)
    if ndx == 0 and ndy == 0 then
        ndx, ndy = 0, 1
    end

    local projectile = ProjectileEntity.new({
        x = projectileX,
        y = projectileY,
        targetX = targetX,
        targetY = targetY,
        targetId = (spell.targeting == "cursor") and nil or targetId,
        spellId = spell.id,
        damage = spell.damage,
        ownerId = caster.id,
        speed = spell.projectileSpeed,
        size = projectileSize,
        color = spell.projectileColor,
        secondaryColor = spell.projectileSecondaryColor,
        coreColor = spell.projectileCoreColor,
        lifetime = spell.lifetime,
        vx = ndx,
        vy = ndy,
        renderKind = spell.projectileRenderKind,
        impactDuration = spell.projectileImpactDuration,
    })

    world:addEntity(projectile)

    -- Play travel sound for fireball
    if spell.id == "fireball" then
        local travelSound = soundHelper.playFireballTravelSound()
        -- Store sound source on projectile so we can stop it on impact
        projectile.travelSoundSource = travelSound
    end

    -- Play travel sound for thunder
    if spell.id == "thunder" then
        local travelSound = soundHelper.playThunderTravelSound()
        -- Store sound source on projectile so we can stop it on impact
        projectile.travelSoundSource = travelSound
    end

    return true
end

local function castSpell(world, slotIndex)
    local player = world:getPlayer()
    if not player or not player.skills then
        return false
    end

    local spellId = player.skills.equipped[slotIndex]
    if not spellId then
        return false
    end

    local spell = Spells.types[spellId]
    if not spell then
        return false
    end

    local modifiedSpell = SkillTree.buildModifiedSpell(player.skills, spell) or spell

    local mana = player.mana
    local manaCost = modifiedSpell.manaCost or spell.manaCost or 0
    if not mana or (mana.current or 0) < manaCost then
        return false
    end

    local target = getTarget(world)
    local targetX, targetY, targetId = computeTargetPosition(world, target, player, modifiedSpell)
    if not targetX or not targetY then
        return false
    end

    local success = createProjectile(world, player, modifiedSpell, targetX, targetY, targetId)
    if not success then
        return false
    end

    mana.current = math.max(0, (mana.current or 0) - manaCost)
    return true
end

function skillCastSystem.update(world, _dt)
    local queue = world.pendingSkillCastSlots
    if not queue or #queue == 0 then
        return
    end

    for _, slotIndex in ipairs(queue) do
        castSpell(world, slotIndex)
    end

    world.pendingSkillCastSlots = {}
end

---Handle key press for skill hotkeys.
---@param world table
---@param action string Action name constant from InputActions
---@return boolean handled
function skillCastSystem.handleKeypress(world, action)
    if not world then
        return false
    end

    local InputActions = require("modules.input_actions")

    local slotIndex
    if action == InputActions.SKILL_1 then
        slotIndex = 1
    elseif action == InputActions.SKILL_2 then
        slotIndex = 2
    elseif action == InputActions.SKILL_3 then
        slotIndex = 3
    elseif action == InputActions.SKILL_4 then
        slotIndex = 4
    else
        return false
    end

    local player = world:getPlayer()
    if not player or not player.skills then
        return false
    end

    local spellId = player.skills.equipped[slotIndex]
    if not spellId then
        return false
    end

    local spell = Spells.types[spellId]
    if not spell then
        return false
    end

    local modifiedSpell = SkillTree.buildModifiedSpell(player.skills, spell) or spell

    local mana = player.mana
    local manaCost = modifiedSpell.manaCost or spell.manaCost or 0
    if not mana or (mana.current or 0) < manaCost then
        return false
    end

    local queue = ensureQueue(world)
    queue[#queue + 1] = slotIndex
    return true
end

return skillCastSystem
