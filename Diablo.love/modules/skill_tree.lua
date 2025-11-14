local SkillTree = {}

local function getTree(spell)
    if not spell then
        return nil
    end
    return spell.skillTree
end

function SkillTree.getNodeDefinition(spell, nodeId)
    local tree = getTree(spell)
    if not tree or not tree.nodes then
        return nil
    end
    return tree.nodes[nodeId]
end

function SkillTree.getAllocation(skills, spellId)
    if not skills or not skills.allocations then
        return nil
    end
    return skills.allocations[spellId]
end

function SkillTree.ensureAllocation(skills, spellId)
    if not skills or not spellId then
        return nil
    end

    skills.allocations = skills.allocations or {}
    local allocation = skills.allocations[spellId]
    if not allocation then
        allocation = {
            nodes = {},
            total = 0,
        }
        skills.allocations[spellId] = allocation
    end
    return allocation
end

function SkillTree.getNodePoints(skills, spellId, nodeId)
    local allocation = SkillTree.getAllocation(skills, spellId)
    if not allocation or not allocation.nodes then
        return 0
    end
    return allocation.nodes[nodeId] or 0
end

local function requirementsMetInternal(skills, spell, node)
    local requirements = node.requirements
    if not requirements or #requirements == 0 then
        return true
    end

    for _, requirement in ipairs(requirements) do
        local requiredPoints = requirement.points or 0
        if requiredPoints > 0 then
            local current = SkillTree.getNodePoints(skills, spell.id, requirement.nodeId)
            if current < requiredPoints then
                return false
            end
        end
    end

    return true
end

function SkillTree.requirementsMet(skills, spell, nodeId)
    if not spell or not nodeId then
        return false
    end

    local node = SkillTree.getNodeDefinition(spell, nodeId)
    if not node then
        return false
    end

    return requirementsMetInternal(skills, spell, node)
end

function SkillTree.canInvest(skills, spell, nodeId)
    if not skills or not spell or not nodeId then
        return false, "invalid"
    end

    local node = SkillTree.getNodeDefinition(spell, nodeId)
    if not node then
        return false, "missing"
    end

    local availablePoints = skills.availablePoints or 0
    if availablePoints <= 0 then
        return false, "no_points"
    end

    if not requirementsMetInternal(skills, spell, node) then
        return false, "locked"
    end

    local currentPoints = SkillTree.getNodePoints(skills, spell.id, nodeId)
    local maxPoints = node.maxPoints or math.huge
    if currentPoints >= maxPoints then
        return false, "maxed"
    end

    return true, nil
end

function SkillTree.invest(skills, spell, nodeId)
    local canInvest, reason = SkillTree.canInvest(skills, spell, nodeId)
    if not canInvest then
        return false, reason
    end

    local allocation = SkillTree.ensureAllocation(skills, spell.id)
    allocation.nodes[nodeId] = (allocation.nodes[nodeId] or 0) + 1
    allocation.total = (allocation.total or 0) + 1
    skills.availablePoints = math.max(0, (skills.availablePoints or 0) - 1)

    return true
end

function SkillTree.getTotalPoints(skills, spellId)
    local allocation = SkillTree.getAllocation(skills, spellId)
    if not allocation then
        return 0
    end
    return allocation.total or 0
end

function SkillTree.computeModifiers(skills, spell)
    local modifiers = {
        damageFlat = 0,
        projectileSize = 0,
        projectileSpeed = 0,
    }

    if not skills or not spell or not spell.skillTree then
        return modifiers
    end

    local allocation = SkillTree.getAllocation(skills, spell.id)
    if not allocation or not allocation.nodes then
        return modifiers
    end

    for nodeId, points in pairs(allocation.nodes) do
        local node = SkillTree.getNodeDefinition(spell, nodeId)
        if node and node.effects and points > 0 then
            for _, effect in ipairs(node.effects) do
                local perPoint = effect.perPoint or 0
                if effect.type == "damage_flat" then
                    modifiers.damageFlat = modifiers.damageFlat + perPoint * points
                elseif effect.type == "projectile_size" then
                    modifiers.projectileSize = modifiers.projectileSize + perPoint * points
                elseif effect.type == "projectile_speed" then
                    modifiers.projectileSpeed = modifiers.projectileSpeed + perPoint * points
                end
            end
        end
    end

    return modifiers
end

function SkillTree.buildModifiedSpell(skills, spell)
    if not spell then
        return nil
    end

    local modifiers = SkillTree.computeModifiers(skills, spell)
    local modified = {}

    for key, value in pairs(spell) do
        if key == "damage" and type(value) == "table" then
            local minDamage = (value.min or 0) + modifiers.damageFlat
            local maxDamage = (value.max or value.min or 0) + modifiers.damageFlat
            if maxDamage < minDamage then
                maxDamage = minDamage
            end
            modified.damage = {
                min = minDamage,
                max = maxDamage,
            }
        else
            modified[key] = value
        end
    end

    if not modified.damage then
        modified.damage = { min = modifiers.damageFlat, max = modifiers.damageFlat }
    end

    if spell.projectileSize then
        modified.projectileSize = (spell.projectileSize or 0) + modifiers.projectileSize
    end

    if spell.projectileSpeed then
        modified.projectileSpeed = (spell.projectileSpeed or 0) + modifiers.projectileSpeed
    end

    modified.modifiers = modifiers
    return modified
end

return SkillTree
