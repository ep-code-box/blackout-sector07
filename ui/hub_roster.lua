-- 펍 로스터 관리 UI 모듈
local UI = require("ui.theme")
local Roster = require("systems.roster")
local UIRoster = {}

function UIRoster.draw(party, roster_cursor)
    local color = {1, 0.5, 0}
    local panel_cfg = {
        x = 50, y = 50, w = 700, h = 400,
        title = "Roster Management (Max 5)", color = color
    }
    
    local unlocked_pool = Roster.getUnlockedPool()
    local list_cfg = {
        size = #unlocked_pool, cursor = roster_cursor, max_visible = 10, item_h = 30
    }

    UI.drawScrollingList(panel_cfg, list_cfg, function(idx, x, y, w, h, is_selected)
        local merc = unlocked_pool[idx]
        
        if is_selected then
            love.graphics.setColor(1, 1, 1, 0.1); love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(1, 1, 1, 1); love.graphics.print(">", x + 5, y + 5)
        end
        
        local is_in_party = false
        for _, p_merc in ipairs(party) do if p_merc.id == merc.id then is_in_party = true; break end end
        
        local formation_tag = (merc.formation or "front") == "rear" and "[R]" or "[F]"
        local f_color = (merc.formation or "front") == "rear" and {0.3,0.7,1} or {1,0.6,0.1}
        love.graphics.setColor(is_in_party and {0, 1, 0} or {0.5, 0.5, 0.5})
        love.graphics.print(string.format("[%s] %s (Lv.%d %s)", is_in_party and "X" or " ", merc.name, merc.level, merc.class), x + 30, y + 5)
        love.graphics.setColor(f_color)
        love.graphics.print(formation_tag, x + 30 + 370, y + 5)
        
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.text_dim)
        local stats = string.format("HP:%d SP:%d STR:%d DEX:%d AGI:%d", merc.max_hp, merc.max_sp, merc.str, merc.dex, merc.agi)
        love.graphics.printf(stats, x, y + 8, w - 10, "right")
        love.graphics.setFont(UI.font_normal)
    end)
    
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.print("[SPACE] 선택/해제  [F] 전열/후열 전환  [ESC] 닫기", 70, 420, 0, 0.8, 0.8)
end

return UIRoster