-- 사이버펑크 하이테크 UI 테마 (Premium Edition V3)
local UI = {}

-- 화면 레이아웃 상수 (HD 와이드 업그레이드)
UI.screen_w = 1280
UI.screen_h = 720

function UI.updateScreenSize(w, h)
    UI.screen_w = w
    UI.screen_h = h
end

-- 상대 좌표/크기 계산 (0.0 ~ 1.0)
function UI.relX(ratio) return UI.screen_w * ratio end
function UI.relY(ratio) return UI.screen_h * ratio end
function UI.relW(ratio) return UI.screen_w * ratio end
function UI.relH(ratio) return UI.screen_h * ratio end

-- 컬러 팔레트 (Cyber-Neutral Palette)
UI.color = {
    bg = {0.02, 0.04, 0.08, 0.95},
    panel = {0.05, 0.1, 0.15, 0.8},
    highlight = {0, 1, 0.8},
    accent = {1, 0.8, 0},
    danger = {1, 0.2, 0.2},
    text_main = {0.9, 1, 1},
    text_dim = {0.5, 0.6, 0.7}
}

-- [고급] 윈도우 드로잉 (중앙 정렬 및 비율 기반)
function UI.drawWindow(rx, ry, rw, rh, title, color)
    local x = UI.relX(rx) - UI.relW(rw)/2
    local y = UI.relY(ry) - UI.relH(rh)/2
    local w = UI.relW(rw)
    local h = UI.relH(rh)
    
    UI.drawPanel(x, y, w, h, title, color)
    return x, y, w, h -- 실제 좌표 반환하여 내부 요소 배치에 활용
end

-- [유틸리티] 스프라이트 파일명으로부터 페이스 이미지 경로 추출
function UI.getFacePath(sprite_name, char_id)
    local AssetManager = require("systems.asset_manager") -- 추가
    
    if not sprite_name or type(sprite_name) ~= "string" then
        return AssetManager.resolvePath("assets/images/" .. (char_id or "unknown") .. "_face.png")
    end
    
    -- 1순위: 스프라이트명_face.png 탐색 (예: merc_01_luna_face.png)
    local base = sprite_name:gsub("%.png$", "")
    local preferred_face = "assets/images/" .. base .. "_face.png"
    local resolved = AssetManager.resolvePath(preferred_face)
    
    -- 만약 해결된 경로가 존재하면 반환
    if love.filesystem.getInfo(resolved) then
        return resolved
    end
    
    -- 2순위: ID_face.png (예: merc_01_face.png)
    return AssetManager.resolvePath("assets/images/" .. (char_id or "unknown") .. "_face.png")
end

-- [추가] 고급 레이아웃 엔진 (Box Model)
UI.layout_stack = {}

-- 레이아웃 시작 (박스 영역 정의)
function UI.beginLayout(x, y, w, h, padding)
    local ctx = {
        x = x, y = y, w = w, h = h,
        p = padding or 10,
        cur_y = y + (padding or 10),
        avail_w = w - (padding or 10) * 2
    }
    table.insert(UI.layout_stack, ctx)
    return ctx
end

