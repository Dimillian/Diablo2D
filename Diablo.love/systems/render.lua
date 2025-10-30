local renderSystem = {}

function renderSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "renderable", "position", "size" })

    for _, entity in ipairs(entities) do
        local renderable = entity.renderable
        if renderable.kind == "rect" then
            love.graphics.setColor(renderable.color)
            love.graphics.rectangle(
                "fill",
                entity.position.x,
                entity.position.y,
                entity.size.w,
                entity.size.h
            )
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderSystem
