local Foe = {}
Foe.__index = Foe

---Create a foe entity using config from foe_types.lua
---@param opts table Must include 'config' key with foe type config from foe_types.lua, plus 'x', 'y', 'width', 'height'
---@return Foe
function Foe.new(opts)
    local config = opts.config
    local typeId = opts.foeTypeId or (config and config.id)

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createWander = require("components.wander")
    local createHealth = require("components.health")
    local createDetection = require("components.detection")
    local createFoeTag = require("components.foe")
    local createCombat = require("components.combat")

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
        }),
        wander = createWander({
            interval = config.wanderInterval,
        }),
        detection = createDetection({
            range = config.detectionRange,
        }),
        foe = createFoeTag({
            typeId = typeId,
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
    }

    return setmetatable(entity, Foe)
end

return Foe
