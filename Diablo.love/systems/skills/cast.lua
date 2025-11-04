local Spells = require("data.spells")
local ProjectileEntity = require("entities.projectile")
local coordinates = require("systems.helpers.coordinates")
local vector = require("modules.vector")

local skillCastSystem = {}

local function ensureQueue(world)
    world.pendingSkillCastSlots = world.pendingSkillCastSlots or {}
    return world.pendingSkillCastSlots
end

local function getEntityCenter(entity)
    return coordinates.getEntityCenter(entity)
end

local function getTarget(world)
    local targetId = world.currentTargetId
    if not targetId then
        return nil
    end

    local target = world:getEntity(targetId)
    if not target or not target.health or target.health.current <= 0 or target.dead then
        return nil
    end

    return target
end

local function computeTargetPosition(world, projectileTarget, caster)
    if projectileTarget then
        local tx, ty = getEntityCenter(projectileTarget)
        if tx and ty then
            return tx, ty, projectileTarget.id
        end
    end

    -- Use player's look direction as fallback if no target entity
    if caster and caster.movement and caster.movement.lookDirection then
        local lookDir = caster.movement.lookDirection
        local casterX, casterY = getEntityCenter(caster)
        if casterX and casterY and lookDir.x and lookDir.y then
            -- Cast projectile forward in look direction at a reasonable range (500 pixels)
            local castRange = 500
            local targetX = casterX + (lookDir.x * castRange)
            local targetY = casterY + (lookDir.y * castRange)
            return targetX, targetY, nil
        end
    end

    -- Final fallback: use mouse position
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

    -- Ensure target position is valid
    if not targetX or not targetY then
        return false
    end

    -- Calculate projectile spawn position (centered on caster)
    local projectileSize = spell.projectileSize or 12
    local projectileX = casterX - (projectileSize / 2)
    local projectileY = casterY - (projectileSize / 2)

    -- Calculate initial direction vector from caster to target
    local dx = targetX - casterX
    local dy = targetY - casterY
    local ndx, ndy = vector.normalize(dx, dy)

    local projectile = ProjectileEntity.new({
        x = projectileX,
        y = projectileY,
        targetX = targetX,
        targetY = targetY,
        targetId = targetId,
        spellId = spell.id,
        damage = spell.damage,
        ownerId = caster.id,
        speed = spell.projectileSpeed,
        size = projectileSize,
        color = spell.projectileColor,
        lifetime = spell.lifetime,
        -- Set initial velocity direction immediately
        vx = ndx,
        vy = ndy,
    })

    world:addEntity(projectile)
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

    local mana = player.mana
    if not mana or (mana.current or 0) < (spell.manaCost or 0) then
        return false
    end

    local target = getTarget(world)
    local targetX, targetY, targetId = computeTargetPosition(world, target, player)
    if not targetX or not targetY then
        return false
    end

    local success = createProjectile(world, player, spell, targetX, targetY, targetId)
    if not success then
        return false
    end

    mana.current = math.max(0, (mana.current or 0) - (spell.manaCost or 0))
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
---@param key string
---@return boolean handled
function skillCastSystem.handleKeypress(world, key)
    if not world then
        return false
    end

    local slotIndex = tonumber(key)
    if not slotIndex or slotIndex < 1 or slotIndex > 4 then
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

    local mana = player.mana
    if not mana or (mana.current or 0) < (spell.manaCost or 0) then
        return false
    end

    local queue = ensureQueue(world)
    queue[#queue + 1] = slotIndex
    return true
end

return skillCastSystem
