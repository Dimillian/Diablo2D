---Input action name constants for centralized input management.
---Prevents typos and enables IDE autocomplete.
local InputActions = {}

-- Movement actions (continuous/held)
InputActions.MOVE_LEFT = "move_left"
InputActions.MOVE_RIGHT = "move_right"
InputActions.MOVE_UP = "move_up"
InputActions.MOVE_DOWN = "move_down"

-- Skill actions (press events)
InputActions.SKILL_1 = "skill_1"
InputActions.SKILL_2 = "skill_2"
InputActions.SKILL_3 = "skill_3"
InputActions.SKILL_4 = "skill_4"

-- Potion actions (press events)
InputActions.POTION_HEALTH = "potion_health"
InputActions.POTION_MANA = "potion_mana"

-- UI actions (press events)
InputActions.TOGGLE_INVENTORY = "toggle_inventory"
InputActions.TOGGLE_SKILLS = "toggle_skills"
InputActions.TOGGLE_WORLD_MAP = "toggle_world_map"
InputActions.CLOSE_MODAL = "close_modal"

-- Debug actions (press events)
InputActions.DEBUG_TOGGLE = "debug_toggle"
InputActions.DEBUG_CHUNKS = "debug_chunks"
InputActions.RESET_WORLD = "reset_world"

-- Minimap actions (press events)
InputActions.MINIMAP_TOGGLE = "minimap_toggle"
InputActions.MINIMAP_ZOOM_IN = "minimap_zoom_in"
InputActions.MINIMAP_ZOOM_OUT = "minimap_zoom_out"

-- Dev actions (press events)
InputActions.INVENTORY_TEST_ITEM = "inventory_test_item"

-- Mouse actions
InputActions.MOUSE_PRIMARY = "mouse_primary"
InputActions.MOUSE_SECONDARY = "mouse_secondary"

return InputActions
