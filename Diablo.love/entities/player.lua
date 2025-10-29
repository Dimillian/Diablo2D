local Player = {}
Player.__index = Player

---Create a player entity with position and size defaults.
---@param opts table|nil
---@return Player
function Player.new(opts)
    opts = opts or {}

    local entity = {
        id = opts.id or "player",
        position = {
            x = opts.x or 0,
            y = opts.y or 0,
        },
        size = {
            w = opts.width or 16,
            h = opts.height or 24,
        },
        inventory = opts.inventory or { items = {} },
        equipment = opts.equipment or {},
    }

    return setmetatable(entity, Player)
end

---Set the absolute position of the player.
---@param x number
---@param y number
function Player:setPosition(x, y)
    self.position.x = x
    self.position.y = y
end

---Move the player relative to the current position.
---@param dx number
---@param dy number
function Player:move(dx, dy)
    self.position.x = self.position.x + dx
    self.position.y = self.position.y + dy
end

return Player
