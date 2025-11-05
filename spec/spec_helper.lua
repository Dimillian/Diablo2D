-- Ensure the game's source directory is on the Lua search path for tests.
local repoRoot = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
if repoRoot then
    local projectRoot = repoRoot:match("^(.*)/spec/")
    if projectRoot then
        local sourcePath = projectRoot .. "/Diablo.love/?.lua"
        local initPath = projectRoot .. "/Diablo.love/?/init.lua"
        local specPath = projectRoot .. "/spec/?.lua"
        local specInitPath = projectRoot .. "/spec/?/init.lua"
        package.path = string.format(
            "%s;%s;%s;%s;%s",
            sourcePath,
            initPath,
            specPath,
            specInitPath,
            package.path
        )
    end
end

-- Helper to build basic entities for tests.
local entityCounter = 0

local function buildEntity(opts)
    opts = opts or {}
    entityCounter = entityCounter + 1
    local entity = {
        id = opts.id or ("entity_" .. tostring(entityCounter)),
        position = opts.position or { x = 0, y = 0 },
        size = opts.size or { w = 20, h = 20 },
    }

    for key, value in pairs(opts) do
        if key ~= "id" and key ~= "position" and key ~= "size" then
            entity[key] = value
        end
    end

    return entity
end

return {
    buildEntity = buildEntity,
}
