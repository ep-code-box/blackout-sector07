-- Hub 서브 상태: 스킬/스탯/전직 관리
local SkillsView = {}
local Progression = require("systems.progression")
local Evolution   = require("data.data_evolution")
local UIHubSkills = require("ui.hub_skills")

function SkillsView.new(party)
    local self = {
        party = party,
        char_idx = 1,
        cursor = 1,
        mode = "skill", -- "skill", "stat", "promote"
        stat_cursor = 1,
        promote_cursor = 1,
        dialogue = ""
    }
    return setmetatable(self, { __index = SkillsView })
end

function SkillsView:draw()
    UIHubSkills.draw(self.party, self.char_idx, self.cursor, self.mode, self.stat_cursor, self.promote_cursor)
end

function SkillsView:getDialogue()
    local d = self.dialogue
    self.dialogue = "" -- 소모성
    return d
end

function SkillsView:keypressed(key)
    local char = self.party[self.char_idx]
    if not char then return "exit" end

    if key == "escape" then return "exit" end

    if key == "tab" then
        self.char_idx = (self.char_idx % #self.party) + 1
        self.cursor = 1; self.stat_cursor = 1; self.promote_cursor = 1
        self.mode = "skill"
        return nil
    end

    if key == "1" then self.mode = "skill"; return nil end
    if key == "2" then self.mode = "stat"; return nil end
    if key == "3" and char.can_promote then self.mode = "promote"; return nil end

    if self.mode == "skill" then
        self:handleSkill(key, char)
    elseif self.mode == "stat" then
        self:handleStat(key, char)
    elseif self.mode == "promote" then
        self:handlePromote(key, char)
    end
    return nil
end

function SkillsView:handleSkill(key, char)
    local skills = char.skills or {}
    local n = math.max(1, #skills)
    if key == "up" then 
        self.cursor = (self.cursor - 2) % n + 1
    elseif key == "down" then 
        self.cursor = self.cursor % n + 1
    elseif key == "return" or key == "space" then
        if (char.skill_points or 0) > 0 then
            char.skill_levels = char.skill_levels or {}
            local s_name = skills[self.cursor]
            if s_name then
                char.skill_levels[s_name] = (char.skill_levels[s_name] or 1) + 1
                char.skill_points = char.skill_points - 1
                self.dialogue = string.format(L("hub_msg_skill_calibrated"), char.name, s_name:upper())
            end
        else
            self.dialogue = L("hub_msg_no_skill_pts")
        end
    end
end

function SkillsView:handleStat(key, char)
    if key == "up" then
        self.stat_cursor = (self.stat_cursor - 2) % 6 + 1
    elseif key == "down" then
        self.stat_cursor = self.stat_cursor % 6 + 1
    elseif key == "return" or key == "space" then
        local stat_keys = {"str","dex","int","con","agi","edg"}
        local ok, msg = Progression.investStat(char, stat_keys[self.stat_cursor])
        if ok then
            self.dialogue = string.format(L("hub_msg_stat_invested"), char.name, msg)
        else
            self.dialogue = string.format(L("hub_msg_stat_denied"), msg)
        end
    end
end

function SkillsView:handlePromote(key, char)
    local class_evo  = Evolution.classes and Evolution.classes[char.class]
    local spec_list  = {}
    if class_evo and class_evo.tier_2 then
        for spec_name, _ in pairs(class_evo.tier_2) do
            table.insert(spec_list, spec_name)
        end
        table.sort(spec_list)
    end
    local n = math.max(1, #spec_list)

    if key == "up" then
        self.promote_cursor = (self.promote_cursor - 2) % n + 1
    elseif key == "down" then
        self.promote_cursor = self.promote_cursor % n + 1
    elseif key == "return" or key == "space" then
        if spec_list[self.promote_cursor] then
            local ok, msg = Progression.promoteChar(char, spec_list[self.promote_cursor])
            if ok then
                self.dialogue = string.format(L("hub_msg_promote_success"), char.name, msg)
                self.mode = "skill"
            else
                self.dialogue = string.format(L("hub_msg_promote_fail"), msg)
            end
        end
    end
end

return SkillsView
