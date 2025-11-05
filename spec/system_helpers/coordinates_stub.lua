local coordinates = {}

function coordinates.getEntityCenter(entity)
    if not entity or not entity.position then
        return nil, nil
    end

    local w = entity.size and entity.size.w or 0
    local h = entity.size and entity.size.h or 0

    return entity.position.x + (w / 2), entity.position.y + (h / 2)
end

return coordinates
