local ItemGenerator = {}

function ItemGenerator.roll(_opts)
    return {
        id = "test_item",
        name = "Test Blade",
        rarity = "common",
        slot = "weapon",
        stats = {},
        source = "monster",
    }
end

return ItemGenerator
