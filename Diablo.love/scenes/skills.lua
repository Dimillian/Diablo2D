local Spells = require("data.spells")

local renderSkillsBackground = require("systems.render.skills_background")
local renderSkillsList = require("systems.render.skills_list")
local renderSkillsEquipped = require("systems.render.skills_equipped")
local renderSkillsTooltip = require("systems.render.skills_tooltip")

local SkillsScene = {}
SkillsScene.__index = SkillsScene

local function equipSpell(player, spellId)
    if not spellId then
        return
    end

    local slots = player.skills.equipped
    for index = 1, 4 do
        if slots[index] == spellId then
            return
        end
    end

    for index = 1, 4 do
        if not slots[index] then
            slots[index] = spellId
            return
        end
    end

    slots[1] = spellId
end

local function unequipSlot(player, slotIndex)
    player.skills.equipped[slotIndex] = nil
end

function SkillsScene.new(opts)
    opts = opts or {}
    local world = assert(opts.world, "SkillsScene requires world reference")

    local scene = {
        world = world,
        kind = "skills",
        title = "Skills",
        availableSpells = Spells.getAll(),
        systems = {
            draw = {
                renderSkillsBackground.draw,
                renderSkillsList.draw,
                renderSkillsEquipped.draw,
                renderSkillsTooltip.draw,
            },
        },
    }

    return setmetatable(scene, SkillsScene)
end

function SkillsScene:enter()
    self.spellRects = {}
    self.slotRects = {}
    self.hoveredSpellId = nil
    self.hoveredSlotIndex = nil
    self._skillsLayout = {}
end

-- luacheck: ignore 212/self
function SkillsScene:exit()
end

-- luacheck: ignore 212/self
function SkillsScene:update(_dt)
end

function SkillsScene:draw()
    love.graphics.push("all")

    self.hoveredSpellId = nil
    self.hoveredSlotIndex = nil

    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

function SkillsScene:keypressed(key)
    if key ~= "s" and key ~= "escape" then
        return
    end

    if self.world and self.world.sceneManager then
        self.world.sceneManager:toggleSkills(key)
    end
end

function SkillsScene:mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local player = self.world and self.world:getPlayer()
    if not player or not player.skills then
        return
    end

    for _, rect in ipairs(self.spellRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            equipSpell(player, rect.spell and rect.spell.id)
            return
        end
    end

    for _, rect in ipairs(self.slotRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            unequipSlot(player, rect.index)
            return
        end
    end
end

return SkillsScene
