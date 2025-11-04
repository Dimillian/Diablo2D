local Targeting = require("systems.helpers.targeting")

local mouseTargetingSystem = {}

function mouseTargetingSystem.update(world, _dt)
    local input = world.input and world.input.mouse and world.input.mouse.primary
    local isAttacking = input and (input.held or input.pressed)

    if isAttacking then
        return
    end

    local hoverRange = 60

    Targeting.resolveMouseTarget(world, {
        range = hoverRange,
        checkPlayerRange = false,
        clearOnNoTarget = true,
    })
end

return mouseTargetingSystem
