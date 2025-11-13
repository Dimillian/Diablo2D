-- luacheck: globals describe it before_each assert

local Tooltips = require("systems.helpers.tooltips")

describe("Tooltips.buildItemStatLines - equipped items comparison", function()
    local function buildItem(opts)
        opts = opts or {}
        return {
            name = opts.name or "Test Item",
            slot = opts.slot or "weapon",
            rarity = opts.rarity or "common",
            stats = opts.stats or {},
        }
    end

    local function buildEquippedItem(opts)
        opts = opts or {}
        return {
            name = opts.name or "Equipped Item",
            slot = opts.slot or "weapon",
            stats = opts.stats or {},
        }
    end

    local function findLine(lines, pattern)
        for _, line in ipairs(lines) do
            if not line.isSectionHeader and not line.isSeparator then
                local text = line.text or ""
                if text:match(pattern) then
                    return line
                end
            end
        end
        return nil
    end

    local function collectStatLines(lines)
        local stats = {}
        for _, line in ipairs(lines) do
            if not line.isSectionHeader and not line.isSeparator then
                stats[#stats + 1] = line
            end
        end
        return stats
    end

    describe("when comparing damage stats", function()
        it("shows green for new damage stat when no equipped item has damage", function()
            local item = buildItem({
                stats = { damageMin = 10, damageMax = 15 },
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local damageLine = findLine(lines, "^Damage:")
            assert.is_not_nil(damageLine)
            assert.matches("Damage: 10 %- 15", damageLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, damageLine.color) -- Green
        end)

        it("shows green with (+X) when damage is better than equipped", function()
            local item = buildItem({
                stats = { damageMin = 15, damageMax = 20 }, -- Avg: 17.5
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15 }, -- Avg: 12.5
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local damageLine = findLine(lines, "^Damage:")
            assert.is_not_nil(damageLine)
            assert.matches("Damage: 15 %- 20 %(%+5%)", damageLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, damageLine.color) -- Green
        end)

        it("shows red with (X) when damage is worse than equipped", function()
            local item = buildItem({
                stats = { damageMin = 5, damageMax = 10 }, -- Avg: 7.5
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15 }, -- Avg: 12.5
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local damageLine = findLine(lines, "^Damage:")
            assert.is_not_nil(damageLine)
            assert.matches("Damage: 5 %- 10 %(%-5%)", damageLine.text)
            assert.same({ 0.85, 0.3, 0.3, 1 }, damageLine.color) -- Red
        end)

        it("shows white when damage is same as equipped", function()
            local item = buildItem({
                stats = { damageMin = 10, damageMax = 15 },
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local damageLine = findLine(lines, "^Damage:")
            assert.is_not_nil(damageLine)
            assert.matches("Damage: 10 %- 15", damageLine.text)
            assert.same({ 1, 1, 1, 1 }, damageLine.color) -- White
        end)

        it("compares against best damage when multiple equipped items have damage", function()
            local item = buildItem({
                stats = { damageMin = 12, damageMax = 17 }, -- Avg: 14.5
            })
            local equipped1 = buildEquippedItem({
                stats = { damageMin = 5, damageMax = 10 }, -- Avg: 7.5
            })
            local equipped2 = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15 }, -- Avg: 12.5 (best)
            })
            local equippedItems = { equipped1, equipped2 }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local damageLine = findLine(lines, "^Damage:")
            assert.is_not_nil(damageLine)
            -- Should compare against best (12.5 avg), so diff is +2
            assert.matches("Damage: 12 %- 17 %(%+2%)", damageLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, damageLine.color) -- Green
        end)
    end)

    describe("when comparing defense stats", function()
        it("shows green for new defense stat when no equipped item has defense", function()
            local item = buildItem({
                stats = { defense = 10 },
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local defenseLine = findLine(lines, "^Defense:")
            assert.is_not_nil(defenseLine)
            assert.matches("Defense: 10", defenseLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, defenseLine.color) -- Green
        end)

        it("shows green with (+X) when defense is better than equipped", function()
            local item = buildItem({
                stats = { defense = 15 },
            })
            local equipped = buildEquippedItem({
                stats = { defense = 10 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local defenseLine = findLine(lines, "^Defense:")
            assert.is_not_nil(defenseLine)
            assert.matches("Defense: 15 %(%+5%)", defenseLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, defenseLine.color) -- Green
        end)

        it("shows red with (X) when defense is worse than equipped", function()
            local item = buildItem({
                stats = { defense = 5 },
            })
            local equipped = buildEquippedItem({
                stats = { defense = 10 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local defenseLine = findLine(lines, "^Defense:")
            assert.is_not_nil(defenseLine)
            assert.matches("Defense: 5 %(%-5%)", defenseLine.text)
            assert.same({ 0.85, 0.3, 0.3, 1 }, defenseLine.color) -- Red
        end)

        it("shows white when defense is same as equipped", function()
            local item = buildItem({
                stats = { defense = 10 },
            })
            local equipped = buildEquippedItem({
                stats = { defense = 10 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local defenseLine = findLine(lines, "^Defense:")
            assert.is_not_nil(defenseLine)
            assert.matches("Defense: 10", defenseLine.text)
            assert.same({ 1, 1, 1, 1 }, defenseLine.color) -- White
        end)

        it("compares against best defense when multiple equipped items have defense", function()
            local item = buildItem({
                stats = { defense = 12 },
            })
            local equipped1 = buildEquippedItem({
                stats = { defense = 5 },
            })
            local equipped2 = buildEquippedItem({
                stats = { defense = 10 }, -- Best
            })
            local equippedItems = { equipped1, equipped2 }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local defenseLine = findLine(lines, "^Defense:")
            assert.is_not_nil(defenseLine)
            -- Should compare against best (10), so diff is +2
            assert.matches("Defense: 12 %(%+2%)", defenseLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, defenseLine.color) -- Green
        end)
    end)

    describe("when comparing health stats", function()
        it("shows green for new health stat when no equipped item has health", function()
            local item = buildItem({
                stats = { health = 20 },
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local healthLine = findLine(lines, "Health")
            assert.is_not_nil(healthLine)
            assert.matches("%+20 Health", healthLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, healthLine.color) -- Green
        end)

        it("shows green with (+X) when health is better than equipped", function()
            local item = buildItem({
                stats = { health = 30 },
            })
            local equipped = buildEquippedItem({
                stats = { health = 20 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local healthLine = findLine(lines, "Health")
            assert.is_not_nil(healthLine)
            assert.matches("%+30 %(%+10%) Health", healthLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, healthLine.color) -- Green
        end)

        it("shows red with (X) when health is worse than equipped", function()
            local item = buildItem({
                stats = { health = 10 },
            })
            local equipped = buildEquippedItem({
                stats = { health = 20 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local healthLine = findLine(lines, "Health")
            assert.is_not_nil(healthLine)
            assert.matches("%+10 %(%-10%) Health", healthLine.text)
            assert.same({ 0.85, 0.3, 0.3, 1 }, healthLine.color) -- Red
        end)
    end)

    describe("when comparing percent-based stats", function()
        it("shows green for new crit chance stat", function()
            local item = buildItem({
                stats = { critChance = 0.1 }, -- 10%
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local critLine = findLine(lines, "Crit Chance")
            assert.is_not_nil(critLine)
            assert.matches("%+10%.0%% Crit Chance", critLine.text)
            assert.same({ 0.3, 0.85, 0.4, 1 }, critLine.color) -- Green
        end)

        it("shows green with (+X%) when crit chance is better than equipped", function()
            local item = buildItem({
                stats = { critChance = 0.15 }, -- 15%
            })
            local equipped = buildEquippedItem({
                stats = { critChance = 0.1 }, -- 10%
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local critLine = findLine(lines, "Crit Chance")
            assert.is_not_nil(critLine)
            assert.matches("15%.0%% Crit Chance", critLine.text)
            assert.matches("%+5%.0%%", critLine.text) -- Should have (+5.0%)
            assert.same({ 0.3, 0.85, 0.4, 1 }, critLine.color) -- Green
        end)

        it("shows red with (X%) when crit chance is worse than equipped", function()
            local item = buildItem({
                stats = { critChance = 0.05 }, -- 5%
            })
            local equipped = buildEquippedItem({
                stats = { critChance = 0.1 }, -- 10%
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            local critLine = findLine(lines, "Crit Chance")
            assert.is_not_nil(critLine)
            assert.matches("5%.0%% Crit Chance", critLine.text)
            assert.matches("%-5%.0%%", critLine.text) -- Should have (-5.0%)
            assert.same({ 0.85, 0.3, 0.3, 1 }, critLine.color) -- Red
        end)
    end)

    describe("when showing losses (stats equipped has but item doesn't)", function()
        it("shows damage loss in red when item has no damage but equipped does", function()
            local item = buildItem({
                stats = { defense = 10 }, -- No damage
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15, defense = 5 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            -- Should have defense gain and damage loss
            local hasDefenseGain = false
            local hasDamageLoss = false
            for _, line in ipairs(lines) do
                local lineText = line.text or ""
                if lineText:match("Defense:") then
                    hasDefenseGain = true
                end
                if lineText:match("Damage: 10 %- 15") and line.color and line.color[1] == 0.85 then
                    hasDamageLoss = true
                end
            end

            assert.is_true(hasDefenseGain)
            assert.is_true(hasDamageLoss)
        end)

        it("shows defense loss in red when item has no defense but equipped does", function()
            local item = buildItem({
                stats = { damageMin = 10, damageMax = 15 }, -- No defense
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 5, damageMax = 10, defense = 10 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            -- Should have damage gain and defense loss
            local hasDamageGain = false
            local hasDefenseLoss = false
            for _, line in ipairs(lines) do
                local lineText = line.text or ""
                if lineText:match("Damage:") and line.color and line.color[1] == 0.3 then
                    hasDamageGain = true
                end
                if lineText:match("Defense: 10") and line.color and line.color[1] == 0.85 then
                    hasDefenseLoss = true
                end
            end

            assert.is_true(hasDamageGain)
            assert.is_true(hasDefenseLoss)
        end)

        it("shows separator between gains and losses", function()
            local item = buildItem({
                stats = { defense = 10 }, -- No damage
            })
            local equipped = buildEquippedItem({
                stats = { damageMin = 10, damageMax = 15, defense = 5 },
            })
            local equippedItems = { equipped }

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            -- Should have separator
            local hasSeparator = false
            for _, line in ipairs(lines) do
                if line.isSeparator then
                    hasSeparator = true
                    break
                end
            end

            assert.is_true(hasSeparator)
        end)
    end)

    describe("when hovering equipped item", function()
        it("shows all stats in white without comparisons", function()
            local item = buildItem({
                stats = {
                    damageMin = 10,
                    damageMax = 15,
                    defense = 20,
                    health = 30,
                    critChance = 0.1,
                },
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, true)

            -- All lines should be white
            local statLines = collectStatLines(lines)
            for _, line in ipairs(statLines) do
                assert.same({ 1, 1, 1, 1 }, line.color) -- White
            end

            -- Should have all stats
            assert.matches("Damage: 10 %- 15", statLines[1].text)
            assert.matches("Defense: 20", statLines[2].text)
            assert.matches("%+30 Health", statLines[3].text)
            assert.matches("%+10%.0%% Crit Chance", statLines[4].text)
        end)
    end)

    describe("edge cases", function()
        it("handles nil item gracefully", function()
            local lines = Tooltips.buildItemStatLines(nil, {}, false)

            assert.equal(1, #lines)
            assert.equal("Unknown item", lines[1].text)
            assert.same({ 1, 1, 1, 1 }, lines[1].color)
        end)

        it("handles item with no stats", function()
            local item = buildItem({
                stats = {},
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            assert.equal(2, #lines)
            assert.is_true(lines[1].isSectionHeader)
            assert.equal("Base Power", lines[1].text)
            assert.equal("No bonuses", lines[2].text)
        end)

        it("handles empty equipped items array", function()
            local item = buildItem({
                stats = { defense = 10 },
            })
            local equippedItems = {}

            local lines = Tooltips.buildItemStatLines(item, equippedItems, false)

            -- Should show as new stat (green)
            assert.is_true(lines[1].isSectionHeader)
            assert.same({ 0.3, 0.85, 0.4, 1 }, lines[2].color) -- Green
        end)
    end)
end)
