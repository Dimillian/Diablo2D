local statKeys = {
    "damageMin",
    "damageMax",
    "defense",
    "health",
    "mana",
    "critChance",
    "moveSpeed",
    "dodgeChance",
    "goldFind",
    "lifeSteal",
    "attackSpeed",
    "resistAll",
}

local Stats = {}

function Stats.newRecord()
    local record = {}
    for _, key in ipairs(statKeys) do
        record[key] = 0
    end
    return record
end

function Stats.clone(base)
    local stats = Stats.newRecord()
    if not base then
        return stats
    end

    for _, key in ipairs(statKeys) do
        stats[key] = base[key] or stats[key]
    end

    return stats
end

function Stats.add(target, source)
    if not source then
        return target
    end

    for _, key in ipairs(statKeys) do
        if source[key] then
            target[key] = (target[key] or 0) + source[key]
        end
    end

    return target
end

Stats.keys = statKeys

return Stats
