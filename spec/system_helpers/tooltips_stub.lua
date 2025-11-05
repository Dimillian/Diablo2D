local Tooltips = {}

Tooltips.rarityColors = {
    common = { 1, 1, 1, 1 },
}

function Tooltips.getRarityColor(_rarity)
    return Tooltips.rarityColors.common
end

return Tooltips
