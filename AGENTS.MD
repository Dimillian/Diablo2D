# Agent Notes

## Snapshot
- Working title: Diablo-inspired roguelike built with LÖVE (Love2D) and Lua.
- Core loop: explore procedurally generated forest biomes, fight monster packs, gain levels, equip random loot, visit small towns for shops/vendors.
- Scope for this phase: capture architecture/gamedesign intent; no code generation yet.

## Architecture Guardrails
- Use a lightweight, homemade ECS: Entity/Component management lives in `modules/ecs.lua` and can be mixed into any scene via `ECS.init(scene)`. `WorldScene` uses ECS and composes entities, component tables, and runs ordered systems. Systems operate on component sets for efficient O(k) queries where k = matching entities; entities remain pure data.
- Everything is an entity; behavior emerges from systems (`player_input`, `mouse_look`, `mouse_movement`, `movement`, `wander`, `detection`, `chase`, `render`, `starter_gear`) consuming components (`movement`, `renderable`, `player_controlled`, `wander`, `detection`, `chase`).
- Entity factories (`entities/player.lua`, `entities/foe.lua`) follow a consistent pattern: `Entity.new(opts)` creates entities with component defaults, allowing easy variation (speed, detection range, etc.).
- Scene orchestration handled by a shared `SceneManager` stack—allows overlay scenes (inventory) without coupling to the world.
- Core world systems cover input (keyboard + mouse), AI detection/chase, AI wander, movement, camera centering, rendering, and HUD (`ui_player_status`). Chase maintains a configurable separation buffer so foes stop short of overlapping their target while still staying within melee range.
- Input systems: `player_input` handles keyboard movement (WASD/QZ for AZERTY keyboards); `mouse_look` tracks cursor position and updates player look direction; `mouse_movement` enables right-click-to-move that overrides keyboard movement when active.
- Movement component includes `lookDirection` field (normalized vector) that tracks where the player is facing; used for combat targeting and visual feedback.
- `render_mouse_look` system draws a visual arrow indicator around the player showing current look direction.
- `WorldScene` provides `systemHelpers.coordinates` helper (`toWorldFromScreen`) for screen-to-world coordinate conversion used by mouse systems.
- `modules/vector.lua` provides utility functions: `normalize`, `length`, `distance` for common vector math operations.
- `starter_gear` system runs once per world initialization: generates and auto-equips common weapon (sword/axe) + 3 armor pieces (helmet, chest, boots) for new players.
- AI behavior: `detection` system checks distance to player and dynamically adds/removes `chase` component using `addComponent`/`removeComponent`; `chase` system moves toward target; `wander` system skips entities with `chase` component (chase takes precedence).
- `WorldScene` guarantees `getPlayer`/`getEntity` helpers so downstream systems can rely on unified entity retrieval (no guard checks needed).
- ECS module provides: `addEntity`, `removeEntity`, `getEntity`, `queryEntities`, `hasComponent`, `addComponent`, `removeComponent`—any scene can opt into ECS capabilities. Use `addComponent`/`removeComponent` for runtime component mutations to ensure component sets stay synchronized.
- Debug mode: `WorldScene.debugMode` flag toggled via 't' key; `render` system conditionally draws detection circles when enabled.
- Target HUD: `ui_target` frame keeps padded spacing between enemy name text and health bar to remain legible across font sizes.
- Keep systems decoupled and data-driven to enable procedural content later.

### Combat System Notes
- Player attacks originate in `systems/player_attack.lua`: it ticks the targeting helper, respects attack speed modifiers, and raises a `combat.queuedAttack` payload when the mouse button is held and the foe is in range.
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
- Extend foe types: create specialized foe factories with different detection ranges, speeds, and behaviors.

## Reminders
- Stay light; expand this doc as systems/specs grow.
- Keep README aligned with this vision so new contributors understand the direction.
- Always run `luacheck .` and fix all warnings before committing changes.
