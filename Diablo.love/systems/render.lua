local renderSystem = {}

function renderSystem.draw(world)
    local renderables = world.components.renderable
    if not renderables then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    for entityId, renderable in pairs(renderables) do
        local entity = world.entities[entityId]
        if entity and entity.position then
            if renderable.kind == "rect" then
                love.graphics.setColor(renderable.color)
                love.graphics.rectangle(
                    "fill",
                    entity.position.x,
                    entity.position.y,
                    renderable.width,
                    renderable.height
                )
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderSystem
