# Upcoming Feature Master Plan

## Movement: WASD With Mouse Steering ✅
- Mouse-facing movement now drives the player's heading and strafe intents via component state, with smoothing handled directly on the movement component for downstream systems. (`Diablo.love/systems/player_input.lua`, `Diablo.love/systems/movement.lua`, `Diablo.love/components/movement.lua`)
- Non-player entities were updated to follow the new intent-driven contract so wander and chase behaviors continue to function without manual velocity writes. (`Diablo.love/systems/wander.lua`, `Diablo.love/systems/chase.lua`)
- Added a reusable coordinate helper registered on the scene for translating screen positions into world space, enabling mouse steering and future cursor-driven features. (`Diablo.love/system_helpers/coordinates.lua`, `Diablo.love/scenes/world.lua`)

## New Game: Guaranteed Starter Item
- **Starting inventory hookup (`Diablo.love/scenes/world.lua`)**
  - After creating the player entity via `scene:addEntity(Player.new(...))`, call into the item generator with forced options (`{ rarity = "common", allowedTypes = { "sword", "axe" } }`).
  - Use ECS-safe helpers when wiring the item into components: mutate the existing `player.inventory` and `player.equipment` tables in place rather than swapping tables so ECS component sets stay valid. If the player does not yet have an `equipment` component, attach it with `scene:addComponent(player.id, "equipment", EquipmentComponent.new())` before populating slots.
  - Trigger a stat recompute by flagging the player for the existing `apply_stats` system (e.g., set `player.stats.needsRefresh = true` if present) so the ECS update loop handles derived data.

- **Generator extension (`Diablo.love/items/generator.lua`)**
  - Provide an API `ItemGenerator.roll(opts)` that respects optional parameters for rarity and type overrides while keeping the weighted defaults for normal drops. Document that passing `source = "starter"` tags the payload for later filtering.

## Combat System Foundations
### Combat 1: Click-to-Attack With Cooldown
- **Player combat component (`Diablo.love/components/combat.lua`)**
  - Create a new component storing combat stats: `attackSpeed`, `cooldown`, `range`, `queuedAttack`, and `swingTimer`. Attach it to the player entity inside `entities/player.lua` by calling `CombatComponent.new(opts)` so the entity is created with the component before `scene:addEntity(player)`. For NPCs that need combat later, reuse the same constructor to keep component shape consistent.

- **Attack input system (`Diablo.love/systems/player_attack.lua`)**
  - Register a new update system after `player_input` and before `movement`. It should:
    - Read `love.mouse.isDown(1)` and, if pressed, look up the player's current target (see targeting helper below).
    - Decrement `combat.cooldown` using `dt` while leaving the table reference intact.
    - When `cooldown <= 0`, populate `combat.queuedAttack = { targetId = target.id, time = scene.time }` and reset `cooldown = 1 / effectiveAttackSpeed` using aggregated stats from `systems.apply_stats` (read-only).
  - Because systems operate on entities retrieved through `scene:getPlayer()` or `scene:queryEntities`, avoid storing per-system state; rely on component data instead.

- **Target acquisition**
  - Add a helper under `Diablo.love/system_helpers/targeting.lua` that queries foes using `scene:queryEntities({ "foe", "position", "health" })`. Foes should gain a lightweight `foe` tag component (`entities/foe.lua`) so they are discoverable.
  - Reuse the new coordinate helper to convert the mouse cursor to world space and perform a simple distance check capped by `combat.range` (~120px). Store the resolved entity ID on the scene (`scene.currentTargetId`) so other systems (UI, damage) can read it without recomputing.

- **Animation stub**
  - During an active attack, let `systems/render_equipment.lua` read `combat.swingTimer`. While `swingTimer > 0`, offset the weapon sprite by a small sine wave. Decrement `swingTimer` in the attack system when an attack is queued and let it reach zero naturally to reset the animation.

### Combat 2: Damage Resolution
- **Damage system (`Diablo.love/systems/combat.lua`)**
  - Consume queued attacks each frame. Use `scene:queryEntities({ "combat" })` to iterate combatants, validate queued attacks (target exists via `scene:getEntity`, target still has `health`, target within range), and then resolve damage.
  - Compute outgoing damage from aggregated stats already cached by `apply_stats` (`entity.stats.total.damageMin`, etc.). Avoid replacing the `health` table; mutate `target.health.current` in place so ECS bookkeeping stays intact.
  - When a target takes damage, push a structured payload into `scene.pendingCombatEvents` (create this table during scene init). Other systems can read and clear this queue during their update pass, which keeps communication data-oriented without inventing a new dispatcher API.