-- 다음 요소의 좌표와 크기를 가져오고 자동으로 y축 갱신
function UI.nextItem(h, margin)
    local ctx = UI.layout_stack[#UI.layout_stack]
    if not ctx then return 0, 0, 0, 0 end
    
    local rx, ry = ctx.x + ctx.p, ctx.cur_y
    local rw = ctx.avail_w
    local rh = h
    
    ctx.cur_y = ctx.cur_y + rh + (margin or 5)
    return rx, ry, rw, rh
end

-- 영역을 N등분하여 현재 행의 좌표들을 반환 (그리드)
function UI.splitRow(h, cols, margin)
    local ctx = UI.layout_stack[#UI.layout_stack]
    if not ctx then return {} end
    
    local m = margin or 5
    local col_w = (ctx.avail_w - (m * (cols - 1))) / cols
    local results = {}
    
    for i = 1, cols do
        table.insert(results, {
            x = ctx.x + ctx.p + (i-1) * (col_w + m),
            y = ctx.cur_y,
            w = col_w,
            h = h
        })
    end
    
    ctx.cur_y = ctx.cur_y + h + m
    return results
end

function UI.endLayout()
    table.remove(UI.layout_stack)
end

-- [추가] 위젯 시스템 (컴포넌트화)
UI.widgets = {}

-- 재사용 가능한 스탯 위젯
function UI.widgets.statBar(label, value, ratio, color)
    local x, y, w, h = UI.nextItem(35, 5)
    UI.drawTechnicalBar(x, y + 15, w, 12, ratio, label, color)
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(value), x, y, w, "right")
end

-- 캐릭터 요약 카드 위젯 (파티 리스트 등에서 재사용)
function UI.widgets.charCard(char, is_selected)
    local x, y, w, h = UI.nextItem(60, 10)
    UI.drawButton(x, y, w, h, "", is_selected)
    
    -- 얼굴 아이콘
    local face_path = UI.getFacePath(char.sprite, char.id)
    local face_img = require("systems.asset_manager").loadImage(char.id.."_face", face_path)
    if face_img then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(face_img, x + 5, y + 5, 0, 50/face_img:getWidth(), 50/face_img:getHeight())
    end
    
    love.graphics.setFont(UI.font_normal)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(char.name, x + 65, y + 10)
    
    -- HP 바 요약
    UI.drawGauge(x + 65, y + 40, w - 80, 6, char.hp/char.max_hp, "HP", char.hp, UI.color.danger)
end

function UI.load()
    local font_path = "assets/fonts/korean.ttf"
    if love.filesystem.getInfo(font_path) then
        UI.font_title = love.graphics.newFont(font_path, 28)
        UI.font_large = love.graphics.newFont(font_path, 20)
        UI.font_normal = love.graphics.newFont(font_path, 14)
        UI.font_small = love.graphics.newFont(font_path, 11)
        love.graphics.setFont(UI.font_normal)
    end
end

-- 고급 하이테크 판넬 (헤더와 나사 장식 포함)
function UI.drawPanel(x, y, w, h, title, color)
    local col = color or UI.color.highlight
    
    -- 1. 본체 배경
    love.graphics.setColor(UI.color.bg)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- 2. 미세한 그리드 패턴 (내부)
    love.graphics.setColor(col[1], col[2], col[3], 0.05)
    for i = 0, w, 20 do love.graphics.line(x+i, y, x+i, y+h) end
    for i = 0, h, 20 do love.graphics.line(x, y+i, x+w, y+i) end

    -- 3. 테두리 및 모서리 절단 효과
    love.graphics.setLineWidth(1)
    love.graphics.setColor(col[1], col[2], col[3], 0.4)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- 4. 헤더 바 (Title Bar)
    if title then
        love.graphics.setColor(col[1], col[2], col[3], 0.2)
        love.graphics.rectangle("fill", x, y, w, 25)
        love.graphics.setColor(col)
        love.graphics.rectangle("fill", x, y, 4, 25) -- 좌측 강조 선
        
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(col)
        love.graphics.print(title:upper(), x + 10, y + 6)
    end

    -- 5. 장식용 '나사' 및 코너 브라켓
    love.graphics.setColor(col)
    local s = 4
    -- 좌상
    love.graphics.line(x, y, x+s*2, y)
    love.graphics.line(x, y, x, y+s*2)
    -- 우상
    love.graphics.line(x+w, y, x+w-s*2, y)
    love.graphics.line(x+w, y, x+w, y+s*2)
    -- 좌하
    love.graphics.line(x, y+h, x+s*2, y+h)
    love.graphics.line(x, y+h, x, y+h-s*2)
    -- 우하
    love.graphics.line(x+w, y+h, x+w-s*2, y+h)
    love.graphics.line(x+w, y+h, x+w, y+h-s*2)
end

-- 게이지 바 (HP/SP 전용)
function UI.drawGauge(x, y, w, h, ratio, label, value, color)
    local col = color or UI.color.highlight
    
    -- 배경
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    
    -- 채우기 (그라데이션 느낌을 위해 두 번 그림)
    love.graphics.setColor(col[1], col[2], col[3], 0.3)
    love.graphics.rectangle("fill", x, y, w * ratio, h)
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", x, y + h*0.7, w * ratio, h*0.3) -- 하단 강조
    
    -- 텍스트 레이아웃
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(label, x, y - 15)
    love.graphics.printf(value, x, y - 15, w, "right")
end

-- 버튼 (선택 시 발광)
function UI.drawButton(x, y, w, h, text, is_selected, color)
    local col = color or UI.color.highlight
    if is_selected then
        love.graphics.setColor(col[1], col[2], col[3], 0.2)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(UI.color.text_dim)
    end
    
    love.graphics.rectangle("line", x, y, w, h)
    
    -- 텍스트 폰트 설정 (일관성 유지)
    love.graphics.setFont(UI.font_normal)
    love.graphics.printf(text, x, y + h/2 - 7, w, "center")
    
    if is_selected then
        love.graphics.setColor(col)
        love.graphics.rectangle("fill", x, y, 4, h)
        love.graphics.rectangle("fill", x+w-4, y, 4, h)
    end
end

function UI.drawScanlines(sw, sh)
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.setLineWidth(1)
    for i = 0, sh, 3 do love.graphics.line(0, i, sw, i) end
    -- 빈티지 비넷 효과
    love.graphics.setColor(0, 0, 0, 0.1)
    love.graphics.circle("fill", sw/2, sh/2, sw/1.5)
end

-- 하위 호환성을 위한 drawNeonBox (내부적으로 drawPanel 호출)
function UI.drawNeonBox(x, y, w, h, r, g, b)
    UI.drawPanel(x, y, w, h, nil, {r, g, b})
end

-- [복구] 공통 스크롤 계산 유틸리티
function UI.getScrollWindow(list_size, cursor, max_visible)
    local start_idx = math.max(1, cursor - math.floor(max_visible / 2))
    if start_idx + max_visible - 1 > list_size then
        start_idx = math.max(1, list_size - max_visible + 1)
    end
    local end_idx = math.min(list_size, start_idx + max_visible - 1)
    local scroll_ratio = (start_idx - 1) / math.max(1, list_size - max_visible)
    return start_idx, end_idx, scroll_ratio
end

-- [복구] 공통 스크롤 바 렌더링
function UI.drawScrollBar(x, y, w, h, list_size, max_visible, scroll_ratio, color)
    if list_size <= max_visible then return end
    local col = color or UI.color.highlight
    local bar_h = h * (max_visible / list_size)
    local bar_y = y + (h - bar_h) * scroll_ratio
    love.graphics.setColor(col[1], col[2], col[3], 0.3)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(col)
    love.graphics.rectangle("fill", x, bar_y, w, bar_h)
end

-- [추가] 테크니컬 스탯 바 (2단계 레이어)
function UI.drawTechnicalBar(x, y, w, h, ratio, label, color)
    local col = color or UI.color.highlight
    
    -- 배경 (슬롯 느낌)
    love.graphics.setColor(0.05, 0.1, 0.15, 0.5)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(col[1], col[2], col[3], 0.2)
    love.graphics.rectangle("line", x, y, w, h)
    
    -- 활성 바 (세그먼트 효과)
    local seg_w = 4
    local seg_gap = 2
    local num_segs = math.floor((w * ratio) / (seg_w + seg_gap))
    
    love.graphics.setColor(col)
    for i = 0, num_segs - 1 do
        love.graphics.rectangle("fill", x + 2 + i * (seg_w + seg_gap), y + 2, seg_w, h - 4)
    end
    
    -- 레이블 (바 우측 상단)
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.print(label, x, y - 14)
end

-- [추가] 클리핑(Scissor) 시스템
local clip_stack = {}

function UI.pushClip(x, y, w, h)
    local cx, cy, cw, ch = love.graphics.getScissor()
    table.insert(clip_stack, {cx, cy, cw, ch})
    
    if cx then
        -- 기존 클립 영역과 교차하는 영역 계산
        local nx = math.max(x, cx)
        local ny = math.max(y, cy)
        local nw = math.min(x + w, cx + cw) - nx
        local nh = math.min(y + h, cy + ch) - ny
        love.graphics.setScissor(nx, ny, math.max(0, nw), math.max(0, nh))
    else
        love.graphics.setScissor(x, y, w, h)
    end
end

function UI.popClip()
    local last = table.remove(clip_stack)
    if last and last[1] then
        love.graphics.setScissor(unpack(last))
    else
        love.graphics.setScissor()
    end
end

-- [추가] 통합 리스트 렌더링 엔진
-- panel_cfg: {x, y, w, h, title, color}
-- list_cfg: {size, cursor, max_visible, item_h}
-- draw_item_func: function(idx, x, y, w, h, is_selected)
function UI.drawScrollingList(panel_cfg, list_cfg, draw_item_func)
    -- 1. 패널 배경 그리기
    UI.drawPanel(panel_cfg.x, panel_cfg.y, panel_cfg.w, panel_cfg.h, panel_cfg.title, panel_cfg.color)
    
    -- 2. 스크롤 윈도우 계산
    local start_idx, end_idx, scroll_ratio = UI.getScrollWindow(list_cfg.size, list_cfg.cursor, list_cfg.max_visible)
    
    -- 3. 클리핑 영역 설정 (헤더 25px 제외)
    local content_y = panel_cfg.y + 25
    local content_h = panel_cfg.h - 35
    UI.pushClip(panel_cfg.x, content_y, panel_cfg.w, content_h)
    
    -- 4. 아이템 렌더링
    for i = start_idx, end_idx do
        local display_i = i - start_idx + 1
        local item_y = content_y + 10 + (display_i - 1) * (list_cfg.item_h or 30)
        draw_item_func(i, panel_cfg.x + 10, item_y, panel_cfg.w - 30, list_cfg.item_h or 30, i == list_cfg.cursor)
    end
    
    UI.popClip()
    
    -- 5. 스크롤 바 렌더링
    UI.drawScrollBar(panel_cfg.x + panel_cfg.w - 10, content_y + 10, 4, content_h - 20, list_cfg.size, list_cfg.max_visible, scroll_ratio, panel_cfg.color)
end

-- [추가] 테크니컬 노이즈 선 (무작위 비트 데이터 스트림 느낌)
function UI.drawNoiseLine(x, y, w, color)
    local col = color or UI.color.highlight
    local time = love.timer.getTime()
    
    love.graphics.setLineWidth(1)
    love.graphics.setColor(col[1], col[2], col[3], 0.3)
    love.graphics.line(x, y, x + w, y)
    
    -- 무작위 데이터 비트들
    love.graphics.setFont(UI.font_small)
    for i = 0, 10 do
        local px = x + (math.sin(time * 10 + i) * 0.5 + 0.5) * w
        local hex = string.format("%X", math.random(15))
        love.graphics.setColor(col[1], col[2], col[3], 0.6)
        love.graphics.print(hex, px, y - 10)
    end
end

return UI