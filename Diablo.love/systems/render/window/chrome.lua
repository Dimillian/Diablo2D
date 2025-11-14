local Resources = require("modules.resources")
local WindowLayout = require("systems.helpers.window_layout")

local renderWindowChrome = {}

local function drawPanelGlow(layout)
    love.graphics.push("all")
    love.graphics.setBlendMode("add", "alphamultiply")

    local glowColor = { 1.0, 0.88, 0.55 }
    for i = 1, 3 do
        local growth = (4 - i) * 4
        local alpha = 0.12 / i
        local lineWidth = 10 + (3 - i) * 4
        love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], alpha)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.rectangle(
            "line",
            layout.panelX - growth,
            layout.panelY - growth,
            layout.panelWidth + growth * 2,
            layout.panelHeight + growth * 2,
            20 + growth,
            20 + growth
        )
    end

    love.graphics.pop()
end

local function drawCloseButton(layout, isHovered)
    local closeX = layout.header.closeX
    local closeY = layout.header.closeY
    local size = layout.header.closeSize
    local radius = 6

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", closeX, closeY, size, size, radius, radius)

    if isHovered then
        love.graphics.setColor(0.9, 0.3, 0.3, 0.8)
    else
        love.graphics.setColor(0.8, 0.75, 0.5, 1)
    end
    love.graphics.rectangle("line", closeX, closeY, size, size, radius, radius)

    local inset = 6
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(closeX + inset, closeY + inset, closeX + size - inset, closeY + size - inset)
    love.graphics.line(closeX + inset, closeY + size - inset, closeX + size - inset, closeY + inset)
end

---Draw the shared window chrome (overlay, panel, header, close button).
---@param scene table Scene owning the window.
---@param opts table Options { title, icon, layout = { ... }, columns = { ... } }.
function renderWindowChrome.draw(scene, opts)
    opts = opts or scene.windowChromeConfig or {}

    local layoutOptions = opts.layout or scene.windowLayoutOptions or {}
    local layout = WindowLayout.calculate(layoutOptions)
    scene.windowLayout = layout

    local columnOptions = opts.columns
    if columnOptions then
        layout.columns = WindowLayout.calculateColumns(layout, columnOptions)
    else
        layout.columns = nil
    end
    layout.columnOptions = columnOptions

    local mouseX, mouseY = love.mouse.getPosition()

    -- Dimmed backdrop
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, layout.screenWidth, layout.screenHeight)

    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle(
        "fill",
        layout.panelX,
        layout.panelY,
        layout.panelWidth,
        layout.panelHeight,
        10,
        10
    )

    drawPanelGlow(layout)

    -- Panel border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle(
        "line",
        layout.panelX,
        layout.panelY,
        layout.panelWidth,
        layout.panelHeight,
        10,
        10
    )

    -- Inner highlight to keep edges bright so CRT bloom catches them
    love.graphics.setColor(1.0, 0.95, 0.75, 0.25)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
        "line",
        layout.panelX + 3,
        layout.panelY + 3,
        layout.panelWidth - 6,
        layout.panelHeight - 6,
        8,
        8
    )

    -- Header divider (uses 16px header padding, not content padding)
    local headerPadding = 16
    local borderInset = math.max(2, math.floor(headerPadding * 0.125))

    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.4, 0.35, 0.25, 1)
    love.graphics.line(
        layout.panelX + borderInset,
        layout.header.y + layout.header.height,
        layout.panelX + layout.panelWidth - borderInset,
        layout.header.y + layout.header.height
    )

    -- Icon
    if opts.icon then
        local icon = Resources.loadUIIcon(opts.icon)
        if icon then
            local iconSize = layout.header.iconSize
            local scale = iconSize / math.max(icon:getWidth(), icon:getHeight())
            local drawWidth = icon:getWidth() * scale
            local drawHeight = icon:getHeight() * scale
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(
                icon,
                layout.header.iconX + (iconSize - drawWidth) / 2,
                layout.header.iconY + (iconSize - drawHeight) / 2,
                0,
                scale,
                scale
            )
        end
    end

    -- Title
    local font = love.graphics.getFont()
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local title = opts.title or scene.title or "Window"
    local titleX = layout.header.iconX + layout.header.iconSize + 12
    local titleY = layout.header.titleY - font:getHeight() / 2
    love.graphics.print(title, titleX, titleY)

    -- Column divider if supplied
    if layout.columns and layout.columns.dividerX then
        love.graphics.setColor(0.4, 0.35, 0.25, 1)
        love.graphics.setLineWidth(1.5)

        local columnConfig = layout.columnOptions or {}
        local defaultInset = math.max(4, borderInset)
        local topInset = columnConfig.topInset or defaultInset
        local bottomInset = columnConfig.bottomInset or defaultInset

        local contentTop = layout.content.y
        local contentBottom = layout.footer
            and layout.footer.y
            or (layout.content.y + layout.content.height)

        local dividerTop = contentTop + topInset
        local dividerBottom = contentBottom - bottomInset

        if dividerBottom < dividerTop then
            dividerBottom = dividerTop
        end

        love.graphics.line(
            layout.columns.dividerX,
            dividerTop,
            layout.columns.dividerX,
            dividerBottom
        )
    end

    local isCloseHovered = mouseX >= layout.header.closeX
        and mouseX <= layout.header.closeX + layout.header.closeSize
        and mouseY >= layout.header.closeY
        and mouseY <= layout.header.closeY + layout.header.closeSize

    drawCloseButton(layout, isCloseHovered)

    scene.windowRects = scene.windowRects or {}
    scene.windowRects.close = {
        x = layout.header.closeX,
        y = layout.header.closeY,
        w = layout.header.closeSize,
        h = layout.header.closeSize,
    }
end

return renderWindowChrome
