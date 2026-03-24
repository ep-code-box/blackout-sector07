-- Hub 서브 상태: 용병 로스터 관리
local RosterView = {}
local Roster   = require("systems.roster")
local UIRoster = require("ui.hub_roster")

function RosterView.new()
    local self = {
        cursor = 1
    }
    return setmetatable(self, { __index = RosterView })
end

function RosterView:draw(party)
    UIRoster.draw(party, self.cursor)
end

function RosterView:keypressed(key)
    local unlocked_pool = Roster.getUnlockedPool()
    if key == "escape" then return "exit" end
    
    if key == "up" then 
        self.cursor = math.max(1, self.cursor - 1)
    elseif key == "down" then 
        self.cursor = math.min(#unlocked_pool, self.cursor + 1)
    elseif key == "space" or key == "return" then
        Roster.toggleMerc(unlocked_pool[self.cursor].id)
    elseif key == "f" then
        local merc = unlocked_pool[self.cursor]
        if merc then
            local new_slot = (merc.formation or "front") == "front" and "rear" or "front"
            Roster.setFormation(merc.id, new_slot)
        end
    end
    return nil
end

return RosterView
