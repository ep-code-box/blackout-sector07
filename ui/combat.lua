-- 전투 모드 UI 리뉴얼 (HD Widescreen Optimized V3)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager")
local FXManager = require("systems.fx_manager")
local UICombat = {}

-- UTF-8 안전 문자열 자르기 (한글 등 멀티바이트 문자 깨짐 방지)
local function utf8sub(s, n)
    local count, i = 0, 1
    while i <= #s and count < n do
        local b = s:byte(i)
        if b >= 240 then i = i + 4
        elseif b >= 224 then i = i + 3
        elseif b >= 192 then i = i + 2
        else i = i + 1 end
        count = count + 1
    end
    return s:sub(1, i - 1)
end

local timeline_hook_fired = false  -- E2E 훅 중복 방지

-- Agility 기반 턴 순서 타임라인 (상단 우측)
local function drawTurnTimeline(party, enemy, timer)
    local actors = {}
    for i, p in ipairs(party) do
        table.insert(actors, { name = p.name, agi = p.agi or 10, is_enemy = false, alive = p.hp > 0 })
    end
    table.insert(actors, { name = enemy.name, agi = enemy.agi or 10, is_enemy = true, alive = enemy.hp > 0 })
    table.sort(actors, function(a, b) return a.agi > b.agi end)

    local item_w, item_h = 88, 28
    local gap     = 4
    local total_w = #actors * (item_w + gap) - gap
    local start_x = 1260 - total_w
    local y       = 6

    -- 배경 바
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", start_x - 6, y - 2, total_w + 12, item_h + 4, 2)

    if not timeline_hook_fired then
        print("E2E_HOOK: TIMELINE_DRAWN")
        timeline_hook_fired = true
    end

    love.graphics.setFont(UI.font_small)
    for i, actor in ipairs(actors) do
        local x = start_x + (i-1) * (item_w + gap)
        local color = actor.is_enemy and UI.color.danger or UI.color.highlight
        if not actor.alive then color = {0.3, 0.3, 0.35} end

        -- 테두리
        love.graphics.setColor(color[1], color[2], color[3], 0.9)
        love.graphics.rectangle("line", x, y, item_w, item_h, 2)
        -- 배경
        love.graphics.setColor(color[1], color[2], color[3], 0.12)
        love.graphics.rectangle("fill", x, y, item_w, item_h, 2)
        -- 이름 + AGI
        love.graphics.setColor(color)
        local label = utf8sub(actor.name, 4)  -- 최대 4글자 (한글 포함)
        love.graphics.printf(label .. " " .. actor.agi, x + 2, y + 7, item_w - 4, "center")
    end
end

-- 진형에 따른 파티원 화면 좌표 계산 (원근감 반영)
local function getActorPositions(party)
    local fronts, rears = {}, {}
    for i, char in ipairs(party) do
        if (char.formation or "front") == "rear" then
            table.insert(rears, i)
        else
            table.insert(fronts, i)
        end
    end

    local positions = {}
    -- 전열: 좌측, y=535, 원근감상 가까운 위치 (카드 크기 scale=1.0)
    local f_x0 = #fronts == 1 and 360 or (#fronts == 2 and 200 or 80)
    for j, idx in ipairs(fronts) do
        positions[idx] = { x = f_x0 + (j-1)*230, y = 535, scale = 1.0, alpha = 1.0 }
    end
    -- 후열: 우측, y=505, 원근감상 먼 위치 (카드 크기 scale=0.82, 살짝 투명)
    local r_x0 = #rears == 1 and 860 or 730
    for j, idx in ipairs(rears) do
        positions[idx] = { x = r_x0 + (j-1)*230, y = 505, scale = 0.82, alpha = 0.88 }
    end
    return positions
end

function UICombat.reset()
    timeline_hook_fired = false
end

