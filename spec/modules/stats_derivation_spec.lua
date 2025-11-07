-- luacheck: globals describe it before_each assert

local StatsDerivation = require("modules.stats_derivation")

describe("StatsDerivation", function()
    it("derives damage from strength", function()
        local attributes = {
            strength = 10,
            dexterity = 0,
            vitality = 0,
            intelligence = 0,
        }

        local derived = StatsDerivation.deriveStatsFromAttributes(attributes)

        -- 10 strength = 10 * 0.2 = 2 damage
        assert.equal(2, derived.damageMin)
        assert.equal(2, derived.damageMax)
    end)

    it("derives crit chance from dexterity", function()
        local attributes = {
            strength = 0,
            dexterity = 25,
            vitality = 0,
            intelligence = 0,
        }

        local derived = StatsDerivation.deriveStatsFromAttributes(attributes)

        -- 25 dexterity = 25 * 0.0002 = 0.005 (0.5%)
        assert.equal(0.005, derived.critChance)
    end)

    it("derives health from vitality", function()
        local attributes = {
            strength = 0,
            dexterity = 0,
            vitality = 50,
            intelligence = 0,
        }

        local derived = StatsDerivation.deriveStatsFromAttributes(attributes)

        -- 50 vitality = 50 health
        assert.equal(50, derived.health)
    end)

    it("derives mana from intelligence", function()
        local attributes = {
            strength = 0,
            dexterity = 0,
            vitality = 0,
            intelligence = 25,
        }

        local derived = StatsDerivation.deriveStatsFromAttributes(attributes)

        -- 25 intelligence = 25 mana
        assert.equal(25, derived.mana)
    end)

    it("handles nil attributes gracefully", function()
        local derived = StatsDerivation.deriveStatsFromAttributes(nil)

        assert.equal(0, derived.damageMin)
        assert.equal(0, derived.damageMax)
        assert.equal(0, derived.critChance)
        assert.equal(0, derived.health)
        assert.equal(0, derived.mana)
    end)

    it("handles missing attributes gracefully", function()
        local derived = StatsDerivation.deriveStatsFromAttributes({})

        assert.equal(0, derived.damageMin)
        assert.equal(0, derived.damageMax)
        assert.equal(0, derived.critChance)
        assert.equal(0, derived.health)
        assert.equal(0, derived.mana)
    end)

    it("derives all stats correctly from full attributes", function()
        local attributes = {
            strength = 25,
            dexterity = 50,
            vitality = 100,
            intelligence = 75,
        }

        local derived = StatsDerivation.deriveStatsFromAttributes(attributes)

        -- 25 strength = 5 damage
        assert.equal(5, derived.damageMin)
        assert.equal(5, derived.damageMax)
        -- 50 dexterity = 0.01 (1%)
        assert.equal(0.01, derived.critChance)
        -- 100 vitality = 100 health
        assert.equal(100, derived.health)
        -- 75 intelligence = 75 mana
        assert.equal(75, derived.mana)
    end)
end)
