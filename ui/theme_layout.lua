-- UI 레이아웃 엔진 + 위젯 + 스크롤 + 클립 (theme.lua 서브 모듈)
local ThemeLayout = {}

function ThemeLayout.install(UI)

    -- ── 레이아웃 엔진 (Box Model) ───────────────────────────────────────────

    UI.layout_stack = {}

    function UI.beginLayout(x, y, w, h, padding)
        local ctx = {
            x = x, y = y, w = w, h = h,
            p = padding or 10,
            cur_y   = y + (padding or 10),
            avail_w = w - (padding or 10) * 2
        }
        table.insert(UI.layout_stack, ctx)
        return ctx
    end

    function UI.nextItem(h, margin)
        local ctx = UI.layout_stack[#UI.layout_stack]
        if not ctx then return 0, 0, 0, 0 end
        local rx, ry = ctx.x + ctx.p, ctx.cur_y
        ctx.cur_y = ctx.cur_y + h + (margin or 5)
        return rx, ry, ctx.avail_w, h
    end

    function UI.splitRow(h, cols, margin)
        local ctx = UI.layout_stack[#UI.layout_stack]
        if not ctx then return {} end
        local m     = margin or 5
        local col_w = (ctx.avail_w - (m * (cols - 1))) / cols
        local results = {}
        for i = 1, cols do
            table.insert(results, {
                x = ctx.x + ctx.p + (i-1) * (col_w + m),
                y = ctx.cur_y, w = col_w, h = h
            })
        end
        ctx.cur_y = ctx.cur_y + h + m
        return results
    end

    function UI.endLayout()
        table.remove(UI.layout_stack)
    end

    -- ── 스크롤 유틸 ────────────────────────────────────────────────────────

    function UI.getScrollWindow(list_size, cursor, max_visible)
        local start_idx = math.max(1, cursor - math.floor(max_visible / 2))
        if start_idx + max_visible - 1 > list_size then
            start_idx = math.max(1, list_size - max_visible + 1)
        end
        local end_idx = math.min(list_size, start_idx + max_visible - 1)
        local scroll_ratio = (start_idx - 1) / math.max(1, list_size - max_visible)
        return start_idx, end_idx, scroll_ratio
    end

    -- ── 클리핑 시스템 ──────────────────────────────────────────────────────

    local clip_stack = {}

    function UI.pushClip(x, y, w, h)
        local cx, cy, cw, ch = love.graphics.getScissor()
        table.insert(clip_stack, {cx, cy, cw, ch})
        if cx then
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

    -- ── 통합 스크롤 리스트 렌더러 ──────────────────────────────────────────

    function UI.drawScrollingList(panel_cfg, list_cfg, draw_item_func)
        UI.drawPanel(panel_cfg.x, panel_cfg.y, panel_cfg.w, panel_cfg.h, panel_cfg.title, panel_cfg.color)
        local start_idx, end_idx, scroll_ratio = UI.getScrollWindow(list_cfg.size, list_cfg.cursor, list_cfg.max_visible)
        local content_y = panel_cfg.y + 25
        local content_h = panel_cfg.h - 35
        UI.pushClip(panel_cfg.x, content_y, panel_cfg.w, content_h)
        for i = start_idx, end_idx do
            local display_i = i - start_idx + 1
            local item_y = content_y + 10 + (display_i - 1) * (list_cfg.item_h or 30)
            draw_item_func(i, panel_cfg.x + 10, item_y, panel_cfg.w - 30, list_cfg.item_h or 30, i == list_cfg.cursor)
        end
        UI.popClip()
        UI.drawScrollBar(panel_cfg.x + panel_cfg.w - 10, content_y + 10, 4, content_h - 20,
            list_cfg.size, list_cfg.max_visible, scroll_ratio, panel_cfg.color)
    end

    -- ── 위젯 시스템 ────────────────────────────────────────────────────────

    UI.widgets = {}

    function UI.widgets.statBar(label, value, ratio, color)
        local x, y, w, h = UI.nextItem(35, 5)
        UI.drawTechnicalBar(x, y + 15, w, 12, ratio, label, color)
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(tostring(value), x, y, w, "right")
    end

    function UI.widgets.charCard(char, is_selected)
        local x, y, w, h = UI.nextItem(60, 10)
        UI.drawButton(x, y, w, h, "", is_selected)
        local face_path = UI.getFacePath(char.sprite, char.id)
        local face_img = require("systems.asset_manager").loadImage(char.id.."_face", face_path)
        if face_img then
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(face_img, x + 5, y + 5, 0, 50/face_img:getWidth(), 50/face_img:getHeight())
        end
        love.graphics.setFont(UI.font_normal)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(char.name, x + 65, y + 10)
        UI.drawGauge(x + 65, y + 40, w - 80, 6, char.hp/char.max_hp, "HP", char.hp, UI.color.danger)
    end

end

return ThemeLayout
