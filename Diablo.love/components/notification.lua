local function createNotificationComponent(opts)
    opts = opts or {}

    return {
        id = opts.id,
        category = opts.category,
        title = opts.title or "",
        bodyLines = opts.bodyLines or {},
        iconPath = opts.iconPath,
        priority = opts.priority or 0,
        ttl = opts.ttl or 5,
        onClickAction = opts.onClickAction,
        timeElapsed = opts.timeElapsed or 0,
        state = opts.state or "enter",
        stateTime = opts.stateTime or 0,
        enterDuration = opts.enterDuration or 0.2,
        exitDuration = opts.exitDuration or 0.25,
        dismissRequested = opts.dismissRequested or false,
        allowDuplicates = opts.allowDuplicates or false,
        sequence = opts.sequence or 0,
        renderX = opts.renderX or 0,
        renderY = opts.renderY or 0,
        renderWidth = opts.renderWidth or 0,
        renderHeight = opts.renderHeight or 0,
        renderAlpha = opts.renderAlpha or 0,
        hovered = false,
    }
end

return createNotificationComponent
