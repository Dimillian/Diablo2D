local Notification = require("entities.notification")

local notificationBus = {}

local DEFAULT_TTL = 5
local MAX_ACTIVE = 4
local DEFAULT_ENTER_DURATION = 0.2
local DEFAULT_EXIT_DURATION = 0.25

local function cloneBodyLines(lines)
    if not lines then
        return {}
    end

    local copy = {}
    for index, value in ipairs(lines) do
        copy[index] = tostring(value)
    end
    return copy
end

local function ensureState(world)
    assert(world, "notification_bus.ensureState requires a world reference")

    world.notifications = world.notifications or {}
    local state = world.notifications

    state.pending = state.pending or {}
    state.active = state.active or {}
    state.lookup = state.lookup or {}
    state.nextSequence = state.nextSequence or 1
    state.nextEntityId = state.nextEntityId or 1
    state.maxActive = state.maxActive or MAX_ACTIVE

    return state
end

local function findPendingByCategory(state, category)
    if not category then
        return nil
    end

    for index, entry in ipairs(state.pending) do
        if entry.payload.category == category then
            return index, entry
        end
    end

    return nil
end

local function findActiveByCategory(state, category)
    if not category then
        return nil
    end

    for _, entry in ipairs(state.active) do
        if entry.notification.category == category then
            return entry
        end
    end

    return nil
end

local function applyPayloadToNotification(entry, payload, sequence)
    local notification = entry.notification

    notification.title = payload.title or notification.title
    notification.bodyLines = cloneBodyLines(payload.bodyLines)
    notification.iconPath = payload.iconPath
    notification.priority = payload.priority or 0
    notification.ttl = payload.ttl or DEFAULT_TTL
    notification.onClickAction = payload.onClickAction
    notification.enterDuration = payload.enterDuration or DEFAULT_ENTER_DURATION
    notification.exitDuration = payload.exitDuration or DEFAULT_EXIT_DURATION
    notification.allowDuplicates = payload.allowDuplicates or false

    notification.timeElapsed = 0
    notification.state = "enter"
    notification.stateTime = 0
    notification.dismissRequested = false
    notification.sequence = sequence

    entry.sequence = sequence
end

local function normalizePayload(payload, sequence)
    assert(type(payload) == "table", "notification payload must be a table")
    assert(payload.title, "notification payload requires a title")

    return {
        id = payload.id or ("notification_" .. tostring(sequence)),
        category = payload.category,
        title = payload.title,
        bodyLines = cloneBodyLines(payload.bodyLines),
        iconPath = payload.iconPath or payload.icon,
        priority = payload.priority or 0,
        ttl = payload.ttl or DEFAULT_TTL,
        onClickAction = payload.onClickAction,
        enterDuration = payload.enterDuration or DEFAULT_ENTER_DURATION,
        exitDuration = payload.exitDuration or DEFAULT_EXIT_DURATION,
        allowDuplicates = payload.allowDuplicates or false,
        sequence = sequence,
    }
end

local function selectNextPending(state)
    local bestIndex
    local bestEntry

    for index, entry in ipairs(state.pending) do
        if not bestEntry then
            bestIndex = index
            bestEntry = entry
        else
            local currentPriority = entry.payload.priority or 0
            local bestPriority = bestEntry.payload.priority or 0

            if currentPriority > bestPriority then
                bestIndex = index
                bestEntry = entry
            elseif currentPriority == bestPriority and entry.sequence < bestEntry.sequence then
                bestIndex = index
                bestEntry = entry
            end
        end
    end

    return bestIndex, bestEntry
end

