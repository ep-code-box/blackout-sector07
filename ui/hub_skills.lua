-- 스킬 업그레이드 UI (SKILLS / STATS / PROMOTE 탭 통합 V2)
local UI       = require("ui.theme")
local DBManager = require("systems.db_manager")
local UIHubSkills = {}

-- 스탯 목록 (순서 고정)
local STAT_LIST = {
    {k="str", n="STR", c={1,0.3,0.3},  desc="물리 공격력 · 근접 대미지 기반"},
    {k="dex", n="DEX", c={0.3,0.8,1},  desc="크리티컬 확률 · 크리 시 방어 감소"},
    {k="int", n="INT", c={0.3,0.5,1},  desc="마법/해킹 대미지 · SP 회복 관련"},
    {k="con", n="CON", c={0.2,0.9,0.4},desc="물리 방어력 · 체력 생존 관련"},
    {k="agi", n="AGI", c={1,0.3,1},    desc="회피율 · 반격 · 속도 관련"},
    {k="edg", n="EDG", c={0,1,1},      desc="크리티컬 확률 · 크레딧 획득 관련"},
}

function UIHubSkills.draw(party, selected_char_idx, skill_cursor, skill_mode, stat_cursor, promote_cursor)
    local char = party[selected_char_idx]
    if not char then return end

    skill_mode    = skill_mode    or "skill"
    stat_cursor   = stat_cursor   or 1
    promote_cursor = promote_cursor or 1

    local wx, wy, ww, wh = UI.drawWindow(0.5, 0.5, 0.82, 0.78,
        "NEURAL INTERFACE: SKILL CALIBRATION", UI.color.accent)

    -- ── 캐릭터 헤더 ──────────────────────────────────────────────────────────
    love.graphics.setFont(UI.font_large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(char.name .. "  //  " .. L(char.class), wx + 30, wy + 40)

    if char.specialization then
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.accent)
        love.graphics.print("★ " .. char.specialization:upper(), wx + 30, wy + 70)
    end

    -- ── 탭 버튼 ──────────────────────────────────────────────────────────────
    local tabs = {
        {key="skill",   label="[1] SKILLS   SP:" .. (char.skill_points or 0)},
        {key="stat",    label="[2] STATS   PTS:" .. (char.stat_points or 0)},
    }
    if char.can_promote then
        table.insert(tabs, {key="promote", label="[3] PROMOTE ★"})
    end

    for i, tab in ipairs(tabs) do
        local is_active = (skill_mode == tab.key)
        love.graphics.setFont(UI.font_normal)
        love.graphics.setColor(is_active and UI.color.accent or UI.color.text_dim)
        love.graphics.print(tab.label, wx + 30 + (i-1) * 220, wy + 95)
        if is_active then
            love.graphics.setColor(UI.color.accent)
            love.graphics.line(wx + 30 + (i-1)*220, wy + 115, wx + 210 + (i-1)*220, wy + 115)
        end
    end

    -- ── 콘텐츠 영역 ──────────────────────────────────────────────────────────
    local cy = wy + 130

    if skill_mode == "skill" then
        -- ── 스킬 목록 ────────────────────────────────────────────────────────
        local skills = char.skills or {}
        local SkillsDB = DBManager.getSkillDict()
        for i, s_name in ipairs(skills) do
            local sy         = cy + (i-1) * 65
            local is_sel     = (skill_cursor == i)
            local s_data     = SkillsDB[s_name] or {}
            local lv         = (char.skill_levels and char.skill_levels[s_name]) or 1

            UI.drawButton(wx + 30, sy, ww - 60, 58, "", is_sel, UI.color.highlight)

            love.graphics.setFont(UI.font_normal)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(L(s_name) .. "  LV." .. lv, wx + 60, sy + 10)

            -- SP 비용
            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(UI.color.accent)
            local sp_text = (s_data.sp or 0) > 0 and ("SP " .. s_data.sp) or "FREE"
            love.graphics.printf(sp_text, wx + 30, sy + 12, ww - 90, "right")

            -- 설명
            love.graphics.setColor(UI.color.text_dim)
            love.graphics.printf(s_data.desc or "", wx + 60, sy + 33, ww - 120, "left")

            if is_sel and (char.skill_points or 0) > 0 then
                love.graphics.setColor(UI.color.accent)
                love.graphics.printf("[SPACE] CALIBRATE -1 SP", wx + 30, sy + 33, ww - 90, "right")
            elseif is_sel and (char.skill_points or 0) <= 0 then
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.printf("SP 부족", wx + 30, sy + 33, ww - 90, "right")
            end
        end

    elseif skill_mode == "stat" then
        -- ── 스탯 투자 ────────────────────────────────────────────────────────
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.print("스탯 20/40 도달 시 펄크(Perk)가 자동 해제됩니다.", wx + 30, cy - 10)

        for i, s in ipairs(STAT_LIST) do
            local sy     = cy + 10 + (i-1) * 60
            local is_sel = (stat_cursor == i)
            local val    = char[s.k] or 0

            UI.drawButton(wx + 30, sy, ww - 60, 52, "", is_sel, UI.color.highlight)

            -- 스탯 이름 & 값
            love.graphics.setFont(UI.font_normal)
            love.graphics.setColor(s.c)
            love.graphics.print(s.n, wx + 60, sy + 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(val .. " / 50", wx + 115, sy + 8)

            -- 설명
            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(UI.color.text_dim)
            love.graphics.print(s.desc, wx + 220, sy + 10)

            -- 펄크 진행도
            local next_thr = val < 20 and 20 or (val < 40 and 40 or nil)
            if next_thr then
                local progress = next_thr == 20 and (val / 20) or ((val - 20) / 20)
                love.graphics.setColor(0.25, 0.25, 0.25)
                love.graphics.rectangle("fill", wx + 220, sy + 30, 200, 8)
                love.graphics.setColor(s.c[1]*0.7, s.c[2]*0.7, s.c[3]*0.7)
                love.graphics.rectangle("fill", wx + 220, sy + 30, 200 * math.min(1, progress), 8)
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print("PERK @ " .. next_thr, wx + 430, sy + 28)
            else
                love.graphics.setColor(UI.color.accent)
                love.graphics.print("✦ MAX PERK", wx + 220, sy + 30)
            end

            if is_sel then
                if (char.stat_points or 0) > 0 then
                    love.graphics.setColor(UI.color.accent)
                    love.graphics.printf("[SPACE] +1 투자", wx + 30, sy + 10, ww - 90, "right")
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                    love.graphics.printf("포인트 없음", wx + 30, sy + 10, ww - 90, "right")
                end
            end
        end

    elseif skill_mode == "promote" then
        -- ── 전직 선택 ────────────────────────────────────────────────────────
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor({1, 0.6, 0.1})
        love.graphics.print("⚠  전직은 되돌릴 수 없습니다. 신중하게 선택하세요.", wx + 30, cy - 10)

        local Evolution  = require("data.data_evolution")
        local class_evo  = Evolution.classes and Evolution.classes[char.class]
        local spec_list  = {}
        if class_evo and class_evo.tier_2 then
            for spec_name, spec_data in pairs(class_evo.tier_2) do
                table.insert(spec_list, {name = spec_name, data = spec_data})
            end
            table.sort(spec_list, function(a, b) return a.name < b.name end)
        end

        for i, spec in ipairs(spec_list) do
            local sy     = cy + 10 + (i-1) * 130
            local is_sel = (promote_cursor == i)

            UI.drawButton(wx + 30, sy, ww - 60, 118, "", is_sel, is_sel and UI.color.accent or UI.color.highlight)

            love.graphics.setFont(UI.font_large)
            love.graphics.setColor(is_sel and UI.color.accent or {0.8, 0.8, 0.8})
            love.graphics.print(">> " .. spec.name, wx + 60, sy + 12)

            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(UI.color.text_dim)
            love.graphics.printf(spec.data.desc or "", wx + 60, sy + 42, ww - 140, "left")

            -- 보너스 스탯
            if spec.data.bonus then
                local bonus_str = "BONUS: "
                for stat, val in pairs(spec.data.bonus) do
                    bonus_str = bonus_str .. stat:upper() .. "+" .. val .. "  "
                end
                love.graphics.setColor(UI.color.accent)
                love.graphics.print(bonus_str, wx + 60, sy + 88)
            end

            -- 신규 스킬
            if spec.data.new_skills then
                local skill_str = "NEW SKILL: "
                for _, sk in ipairs(spec.data.new_skills) do
                    skill_str = skill_str .. L(sk) .. "  "
                end
                love.graphics.setColor({0.8, 1, 0.4})
                love.graphics.print(skill_str, wx + 60 + (ww/2), sy + 88)
            end

            if is_sel then
                love.graphics.setColor(UI.color.accent)
                love.graphics.printf("[SPACE] 전직 확정", wx + 30, sy + 12, ww - 90, "right")
            end
        end
    end

    -- ── 하단 안내 ────────────────────────────────────────────────────────────
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    local hint = "[TAB] 다음 캐릭터  [↑↓] 선택  [1]스킬  [2]스탯"
    if char.can_promote then hint = hint .. "  [3]전직★" end
    hint = hint .. "  [ESC] 닫기"
    love.graphics.printf(hint, wx, wy + wh - 28, ww, "center")
end

return UIHubSkills