function UICombat.draw(party, enemy_sprite, current_turn, selected_menu, log_msg, current_enemy, timer)
    -- 글리치 상태에서 패널 강조색 변경
    local panel_color = FXManager.isGlitching() and UI.color.danger or UI.color.highlight

    -- 1. 상단 정보 스트림 + 턴 순서 타임라인
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 1280, 45)
    love.graphics.setColor(panel_color)
    love.graphics.setFont(UI.font_normal)
    love.graphics.print(">> STATUS: " .. log_msg, 30, 15)
    drawTurnTimeline(party, current_enemy, timer)

    -- 2. 적 일러스트 (중앙 와이드 배치)
    if enemy_sprite then
        local sw, sh = enemy_sprite:getDimensions()
        local scale = 450 / sh

        love.graphics.setColor(1, 0, 1, 0.3)
        love.graphics.ellipse("line", 640, 420, 250, 60) -- 네온 링 확대 및 중앙

        local float_y = math.sin(timer * 1.5) * 10
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(enemy_sprite, 640, 250 + float_y, 0, scale, scale, sw/2, sh/2)

        -- 네온 스캔 프레임
        local ew, eh = sw * scale, sh * scale
        local ex, ey = 640 - ew/2, 250 + float_y - eh/2
        local pad = 6
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.9)
        love.graphics.setLineWidth(2)
        local cs = 20
        -- 코너 마커 (홀로그램 느낌)
        love.graphics.line(ex-pad, ey-pad, ex-pad+cs, ey-pad)
        love.graphics.line(ex-pad, ey-pad, ex-pad, ey-pad+cs)
        love.graphics.line(ex+ew+pad-cs, ey-pad, ex+ew+pad, ey-pad)
        love.graphics.line(ex+ew+pad, ey-pad, ex+ew+pad, ey-pad+cs)
        love.graphics.line(ex-pad, ey+eh+pad-cs, ex-pad, ey+eh+pad)
        love.graphics.line(ex-pad, ey+eh+pad, ex-pad+cs, ey+eh+pad)
        love.graphics.line(ex+ew+pad, ey+eh+pad-cs, ex+ew+pad, ey+eh+pad)
        love.graphics.line(ex+ew+pad, ey+eh+pad, ex+ew+pad-cs, ey+eh+pad)
        love.graphics.setLineWidth(1)
        
        -- 적 HP 바 (중앙 상단 와이드화)
        UI.drawGauge(440, 60, 400, 10, current_enemy.hp / current_enemy.max_hp, current_enemy.name, current_enemy.hp .. "/" .. current_enemy.max_hp, UI.color.danger)
    end
    
    -- 3. 아군 전술 패널 (하단 와이드 배치)
    UI.drawPanel(20, 470, 1240, 230, L("ui_tactical_interface") .. " // Sector 07 Link")

    -- 진형 구분선
    love.graphics.setColor(UI.color.accent[1], UI.color.accent[2], UI.color.accent[3], 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.line(650, 478, 650, 695)
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.print("FRONT", 100, 478)
    love.graphics.print("REAR", 780, 478)
    love.graphics.setLineWidth(1)

    local positions = getActorPositions(party)

    for i, char in ipairs(party) do
        local pos   = positions[i] or { x = 50 + (i-1)*220, y = 515, scale = 1.0, alpha = 1.0 }
        local x, y  = pos.x, pos.y
        local sc    = pos.scale or 1.0
        local alpha = pos.alpha or 1.0
        local face_px = math.floor(110 * sc)  -- 원근감 반영 얼굴 크기
        local card_w  = face_px + 94           -- 카드 전체 너비(얼굴 + 게이지)

        if current_turn == i then
            love.graphics.setColor(panel_color[1], panel_color[2], panel_color[3], 0.1)
            love.graphics.rectangle("fill", x-10, y-10, card_w + 10, math.floor(175 * sc))
            love.graphics.setColor(panel_color)
            love.graphics.rectangle("line", x-10, y-10, card_w + 10, math.floor(175 * sc))
        end

        local face_path = UI.getFacePath(char.sprite, char.id)
        local face_img = AssetManager.loadImage(face_path, face_path)
        if face_img then
            local base_color = char.hp <= 0 and {0.3, 0.3, 0.3, alpha} or {1, 1, 1, alpha}
            love.graphics.setColor(unpack(base_color))
            love.graphics.draw(face_img, x, y, 0, face_px/face_img:getWidth(), face_px/face_img:getHeight())
            local fc = current_turn == i and panel_color or UI.color.accent
            love.graphics.setColor(fc[1], fc[2], fc[3], 0.9 * alpha)
            love.graphics.setLineWidth(sc > 0.9 and 2 or 1)
            love.graphics.rectangle("line", x-2, y-2, face_px + 4, face_px + 4)
            love.graphics.setLineWidth(1)
        end

        -- 진형 뱃지
        local is_rear = (char.formation or "front") == "rear"
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(is_rear and {0.3, 0.7, 1, alpha} or {1, 0.6, 0.1, alpha})
        love.graphics.print(is_rear and "[R]" or "[F]", x, y - 14)

        local gauge_x = x + face_px + 10
        UI.drawGauge(gauge_x, y + 5,  80, 6, char.hp/char.max_hp, "HP", char.hp, UI.color.danger)
        UI.drawGauge(gauge_x, y + 30, 80, 6, char.sp/char.max_sp, "SP", char.sp, {0.2, 0.6, 1})

        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(char.name, x, y + face_px + 8, face_px, "center")
    end

    -- 4. 커맨드 메뉴 (현재 캐릭터 위에 팝업)
    if current_turn <= #party then
        local pos = positions[current_turn] or { x = 50 + (current_turn-1)*220, y = 515 }
        local tx = pos.x
        local char = party[current_turn]
        local skills = char.skills or {}
        local DBManager = require("systems.db_manager")
        local SkillsDB = DBManager.getSkillDict()
        
        -- 스킬 인텔 (커맨드 메뉴 위)
        local selected_skill_name = skills[selected_menu]
        local skill_data = SkillsDB[selected_skill_name]
        
        if skill_data then
            UI.drawPanel(tx, 250, 220, 90, L("ui_skill_intel"), panel_color)
            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(UI.color.accent)
            love.graphics.print(L("ui_cost") .. ": " .. (skill_data.sp or 0) .. " SP", tx + 10, 275)
            love.graphics.setColor(UI.color.text_main)
            love.graphics.printf(skill_data.desc or "", tx + 10, 295, 200, "left")
        end

        -- 커맨드 리스트
        UI.drawPanel(tx, 350, 160, 120, L("ui_commands"), UI.color.accent)
        for i, cmd in ipairs(skills) do
            local sy = 380 + (i-1) * 30
            local s_data = SkillsDB[cmd]
            local display_name = L(cmd) .. (s_data and s_data.sp and s_data.sp > 0 and " ("..s_data.sp..")" or "")
            UI.drawButton(tx + 5, sy, 150, 26, display_name, selected_menu == i, UI.color.accent)
        end
    end
end

return UICombat
