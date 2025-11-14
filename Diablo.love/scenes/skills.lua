local Spells = require("data.spells")
local InputManager = require("modules.input_manager")
local InputActions = require("modules.input_actions")
local SceneKinds = require("modules.scene_kinds")
local SkillTree = require("modules.skill_tree")

local renderWindowChrome = require("systems.render.window.chrome")
local renderSkillsList = require("systems.render.skills.list")
local renderSkillsEquipped = require("systems.render.skills.equipped")
local renderSkillsEquipMenu = require("systems.render.skills.equip_menu")
local renderSkillsTooltip = require("systems.render.skills.tooltip")
local renderSkillsTree = require("systems.render.skills.tree")

local SkillsScene = {}
SkillsScene.__index = SkillsScene

local function assignSpellToSlot(player, slotIndex, spellId)
    if not player or not player.skills then
        return
    end

    if slotIndex < 1 or slotIndex > 4 then
        return
    end

    if spellId == nil or spellId == "__clear__" then
        player.skills.equipped[slotIndex] = nil
        return
    end

    local slots = player.skills.equipped
    for index = 1, 4 do
        if slots[index] == spellId then
            slots[index] = nil
        end
    end

    slots[slotIndex] = spellId
end

function SkillsScene.new(opts)
    opts = opts or {}
    local world = assert(opts.world, "SkillsScene requires world reference")

    local scene = {
        world = world,
        kind = SceneKinds.SKILLS,
        title = "Skills",
        availableSpells = Spells.getAll(),
        windowLayoutOptions = {
            widthRatio = 0.8,
            heightRatio = 0.8,
            headerHeight = 72,
            padding = 28,
        },
        systems = {
            draw = {
                renderWindowChrome.draw,
                renderSkillsTree.draw,
                renderSkillsList.draw,
                renderSkillsEquipped.draw,
                renderSkillsEquipMenu.draw,
                renderSkillsTooltip.draw,
            },
        },
    }

    scene.windowChromeConfig = {
        title = scene.title,
        icon = "book_open",
        columns = {
            leftRatio = 0.5,
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
    self.hoveredSkillNode = nil
    self.windowRects = {}
    self.windowLayout = nil
    self.skillTreeNodeRects = {}
    self.equipMenu = nil
    self.isTreeVisible = false

    if (not self.selectedSpellId or not Spells.types[self.selectedSpellId]) and self.availableSpells then
        local firstSpell = self.availableSpells[1]
        self.selectedSpellId = firstSpell and firstSpell.id or nil
    end
end

-- luacheck: ignore 212/self
function SkillsScene:exit()
end

-- luacheck: ignore 212/self
function SkillsScene:update(_dt)
end

function SkillsScene:draw()
    love.graphics.push("all")

    local showTree = self.isTreeVisible and self.selectedSpellId ~= nil
    if self.windowChromeConfig then
        if showTree then
            self.windowLayoutOptions.widthRatio = 0.82
            self.windowChromeConfig.columns = { leftRatio = 0.42, spacing = 32 }
        else
            self.windowLayoutOptions.widthRatio = 0.54
            self.windowChromeConfig.columns = nil
        end
    end

    self.hoveredSpellId = nil
    self.hoveredSlotIndex = nil
    self.hoveredSkillNode = nil
    self.windowRects = {}
    self.skillTreeNodeRects = {}

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

    local equipMenu = self.equipMenu
    if equipMenu then
        local bounds = equipMenu.bounds
        local isInMenuBounds = bounds
            and x >= bounds.x
            and x <= bounds.x + bounds.w
            and y >= bounds.y
            and y <= bounds.y + bounds.h

        if isInMenuBounds then
            for _, option in ipairs(equipMenu.optionRects or {}) do
                if x >= option.x and x <= option.x + option.w and y >= option.y and y <= option.y + option.h then
                    assignSpellToSlot(player, equipMenu.slotIndex, option.spellId)
                    self.equipMenu = nil
                    return
                end
            end
        else
            self.equipMenu = nil
            return
        end
    end

    for _, rect in ipairs(self.skillTreeNodeRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local spell = rect.spellId and Spells.types[rect.spellId]
            if spell and player.skills then
                if rect.spellId then
                    self.selectedSpellId = rect.spellId
                end
                SkillTree.invest(player.skills, spell, rect.nodeId)
                self.equipMenu = nil
            end
            return
        end
    end

    for _, rect in ipairs(self.spellRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if rect.spell and rect.spell.id then
                self.selectedSpellId = rect.spell.id
                self.isTreeVisible = true
                self.equipMenu = nil
            end
            return
        end
    end

    for _, rect in ipairs(self.slotRects or {}) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            if self.equipMenu and self.equipMenu.slotIndex == rect.index then
                self.equipMenu = nil
                return
            end

            self.equipMenu = {
                slotIndex = rect.index,
                slotRect = {
                    x = rect.x,
                    y = rect.y,
                    w = rect.w,
                    h = rect.h,
                },
            }
            return
        end
    end
end

return SkillsScene
