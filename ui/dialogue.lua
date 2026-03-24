-- 시네마틱 대화 UI 모듈 (연출 강화 V4)
local UI = require("ui.theme")
local AssetManager = require("systems.asset_manager")
local FXManager = require("systems.fx_manager")
local UIDialogue = {}

local typewriter_text = ""
local display_text = ""
local timer = 0
local char_idx = 1
local is_finished = false

-- 연출용 데이터
local current_event = nil

function UIDialogue.reset(event_data)
    current_event = event_data
    typewriter_text = L(event_data.text or "")
    display_text = ""
    char_idx = 1
    timer = 0
    is_finished = false
    
    -- 연출 트리거 (Shake / Flash)
    if event_data.shake then
        FXManager.shake(event_data.shake_intensity or 10, event_data.shake_duration or 0.5)
    end
    if event_data.flash then
        FXManager.flash(event_data.flash_color or {1,1,1,1}, event_data.flash_duration or 0.3)
    end
end

function UIDialogue.update(dt)
    local cfg = UI.layout.dialogue
    if not is_finished then
        timer = timer + dt
        if timer > cfg.typewriter_speed then -- 타이핑 속도 (상수 참조)
            timer = 0
            
            -- UTF-8 호환 인덱싱
            local byte_idx = 1
            local count = 0
            while count < char_idx do
                local c = typewriter_text:byte(byte_idx)
                if not c then break end
                if c < 128 then byte_idx = byte_idx + 1
                elseif c < 224 then byte_idx = byte_idx + 2
                elseif c < 240 then byte_idx = byte_idx + 3
                else byte_idx = byte_idx + 4 end
                count = count + 1
            end
            
            display_text = typewriter_text:sub(1, byte_idx - 1)
            char_idx = char_idx + 1
            if byte_idx > #typewriter_text then is_finished = true end
        end
    end
end

function UIDialogue.draw(speaker_name, portrait_id, side)
    local cfg = UI.layout.dialogue
    local x, y, w, h = cfg.x, cfg.y, cfg.w, cfg.h
    side = side or "left"

    -- 1. 반투명 배경 패널 (와이드 레이아웃)
    UI.drawPanel(x, y, w, h, "NEURAL LINK: " .. (speaker_name or "Unknown"))
    
    -- 2. 초상화 (상수 기반 스케일링)
    local face_path = "assets/images/" .. (portrait_id or "npc_bartender") .. ".png"
    
    -- 용병/NPC 경로 스마트 해결
    local img = AssetManager.loadImage(portrait_id, face_path)
    if not img then
        local alt_path = "assets/images/npc/" .. (portrait_id or "npc_bartender") .. ".png"
        img = AssetManager.loadImage(portrait_id, alt_path)
    end

    if img then
        local sw, sh = img:getDimensions()
        local scale = cfg.portrait_scale / sh -- 초상화 스케일
        love.graphics.setColor(1, 1, 1, 1)
        
        if side == "left" then
            love.graphics.draw(img, cfg.portrait_left_x, cfg.portrait_y, 0, scale, scale, sw/2, sh/2)
        else
            love.graphics.draw(img, cfg.portrait_right_x, cfg.portrait_y, 0, -scale, scale, sw/2, sh/2)
        end
    end

    -- 3. 대사 출력 (타이핑 효과)
    love.graphics.setFont(UI.font_normal)
    love.graphics.setColor(UI.color.text_main)
    love.graphics.printf(display_text, x + cfg.padding, y + 60, w - (cfg.padding * 2), "left")
    
    -- 4. 계속 지침 (깜빡임 효과)
    if is_finished then
        local blink = math.abs(math.sin(love.timer.getTime() * cfg.continue_blink_speed))
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], blink)
        love.graphics.print(">> PRESS SPACE TO CONTINUE", x + w - 220, y + h - 30, 0, 0.7, 0.7)
    end
end

function UIDialogue.skip()
    display_text = typewriter_text
    is_finished = true
end

return UIDialogue
