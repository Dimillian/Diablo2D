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

## 4. Magic/Skills System

### Overview
Implement a magic/skills system where players can equip up to 4 skills and cast them using hotkeys (1/2/3/4). Skills consume mana and can be projectiles that travel toward enemies and deal damage. A skills scene allows players to view available spells and manage equipped skills. The bottom bar displays equipped skills and includes a book icon to open the skills scene.

### Implementation Details

#### Data

**New Data File: `data/spells.lua`**
```lua
local Spells = {}

Spells.types = {
    fireball = {
        id = "fireball",
        label = "Fireball",
        manaCost = 10,
        damage = { min = 15, max = 25 },
        projectileSpeed = 300, -- pixels per second
        projectileSize = 12, -- radius or size for rendering
        projectileColor = { 1.0, 0.4, 0.1, 1 }, -- Orange-red fireball color
        icon = "resources/skills/fireball.png",
    },
    -- Future spells can be added here following the same structure
}

return Spells
```

#### Components

**New Component: `components/skills.lua`**
```lua
local function createSkillsComponent(opts)
    opts = opts or {}
    return {
        equipped = opts.equipped or {}, -- Array of 4 spell IDs (can be nil for empty slots)
        -- equipped[1] = "fireball", equipped[2] = nil, etc.
    }
end

return createSkillsComponent
```

**New Component: `components/projectile.lua`**
```lua
local function createProjectileComponent(opts)
    opts = opts or {}
    return {
        spellId = opts.spellId, -- Which spell this projectile belongs to
        targetId = opts.targetId, -- Entity ID this projectile is targeting (nil if targeting position)
        targetX = opts.targetX, -- Target X position (if no targetId)
        targetY = opts.targetY, -- Target Y position (if no targetId)
        damage = opts.damage, -- Damage to deal on hit
        ownerId = opts.ownerId, -- Entity ID that cast this (player)
        lifetime = opts.lifetime or 3.0, -- Max lifetime in seconds before projectile despawns
        maxLifetime = opts.maxLifetime or 3.0,
    }
end

return createProjectileComponent
```

#### Systems

**New System: `systems/skills/cast.lua`**
- Handle keypress for skill hotkeys (1/2/3/4)
- In `WorldScene:keypressed()` method, add:
  ```lua
  if key == "1" or key == "2" or key == "3" or key == "4" then
      skillCastSystem.handleKeypress(self, key)
  end
  ```
- In `handleKeypress()` function:
  - Get player entity: `world:getPlayer()`
  - Get slot index from key: `local slotIndex = tonumber(key)`
  - Check if player has skills component: `player.skills`
  - Get equipped spell: `local spellId = player.skills.equipped[slotIndex]`
  - If spellId is nil, return early (no skill equipped)
  - Get spell definition: `local spell = Spells.types[spellId]`
  - Check mana: `if player.mana.current < spell.manaCost then return end`
  - Consume mana: `player.mana.current = player.mana.current - spell.manaCost`
  - Cast spell: `skillCastSystem.castSpell(world, player, spell, slotIndex)`

**Cast Spell Logic (in `systems/skills/cast.lua`):**
```lua
function skillCastSystem.castSpell(world, caster, spell, slotIndex)
    -- Get caster position
    local casterX, casterY = getEntityCenter(caster)
    if not casterX then return end

    -- Determine target: use current target if available, otherwise use mouse position
    local targetX, targetY = nil, nil
    local targetId = nil

    if world.currentTargetId then
        local target = world:getEntity(world.currentTargetId)
        if target and target.health and not target.dead then
            targetX, targetY = getEntityCenter(target)
            targetId = target.id
        end
    end

    -- Fallback to mouse position if no target
    if not targetX then
        local mx, my = love.mouse.getPosition()
        local coords = world.systemHelpers.coordinates
        targetX, targetY = coords.toWorldFromScreen(world, mx, my)
    end

    -- Create projectile entity
    local ProjectileEntity = require("entities.projectile")
    local projectile = ProjectileEntity.new({
        x = casterX,
        y = casterY,
        targetX = targetX,
        targetY = targetY,
        targetId = targetId,
        spellId = spell.id,
        damage = spell.damage,
        ownerId = caster.id,
        speed = spell.projectileSpeed,
        size = spell.projectileSize,
        color = spell.projectileColor,
    })

    world:addEntity(projectile)
end
```

**New System: `systems/projectile/movement.lua`**
- Query entities with `projectile`, `position`, `movement` components
- For each projectile:
  - Decrement lifetime: `projectile.projectile.lifetime = projectile.projectile.lifetime - dt`
  - If lifetime <= 0, remove projectile: `world:removeEntity(projectile.id)`
  - Calculate direction toward target:
    - If `targetId` exists, get target entity and calculate direction
    - Otherwise use `targetX`, `targetY`
  - Set movement velocity: `movement.vx = directionX * projectile.projectile.speed`, `movement.vy = directionY * projectile.projectile.speed`

