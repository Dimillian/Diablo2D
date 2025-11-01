# Upcoming Feature Master Plan

## Movement: Keyboard-Based With Mouse Look Indicator ✅ COMPLETED
- **Movement remains keyboard-only (`Diablo.love/systems/player_input.lua`)** ✅
  - ✅ No changes made—existing WASD/ZQSD/arrow key movement remains exactly as-is.

- **Mouse look tracking (`Diablo.love/systems/mouse_look.lua`)** ✅
  - ✅ Created update system that runs after `player_input` and before `movement`.
  - ✅ Queries entities with `movement` and `playerControlled` components.
  - ✅ Uses `love.mouse.getPosition()` and converts to world space via coordinate helper.
  - ✅ Computes direction vector from player center to mouse cursor in world space.
  - ✅ Stores normalized look direction as `movement.lookDirection = { x, y }` (mutates existing table).
  - ✅ Updates every frame to track current mouse position.
  - ✅ Includes safety check to ensure `lookDirection` exists before mutation.

- **Visual arrow indicator (`Diablo.love/systems/render_mouse_look.lua`)** ✅
  - ✅ Created draw system registered after `renderEquipmentSystem.draw` and before `uiPlayerStatus.draw`.
  - ✅ Queries player entity using `scene:getPlayer()` and checks for `movement.lookDirection`.
  - ✅ Draws arrow shape as triangle polygon using `love.graphics.polygon()`.
  - ✅ Arrow positioned on fixed-radius circle around player center: `playerRadius + 20` pixels (prevents overlap with player sprite).
  - ✅ Arrow moves along invisible circle based on `lookDirection` vector, rotating around player center.
  - ✅ Arrow rotation computed using `math.atan2(lookDirection.y, lookDirection.x)`.
  - ✅ Uses `love.graphics.push()`/`pop()` with `translate()` and `rotate()` for positioning/orientation.
  - ✅ Drawn within camera transform context (appears in world space).
  - ✅ Styled with light yellow color (RGB: 1, 1, 0.7) and 0.7 opacity.
  - ✅ Sized at 1.2x player sprite size for visibility.

- **Component defaults (`Diablo.love/components/movement.lua`)** ✅
  - ✅ Added default `lookDirection = { x = 0, y = -1 }` to movement component factory.
  - ✅ Initializes to point upward (negative Y) by default.
  - ✅ Foes use default value but aren't processed by mouse look system (no `playerControlled` component).

- **Camera/world coordinate conversion (`Diablo.love/system_helpers/coordinates.lua`)** ✅
  - ✅ Created helper module with `toWorldFromScreen(camera, screenX, screenY)` function.
  - ✅ Implements coordinate transform: `worldX = screenX + camera.x`, `worldY = screenY + camera.y`.
  - ✅ Initialized during scene setup (`WorldScene.new`) and stored at `scene.systemHelpers.coordinates`.
  - ✅ Available for reuse by future combat/targeting systems.

## Movement: Mouse-Based Right-Click Movement ✅ COMPLETED
- **Right-click movement system (`Diablo.love/systems/mouse_movement.lua`)** ✅
  - ✅ Created a new update system that runs after `mouseLookSystem` and before `movement`. Queries entities with `movement` and `playerControlled` components.
  - ✅ Checks `love.mouse.isDown(2)` (right mouse button) each frame. When held, overrides keyboard movement.
  - ✅ Uses `love.mouse.getPosition()` to get current mouse cursor position in screen coordinates.
  - ✅ Converts mouse position to world space using the existing coordinate helper (`scene.systemHelpers.coordinates.toWorldFromScreen`).
  - ✅ Computes direction vector from player center position to mouse cursor position in world space.
  - ✅ Calculates distance to target using `vector.distance()`. If within threshold (8 pixels), sets `movement.vx = 0` and `movement.vy = 0` to stop movement (prevents jitter when reaching destination).
  - ✅ If beyond threshold, normalizes the direction vector using `vector.normalize()` and sets `movement.vx` and `movement.vy` using the normalized direction values.
  - ✅ When right-click is not held, the system returns early without modifying `movement.vx`/`movement.vy`, allowing keyboard input to work normally.
  - ✅ The existing `movementSystem` handles applying speed and moving the entity based on these velocity values.

- **Integration with keyboard movement** ✅
  - ✅ Right-click movement takes precedence over keyboard input. When right-click is held, keyboard input is overridden for that frame.
  - ✅ System execution order: `playerInputSystem` (sets keyboard velocities) → `mouseLookSystem` (updates look direction) → `mouseMovementSystem` (overrides velocities if right-click held) → `movementSystem` (applies velocities).
  - ✅ Allows seamless switching between keyboard and mouse movement without conflicts.

