local function createSkillsComponent()
    local equipped = {}

    for index = 1, 4 do
        equipped[index] = nil
    end

    return {
        equipped = equipped,
    }
end

return createSkillsComponent
