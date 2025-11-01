local vector = {}

function vector.length(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

function vector.normalize(dx, dy)
    local len = vector.length(dx, dy)
    if len == 0 then
        return 0, 0, 0
    end
    return dx / len, dy / len, len
end

function vector.distance(x1, y1, x2, y2)
    return vector.length(x2 - x1, y2 - y1)
end

return vector
