-- 엔딩 화면 렌더링 모듈
local UI        = require("ui.theme")
local Roster    = require("systems.roster")
local StoryManager = require("systems.story_manager")

local EndingScreen = {}

function EndingScreen.draw()
    local ending_id   = StoryManager.world_flags.ending or "hope"
    local ending_data = StoryManager.endings[ending_id]
    local t           = love.timer.getTime()
    local accent      = UI.color.accent

    love.graphics.setColor(0, 0, 0, 0.92)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    love.graphics.setColor(accent[1], accent[2], accent[3], 0.4)
    love.graphics.rectangle("fill", 0, 340, 1280, 1)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.15)
    love.graphics.rectangle("fill", 0, 338, 1280, 3)

    local wx, wy, ww, wh = 290, 130, 700, 460
    UI.drawPanel(wx, wy, ww, wh, "// NEURAL ARCHIVE UNLOCKED //", accent)

    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(accent[1], accent[2], accent[3], 0.6)
    love.graphics.printf("ROUTE: " .. ending_id:upper(), wx, wy + 36, ww, "center")

    love.graphics.setFont(UI.font_title or UI.font_large)
    love.graphics.setColor(accent)
    love.graphics.printf(L(ending_data.title), wx, wy + 70, ww, "center")

    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("fill", wx + 60, wy + 140, ww - 120, 1)

    love.graphics.setFont(UI.font_normal)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.printf(L(ending_data.text), wx + 60, wy + 160, ww - 120, "center")

    local names = {}
    for _, m in ipairs(Roster.active_party) do
        table.insert(names, m.name .. " Lv." .. m.level)
    end
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.printf("SQUAD: " .. table.concat(names, "  //  "), wx, wy + 380, ww, "center")

    local blink = math.abs(math.sin(t * 1.8))
    local hl    = UI.color.highlight
    love.graphics.setColor(hl[1], hl[2], hl[3], blink)
    love.graphics.printf("[ PRESS ESC TO RETURN TO TITLE ]", wx, wy + 415, ww, "center")
end

return EndingScreen
