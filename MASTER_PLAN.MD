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

## 2. Potion System

### Overview
Implement a health potion system where players start with 3 potions, can consume them to restore 25 HP, and see visual representation near the health bar. Monsters can drop potions as loot (in addition to regular items).

### Implementation Details

#### Components

**New Component: `components/potions.lua`**
```lua
local function createPotionsComponent(opts)
    opts = opts or {}
    return {
        healthPotionCount = opts.healthPotionCount or 3,
        maxHealthPotionCount = opts.maxHealthPotionCount or 10, -- max carry limit
        lastUseTime = opts.lastUseTime or nil,  -- Track last use time for cooldown
        cooldownRemaining = opts.cooldownRemaining or 0,  -- Current cooldown timer
    }
end
```

**Modify: `components/inventory.lua`**
- Inventory can hold potions as items, but `potions` component tracks consumable potions separately (quicker access, doesn't clutter inventory)

**Modify: `data/items.lua`**
- Add potion item type to `Items.types` table:
```lua
health_potion = {
    id = "health_potion",
    label = "Health Potion",
    slot = "consumable",  -- Special slot that doesn't use equipment slots
    consumable = true,
    restoreHealth = 25,
    base = {
        damage = { min = 0, max = 0 },
        defense = 0,
    },
},
```
- Note: Potions won't use item generator prefixes/suffixes (they're consumables, not equipment)

#### Systems

**New System: `systems/potion_consumption.lua`**
- **IMPORTANT**: Use `love.keypressed()` callback, NOT `love.keyboard.isDown()` (potions should trigger on single press, not continuous)
- Decrement cooldown each frame in `update()`:
  ```lua
  function potionConsumptionSystem.update(world, dt)
      local player = world:getPlayer()
      if player and player.potions and player.potions.lastUseTime then
          player.potions.cooldownRemaining = math.max(0, (player.potions.cooldownRemaining or 0) - dt)
      end
  end
  ```
- Handle keypress in `WorldScene:keypressed()` method (add to `scenes/world.lua`):
  ```lua
  function WorldScene:keypressed(key)
      if key == "t" then
          self.debugMode = not self.debugMode
          return
      end

      -- Potion consumption (key "1" or "q")
      if key == "1" or key == "q" then
          potionConsumptionSystem.handleKeypress(self, key)
      end
  end
  ```
- In `handleKeypress()` function:
  - Get player entity: `world:getPlayer()`
  - Verify player has potions: `player.potions.healthPotionCount > 0`
  - Verify player needs healing: `player.health.current < player.health.max`
  - Check cooldown: `player.potions.cooldownRemaining <= 0`
  - When conditions met:
    - Restore health: `player.health.current = math.min(player.health.max, player.health.current + 25)`
    - Decrement count: `player.potions.healthPotionCount = player.potions.healthPotionCount - 1`
    - Set cooldown: `player.potions.cooldownRemaining = 0.5` (0.5 seconds)
    - Optional: Create visual feedback (particle effect, sound, etc.)

**Modify: `systems/loot_pickup.lua`**
- In `transferItemToPlayer()` function, before adding to inventory/equipment:
  - Check if item type is `health_potion`
  - If yes, add to potion count and skip inventory transfer:
    ```lua
    if item.type == "health_potion" then
        if player.potions then
            player.potions.healthPotionCount = math.min(
                player.potions.maxHealthPotionCount,
                player.potions.healthPotionCount + 1
            )
        end
        lootable.item = nil
        world:removeEntity(lootEntity.id)
        return  -- Skip inventory/equipment transfer
    end
    ```

**Modify: `systems/loot_drops.lua`**
- Add potion drop chance to death events
- In `spawnLoot()` function, after regular item roll:
  - Roll chance: `math.random() < 0.15` (15% chance to drop potion)
  - If successful, create potion item:
    ```lua
    local potionItem = {
        type = "health_potion",
        rarity = "common",
        source = "monster",
        -- ... other item metadata
    }
    local potionLoot = LootEntity.new({
        x = event.position.x - 13,
        y = event.position.y - 13,
        width = 26,
        height = 26,
        renderable = {
            kind = "loot",
            color = { 0.8, 0.2, 0.2, 1 }, -- Red color for potion
        },
        lootable = {
            item = potionItem,
            pickupRadius = 128,
            source = event.targetId,
            despawnTimer = 45,
            maxDespawnTimer = 45,
        },
    })
    world:addEntity(potionLoot)
    ```

