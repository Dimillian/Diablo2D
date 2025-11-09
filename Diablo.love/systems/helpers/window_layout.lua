---Generic window layout helper for modal scenes (inventory, skills, etc).
local WindowLayout = {}

local DEFAULTS = {
    widthRatio = 0.8,
    heightRatio = 0.8,
    headerHeight = 72,
    footerHeight = 0,
    padding = 24,
    footerSpacing = 16,
    iconSize = 40,
    closeButtonSize = 28,
}

-- Header elements always use 16px padding from edges, regardless of content padding
local HEADER_PADDING = 16

local function snap(value)
    return math.floor(value + 0.5)
end

---Calculate full window layout (panel, header, content, footer).
---@param opts table|nil Optional layout overrides.
---@return table layout Calculated layout information.
function WindowLayout.calculate(opts)
    opts = opts or {}

    local screenWidth, screenHeight = love.graphics.getDimensions()

    local widthRatio = opts.widthRatio or DEFAULTS.widthRatio
    local heightRatio = opts.heightRatio or DEFAULTS.heightRatio
    local padding = opts.padding or DEFAULTS.padding
    local headerHeight = snap(opts.headerHeight or DEFAULTS.headerHeight)
    local footerHeight = snap(opts.footerHeight or DEFAULTS.footerHeight)
    local footerSpacing = footerHeight > 0 and (opts.footerSpacing or DEFAULTS.footerSpacing) or 0
    local iconSize = opts.iconSize or DEFAULTS.iconSize
    local closeButtonSize = opts.closeButtonSize or DEFAULTS.closeButtonSize

    local panelWidth = snap(screenWidth * widthRatio)
    local panelHeight = snap(screenHeight * heightRatio)
    local panelX = snap((screenWidth - panelWidth) / 2)
    local panelY = snap((screenHeight - panelHeight) / 2)

    local contentWidth = panelWidth - padding * 2
    local contentHeight = panelHeight - headerHeight - footerHeight - padding * 2 - footerSpacing
    if contentHeight < 0 then
        contentHeight = 0
    end

    local headerY = panelY
    local headerIconSize = math.min(iconSize, headerHeight - HEADER_PADDING)
    local iconY = headerY + (headerHeight - headerIconSize) / 2
    local iconX = panelX + HEADER_PADDING
    local titleX = iconX + headerIconSize + 12
    local titleY = headerY + headerHeight / 2

    local closeX = panelX + panelWidth - HEADER_PADDING - closeButtonSize
    local closeY = headerY + (headerHeight - closeButtonSize) / 2

    local contentX = panelX + padding
    local contentY = headerY + headerHeight + padding

    local footer = nil
    if footerHeight > 0 then
        local footerPadding = opts.footerPadding or padding
        local footerY = panelY + panelHeight - footerHeight - footerPadding
        footer = {
            x = panelX + padding,
            y = footerY,
            width = contentWidth,
            height = footerHeight,
        }
    end

    return {
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        panelX = panelX,
        panelY = panelY,
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        padding = padding,
        headerHeight = headerHeight,
        footerHeight = footerHeight,
        footerSpacing = footerSpacing,
        content = {
            x = contentX,
            y = contentY,
            width = contentWidth,
            height = contentHeight,
        },
        header = {
            x = panelX,
            y = headerY,
            width = panelWidth,
            height = headerHeight,
            iconSize = headerIconSize,
            iconX = iconX,
            iconY = iconY,
            titleX = titleX,
            titleY = titleY,
            closeX = closeX,
            closeY = closeY,
            closeSize = closeButtonSize,
        },
        footer = footer,
        options = opts,
    }
end

---Calculate column areas inside the window content region.
---@param layout table Layout returned by WindowLayout.calculate.
---@param opts table|nil Column options { leftRatio, spacing }.
---@return table columns Column information with left/right rectangles and dividerX.
function WindowLayout.calculateColumns(layout, opts)
    opts = opts or {}
    local content = layout.content
    local spacing = opts.spacing or layout.padding
    local leftRatio = opts.leftRatio or 0.45

    local leftWidth = snap(content.width * leftRatio)
    if leftWidth > content.width - spacing then
        leftWidth = content.width - spacing
    end
    local rightWidth = content.width - leftWidth - spacing
    if rightWidth < 0 then
        rightWidth = 0
    end

    local leftX = content.x
    local rightX = leftX + leftWidth + spacing
    local dividerX = rightX - spacing / 2

    return {
        left = {
            x = leftX,
            y = content.y,
            width = leftWidth,
            height = content.height,
        },
        right = {
            x = rightX,
            y = content.y,
            width = rightWidth,
            height = content.height,
        },
        dividerX = dividerX,
        spacing = spacing,
    }
end

---Split a rectangle vertically into two sections.
---@param area table Rectangle { x, y, width, height }.
---@param opts table|nil Options { ratio, spacing }.
---@param defaultSpacing number|nil Default spacing fallback.
---@return table topArea, table bottomArea
function WindowLayout.splitVertical(area, opts, defaultSpacing)
    opts = opts or {}
    local spacing = opts.spacing or defaultSpacing or 16
    local ratio = opts.ratio or 0.6

    local availableHeight = area.height - spacing
    if availableHeight < 0 then
        availableHeight = 0
        spacing = 0
    end

    local topHeight = snap(availableHeight * ratio)
    local bottomHeight = availableHeight - topHeight

    local topArea = {
        x = area.x,
        y = area.y,
        width = area.width,
        height = topHeight,
    }

    local bottomArea = {
        x = area.x,
        y = area.y + topHeight + spacing,
        width = area.width,
        height = bottomHeight,
    }

    return topArea, bottomArea
end

WindowLayout.snap = snap

return WindowLayout
