local ItemGenerator = require("items.generator")
local EquipmentHelper = require("systems.helpers.equipment")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")

-- Import render systems
local renderWindowChrome = require("systems.render.window.chrome")
local renderInventoryEquipment = require("systems.render.inventory.equipment")
local renderInventoryStats = require("systems.render.inventory.stats")
local renderInventoryGrid = require("systems.render.inventory.grid")
local renderInventoryBottomBar = require("systems.render.inventory.bottom_bar")
local renderInventoryTooltip = require("systems.render.inventory.tooltip")
local renderInventoryDragDrop = require("systems.render.inventory.drag_drop")

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
        kind = SceneKinds.INVENTORY,
        windowLayoutOptions = {
            widthRatio = 0.8,
            heightRatio = 0.9,
            headerHeight = 76,
            footerHeight = renderInventoryBottomBar.HEIGHT,
            footerSpacing = 20,
            padding = 28,
            footerPadding = 12,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderInventoryEquipment.draw,
                renderInventoryStats.draw,
                renderInventoryGrid.draw,
                renderInventoryBottomBar.draw,
                renderInventoryDragDrop.draw,
                renderInventoryTooltip.draw,
            },
        },
    }

    scene.windowChromeConfig = {
        title = scene.title,
        icon = "bag",
        columns = {
            leftRatio = 0.43,
            spacing = 28,
            topInset = 0,
            bottomInset = 24,
        },
    }

    return setmetatable(scene, InventoryScene)
end

---Initialize scene state when entering
function InventoryScene:enter()
    self.itemRects = {}
    self.equipmentRects = {}
    self.inventoryGridBottomY = nil
    self.windowRects = {}
    self.attributeButtonRects = {}
    self.windowLayout = nil
    self.dragState = nil
    self.trashRect = nil
end

-- luacheck: ignore 212/self
function InventoryScene:exit()
    -- Clear drag state when leaving inventory
    self.dragState = nil
end

-- luacheck: ignore 212/self
function InventoryScene:update(_dt)
end

---Main draw function orchestrating all rendering systems
function InventoryScene:draw()
    love.graphics.push("all")

    -- Reset rects for click detection
    self.itemRects = {}
    self.equipmentRects = {}
    self.inventoryGridBottomY = nil
    self.windowRects = {}
    self.attributeButtonRects = {}

    -- Iterate through all render systems
    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

