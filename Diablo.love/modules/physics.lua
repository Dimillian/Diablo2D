local Physics = {}

local hasLovePhysics = love and love.physics

local function getEntityFromFixture(world, fixture)
    if not fixture then
        return nil
    end

    local data = fixture:getUserData()
    if not data then
        return nil
    end

    local entityId = data.entityId or data
    if not entityId then
        return nil
    end

    if not world.entities then
        return nil
    end

    return world.entities[entityId]
end

local function registerContact(entity, otherEntity, otherFixture, normalX, normalY)
    if not entity or not entity.physicsBody then
        return
    end

    local physics = entity.physicsBody
    if physics.bodyType ~= "dynamic" then
        return
    end

    if not otherEntity or not otherEntity.physicsBody then
        return
    end

    if otherEntity.physicsBody.bodyType ~= "static" then
        return
    end

    physics.contactNormals = physics.contactNormals or {}
    physics.contactNormals[otherFixture] = { x = normalX, y = normalY }
end

local function removeContact(entity, otherFixture)
    if not entity or not entity.physicsBody or not entity.physicsBody.contactNormals then
        return
    end

    entity.physicsBody.contactNormals[otherFixture] = nil

    if not next(entity.physicsBody.contactNormals) then
        entity.physicsBody.contactNormals = nil
    end
end

local function beginContact(world, fixtureA, fixtureB, contact)
    local entityA = getEntityFromFixture(world, fixtureA)
    local entityB = getEntityFromFixture(world, fixtureB)
    if not entityA or not entityB then
        return
    end

    local normalX, normalY = contact:getNormal()

    registerContact(entityA, entityB, fixtureB, normalX, normalY)
    registerContact(entityB, entityA, fixtureA, -normalX, -normalY)
end

local function endContact(world, fixtureA, fixtureB)
    local entityA = getEntityFromFixture(world, fixtureA)
    local entityB = getEntityFromFixture(world, fixtureB)
    if not entityA or not entityB then
        return
    end

    removeContact(entityA, fixtureB)
    removeContact(entityB, fixtureA)
end

function Physics.initWorld(world)
    if not hasLovePhysics then
        return
    end

    if world.physicsWorld then
        return
    end

    local physicsWorld = love.physics.newWorld(0, 0, true)
    physicsWorld:setGravity(0, 0)
    physicsWorld:setSleepingAllowed(false)
    physicsWorld:setCallbacks(
        function(fixtureA, fixtureB, contact)
            beginContact(world, fixtureA, fixtureB, contact)
        end,
        function() end,
        function() end,
        function(fixtureA, fixtureB)
            endContact(world, fixtureA, fixtureB)
        end
    )

    world.physicsWorld = physicsWorld
end

local function isBodyValid(physics)
    if not physics then
        return false
    end

    if not physics.body then
        return false
    end

    if physics.body.isDestroyed and physics.body:isDestroyed() then
        return false
    end

    return true
end

local function ensureUserData(entity)
    local physics = entity.physicsBody
    if physics and physics.userData then
        return physics.userData
    end

    return { entityId = entity.id }
end

function Physics.ensureBody(world, entity)
    if not hasLovePhysics then
        return
    end

    if not entity or not entity.physicsBody or not entity.position or not entity.size then
        return
    end

    local physics = entity.physicsBody

    if isBodyValid(physics) then
        return
    end

    if not world.physicsWorld then
        return
    end

    local width = entity.size.w or 0
    local height = entity.size.h or 0

    local centerX = (entity.position.x or 0) + width * 0.5
    local centerY = (entity.position.y or 0) + height * 0.5

    local body = love.physics.newBody(world.physicsWorld, centerX, centerY, physics.bodyType or "dynamic")
    body:setFixedRotation(physics.fixedRotation ~= false)
    body:setGravityScale(0)
    body:setSleepingAllowed(false)

    if physics.bodyType ~= "static" then
        local damping = physics.linearDamping or 18
        body:setLinearDamping(damping)
    end

    local shape = love.physics.newRectangleShape(width, height)
    local fixture = love.physics.newFixture(body, shape, physics.density or 1)
    fixture:setFriction(physics.friction or 0)
    fixture:setRestitution(0)
    fixture:setUserData(ensureUserData(entity))

    physics.body = body
    physics.shape = shape
    physics.fixture = fixture
    physics.contactNormals = nil

    Physics.syncEntityPositionFromBody(entity)
end

function Physics.destroyBody(entity)
    if not hasLovePhysics then
        return
    end

    if not entity or not entity.physicsBody then
        return
    end

    local physics = entity.physicsBody
    if physics.fixture then
        physics.fixture:setUserData(nil)
    end

    if physics.body then
        local canDestroy = true
        if physics.body.isDestroyed and physics.body:isDestroyed() then
            canDestroy = false
        end

        if canDestroy then
            physics.body:destroy()
        end
    end

    physics.body = nil
    physics.shape = nil
    physics.fixture = nil
    physics.contactNormals = nil
end

function Physics.syncEntityPositionFromBody(entity)
    if not hasLovePhysics then
        return
    end

    if not entity or not entity.physicsBody or not entity.physicsBody.body then
        return
    end

    if not entity.position or not entity.size then
        return
    end

    local body = entity.physicsBody.body
    local x, y = body:getPosition()

    entity.position.x = x - (entity.size.w or 0) * 0.5
    entity.position.y = y - (entity.size.h or 0) * 0.5
end

function Physics.updateWorld(world, dt)
    if not hasLovePhysics then
        return
    end

    if not world.physicsWorld then
        return
    end

    world.physicsWorld:update(dt)
end

return Physics
