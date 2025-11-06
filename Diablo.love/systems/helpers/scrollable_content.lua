---Generic scrollable content helper for managing scroll state in scenes.
---Provides scroll position tracking, bounds clamping, and viewport calculations.
local ScrollableContent = {}

---Initialize scroll state for a scene.
---@param scene table Scene object to attach scroll state to
---@param viewportHeight number Height of visible area
---@param contentHeight number Total height of scrollable content
---@return table scrollState Initialized scroll state
function ScrollableContent.init(scene, viewportHeight, contentHeight)
    local scrollState = {
        scrollY = 0,
        viewportHeight = viewportHeight,
        contentHeight = contentHeight,
    }
    scene.scrollState = scrollState
    ScrollableContent.updateBounds(scrollState)
    return scrollState
end

---Update scroll bounds based on current content and viewport heights.
---@param scrollState table Scroll state to update
function ScrollableContent.updateBounds(scrollState)
    scrollState.maxScrollY = math.max(0, scrollState.contentHeight - scrollState.viewportHeight)
    -- Clamp current scroll position to new bounds
    if scrollState.scrollY > scrollState.maxScrollY then
        scrollState.scrollY = scrollState.maxScrollY
    end
    if scrollState.scrollY < 0 then
        scrollState.scrollY = 0
    end
end

---Update scroll position by delta amount.
---@param scrollState table Scroll state to update
---@param dy number Delta Y (positive = scroll down, negative = scroll up)
---@param scrollSpeed number|nil Optional scroll speed multiplier (default: 30)
function ScrollableContent.updateScroll(scrollState, dy, scrollSpeed)
    scrollSpeed = scrollSpeed or 30
    local delta = dy * scrollSpeed

    scrollState.scrollY = scrollState.scrollY + delta
    scrollState.scrollY = math.max(0, math.min(scrollState.scrollY, scrollState.maxScrollY))
end

---Get the visible area rectangle for clipping.
---@param scrollState table Scroll state
---@param contentX number X position of content area
---@param contentY number Y position of content area
---@param contentWidth number Width of content area
---@return number x, number y, number width, number height Visible area coordinates
function ScrollableContent.getVisibleArea(scrollState, contentX, contentY, contentWidth)
    return contentX, contentY, contentWidth, scrollState.viewportHeight
end

---Check if scrolling is needed (content exceeds viewport).
---@param scrollState table Scroll state
---@return boolean True if scrolling is needed
function ScrollableContent.needsScrolling(scrollState)
    return scrollState.contentHeight > scrollState.viewportHeight
end

return ScrollableContent
