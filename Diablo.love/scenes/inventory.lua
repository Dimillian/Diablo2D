local ItemGenerator = require("items.generator")
local EquipmentHelper = require("system_helpers.equipment")
local Resources = require("modules.resources")

local rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local function snap(value)
    return math.floor(value + 0.5)
end

local statDisplayOrder = {
    { key = "health", label = "Health", always = true, type = "int" },
    { key = "defense", label = "Defense", type = "int" },
    { key = "critChance", label = "Crit Chance", type = "percent" },
    { key = "attackSpeed", label = "Attack Speed", type = "percent" },
    { key = "lifeSteal", label = "Life Steal", type = "percent" },
    { key = "moveSpeed", label = "Move Speed", type = "percent" },
    { key = "dodgeChance", label = "Dodge Chance", type = "percent" },
    { key = "goldFind", label = "Gold Find", type = "percent" },
    { key = "resistAll", label = "All Resist", type = "percent" },
}

local function buildSummaryLines(total)
    local lines = {}

    local damageMin = total.damageMin or 0
    local damageMax = total.damageMax or 0
    if damageMin > 0 or damageMax > 0 then
        lines[#lines + 1] = string.format("Damage: %d - %d", math.floor(damageMin + 0.5), math.floor(damageMax + 0.5))
    end

    for _, entry in ipairs(statDisplayOrder) do
        local value = total[entry.key] or 0
        if value ~= 0 or entry.always then
            if entry.type == "percent" then
                lines[#lines + 1] = string.format("%s: %.1f%%", entry.label, value * 100)
            else
                lines[#lines + 1] = string.format("%s: %d", entry.label, math.floor(value + 0.5))
            end
        end
    end

    if #lines == 0 then
        lines[#lines + 1] = "No stats"
    end

    return lines
end

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
    self.equipmentRects = {}
end

-- luacheck: ignore 212/self
function InventoryScene:exit()
end

-- luacheck: ignore 212/self
function InventoryScene:update(_dt)
end

function InventoryScene:draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()

    local panelWidth = snap(screenWidth * 0.8)
    local panelHeight = snap(screenHeight * 0.8)
    local panelX = snap((screenWidth - panelWidth) / 2)
    local panelY = snap((screenHeight - panelHeight) / 2)

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
    local dividerX = snap(panelX + (panelWidth * 0.45))
    love.graphics.line(dividerX, panelY, dividerX, panelY + panelHeight)

    local headerY = snap(panelY + 20)
    local equipmentHeaderX = snap(panelX + 20)
    local inventoryHeaderX = snap(dividerX + 20)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Equipment", equipmentHeaderX, headerY)
    love.graphics.print("Inventory", inventoryHeaderX, headerY)

    local equipmentAreaTop = snap(headerY + 30)
    local equipmentAreaHeight = snap(panelHeight * 0.45)
    local equipmentAreaBottom = equipmentAreaTop + equipmentAreaHeight
    local equipmentAreaWidth = snap(dividerX - panelX - 40)
    local equipmentAreaX = equipmentHeaderX

    local statsDividerY = snap(equipmentAreaBottom + 12)
    local statsHeaderY = snap(statsDividerY + 12)
    local statsStartY = snap(statsHeaderY + 24)

    local player = self.world:getPlayer()
    local inventory, equipment = EquipmentHelper.ensure(player)
    local items = inventory and inventory.items or {}

    self.itemRects = {}
    self.equipmentRects = {}

    -- Equipment slots
    local columns = 2
    local slotSpacingX = 14
    local slotSpacingY = 12
    local slotWidth = snap((equipmentAreaWidth - slotSpacingX * (columns - 1)) / columns)
    local slotHeight = 64

    local slots = EquipmentHelper.slots()
    for index, slot in ipairs(slots) do
        local col = ((index - 1) % columns)
        local row = math.floor((index - 1) / columns)

        local slotX = snap(equipmentAreaX + col * (slotWidth + slotSpacingX))
        local slotY = snap(equipmentAreaTop + row * (slotHeight + slotSpacingY))

        love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
        love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 6, 6)
        love.graphics.setColor(0.45, 0.4, 0.3, 1)
        love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 6, 6)

        local labelY = snap(slotY + 6)
        love.graphics.setColor(0.85, 0.82, 0.7, 1)
        love.graphics.print(slot.label, snap(slotX + 8), labelY)

        local equippedItem = equipment[slot.id]

        if equippedItem then
            -- Draw sprite centered in slot
            local sprite = Resources.loadImageSafe(equippedItem.spritePath)
            if sprite then
                local spriteSize = 40
                local spriteX = snap(slotX + (slotWidth - spriteSize) / 2)
                local spriteY = snap(labelY + 20)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(sprite, spriteX, spriteY, 0, spriteSize / sprite:getWidth(), spriteSize / sprite:getHeight())
            end

            self.equipmentRects[#self.equipmentRects + 1] = {
                slot = slot.id,
                item = equippedItem,
                x = slotX,
                y = slotY,
                w = slotWidth,
                h = slotHeight,
            }
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            local emptyTextY = snap(slotY + (slotHeight / 2))
            love.graphics.print("Empty", snap(slotX + (slotWidth - love.graphics.getFont():getWidth("Empty")) / 2), emptyTextY)
            self.equipmentRects[#self.equipmentRects + 1] = {
                slot = slot.id,
                item = nil,
                x = slotX,
                y = slotY,
                w = slotWidth,
                h = slotHeight,
            }
        end
    end

    -- Stats section
    local statsWidth = equipmentAreaWidth
    love.graphics.setColor(0.35, 0.32, 0.28, 1)
    love.graphics.line(equipmentAreaX, statsDividerY, equipmentAreaX + statsWidth, statsDividerY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Stats", equipmentAreaX, statsHeaderY)

    local totalStats = EquipmentHelper.computeTotalStats(player)
    local statLines = buildSummaryLines(totalStats)
    local statLineHeight = 18
    for idx, line in ipairs(statLines) do
        love.graphics.print(line, equipmentAreaX, snap(statsStartY + (idx - 1) * statLineHeight))
    end

    -- Inventory items list
    local lineHeight = 18
    local spriteIconSize = 16
    local itemsStartY = snap(headerY + 32)
    local itemAreaX = inventoryHeaderX
    local itemAreaWidth = snap((panelX + panelWidth) - 40 - itemAreaX)
    local textOffsetX = itemAreaX + spriteIconSize + 8

    for index, item in ipairs(items) do
        local y = itemsStartY + (index - 1) * lineHeight
        if y > panelY + panelHeight - 60 then
            break
        end
        local snappedY = snap(y)

        -- Draw sprite icon if available
        local sprite = Resources.loadImageSafe(item.spritePath)
        if sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprite, itemAreaX, snappedY, 0, spriteIconSize / sprite:getWidth(), spriteIconSize / sprite:getHeight())
        end

        local color = rarityColors[item.rarity] or rarityColors.common
        love.graphics.setColor(color)
        love.graphics.print(
            string.format("%s [%s]", item.name, item.rarityLabel),
            textOffsetX,
            snappedY
        )

        self.itemRects[#self.itemRects + 1] = {
            item = item,
            index = index,
            x = itemAreaX,
            y = snappedY,
            w = itemAreaWidth,
            h = lineHeight,
        }
    end

    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Press G to add random loot", inventoryHeaderX, snap(panelY + panelHeight - 32))

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
        local inventory = EquipmentHelper.ensure(player)
        if inventory and inventory.items then
            table.insert(inventory.items, item)
        end
    end
end

function InventoryScene:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local player = self.world:getPlayer()
    if not player then
        return
    end

    local inventory, equipment = EquipmentHelper.ensure(player)
    if not inventory or not equipment then
        return
    end

    -- Inventory items: equip on click
    for _, rect in ipairs(self.itemRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local item = rect.item
            local slot = item.slot
            if slot then
                EquipmentHelper.removeFromInventory(player, rect.index)
                EquipmentHelper.equip(player, item)
            end
            return
        end
    end

    -- Equipment slots: unequip on click
    for _, rect in ipairs(self.equipmentRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            EquipmentHelper.unequip(player, rect.slot)
            return
        end
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
    local mx, my = love.mouse.getPosition()
    local hovered

    for _, rect in ipairs(self.itemRects) do
        if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
            hovered = rect.item
            break
        end
    end

    if not hovered then
        for _, rect in ipairs(self.equipmentRects or {}) do
            if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
                hovered = rect.item
                break
            end
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
    width = math.max(width, font:getWidth(hovered.rarityLabel or ""))
    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    width = math.ceil(width + padding * 2)

    local height = math.ceil(lineHeight * (#lines + 1) + padding * 3)

    local tooltipX = snap(mx + 16)
    local tooltipY = snap(my + 16)

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
    love.graphics.print(hovered.name, snap(tooltipX + padding), snap(titleY))

    love.graphics.setColor(0.75, 0.75, 0.85, 1)
    love.graphics.print(hovered.rarityLabel, snap(tooltipX + padding), snap(titleY + lineHeight))

    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(lines) do
        love.graphics.print(
            line,
            snap(tooltipX + padding),
            snap(titleY + lineHeight * (index + 1))
        )
    end

    love.graphics.pop()
end

return InventoryScene
