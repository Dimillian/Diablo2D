# Upcoming Feature Master Plan

## Movement: WASD With Mouse Steering
- **Input capture (systems/player_input.lua)**
  - Keep the existing WASD mapping but augment `playerInputSystem.update` to also read the mouse cursor in world coordinates. Use the world camera (`world.camera`) to translate `love.mouse.getPosition()` into world space so the direction vector is computed relative to the player's `position` component.
  - Replace the current `dx/dy` assignment with logic that stores two pieces of state on the player entity:
    - `movement.intentForward` (boolean) is true when `w`/`up` is held.
    - `movement.intentStrafe` keeps the lateral keyboard vector for optional strafe/backpedal moves (still allow `a/d` and `s` to move without mouse steering).
  - When forward input is pressed, set a `movement.targetHeading` vector pointing from player position toward the mouse location. Smoothly interpolate the current heading toward this target each frame (e.g., using `movement.headingLerp = 0.2`).

- **Movement resolution (systems/movement.lua)**
  - Extend movement components to include `heading` (normalized `x/y`) and `currentSpeed`. During `movementSystem.update`, derive the final velocity from:
    - Forward component: `movement.intentForward` * `movement.heading`.
    - Strafe/backpedal: reuse raw keyboard vector when `movement.intentStrafe` or backward input is active.
  - Normalize the combined vector and scale by `movement.speed`. Apply smooth heading updates so the player rotates toward the mouse even when stationary by gradually adjusting `movement.heading` each frame.
  - Reset `intent` flags after applying so the ECS component only carries persistent heading/orientation values between frames.

- **Component updates (components/movement.lua)**
  - Add defaults for `heading = { x = 0, y = -1 }`, `intentForward = false`, `intentStrafe = { x = 0, y = 0 }`, and `headingLerp = 0.2`. Ensure new fields are included when foes are instantiated so AI systems can reuse them if needed.

- **Camera-facing utilities (system_helpers)**
  - Introduce a helper (e.g., `system_helpers.coordinates.toWorldFromScreen(camera, x, y)`) to centralize screen→world conversion so both player input and future mouse-driven systems share identical math.

## New Game: Guaranteed Starter Item
- **Starting inventory hookup (scenes/world.lua)**
  - After creating the player entity, generate a starter item via `items/generator.lua` with rarity forced to common. Add a utility in the generator to accept an options table `{ forcedRarity = "common", allowedTypes = {"sword", "axe"} }`.
  - Equip the item automatically by inserting it into `player.equipment.slots.weapon`. Also push a copy into `player.inventory.items` so the UI sees it. Ensure the equipment system recomputes stats by invoking `EquipmentHelper.computeTotalStats` on first update.

- **Generator extension (items/generator.lua)**
  - Provide an API `ItemGenerator.roll(opts)` that respects optional parameters for rarity and type overrides. Reuse the existing weighted logic when overrides are absent so spawn/loot tables keep their behavior.
  - Mark starter gear as `source = "starter"` to support future quest logic or exclusion from drops.

## Combat System Foundations
### Combat 1: Click-to-Attack With Cooldown
- **Player combat component (components/combat.lua)**
  - Create a new component storing combat stats: `attackSpeed`, `cooldown`, `range`, `queuedAttack`, and `animationTime`. Attach it to the player entity in `entities/player.lua`, seeding `attackSpeed` from `baseStats.attackSpeed` or equipment stats.

- **Attack input system (systems/player_attack.lua)**
  - New update system inserted after `player_input` but before `movement`. Detect `love.mouse.isDown(1)` and, if the player has a valid target (see detection below), schedule an attack by setting `queuedAttack = { targetId, timestamp }` when `cooldown <= 0`.
  - Maintain `player.combat.cooldown` by decrementing with `dt`. When an attack is triggered, set `cooldown = 1 / effectiveAttackSpeed`. Use total stats (`EquipmentHelper.computeTotalStats`) to determine `effectiveAttackSpeed = 1 + totalStats.attackSpeed`.

- **Target acquisition**
  - Extend detection/chase systems or add a helper to find the closest foe under the cursor when clicking. Reuse `world:queryEntities({"foeTag", "position", "health"})` (add a simple `foeTag` component when foes are created). Intersect the mouse ray or simple distance check to allow attacks only within `combat.range` (~120px).

