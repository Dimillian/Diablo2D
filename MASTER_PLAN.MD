# Master Plan - Upcoming Features

This document outlines concrete implementation details for upcoming features. Each section provides actionable guidance that fits within the existing ECS architecture.

---

## 1. Foe Attack System

### Overview
Add offensive capabilities to foes so they can attack the player when in melee range. Foes should visually strike the player, show damage numbers, apply a brief knockback effect, and have a cooldown between attacks. Player attack range must be longer than foe attack range to maintain gameplay balance.

### Implementation Details

#### Components

**No new components needed** - Existing `combat` component already supports attack mechanics via `queuedAttack`, `cooldown`, `range`, `baseDamageMin`, `baseDamageMax`.

#### Systems

**New System: `systems/foe_attack.lua`**
- Query entities with `foe`, `chase`, `combat`, `position`, `health` components
- **IMPORTANT**: Decrement cooldown each frame (like `player_attack.lua` does): `combat.cooldown = math.max((combat.cooldown or 0) - dt, 0)`
- For each foe that has a `chase` component (already chasing player):
  - Get player entity via `world:getPlayer()`
  - Skip if player is dead or missing health component
  - Calculate distance between foe center and player center using `getEntityCenter()` helper (similar to `combat.lua`)
  - Check if foe is within attack range: `distance <= (foe.combat.range or 80)` (80 = shorter than player's 120 range)
  - Check if cooldown is ready: `foe.combat.cooldown <= 0`
  - If conditions met:
    - Set `foe.combat.queuedAttack = { targetId = player.id, range = foe.combat.range or 80 }`
    - Set cooldown: `foe.combat.cooldown = 1 / (foe.combat.attackSpeed or 0.8)` (slower than player)
    - Set swing timer: `foe.combat.swingTimer = foe.combat.swingDuration or 0.3`
    - Optionally add visual feedback component (see below)

**Modify: `systems/chase.lua`** (Optional Enhancement)
- Current chase system uses `separationBuffer` to stop foes short of target
- Enhancement: When foe is within attack range, reduce movement speed or stop completely
- Alternative: Let `foe_attack` system handle stopping foes when attacking (simpler)
- If enhancing chase: Check `distance <= (entity.combat and entity.combat.range or 80)` and reduce `maxDistance` accordingly

**Modify: `components/combat.lua`**
- Ensure foes created via `Foe.new()` have appropriate `combat` defaults:
  - `range = 80` (shorter than player's 120)
  - `attackSpeed = 0.8` (slower than player's base 1.0)
  - `baseDamageMin = 3`, `baseDamageMax = 6` (adjust per foe type if needed)

**Modify: `entities/foe.lua`**
- Update `Foe.new()` to pass combat defaults:
  ```lua
  combat = createCombat(opts.combat or {
      range = 80,
      attackSpeed = 0.8,
      baseDamageMin = 3,
      baseDamageMax = 6,
  })
  ```

**Existing System: `systems/combat.lua`**
- Already handles `queuedAttack` processing
- Already computes damage via `computeDamage()`
- Already creates damage events and applies to target health
- Already triggers `recentlyDamaged` component
- Already spawns floating damage numbers via events

**New Component: `components/knockback.lua` (Optional Visual Feedback)**
- Optional enhancement for visual impact
- Fields: `x`, `y`, `timer`, `maxTimer`, `strength`
- If added, create in `systems/foe_attack.lua` when foe attacks:
  ```lua
  local knockback = createKnockback({
      x = directionToPlayer.x * 20,
      y = directionToPlayer.y * 20,
      timer = 0.15,
      maxTimer = 0.15,
      strength = 20,
  })
  world:addComponent(player.id, "knockback", knockback)
  ```
- Apply in `systems/movement.lua` by modifying velocity when `knockback` component exists

#### Entity Changes

**Modify: `entities/foe.lua`**
- Ensure all foes have `combat` component with appropriate ranges
- Default foe attack range: 80 pixels (vs player's 120 pixels)

**Modify: `data/foe_types.lua`**
- Current structure: `foeTypes.types` table with `slow`, `medium`, `aggressive` types
- Each type already has: `damageMin`, `damageMax`, `attackSpeed` fields
- Add `range` field to each type configuration:
  ```lua
  slow = {
      -- ... existing fields ...
      range = 90,  -- Slower but longer reach
  },
  medium = {
      -- ... existing fields ...
      range = 80,  -- Standard range
  },
  aggressive = {
      -- ... existing fields ...
      range = 70,  -- Fast but shorter reach
  },
  ```
**Modify: `systems/spawn.lua`**
- Update `spawnGroup()` function to include `range` from foe type config:
  ```lua
  combat = {
      range = config.range or 80,  -- Add this line
      attackSpeed = config.attackSpeed,
      baseDamageMin = config.damageMin,
      baseDamageMax = config.damageMax,
  },
  ```

#### System Registration

**Modify: `scenes/world.lua`**
- Add `foeAttackSystem.update` to update systems (before `combatSystem.update`)
- Order: `detectionSystem.update`, `chaseSystem.update`, `foeAttackSystem.update`, `combatSystem.update`

#### Visual Feedback

**Existing: `systems/render_damage_numbers.lua`**
- Already handles damage number display via combat events
- No changes needed

**Optional: Visual Strike Indicator**
- Add brief color flash to player when damaged (via `recentlyDamaged` component)
- Modify `systems/render.lua` to tint player renderable when `recentlyDamaged` component exists

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
            pickupRadius = 64,
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

## Implementation Order Recommendation

1. **EXP System** - Foundation for progression, independent of other systems
2. **Potion System** - Adds survivability without complex combat interactions
3. **Foe Attack System** - Completes combat loop, requires careful balance testing

---

## Testing Checklist

### Foe Attack System
- [ ] Foes attack player when in range
- [ ] Attack range is shorter than player attack range (80 vs 120)
- [ ] Damage numbers appear correctly
- [ ] Cooldown prevents spam attacks
- [ ] Player can kite foes effectively

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
