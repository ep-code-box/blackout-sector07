-- 시각 특수 효과 매니저 (Flux 기반)
local FXManager = {}
local UI = require("ui.theme")
local flux = require("lib.flux")

local floating_texts = {}

-- 새로운 텍스트 팝업 생성
function FXManager.spawnText(x, y, text, color, is_crit)
    local scale = is_crit and 2.0 or 1.0
    local fx = {
        x = x + (math.random() - 0.5) * 40,
        y = y,
        text = text,
        color = color or {1, 1, 1},
        alpha = 1.0,
        scale = scale,
        alive = true
    }
    table.insert(floating_texts, fx)

    flux.to(fx, 1.5, {y = y - 60, alpha = 0}):ease("quadout"):oncomplete(function()
        fx.alive = false
    end)
end

-- 효과 업데이트 (love.update에서 호출 / flux.update는 main.lua에서 처리)
function FXManager.update(dt)
    for i = #floating_texts, 1, -1 do
        if not floating_texts[i].alive then
            table.remove(floating_texts, i)
        end
    end
end

-- 효과 렌더링 (love.draw 맨 마지막에 호출)
function FXManager.draw()
    love.graphics.setFont(UI.font_large)
    for _, fx in ipairs(floating_texts) do
        local c = fx.color
        -- 그림자
        love.graphics.setColor(0, 0, 0, fx.alpha * 0.8)
        love.graphics.print(fx.text, fx.x + 2, fx.y + 2, 0, fx.scale, fx.scale)
        -- 본체
        love.graphics.setColor(c[1], c[2], c[3], fx.alpha)
        love.graphics.print(fx.text, fx.x, fx.y, 0, fx.scale, fx.scale)
    end
end

return FXManager
