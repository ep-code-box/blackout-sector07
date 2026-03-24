-- 상태창: 캐릭터 일러스트 및 홀로그램 프레임 렌더링 모듈 (V2)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager") -- 추가
local StatusPreview = {}

function StatusPreview.draw(char, x, y, frame_holo)
    local sprite_path = "assets/images/" .. (char.sprite or char.id .. ".png")
    local sprite = AssetManager.loadImage(sprite_path, sprite_path)
    
    if sprite then
        local sw, sh = sprite:getDimensions()
        local scale = 550 / sh
        
        -- 1. 미세한 호흡 효과 (애니메이션)
        local time = love.timer.getTime()
        local scale_mod = 1 + math.sin(time * 2) * 0.005
        
        -- 캐릭터 본체 (약간 푸른 빛을 띠게)
        love.graphics.setColor(0.9, 1, 1, 1)
        love.graphics.draw(sprite, x, y, 0, scale * scale_mod, scale * scale_mod, sw/2, sh/2)
        
        -- 2. 홀로그램 프레임 및 글리치
        if frame_holo then
            love.graphics.setColor(0, 1, 1, 0.3)
            local frame_scale = 1.15 + math.sin(time * 3) * 0.01
            love.graphics.draw(frame_holo, x, y, 0, frame_scale, frame_scale, frame_holo:getWidth()/2, frame_holo:getHeight()/2)
            
            -- 무작위 글리치 선
            if math.random() > 0.95 then
                love.graphics.setColor(0, 1, 1, 0.5)
                local gy = y - 200 + math.random(400)
                love.graphics.line(x - 150, gy, x + 150, gy)
            end
        end

        -- 3. [추가] 실시간 스캔 라인
        local scan_y = (time * 150) % 600 - 300
        love.graphics.setColor(0, 1, 0.8, 0.2)
        love.graphics.rectangle("fill", x - 180, y + scan_y, 360, 2)
        love.graphics.setColor(0, 1, 0.8, 0.05)
        love.graphics.rectangle("fill", x - 180, y + scan_y - 20, 360, 20) -- 잔상

        -- 4. [추가] 테크니컬 데이터 오버레이
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.6)
        
        -- 좌상단 태그
        love.graphics.print("BIOMETRIC_LINK: ACTIVE", x - 180, y - 260)
        -- 우상단 ID
        love.graphics.printf("ID_" .. char.id:upper(), x, y - 260, 180, "right")
        
        -- 좌하단 상태
        love.graphics.setColor(UI.color.accent)
        love.graphics.print("SYNC_RATE: " .. math.floor(95 + math.sin(time)*4) .. "%", x - 180, y + 240)
        -- 우하단 좌표 (가상)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.printf("POS: " .. string.format("%.2f, %.2f", x, y), x, y + 240, 180, "right")
    end
end

return StatusPreview