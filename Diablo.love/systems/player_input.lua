local vector = require("modules.vector")

local playerInputSystem = {}

function playerInputSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.movement or not player.position then
        return
    end

    local movement = player.movement
    if not movement.heading then
        return
    end

    if not movement.intentStrafe then
        movement.intentStrafe = { x = 0, y = 0 }
    end

    local heading = movement.heading
    local rightX = -heading.y
    local rightY = heading.x

    local isForward = love.keyboard.isDown("up", "w")
    local isBackward = love.keyboard.isDown("down", "s")
    local isLeft = love.keyboard.isDown("left", "a")
    local isRight = love.keyboard.isDown("right", "d")

    movement.intentForward = isForward

    local strafeX, strafeY = 0, 0
    if isLeft then
        strafeX = strafeX - rightX
        strafeY = strafeY - rightY
    end
    if isRight then
        strafeX = strafeX + rightX
        strafeY = strafeY + rightY
    end
    if isBackward then
        strafeX = strafeX - heading.x
        strafeY = strafeY - heading.y
    end

    local strafeMagnitude = vector.length(strafeX, strafeY)
    if strafeMagnitude > 0 then
        strafeX = strafeX / strafeMagnitude
        strafeY = strafeY / strafeMagnitude
    else
        strafeX, strafeY = 0, 0
    end

    movement.intentStrafe.x = strafeX
    movement.intentStrafe.y = strafeY

    if isForward then
        local mouseX, mouseY = love.mouse.getPosition()
        local coordinatesHelper = world.systemHelpers and world.systemHelpers.coordinates
        if coordinatesHelper and coordinatesHelper.toWorldFromScreen then
            mouseX, mouseY = coordinatesHelper.toWorldFromScreen(world.camera, mouseX, mouseY)
        end

        local position = player.position
        local size = player.size
        local playerCenterX = position.x
        local playerCenterY = position.y

        if size then
            playerCenterX = playerCenterX + (size.w / 2)
            playerCenterY = playerCenterY + (size.h / 2)
        end

        local dx = mouseX - playerCenterX
        local dy = mouseY - playerCenterY
        local ndx, ndy = vector.normalize(dx, dy)

        if ndx ~= 0 or ndy ~= 0 then
            movement.targetHeading.x = ndx
            movement.targetHeading.y = ndy
        end
    end

    local targetHeading = movement.targetHeading or heading
    local lerpAmount = movement.headingLerp or 0.2
    local interpolatedX = heading.x + (targetHeading.x - heading.x) * lerpAmount
    local interpolatedY = heading.y + (targetHeading.y - heading.y) * lerpAmount
    local normalizedX, normalizedY, normalizedLength = vector.normalize(interpolatedX, interpolatedY)

    if normalizedLength > 0 then
        heading.x = normalizedX
        heading.y = normalizedY
    end
end

return playerInputSystem
