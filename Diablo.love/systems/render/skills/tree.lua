local Spells = require("data.spells")
local SkillTree = require("modules.skill_tree")
local WindowLayout = require("systems.helpers.window_layout")

local renderSkillsTree = {}
local MIN_NODE_VERTICAL_SPACING = 36

local function clamp01(value)
    if value < 0 then
        return 0
    end
    if value > 1 then
        return 1
    end
    return value
end

local function getNodePosition(area, node)
    local position = node.position or {}
    local innerPadding = math.min(28, math.min(area.width, area.height) * 0.1)
    local innerWidth = math.max(0, area.width - innerPadding * 2)
    local innerHeight = math.max(0, area.height - innerPadding * 2)

    local px = clamp01(position.x or 0.5)
    local py = clamp01(position.y or 0.5)

    local x = area.x + innerPadding + innerWidth * px
    local y = area.y + innerPadding + innerHeight * py
    return x, y, innerPadding
end

local function calculateNodePositions(area, nodeList)
    local nodePositions = {}
    local bucketLastY = {}

    for _, node in ipairs(nodeList) do
        local nodeX, nodeY, innerPadding = getNodePosition(area, node)

        local px = clamp01((node.position and node.position.x) or 0.5)
        local bucket = math.floor(px * 10 + 0.5)
        local lastY = bucketLastY[bucket]
        if lastY and nodeY - lastY < MIN_NODE_VERTICAL_SPACING then
            local bottom = area.y + area.height - innerPadding
            nodeY = math.min(bottom, lastY + MIN_NODE_VERTICAL_SPACING)
        end

        bucketLastY[bucket] = nodeY
        nodePositions[node.id] = { x = nodeX, y = nodeY }
    end

    return nodePositions
end

