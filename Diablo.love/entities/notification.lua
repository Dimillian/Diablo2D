local createNotificationComponent = require("components.notification")

local Notification = {}
Notification.__index = Notification

---Create a notification entity wrapping the notification component data.
---@param opts table|nil
---@return table
function Notification.new(opts)
    opts = opts or {}

    local entity = {
        id = opts.id or ("notification_entity_" .. tostring(os.clock()):gsub("%.", "")),
        notification = createNotificationComponent(opts.notification or {}),
    }

    return setmetatable(entity, Notification)
end

return Notification