**New System: `systems/ui_potions.lua`**
- Draw potion UI near health bar (bottom left)
- Position: Right of health bar or above it
- Visual representation:
  - Icon/bottle shape: Small filled rectangle or circle
  - Count text: `player.potions.healthPotionCount`
  - Color: Red tint `{0.8, 0.2, 0.2, 1}` for health potions
- Layout example:
  ```lua
  local potionX = barX + barWidth + 16
  local potionY = barY
  local potionSize = 24
  -- Draw potion icon/bottle
  love.graphics.setColor(0.8, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", potionX, potionY, potionSize, potionSize, 2, 2)
  -- Draw count
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(player.potions.healthPotionCount, potionX + potionSize/2, potionY + potionSize/2)
  ```

#### Entity Changes

**Modify: `entities/player.lua`**
- Add `potions` component to player creation:
  ```lua
  local createPotions = require("components.potions")
  -- ...
  potions = createPotions(opts.potions or {
      healthPotionCount = 3,
  }),
  ```

#### System Registration

**Modify: `scenes/world.lua`**
- Add `potionConsumptionSystem.update` to update systems (after `playerInputSystem.update`) - handles cooldown decrement
- Add `potionConsumptionSystem.handleKeypress` call in `WorldScene:keypressed()` method (see system details above)
- Add `uiPotionsSystem.draw` to draw systems (after `uiPlayerStatus.draw`)

#### Item Generator

**Modify: `items/generator.lua`**
- Add potion type to item generation (if using generator for potions)
- Or handle potions separately in loot drops (recommended)

---

## 3. EXP System

### Overview
Implement an experience point (XP) system where players start at level 1 with 0 XP, gain XP from killing foes, and have a leveling table that scales XP requirements. Display an XP bar at the bottom of the screen showing current XP vs required XP for next level, filling the entire screen width for a gamey feel.

### Implementation Details

#### Components

**New Component: `components/experience.lua`**
```lua
local function createExperienceComponent(opts)
    opts = opts or {}
    return {
        level = opts.level or 1,
        currentXP = opts.currentXP or 0,
        xpForNextLevel = opts.xpForNextLevel or 100, -- Will be computed from leveling table
    }
end
```

#### Data

**New Data File: `data/leveling.lua`**
```lua
local Leveling = {}

-- XP required to reach level N (cumulative from level 1)
-- Formula: XP(n) = baseXP * (multiplier ^ (n - 1))
-- Example: baseXP = 100, multiplier = 1.5
Leveling.getXPForLevel = function(targetLevel)
    local baseXP = 100
    local multiplier = 1.5
    if targetLevel <= 1 then
        return 0
    end
    local totalXP = 0
    for i = 2, targetLevel do
        totalXP = totalXP + math.floor(baseXP * (multiplier ^ (i - 2)))
    end
    return totalXP
end

-- XP required to go from level N to level N+1
Leveling.getXPRequiredForNextLevel = function(currentLevel)
    local baseXP = 100
    local multiplier = 1.5
    if currentLevel < 1 then
        return baseXP
    end
    return math.floor(baseXP * (multiplier ^ (currentLevel - 1)))
end

-- XP gained from killing a foe (scales with level or fixed)
Leveling.getFoeXP = function(foeLevel, playerLevel)
    -- Base XP per kill
    local baseXP = 25
    -- Optional: Scale based on level difference
    -- For now, fixed XP per kill
    return baseXP
end

return Leveling
```

#### Systems

**New System: `systems/experience.lua`**
- Listen to combat events: `world.pendingCombatEvents`
- For each `death` event where `sourceId` is player:
  - Get player entity: `world:getPlayer()`
  - Get slain foe: `world:getEntity(event.targetId)`
  - Calculate XP gain: `Leveling.getFoeXP(foeLevel or 1, player.experience.level)`
  - Add XP: `player.experience.currentXP = player.experience.currentXP + xpGain`
  - Check for level up (see below)

**Level Up Logic (in `systems/experience.lua`):**
```lua
local function checkLevelUp(world, player)
    local exp = player.experience
    local totalXPForCurrentLevel = Leveling.getXPForLevel(exp.level)
    local totalXPForNextLevel = Leveling.getXPForLevel(exp.level + 1)

    -- Check if player has enough XP for next level
    if exp.currentXP >= totalXPForNextLevel then
        -- Level up!
        exp.level = exp.level + 1

        -- Optional: Grant stat bonuses on level up
        -- Example: +5 max health per level
        if player.health then
            player.health.max = player.health.max + 5
            player.health.current = player.health.max -- Full heal on level up
        end

        -- Recalculate for potential multiple level ups
        local newTotalXPForNextLevel = Leveling.getXPForLevel(exp.level + 1)
        if exp.currentXP >= newTotalXPForNextLevel then
            -- Recursively check for additional level ups
            checkLevelUp(world, player)
            return
        end

        -- Optional: Create level up event/notification
        -- Could add to pendingCombatEvents or separate event queue
    end

    -- Update XP required for next level display (always update for UI)
    local xpRequired = Leveling.getXPRequiredForNextLevel(exp.level)
    exp.xpForNextLevel = xpRequired
end
```

