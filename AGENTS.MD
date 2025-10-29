# Agent Notes

## Snapshot
- Working title: Diablo-inspired roguelike built with LÖVE (Love2D) and Lua.
- Core loop: explore procedurally generated forest biomes, fight monster packs, gain levels, equip random loot, visit small towns for shops/vendors.
- Scope for this phase: capture architecture/gamedesign intent; no code generation yet.

## Architecture Guardrails
- Use a lightweight, homemade ECS: `WorldScene` composes entities, component tables, and runs ordered systems. Systems operate on component sets; entities remain data.
- Everything is an entity; behavior emerges from systems (`player_input`, `movement`, `wander`, `render`) consuming components (`movement`, `renderable`, `player_controlled`, `wander`).
- Scene orchestration handled by a shared `SceneManager` stack—allows overlay scenes (inventory) without coupling to the world.
- Core world systems cover input, AI wander, movement, camera centering, rendering, and HUD (`ui_player_status`).
- `WorldScene` guarantees `getPlayer`/`getEntity` helpers so downstream systems can rely on unified entity retrieval (no guard checks needed).
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
- Expand ECS scaffolding: shared entity helpers, additional components (health, combat) and system registry utilities.
- Flesh out scene manager transitions (pause behavior, modal overlays) and input routing.
- Stub world generator pipeline (biome params, spawn rules).
- Draft inventory/equipment data schema; connect inventory scene to real data and interactions.

## Reminders
- Stay light; expand this doc as systems/specs grow.
- Keep README aligned with this vision so new contributors understand the direction.
