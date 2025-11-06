---Scrollbar renderer for scrollable content areas.
---Draws a visual scrollbar indicator on the right edge of content areas.
local ScrollableContent = require("systems.helpers.scrollable_content")

local renderScrollbar = {}

local SCROLLBAR_WIDTH = 8
local SCROLLBAR_MARGIN = 12
local SCROLLBAR_BG_COLOR = { 0.2, 0.2, 0.2, 0.5 }
local SCROLLBAR_THUMB_COLOR = { 0.6, 0.55, 0.45, 0.9 }

---Draw scrollbar for a scrollable content area.
---@param scene table Scene with scrollState and windowLayout
function renderScrollbar.draw(scene)
    local scrollState = scene.scrollState
    local layout = scene.windowLayout

    if not scrollState or not layout or not layout.content then
        return
    end

    -- Only show scrollbar if scrolling is needed
    if not ScrollableContent.needsScrolling(scrollState) then
        return
    end

    local content = layout.content
    local contentX = content.x
    local contentY = content.y
    local contentWidth = content.width
    local contentHeight = content.height

    -- Calculate scrollbar position (right edge of content area)
    local scrollbarX = contentX + contentWidth - SCROLLBAR_WIDTH - SCROLLBAR_MARGIN
    local scrollbarY = contentY
    local scrollbarHeight = contentHeight

    -- Calculate thumb size (proportional to visible area)
    local thumbHeight = scrollbarHeight * (scrollState.viewportHeight / scrollState.contentHeight)
    thumbHeight = math.max(12, thumbHeight) -- Minimum thumb height for visibility

    -- Calculate thumb position based on scroll offset
    local scrollRatio = 0
    if scrollState.maxScrollY > 0 then
        scrollRatio = scrollState.scrollY / scrollState.maxScrollY
    end
    local availableHeight = scrollbarHeight - thumbHeight
    local thumbY = scrollbarY + scrollRatio * availableHeight

    -- Draw scrollbar background
    love.graphics.setColor(SCROLLBAR_BG_COLOR)
    love.graphics.rectangle("fill", scrollbarX, scrollbarY, SCROLLBAR_WIDTH, scrollbarHeight, 2, 2)

    -- Draw scrollbar thumb
    love.graphics.setColor(SCROLLBAR_THUMB_COLOR)
    love.graphics.rectangle("fill", scrollbarX, thumbY, SCROLLBAR_WIDTH, thumbHeight, 2, 2)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return renderScrollbar
