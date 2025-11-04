local SkillsLayout = require("systems.helpers.skills_layout")

local renderSkillsHelp = {}

function renderSkillsHelp.draw(scene)
    local layout = scene._skillsLayout or {}
    local panel = layout.panel or SkillsLayout.calculatePanel()
    local helpPos = SkillsLayout.calculateHelpPosition(panel)

    love.graphics.setColor(0.85, 0.8, 0.6, 1)
    love.graphics.print("Click a spell to equip. Click an equipped slot to unequip. Press S to close.", helpPos.x, helpPos.y)
end

return renderSkillsHelp
