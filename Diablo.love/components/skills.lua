local function createSkillsComponent()
    local equipped = {}

    for index = 1, 4 do
        equipped[index] = nil
    end

    return {
        equipped = equipped,
        availablePoints = 0,
        allocations = {},
    }
end

return createSkillsComponent
