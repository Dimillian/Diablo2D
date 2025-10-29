local ItemGenerator = require("items.generator")

local rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local InventoryScene = {}
InventoryScene.__index = InventoryScene

function InventoryScene.new(opts)
    opts = opts or {}

    local world = assert(opts.world, "InventoryScene requires world reference")

    local scene = {
        world = world,
        title = opts.title or "Inventory",
        kind = "inventory",
    }

    return setmetatable(scene, InventoryScene)
end

function InventoryScene:enter()
    self.itemRects = {}
end

function InventoryScene:exit()
end

function InventoryScene:update(dt)
end

function InventoryScene:draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()

    local panelWidth = screenWidth * 0.8
    local panelHeight = screenHeight * 0.8
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = (screenHeight - panelHeight) / 2

    love.graphics.push("all")

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8, 8)

    -- Panel border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8, 8)

    -- Divide panel into equipment (left) and inventory (right)
    local dividerX = panelX + (panelWidth * 0.45)
    love.graphics.line(dividerX, panelY, dividerX, panelY + panelHeight)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Equipment", panelX + 20, panelY + 20)
    love.graphics.print("Inventory", dividerX + 20, panelY + 20)

    -- Draw inventory items list
    local player = self.world:getPlayer()
    local inventory = player and player.inventory or { items = {} }
    inventory.items = inventory.items or {}
    local items = inventory.items
    local lineHeight = 18
    local startY = panelY + 52
    local itemAreaX = dividerX + 20
    local itemAreaWidth = (panelX + panelWidth) - 40 - itemAreaX

    self.itemRects = {}

    for index, item in ipairs(items) do
        local y = startY + (index - 1) * lineHeight
        if y > panelY + panelHeight - 40 then
            break
        end

        local color = rarityColors[item.rarity] or rarityColors.common
        love.graphics.setColor(color)
        love.graphics.print(
            string.format("%s [%s]", item.name, item.rarityLabel),
            itemAreaX,
            y
        )

        self.itemRects[#self.itemRects + 1] = {
            item = item,
            x = itemAreaX,
            y = y,
            w = itemAreaWidth,
            h = lineHeight,
        }
    end

    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Press G to add random loot", dividerX + 20, panelY + panelHeight - 32)

    self:drawTooltip()

    love.graphics.pop()
end

function InventoryScene:keypressed(key)
    if key == "g" then
        local item = ItemGenerator.generate()
        local player = self.world:getPlayer()
        if not player then
            return
        end
        player.inventory = player.inventory or { items = {} }
        player.inventory.items = player.inventory.items or {}
        table.insert(player.inventory.items, item)
    end
end

local function formatStatLines(item)
    local stats = item.stats or {}
    local lines = {}

    if stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0) then
        lines[#lines + 1] = string.format("Damage: %d - %d", stats.damageMin, stats.damageMax)
    end

    if stats.defense and stats.defense > 0 then
        lines[#lines + 1] = string.format("Defense: %d", stats.defense)
    end

    if stats.health and stats.health > 0 then
        lines[#lines + 1] = string.format("+%d Health", stats.health)
    end

    local function formatPercent(value)
        return string.format("+%.1f%%", value * 100)
    end

    if stats.critChance and stats.critChance > 0 then
        lines[#lines + 1] = formatPercent(stats.critChance) .. " Crit Chance"
    end

    if stats.moveSpeed and stats.moveSpeed > 0 then
        lines[#lines + 1] = formatPercent(stats.moveSpeed) .. " Move Speed"
    end

    if stats.dodgeChance and stats.dodgeChance > 0 then
        lines[#lines + 1] = formatPercent(stats.dodgeChance) .. " Dodge Chance"
    end

    if stats.goldFind and stats.goldFind > 0 then
        lines[#lines + 1] = formatPercent(stats.goldFind) .. " Gold Find"
    end

    if stats.lifeSteal and stats.lifeSteal > 0 then
        lines[#lines + 1] = formatPercent(stats.lifeSteal) .. " Life Steal"
    end

    if stats.attackSpeed and stats.attackSpeed > 0 then
        lines[#lines + 1] = formatPercent(stats.attackSpeed) .. " Attack Speed"
    end

    if stats.resistAll and stats.resistAll > 0 then
        lines[#lines + 1] = formatPercent(stats.resistAll) .. " All Resist"
    end

    if #lines == 0 then
        lines[#lines + 1] = "No bonuses"
    end

    return lines
end

function InventoryScene:drawTooltip()
    if not self.itemRects then
        return
    end

    local mx, my = love.mouse.getPosition()
    local hovered

    for _, rect in ipairs(self.itemRects) do
        if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
            hovered = rect.item
            break
        end
    end

    if not hovered then
        return
    end

    local lines = formatStatLines(hovered)
    local rarityColor = rarityColors[hovered.rarity] or rarityColors.common
    local font = love.graphics.getFont()
    local padding = 10
    local lineHeight = font:getHeight()

    local width = font:getWidth(hovered.name)
    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    width = width + padding * 2

    local height = lineHeight * (#lines + 1) + padding * 3

    local tooltipX = mx + 16
    local tooltipY = my + 16

    local screenWidth, screenHeight = love.graphics.getDimensions()

    if tooltipX + width > screenWidth then
        tooltipX = screenWidth - width - 8
    end

    if tooltipY + height > screenHeight then
        tooltipY = screenHeight - height - 8
    end

    love.graphics.push("all")

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tooltipX, tooltipY, width, height, 6, 6)

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

    local titleY = tooltipY + padding
    love.graphics.setColor(rarityColor)
    love.graphics.print(hovered.name, tooltipX + padding, titleY)

    love.graphics.setColor(0.75, 0.75, 0.85, 1)
    love.graphics.print(hovered.rarityLabel, tooltipX + padding, titleY + lineHeight)

    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(lines) do
        love.graphics.print(
            line,
            tooltipX + padding,
            titleY + lineHeight * (index + 1)
        )
    end

    love.graphics.pop()
end

return InventoryScene
