local Targeting = require("systems.helpers.targeting")

local mouseTargetingSystem = {}

---Update mouse hover targeting - sets target when hovering over foes
---@param world table
---@param _dt number
function mouseTargetingSystem.update(world, _dt)
    -- Only update hover targeting if not actively attacking
    -- This prevents conflicts with attack-based targeting
    local input = world.input and world.input.mouse and world.input.mouse.primary
    local isAttacking = input and (input.held or input.pressed)

    -- If attacking, let playerAttackSystem handle targeting
    if isAttacking then
        return
    end

    -- Use a smaller hover range for more precise targeting
    -- Don't check player range - allow targeting any foe under cursor
    local hoverRange = 60 -- Hover range in pixels (smaller for less sensitivity)

    -- Check for foes under mouse cursor and set target
    -- Use clearOnNoTarget to immediately clear target when mouse moves away
    Targeting.resolveMouseTarget(world, {
        range = hoverRange,
        checkPlayerRange = false, -- Allow targeting foes even if out of attack range
        clearOnNoTarget = true, -- Clear target immediately when not hovering over a foe
    })
end

return mouseTargetingSystem
