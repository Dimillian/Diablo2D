local InventoryScene = {}
InventoryScene.__index = InventoryScene

function InventoryScene.new(opts)
    opts = opts or {}

    local scene = {
        inventory = opts.inventory or {},
        equipment = opts.equipment or {},
        title = opts.title or "Inventory",
        kind = "inventory",
    }

    return setmetatable(scene, InventoryScene)
end

function InventoryScene:enter()
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

    love.graphics.pop()
end

return InventoryScene
