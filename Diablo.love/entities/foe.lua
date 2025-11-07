local Foe = {}
Foe.__index = Foe

---Create a foe entity using config from foe_types.lua
---@param opts table Must include 'config' key with foe type config from foe_types.lua, plus 'x', 'y', 'width', 'height'
---@return Foe
function Foe.new(opts)
    local config = opts.config
    local typeId = opts.foeTypeId or (config and config.id)
    local packAggro = opts.packAggro
    if packAggro == nil and config then
        packAggro = config.packAggro
    end

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

    local entity = {
        id = opts.id or ("foe_" .. math.random(10000, 99999)),
        name = config.name,
        position = createPosition({
            x = opts.x,
            y = opts.y,
        }),
        size = createSize({
            w = opts.width,
            h = opts.height,
        }),
        movement = createMovement({
            speed = config.speed,
        }),
        renderable = createRenderable({
            kind = "rect",
            color = config.color,
            spritePrefix = config.spritePrefix,
            animationState = "idle",
        }),
        wander = createWander({
            interval = config.wanderInterval,
        }),
        detection = createDetection({
            range = config.detectionRange,
            leashExtension = config.leashExtension,
        }),
        foe = createFoeTag({
            type = opts.foeType or typeId,
            typeId = typeId,
            packId = opts.packId,
            packAggro = packAggro,
        }),
        health = createHealth({
            max = config.health,
            current = config.health,
        }),
        combat = createCombat({
            range = config.range,
            attackSpeed = config.attackSpeed,
            baseDamageMin = config.damageMin,
            baseDamageMax = config.damageMax,
        }),
        foeTypeId = typeId,
        physicsBody = createPhysicsBody({
            bodyType = "dynamic",
            fixedRotation = true,
            linearDamping = (config and config.physicsLinearDamping) or 16,
            friction = 0,
        }),
    }

    return setmetatable(entity, Foe)
end

return Foe
