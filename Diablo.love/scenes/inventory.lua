local ItemGenerator = require("items.generator")
local EquipmentHelper = require("system_helpers.equipment")
local Resources = require("modules.resources")
local Tooltips = require("system_helpers.tooltips")

local rarityColors = Tooltips.rarityColors

-- Utility function to snap values to nearest pixel for crisp rendering
local function snap(value)
    return math.floor(value + 0.5)
end

-- Configuration for stat display order and formatting
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

---Build formatted stat summary lines from total stats
---@param total table Total stats object
---@return table Array of formatted stat strings
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

---Create a new inventory scene
---@param opts table|nil Options table with world reference
---@return InventoryScene
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

---Initialize scene state when entering
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

---Calculate panel dimensions and position centered on screen
---@return number panelX, number panelY, number panelWidth, number panelHeight
local function calculatePanelLayout()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelWidth = snap(screenWidth * 0.8)
    local panelHeight = snap(screenHeight * 0.8)
    local panelX = snap((screenWidth - panelWidth) / 2)
    local panelY = snap((screenHeight - panelHeight) / 2)
    return panelX, panelY, panelWidth, panelHeight
end

---Draw dimmed background overlay
---@param screenWidth number Screen width
---@param screenHeight number Screen height
local function drawBackground(screenWidth, screenHeight)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
end

---Draw panel background and border
---@param panelX number Panel X position
---@param panelY number Panel Y position
---@param panelWidth number Panel width
---@param panelHeight number Panel height
local function drawPanel(panelX, panelY, panelWidth, panelHeight)
    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 8, 8)

    -- Panel border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 8, 8)
end

---Draw section headers and divider
---@param panelX number Panel X position
---@param panelY number Panel Y position
---@param panelWidth number Panel width
---@param panelHeight number Panel height
---@param dividerX number X position of divider line
---@return number equipmentHeaderX, number inventoryHeaderX, number headerY
local function drawHeaders(panelX, panelY, panelWidth, panelHeight, dividerX)
    local headerY = snap(panelY + 20)
    local equipmentHeaderX = snap(panelX + 20)
    local inventoryHeaderX = snap(dividerX + 20)

    -- Draw divider line
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.line(dividerX, panelY, dividerX, panelY + panelHeight)

    -- Draw headers
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Equipment", equipmentHeaderX, headerY)
    love.graphics.print("Inventory", inventoryHeaderX, headerY)

    return equipmentHeaderX, inventoryHeaderX, headerY
end

---Draw a single equipment slot with item sprite if equipped
---@param self InventoryScene Scene instance
---@param slot table Slot definition {id, label}
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotWidth number Slot width
---@param slotHeight number Slot height
---@param equippedItem table|nil Equipped item or nil
local function drawEquipmentSlot(self, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    -- Draw slot background and border
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotWidth, slotHeight, 6, 6)
    love.graphics.setColor(0.45, 0.4, 0.3, 1)
    love.graphics.rectangle("line", slotX, slotY, slotWidth, slotHeight, 6, 6)

    -- Draw slot label
    local labelY = snap(slotY + 6)
    love.graphics.setColor(0.85, 0.82, 0.7, 1)
    love.graphics.print(slot.label, snap(slotX + 8), labelY)

    if equippedItem then
        -- Draw equipped item sprite
        local sprite = Resources.loadImageSafe(equippedItem.spritePath)
        if sprite then
            local spriteSize = 40
            local spriteX = snap(slotX + (slotWidth - spriteSize) / 2)
            local spriteY = snap(labelY + 20)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                sprite,
                spriteX,
                spriteY,
                0,
                spriteSize / sprite:getWidth(),
                spriteSize / sprite:getHeight()
            )
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
        -- Draw "Empty" text
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        local emptyTextY = snap(slotY + (slotHeight / 2))
        local emptyTextX = snap(slotX + (slotWidth - love.graphics.getFont():getWidth("Empty")) / 2)
        love.graphics.print("Empty", emptyTextX, emptyTextY)

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

---Draw all equipment slots in a grid layout
---@param self InventoryScene Scene instance
---@param equipment table Equipment component
---@param equipmentAreaX number Area X position
---@param equipmentAreaTop number Area top Y position
---@param equipmentAreaWidth number Area width
local function drawEquipmentSlots(self, equipment, equipmentAreaX, equipmentAreaTop, equipmentAreaWidth)
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
        local equippedItem = equipment[slot.id]

        drawEquipmentSlot(self, slot, slotX, slotY, slotWidth, slotHeight, equippedItem)
    end
