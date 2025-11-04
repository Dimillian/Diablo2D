local function createSkillsComponent(opts)
    opts = opts or {}
    local equipped = {}
    local source = opts.equipped or {}

    for index = 1, 4 do
        equipped[index] = source[index]
    end

    return {
        equipped = equipped,
    }
end

return createSkillsComponent
