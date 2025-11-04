# Agent Notes

## Snapshot
- Working title: Diablo-inspired roguelike built with LÖVE (Love2D) and Lua.
- Core loop: explore procedurally generated forest biomes, fight monster packs, gain levels, equip random loot, visit small towns for shops/vendors.
- Scope for this phase: capture architecture/gamedesign intent; no code generation yet.

## Architecture Guardrails
- Use a lightweight, homemade ECS: Entity/Component management lives in `modules/ecs.lua` and can be mixed into any scene via `ECS.init(scene)`. `WorldScene` uses ECS and composes entities, component tables, and runs ordered systems. Systems operate on component sets for efficient O(k) queries where k = matching entities; entities remain pure data.
- Everything is an entity; behavior emerges from systems (`player_input`, `mouse_look`, `mouse_movement`, `movement`, `wander`, `detection`, `chase`, `render`, `starter_gear`, `combat`, `foe_attack`, `core/potion_consumption`, `core/experience`, `skills/cast`, `projectile/movement`, `projectile/collision`, `ui/skills_bar`) consuming components (`movement`, `renderable`, `player_controlled`, `wander`, `detection`, `chase`, `combat`, `potions`, `experience`, `skills`, `projectile`).
- Entity factories (`entities/player.lua`, `entities/foe.lua`) follow a consistent pattern: `Entity.new(opts)` creates entities with component defaults, allowing easy variation (speed, detection range, etc.).
- Scene orchestration handled by a shared `SceneManager` stack—allows overlay scenes (inventory) without coupling to the world.
- Core world systems cover input (keyboard + mouse), AI detection/chase, AI wander, movement, camera centering, rendering, combat resolution, consumable handling, experience progression, and HUD (`ui_player_status`, `ui/experience_bar`, `ui/bottom_bar`, `ui/skills_bar`). Chase maintains a configurable separation buffer so foes stop short of overlapping their target while still staying within melee range.
- Input systems: `player_input` handles keyboard movement (WASD/QZ for AZERTY keyboards); `mouse_look` tracks cursor position and updates player look direction; `mouse_movement` enables right-click-to-move that overrides keyboard movement when active.
- Movement component includes `lookDirection` field (normalized vector) that tracks where the player is facing; used for combat targeting and visual feedback.
- `render_mouse_look` system draws a visual arrow indicator around the player showing current look direction.
- `WorldScene` provides `systemHelpers.coordinates` helper (`toWorldFromScreen`) for screen-to-world coordinate conversion used by mouse systems.
- `modules/vector.lua` provides utility functions: `normalize`, `length`, `distance` for common vector math operations.
- `starter_gear` system runs once per world initialization: generates and auto-equips common weapon (sword/axe) + 3 armor pieces (helmet, chest, boots) for new players.
- Combat events live on `world.pendingCombatEvents` each frame; `systems/combat.lua` pushes `damage`/`death` payloads that downstream systems consume (`render_damage_numbers`, `loot_drops`, `loot_tooltip`, `ui_target`, `core/experience`).
- AI behavior: `detection` system checks distance to player and dynamically adds/removes `chase` component using `addComponent`/`removeComponent`; `chase` system moves toward target; `wander` system skips entities with `chase` component (chase takes precedence).
- Enemy offense: `systems/foe_attack.lua` queues melee swings only when within archetype ranges, respects per-foe cooldowns, and pairs with `components/knockback.lua` so `systems/movement.lua` can apply short pushbacks when combat resolves.
- Consumables: `components/potions.lua` tracks stack counts and cooldown metadata; `systems/core/potion_consumption.lua` enforces shared cooldown, hotkeys (`1`/`2`), and HUD click handling, while loot pickup increments stacks up to per-type caps.
- Experience: `components/experience.lua` pairs with `modules/leveling.lua` and `systems/core/experience.lua` to award XP on foe death, grant stat bonuses, and feed the full-width `ui/experience_bar.lua`.
- Skills: `components/skills.lua`, `components/projectile.lua`, and systems in `systems/skills` / `systems/projectile` provide the spellbook scene, hotkey queueing, projectile travel/collision, and skills bar UI (with book icon toggle via `K`).
- Mouse input is centralized via `systems/mouse_input`: `WorldScene` seeds `scene.input.mouse.primary` state, forwards Love2D `mousepressed`/`mousereleased`, and runs the input system first each frame. Consumers (loot pickup, player attack, potion HUD clicks, skills scene, inventory interactions, etc.) read `pressed/held` from the shared state and set `consumedClickId` when they claim a click so downstream systems can exit early. Add new mouse actions by copying the primary schema to `scene.input.mouse.secondary` (or similar) and queuing presses/releases through the helper.
- `WorldScene` guarantees `getPlayer`/`getEntity` helpers so downstream systems can rely on unified entity retrieval (no guard checks needed).
- ECS module provides: `addEntity`, `removeEntity`, `getEntity`, `queryEntities`, `hasComponent`, `addComponent`, `removeComponent`—any scene can opt into ECS capabilities. Use `addComponent`/`removeComponent` for runtime component mutations to ensure component sets stay synchronized.
- Debug mode: `WorldScene.debugMode` flag toggled via 't' key; `render` system conditionally draws detection circles when enabled.
- Target HUD: `ui_target` frame keeps padded spacing between enemy name text and health bar to remain legible across font sizes.
- Keep systems decoupled and data-driven to enable procedural content later.

