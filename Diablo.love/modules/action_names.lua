---Helper function to convert action constants to human-readable names.
---@param action string Action constant from InputActions
---@return string Human-readable action name
local function getActionDisplayName(action)
    local InputActions = require("modules.input_actions")

    -- Movement
    if action == InputActions.MOVE_LEFT then
        return "Move Left"
    elseif action == InputActions.MOVE_RIGHT then
        return "Move Right"
    elseif action == InputActions.MOVE_UP then
        return "Move Up"
    elseif action == InputActions.MOVE_DOWN then
        return "Move Down"
    -- Skills
    elseif action == InputActions.SKILL_1 then
        return "Skill Slot 1"
    elseif action == InputActions.SKILL_2 then
        return "Skill Slot 2"
    elseif action == InputActions.SKILL_3 then
        return "Skill Slot 3"
    elseif action == InputActions.SKILL_4 then
        return "Skill Slot 4"
    -- Potions
    elseif action == InputActions.POTION_HEALTH then
        return "Health Potion"
    elseif action == InputActions.POTION_MANA then
        return "Mana Potion"
    -- UI
    elseif action == InputActions.TOGGLE_INVENTORY then
        return "Toggle Inventory"
    elseif action == InputActions.TOGGLE_SKILLS then
        return "Toggle Skills"
    elseif action == InputActions.CLOSE_MODAL then
        return "Close Modal"
    -- Debug
    elseif action == InputActions.DEBUG_TOGGLE then
        return "Toggle Debug"
    elseif action == InputActions.DEBUG_CHUNKS then
        return "Debug Chunks"
    elseif action == InputActions.RESET_WORLD then
        return "Reset World"
    -- Minimap
    elseif action == InputActions.MINIMAP_TOGGLE then
        return "Toggle Minimap"
    elseif action == InputActions.MINIMAP_ZOOM_IN then
        return "Minimap Zoom In"
    elseif action == InputActions.MINIMAP_ZOOM_OUT then
        return "Minimap Zoom Out"
    -- Mouse
    elseif action == InputActions.MOUSE_PRIMARY then
        return "Left Mouse Button"
    elseif action == InputActions.MOUSE_SECONDARY then
        return "Right Mouse Button"
    -- Dev
    elseif action == InputActions.INVENTORY_TEST_ITEM then
        return "Test Item (Dev)"
    else
        return action
    end
end

---Get action category for grouping in controls screen.
---@param action string Action constant from InputActions
---@return string Category name
local function getActionCategory(action)
    local InputActions = require("modules.input_actions")

    if action == InputActions.MOVE_LEFT
        or action == InputActions.MOVE_RIGHT
        or action == InputActions.MOVE_UP
        or action == InputActions.MOVE_DOWN
    then
        return "Movement"
    elseif action == InputActions.SKILL_1
        or action == InputActions.SKILL_2
        or action == InputActions.SKILL_3
        or action == InputActions.SKILL_4
    then
        return "Skills"
    elseif action == InputActions.POTION_HEALTH
        or action == InputActions.POTION_MANA
    then
        return "Potions"
    elseif action == InputActions.TOGGLE_INVENTORY
        or action == InputActions.TOGGLE_SKILLS
        or action == InputActions.CLOSE_MODAL
    then
        return "UI"
    elseif action == InputActions.DEBUG_TOGGLE
        or action == InputActions.DEBUG_CHUNKS
        or action == InputActions.RESET_WORLD
    then
        return "Debug"
    elseif action == InputActions.MINIMAP_TOGGLE
        or action == InputActions.MINIMAP_ZOOM_IN
        or action == InputActions.MINIMAP_ZOOM_OUT
    then
        return "Minimap"
    elseif action == InputActions.MOUSE_PRIMARY
        or action == InputActions.MOUSE_SECONDARY
    then
        return "Mouse"
    elseif action == InputActions.INVENTORY_TEST_ITEM then
        return "Development"
    else
        return "Other"
    end
end

---Format key for display (convert button numbers to readable names).
---@param key string|number Key string or button number
---@return string Formatted key name
local function formatKey(key)
    if type(key) == "number" then
        if key == 1 then
            return "Left Mouse"
        elseif key == 2 then
            return "Right Mouse"
        else
            return "Button " .. tostring(key)
        end
    end

    -- Handle special keys
    local specialKeys = {
        escape = "Escape",
        left = "Left Arrow",
        right = "Right Arrow",
        up = "Up Arrow",
        down = "Down Arrow",
        space = "Space",
        enter = "Enter",
        backspace = "Backspace",
        tab = "Tab",
    }

    if specialKeys[key] then
        return specialKeys[key]
    end

    -- Handle function keys (f1, f2, etc.)
    if string.match(key, "^f%d+$") then
        return string.upper(key)
    end

    -- Handle bracket keys
    if key == "[" then
        return "["
    elseif key == "]" then
        return "]"
    end

    -- Single character keys - capitalize
    if string.len(key) == 1 then
        return string.upper(key)
    end

    -- Multi-character keys - capitalize first letter
    return string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
end

local ActionNames = {}

ActionNames.getDisplayName = getActionDisplayName
ActionNames.getCategory = getActionCategory
ActionNames.formatKey = formatKey

return ActionNames
