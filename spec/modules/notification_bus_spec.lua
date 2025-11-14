require("spec.spec_helper")

local notificationBus = require("modules.notification_bus")
local ECS = require("modules.ecs")

describe("notification_bus", function()
    local world

    before_each(function()
        world = {}
        ECS.init(world)
    end)

    it("queues payloads and promotes them to active notifications", function()
        notificationBus.queue(world, { title = "Level Up!", bodyLines = { "+5 Health" } })

        notificationBus.update(world, 0)
        local active = notificationBus.getActive(world)

        assert.are.equal(1, #active)
        assert.are.equal("Level Up!", active[1].notification.title)
        assert.are.same({ "+5 Health" }, active[1].notification.bodyLines)
        assert.are.equal("enter", active[1].notification.state)
    end)

    it("preserves click actions when promoting notifications", function()
        notificationBus.queue(world, {
            title = "Assign your points",
            onClickAction = "open_inventory",
        })

        notificationBus.update(world, 0)

        local active = notificationBus.getActive(world)
        assert.are.equal(1, #active)
        assert.are.equal("open_inventory", active[1].notification.onClickAction)
    end)

    it("respects the maximum active stack and keeps overflow pending", function()
        for index = 1, 5 do
            notificationBus.queue(world, { title = "Alert " .. index })
        end

        notificationBus.update(world, 0)

        local state = notificationBus.getState(world)
        assert.are.equal(4, #state.active)
        assert.are.equal(1, #state.pending)
    end)

    it("refreshes an existing category instead of duplicating it", function()
        notificationBus.queue(world, { category = "level_up", title = "Level 2" })
        notificationBus.update(world, 0)

        notificationBus.queue(world, { category = "level_up", title = "Level 3" })
        notificationBus.update(world, 0)

        local active = notificationBus.getActive(world)
        assert.are.equal(1, #active)
        assert.are.equal("Level 3", active[1].notification.title)
        assert.are.equal("enter", active[1].notification.state)
        assert.are.equal(0, active[1].notification.timeElapsed)
    end)

    it("dismisses notifications and removes them after the exit animation", function()
        notificationBus.queue(world, { title = "Dismiss me", ttl = 5 })
        notificationBus.update(world, 0)
        notificationBus.update(world, 0.25)

        local active = notificationBus.getActive(world)
        assert.are.equal(1, #active)

        local notificationId = active[1].notification.id
        notificationBus.dismiss(world, notificationId)

        notificationBus.update(world, 0)
        active = notificationBus.getActive(world)
        assert.are.equal("exit", active[1].notification.state)

        notificationBus.update(world, 0.3)
        assert.are.equal(0, #notificationBus.getActive(world))
    end)

    it("auto-dismisses notifications after their ttl elapses", function()
        notificationBus.queue(world, { title = "Short lived", ttl = 0.1 })
        notificationBus.update(world, 0)
        notificationBus.update(world, 0.2)

        notificationBus.update(world, 0)
        local active = notificationBus.getActive(world)
        assert.are.equal("exit", active[1].notification.state)

        notificationBus.update(world, 0.3)
        assert.are.equal(0, #notificationBus.getActive(world))
    end)
end)
