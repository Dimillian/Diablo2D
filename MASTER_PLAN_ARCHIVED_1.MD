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
- **Player combat component (`Diablo.love/components/combat.lua`)** ✅
  - ✅ Added reusable combat stats (attack speed, range, cooldown, swing state, base damage, crit chance) with safe defaults so systems mutate shared tables in place.
  - ✅ Player and foe factories attach the component; foes also gained a `foe` tag for reliable queries.

- **Attack input system (`Diablo.love/systems/player_attack.lua`)** ✅
  - ✅ Runs after mouse movement, decrements cooldown, resolves mouse targets, and queues attacks using aggregated stats to reset timers.
  - ✅ Updates `scene.currentTargetId` and `scene.targetDisplayTimer` to feed downstream HUD systems.

- **Target acquisition (`Diablo.love/system_helpers/targeting.lua`)** ✅
  - ✅ Converts cursor coordinates to world space, selects the closest foe in range, and auto-clears when foes die or timers expire.

- **Animation stub (`Diablo.love/systems/render_equipment.lua`)** ✅
  - ✅ Weapon sprites swing via sine offsets while `combat.swingTimer` is active, giving instant attack feedback.

### Combat 2: Damage Resolution ✅ COMPLETED
- **Damage system (`Diablo.love/systems/combat.lua`)** ✅
  - ✅ Consumes queued attacks, rolls damage from aggregated stats, mutates health in place, marks recently damaged foes, and pushes structured `damage`/`death` events.
  - ✅ Removes AI components, marks entities dead, clears targeting, and removes foes from ECS after death cleanup.

- **World scene integration (`Diablo.love/scenes/world.lua`)** ✅
  - ✅ Scene tracks `time`, `lastUpdateDt`, and `pendingCombatEvents`; update loop includes attack, loot pickup, combat, loot drop, and existing AI/movement systems.

- **Top-of-screen target frame (`Diablo.love/systems/ui_target.lua`)** ✅
  - ✅ Renders focus name and health bar after the player HUD, fading automatically when timers expire.

- **Floating enemy bars (`Diablo.love/systems/render_health.lua`, `Diablo.love/components/recently_damaged.lua`)** ✅
  - ✅ Recently damaged foes display overhead health bars while their timer is active.

- **Floating damage numbers (`Diablo.love/systems/render_damage_numbers.lua`, `Diablo.love/components/floating_damage.lua`)** ✅
  - ✅ Damage events spawn temporary entities that float, fade, and self-remove using world delta time and gravity tweaks.

- **Loot loop (`Diablo.love/systems/loot_drops.lua`, `Diablo.love/systems/render_loot.lua`, `Diablo.love/entities/loot.lua`, `Diablo.love/systems/loot_pickup.lua`, `Diablo.love/systems/loot_tooltip.lua`, `Diablo.love/system_helpers/tooltips.lua`)** ✅
  - ✅ Death events roll loot, spawn rarity-bordered drops with centered sprites, support click-to-pickup/auto-equip, despawn timers, and shared tooltip rendering.

- **System registration (`Diablo.love/scenes/world.lua`)** ✅
  - ✅ Update order: `starterGear`, `applyStats`, `playerInput`, `mouseLook`, `mouseMovement`, `playerAttack`, `lootPickup`, `spawn`, `culling`, `detection`, `wander`, `chase`, `combat`, `lootDrop`, `movement`, `camera`.
  - ✅ Draw order adds `renderLoot`, `renderHealth`, `renderDamageNumbers`, `uiTarget`, and `lootTooltip` between existing world and HUD layers.

- **Foe templates (`Diablo.love/data/foe_types.lua`, `Diablo.love/systems/spawn.lua`)** ✅
  - ✅ Foes spawn with health/combat stats per archetype so combat resolution produces meaningful values.

- ✅ `luacheck .` passes after integration; README refresh pending once combat controls and loot loop are documented.


- When adding components at runtime, prefer `scene:addComponent`/`scene:removeComponent` to keep `componentSets` authoritative. Only mutate fields on existing component tables to maintain references used by systems.
- Update `Readme.md` once features land to describe combat controls and loot loop.
- Run `luacheck .` after implementation to maintain lint cleanliness (per AGENTS instructions).