### Combat System Notes
- Player attacks originate in `systems/player_attack.lua`: it ticks the targeting helper, respects attack speed modifiers, and raises a `combat.queuedAttack` payload when the mouse button is held and the foe is in range.
- `systems/foe_attack.lua` handles enemy offensive cadence: it checks chase targets, archetype melee ranges, and cooldowns before queueing retaliatory swings so enemies feel threatening without overwhelming the player.
- Knockback is handled via `components/knockback.lua`; `systems/combat.lua` applies push vectors to both parties on hit and `systems/movement.lua` eases positions until timers expire.
- `systems/combat.lua` is the central executor: validates target state/range, computes damage using base combat stats plus `player.stats.total`, handles crit rolls, marks recently damaged entities, raises `damage`/`death` events, and cleans up dead foes.
- Events live on `world.pendingCombatEvents` for the frame; downstream systems (`render_damage_numbers`, `loot_drops`, `loot_tooltip`, `loot_pickup`, `ui_target`) consume these without tight coupling.
- Foes use the updated chase logic to stop outside the player by combining radius checks with a configurable separation buffer; movement honors a per-frame `maxDistance` clamp so positional corrections stay granular.
- Loot pickup requires both cursor hover and proximity; equipment helper ensures items move cleanly between inventory/equipment without duplicates.

### Loot/Item System
- Item metadata lives in `data/items.lua`: types, rarity weights, base stat ranges, and slot-gated prefix/suffix pools.
- `items/generator.lua` provides two APIs: `ItemGenerator.generate(opts)` for full generation, and `ItemGenerator.roll(opts)` for flexible item creation with optional rarity, type, `allowedTypes` array, and `source` tagging.
- `ItemGenerator.roll()` supports string lookups for rarity/itemType IDs, or direct entry objects; resolves `allowedTypes` arrays by randomly selecting from the list; useful for starter gear, loot drops, and vendor inventories.
- Equipment helper (`system_helpers/equipment.lua`) prevents item duplication when equipping—checks if item already equipped before moving from inventory.
- Inventory scene and future loot drops consume the generator and read stats directly off the generated item payload.

### Consumable System
- `components/potions.lua` tracks per-type counts, max stacks, shared cooldown metadata, and is attached to the player at creation.
- `systems/core/potion_consumption.lua` decays cooldown timers, gates usage on resource caps, and responds to hotkeys `1`/`2` or HUD clicks registered by `systems/ui/bottom_bar.lua`.
- Potion loot is generated in `systems/core/loot_drops.lua` (15% drop chance) and routed through `systems/core/loot_pickup.lua`, which increments stacks while respecting caps and skipping equipment flows.
- HUD: `systems/ui/bottom_bar.lua` draws potion boxes with cooldown shading/badges and stores clickable rects; the inventory scene renders potion counts via `systems/render/inventory_potions.lua`.