**New System: `systems/projectile/collision.lua`**
- Query entities with `projectile`, `position` components
- For each projectile:
  - Get owner: `world:getEntity(projectile.projectile.ownerId)`
  - Query nearby entities with `position`, `health` components (excluding owner)
  - Check collision with foes (circular collision detection):
    - Calculate distance between projectile center and foe center
    - If distance < (projectile.size.w/2 + foe.size.w/2) or similar radius check
    - If collision:
      - Calculate damage: `local damage = projectile.projectile.damage.min + math.random() * (projectile.projectile.damage.max - projectile.projectile.damage.min)`
      - Apply damage: `foe.health.current = math.max(0, foe.health.current - damage)`
      - Create damage event: `pushCombatEvent(world, { type = "damage", sourceId = projectile.projectile.ownerId, targetId = foe.id, amount = damage, crit = false, position = { x = foeX, y = foeY }, time = world.time })`
      - Check for death: `if foe.health.current <= 0 then handleDeath(world, foe, owner, { x = foeX, y = foeY }) end`
      - Remove projectile: `world:removeEntity(projectile.id)`
      - Break (projectile can only hit one target)

**New System: `systems/render/projectile.lua`**
- Query entities with `projectile`, `position`, `renderable` components
- For each projectile:
  - Get spell definition: `local spell = Spells.types[projectile.projectile.spellId]`
  - Draw projectile using `renderable` component:
    - For fireball: Draw filled circle with orange-red color
    - Position: `projectile.position.x`, `projectile.position.y`
    - Size: `spell.projectileSize` or `projectile.size.w`
    - Color: `spell.projectileColor` or `renderable.color`
    - Optional: Draw sprite if spell has icon and projectile supports sprites

**New System: `systems/ui/skills_bar.lua`**
- Draw equipped skills in bottom bar (next to bag/book icons)
- Position: Right of book icon, horizontally aligned
- For each equipped skill slot (1-4):
  - Draw skill slot rectangle (smaller than bag icon, e.g., 32x32)
  - If skill equipped: Draw skill icon from `spell.icon`
  - Draw hotkey label (1/2/3/4) in corner
  - Visual feedback: Highlight if skill is on cooldown (future) or if insufficient mana

**Modify: `systems/ui/bottom_bar.lua`**
- Refactor to share icon rendering logic:
  - Create helper function `drawIconButton(world, x, y, size, iconPath, keyLabel, onClickRect)`
  - Render bag icon using shared helper
  - Render book icon using shared helper (new, positioned next to bag icon)
  - Store rects for click detection: `world.bottomBarBookRect`
- Book icon opens skills scene (key "s" or click)
- Position: Right of health/mana bars, book icon before bag icon

**New System: `systems/skills/scene_management.lua`**
- Handle skills scene toggle (similar to inventory scene)
- In `SceneManager:toggleSkills(key)`:
  - Check if key is "s" or "escape"
  - Toggle skills scene on/off
  - Similar pattern to `toggleInventory()` in `scene_manager.lua`

**Modify: `scenes/world.lua`**
- Add `skillCastSystem.update` to update systems (after `playerAttackSystem.update`)
- Add `projectileMovementSystem.update` to update systems (after `skillCastSystem.update`)
- Add `projectileCollisionSystem.update` to update systems (after `combatSystem.update`, before `movementSystem.update`)
- Add `skillCastSystem.handleKeypress` call in `WorldScene:keypressed()` method
- Add `renderProjectileSystem.draw` to draw systems (after `renderEquipmentSystem.draw`, before `renderMouseLookSystem.draw`)
- Add `uiSkillsBarSystem.draw` to draw systems (after `uiBottomBar.draw`)
- Handle book icon click in `mousepressed()`: Check `bottomBarBookRect` and open skills scene

#### Entity Changes

**New Entity: `entities/projectile.lua`**
```lua
local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(opts)
    opts = opts or {}

    local createPosition = require("components.position")
    local createSize = require("components.size")
    local createMovement = require("components.movement")
    local createRenderable = require("components.renderable")
    local createProjectile = require("components.projectile")

    local entity = {
        id = opts.id or "projectile_" .. math.random(10000, 99999),
        position = createPosition({
            x = opts.x or 0,
            y = opts.y or 0,
        }),
        size = createSize({
            w = opts.size or 12,
            h = opts.size or 12,
        }),
        movement = createMovement({
            speed = opts.speed or 300,
        }),
        renderable = createRenderable({
            kind = "circle", -- or "image" if using sprite
            color = opts.color or { 1.0, 0.4, 0.1, 1 },
        }),
        projectile = createProjectile({
            spellId = opts.spellId,
            targetId = opts.targetId,
            targetX = opts.targetX,
            targetY = opts.targetY,
            damage = opts.damage,
            ownerId = opts.ownerId,
            lifetime = opts.lifetime or 3.0,
            maxLifetime = opts.lifetime or 3.0,
        }),
    }

    return setmetatable(entity, Projectile)
end

return Projectile
```

