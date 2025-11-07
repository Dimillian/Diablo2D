# Agent Notes

## Core Architecture

- **ECS**: Lightweight homemade ECS in `modules/ecs.lua`. Use `ECS.init(scene)` to mix ECS into any scene. Entities are pure data tables with `id` field. Components are entity fields (tables). Systems query via `world:queryEntities({ "component1", "component2" })` for efficient O(k) lookups.
- **Key ECS methods**: `addEntity`, `removeEntity`, `getEntity`, `queryEntities`, `hasComponent`, `addComponent`, `removeComponent`. Always use `addComponent`/`removeComponent` for runtime mutations to keep component sets synchronized.
- **Scenes**: `WorldScene` uses ECS and composes systems. Scene manager handles overlay stack (inventory, skills). `WorldScene` provides `getPlayer()`/`getEntity()` helpers and `systemHelpers.coordinates` for screen-to-world conversion.
- **Systems**: Export `update(world, dt)` and/or `draw(world)`. Systems operate on component sets via queries. Keep systems decoupled—they communicate via events or component mutations.

## Component Design Rules

**CRITICAL**: Components should only accept `opts` when values vary per entity (e.g., `position`, `health`, `combat`). Components with fixed defaults (e.g., `inventory`, `equipment`, `potions`, `skills`, `player_controlled`, `recently_damaged`) must NOT accept `opts` and always return fixed values from `data/component_defaults.lua`. This ensures components are never nil and eliminates defensive checks.

**Component defaults**: All defaults centralized in `data/component_defaults.lua`. Reference constants in component factories, never hardcode magic numbers.

**Component factory pattern**:
```lua
-- Fixed defaults (no opts):
local ComponentDefaults = require("data.component_defaults")
local function createComponentName()
    return {
        field = ComponentDefaults.CONSTANT,
    }
end

-- Variable defaults (with opts):
local function createComponentName(opts)
    opts = opts or {}
    return {
        field = opts.field or ComponentDefaults.DEFAULT_VALUE,
    }
end
```

## Naming Conventions

- **Modules/Classes**: PascalCase (`WorldScene`, `ItemGenerator`, `ECS`)
- **Functions/Variables**: camelCase (`getPlayer`, `cooldownRatio`)
- **Component factories**: `createXComponent` pattern (`createMovementComponent`, `createHealth`)
- **System modules**: snake_case filenames, camelCase table names (`systems/player_input.lua` exports `playerInputSystem`)
- **Constants**: UPPER_SNAKE_CASE when truly constant, otherwise camelCase

## Key Patterns

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

**Mouse Input**: Centralized via `systems/mouse_input`. `WorldScene` seeds `scene.input.mouse.primary` state. Consumers read `pressed/held` and set `consumedClickId` when claiming clicks.

**Combat Events**: Live on `world.pendingCombatEvents` each frame. Systems push `damage`/`death` payloads; downstream systems consume without tight coupling.

**Component Mutations**: Use `world:addComponent(entityId, componentName, component)` and `world:removeComponent(entityId, componentName)` for runtime changes (e.g., AI adding/removing `chase` component).

**Resource Management**: Centralized in `modules/resources.lua`. All image loading goes through the resource manager for caching and error handling:
- `resources.loadImage(path)` - Load standalone images (cached)
- `resources.loadImageSafe(path)` - Safe loading with nil return on error (use for optional assets)
- `resources.loadAtlas(imagePath, metadataPath, spriteSize)` - Load sprite sheets with quads (supports metadata files or uniform grid)
- `resources.getAtlasSprite(atlasPath, spriteName)` - Get a quad from a loaded atlas
- `resources.loadUIIcon(iconName)` - Load UI icons from `resources/icons/` directory (e.g., "bag", "health_potion")
- `resources.getFoeSpritePath(prefix, animationType)` - Get foe sprite sheet paths (e.g., "orc1", "walk" → "resources/foe/orc1_walk.png")
- `resources.clearCache()` - Clear all cached resources (useful for testing/reloading)

Always use `loadImageSafe()` for optional assets that may not exist. Use `loadImage()` for required assets. All resources are cached automatically.

## Critical System Interactions

- **Combat**: `systems/combat.lua` processes queued attacks, computes damage using `player.stats.total`, raises events. `systems/player_attack.lua` queues attacks; `systems/foe_attack.lua` handles enemy offense.
- **AI**: `detection` system adds/removes `chase` component dynamically. `chase` takes precedence over `wander`.
- **Stats**: `systems/core/apply_stats.lua` computes `entity.stats.total` from `baseStats` + equipment. Systems read `stats.total` for combat calculations.
- **Items**: `items/generator.lua` provides `ItemGenerator.generate(opts)` and `ItemGenerator.roll(opts)`. Equipment helper (`systems/helpers/equipment.lua`) prevents duplication when equipping.

## Testing Workflow

- Tests in `spec/` run with `busted spec`. Keep green before pushing.
- Stubs in `spec/system_helpers/` for Love2D dependencies. Use `spec/support/test_world.lua` for ECS doubles.
- Add specs alongside gameplay changes to catch regressions.

## Development Commands

- `luacheck .` - Run before committing to catch lint issues
- `busted spec` - Run test suite
- `lua tools/item_balance_report.lua 5000` - Generate item balance snapshot after loot/affix changes

## Code Style

- **Indentation**: 4 spaces
- **Imports first**: All `require()` at top
- **Early returns**: Use guard clauses (`if not X then return end`)
- **Table construction**: Prefer `list[#list + 1] = value` pattern
- **Nil-safe access**: Guard before accessing nested properties (`entity and entity.component`)
- **Documentation**: LuaDoc-style with `---` prefix, `@param`/`@return` tags