### Experience & Leveling
- Player spawns with `components/experience.lua` (level, current XP, target XP) configured by `modules/leveling.lua`.
- `systems/core/experience.lua` listens to combat death events, applies XP gains (with while-loop for multi-level ups), issues stat bonuses (+5 health, +1 min/max damage, +1 defense), and refreshes totals through the existing stats pipeline.
- `systems/ui/experience_bar.lua` renders a full-width bar along the bottom edge with level labels and progress text.

### Skills & Projectiles
- Skills data is defined in `data/spells.lua`; `components/skills.lua` stores four equipped slots and is attached to the player.
- Casting flow: `systems/skills/cast.lua` maps number keys `1`-`4` (with priority handling for potions when slots are empty) and mouse clicks to spawn projectile entities via `entities/projectile.lua`.
- `systems/projectile/movement.lua` and `systems/projectile/collision.lua` move fireballs toward targets, detect circular collisions, apply combat events/damage, and despawn on hit or lifetime expiry.
- `systems/ui/skills_bar.lua` extends the bottom bar with hotkeyed slots; `systems/ui/bottom_bar.lua` adds a book icon that toggles `scenes/skills.lua`, mirroring the inventory overlay pattern for mouse-driven equip/unequip interactions.

## Coding Style Guide

### Naming Conventions
- **Modules/Classes**: PascalCase (e.g., `WorldScene`, `ItemGenerator`, `ECS`, `Player`)
- **Functions/Variables**: camelCase (e.g., `getPlayer`, `cooldownRatio`, `handleDeath`, `ensureEventQueue`)
- **Component factories**: `createXComponent` pattern (e.g., `createMovementComponent`, `createHealth`)
- **System modules**: snake_case filenames, camelCase table names (e.g., `systems/player_input.lua` exports `playerInputSystem`)
- **Constants**: UPPER_SNAKE_CASE when truly constant, otherwise camelCase
- **Private/helper functions**: camelCase, prefixed with descriptive action verbs (e.g., `getEntityCenter`, `pushCombatEvent`, `markRecentlyDamaged`)

### Module Structure Patterns

**Module/Class Pattern** (for reusable modules like `ECS`, `WorldScene`):
```lua
local ModuleName = {}
ModuleName.__index = ModuleName

function ModuleName.new(opts)
    opts = opts or {}
    local instance = {}
    -- ... initialization ...
    return setmetatable(instance, ModuleName)
end

function ModuleName:method()
    -- ...
end

return ModuleName
```

**Component Factory Pattern** (for components in `components/`):
```lua
local function createComponentName(opts)
    opts = opts or {}
    return {
        field = opts.field or defaultValue,
        -- ...
    }
end

return createComponentName
```

**System Pattern** (for systems in `systems/`):
```lua
local systemName = {}

function systemName.update(world, dt)
    -- ...
end

function systemName.draw(world)
    -- ...
end

return systemName
```

**Helper/Utility Module Pattern** (for utilities like `vector`, `targeting`):
```lua
local HelperName = {}

function HelperName.functionName(param)
    -- ...
end

return HelperName
```

### Code Organization
- **Imports first**: All `require()` statements at the top of the file
- **Local helpers before exports**: Define private helper functions before main module exports
- **Early returns**: Use guard clauses (`if not X then return end`) for early exits
- **Function ordering**: Public API functions first, then private helpers
- **One responsibility**: Functions should do one thing well; extract complex logic into named helpers

### Documentation Style
- Use LuaDoc-style comments with `---` prefix for function documentation
- Document all public functions with:
  - Brief description on first line
  - `@param` tags for parameters (include type and description)
  - `@return` tags for return values (include type and description)
- Example:
```lua
---Compute damage for an attack, factoring in stats and crit chance.
---@param attacker table Entity with combat and stats components
---@return number damage The computed damage amount
---@return boolean isCrit Whether this was a critical hit
local function computeDamage(attacker)
    -- ...
end
```

