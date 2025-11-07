local function createPhysicsBodyComponent(opts)
    opts = opts or {}

    return {
        bodyType = opts.bodyType or "dynamic",
        linearDamping = opts.linearDamping or 18,
        fixedRotation = opts.fixedRotation ~= false,
        friction = opts.friction or 0,
        density = opts.density or 1,
        userData = opts.userData,
        body = nil,
        shape = nil,
        fixture = nil,
        contactNormals = nil,
    }
end

return createPhysicsBodyComponent
