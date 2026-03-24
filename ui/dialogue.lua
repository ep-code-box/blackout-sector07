-- 시네마틱 대화 UI 모듈 (리팩토링 V3)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager")
local UIDialogue = {}

local typewriter_text = ""
local display_text = ""
local timer = 0
local char_idx = 1
local is_finished = false

function UIDialogue.reset(text)
    typewriter_text = text
    display_text = ""
    char_idx = 1
    timer = 0
    is_finished = false
end

function UIDialogue.update(dt)
    if not is_finished then
        timer = timer + dt
        if timer > 0.03 then -- 타이핑 속도
            timer = 0
            -- UTF-8 호환을 위한 처리
            local byte_idx = 1
            for i = 1, char_idx do
                local c = typewriter_text:byte(byte_idx)
                if not c then break end
                if c >= 0 and c <= 127 then byte_idx = byte_idx + 1
                elseif c >= 192 and c <= 223 then byte_idx = byte_idx + 2
                elseif c >= 224 and c <= 239 then byte_idx = byte_idx + 3
                elseif c >= 240 and c <= 247 then byte_idx = byte_idx + 4
                end
            end
            display_text = typewriter_text:sub(1, byte_idx - 1)
            char_idx = char_idx + 1
            if byte_idx > #typewriter_text then is_finished = true end
        end
    end
end

function UIDialogue.draw(speaker_name, portrait_id, side)
    local x, y, w, h = 50, 420, 700, 150
    side = side or "left" -- left or right

    -- 1. 반투명 배경 패널
    UI.drawPanel(x, y, w, h, "Comms Log: " .. (speaker_name or "Unknown"))
    
    -- 2. 초상화 경로 해결 (V2)
    local face_path = "assets/images/" .. (portrait_id or "npc_bartender") .. ".png"
    
    -- 용병 ID일 경우 전용 페이스 경로 탐색
    if portrait_id and portrait_id:match("^merc_") then
        local Roster = require("systems.roster")
        for _, m in ipairs(Roster.pool) do
            if m.id == portrait_id then
                face_path = UI.getFacePath(m.sprite, m.id)
                break
            end
        end
    end
    
    -- 에셋 매니저를 통한 안전한 캐싱 로드
    local img = AssetManager.loadImage(face_path, face_path)
    if not img then
        local alt_path = "assets/images/" .. (portrait_id or "npc_bartender") .. "_face.png"
        img = AssetManager.loadImage(alt_path, alt_path)
    end

    if img then
        local sw, sh = img:getDimensions()
        local scale = 180 / sh
        love.graphics.setColor(1, 1, 1, 1)
        
        if side == "left" then
            love.graphics.draw(img, 100, 400, 0, scale, scale, sw/2, sh/2)
        else
            love.graphics.draw(img, 700, 400, 0, -scale, scale, sw/2, sh/2)
        end
    end

    -- 3. 대사 출력
    love.graphics.setFont(UI.font_normal)
    love.graphics.setColor(UI.color.text_main)
    love.graphics.printf(display_text, x + 120, y + 50, w - 150, "left")
    
    -- 4. 계속하려면 클릭/스페이스 안내
    if is_finished then
        local blink = math.abs(math.sin(love.timer.getTime() * 5))
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], blink)
        love.graphics.print("▼ PRESS SPACE", x + w - 120, y + h - 30, 0, 0.8, 0.8)
    end
end

function UIDialogue.skip()
    display_text = typewriter_text
    is_finished = true
end

return UIDialogue
