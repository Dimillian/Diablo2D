---Centralized input management system for key bindings and action mapping.
---Enables future key rebinding and settings screen support.
local InputActions = require("modules.input_actions")

local InputManager = {}

-- Default key bindings: action name -> array of Love2D key strings
local defaultBindings = {
    -- Movement (continuous)
    [InputActions.MOVE_LEFT] = { "left", "a", "q" },
    [InputActions.MOVE_RIGHT] = { "right", "d" },
    [InputActions.MOVE_UP] = { "up", "w", "z" },
    [InputActions.MOVE_DOWN] = { "down", "s" },

    -- Skills
    [InputActions.SKILL_1] = { "1" },
    [InputActions.SKILL_2] = { "2" },
    [InputActions.SKILL_3] = { "3" },
    [InputActions.SKILL_4] = { "4" },

    -- Potions
    [InputActions.POTION_HEALTH] = { "5" },
    [InputActions.POTION_MANA] = { "6" },

    -- UI
    [InputActions.TOGGLE_INVENTORY] = { "i" },
    [InputActions.TOGGLE_SKILLS] = { "k" },
    [InputActions.TOGGLE_WORLD_MAP] = { "m" },
    [InputActions.CLOSE_MODAL] = { "escape" },

    -- Debug
    [InputActions.DEBUG_TOGGLE] = { "t" },
    [InputActions.DEBUG_CHUNKS] = { "f7" },
    [InputActions.RESET_WORLD] = { "f5" },

    -- Minimap
    [InputActions.MINIMAP_TOGGLE] = {},
    [InputActions.MINIMAP_ZOOM_IN] = { "]" },
    [InputActions.MINIMAP_ZOOM_OUT] = { "[" },

    -- Dev
    [InputActions.INVENTORY_TEST_ITEM] = { "g" },

    -- Mouse (button numbers)
    [InputActions.MOUSE_PRIMARY] = { 1 },
    [InputActions.MOUSE_SECONDARY] = { 2 },
}

-- Current bindings (can be modified for rebinding)
local bindings = {}

-- Track pressed keys for this frame (reset each update)
local pressedKeysThisFrame = {}

---Initialize bindings with defaults (called automatically on first use)
local function initializeBindings()
    if next(bindings) == nil then
        for action, keys in pairs(defaultBindings) do
            bindings[action] = {}
            for _, key in ipairs(keys) do
                bindings[action][#bindings[action] + 1] = key
            end
        end
    end
end

---Get the keys bound to an action.
---@param actionName string Action name constant from InputActions
---@return table|nil Array of key strings/numbers, or nil if action not found
local function getKeysForAction(actionName)
    initializeBindings()
    return bindings[actionName]
end

---Check if any key bound to an action is currently held down.
---@param actionName string Action name constant from InputActions
---@return boolean True if any bound key is down
function InputManager.isActionDown(actionName)
    local keys = getKeysForAction(actionName)
    if not keys then
        return false
    end

    -- Handle mouse buttons
    if actionName == InputActions.MOUSE_PRIMARY or actionName == InputActions.MOUSE_SECONDARY then
        for _, button in ipairs(keys) do
            if love.mouse.isDown(button) then
                return true
            end
        end
        return false
    end

    -- Handle keyboard keys
    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end

    return false
end

---Check if any key bound to an action was pressed this frame.
---Call update() each frame to reset pressed state.
---@param actionName string Action name constant from InputActions
---@return boolean True if any bound key was pressed this frame
function InputManager.isActionPressed(actionName)
    local keys = getKeysForAction(actionName)
    if not keys then
        return false
    end

    -- Handle mouse buttons
    if actionName == InputActions.MOUSE_PRIMARY or actionName == InputActions.MOUSE_SECONDARY then
        for _, button in ipairs(keys) do
            if pressedKeysThisFrame[button] then
                return true
            end
        end
        return false
    end

    -- Handle keyboard keys
    for _, key in ipairs(keys) do
        if pressedKeysThisFrame[key] then
            return true
        end
    end

    return false
end

---Get the primary (first) key bound to an action for display purposes.
---@param actionName string Action name constant from InputActions
---@return string|number|nil Primary key, or nil if action not found
function InputManager.getActionKey(actionName)
    local keys = getKeysForAction(actionName)
    if not keys or #keys == 0 then
        return nil
    end
    return keys[1]
end

---Convert a Love2D key string to an action name.
---Returns the first matching action, or nil if no action is bound to this key.
---@param key string|number Love2D key string or mouse button number
---@return string|nil Action name, or nil if key not bound
function InputManager.getActionForKey(key)
    initializeBindings()
    for action, keys in pairs(bindings) do
        for _, boundKey in ipairs(keys) do
            if boundKey == key then
                return action
            end
        end
    end
    return nil
end

---Register a key press for this frame.
---Called by main.lua love.keypressed and love.mousepressed handlers.
---@param key string|number Love2D key string or mouse button number
function InputManager.registerPress(key)
    pressedKeysThisFrame[key] = true
end

---Register a key release.
---Called by main.lua love.keyreleased and love.mousereleased handlers.
---@param key string|number Love2D key string or mouse button number
function InputManager.registerRelease(key)
    -- Key release tracking (currently unused but kept for future use)
    pressedKeysThisFrame[key] = false
end

---Update input state (call once per frame).
---Resets pressed keys for this frame.
function InputManager.update()
    pressedKeysThisFrame = {}
end

---Get current bindings (for future settings persistence).
---@return table Copy of current bindings table
function InputManager.getBindings()
    initializeBindings()
    local copy = {}
    for action, keys in pairs(bindings) do
        copy[action] = {}
        for _, key in ipairs(keys) do
            copy[action][#copy[action] + 1] = key
        end
    end
    return copy
end

---Set bindings (for future settings/rebinding).
---@param newBindings table Action name -> array of key strings/numbers
function InputManager.setBindings(newBindings)
    bindings = {}
    for action, keys in pairs(newBindings) do
        bindings[action] = {}
        for _, key in ipairs(keys) do
            bindings[action][#bindings[action] + 1] = key
        end
    end
end

return InputManager
