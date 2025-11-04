local Spells = require("data.spells")
local coordinates = require("systems.helpers.coordinates")

local renderProjectileSystem = {}

function renderProjectileSystem.draw(world)
    local projectiles = world:queryEntities({ "projectile", "position", "size", "renderable" })
    if #projectiles == 0 then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    for _, projectile in ipairs(projectiles) do
        if projectile.inactive then
            goto continue
        end

        local renderable = projectile.renderable
        local projectileComponent = projectile.projectile
        local spell = projectileComponent and projectileComponent.spellId and Spells.types[projectileComponent.spellId]

        local color = renderable.color
        if spell and spell.projectileColor then
            color = spell.projectileColor
        end

        local radius = (projectile.size.w or projectile.size.h or 0) / 2
        local centerX, centerY = coordinates.getEntityCenter(projectile)

        love.graphics.setColor(color or { 1, 1, 1, 1 })
        if renderable.kind == "image" and renderable.sprite then
            love.graphics.draw(renderable.sprite, projectile.position.x, projectile.position.y)
        else
            love.graphics.circle("fill", centerX, centerY, radius)
        end

        ::continue::
    end

    love.graphics.pop()
end

return renderProjectileSystem
