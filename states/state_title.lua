-- 타이틀 화면 상태 모듈
local StateTitle = {}
local UI = require("ui.theme")
local i18n = require("systems.i18n")
local AssetManager = require("systems.asset_manager")
local SaveManager = require("systems.save_manager")
local AudioManager = require("systems.audio_manager")
local DB = require("systems.db_manager")

local bg_img
local selected_menu = 1
local menu_items = {"menu_new_game", "menu_load_game", "menu_options", "menu_exit"}
local has_save = false
local message = ""
local msg_timer = 0

local SAVE_FILENAME = "save_data.json"

function StateTitle.load()
    bg_img = AssetManager.loadImage("ui_title_screen", "assets/images/map/ui_title_screen.png")
    
    -- 세이브 파일 존재 여부 확인 (Memory-DB 기반)
    has_save = love.filesystem.getInfo(SAVE_FILENAME) ~= nil
    
    AudioManager.playBGM("bgm_title", "assets/audio/bgm/bgm_title.wav")
end

function StateTitle.update(dt)
    if msg_timer > 0 then
        msg_timer = msg_timer - dt
        if msg_timer <= 0 then message = "" end
    end
end

function StateTitle.draw()
    love.graphics.clear(0, 0, 0)
    
    -- 1. 배경 이미지 (어둡게 처리)
    if bg_img then
        love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
        local sw, sh = bg_img:getDimensions()
        love.graphics.draw(bg_img, 0, 0, 0, 1280/sw, 720/sh)
    end

    -- 2. 타이틀 텍스트
    love.graphics.setFont(UI.font_title)
    love.graphics.setColor(UI.color.highlight)
    love.graphics.printf(L("title_game_name"), 0, 150, 1280, "center")
    
    -- 3. 메뉴 레이아웃 (중앙 배치)
    local mw, mh = 400, 200
    UI.beginLayout(640 - mw/2, 350, mw, mh, 10)
    
    for i, key in ipairs(menu_items) do
        local is_selected = (selected_menu == i)
        local display_text = L(key)
        
        -- 세이브가 없는데 로드 메뉴인 경우 흐리게 표시
        if key == "menu_load_game" and not has_save then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            UI.drawButton(640 - mw/2 + 10, 350 + (i-1)*45, mw - 20, 35, display_text, false)
        else
            UI.drawButton(640 - mw/2 + 10, 350 + (i-1)*45, mw - 20, 35, display_text, is_selected, UI.color.accent)
        end
    end
    UI.endLayout()

    -- 4. 메시지 출력 (세이브 없음 등)
    if message ~= "" then
        love.graphics.setFont(UI.font_normal)
        love.graphics.setColor(UI.color.danger)
        love.graphics.printf(message, 0, 580, 1280, "center")
    end

    -- 5. 하단 버전 및 카피라이트
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.printf("VER 1.0.3 // NEURAL LINK STABLE", 0, 680, 1280, "center")
end

function StateTitle.keypressed(key)
    if key == "up" then
        selected_menu = (selected_menu - 2) % #menu_items + 1
    elseif key == "down" then
        selected_menu = selected_menu % #menu_items + 1
    elseif key == "return" or key == "space" then
        local choice = menu_items[selected_menu]
        
        if choice == "menu_new_game" then
            -- 1. DB 초기화 (메모리 데이터 리셋)
            local StoryManager = require("systems.story_manager")
            
            DB.data.mercenaries = {}
            DB.data.save_state = {}
            DB.data.generated_quests = {}
            DB.seedMercs()
            DB.resetQuests()
            
            -- 기존 세이브 파일 삭제 (선택사항, 여기서는 덮어쓰기 방식으로 처리 가능)
            -- love.filesystem.remove(SAVE_FILENAME)

            -- 2. 시스템 상태 리셋
            local Roster = require("systems.roster")
            Roster.init()
            StoryManager.current_chapter = 1 -- 챕터 기록 초기화
            
            return "hub"
            
        elseif choice == "menu_load_game" then
            if has_save then
                if SaveManager.load() then
                    return "hub"
                end
            else
                message = L("ui_no_save_found")
                msg_timer = 2
            end
            
        elseif choice == "menu_options" then
            -- 옵션 기능 (일단 언어 전환 토글)
            local current = i18n.current_lang or "ko"
            i18n.setLanguage(current == "ko" and "en" or "ko")
            UI.load() -- 폰트 재로드 (필요시)
            
        elseif choice == "menu_exit" then
            love.event.quit()
        end
    end
    return nil
end

return StateTitle
