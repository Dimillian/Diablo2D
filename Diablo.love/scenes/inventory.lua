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
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderInventoryEquipment.draw,
                renderInventoryStats.draw,
                renderInventoryGrid.draw,
                renderInventoryBottomBar.draw,
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
end

-- luacheck: ignore 212/self
function InventoryScene:exit()
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
        local item = ItemGenerator.generate()
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

return InventoryScene
