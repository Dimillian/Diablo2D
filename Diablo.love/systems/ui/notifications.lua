local notificationBus = require("modules.notification_bus")
local Resources = require("modules.resources")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")

local notificationsSystem = {}

local CARD_WIDTH = 320
local CARD_PADDING = 12
local CARD_SPACING = 10
local ICON_SIZE = 32
local ENTER_OFFSET = 32
local TOP_MARGIN = 24
local RIGHT_MARGIN = 24
local MINIMAP_SIZE = 150
local MINIMAP_PADDING = 16
local MINIMAP_STACK_GAP = 16

local ACTION_HANDLERS = {
    open_inventory = function(world)
        if not world or not world.sceneManager then
            return
        end

        local inventoryKey = InputManager.getActionKey(InputActions.TOGGLE_INVENTORY)
        world.sceneManager:toggleInventory(inventoryKey)
    end,
}

local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

local function triggerNotificationAction(world, notification)
    if not notification or not notification.onClickAction then
        return
    end

    local handler = ACTION_HANDLERS[notification.onClickAction]
    if handler then
        handler(world, notification)
    end
end

local function computeCardHeight(notification, font)
    local lineHeight = font:getHeight()
    local bodyCount = #notification.bodyLines
    local totalTextHeight = lineHeight

    if bodyCount > 0 then
        totalTextHeight = totalTextHeight + bodyCount * (lineHeight - 2)
    end

    local textHeight = math.max(totalTextHeight, ICON_SIZE)
    return textHeight + CARD_PADDING * 2
end

local function pointInRect(x, y, rect)
    return rect
        and x >= rect.x
        and x <= rect.x + rect.w
        and y >= rect.y
        and y <= rect.y + rect.h
end

function notificationsSystem.update(world, dt)
    notificationBus.update(world, dt)

    if not (love and love.graphics and love.graphics.getWidth) then
        return
    end

    local active = notificationBus.getActive(world)
    if not active or #active == 0 then
        return
    end

    local font = love.graphics.getFont()
    local screenWidth = love.graphics.getWidth()
    local minimapState = world.minimapState
    local minimapVisible = minimapState == nil or minimapState.visible ~= false

    local baseX
    local cursorY

    if minimapVisible and world.chunkManager then
        baseX = math.max(RIGHT_MARGIN, screenWidth - MINIMAP_PADDING - CARD_WIDTH)
        cursorY = MINIMAP_PADDING + MINIMAP_SIZE + MINIMAP_STACK_GAP
    else
        baseX = screenWidth - CARD_WIDTH - RIGHT_MARGIN
        cursorY = TOP_MARGIN
    end

    local mouseX, mouseY = 0, 0
    if love.mouse and love.mouse.getPosition then
        mouseX, mouseY = love.mouse.getPosition()
    end

    local primary = world.input
        and world.input.mouse
        and world.input.mouse.primary

    for _, entry in ipairs(active) do
        local notification = entry.notification
        local cardHeight = computeCardHeight(notification, font)
        local state = notification.state
        local enterDuration = notification.enterDuration > 0 and notification.enterDuration or 0.0001
        local exitDuration = notification.exitDuration > 0 and notification.exitDuration or 0.0001

        local targetX = baseX
        local alpha = 1

        if state == "enter" then
            local progress = math.min(notification.stateTime / enterDuration, 1)
            local eased = smoothstep(progress)
            targetX = baseX + (1 - eased) * ENTER_OFFSET
            alpha = eased
        elseif state == "exit" then
            local progress = math.min(notification.stateTime / exitDuration, 1)
            local eased = smoothstep(progress)
            targetX = baseX + eased * ENTER_OFFSET
            alpha = 1 - eased
        end

        notification.renderX = targetX
        notification.renderY = cursorY
        notification.renderWidth = CARD_WIDTH
        notification.renderHeight = cardHeight
        notification.renderAlpha = alpha

        local cardRect = {
            x = targetX,
            y = cursorY,
            w = CARD_WIDTH,
            h = cardHeight,
        }

        entry.rect = cardRect

        local closeSize = 16
        local closeRect = {
            x = targetX + CARD_WIDTH - closeSize - CARD_PADDING,
            y = cursorY + CARD_PADDING,
            w = closeSize,
            h = closeSize,
        }
        entry.closeRect = closeRect

        local isCardHovered = pointInRect(mouseX, mouseY, cardRect)
        local isCloseHovered = pointInRect(mouseX, mouseY, closeRect)

        entry.closeHovered = isCloseHovered
        notification.hovered = isCardHovered or isCloseHovered

        if primary
            and primary.pressed
            and (primary.consumedClickId == nil or primary.consumedClickId == primary.clickId)
            and isCloseHovered
            and notification.renderAlpha > 0
        then
            notificationBus.dismiss(world, notification.id, "click")
            primary.consumedClickId = primary.clickId
        elseif primary
            and primary.pressed
            and (primary.consumedClickId == nil or primary.consumedClickId == primary.clickId)
            and isCardHovered
            and not isCloseHovered
            and notification.renderAlpha > 0
        then
            triggerNotificationAction(world, notification)
            notificationBus.dismiss(world, notification.id, "click")
            primary.consumedClickId = primary.clickId
        end

        cursorY = cursorY + cardHeight + CARD_SPACING
    end
