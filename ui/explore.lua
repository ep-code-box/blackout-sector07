-- 탐험 모드 UI 리뉴얼 (HD Widescreen Optimized V2)
local UI = require("ui.theme")
local UIExplore = {}

function UIExplore.draw(map, player, blink_alpha, interaction_msg)
    if not map or #map == 0 or not map[1] then return end
    local time = love.timer.getTime()
    
    -- 1. 미니맵 (우측 상단, 크기 확장 및 위치 조정)
    local mw, mh = 240, 240
    local mx, my = 1020, 20
    UI.drawPanel(mx, my, mw, mh, L("ui_radar_title"))
    
    -- 그리드 배경 (어두운 레이더망)
    love.graphics.setColor(0.02, 0.08, 0.1, 0.8)
    love.graphics.rectangle("fill", mx + 10, my + 35, mw - 20, mh - 45)

    -- 레이더 스캔 라인 애니메이션
    local scan_pos = (time * 1.2) % 1
    love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.15 * (1-scan_pos))
    love.graphics.rectangle("fill", mx + 10, my + 35 + scan_pos * (mh - 45), mw - 20, 2)

    local map_h = #map
    local map_w = #map[1]
    -- 패널 내부에 딱 맞게 타일 크기 자동 계산
    local padding = 15
    local available_w = mw - (padding * 2)
    local available_h = mh - 35 - (padding * 2)
    local tile_size = math.min(available_w / map_w, available_h / map_h)
    
    -- 중앙 정렬을 위한 시작 오프셋
    local start_x = mx + padding + (available_w - (map_w * tile_size)) / 2
    local start_y = my + 35 + padding + (available_h - (map_h * tile_size)) / 2
    
    for y = 1, map_h do
        for x = 1, map_w do
            local dx = start_x + (x-1)*tile_size
            local dy = start_y + (y-1)*tile_size
            
            -- 타일 베이스
            if map[y][x] == 0 then
                love.graphics.setColor(0.05, 0.15, 0.2, 0.4) -- 벽
            else
                love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.15) -- 길
            end
            love.graphics.rectangle("fill", dx, dy, tile_size-1, tile_size-1)
            
            -- 이벤트 마커 (강조)
            local marker_alpha = 0.6 + math.sin(time * 8) * 0.4
            if map[y][x] == 2 then -- 적
                love.graphics.setColor(UI.color.danger[1], UI.color.danger[2], UI.color.danger[3], marker_alpha)
                love.graphics.rectangle("fill", dx+tile_size*0.2, dy+tile_size*0.2, tile_size*0.6, tile_size*0.6)
            elseif map[y][x] == 3 then -- 보물
                love.graphics.setColor(UI.color.accent[1], UI.color.accent[2], UI.color.accent[3], marker_alpha)
                love.graphics.circle("fill", dx+tile_size/2, dy+tile_size/2, tile_size*0.3)
            elseif map[y][x] == 4 then -- 출구
                love.graphics.setColor(0, 1, 0.5, marker_alpha)
                love.graphics.rectangle("line", dx+1, dy+1, tile_size-3, tile_size-3)
            end
            
            -- 플레이어 아이콘
            if player.x == x and player.y == y then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", dx-1, dy-1, tile_size+1, tile_size+1)
                love.graphics.setColor(UI.color.highlight)
                love.graphics.rectangle("fill", dx+1, dy+1, tile_size-3, tile_size-3)
                
                -- 시선 방향 삼각형
                local cx, cy = dx + tile_size/2, dy + tile_size/2
                local s = tile_size * 0.6
                love.graphics.setColor(1, 1, 1)
                if player.facing == "north" then love.graphics.polygon("fill", cx, cy-s, cx-s/2, cy, cx+s/2, cy)
                elseif player.facing == "south" then love.graphics.polygon("fill", cx, cy+s, cx-s/2, cy, cx+s/2, cy)
                elseif player.facing == "east" then love.graphics.polygon("fill", cx+s, cy, cx, cy-s/2, cx, cy+s/2)
                elseif player.facing == "west" then love.graphics.polygon("fill", cx-s, cy, cx, cy-s/2, cx, cy+s/2) end
            end
        end
    end
    
    -- 2. 상단 정보 허브 (동적 데이터 강화)
    UI.drawPanel(20, 20, 480, 130, L("ui_uplink_title"))
    local StoryManager = require("systems.story_manager")
    local DB = require("systems.db_manager")
    local cur_chap = DB.query(string.format(
        "SELECT * FROM story_chapters WHERE chapter_order=%d LIMIT 1",
        math.max(1, StoryManager.current_chapter - 1)
    ))
    cur_chap = cur_chap and cur_chap[1]
    if cur_chap then
        love.graphics.setFont(UI.font_normal)
        love.graphics.setColor(UI.color.accent)
        love.graphics.print(L(cur_chap.title), 40, 50)
    end

    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.highlight)
    love.graphics.print(string.format("%s: [%02d, %02d]  |  %s: %s", L("ui_pos_data"), player.x, player.y, L("ui_orientation"), player.facing:upper()), 40, 100)
    
    local link_ratio = 0.85 + math.sin(time * 3) * 0.1
    UI.drawTechnicalBar(40, 125, 440, 6, link_ratio, L("ui_neural_link"), UI.color.highlight)
    
    -- 3. 상호작용 알림
    if interaction_msg ~= "" then
        UI.drawPanel(440, 320, 400, 70, L("ui_system_alert"), UI.color.accent)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(UI.font_normal)
        love.graphics.printf(interaction_msg, 440, 355, 400, "center")
    end
    
    -- 4. 전체 화면 페이드
    if blink_alpha > 0 then
        love.graphics.setColor(0, 0, 0, blink_alpha)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
end

return UIExplore
