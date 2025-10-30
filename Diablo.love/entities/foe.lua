local Foe = {}
Foe.__index = Foe

---Create a foe entity with position and size defaults.
---@param opts table|nil
---@return Foe
function Foe.new(opts)
    opts = opts or {}

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createWander = require("components.wander")
    local createHealth = require("components.health")
    local createDetection = require("components.detection")

    local entity = {
        id = opts.id or ("foe_" .. math.random(10000, 99999)),
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = opts.width or 20,
            h = opts.height or 20,
        }),
        movement = createMovement({
            speed = opts.speed or 80,
        }),
        renderable = createRenderable(opts.renderable or {
            kind = "rect",
            color = { 1, 0, 0, 1 },
        }),
        wander = createWander({
            interval = opts.wanderInterval or 0.01,
        }),
        detection = createDetection({
            range = opts.detectionRange or 150,
        }),
    }

    -- Optional health component
    if opts.health then
        entity.health = createHealth(opts.health)
    end

    return setmetatable(entity, Foe)
end

return Foe
