local function createChunkResidentComponent(opts)
    opts = opts or {}

    return {
        chunkKey = opts.chunkKey,
        descriptorId = opts.descriptorId,
        kind = opts.kind,
    }
end

return createChunkResidentComponent
