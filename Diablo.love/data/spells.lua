local Spells = {}

Spells.types = {
    fireball = {
        id = "fireball",
        label = "Fireball",
        description = "Launch a blazing fireball that scorches foes.",
        manaCost = 10,
        damage = { min = 15, max = 25 },
        projectileSpeed = 300,
        projectileSize = 12,
        projectileColor = { 1.0, 0.4, 0.1, 1 },
        projectileRenderKind = "fireball",
        projectileImpactDuration = 0.4,
        icon = "resources/skills/fireball.png",
        lifetime = 2.5,
    },
}

---Return an ordered array of spell definitions.
---@return table
function Spells.getAll()
    local list = {}
    for _, spell in pairs(Spells.types) do
        list[#list + 1] = spell
    end
    table.sort(list, function(a, b)
        return a.label < b.label
    end)
    return list
end

return Spells
