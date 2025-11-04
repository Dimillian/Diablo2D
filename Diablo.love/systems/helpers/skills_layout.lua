local SkillsLayout = {}

local function snap(value)
    return math.floor(value + 0.5)
end

function SkillsLayout.calculatePanel()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelWidth = snap(screenWidth * 0.6)
    local panelHeight = snap(screenHeight * 0.65)
    local panelX = snap((screenWidth - panelWidth) / 2)
    local panelY = snap((screenHeight - panelHeight) / 2)

    return {
        screenWidth = screenWidth,
        screenHeight = screenHeight,
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        panelX = panelX,
        panelY = panelY,
    }
end

function SkillsLayout.calculateColumns(panel)
    local headerY = snap(panel.panelY + 20)
    local dividerX = snap(panel.panelX + panel.panelWidth * 0.5)
    local slotsX = snap(panel.panelX + 24)
    local listX = snap(dividerX + 24)

    return {
        headerY = headerY,
        dividerX = dividerX,
        listX = listX,
        slotsX = slotsX,
    }
end

function SkillsLayout.calculateListArea(panel, columns)
    local listWidth = panel.panelX + panel.panelWidth - columns.dividerX - 36
    local listTop = snap(columns.headerY + 40)
    local itemHeight = 48
    return {
        x = columns.listX,
        y = listTop,
        width = listWidth,
        itemHeight = itemHeight,
        spacing = 12,
    }
end

function SkillsLayout.calculateSlotsArea(_panel, columns)
    local slotsTop = snap(columns.headerY + 48)
    local slotSize = 48
    local slotSpacing = 16

    return {
        x = columns.slotsX,
        y = slotsTop,
        slotSize = slotSize,
        slotSpacing = slotSpacing,
    }
end

return SkillsLayout
