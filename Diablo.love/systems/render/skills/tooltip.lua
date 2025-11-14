local Spells = require("data.spells")
local SkillTree = require("modules.skill_tree")

local renderSkillsTooltip = {}

local function appendLine(lines, text)
    lines[#lines + 1] = text
end

local function appendBlankLine(lines)
    if #lines == 0 then
        return
    end
    if lines[#lines] == "" then
        return
    end
    lines[#lines + 1] = ""
end

local function findSpell(scene)
    local spellId = scene.hoveredSpellId
    if spellId then
        return Spells.types[spellId]
    end

    local slotIndex = scene.hoveredSlotIndex
    if slotIndex and scene.world then
        local player = scene.world:getPlayer()
        if player and player.skills then
            local equippedId = player.skills.equipped[slotIndex]
            if equippedId then
                return Spells.types[equippedId]
            end
        end
    end
end

local function formatNodeEffectLine(effect, points)
    local perPoint = effect.perPoint or 0
    local total = perPoint * points

    if effect.type == "damage_flat" then
        local base = string.format("+%d damage per point", perPoint)
        if points > 0 and perPoint ~= 0 then
            return string.format("%s (%+d total)", base, total)
        end
        return base
    elseif effect.type == "projectile_size" then
        local base = string.format("+%d projectile size per point", perPoint)
        if points > 0 and perPoint ~= 0 then
            return string.format("%s (+%d total)", base, total)
        end
        return base
    elseif effect.type == "projectile_speed" then
        local base = string.format("+%d projectile speed per point", perPoint)
        if points > 0 and perPoint ~= 0 then
            return string.format("%s (+%d total)", base, total)
        end
        return base
    end
end

local function buildNodeTooltipLines(scene)
    local hovered = scene.hoveredSkillNode
    if not hovered then
        return nil
    end

    local spell = hovered.spellId and Spells.types[hovered.spellId]
    if not spell then
        return nil
    end

    local node = SkillTree.getNodeDefinition(spell, hovered.nodeId)
    if not node then
        return nil
    end

    local player = scene.world and scene.world:getPlayer()
    local skills = player and player.skills

    local lines = {}
    appendLine(lines, node.label or node.id)
    if node.description then
        appendLine(lines, node.description)
    end

    local points = skills and SkillTree.getNodePoints(skills, spell.id, node.id) or 0
    local maxPoints = node.maxPoints or math.huge
    if maxPoints == math.huge then
        appendLine(lines, string.format("Points: %d", points))
    else
        appendLine(lines, string.format("Points: %d / %d", points, maxPoints))
    end

    if node.effects then
        for _, effect in ipairs(node.effects) do
            local effectLine = formatNodeEffectLine(effect, points)
            if effectLine then
                appendLine(lines, effectLine)
            end
        end
    end

    if skills then
        local requirements = node.requirements
        if requirements and #requirements > 0 then
            appendBlankLine(lines)
            appendLine(lines, "Requires:")
            for _, requirement in ipairs(requirements) do
                local requiredNode = SkillTree.getNodeDefinition(spell, requirement.nodeId)
                local requirementLabel = requiredNode and requiredNode.label or requirement.nodeId
                local currentPoints = SkillTree.getNodePoints(skills, spell.id, requirement.nodeId)
                appendLine(
                    lines,
                    string.format(" - %s (%d / %d)", requirementLabel, currentPoints, requirement.points or 0)
                )
            end
        end

        local canInvest, reason = SkillTree.canInvest(skills, spell, node.id)
        appendBlankLine(lines)
        if canInvest then
            appendLine(lines, "Left click to invest")
        elseif reason == "no_points" then
            appendLine(lines, "No available skill points")
        elseif reason == "maxed" then
            appendLine(lines, "Node is at maximum rank")
        elseif reason == "locked" then
            appendLine(lines, "Spend more points in previous nodes")
        end
    end

    return lines
end

local function buildSpellTooltipLines(scene, spell)
    local lines = {}
    appendLine(lines, spell.label or spell.id)
    if spell.description then
        appendLine(lines, spell.description)
    end

    local player = scene.world and scene.world:getPlayer()
    local skills = player and player.skills
    local modifiedSpell = SkillTree.buildModifiedSpell(skills, spell) or spell
    local modifiers = modifiedSpell.modifiers or { damageFlat = 0, projectileSize = 0, projectileSpeed = 0 }

    if modifiedSpell.damage then
        local minDamage = modifiedSpell.damage.min or 0
        local maxDamage = modifiedSpell.damage.max or modifiedSpell.damage.min or 0
        appendLine(lines, string.format("Damage: %d - %d", minDamage, maxDamage))

        local baseDamage = spell.damage
        if baseDamage and modifiers.damageFlat and modifiers.damageFlat ~= 0 then
            appendLine(lines, string.format("  (+%d from skill tree)", modifiers.damageFlat))
        end
    end

    appendLine(lines, string.format("Mana Cost: %d", spell.manaCost or 0))

    if spell.projectileSpeed then
        if modifiers.projectileSpeed and modifiers.projectileSpeed ~= 0 then
            appendLine(
                lines,
                string.format(
                    "Projectile Speed: %d (+%d)",
                    (modifiedSpell.projectileSpeed or spell.projectileSpeed),
                    modifiers.projectileSpeed
                )
            )
        else
            appendLine(lines, string.format("Projectile Speed: %d", spell.projectileSpeed))
        end
    end

    if spell.projectileSize then
        if modifiers.projectileSize and modifiers.projectileSize ~= 0 then
            appendLine(
                lines,
                string.format(
                    "Projectile Size: %d (+%d)",
                    (modifiedSpell.projectileSize or spell.projectileSize),
                    modifiers.projectileSize
                )
            )
        else
            appendLine(lines, string.format("Projectile Size: %d", spell.projectileSize))
        end
    end

    return lines
end

function renderSkillsTooltip.draw(scene)
    local lines = buildNodeTooltipLines(scene)
    if not lines then
        local spell = findSpell(scene)
        if not spell then
            return
        end
        lines = buildSpellTooltipLines(scene, spell)
    end

    local font = love.graphics.getFont()
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, font:getWidth(line))
    end

    local padding = 10
    local height = #lines * (font:getHeight() + 2) + padding
    local width = maxWidth + padding * 2

    local mouseX, mouseY = love.mouse.getPosition()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local x = mouseX + 20
    local y = mouseY + 20

    if x + width > screenWidth then
        x = screenWidth - width - 12
    end
    if y + height > screenHeight then
        y = screenHeight - height - 12
    end

    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 6, 6)

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local cursorY = y + padding / 2
    for _, line in ipairs(lines) do
        love.graphics.print(line, x + padding, cursorY)
        cursorY = cursorY + font:getHeight() + 2
    end

    love.graphics.pop()
end

return renderSkillsTooltip
