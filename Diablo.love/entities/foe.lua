local foeRarity = require("modules.world.foe_rarity")

local Foe = {}
Foe.__index = Foe

---Create a foe entity using config from foe_types.lua
---@param opts table Must include 'config' key with foe type config from foe_types.lua, plus 'x', 'y', 'width', 'height'
---@return Foe
function Foe.new(opts)
    local config = opts.config
    local typeId = opts.foeTypeId or (config and config.id)
    local rarityId = opts.rarity or opts.rarityId or "common"
    local scaled = foeRarity.apply(config, rarityId)

    local packAggro = scaled.packAggro
    if packAggro == nil and config then
        packAggro = config.packAggro
    end
    packAggro = packAggro or false

    local renderColor = config and config.color
    local rarity = foeRarity.get(rarityId)
    local outlineColor = nil
    if rarityId ~= "common" and rarity then
        outlineColor = rarity.tint
    end
    local detectionRange = scaled.detectionRange or (config and config.detectionRange)
    local leashExtension = scaled.leashExtension or (config and config.leashExtension)
    local health = scaled.health or (config and config.health)
    local damageMin = scaled.damageMin or (config and config.damageMin)
    local damageMax = scaled.damageMax or (config and config.damageMax)
    local sizeScale = scaled.scaleMultiplier or 1
    local width = (opts.width or 20) * sizeScale
    local height = (opts.height or 20) * sizeScale

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createWander = require("components.wander")
    local createHealth = require("components.health")
    local createDetection = require("components.detection")
    local createFoeTag = require("components.foe")
    local createCombat = require("components.combat")
    local createPhysicsBody = require("components.physics_body")
    local createInactive = require("components.inactive")

    local entity = {
        id = opts.id or ("foe_" .. math.random(10000, 99999)),
        name = opts.name or config.name,
        position = createPosition({
            x = opts.x,
            y = opts.y,
        }),
        size = createSize({
            w = width,
            h = height,
        }),
        movement = createMovement({
            speed = config.speed,
        }),
        renderable = createRenderable({
            kind = "rect",
            color = renderColor,
            outlineColor = outlineColor,
            spritePrefix = config.spritePrefix,
            animationState = "idle",
            scaleMultiplier = sizeScale,
        }),
        wander = createWander({
            interval = config.wanderInterval,
        }),
        detection = createDetection({
            range = detectionRange,
            leashExtension = leashExtension,
        }),
        foe = createFoeTag({
            type = opts.foeType or typeId,
            typeId = typeId,
            packId = opts.packId,
            packAggro = packAggro,
            rarity = scaled.rarityId,
            rarityLabel = scaled.rarityLabel,
        }),
        health = createHealth({
            max = health,
            current = health,
        }),
        combat = createCombat({
            range = config.range,
            attackSpeed = config.attackSpeed,
            baseDamageMin = damageMin,
            baseDamageMax = damageMax,
        }),
        foeTypeId = typeId,
        physicsBody = createPhysicsBody({
            bodyType = "dynamic",
            fixedRotation = true,
            linearDamping = (config and config.physicsLinearDamping) or 16,
            friction = 0,
        }),
        inactive = createInactive(),
    }

    return setmetatable(entity, Foe)
end

return Foe
