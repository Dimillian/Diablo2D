local spriteDirection = {}

function spriteDirection.getSpriteRow(lookDirection)
    if not lookDirection then
        return 0
    end

    local x = lookDirection.x or 0
    local y = lookDirection.y or 0

    local absX = math.abs(x)
    local absY = math.abs(y)

    if y > 0 and absY >= absX then
        return 0
    end

    if y < 0 and absY >= absX then
        return 1
    end

    if x < 0 and absX > absY then
        return 2
    end

    return 3
end

return spriteDirection