**New System: `systems/ui_experience.lua`**
- Draw full-width XP bar at bottom of screen
- Position: `barY = screenHeight - barHeight - 8` (8px from bottom)
- Width: `barWidth = screenWidth - 32` (16px margin on each side)
- Height: `barHeight = 20` (thick enough to be visible)
- Visual design:
  - Background: Dark color `{0.1, 0.1, 0.1, 0.9}`
  - Fill: Bright color `{0.2, 0.6, 1.0, 1}` (blue) or `{0.4, 0.8, 0.4, 1}` (green)
  - Outline: Light color `{0.9, 0.85, 0.65, 1}`
  - Text overlay: Current XP / Required XP, Level number
- Implementation:
  ```lua
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local barHeight = 20
  local barY = screenHeight - barHeight - 8
  local barWidth = screenWidth - 32
  local barX = 16

  local player = world:getPlayer()
  if not player or not player.experience then
      return
  end

  local exp = player.experience
  local totalXPForCurrentLevel = Leveling.getXPForLevel(exp.level)
  local totalXPForNextLevel = Leveling.getXPForLevel(exp.level + 1)
  local xpProgress = exp.currentXP - totalXPForCurrentLevel
  local xpRequired = totalXPForNextLevel - totalXPForCurrentLevel
  local ratio = xpRequired > 0 and (xpProgress / xpRequired) or 1

  -- Draw background
  love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
  love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4, 4)

  -- Draw fill
  love.graphics.setColor(0.2, 0.6, 1.0, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight, 4, 4)

  -- Draw outline
  love.graphics.setColor(0.9, 0.85, 0.65, 1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 4, 4)

  -- Draw text
  love.graphics.setColor(1, 1, 1, 1)
  local text = string.format("Level %d | %d / %d XP", exp.level, math.floor(xpProgress), math.floor(xpRequired))
  love.graphics.printf(text, barX, barY + barHeight/2 - 6, barWidth, "center")
  ```

#### Entity Changes

**Modify: `entities/player.lua`**
- Add `experience` component to player creation:
  ```lua
  local createExperience = require("components.experience")
  -- ...
  experience = createExperience(opts.experience or {
      level = 1,
      currentXP = 0,
  }),
  ```
- Initialize XP for next level based on leveling table

#### System Registration

**Modify: `scenes/world.lua`**
- Add `experienceSystem.update` to update systems (after `combatSystem.update` and `lootDropSystem.update`)
- Add `uiExperienceSystem.draw` to draw systems (after `uiPlayerStatus.draw`, before `uiTargetSystem.draw` or at end)

#### Level Up Rewards

**Optional Enhancement:**
- On level up, grant stat bonuses:
  - +5 max health (already implemented in level up logic above)
  - +1 damage min/max (add to `baseStats` component)
  - +1 defense (add to `baseStats` component)
- **Integration with `systems/apply_stats.lua`**:
  - Current system reads `player.baseStats` and combines with equipment stats
  - Level bonuses should be stored in `baseStats` component, so they automatically combine with equipment
  - Modify level up logic to update `player.baseStats`:
    ```lua
    if player.baseStats then
        player.baseStats.damageMin = (player.baseStats.damageMin or 5) + 1
        player.baseStats.damageMax = (player.baseStats.damageMax or 8) + 1
        player.baseStats.defense = (player.baseStats.defense or 2) + 1
    end
    ```
  - `apply_stats` system will automatically recalculate total stats on next frame

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
2. **EXP System** - Foundation for progression, independent of other systems
3. **Potion System** - Adds survivability without complex combat interactions
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
- [ ] Player starts with 3 potions
- [ ] Potions restore 25 HP correctly
- [ ] Potion count decreases on use
- [ ] Potions appear in UI near health bar
- [ ] Monsters can drop potions as loot
- [ ] Potion pickup adds to potion count

### EXP System
- [ ] Player starts at level 1 with 0 XP
- [ ] Killing foes grants XP
- [ ] XP bar displays correctly (full width)
- [ ] Level up occurs at correct XP thresholds
- [ ] XP requirements scale properly
- [ ] Level number displays correctly

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
