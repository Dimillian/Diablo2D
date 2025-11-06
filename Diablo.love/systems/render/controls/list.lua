local ActionNames = require("modules.action_names")
local InputManager = require("modules.input_manager")
local ScrollableContent = require("systems.helpers.scrollable_content")

local renderControlsList = {}

local LINE_HEIGHT = 24
local CATEGORY_SPACING = 8
local ITEM_SPACING = 4
local LEFT_PADDING = 20
local RIGHT_PADDING = 20
local TOP_PADDING = 20

---Calculate total content height needed for all controls.
---@param bindings table Input bindings
---@return number totalHeight Total height needed
local function calculateContentHeight(bindings)
    local categories = {}

    -- Group actions by category
    for action, keys in pairs(bindings) do
        local category = ActionNames.getCategory(action)
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category], {
            action = action,
            keys = keys,
        })
    end

    -- Sort categories
    local categoryOrder = { "Movement", "Skills", "Potions", "UI", "Minimap", "Mouse", "Debug", "Development", "Other" }
    local sortedCategories = {}
    for _, catName in ipairs(categoryOrder) do
        if categories[catName] then
            table.insert(sortedCategories, { name = catName, actions = categories[catName] })
        end
    end

    -- Add any remaining categories
    for catName, actions in pairs(categories) do
        local found = false
        for _, cat in ipairs(sortedCategories) do
            if cat.name == catName then
                found = true
                break
            end
        end
        if not found then
            table.insert(sortedCategories, { name = catName, actions = actions })
        end
    end

    -- Calculate total height
    local totalHeight = TOP_PADDING
    for _, category in ipairs(sortedCategories) do
        -- Category header
        totalHeight = totalHeight + LINE_HEIGHT + CATEGORY_SPACING

        -- Category items
        for _ = 1, #category.actions do
            totalHeight = totalHeight + LINE_HEIGHT + ITEM_SPACING
        end

        totalHeight = totalHeight + CATEGORY_SPACING
    end

    return totalHeight
end

function renderControlsList.draw(scene)
    local layout = scene.windowLayout
    if not layout or not layout.content then
        return
    end

    local contentX = layout.content.x
    local contentY = layout.content.y
    local contentWidth = layout.content.width
    local contentHeight = layout.content.height

    local bindings = InputManager.getBindings()
    local font = love.graphics.getFont()

    -- Calculate total content height and initialize scroll state if needed
    local totalContentHeight = calculateContentHeight(bindings)
    if not scene.scrollState then
        ScrollableContent.init(scene, contentHeight, totalContentHeight)
    else
        -- Update scroll state with current dimensions
        scene.scrollState.viewportHeight = contentHeight
        scene.scrollState.contentHeight = totalContentHeight
        ScrollableContent.updateBounds(scene.scrollState)
    end

    local scrollState = scene.scrollState

    -- Adjust content width to leave space for scrollbar when scrolling is needed
    local effectiveContentWidth = contentWidth
    if ScrollableContent.needsScrolling(scrollState) then
        -- Reserve space for scrollbar: width (8) + margin (12) = 20px
        effectiveContentWidth = contentWidth - 20
    end

    -- Apply scissor to clip content to viewport
    local scissorX, scissorY, scissorW, scissorH = ScrollableContent.getVisibleArea(
        scrollState,
        contentX,
        contentY,
        contentWidth
    )
    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH)

    -- Group actions by category
    local categories = {}
    for action, keys in pairs(bindings) do
        local category = ActionNames.getCategory(action)
        if not categories[category] then
            categories[category] = {}
        end
        table.insert(categories[category], {
            action = action,
            keys = keys,
        })
    end

    -- Sort categories
    local categoryOrder = { "Movement", "Skills", "Potions", "UI", "Minimap", "Mouse", "Debug", "Development", "Other" }
    local sortedCategories = {}
    for _, catName in ipairs(categoryOrder) do
        if categories[catName] then
            table.insert(sortedCategories, { name = catName, actions = categories[catName] })
        end
    end

    -- Add any remaining categories
    for catName, actions in pairs(categories) do
        local found = false
        for _, cat in ipairs(sortedCategories) do
            if cat.name == catName then
                found = true
                break
            end
        end
        if not found then
            table.insert(sortedCategories, { name = catName, actions = actions })
        end
    end

    -- Draw content with scroll offset
    local y = contentY + TOP_PADDING - scrollState.scrollY

    for _, category in ipairs(sortedCategories) do
        -- Category header
        love.graphics.setColor(0.95, 0.9, 0.7, 1)
        love.graphics.setFont(font)
        love.graphics.print(category.name .. ":", contentX + LEFT_PADDING, y)
        y = y + LINE_HEIGHT + CATEGORY_SPACING

        -- Category items
        for _, item in ipairs(category.actions) do
            local displayName = ActionNames.getDisplayName(item.action)

            -- Format keys
            local keyStrings = {}
            for _, key in ipairs(item.keys) do
                table.insert(keyStrings, ActionNames.formatKey(key))
            end
            local keysText = table.concat(keyStrings, ", ")

            -- Action name
            love.graphics.setColor(0.85, 0.8, 0.75, 1)
            love.graphics.print(displayName, contentX + LEFT_PADDING + 20, y)

            -- Keys (right-aligned)
            local keysWidth = font:getWidth(keysText)
            love.graphics.setColor(0.7, 0.65, 0.6, 1)
            love.graphics.print(keysText, contentX + effectiveContentWidth - RIGHT_PADDING - keysWidth, y)

            y = y + LINE_HEIGHT + ITEM_SPACING
        end

        y = y + CATEGORY_SPACING
    end

    -- Reset scissor
    love.graphics.setScissor()
end

return renderControlsList
