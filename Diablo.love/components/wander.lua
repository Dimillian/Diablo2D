local ComponentDefaults = require("data.component_defaults")

local function createWanderComponent(opts)
    opts = opts or {}

    return {
        interval = opts.interval or ComponentDefaults.WANDER_INTERVAL,
        variance = opts.variance or ComponentDefaults.WANDER_INTERVAL_VARIANCE,
        elapsed = 0,
        removeOnDeath = true,
        cohesionRange = opts.cohesionRange or ComponentDefaults.WANDER_COHESION_RANGE,
        cohesionStrength = opts.cohesionStrength or ComponentDefaults.WANDER_COHESION_STRENGTH,
        separationRange = opts.separationRange or ComponentDefaults.WANDER_SEPARATION_RANGE,
        separationStrength = opts.separationStrength or ComponentDefaults.WANDER_SEPARATION_STRENGTH,
        randomWeight = opts.randomWeight or ComponentDefaults.WANDER_RANDOM_WEIGHT,
        cohesionImpulseWeight = opts.cohesionImpulseWeight or ComponentDefaults.WANDER_COHESION_WEIGHT,
        separationImpulseWeight = opts.separationImpulseWeight or ComponentDefaults.WANDER_SEPARATION_WEIGHT,
        cohesionSteeringWeight = opts.cohesionSteeringWeight or ComponentDefaults.WANDER_COHESION_STEERING_WEIGHT,
        separationSteeringWeight = opts.separationSteeringWeight or ComponentDefaults.WANDER_SEPARATION_STEERING_WEIGHT,
    }
end

return createWanderComponent