### Common Patterns

**Optional Parameters**:
```lua
function someFunction(opts)
    opts = opts or {}
    local value = opts.value or defaultValue
    -- ...
end
```

**Guard Clauses**:
```lua
function someFunction(entity)
    if not entity then
        return nil
    end
    -- Main logic here
end
```

**Nil-Safe Access**:
```lua
local player = world:getPlayer()
local potions = player and player.potions
if not potions then
    return
end
```

**Clamping Values**:
```lua
value = math.max(minValue, math.min(maxValue, value))
-- or
value = math.max(0, value)  -- for non-negative values
```

**Table Iteration**:
- Use `ipairs` for ordered arrays
- Use `pairs` for key-value maps
- Prefer `ipairs` when order matters

**Loop Control**:
- Use `goto continue` for skipping loop iterations when needed
- Label with `::continue::` at end of loop body

**Event Queue Pattern**:
```lua
local function ensureEventQueue(world)
    world.pendingCombatEvents = world.pendingCombatEvents or {}
    return world.pendingCombatEvents
end

local function pushEvent(world, payload)
    local events = ensureEventQueue(world)
    events[#events + 1] = payload
end
```

### Formatting
- **Indentation**: 4 spaces (no tabs)
- **Line length**: Prefer wrapping long lines for readability
- **Spacing**: Single blank line between logical sections, double blank line before function definitions
- **Brackets**: Use table literals with explicit field names: `{ x = 0, y = 0 }` not `{0, 0}` when field names clarify intent
- **Parentheses**: Use when they improve clarity, omit for simple function calls
- **Comments**: Use `--` for inline comments, `---` for documentation comments

### Error Handling
- Prefer nil returns over throwing errors for expected failure cases
- Use `assert()` for programming errors (missing required parameters in constructors)
- Guard against nil/undefined before accessing nested properties
- Use `luacheck: ignore` comments for intentional unused parameters (e.g., `-- luacheck: ignore 212/self`)

### System-Specific Conventions
- **Systems**: Export `update(world, dt)` and/or `draw(world)` functions
- **Components**: Pure data tables created by factory functions
- **Entities**: Tables with `id` field and component tables as fields
- **Scenes**: Use metatables for method dispatch (`Scene:method()` syntax)
- **Helpers**: Static utility functions, no state

### Best Practices
- Keep functions small and focused (single responsibility principle)
- Prefer local functions over globals
- Use descriptive names that explain intent
- Avoid magic numbers—use named constants or parameters
- Extract repeated logic into helper functions
- Prefer explicit nil checks over truthy/falsy checks when clarity matters
- Use table construction patterns consistently (e.g., `table.insert(list, value)` vs `list[#list + 1] = value`—codebase uses both; prefer `#list + 1` pattern for consistency with existing code)

## Gameplay Pillars To Enable
- Procedural forest world generation as the first playable space.
- Monster packs with basic combat behaviors and XP/level progression.
- Randomized loot tables that feed inventory and equipment slots.
- Small towns that spawn intermittently with shops and vendor interactions.

## Near-Term Focus
- Expand ECS scaffolding: additional components (combat stats, damage) and system registry utilities.
- Flesh out scene manager transitions (pause behavior, modal overlays) and input routing.
- Stub world generator pipeline (biome params, spawn rules).
- Draft inventory/equipment data schema; connect inventory scene to real data and interactions.
- Extend foe types: create specialized foe factories with different detection ranges, speeds, behaviors, and attack cadences to pressure potion usage.
- Grow the spell roster, introduce elemental variants, and balance mana costs/cooldowns against the new potion economy and XP curve.

## Reminders
- Stay light; expand this doc as systems/specs grow.
- Keep README aligned with this vision so new contributors understand the direction.
- Always run `luacheck .` and fix all warnings before committing changes.
- Run `lua tools/item_balance_report.lua 5000` after loot/affix changes to verify stat distribution and drop mix.
