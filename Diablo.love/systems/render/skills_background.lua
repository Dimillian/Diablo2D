local SkillsLayout = require("systems.helpers.skills_layout")

local renderSkillsBackground = {}

function renderSkillsBackground.draw(scene)
    local panel = SkillsLayout.calculatePanel()

    scene._skillsLayout = scene._skillsLayout or {}
    scene._skillsLayout.panel = panel

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, panel.screenWidth, panel.screenHeight)

    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", panel.panelX, panel.panelY, panel.panelWidth, panel.panelHeight, 8, 8)

    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panel.panelX, panel.panelY, panel.panelWidth, panel.panelHeight, 8, 8)

    local columns = SkillsLayout.calculateColumns(panel)
    scene._skillsLayout.columns = columns

    love.graphics.setLineWidth(2)
    love.graphics.line(columns.dividerX, panel.panelY, columns.dividerX, panel.panelY + panel.panelHeight)

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Equipped", columns.slotsX, columns.headerY)
    love.graphics.print("Spells", columns.listX, columns.headerY)
end

return renderSkillsBackground