- **System registration (`Diablo.love/scenes/world.lua`)** ✅
  - ✅ Registered `mouseMovementSystem.update` in the update list after `mouseLookSystem.update` and before `movementSystem.update`.
  - ✅ Update list order: `playerInputSystem.update` → `mouseLookSystem.update` → `mouseMovementSystem.update` → `movementSystem.update`.
  - ✅ Ensures mouse look updates first (for visual indicator), then mouse movement can override velocities, then movement system applies them.

- **Reuse existing infrastructure** ✅
  - ✅ Leverages the coordinate helper already created for mouse look system.
  - ✅ Uses the same ECS query pattern (`queryEntities({ "movement", "playerControlled" })`).
  - ✅ Mutates existing `movement.vx` and `movement.vy` values (same pattern as keyboard input) to maintain ECS component references.

## New Game: Guaranteed Starter Item ✅ COMPLETED
- **Starter gear system (`Diablo.love/systems/starter_gear.lua`)** ✅
  - ✅ Created dedicated update system that runs once per world scene initialization.
  - ✅ Uses flag (`world.starterGearGenerated`) to prevent re-running on subsequent update cycles.
  - ✅ Generates full starter set: weapon (sword or axe) + 3 armor pieces (helmet, chest, boots).
  - ✅ All items generated with `ItemGenerator.roll()` using `rarity = "common"` and `source = "starter"` tag.
  - ✅ Uses ECS-safe helpers: mutate existing `player.inventory.items` table in place and `EquipmentHelper.ensure()` to guarantee components exist.
  - ✅ Auto-equips all starter gear via `EquipmentHelper.equip()` which mutates the existing equipment table.
  - ✅ Stats recompute automatically via `applyStatsSystem` which runs after starter gear generation.

- **System registration (`Diablo.love/scenes/world.lua`)** ✅
  - ✅ Registered `starterGearSystem.update` at the start of the update list (runs first, before `applyStatsSystem`).
  - ✅ World scene constructor simplified—removed inline starter gear generation code (now handled by dedicated system).
  - ✅ Follows ECS pattern: world scene handles entity setup, system handles gear generation logic.

- **Generator extension (`Diablo.love/items/generator.lua`)** ✅
  - ✅ Added `ItemGenerator.roll(opts)` API that accepts optional parameters for rarity and type overrides.
  - ✅ Supports string IDs (e.g., `rarity = "common"`) or full ItemData entries for flexibility.
  - ✅ Supports `allowedTypes` array (e.g., `{"sword", "axe"}`) to randomly select from multiple types.
  - ✅ Supports `source` tag (e.g., `source = "starter"`) which is added to item payload for filtering.
  - ✅ Falls back to weighted defaults when options not provided (maintains existing drop behavior).

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

- Register new systems in `Diablo.love/scenes/world.lua` in ECS-friendly order:
  - ✅ **Update list (completed):**
    1. ✅ `starterGearSystem.update` (registered first, generates starter gear on new game)
    2. ✅ `applyStatsSystem.update`
    3. ✅ `playerInputSystem.update`
    4. ✅ `mouseLookSystem.update` (registered after playerInputSystem, before movementSystem)
    5. ✅ `mouseMovementSystem.update` (registered after mouseLookSystem, before movementSystem)
    6. `playerAttackSystem.update` (pending)
    7. `lootPickupSystem.update` (pending)
    8. ✅ `spawnSystem.update`
    9. ✅ `cullingSystem.update`
    10. ✅ `detectionSystem.update`
    11. ✅ `wanderSystem.update`
    12. ✅ `chaseSystem.update`
    13. `combatSystem.update` (pending)
    14. ✅ `movementSystem.update`
    15. ✅ `cameraSystem.update`

  - ✅ **Draw list (completed):**
    - ✅ `renderSystem.draw`
    - ✅ `renderEquipmentSystem.draw`
    - ✅ `renderMouseLookSystem.draw` (registered after renderEquipmentSystem, before uiPlayerStatus)
    - ✅ `uiPlayerStatus.draw`
    - `renderHealthSystem.draw` (pending)
    - `uiTargetSystem.draw` (pending)
- When adding components at runtime, prefer `scene:addComponent`/`scene:removeComponent` to keep `componentSets` authoritative. Only mutate fields on existing component tables to maintain references used by systems.
- Update `Readme.md` once features land to describe combat controls and loot loop.
- Run `luacheck .` after implementation to maintain lint cleanliness (per AGENTS instructions).
