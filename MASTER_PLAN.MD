# Master Plan - Upcoming Features

This document outlines concrete implementation details for upcoming features. Each section provides actionable guidance that fits within the existing ECS architecture.

---

## 1. Foe Attack System ✅ **COMPLETED**

### Overview
Add offensive capabilities to foes so they can attack the player when in melee range. Foes should visually strike the player, show damage numbers, apply a brief knockback effect, and have a cooldown between attacks. Player attack range must be longer than foe attack range to maintain gameplay balance.

### Implementation Status: **COMPLETE**

All core functionality has been implemented:
- ✅ Foe attack system with cooldown and range checking
- ✅ Knockback component and application
- ✅ Visual strike indicator (red tint on damage)
- ✅ Damage numbers via existing combat event system
- ✅ Foe type-specific attack ranges (45-50px vs player's 100px)

### Implementation Details

#### Components

**✅ `components/knockback.lua` - IMPLEMENTED**
- Fields: `x`, `y`, `timer`, `maxTimer`, `strength`
- Created via `createKnockback()` factory function
- Applied to both attacker and target when combat occurs (in `systems/combat.lua`)

#### Systems

**✅ `systems/foe_attack.lua` - IMPLEMENTED**
- Queries entities with `foe`, `chase`, `combat`, `position` components
- Decrements cooldown each frame: `combat.cooldown = math.max((combat.cooldown or 0) - dt, 0)`
- For each foe chasing player:
  - Calculates distance using `getEntityCenter()` helper
  - Checks if within attack range: `distance <= (foe.combat.range or 80)`
  - Checks cooldown readiness: `foe.combat.cooldown <= 0`
  - Sets `queuedAttack` with target and range
  - Sets cooldown: `combat.cooldown = 1 / (combat.attackSpeed or 0.8)`
  - Sets swing timer: `combat.swingTimer = combat.swingDuration or 0.3`

**✅ `systems/movement.lua` - MODIFIED**
- Applies knockback as direct position offset when `knockback` component exists
- Uses `strength` field (pixels per second) to control knockback intensity
- Automatically removes knockback component when timer expires

**✅ `systems/combat.lua` - MODIFIED**
- Adds knockback to both attacker and target when hit occurs
- Knockback direction: attacker pushed away from target, target pushed away from attacker
- Uses 80 pixels/second strength with 0.2 second duration
- Existing damage processing, events, and `recentlyDamaged` component remain unchanged

**✅ `systems/render.lua` - MODIFIED**
- Visual strike indicator: tints entity red when `recentlyDamaged` component exists
- Provides immediate visual feedback when player or foes take damage

#### Entity Changes

**✅ `entities/foe.lua` - MODIFIED**
- `Foe.new()` now creates `combat` component with values from config:
  - `range = config.range` (from foe type)
  - `attackSpeed = config.attackSpeed`
  - `baseDamageMin = config.damageMin`
  - `baseDamageMax = config.damageMax`

**✅ `data/foe_types.lua` - MODIFIED**
- All foe types now include `range` field:
  - `slow`: `range = 45` (slowest but longest reach)
  - `medium`: `range = 50` (standard range)
  - `aggressive`: `range = 50` (fast but shorter reach)
- Note: All ranges are significantly shorter than player's 100px range

**✅ `systems/spawn.lua` - NO CHANGES NEEDED**
- Already passes config to `Foe.new()`, which extracts range and other combat values

#### System Registration

**✅ `scenes/world.lua` - MODIFIED**
- `foeAttackSystem.update` registered in update systems
- Correct order: `detectionSystem.update`, `chaseSystem.update`, `foeAttackSystem.update`, `combatSystem.update`

#### Visual Feedback

**✅ `systems/render_damage_numbers.lua`**
- Already handles damage number display via combat events
- No changes needed

**✅ `systems/render.lua` - Visual Strike Indicator**
- Red tint flash applied when `recentlyDamaged` component exists
- Provides clear visual feedback for incoming damage

### Implementation Notes

- **Attack Ranges**: Player (100px) is significantly longer than all foe types (45-50px), maintaining gameplay balance
- **Knockback**: Applied to both parties during combat for more dynamic feel
- **Cooldown**: Foes use their type-specific `attackSpeed` values, ensuring variety in combat pacing
- **Visual Feedback**: Red tint on damage + floating damage numbers provide clear combat feedback

---

## 2. Potion System ✅ **COMPLETED**

### Overview
Players now carry dedicated health and mana potions, consume them from the bottom bar (keys `1`/`2` or mouse clicks), and restock via monster drops. Potion counts are visible both in the HUD and inside the inventory scene.

### Implementation Status: **COMPLETE**

- ✅ Added reusable `potions` component with default starter counts and cooldown tracking.
- ✅ Hooked potion consumption into the world scene (keyboard + clickable HUD icons) with shared cooldown logic.
- ✅ Displayed potion counts next to the health/mana bars and within the inventory UI, including disabled/cooldown feedback.
- ✅ Enabled foes to drop potions alongside normal loot and integrated potion pickup into the existing loot system.

### Implementation Details

#### Components & Entity Setup

**✅ `components/potions.lua` - NEW**
- Provides `healthPotionCount`, `manaPotionCount`, max stack sizes, and shared cooldown metadata.

**✅ `entities/player.lua` - MODIFIED**
- Automatically attaches the new potions component when the player entity is created (defaults to 3 health / 2 mana potions).

#### Data & Generation

**✅ `data/items.lua` - UPDATED**
- Added `health_potion` and `mana_potion` consumable entries with restore values and a flag to exclude them from normal equipment rolls.

**✅ `items/generator.lua` - UPDATED**
- Filters out consumable item types (`excludeFromRandom`) so random gear drops remain unaffected while allowing explicit potion creation.

#### Systems & Game Logic

**✅ `systems/core/potion_consumption.lua` - NEW**
- Handles per-frame cooldown decay and the actual consume logic for keys `1`/`2` or UI clicks.
- Restores 25 HP or 15 mana, decrements counts, and enforces a 0.5s shared cooldown.

**✅ `scenes/world.lua` - MODIFIED**
- Registers the potion system in the update loop and forwards `keypressed`/`mousepressed` events for hotkeys and HUD clicks.

**✅ `systems/core/loot_pickup.lua` - MODIFIED**
- Detects potion loot and increments the player’s potion stacks (respecting max counts) instead of routing items through inventory/equipment.

**✅ `systems/core/loot_drops.lua` - MODIFIED**
- Gives slain foes a 15% chance to drop a potion (red for health, blue for mana) in addition to their regular loot roll.

#### UI & Inventory Updates

**✅ `systems/ui/bottom_bar.lua` - ENHANCED**
- Draws potion icons with hotkey badges, live counts, disabled states when full/out-of-stock, and cooldown shading.
- Stores hitboxes for click detection so the world scene can trigger consumption.

**✅ `systems/render/inventory_grid.lua` & `scenes/inventory.lua` - UPDATED**
- Track the rendered grid bounds each frame so downstream systems can anchor extra UI (like potion info) below the item slots.

**✅ `systems/render/inventory_potions.lua` - NEW**
- Renders a dedicated potion section beneath the inventory grid with icons and `current / max` counts for both potion types.

#### Additional Notes

- Potion defaults: 3 health / 2 mana, max stacks of 10 each, shared 0.5s cooldown.
- HUD icons disable when on cooldown, when the relevant resource is capped, or when out of potions.
- Potion loot uses the existing icon set and respects the normal loot despawn timers.

---

## 3. EXP System ✅ **COMPLETED**

### Overview
Implement an experience point (XP) system where players start at level 1 with 0 XP, gain XP from killing foes, and have a leveling table that scales XP requirements. Display an XP bar at the bottom of the screen showing current XP vs required XP for next level, filling the entire screen width for a gamey feel.

### Implementation Status: **COMPLETE**

All core functionality has been implemented:
- ✅ Experience component with level, currentXP, and xpForNextLevel fields
- ✅ Leveling module with XP calculation formulas (baseXP = 100, multiplier = 1.5)
- ✅ XP awarded on foe death (25 XP per kill)
- ✅ Level up system with stat bonuses (+5 health, +1 damage min/max, +1 defense)
- ✅ Full-width XP bar UI with visual feedback
- ✅ Multiple level ups handled correctly

### Implementation Details

#### Components

**✅ `components/experience.lua` - IMPLEMENTED**
- Fields: `level`, `currentXP`, `xpForNextLevel`
- Created via `createExperienceComponent()` factory function
- Initializes XP for next level using leveling table

#### Data

**✅ `modules/leveling.lua` - IMPLEMENTED**
- Provides `getXPForLevel()` for cumulative XP calculation
- Provides `getXPRequiredForNextLevel()` for level-to-level XP requirement
- Provides `getFoeXP()` for XP awards (currently 25 XP per kill)
- Uses exponential formula: baseXP = 100, multiplier = 1.5

#### Systems

**✅ `systems/combat/combat.lua` - MODIFIED**
- `handleDeath()` function captures `foeLevel` from target before entity removal
- Death event payload includes `foeLevel` field for XP calculation

**✅ `systems/core/experience.lua` - IMPLEMENTED**
- Processes combat events and awards XP for player kills
- Handles level up logic with while loop to support multiple level ups in one frame
- Grants stat bonuses on level up: +5 health, +1 damage min/max, +1 defense
- Updates `xpForNextLevel` for UI display

**✅ `systems/ui/experience_bar.lua` - IMPLEMENTED**
- Draws full-width XP bar at bottom of screen (via UIConfig positioning)
- Displays level number, current XP progress, and required XP for next level
- Visual design: dark background, blue fill, light outline, centered text
- Positioned dynamically based on screen dimensions

#### Entity Changes

**✅ `entities/player.lua` - MODIFIED**
- `experience` component added to player creation with default level 1, 0 XP
- XP for next level initialized using leveling table

#### System Registration

**✅ `scenes/world.lua` - MODIFIED**
- `experienceSystem.update` registered in update systems (after `lootDropSystem.update`)
- `uiExperienceBar.draw` registered via `uiMain.draw` system (after `uiPlayerStatus.draw`)

#### Level Up Rewards

**✅ Level Up Rewards - IMPLEMENTED**
- On level up, stat bonuses are granted:
  - +5 max health (updates `baseStats.health`)
  - +1 damage min/max (updates `baseStats.damageMin`/`damageMax`)
  - +1 defense (updates `baseStats.defense`)
- **Integration with `systems/apply_stats.lua`**:
  - Level bonuses stored in `baseStats` component
  - `apply_stats` system automatically recalculates total stats on next frame
  - Health max/current updated automatically when baseStats change

### Implementation Notes

- **XP Calculation**: Uses exponential formula with baseXP = 100, multiplier = 1.5
- **XP per Kill**: Fixed 25 XP per foe kill (future-proofed for level-scaling)
- **Level Up Bonuses**: Applied to `baseStats` so they combine with equipment stats
- **Multiple Level Ups**: Handled correctly with while loop to process all level ups in one frame
- **XP Bar**: Full-width display at bottom of screen with visual feedback

---

## 4. Magic/Skills System ✅ **COMPLETED**

### Overview
Implement a magic/skills system where players can equip up to 4 skills and cast them using hotkeys (1/2/3/4). Skills consume mana and can be projectiles that travel toward enemies and deal damage. A skills scene allows players to view available spells and manage equipped skills. The bottom bar displays equipped skills and includes a book icon to open the skills scene.

### Implementation Status: **COMPLETE**

All core functionality has been implemented:
- ✅ Skills component with 4 equipped slots
- ✅ Projectile component and entity system
- ✅ Skill casting system with hotkey support (1/2/3/4)
- ✅ Projectile movement and collision detection
- ✅ Skills scene with equip/unequip functionality
- ✅ Skills bar UI showing equipped skills
- ✅ Book icon in bottom bar to open skills scene
- ✅ Fireball spell as initial spell

### Implementation Details

#### Data

**✅ `data/spells.lua` - IMPLEMENTED**
- Fireball spell definition with all required fields
- Added `description` field for UI display
- Added `lifetime` field (2.5 seconds) for projectile despawn
- `Spells.getAll()` helper function returns ordered list of spells

#### Components

**✅ `components/skills.lua` - IMPLEMENTED**
- Provides `equipped` array with 4 slots (can be nil for empty slots)
- Initializes slots from provided source array or defaults to empty
- Component factory pattern matches codebase conventions

**✅ `components/projectile.lua` - IMPLEMENTED**
- Contains all required fields: `spellId`, `targetId`, `targetX`, `targetY`, `damage`, `ownerId`, `lifetime`, `maxLifetime`
- Added `speed` field for projectile movement speed
- Lifetime defaults to 3.0 seconds if not specified

#### Systems

**✅ `systems/skills/cast.lua` - IMPLEMENTED**
- Handles keypress for skill hotkeys (1/2/3/4)
- Uses queue-based system: `handleKeypress()` queues slot index, `update()` processes queue
- Mana checking happens before queuing (prevents spam when insufficient mana)
- Targeting logic:
  - Prioritizes current target (`world.currentTargetId`) if available
  - Falls back to player look direction (cast range 500px)
  - Final fallback to mouse position
- Projectile creation:
  - Spawns from caster center position
  - Calculates initial velocity direction toward target
  - Mana consumed only after successful projectile creation
- Integrated into `WorldScene:keypressed()` method

**✅ `systems/projectile/movement.lua` - IMPLEMENTED**
- Queries entities with `projectile`, `position`, `movement`, `size` components
- Decrements lifetime each frame and removes expired projectiles
- Updates target position dynamically:
  - If `targetId` exists, tracks target entity (clears if target dies)
  - Falls back to static `targetX`, `targetY` if no target entity
- Calculates normalized direction vector toward target each frame
- Sets movement velocity components (`vx`, `vy`) and speed from projectile component
- Uses `goto continue` pattern for performance

**✅ `systems/projectile/collision.lua` - IMPLEMENTED**
- Queries all projectiles and foes separately for efficiency
- Circular collision detection using entity center and radius
- Excludes owner from collision checks
- Damage calculation: `rollDamage()` helper function with min/max range
- Creates combat events for damage and death (integrates with existing combat system)
- Applies `recentlyDamaged` component for visual feedback
- Removes projectile on first hit (single target collision)
- Handles death cleanup and target clearing

**✅ `systems/render/projectile.lua` - IMPLEMENTED**
- Queries entities with `projectile`, `position`, `size`, `renderable` components
- Draws projectiles as filled circles using spell color
- Uses spell definition for projectile color override
- Respects camera translation for world space rendering
- Supports sprite rendering if `renderable.kind == "image"` (future feature)

**✅ `systems/ui/skills_bar.lua` - IMPLEMENTED**
- Draws 4 skill slots horizontally after book/bag icons
- Each slot: 32x32px with rounded corners, gold border
- Shows hotkey label (1/2/3/4) in bottom-right corner
- Displays skill icon if equipped (loaded via Resources module)
- Visual feedback: Gray overlay if insufficient mana
- Empty slots show subtle inner border
- Positioned dynamically based on bottom bar layout

**✅ `systems/ui/bottom_bar.lua` - MODIFIED**
- Refactored with shared `drawIconBox()` helper function
- Supports badges, shadows, cooldown overlays, disabled states
- Book icon added with "K" badge (positioned before bag icon)
- Stores `bottomBarBookRect` for click detection
- Book icon opens skills scene via scene manager
- Icon layout: health potion | mana potion | book | bag

**✅ `modules/scene_manager.lua` - MODIFIED**
- Added `toggleSkills(key)` method
- Uses "k" key (not "s" as originally planned) to toggle skills scene
- Handles "escape" key to close skills scene
- Similar pattern to `toggleInventory()` method

**✅ `scenes/world.lua` - MODIFIED**
- `skillCastSystem.update` registered in update systems (after `playerAttackSystem.update`)
- `projectileMovementSystem.update` registered in update systems (after `skillCastSystem.update`)
- `projectileCollisionSystem.update` registered in update systems (after `combatSystem.update`, before `movementSystem.update`)
- `skillCastSystem.handleKeypress` called in `WorldScene:keypressed()` method (handles keys 1-4)
- `renderProjectileSystem.draw` registered in draw systems (after `renderEquipmentSystem.draw`, before `renderMouseLookSystem.draw`)
- `uiSkillsBarSystem.draw` registered via `uiMain.draw` system (draws after bottom bar)
- Book icon click handled in `mousepressed()`: Checks `bottomBarBookRect` and opens skills scene

#### Entity Changes

**✅ `entities/projectile.lua` - IMPLEMENTED**
- Creates projectile entity with all required components
- Generates unique ID if not provided
- Initializes `position`, `size`, `movement`, `renderable`, `projectile` components
- Sets initial velocity (`vx`, `vy`) from normalized direction vector
- Uses `renderable.kind = "circle"` for rendering
- Supports color override from spell definition

**✅ `entities/player.lua` - MODIFIED**
- `skills` component added to player creation
- Defaults to empty equipped slots array
- Uses component factory pattern consistent with codebase

#### Scene Changes

**✅ `scenes/skills.lua` - IMPLEMENTED**
- Similar structure to `inventory.lua` scene
- Systems registered:
  - `renderSkillsBackground` - Draws background panel
  - `renderSkillsList` - Lists all available spells with icons and mana costs
  - `renderSkillsEquipped` - Shows 4 equipped skill slots
  - `renderSkillsHelp` - Shows help text
  - `renderSkillsTooltip` - Shows spell details on hover
- Mouse click handling:
  - Click on available spell: Equips to first empty slot (or replaces first slot if all full)
  - Click on equipped slot: Unequips skill from that slot
  - Prevents duplicate equipping (checks if spell already equipped)
- Key handling:
  - "k" or "escape": Closes skills scene (note: uses "k" not "s")
- Uses `SkillsLayout` helper for panel calculations

#### Rendering Systems

**✅ `systems/render/skills_background.lua` - IMPLEMENTED**
- Draws background panel for skills scene

**✅ `systems/render/skills_list.lua` - IMPLEMENTED**
- Lists all available spells with icons, labels, and mana costs
- Handles hover highlighting
- Stores clickable rects for equip functionality

**✅ `systems/render/skills_equipped.lua` - IMPLEMENTED**
- Renders 4 equipped skill slots
- Shows skill icons when equipped
- Handles click detection for unequipping

**✅ `systems/render/skills_help.lua` - IMPLEMENTED**
- Displays help text for skills scene

**✅ `systems/render/skills_tooltip.lua` - IMPLEMENTED**
- Shows spell details on hover

**✅ `systems/render/render_world.lua` - NO CHANGES NEEDED**
- Projectiles handled by dedicated `renderProjectileSystem`

#### Implementation Notes

- **Mana Consumption**: Spells consume mana immediately on cast; if insufficient mana, cast fails silently (returns false)
- **Projectile Targeting**: Prioritizes current target (`world.currentTargetId`), falls back to player look direction (500px range), then mouse position
- **Projectile Collision**: Uses circular collision detection; projectiles disappear on first hit
- **Skill Equipping**: Players can equip/unequip skills via the skills scene; maximum 4 equipped skills; prevents duplicate equipping
- **Hotkeys**: Skills triggered with number keys 1/2/3/4 (mapped to equipped slots); keys 1/2 prioritize potions if pressed without skill equipped
- **Fireball**: First and only spell initially; uses `resources/skills/fireball.png` for icon; 10 mana cost, 15-25 damage range
- **Skills Scene**: Accessed via "k" key (changed from original "s" plan) or clicking book icon in bottom bar
- **Bottom Bar**: Icon rendering logic extracted to shared `drawIconBox()` helper; supports badges, shadows, cooldown overlays
- **Queue System**: Skill casting uses queue-based system to prevent frame timing issues
- **Projectile Lifetime**: Default 2.5 seconds for fireball; projectiles despawn on timeout or collision

---

## Implementation Order Recommendation

1. ✅ **Foe Attack System** - **COMPLETED** - Combat loop is now complete with enemy attacks, knockback, and visual feedback
2. ✅ **EXP System** - **COMPLETED** - Foundation for progression with leveling, XP awards, and stat bonuses
3. ✅ **Potion System** - **COMPLETED** - Adds survivability with health/mana potions and cooldown mechanics
4. ✅ **Magic/Skills System** - **COMPLETED** - Adds ranged combat options with projectile spells, skills scene, and hotkey casting

---

## Testing Checklist

### Foe Attack System ✅ **COMPLETE**
- [x] Foes attack player when in range
- [x] Attack range is shorter than player attack range (45-50px vs 100px)
- [x] Damage numbers appear correctly
- [x] Cooldown prevents spam attacks
- [x] Player can kite foes effectively
- [x] Knockback applied to both attacker and target
- [x] Visual strike indicator (red tint) when damaged

### Potion System
- [x] Player starts with 3 health potions and 2 mana potions
- [x] Health potions restore 25 HP correctly
- [x] Mana potions restore 15 mana correctly
- [x] Potion count decreases on use
- [x] Health potion icon appears in UI next to health bar (key "1")
- [x] Mana potion icon appears in UI next to mana bar (key "2")
- [x] Potion icons are clickable (mouse click triggers consumption)
- [x] Potion icons show visual feedback (cooldown, insufficient resources)
- [x] Monsters can drop potions as loot (health or mana randomly)
- [x] Potion pickup adds to correct potion count
- [x] Cooldown prevents rapid potion consumption
- [x] Cannot use potions when already at max health/mana
- [x] Potions displayed in inventory scene below inventory grid
- [x] Inventory shows divider between items and potions
- [x] Inventory shows potion counts (current / max) for both types

### EXP System ✅ **COMPLETE**
- [x] Player starts at level 1 with 0 XP
- [x] Killing foes grants XP
- [x] XP bar displays correctly (full width)
- [x] Level up occurs at correct XP thresholds
- [x] XP requirements scale properly
- [x] Level number displays correctly
- [x] Stat bonuses applied on level up (+5 health, +1 damage min/max, +1 defense)
- [x] Multiple level ups handled correctly in single frame

### Magic/Skills System ✅ **COMPLETE**
- [x] Skills scene opens with "k" key or book icon click
- [x] Skills scene closes with "k" or "escape" key
- [x] Fireball spell can be equipped/unequipped in skills scene
- [x] Maximum 4 skills can be equipped
- [x] Equipped skills appear in bottom bar (4 slots)
- [x] Skills cast with hotkeys 1/2/3/4
- [x] Casting fireball consumes mana correctly
- [x] Cannot cast if insufficient mana
- [x] Fireball projectile spawns from player position
- [x] Fireball projectile travels toward target/mouse position (with smart targeting)
- [x] Fireball projectile renders correctly (orange-red circle)
- [x] Fireball projectile hits enemies on collision
- [x] Fireball projectile applies damage correctly
- [x] Fireball projectile despawns on hit or timeout
- [x] Damage numbers appear when fireball hits (via combat event system)
- [x] Book icon renders correctly next to bag icon
- [x] Bottom bar icon rendering helper works for all icons