---Handle keyboard input
---@param key string Key pressed
function InventoryScene:keypressed(key)
    local action = InputManager.getActionForKey(key)
    if action == InputActions.INVENTORY_TEST_ITEM then
        local item = ItemGenerator.generate({ foeTier = 1 })
        local player = self.world:getPlayer()
        if player then
            EquipmentHelper.addToInventory(player, item)
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

    local closeRect = self.windowRects and self.windowRects.close
    if closeRect
        and x >= closeRect.x
        and x <= closeRect.x + closeRect.w
        and y >= closeRect.y
        and y <= closeRect.y + closeRect.h
    then
        if self.world.sceneManager then
            self.world.sceneManager:pop()
        end
        return
    end

    -- Inventory items: start drag on click (only if item exists)
    for _, rect in ipairs(self.itemRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local item = rect.item
            if item then
                -- Start drag
                self.dragState = {
                    item = item,
                    sourceIndex = rect.index,
                    sourceType = "inventory",
                    mouseX = x,
                    mouseY = y,
                }
            end
            return
        end
    end

    -- Equipment slots: start drag on click (if item exists)
    for _, rect in ipairs(self.equipmentRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local item = rect.item
            if item then
                -- Start drag from equipment slot
                self.dragState = {
                    item = item,
                    sourceSlot = rect.slot,
                    sourceType = "equipment",
                    mouseX = x,
                    mouseY = y,
                }
            end
            return
        end
    end

    -- Attribute + buttons: allocate points
    for _, rect in ipairs(self.attributeButtonRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local exp = player.experience
            if exp and (exp.unallocatedPoints or 0) > 0 and player.baseStats then
                local attributeKey = rect.attributeKey
                if attributeKey then
                    player.baseStats[attributeKey] = (player.baseStats[attributeKey] or 0) + 1
                    exp.unallocatedPoints = (exp.unallocatedPoints or 0) - 1
                end
            end
            return
        end
    end
end

---Handle mouse release input
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button released
function InventoryScene:mousereleased(x, y, button)
    if button ~= 1 then
        return
    end

    if not self.dragState then
        return
    end

    local player = self.world:getPlayer()
    if not player then
        self.dragState = nil
        return
    end

    local dragState = self.dragState
    local draggedItem = dragState.item

    -- Check trash dropzone first
    if self.trashRect then
        if x >= self.trashRect.x
            and x <= self.trashRect.x + self.trashRect.w
            and y >= self.trashRect.y
            and y <= self.trashRect.y + self.trashRect.h
        then
            -- Destroy item
            if dragState.sourceType == "inventory" then
                EquipmentHelper.removeFromInventory(player, dragState.sourceIndex)
            elseif dragState.sourceType == "equipment" then
                local equipment = player.equipment
                equipment[dragState.sourceSlot] = nil
            end
            self.dragState = nil
            return
        end
    end

    -- Check equipment slots
    for _, rect in ipairs(self.equipmentRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            -- Check if item is compatible with this slot
            local slotId = rect.slot
            local compatibleSlot = draggedItem.slot
            if compatibleSlot == "ring" and (slotId == "ringLeft" or slotId == "ringRight") then
                compatibleSlot = slotId
            end

            if compatibleSlot == slotId then
                -- Equip item
                local previousItem = nil
                if dragState.sourceType == "inventory" then
                    EquipmentHelper.removeFromInventory(player, dragState.sourceIndex)
                elseif dragState.sourceType == "equipment" then
                    local equipment = player.equipment
                    previousItem = equipment[dragState.sourceSlot]
                    equipment[dragState.sourceSlot] = nil
                end
                local equipped = EquipmentHelper.equip(player, draggedItem)
                if not equipped then
                    -- Failed to equip (inventory full), restore item
                    if dragState.sourceType == "inventory" then
                        EquipmentHelper.addToInventory(player, draggedItem)
                    elseif dragState.sourceType == "equipment" then
                        local equipment = player.equipment
                        equipment[dragState.sourceSlot] = previousItem
                    end
                end
                self.dragState = nil
                return
            end
        end
    end

    -- Check inventory slots
    for _, rect in ipairs(self.itemRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local targetIndex = rect.index

            -- If dragging from inventory to inventory, swap items
            if dragState.sourceType == "inventory" then
                local inventory = player.inventory
                local items = inventory.items
                local sourceIndex = dragState.sourceIndex

                if sourceIndex ~= targetIndex then
                    local targetItem = items[targetIndex]
                    items[targetIndex] = draggedItem
                    items[sourceIndex] = targetItem
                end
            elseif dragState.sourceType == "equipment" then
                -- Dragging from equipment to inventory slot
                local inventory = player.inventory
                local items = inventory.items
                local targetItem = items[targetIndex]

                -- Remove from equipment first
                local equipment = player.equipment
                equipment[dragState.sourceSlot] = nil

                -- If target slot has an item, try to swap
                if targetItem then
                    -- Try to equip the target item if compatible
                    if targetItem.slot then
                        local slotId = targetItem.slot
                        if slotId == "ring" then
                            -- Try ringLeft first, then ringRight
                            if not equipment.ringLeft then
                                slotId = "ringLeft"
                            elseif not equipment.ringRight then
                                slotId = "ringRight"
                            else
                                slotId = "ringLeft"
                            end
                        end
                        if not equipment[slotId] then
                            -- Can equip target item
                            -- equip() already removes the item from inventory internally
                            local equipped = EquipmentHelper.equip(player, targetItem)
                            if not equipped then
                                -- Failed to equip (inventory full), restore dragged item to equipment
                                equipment[dragState.sourceSlot] = draggedItem
                                return
                            end
                        else
                            -- Can't equip, restore equipment and keep target item
                            equipment[dragState.sourceSlot] = draggedItem
                            return
                        end
                    else
                        -- Target item has no slot, swap positions
                        items[targetIndex] = draggedItem
                        -- Put target item back in equipment slot
                        equipment[dragState.sourceSlot] = targetItem
                        return
                    end
                end

                -- Place dragged item in target slot (empty or after swap)
                items[targetIndex] = draggedItem
            end

            self.dragState = nil
            return
        end
    end

    -- Drop outside any valid target - cancel drag
    self.dragState = nil
end

---Handle mouse move input
---@param x number Mouse X position
---@param y number Mouse Y position
---@param dx number Mouse X delta (unused)
---@param dy number Mouse Y delta (unused)
---@param istouch boolean Whether this is a touch event (unused)
-- luacheck: ignore 212/dx 212/dy 212/istouch
function InventoryScene:mousemoved(x, y, dx, dy, istouch)
    if self.dragState then
        self.dragState.mouseX = x
        self.dragState.mouseY = y
    end
end

return InventoryScene
