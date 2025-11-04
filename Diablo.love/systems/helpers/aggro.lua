local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")
local createChase = require("components.chase")

local Aggro = {}

local function addChaseComponent(world, foe, targetId)
    if foe.chase then
        foe.chase.targetId = targetId
        return
    end

    world:addComponent(foe.id, "chase", createChase({ targetId = targetId }))
end

local function updateDetectionForAggro(foe, target)
    local detection = foe.detection
    if not detection then
        return
    end

    detection.detectedTargetId = target.id
    detection.forceAggro = true

    local baseRange = detection.range or 0
    local extension = detection.leashExtension or 0
    local leashRange = math.max(baseRange, baseRange + extension)

    local foeCenterX, foeCenterY = coordinates.getEntityCenter(foe)
    local targetCenterX, targetCenterY = coordinates.getEntityCenter(target)

    if foeCenterX and targetCenterX then
        local distance = vector.distance(foeCenterX, foeCenterY, targetCenterX, targetCenterY)
        leashRange = math.max(leashRange, distance + extension)
    end

    detection.leashRange = leashRange
end

---Force a foe to aggro onto a specific target (typically the player).
---@param world table
---@param foe table
---@param targetId string
---@param opts table|nil
function Aggro.ensureAggro(world, foe, targetId, opts)
    opts = opts or {}

    if not world or not foe or foe.dead then
        return
    end

    local target = opts.target or world:getEntity(targetId)
    if not target or not target.playerControlled then
        return
    end

    foe.inactive = false
    addChaseComponent(world, foe, target.id)
    updateDetectionForAggro(foe, target)

    if opts.propagatePack == false then
        return
    end

    local foeInfo = foe.foe
    if not foeInfo or not foeInfo.packAggro or not foeInfo.packId then
        return
    end

    local packMembers = world:queryEntities({ "foe" })
    for _, other in ipairs(packMembers) do
        if other.id ~= foe.id and not other.dead then
            local otherInfo = other.foe
            if otherInfo and otherInfo.packId == foeInfo.packId then
                Aggro.ensureAggro(world, other, target.id, {
                    target = target,
                    propagatePack = false,
                })
            end
        end
    end
end

return Aggro
