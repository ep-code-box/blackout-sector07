-- UI 드로잉 프리미티브 (theme.lua 서브 모듈)
local ThemePrimitives = {}

function ThemePrimitives.install(UI)

    function UI.load()
        local font_path = "assets/fonts/korean.ttf"
        if love.filesystem.getInfo(font_path) then
            UI.font_title  = love.graphics.newFont(font_path, 28)
            UI.font_large  = love.graphics.newFont(font_path, 20)
            UI.font_normal = love.graphics.newFont(font_path, 14)
            UI.font_small  = love.graphics.newFont(font_path, 11)
            love.graphics.setFont(UI.font_normal)
        end
    end

    function UI.drawPanel(x, y, w, h, title, color)
        local col = color or UI.color.highlight
        love.graphics.setColor(UI.color.bg)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(col[1], col[2], col[3], 0.05)
        for i = 0, w, 20 do love.graphics.line(x+i, y, x+i, y+h) end
        for i = 0, h, 20 do love.graphics.line(x, y+i, x+w, y+i) end
        love.graphics.setLineWidth(1)
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.rectangle("line", x, y, w, h)
        if title then
            love.graphics.setColor(col[1], col[2], col[3], 0.2)
            love.graphics.rectangle("fill", x, y, w, 25)
            love.graphics.setColor(col)
            love.graphics.rectangle("fill", x, y, 4, 25)
            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(col)
            love.graphics.print(title:upper(), x + 10, y + 6)
        end
        love.graphics.setColor(col)
        local s = 4
        love.graphics.line(x,   y,   x+s*2, y);   love.graphics.line(x,   y,   x,   y+s*2)
        love.graphics.line(x+w, y,   x+w-s*2, y); love.graphics.line(x+w, y,   x+w, y+s*2)
        love.graphics.line(x,   y+h, x+s*2, y+h); love.graphics.line(x,   y+h, x,   y+h-s*2)
        love.graphics.line(x+w, y+h, x+w-s*2,y+h);love.graphics.line(x+w, y+h, x+w, y+h-s*2)
    end

    function UI.drawGauge(x, y, w, h, ratio, label, value, color)
        local col = color or UI.color.highlight
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(col[1], col[2], col[3], 0.3)
        love.graphics.rectangle("fill", x, y, w * ratio, h)
        love.graphics.setColor(col)
        love.graphics.rectangle("fill", x, y + h*0.7, w * ratio, h*0.3)
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(label, x, y - 15)
        love.graphics.printf(value, x, y - 15, w, "right")
    end

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
        love.graphics.setFont(UI.font_normal)
        love.graphics.printf(text, x, y + h/2 - 7, w, "center")
        if is_selected then
            love.graphics.setColor(col)
            love.graphics.rectangle("fill", x,     y, 4, h)
            love.graphics.rectangle("fill", x+w-4, y, 4, h)
        end
    end

    function UI.drawScanlines(sw, sh)
        love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.setLineWidth(1)
        for i = 0, sh, 3 do love.graphics.line(0, i, sw, i) end
        love.graphics.setColor(0, 0, 0, 0.1)
        love.graphics.circle("fill", sw/2, sh/2, sw/1.5)
    end

    function UI.drawNeonBox(x, y, w, h, r, g, b)
        UI.drawPanel(x, y, w, h, nil, {r, g, b})
    end

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

    function UI.drawTechnicalBar(x, y, w, h, ratio, label, color)
        local col = color or UI.color.highlight
        love.graphics.setColor(0.05, 0.1, 0.15, 0.5)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(col[1], col[2], col[3], 0.2)
        love.graphics.rectangle("line", x, y, w, h)
        local seg_w, seg_gap = 4, 2
        local num_segs = math.floor((w * ratio) / (seg_w + seg_gap))
        love.graphics.setColor(col)
        for i = 0, num_segs - 1 do
            love.graphics.rectangle("fill", x + 2 + i * (seg_w + seg_gap), y + 2, seg_w, h - 4)
        end
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.print(label, x, y - 14)
    end

    function UI.drawNoiseLine(x, y, w, color)
        local col = color or UI.color.highlight
        local time = love.timer.getTime()
        love.graphics.setLineWidth(1)
        love.graphics.setColor(col[1], col[2], col[3], 0.3)
        love.graphics.line(x, y, x + w, y)
        love.graphics.setFont(UI.font_small)
        for i = 0, 10 do
            local px = x + (math.sin(time * 10 + i) * 0.5 + 0.5) * w
            local hex = string.format("%X", math.random(15))
            love.graphics.setColor(col[1], col[2], col[3], 0.6)
            love.graphics.print(hex, px, y - 10)
        end
    end

end

return ThemePrimitives
