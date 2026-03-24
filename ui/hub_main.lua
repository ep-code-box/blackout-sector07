-- 펍 메인 메뉴 및 배경 UI 모듈 (Layout Engine Integration)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager")
local Inventory = require("systems.inventory")
local UIHubMain = {}

function UIHubMain.draw(pub_bg, npc_bartender, quests_db, party, menu_keys, selected_menu, dialogue)
    -- 1. 배경 (1280x720 전체 화면)
    love.graphics.setColor(1, 1, 1, 0.4)
    local bg = AssetManager.loadImage("map_pub", "assets/images/map/map_pub.png")
    if bg then 
        local sw, sh = bg:getDimensions()
        love.graphics.draw(bg, 0, 0, 0, 1280/sw, 720/sh) 
    end
    
    -- 2. NPC 배치 (얼굴 가림 방지 배치)
    love.graphics.setColor(1, 1, 1, 1)
    local npc = AssetManager.loadImage("npc_bartender", "assets/images/npc/npc_bartender.png")
    if npc then
        local sw, sh = npc:getDimensions()
        local scale = 750 / sh
        -- 캐릭터를 왼쪽 1/3 지점에 배치
        love.graphics.draw(npc, 400, 400, 0, scale, scale, sw/2, sh/2)
    end

    -- [우측 정보 컬럼: 레이아웃 엔진 사용]
    local col_x, col_y, col_w, col_h = 880, 20, 380, 680
    UI.beginLayout(col_x, col_y, col_w, col_h, 10)

    -- 3. 파티 요약 패널
    local px, py, pw, ph = UI.nextItem(180, 10)
    UI.drawPanel(px, py, pw, ph, L("ui_squad_status"))
    for i, char in ipairs(party) do
        local sy = py + 35 + (i-1) * 28
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%s [%s.%d]", char.name, L("ui_level"), char.level), px + 15, sy)
        love.graphics.setColor(UI.color.danger[1], UI.color.danger[2], UI.color.danger[3], 0.3)
        love.graphics.rectangle("fill", px + 200, sy+4, 140, 8)
        love.graphics.setColor(UI.color.danger)
        love.graphics.rectangle("fill", px + 200, sy+4, 140 * (char.hp/char.max_hp), 8)
    end

    -- 4. 미션 아카이브 패널
    local ax, ay, aw, ah = UI.nextItem(220, 10)
    UI.drawPanel(ax, ay, aw, ah, L("ui_mission_archive"), {0, 1, 0.8})
    local max_visible = 6
    local active_idx = 1
    for i, q in ipairs(quests_db) do if not q.completed then active_idx = i break end end
    local start_idx, end_idx, scroll_ratio = UI.getScrollWindow(#quests_db, active_idx, max_visible)
    for i = start_idx, end_idx do
        local q = quests_db[i]
        local display_i = i - start_idx + 1
        local y = ay + 30 + (display_i * 24)
        love.graphics.setFont(UI.font_small)
        if not q.completed then
            love.graphics.setColor(UI.color.highlight)
            love.graphics.print(">", ax + 15, y)
            love.graphics.setColor(UI.color.text_main)
        else love.graphics.setColor(0.4, 0.4, 0.4) end
        love.graphics.print((q.completed and "[DONE] " or "[ACTV] ") .. q.title, ax + 35, y)
    end
    UI.drawScrollBar(ax + aw - 10, ay + 40, 3, ah - 50, #quests_db, max_visible, scroll_ratio, {0, 1, 0.8})

    -- 5. 커맨드 센터 패널 (메뉴)
    local cx, cy, cw, ch = UI.nextItem(250, 0)
    UI.drawPanel(cx, cy, cw, ch, L("ui_central_command"), UI.color.accent)
    for i, key in ipairs(menu_keys) do
        local by = cy + 40 + (i-1) * 28
        UI.drawButton(cx + 15, by, cw - 30, 24, L(key), selected_menu == i, UI.color.accent)
    end

    UI.endLayout()

    -- 6. 하단 대화창 & 시스템 로그
    UI.drawPanel(20, 580, 840, 120, L("ui_system_comms"))
    love.graphics.setFont(UI.font_normal)
    love.graphics.setColor(UI.color.text_main)
    love.graphics.printf(dialogue, 50, 620, 780, "left")

    local time = love.timer.getTime()
    UI.drawNoiseLine(20, 550, 350, UI.color.text_dim)
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.print(L("ui_uplink_stable"), 40, 535)
    love.graphics.printf(L("ui_latency") .. ": " .. math.floor(20 + math.sin(time*10)*5) .. "ms", 20, 535, 330, "right")
    
    love.graphics.setColor(UI.color.accent)
    love.graphics.setFont(UI.font_normal)
    love.graphics.print(L("ui_credits") .. ": " .. (Inventory.credits or 0) .. " C", 40, 35)
end

return UIHubMain
