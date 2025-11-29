local ComponentDefaults = {}

-- Inventory defaults
ComponentDefaults.INVENTORY_CAPACITY = 80

-- Potion defaults
ComponentDefaults.HEALTH_POTION_STARTING_COUNT = 3
ComponentDefaults.MAX_HEALTH_POTION_COUNT = 10
ComponentDefaults.MANA_POTION_STARTING_COUNT = 2
ComponentDefaults.MAX_MANA_POTION_COUNT = 10
ComponentDefaults.POTION_COOLDOWN_DURATION = 0.5

-- Visual feedback defaults
ComponentDefaults.DAMAGE_FLASH_DURATION = 0.5

-- Player starting values
ComponentDefaults.PLAYER_STARTING_HEALTH = 50
ComponentDefaults.PLAYER_STARTING_MANA = 25
ComponentDefaults.BASE_MOVEMENT_SPEED = 140
ComponentDefaults.PLAYER_COMBAT_RANGE = 100

-- Combat defaults
ComponentDefaults.COMBAT_SWING_DURATION = 0.35
ComponentDefaults.DEFAULT_COMBAT_RANGE = 120
ComponentDefaults.BASE_ATTACK_SPEED = 1.0
ComponentDefaults.MIN_ATTACK_SPEED = 0.1
ComponentDefaults.MIN_ATTACK_SPEED_MULTIPLIER = 0.1

-- Entity state defaults
ComponentDefaults.INACTIVE_STATE = false

-- Targeting defaults
ComponentDefaults.TARGET_KEEP_ALIVE = 1.5

-- Wander behaviour defaults
ComponentDefaults.WANDER_INTERVAL = 1.5
ComponentDefaults.WANDER_INTERVAL_VARIANCE = 0.3
ComponentDefaults.WANDER_COHESION_RANGE = 120
ComponentDefaults.WANDER_COHESION_STRENGTH = 0.1
ComponentDefaults.WANDER_SEPARATION_RANGE = 70
ComponentDefaults.WANDER_SEPARATION_STRENGTH = 0.5
ComponentDefaults.WANDER_RANDOM_WEIGHT = 1.0
ComponentDefaults.WANDER_COHESION_WEIGHT = 1.0
ComponentDefaults.WANDER_SEPARATION_WEIGHT = 1.5
ComponentDefaults.WANDER_COHESION_STEERING_WEIGHT = 0.5
ComponentDefaults.WANDER_SEPARATION_STEERING_WEIGHT = 1.2

return ComponentDefaults
