-- 상태창: 바이오메트릭 진단 터미널 (계산된 전투 수치 + 펄크 진행도 V2)
local UI           = require("ui.theme")
local Inventory    = require("systems.inventory")
local AssetManager = require("systems.asset_manager")
local StatusInfo   = {}

function StatusInfo.draw(char, x, y, equip_mode, slot_cursor, slot_keys)
    UI.beginLayout(x, y, 420, 560, 20)
    UI.drawPanel(x, y, 420, 560, L("ui_biometric_diag") .. ": " .. char.id:upper())

    -- ── [섹션 1] 초상화 + 신원 ───────────────────────────────────────────────
    local face_path = UI.getFacePath(char.sprite, char.id)
    local face_img  = AssetManager.loadImage(face_path, face_path)
    if face_img then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(face_img, x + 20, y + 40, 0, 80/face_img:getWidth(), 80/face_img:getHeight())
        -- 네온 테두리 + 코너 마커
        local fx, fy, fs = x + 20, y + 40, 80
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", fx - 2, fy - 2, fs + 4, fs + 4)
        local cs = 10
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(fx-2, fy-2, fx-2+cs, fy-2)
        love.graphics.line(fx-2, fy-2, fx-2, fy-2+cs)
        love.graphics.line(fx+fs+2-cs, fy-2, fx+fs+2, fy-2)
        love.graphics.line(fx+fs+2, fy-2, fx+fs+2, fy-2+cs)
        love.graphics.line(fx-2, fy+fs+2-cs, fx-2, fy+fs+2)
        love.graphics.line(fx-2, fy+fs+2, fx-2+cs, fy+fs+2)
        love.graphics.line(fx+fs+2, fy+fs+2-cs, fx+fs+2, fy+fs+2)
        love.graphics.line(fx+fs+2, fy+fs+2, fx+fs+2-cs, fy+fs+2)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setFont(UI.font_large)
    love.graphics.setColor(UI.color.text_main)
    love.graphics.print(char.name, x + 115, y + 45)

    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.highlight)
    local class_str = L(char.class)
    if char.specialization then class_str = class_str .. "  >>  " .. char.specialization end
    love.graphics.print(class_str, x + 115, y + 70)
    love.graphics.print(L("ui_level") .. ". " .. char.level, x + 115, y + 85)

    -- 경험치 바
    UI.drawTechnicalBar(x + 115, y + 100, 280, 6, (char.exp or 0)/100, L("ui_sync_rate"), UI.color.accent)

    UI.nextItem(115)

    -- ── [섹션 2] 코어 스탯 + 전투 수치 2열 ──────────────────────────────────
    local mid_rows = UI.splitRow(230, 2, 10)

    -- 좌측: 코어 스탯
    local left = mid_rows[1]
    UI.drawPanel(left.x, left.y, left.w, left.h, L("ui_core_biometrics"), {0.3, 0.3, 0.3})
    local stats = {
        {n="STR", k="str", c=UI.color.danger},
        {n="DEX", k="dex", c=UI.color.highlight},
        {n="INT", k="int", c={0.3, 0.6, 1}},
        {n="CON", k="con", c=UI.color.accent},
        {n="AGI", k="agi", c={1, 0.3, 1}},
        {n="EDG", k="edg", c={0, 1, 1}},
    }
    for i, s in ipairs(stats) do
        local sy  = left.y + 35 + (i-1) * 30
        local val = char[s.k] or 0
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(s.c)
        love.graphics.print(s.n, left.x + 15, sy)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(tostring(val), left.x + 15, sy, left.w - 30, "right")

        -- 펄크 진행 바 (해당 스탯의 다음 펄크 임계값까지 얼마나 왔는지)
        local next_thr = val < 20 and 20 or (val < 40 and 40 or nil)
        if next_thr then
            local base   = next_thr == 20 and 0 or 20
            local pct    = math.min(1, (val - base) / 20)
            local bx, bw = left.x + 55, 40
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", bx, sy + 4, bw, 4)
            love.graphics.setColor(s.c[1]*0.6, s.c[2]*0.6, s.c[3]*0.6)
            love.graphics.rectangle("fill", bx, sy + 4, bw * pct, 4)
        elseif val >= 40 then
            love.graphics.setColor(UI.color.accent)
            love.graphics.print("✦", left.x + 55, sy)
        end

        if (char.stat_points or 0) > 0 then
            love.graphics.setColor(UI.color.accent)
            love.graphics.print("[스킬탭→스탯]", left.x + 55, sy)
        end
    end

    -- 우측: 계산된 전투 수치
    local right = mid_rows[2]
    UI.drawPanel(right.x, right.y, right.w, right.h, L("ui_combat_perf"), {0.3, 0.3, 0.3})

    local str  = char.str  or 0
    local dex  = char.dex  or 0
    local int_ = char.int  or 0
    local con  = char.con  or 0
    local agi  = char.agi  or 0
    local edg  = char.edg  or 0
    local lv   = char.level or 1

    local perf = {
        {n = L("stat_atk"),  v = math.floor(str * 2 + lv * 5)},
        {n = L("stat_def"),  v = math.floor(con * 0.5)},
        {n = L("stat_crit"), v = edg .. "%"},
        {n = L("stat_evade"),v = agi .. "%"},
        {n = L("stat_mem"),  v = int_ * 2},
        {n = "MAX HP",       v = char.max_hp},
        {n = "MAX SP",       v = char.max_sp},
    }
    for i, p in ipairs(perf) do
        local sy = right.y + 30 + (i-1) * 28
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.print(p.n, right.x + 12, sy)
        love.graphics.setColor(UI.color.highlight)
        love.graphics.printf(tostring(p.v), right.x + 12, sy, right.w - 24, "right")
    end

    -- ── [섹션 3] 활성화된 펄크 ──────────────────────────────────────────────
    local perk_area_x, perk_area_y, perk_area_w, perk_area_h = UI.nextItem(140, 10)
    UI.drawPanel(perk_area_x, perk_area_y, perk_area_w, perk_area_h, L("ui_perk_deck"), UI.color.accent)

    local perk_count = 0
    if char.perks then
        love.graphics.setFont(UI.font_small)
        for _, name in pairs(char.perks) do
            local px = perk_area_x + 15 + (perk_count % 2) * 185
            local py = perk_area_y + 32 + math.floor(perk_count / 2) * 24
            love.graphics.setColor(UI.color.accent)
            love.graphics.print(">> " .. name:upper(), px, py)
            perk_count = perk_count + 1
        end
    end
    if perk_count == 0 then
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.printf(L("ui_no_perks"), perk_area_x, perk_area_y + 60, perk_area_w, "center")
    end

    -- 미분배 포인트 안내
    if (char.stat_points or 0) > 0 then
        love.graphics.setFont(UI.font_normal)
        local blink = math.abs(math.sin(love.timer.getTime() * 8))
        love.graphics.setColor(1, 0.8, 0, blink)
        love.graphics.printf(
            L("ui_uncalibrated_pts") .. ": " .. char.stat_points .. "  →  [스킬] 탭에서 투자",
            x, y + 540, 420, "center"
        )
    end

    UI.endLayout()
end

return StatusInfo
