-- 시각 특수 효과 매니저 (FX & 연출 강화 V2)
local FXManager = {}
local UI = require("ui.theme")
local flux = require("lib.flux")

local floating_texts = {}

-- 1. 화면 흔들림 (Screen Shake)
local shake_amount = 0
local shake_duration = 0

function FXManager.shake(amount, duration)
    shake_amount = amount or 10
    shake_duration = duration or 0.5
end

function FXManager.getShakeOffset()
    if shake_duration > 0 then
        local dx = (math.random() - 0.5) * shake_amount
        local dy = (math.random() - 0.5) * shake_amount
        return dx, dy
    end
    return 0, 0
end

-- 2. 화면 플래시 (Screen Flash)
local flash_color = {1, 1, 1, 0}
local flash_timer = 0

function FXManager.flash(color, duration)
    flash_color = {color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1}
    flash_timer = duration or 0.3
    flux.to(flash_color, flash_timer, { [4] = 0 }):ease("quadout")
end

-- 3. 플로팅 텍스트 (데미지 등)
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

function FXManager.update(dt)
    -- Shake 업데이트
    if shake_duration > 0 then
        shake_duration = shake_duration - dt
    end

    -- 텍스트 제거 관리
    for i = #floating_texts, 1, -1 do
        if not floating_texts[i].alive then
            table.remove(floating_texts, i)
        end
    end
end

function FXManager.draw()
    -- 1. 플래시 효과 (화면 전체 덮기)
    if flash_color[4] > 0 then
        love.graphics.setColor(flash_color[1], flash_color[2], flash_color[3], flash_color[4])
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end

    -- 2. 플로팅 텍스트 렌더링
    love.graphics.setFont(UI.font_large)
    for _, fx in ipairs(floating_texts) do
        local c = fx.color
        love.graphics.setColor(0, 0, 0, fx.alpha * 0.8)
        love.graphics.print(fx.text, fx.x + 2, fx.y + 2, 0, fx.scale, fx.scale)
        love.graphics.setColor(c[1], c[2], c[3], fx.alpha)
        love.graphics.print(fx.text, fx.x, fx.y, 0, fx.scale, fx.scale)
    end
end

return FXManager