**Modify: `entities/player.lua`**
- Add `skills` component to player creation:
  ```lua
  local createSkills = require("components.skills")
  -- ...
  skills = createSkills(opts.skills or {
      equipped = {}, -- Empty by default
  }),
  ```

#### Scene Changes

**New Scene: `scenes/skills.lua`**
- Similar structure to `inventory.lua`
- Systems:
  - `renderSkillsBackground` - Draw background
  - `renderSkillsList` - List all available spells (currently only fireball)
  - `renderSkillsEquipped` - Show equipped skill slots (4 slots)
  - `renderSkillsHelp` - Show help text ("Click to equip/unequip, S to close")
  - `renderSkillsTooltip` - Show spell details on hover
- Mouse click handling:
  - Click on available spell: Equip to first empty slot (or replace first slot)
  - Click on equipped slot: Unequip skill
- Key handling:
  - "s" or "escape": Close skills scene

**Modify: `modules/scene_manager.lua`**
- Add `toggleSkills(key)` method similar to `toggleInventory(key)`
- Import `SkillsScene` from `scenes.skills`
- Handle "s" key to toggle skills scene

#### System Registration

**Modify: `scenes/world.lua`**
- Add `skillCastSystem.update` to update systems (after `playerAttackSystem.update`)
- Add `projectileMovementSystem.update` to update systems (after `skillCastSystem.update`)
- Add `projectileCollisionSystem.update` to update systems (after `combatSystem.update`, before `movementSystem.update`)
- Add `skillCastSystem.handleKeypress` call in `WorldScene:keypressed()` method
- Add `renderProjectileSystem.draw` to draw systems (after `renderEquipmentSystem.draw`, before `renderMouseLookSystem.draw`)
- Add `uiSkillsBarSystem.draw` to draw systems (after `uiBottomBar.draw`)
- Handle book icon click in `mousepressed()` method

**Modify: `scenes/skills.lua`**
- Register all render systems in `systems.draw` array
- Handle keyboard input in `keypressed()` method
- Handle mouse input in `mousepressed()` method

#### Rendering Changes

**Modify: `systems/render/render_world.lua`**
- Ensure projectiles are rendered (should already be handled by `renderProjectileSystem`)

**Modify: `systems/ui/bottom_bar.lua`**
- Refactor icon rendering into shared helper function
- Add book icon rendering next to bag icon
- Store `bottomBarBookRect` for click detection
- Position book icon to the left of bag icon

**New System: `systems/ui/skills_bar.lua`**
- Draw 4 skill slots horizontally after book/bag icons
- Each slot: 32x32px rectangle
- If skill equipped: Draw icon from `spell.icon` (resize to fit)
- Draw hotkey label ("1"/"2"/"3"/"4") in corner
- Visual state: Gray out if insufficient mana

#### Implementation Notes

- **Mana Consumption**: Spells consume mana immediately on cast; if insufficient mana, cast fails silently
- **Projectile Targeting**: Projectiles target the current target (`world.currentTargetId`) if available, otherwise use mouse position
- **Projectile Collision**: Uses circular collision detection; projectiles disappear on first hit
- **Skill Equipping**: Players can equip/unequip skills via the skills scene; maximum 4 equipped skills
- **Hotkeys**: Skills are triggered with number keys 1/2/3/4 (mapped to equipped slots)
- **Fireball**: First and only spell initially; uses `resources/skills/fireball.png` for icon
- **Skills Scene**: Accessed via "s" key or clicking book icon in bottom bar
- **Bottom Bar Refactor**: Icon rendering logic extracted to shared helper for reusability

---

## Implementation Order Recommendation

1. ✅ **Foe Attack System** - **COMPLETED** - Combat loop is now complete with enemy attacks, knockback, and visual feedback
2. ✅ **EXP System** - **COMPLETED** - Foundation for progression with leveling, XP awards, and stat bonuses
3. ✅ **Potion System** - **COMPLETED** - Adds survivability with health/mana potions and cooldown mechanics
4. **Magic/Skills System** - Adds ranged combat options and spell variety

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

### Magic/Skills System
- [ ] Skills scene opens with "s" key or book icon click
- [ ] Skills scene closes with "s" or "escape" key
- [ ] Fireball spell can be equipped/unequipped in skills scene
- [ ] Maximum 4 skills can be equipped
- [ ] Equipped skills appear in bottom bar (4 slots)
- [ ] Skills cast with hotkeys 1/2/3/4
- [ ] Casting fireball consumes mana correctly
- [ ] Cannot cast if insufficient mana
- [ ] Fireball projectile spawns from player position
- [ ] Fireball projectile travels toward target/mouse position
- [ ] Fireball projectile renders correctly (orange-red circle)
- [ ] Fireball projectile hits enemies on collision
- [ ] Fireball projectile applies damage correctly
- [ ] Fireball projectile despawns on hit or timeout
- [ ] Damage numbers appear when fireball hits
- [ ] Book icon renders correctly next to bag icon
- [ ] Bottom bar icon rendering helper works for both icons