local function promotePending(world, state)
    while #state.active < state.maxActive do
        local pendingIndex, pendingEntry = selectNextPending(state)
        if not pendingEntry then
            break
        end

        table.remove(state.pending, pendingIndex)

        local entityId = "notification_entity_" .. tostring(state.nextEntityId)
        state.nextEntityId = state.nextEntityId + 1

        local entity = Notification.new({
            id = entityId,
            notification = pendingEntry.payload,
        })

        world:addEntity(entity)

        local entry = {
            entityId = entityId,
            notification = entity.notification,
            sequence = pendingEntry.sequence,
        }

        state.active[#state.active + 1] = entry
        state.lookup[entity.notification.id] = entry
    end
end

local function rebuildCategoryLookup(state)
    state.categoryLookup = {}
    for _, entry in ipairs(state.active) do
        if entry.notification.category then
            state.categoryLookup[entry.notification.category] = entry
        end
    end
end

local function advanceNotificationState(notification, dt)
    notification.timeElapsed = notification.timeElapsed + dt
    notification.stateTime = notification.stateTime + dt

    if notification.state == "enter" then
        if notification.stateTime >= (notification.enterDuration or DEFAULT_ENTER_DURATION) then
            notification.state = "idle"
            notification.stateTime = 0
        end
        return false
    end

    if notification.state == "idle" then
        local shouldExit = notification.dismissRequested
            or notification.timeElapsed >= (notification.ttl or DEFAULT_TTL)

        if shouldExit then
            notification.state = "exit"
            notification.stateTime = 0
            notification.dismissRequested = false
        end
        return false
    end

    if notification.state == "exit" then
        local exitDuration = notification.exitDuration or DEFAULT_EXIT_DURATION
        if notification.stateTime >= exitDuration then
            return true
        end
    end

    return false
end

local function removeActiveEntry(world, state, index)
    local entry = state.active[index]
    local notification = entry.notification

    state.lookup[notification.id] = nil

    world:removeEntity(entry.entityId)
    table.remove(state.active, index)
end

function notificationBus.queue(world, payload)
    local state = ensureState(world)
    local sequence = state.nextSequence
    state.nextSequence = state.nextSequence + 1

    local normalized = normalizePayload(payload, sequence)

    if normalized.id then
        local existingById = state.lookup[normalized.id]
        if existingById and not normalized.allowDuplicates then
            applyPayloadToNotification(existingById, normalized, sequence)
            return normalized.id
        end

        for _, pendingEntry in ipairs(state.pending) do
            if pendingEntry.componentId == normalized.id and not normalized.allowDuplicates then
                pendingEntry.payload = normalized
                pendingEntry.sequence = sequence
                return normalized.id
            end
        end
    end

    if normalized.category and not normalized.allowDuplicates then
        local activeEntry = findActiveByCategory(state, normalized.category)
        if activeEntry then
            normalized.id = activeEntry.notification.id
            applyPayloadToNotification(activeEntry, normalized, sequence)
            rebuildCategoryLookup(state)
            return normalized.id
        end

        local _, pendingEntry = findPendingByCategory(state, normalized.category)
        if pendingEntry then
            normalized.id = pendingEntry.componentId
            pendingEntry.payload = normalized
            pendingEntry.sequence = sequence
            return pendingEntry.componentId
        end
    end

    state.pending[#state.pending + 1] = {
        payload = normalized,
        sequence = sequence,
        componentId = normalized.id,
    }

    return normalized.id
end

function notificationBus.update(world, dt)
    local state = ensureState(world)
    dt = dt or 0

    promotePending(world, state)

    for index = #state.active, 1, -1 do
        local entry = state.active[index]
        if advanceNotificationState(entry.notification, dt) then
            removeActiveEntry(world, state, index)
        end
    end

    rebuildCategoryLookup(state)
    promotePending(world, state)

    table.sort(state.active, function(a, b)
        local priorityA = a.notification.priority or 0
        local priorityB = b.notification.priority or 0
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end
        return a.sequence < b.sequence
    end)

    for index, entry in ipairs(state.active) do
        entry.order = index
        entry.notification.sequence = entry.sequence
    end
end

function notificationBus.dismiss(world, identifier, _reason)
    local state = ensureState(world)
    if not identifier then
        return
    end

    local entry = state.lookup[identifier]
    if entry then
        entry.notification.dismissRequested = true
        return
    end

    local categoryEntry = state.categoryLookup and state.categoryLookup[identifier]
    if categoryEntry then
        categoryEntry.notification.dismissRequested = true
        return
    end

    for _, pendingEntry in ipairs(state.pending) do
        if pendingEntry.componentId == identifier or pendingEntry.payload.category == identifier then
            pendingEntry.payload.dismissRequested = true
            pendingEntry.payload.ttl = 0
        end
    end
end

function notificationBus.clear(world, category)
    local state = ensureState(world)

    if category == nil then
        for index = #state.active, 1, -1 do
            local entry = state.active[index]
            if entry then
                world:removeEntity(entry.entityId)
                state.lookup[entry.notification.id] = nil
            end
            state.active[index] = nil
        end

        state.pending = {}
        state.categoryLookup = {}
        return
    end

    for index = #state.active, 1, -1 do
        local entry = state.active[index]
        if entry.notification.category == category then
            world:removeEntity(entry.entityId)
            state.lookup[entry.notification.id] = nil
            table.remove(state.active, index)
        end
    end

    for index = #state.pending, 1, -1 do
        if state.pending[index].payload.category == category then
            table.remove(state.pending, index)
        end
    end

    rebuildCategoryLookup(state)
end

function notificationBus.getState(world)
    return ensureState(world)
end

function notificationBus.getActive(world)
    local state = ensureState(world)
    return state.active
end

return notificationBus