- **Top-of-screen target frame (`Diablo.love/systems/ui_target.lua`)**
  - Add a draw system registered after `systems.ui_player_status.draw`. It should read `scene.currentTargetId` and fetch the entity via `scene:getEntity`. Render a framed bar showing `health.current/max` using the same coordinate transforms already applied in the HUD.

- **Floating enemy bars**
  - Either extend `Diablo.love/systems/render.lua` or create `systems/render_health.lua` to query foes with `health` and a `recentlyDamaged` component/flag. Populate or clear that flag inside the combat system when handling `scene.pendingCombatEvents`.
  - Use the active camera transform already applied in `renderSystem` to draw the health bar above the enemy (`position.y - offset`). Keep timers (`recentlyDamaged.timer`) inside the component and decrement them during the render system to manage visibility.

- **State tracking**
  - Maintain combat focus on the scene (`scene.currentTargetId` and `scene.targetDisplayTimer`). Clear the target when the entity dies (`health.current <= 0`) or when the timer expires so systems automatically stop drawing UI.

- **Monster death handling**
  - Extend the combat system so when `health.current` reaches `0`, it removes AI-specific components (`scene:removeComponent(id, "chase")`, etc.) and queues a `death` payload in `scene.pendingCombatEvents`. Defer entity removal until any death animation or loot spawn has finished to keep systems deterministic.

- **Loot entity & components (`Diablo.love/components/lootable.lua`, `Diablo.love/entities/loot.lua`)**
  - Create a loot entity factory that returns an entity table with an `id`, `position`, `lootable`, `renderable`, and optional `hoverable` component. Call `scene:addEntity(lootEntity)` so ECS registers every component set.
  - The `lootable` component should carry the rolled item payload, a `pickupRadius`, and a `source` tag. Because ECS tracks components by table identity, mutate fields rather than replacing the `lootable` table if the item changes.

- **Tooltip reuse**
  - Extract inventory tooltip rendering into `Diablo.love/system_helpers/tooltips.lua`. Both the inventory scene and a new `systems/loot_tooltip.lua` draw system can call it by passing the hovered entity and item payload.

- **Pickup interaction**
  - Handle click-to-pickup inside a dedicated system (`Diablo.love/systems/loot_pickup.lua`) that runs after player input. It should query `scene:queryEntities({ "lootable", "position" })`, test cursor distance using the coordinate helper, and when the player clicks:
    - Transfer the item into `player.inventory.items` (mutate existing tables).
    - Optionally auto-equip if the slot is empty by mutating `player.equipment.slots`.
    - Remove the entity with `scene:removeEntity(lootEntity.id)` to keep component sets accurate.

- **Persistence & cleanup**
  - Ensure loot entities are ignored by systems that only care about `movement` or AI components. If the loot should despawn, store `lootable.despawnTimer` and decrement it in the pickup system, removing the entity via ECS when the timer elapses.

- Register new systems in `Diablo.love/scenes/world.lua` in ECS-friendly order (update list):
  1. `applyStatsSystem.update`
  2. `playerInputSystem.update`
  3. `playerAttackSystem.update`
  4. `lootPickupSystem.update`
  5. `spawnSystem.update`
  6. `cullingSystem.update`
  7. `detectionSystem.update`
  8. `wanderSystem.update`
  9. `chaseSystem.update`
  10. `combatSystem.update`
  11. `movementSystem.update`
  12. `cameraSystem.update`

  Draw list should append `renderHealthSystem.draw` and `uiTargetSystem.draw` after existing renderers so ECS-managed entities stay in sync with the HUD.
- When adding components at runtime, prefer `scene:addComponent`/`scene:removeComponent` to keep `componentSets` authoritative. Only mutate fields on existing component tables to maintain references used by systems.
- Update `Readme.md` once features land to describe combat controls and loot loop.
- Run `luacheck .` after implementation to maintain lint cleanliness (per AGENTS instructions).
