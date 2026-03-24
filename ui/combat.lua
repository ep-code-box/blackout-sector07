-- 전투 모드 UI 리뉴얼 (HD Widescreen Optimized V3)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager")
local UICombat = {}

-- 진형에 따른 파티원 화면 좌표 계산
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
    -- 전열: 좌측, y=530
    local f_x0 = #fronts == 1 and 360 or (#fronts == 2 and 200 or 80)
    for j, idx in ipairs(fronts) do
        positions[idx] = { x = f_x0 + (j-1)*230, y = 530 }
    end
    -- 후열: 우측, y=495 (약간 뒤에 있는 느낌)
    local r_x0 = #rears == 1 and 860 or 730
    for j, idx in ipairs(rears) do
        positions[idx] = { x = r_x0 + (j-1)*230, y = 495 }
    end
    return positions
end

function UICombat.draw(party, enemy_sprite, current_turn, selected_menu, log_msg, current_enemy, timer)
    -- 1. 상단 정보 스트림 (와이드 해상도 대응)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 1280, 45)
    love.graphics.setColor(UI.color.highlight)
    love.graphics.setFont(UI.font_normal)
    love.graphics.print(">> STATUS: " .. log_msg, 30, 15)

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
        local pos = positions[i] or { x = 50 + (i-1)*220, y = 515 }
        local x, y = pos.x, pos.y

        if current_turn == i then
            love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.1)
            love.graphics.rectangle("fill", x-10, y-10, 215, 175)
            love.graphics.setColor(UI.color.highlight)
            love.graphics.rectangle("line", x-10, y-10, 215, 175)
        end

        local face_path = UI.getFacePath(char.sprite, char.id)
        local face_img = AssetManager.loadImage(face_path, face_path)
        if face_img then
            love.graphics.setColor(char.hp <= 0 and {0.3,0.3,0.3} or {1,1,1,1})
            love.graphics.draw(face_img, x, y, 0, 110/face_img:getWidth(), 110/face_img:getHeight())
            local fc = current_turn == i and UI.color.highlight or UI.color.accent
            love.graphics.setColor(fc[1], fc[2], fc[3], 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x-2, y-2, 114, 114)
            love.graphics.setLineWidth(1)
        end

        -- 진형 뱃지
        local is_rear = (char.formation or "front") == "rear"
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(is_rear and {0.3,0.7,1} or {1,0.6,0.1})
        love.graphics.print(is_rear and "[R]" or "[F]", x, y - 14)

        UI.drawGauge(x + 120, y + 5,  80, 6, char.hp/char.max_hp, "HP", char.hp, UI.color.danger)
        UI.drawGauge(x + 120, y + 30, 80, 6, char.sp/char.max_sp, "SP", char.sp, {0.2, 0.6, 1})

        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(char.name, x, y + 118, 110, "center")
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
            UI.drawPanel(tx, 250, 220, 90, L("ui_skill_intel"), UI.color.highlight)
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