end

function notificationsSystem.draw(world)
    if not (love and love.graphics and love.graphics.getWidth) then
        return
    end

    local active = notificationBus.getActive(world)
    if not active or #active == 0 then
        return
    end

    love.graphics.push("all")

    local font = love.graphics.getFont()

    for _, entry in ipairs(active) do
        local notification = entry.notification
        local alpha = notification.renderAlpha or 0

        if alpha > 0 then
            local x = notification.renderX or 0
            local y = notification.renderY or 0
            local width = notification.renderWidth or CARD_WIDTH
            local height = notification.renderHeight or computeCardHeight(notification, font)

            local hovered = notification.hovered
            local baseBg = hovered and 0.16 or 0.1
            love.graphics.setColor(baseBg, baseBg, baseBg, 0.85 * alpha)
            love.graphics.rectangle("fill", x, y, width, height, 8, 8)

            love.graphics.setLineWidth(2)
            love.graphics.setColor(0.75, 0.7, 0.5, 0.9 * alpha)
            love.graphics.rectangle("line", x, y, width, height, 8, 8)

            local icon = notification.iconPath and Resources.loadImageSafe(notification.iconPath)
            if icon then
                local iconScale = math.min(
                    ICON_SIZE / icon:getWidth(),
                    ICON_SIZE / icon:getHeight()
                )
                local iconDrawHeight = icon:getHeight() * iconScale
                local iconX = x + CARD_PADDING
                local iconY = y + CARD_PADDING + (ICON_SIZE - iconDrawHeight) / 2

                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(icon, iconX, iconY, 0, iconScale, iconScale)
            end

            local textX = x + CARD_PADDING + ICON_SIZE + 10
            local textY = y + CARD_PADDING

            love.graphics.setColor(0.96, 0.9, 0.74, alpha)
            love.graphics.print(notification.title, textX, textY)

            textY = textY + font:getHeight()
            love.graphics.setColor(0.85, 0.82, 0.76, 0.9 * alpha)

            for _, line in ipairs(notification.bodyLines) do
                love.graphics.print(line, textX, textY)
                textY = textY + font:getHeight() - 2
            end

            local closeRect = entry.closeRect
            if closeRect then
                local cx = closeRect.x + closeRect.w / 2
                local cy = closeRect.y + closeRect.h / 2
                local offset = closeRect.w / 2 - 2

                local crossColor = entry.closeHovered and { 0.95, 0.5, 0.4, alpha } or { 0.8, 0.75, 0.6, alpha }
                love.graphics.setColor(crossColor)
                love.graphics.setLineWidth(2)
                love.graphics.line(cx - offset, cy - offset, cx + offset, cy + offset)
                love.graphics.line(cx - offset, cy + offset, cx + offset, cy - offset)
            end
        end
    end

    love.graphics.pop()
end

return notificationsSystem
