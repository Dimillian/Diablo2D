local mouseInputSystem = {}

local function ensurePrimary(scene)
    scene.input = scene.input or {}
    local input = scene.input

    input.mouse = input.mouse or {}
    local mouse = input.mouse

    mouse.primary = mouse.primary
        or {
            held = false,
            pressed = false,
            released = false,
            clickId = 0,
            consumedClickId = nil,
            _pressedFrame = false,
            _releasedFrame = false,
        }

    local primary = mouse.primary
    primary.clickId = primary.clickId or 0

    return primary
end

function mouseInputSystem.queuePress(scene)
    local primary = ensurePrimary(scene)

    primary._pressedFrame = true
    primary.held = true
    primary.clickId = (primary.clickId or 0) + 1
    primary.consumedClickId = nil
end

function mouseInputSystem.queueRelease(scene)
    local primary = ensurePrimary(scene)

    primary._releasedFrame = true
    primary.held = false
end

function mouseInputSystem.update(scene, _dt)
    local primary = ensurePrimary(scene)

    primary.pressed = primary._pressedFrame
    primary.released = primary._releasedFrame

    primary._pressedFrame = false
    primary._releasedFrame = false
end

return mouseInputSystem
