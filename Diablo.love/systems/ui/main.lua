local uiPlayerStatus = require("systems.ui.player_status")
local uiExperienceBar = require("systems.ui.experience_bar")
local uiBottomBar = require("systems.ui.bottom_bar")
local uiSkillsBar = require("systems.ui.skills_bar")

local uiMain = {}

---Draw all UI systems in order
---@param world WorldScene The world scene
function uiMain.draw(world)
    uiPlayerStatus.draw(world)
    uiExperienceBar.draw(world)
    uiBottomBar.draw(world)
    uiSkillsBar.draw(world)
end

return uiMain
