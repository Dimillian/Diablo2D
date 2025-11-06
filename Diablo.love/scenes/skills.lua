local Spells = require("data.spells")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")

local renderWindowChrome = require("systems.render.window.chrome")
local renderSkillsList = require("systems.render.skills.list")
local renderSkillsEquipped = require("systems.render.skills.equipped")
local renderSkillsTooltip = require("systems.render.skills.tooltip")

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
        windowLayoutOptions = {
            widthRatio = 0.62,
            heightRatio = 0.6,
            headerHeight = 72,
            padding = 28,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderSkillsList.draw,
                renderSkillsEquipped.draw,
                renderSkillsTooltip.draw,
            },
        },
    }

    scene.windowChromeConfig = {
        title = scene.title,
        icon = "book_open",
        columns = {
            leftRatio = 0.35,
            spacing = 28,
        },
    }

    return setmetatable(scene, SkillsScene)
end

function SkillsScene:enter()
    self.spellRects = {}
    self.slotRects = {}
    self.hoveredSpellId = nil
    self.hoveredSlotIndex = nil
    self.windowRects = {}
    self.windowLayout = nil
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
    self.windowRects = {}

    for _, system in ipairs(self.systems.draw) do
        system(self)
    end

    love.graphics.pop()
end

function SkillsScene:keypressed(key)
    local action = InputManager.getActionForKey(key)
    if action ~= InputActions.TOGGLE_SKILLS and action ~= InputActions.CLOSE_MODAL then
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

    local closeRect = self.windowRects and self.windowRects.close
    if closeRect
        and x >= closeRect.x
        and x <= closeRect.x + closeRect.w
        and y >= closeRect.y
        and y <= closeRect.y + closeRect.h
    then
        if self.world and self.world.sceneManager then
            self.world.sceneManager:pop()
        end
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
