local Spells = require("data.spells")
local ProjectileEntity = require("entities.projectile")
local coordinates = require("systems.helpers.coordinates")

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

local function computeTargetPosition(world, projectileTarget)
    if projectileTarget then
        local tx, ty = getEntityCenter(projectileTarget)
        if tx and ty then
            return tx, ty, projectileTarget.id
        end
    end

    local mx, my = love.mouse.getPosition()
    local camera = world.camera or { x = 0, y = 0 }
    local targetX, targetY = coordinates.toWorldFromScreen(camera, mx, my)
    return targetX, targetY, nil
end

local function createProjectile(world, caster, spell, targetX, targetY, targetId)
    local casterX, casterY = getEntityCenter(caster)
    if not casterX then
        return false
    end

    local projectile = ProjectileEntity.new({
        x = casterX - (spell.projectileSize or 12) / 2,
        y = casterY - (spell.projectileSize or 12) / 2,
        targetX = targetX,
        targetY = targetY,
        targetId = targetId,
        spellId = spell.id,
        damage = spell.damage,
        ownerId = caster.id,
        speed = spell.projectileSpeed,
        size = spell.projectileSize,
        color = spell.projectileColor,
        lifetime = spell.lifetime,
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
    local targetX, targetY, targetId = computeTargetPosition(world, target)
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