- **Animation stub**
  - During an active attack, add a minor oscillation to the equipped weapon sprite in `systems/render_equipment.lua` using `player.combat.animationTime` (sine wave scaled by time remaining). Reset when cooldown completes.

### Combat 2: Damage Resolution
- **Damage system (systems/combat.lua)**
  - Consume queued attacks each frame. Validate the target entity still exists, is alive (`health.current > 0`), and within range before applying damage.
  - Compute damage using:
    - Base weapon damage from equipped item (`EquipmentHelper.computeTotalStats` already aggregates `damageMin`/`damageMax`).
    - Apply random roll between min/max and add crit handling via `totalStats.critChance`.
    - Subtract target defense/resistance once foe stats are introduced (stub with constant for now).
  - Apply damage by mutating `target.health.current = max(0, current - damageAmount)`. Emit an event-like table (`world:dispatchEvent("damage", {...})`) so UI and loot logic can react without tight coupling.

### Combat 3: Monster Health UI
- **Top-of-screen target frame (systems/ui_target.lua)**
  - Add a new draw system after `ui_player_status`. When `world.currentTargetId` is set (attack target or last hit foe), render a framed bar at the top center showing `monsterName` and `health.current/max`. Use `love.graphics.printf` similar to the player HUD.

- **Floating enemy bars**
  - Augment `systems/render.lua` (or a dedicated `systems/render_health.lua`) to iterate foes with `health` and `recentlyDamaged` flags. Draw a small bar above the enemy's position using camera translation already in effect. Toggle `recentlyDamaged` when the damage system processes a hit and decay it over ~2 seconds via a timer stored in the foe component.

- **State tracking**
  - Store combat focus on the world object (`world.currentTargetId`, `world.targetDisplayTimer`). Reset when the target dies or timer expires so UI hides when leaving combat.

## Loot Flow
- **Monster death handling**
  - Extend the combat system to detect when `target.health.current` reaches 0. Remove combat-related components (e.g., `chase`, `wander`) and flag for removal once the death animation finishes. Trigger a loot spawn routine.

- **Loot entity & components (components/lootable.lua, entities/loot.lua)**
  - Create a lightweight entity with `position`, `loot` (item payload), `renderable` (sprite or icon), and `pickupRadius`. Store the generated item (again using `ItemGenerator.roll`) with rarity weighting but allow overrides from monster templates later.
  - Add this entity to the world when a monster dies. Optionally push to a `world.lootEntities` list for quick queries.

- **Tooltip reuse**
  - The inventory scene already draws item tooltips; extract that logic into `system_helpers.tooltip` so both the inventory UI and the world scene can call it. When the cursor hovers over a loot entity (distance check), invoke the helper to render the tooltip near the cursor.

- **Pickup interaction**
  - Detect `love.mouse.isDown(1)` while hovering or implement a simple `love.mousepressed` hook in `WorldScene` to collect the loot. On pickup:
    - Remove the loot entity via `world:removeEntity(id)`.
    - Insert the item into `player.inventory.items` and, if the slot is empty, auto-equip.
    - Emit a short-lived floating text via a planned `systems/combat_feedback.lua` (optional future work) or at least log a message to the console for debugging.

- **Persistence & cleanup**
  - Ensure loot entities respect `cullingSystem` so off-screen drops stay active but are skipped from costly updates. Add a timeout or manual cleanup when leaving the scene.

## Integration Checklist
- Register new systems in `scenes/world.lua` update/draw lists in sensible order:
  1. `applyStatsSystem`
  2. `playerInputSystem`
  3. `playerAttackSystem`
  4. `spawnSystem`
  5. `cullingSystem`
  6. `detectionSystem`
  7. `wanderSystem`
  8. `chaseSystem`
  9. `combatSystem`
  10. `movementSystem`
  11. `cameraSystem`

  Draw order should append `uiTargetSystem.draw` and the new foe health overlay.
- Add any new component modules to entity factories (player, foe, loot) and ensure ECS `componentSets` remain consistent by using `addComponent` when mutating at runtime.
- Update `Readme.md` after implementation to describe combat controls and loot loop.
- Run `luacheck .` to keep lint clean (per AGENTS instructions) once features are implemented.
