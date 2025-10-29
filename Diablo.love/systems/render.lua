local renderSystem = {}

function renderSystem.draw(world)
    local renderables = world.components.renderable
    if not renderables then
        return
    end

    for entityId, renderable in pairs(renderables) do
        local entity = world.entities[entityId]
        if entity then
            local position = entity.position
            if renderable.kind == "rect" then
                love.graphics.setColor(renderable.color)
                love.graphics.rectangle(
                    "fill",
                    position.x,
                    position.y,
                    renderable.width,
                    renderable.height
                )
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return renderSystem