local function buildSortedNodes(nodes)
    local list = {}
    for _, node in pairs(nodes or {}) do
        list[#list + 1] = node
    end

    table.sort(list, function(a, b)
        local ay = (a.position and a.position.y) or 0
        local by = (b.position and b.position.y) or 0
        if ay == by then
            local ax = (a.position and a.position.x) or 0
            local bx = (b.position and b.position.x) or 0
            return ax < bx
        end
        return ay < by
    end)

    return list
end

local function drawHeader(treeArea, skills)
    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()
    local availablePoints = skills and skills.availablePoints or 0

    if availablePoints > 0 then
        love.graphics.setColor(0.95, 0.9, 0.7, 1)
    else
        love.graphics.setColor(0.7, 0.3, 0.3, 1)
    end
    love.graphics.print(string.format("Skill Points: %d", availablePoints), treeArea.x, treeArea.y)

    love.graphics.setColor(0.75, 0.7, 0.55, 1)
    local instructions
    if availablePoints > 0 then
        instructions = "Click a node to invest." 
    else
        instructions = "Earn skill points by leveling up."
    end
    love.graphics.print(instructions, treeArea.x, treeArea.y + fontHeight + 6)

    return fontHeight * 2 + 12
end

local function drawTreeBackdrop(area)
    love.graphics.setColor(0.12, 0.11, 0.1, 0.92)
    love.graphics.rectangle("fill", area.x, area.y, area.width, area.height, 10, 10)
    love.graphics.setColor(0.38, 0.33, 0.26, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", area.x, area.y, area.width, area.height, 10, 10)
end

local function drawEdges(area, spell, skills, nodePositions)
    local edges = (spell.skillTree and spell.skillTree.edges) or {}
    love.graphics.setLineWidth(3)
    for _, edge in ipairs(edges) do
        local fromPos = nodePositions[edge.from]
        local toPos = nodePositions[edge.to]
        if fromPos and toPos then
            local requirementsMet = SkillTree.requirementsMet(skills, spell, edge.to)
            if requirementsMet then
                love.graphics.setColor(0.8, 0.45, 0.2, 0.9)
            else
                love.graphics.setColor(0.3, 0.28, 0.24, 0.7)
            end
            love.graphics.line(fromPos.x, fromPos.y, toPos.x, toPos.y)
        end
    end
end

local function drawNode(scene, area, spell, node, skills, nodePositions)
    local position = nodePositions[node.id]
    if not position then
        return
    end

    local radius = math.min(38, math.max(28, math.min(area.width, area.height) * 0.1))
    local points = SkillTree.getNodePoints(skills, spell.id, node.id)
    local requirementsMet = SkillTree.requirementsMet(skills, spell, node.id)
    local maxPoints = node.maxPoints or math.huge
    local canInvest = false
    local availablePoints = skills and skills.availablePoints or 0
    if availablePoints > 0 and requirementsMet and points < maxPoints then
        canInvest = true
    end
    local isMaxed = maxPoints ~= math.huge and points >= maxPoints

    if points > 0 then
        love.graphics.setColor(0.72, 0.28, 0.12, 0.95)
    elseif requirementsMet then
        love.graphics.setColor(0.25, 0.2, 0.16, 0.9)
    else
        love.graphics.setColor(0.18, 0.18, 0.18, 0.75)
    end
    love.graphics.circle("fill", position.x, position.y, radius)

    if points > 0 then
        love.graphics.setColor(1.0, 0.6, 0.28, 1)
    elseif requirementsMet then
        love.graphics.setColor(0.78, 0.62, 0.32, 1)
    else
        love.graphics.setColor(0.45, 0.4, 0.32, 1)
    end
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", position.x, position.y, radius)

    local mouseX, mouseY = love.mouse.getPosition()
    local dx = mouseX - position.x
    local dy = mouseY - position.y
    local distanceSquared = dx * dx + dy * dy
    local hovered = distanceSquared <= radius * radius

    if hovered and canInvest then
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.circle("fill", position.x, position.y, radius)
    elseif hovered then
        love.graphics.setColor(1, 1, 1, 0.06)
        love.graphics.circle("fill", position.x, position.y, radius)
    end

    local font = love.graphics.getFont()
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local label = node.label or node.id
    local textWidth = font:getWidth(label)
    love.graphics.print(label, position.x - textWidth / 2, position.y + radius + 6)

    local pointsText
    if maxPoints == math.huge then
        pointsText = tostring(points)
    else
        pointsText = string.format("%d / %d", points, maxPoints)
    end
    local pointsWidth = font:getWidth(pointsText)
    love.graphics.print(pointsText, position.x - pointsWidth / 2, position.y - font:getHeight() / 2)

    scene.skillTreeNodeRects[#scene.skillTreeNodeRects + 1] = {
        x = position.x - radius,
        y = position.y - radius,
        w = radius * 2,
        h = radius * 2,
        nodeId = node.id,
        spellId = spell.id,
    }

    if hovered then
        scene.hoveredSkillNode = {
            spellId = spell.id,
            nodeId = node.id,
        }
    end

    if canInvest and not isMaxed then
        love.graphics.setColor(0.95, 0.9, 0.7, 1)
        love.graphics.print("+", position.x - 4, position.y - radius - font:getHeight())
    elseif isMaxed then
        love.graphics.setColor(0.75, 0.7, 0.5, 1)
        love.graphics.print("Max", position.x - font:getWidth("Max") / 2, position.y - radius - font:getHeight())
    end
end

function renderSkillsTree.draw(scene)
    local world = scene.world
    local player = world and world:getPlayer()
    if not player or not player.skills then
        return
    end

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local columns = layout.columns or WindowLayout.calculateColumns(layout, scene.windowChromeConfig and scene.windowChromeConfig.columns)
    layout.columns = columns
    local leftColumn = columns.left
    local padding = layout.padding or 28

    local treeArea, equippedArea = WindowLayout.splitVertical(leftColumn, { ratio = 0.62, spacing = padding }, padding)
    scene.skillTreeArea = treeArea
    scene.equippedArea = equippedArea

    local skills = player.skills
    local headerHeight = drawHeader(treeArea, skills)
    local graphArea = {
        x = treeArea.x,
        y = treeArea.y + headerHeight,
        width = treeArea.width,
        height = math.max(0, treeArea.height - headerHeight),
    }

    if graphArea.width <= 0 or graphArea.height <= 0 then
        return
    end

    drawTreeBackdrop(graphArea)

    local selectedSpellId = scene.selectedSpellId
    local spell = selectedSpellId and Spells.types[selectedSpellId] or nil
    if not spell or not spell.skillTree then
        love.graphics.setColor(0.7, 0.65, 0.5, 1)
        love.graphics.print("Select a spell to view its skill tree.", graphArea.x + padding, graphArea.y + padding)
        return
    end

    local nodes = spell.skillTree.nodes or {}
    local nodeList = buildSortedNodes(nodes)
    local nodePositions = calculateNodePositions(graphArea, nodeList)

    drawEdges(graphArea, spell, skills, nodePositions)

    scene.skillTreeNodeRects = {}
    for _, node in ipairs(nodeList) do
        drawNode(scene, graphArea, spell, node, skills, nodePositions)
    end
end

return renderSkillsTree
