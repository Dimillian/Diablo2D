local createPosition = require("components.position")
local createSize = require("components.size")
local createRenderable = require("components.renderable")
local createStructure = require("components.structure")

local StructureFactory = {}
StructureFactory.__index = StructureFactory

local STRUCTURE_TEMPLATES = {
    tree_cluster = {
        size = { w = 48, h = 64 },
        renderable = { kind = "structure", shape = "tree_cluster", color = { 0.1, 0.4, 0.18, 1 } },
    },
    forest_hut = {
        size = { w = 70, h = 50 },
        renderable = { kind = "structure", shape = "forest_hut", color = { 0.45, 0.27, 0.11, 1 } },
    },
    desert_rock = {
        size = { w = 60, h = 40 },
        renderable = { kind = "structure", shape = "desert_rock", color = { 0.65, 0.54, 0.3, 1 } },
    },
    ruined_obelisk = {
        size = { w = 40, h = 90 },
        renderable = { kind = "structure", shape = "ruined_obelisk", color = { 0.55, 0.5, 0.42, 1 } },
    },
    ice_spike = {
        size = { w = 36, h = 80 },
        renderable = { kind = "structure", shape = "ice_spike", color = { 0.72, 0.85, 0.95, 1 } },
    },
    frozen_ruin = {
        size = { w = 80, h = 60 },
        renderable = { kind = "structure", shape = "frozen_ruin", color = { 0.68, 0.77, 0.88, 1 } },
    },
}

local function resolveTemplate(structureId)
    return STRUCTURE_TEMPLATES[structureId] or STRUCTURE_TEMPLATES.tree_cluster
end

function StructureFactory.build(opts)
    opts = opts or {}
    local template = resolveTemplate(opts.structureId)

    local entity = {
        id = opts.id or (opts.structureId .. "_" .. tostring(math.floor(math.random() * 100000))),
        position = createPosition({ x = opts.x or 0, y = opts.y or 0 }),
        size = createSize({ w = template.size.w, h = template.size.h }),
        renderable = createRenderable({ kind = template.renderable.kind, color = template.renderable.color }),
        structure = createStructure({ id = opts.id, structureId = opts.structureId, lootable = template.lootable }),
    }

    entity.renderable.shape = template.renderable.shape
    entity.renderable.rotation = opts.rotation or 0

    return entity
end

return StructureFactory
