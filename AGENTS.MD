# Agent Notes

## Snapshot
- Working title: Diablo-inspired roguelike built with LÖVE (Love2D) and Lua.
- Core loop: explore procedurally generated forest biomes, fight monster packs, gain levels, equip random loot, visit small towns for shops/vendors.
- Scope for this phase: capture architecture/gamedesign intent; no code generation yet.

## Architecture Guardrails
- Use a lightweight, homemade ECS: Entity/Component management lives in `modules/ecs.lua` and can be mixed into any scene via `ECS.init(scene)`. `WorldScene` uses ECS and composes entities, component tables, and runs ordered systems. Systems operate on component sets for efficient O(k) queries where k = matching entities; entities remain pure data.
- Everything is an entity; behavior emerges from systems (`player_input`, `movement`, `wander`, `detection`, `chase`, `render`) consuming components (`movement`, `renderable`, `player_controlled`, `wander`, `detection`, `chase`).
- Entity factories (`entities/player.lua`, `entities/foe.lua`) follow a consistent pattern: `Entity.new(opts)` creates entities with component defaults, allowing easy variation (speed, detection range, etc.).
- Scene orchestration handled by a shared `SceneManager` stack—allows overlay scenes (inventory) without coupling to the world.
- Core world systems cover input, AI detection/chase, AI wander, movement, camera centering, rendering, and HUD (`ui_player_status`).
- AI behavior: `detection` system checks distance to player and dynamically adds/removes `chase` component using `addComponent`/`removeComponent`; `chase` system moves toward target; `wander` system skips entities with `chase` component (chase takes precedence).
- `WorldScene` guarantees `getPlayer`/`getEntity` helpers so downstream systems can rely on unified entity retrieval (no guard checks needed).
- ECS module provides: `addEntity`, `removeEntity`, `getEntity`, `queryEntities`, `hasComponent`, `addComponent`, `removeComponent`—any scene can opt into ECS capabilities. Use `addComponent`/`removeComponent` for runtime component mutations to ensure component sets stay synchronized.
- Debug mode: `WorldScene.debugMode` flag toggled via 't' key; `render` system conditionally draws detection circles when enabled.
- Keep systems decoupled and data-driven to enable procedural content later.

### Loot/Item System
- Item metadata lives in `data/items.lua`: types, rarity weights, base stat ranges, and slot-gated prefix/suffix pools.
- `items/generator.lua` rolls rarity (weighted 50/25/15/7/3), item type, base stats within min/max, applies rarity multipliers, then affixes respecting slot restrictions.
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
