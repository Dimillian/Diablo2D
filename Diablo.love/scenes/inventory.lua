local ItemGenerator = require("items.generator")
local EquipmentHelper = require("systems.helpers.equipment")

-- Import render systems
local renderInventoryBackground = require("systems.render.inventory.background")
local renderInventoryEquipment = require("systems.render.inventory.equipment")
local renderInventoryStats = require("systems.render.inventory.stats")
local renderInventoryGrid = require("systems.render.inventory.grid")
local renderInventoryBottomBar = require("systems.render.inventory.bottom_bar")
local renderInventoryHelp = require("systems.render.inventory.help")
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
        kind = "inventory",
        systems = {
            draw = {
                renderInventoryBackground.draw,
                renderInventoryEquipment.draw,
                renderInventoryStats.draw,
                renderInventoryGrid.draw,
                renderInventoryBottomBar.draw,
                renderInventoryHelp.draw,
                renderInventoryTooltip.draw,
            },
        },
    }

    return setmetatable(scene, InventoryScene)
end

---Initialize scene state when entering
function InventoryScene:enter()
    self.itemRects = {}
    self.equipmentRects = {}
    self.inventoryGridBottomY = nil
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

    -- Iterate through all render systems
    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

---Handle keyboard input
---@param key string Key pressed
function InventoryScene:keypressed(key)
    if key == "g" then
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

return InventoryScene