end

---Draw stats section with total stats
---@param player table Player entity
---@param equipmentAreaX number Area X position
---@param statsDividerY number Divider Y position
---@param statsHeaderY number Header Y position
---@param statsStartY number Stats start Y position
---@param equipmentAreaWidth number Area width
local function drawStats(player, equipmentAreaX, statsDividerY, statsHeaderY, statsStartY, equipmentAreaWidth)
    -- Draw divider line
    love.graphics.setColor(0.35, 0.32, 0.28, 1)
    love.graphics.line(equipmentAreaX, statsDividerY, equipmentAreaX + equipmentAreaWidth, statsDividerY)

    -- Draw header
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Stats", equipmentAreaX, statsHeaderY)

    -- Draw stat lines
    local totalStats = EquipmentHelper.computeTotalStats(player)
    local statLines = buildSummaryLines(totalStats)
    local statLineHeight = 18
    for idx, line in ipairs(statLines) do
        love.graphics.print(line, equipmentAreaX, snap(statsStartY + (idx - 1) * statLineHeight))
    end
end

---Draw a filled inventory slot with item sprite and rarity-colored border
---@param self InventoryScene Scene instance
---@param item table Item object
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotSize number Slot size (width and height)
---@param slotIndex number Slot index in inventory
local function drawInventorySlotFilled(self, item, slotX, slotY, slotSize, slotIndex)
    local rarityColor = rarityColors[item.rarity] or rarityColors.common

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw rarity-colored border
    love.graphics.setColor(rarityColor)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw sprite centered (32x32)
    local sprite = Resources.loadImageSafe(item.spritePath)
    if sprite then
        local spriteSize = 32
        local spriteX = snap(slotX + (slotSize - spriteSize) / 2)
        local spriteY = snap(slotY + (slotSize - spriteSize) / 2)

        love.graphics.setColor(1, 1, 1, 1)
        local spriteScaleX = spriteSize / sprite:getWidth()
        local spriteScaleY = spriteSize / sprite:getHeight()
        love.graphics.draw(
            sprite,
            spriteX,
            spriteY,
            0,
            spriteScaleX,
            spriteScaleY
        )
    end

    -- Store rect for click detection
    self.itemRects[#self.itemRects + 1] = {
        item = item,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

---Draw an empty inventory slot
---@param self InventoryScene Scene instance
---@param slotX number Slot X position
---@param slotY number Slot Y position
---@param slotSize number Slot size (width and height)
---@param slotIndex number Slot index in inventory
local function drawInventorySlotEmpty(self, slotX, slotY, slotSize, slotIndex)
    -- Draw empty slot background
    love.graphics.setColor(0.16, 0.16, 0.18, 0.95)
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Draw empty slot border
    love.graphics.setColor(0.35, 0.35, 0.35, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4, 4)

    -- Store rect for click detection
    self.itemRects[#self.itemRects + 1] = {
        item = nil,
        index = slotIndex,
        x = slotX,
        y = slotY,
        w = slotSize,
        h = slotSize,
    }
end

---Draw inventory grid with filled and empty slots
---@param self InventoryScene Scene instance
---@param items table Array of inventory items
---@param inventoryHeaderX number Inventory header X position
---@param headerY number Header Y position
---@param panelX number Panel X position
---@param panelY number Panel Y position
---@param panelWidth number Panel width
---@param panelHeight number Panel height
local function drawInventoryGrid(self, items, inventoryHeaderX, headerY, panelX, panelY, panelWidth, panelHeight)
    local gridSlotSize = 40 -- 32px sprite + 8px padding
    local gridCols = 8
    local gridRows = 6
    local gridMaxSlots = gridCols * gridRows
    local gridSpacing = 4
    local gridStartX = inventoryHeaderX
    local gridStartY = snap(headerY + 32)
    local gridAreaWidth = snap((panelX + panelWidth) - 40 - gridStartX)

    -- Calculate how many columns fit in available width
    local availableCols = math.floor((gridAreaWidth + gridSpacing) / (gridSlotSize + gridSpacing))
    if availableCols < gridCols then
        gridCols = math.max(1, availableCols)
        gridMaxSlots = gridCols * gridRows
    end

    -- Draw inventory grid (empty slots + filled slots)
    for slotIndex = 1, gridMaxSlots do
        local col = ((slotIndex - 1) % gridCols)
        local row = math.floor((slotIndex - 1) / gridCols)

        local slotX = snap(gridStartX + col * (gridSlotSize + gridSpacing))
        local slotY = snap(gridStartY + row * (gridSlotSize + gridSpacing))

        -- Stop if we go beyond panel bounds
        if slotY + gridSlotSize > panelY + panelHeight - 60 then
            break
        end

        local item = items[slotIndex]

        if item then
            drawInventorySlotFilled(self, item, slotX, slotY, gridSlotSize, slotIndex)
        else
            drawInventorySlotEmpty(self, slotX, slotY, gridSlotSize, slotIndex)
        end
    end
end

---Draw help text at bottom of inventory section
---@param inventoryHeaderX number Inventory header X position
---@param panelY number Panel Y position
---@param panelHeight number Panel height
local function drawHelpText(inventoryHeaderX, panelY, panelHeight)
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("Press G to add random loot", inventoryHeaderX, snap(panelY + panelHeight - 32))
end

---Main draw function orchestrating all rendering
function InventoryScene:draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelX, panelY, panelWidth, panelHeight = calculatePanelLayout()

    love.graphics.push("all")

    -- Draw background and panel
    drawBackground(screenWidth, screenHeight)
    drawPanel(panelX, panelY, panelWidth, panelHeight)

    -- Calculate divider and draw headers
    local dividerX = snap(panelX + (panelWidth * 0.45))
    local equipmentHeaderX, inventoryHeaderX, headerY = drawHeaders(panelX, panelY, panelWidth, panelHeight, dividerX)

    -- Calculate equipment area layout
    local equipmentAreaTop = snap(headerY + 30)
    local equipmentAreaHeight = snap(panelHeight * 0.45)
    local equipmentAreaBottom = equipmentAreaTop + equipmentAreaHeight
    local equipmentAreaWidth = snap(dividerX - panelX - 40)
    local equipmentAreaX = equipmentHeaderX

    local statsDividerY = snap(equipmentAreaBottom + 12)
    local statsHeaderY = snap(statsDividerY + 12)
    local statsStartY = snap(statsHeaderY + 24)

    -- Get player data
    local player = self.world:getPlayer()
    if not player then
        love.graphics.pop()
        return
    end

    local inventory, equipment = EquipmentHelper.ensure(player)
    local items = inventory and inventory.items or {}

    -- Reset rects for click detection
    self.itemRects = {}
    self.equipmentRects = {}

    -- Draw equipment section
    drawEquipmentSlots(self, equipment, equipmentAreaX, equipmentAreaTop, equipmentAreaWidth)
    drawStats(player, equipmentAreaX, statsDividerY, statsHeaderY, statsStartY, equipmentAreaWidth)

    -- Draw inventory grid
    drawInventoryGrid(self, items, inventoryHeaderX, headerY, panelX, panelY, panelWidth, panelHeight)

    -- Draw help text
    drawHelpText(inventoryHeaderX, panelY, panelHeight)

    -- Draw tooltips
    self:drawTooltip()

    love.graphics.pop()
end

---Handle keyboard input
---@param key string Key pressed
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

---Handle mouse click input
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button pressed
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

    -- Inventory items: equip on click (only if item exists)
    for _, rect in ipairs(self.itemRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local item = rect.item
            if item and item.slot then
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

---Draw tooltip for hovered item
function InventoryScene:drawTooltip()
    local mx, my = love.mouse.getPosition()
    local hovered

    -- Check inventory items (only show tooltip if item exists)
    for _, rect in ipairs(self.itemRects or {}) do
        if mx >= rect.x and mx <= rect.x + rect.w and my >= rect.y and my <= rect.y + rect.h then
            if rect.item then
                hovered = rect.item
                break
            end
        end
    end

    -- Check equipment slots
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

    Tooltips.drawItemTooltip(hovered, mx, my, {
        offsetX = 16,
        offsetY = 16,
        clamp = true,
    })
end

return InventoryScene
