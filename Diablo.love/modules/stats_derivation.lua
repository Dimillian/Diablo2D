---Stats derivation module: converts primary attributes to derived stats
local StatsDerivation = {}

---Derive stats from primary attributes
---@param attributes table Table with strength, dexterity, vitality, intelligence
---@return table derivedStats Derived stats table compatible with stats structure
function StatsDerivation.deriveStatsFromAttributes(attributes)
    attributes = attributes or {}

    local strength = attributes.strength or 0
    local dexterity = attributes.dexterity or 0
    local vitality = attributes.vitality or 0
    local intelligence = attributes.intelligence or 0

    -- Conversion formulas:
    -- Strength: 5 str = +1 min/max damage (1 str = 0.2 damage)
    -- Dexterity: 5 dex = +0.1% crit chance (1 dex = 0.02% = 0.0002 decimal)
    -- Vitality: 5 vit = +5 health (1 vit = 1 health)
    -- Intelligence: 5 int = +5 mana (1 int = 1 mana)

    local derivedStats = {
        damageMin = strength * 0.2,
        damageMax = strength * 0.2,
        critChance = dexterity * 0.0002,
        health = vitality,
        mana = intelligence,
    }

    return derivedStats
end

return StatsDerivation
