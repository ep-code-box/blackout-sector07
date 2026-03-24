-- 스토리 및 이벤트 매니저 (Decision System Integrated)
local UIDialogue = require("ui.dialogue")
local StoryManager = {}

-- [추가] 런타임 스토리 상태 (data_story.lua 대체)
StoryManager.current_chapter = 1
StoryManager.world_flags = {}
StoryManager.endings = {
    hope = {
        title = "ending_hope_title",
        text  = "ending_hope_text"
    },
    betrayal = {
        title = "ending_betrayal_title",
        text  = "ending_betrayal_text"
    }
}

StoryManager.current_queue = {} 
StoryManager.is_active = false
StoryManager.callback = nil
StoryManager.current_talk = nil
StoryManager.choices = nil -- [추가] 현재 활성화된 선택지 목록
StoryManager.selected_choice = 1
StoryManager.is_game_cleared = false -- [추가] 엔딩 달성 여부

function StoryManager.start(dialogue_list, callback)
    StoryManager.current_queue = {}
    for _, d in ipairs(dialogue_list) do table.insert(StoryManager.current_queue, d) end
    StoryManager.is_active = true
    StoryManager.callback = callback
    StoryManager.next()
end

function StoryManager.triggerChapter(trigger_type, trigger_id)
    local DB   = require("systems.db_manager")
    local json = require("lib.json")

    local chapter = DB.getChapterByTrigger(trigger_type, trigger_id or "")
    if not chapter then return false end

    -- 이미 진행한 챕터면 스킵 (chapter_order 기반)
    if chapter.chapter_order < StoryManager.current_chapter then return false end

    -- DB에서 이벤트 로드 → story_manager 형식으로 변환
    local raw_events = DB.getChapterEvents(chapter.id)
    local events = {}
    for _, ev in ipairs(raw_events) do
        local entry = {
            name     = ev.speaker,
            speaker  = ev.speaker,
            portrait = ev.portrait,
            side     = ev.side,
            text     = ev.text,
            -- 추가 연출 데이터 (DB 스키마 확장이 필요할 수 있으나, 일단 text에 메타데이터가 있거나 seed에서 온다고 가정)
            shake    = ev.shake == 1,
            flash    = ev.flash == 1,
            shake_intensity = ev.shake_intensity,
            flash_color = ev.flash_color_json and json.decode(ev.flash_color_json) or {1,1,1,1}
        }
        if ev.is_choice_node == 1 then
            local raw_choices = DB.getChoicesForEvent(ev.id)
            entry.choices = {}
            for _, c in ipairs(raw_choices) do
                table.insert(entry.choices, {
                    text    = c.text,
                    actions = c.actions or {},
                })
            end
        end
        table.insert(events, entry)
    end

    StoryManager.start(events)
    StoryManager.current_chapter = chapter.chapter_order + 1
    return true
end

function StoryManager.next()
    if StoryManager.choices then return end -- 선택 중에는 넘기기 불가

    if #StoryManager.current_queue > 0 then
        local next_talk = table.remove(StoryManager.current_queue, 1)
        
        -- 만약 다음이 선택지라면?
        if next_talk.choices and #next_talk.choices > 0 then
            StoryManager.choices = next_talk.choices
            StoryManager.selected_choice = 1
            StoryManager.current_talk = next_talk
        else
            UIDialogue.reset(next_talk) -- 텍스트 대신 전체 데이터 전달
            StoryManager.current_talk = next_talk
        end
    else
        StoryManager.is_active = false
        if StoryManager.callback then StoryManager.callback() end
    end
end

function StoryManager.update(dt)
    if StoryManager.is_active and not StoryManager.choices then
        UIDialogue.update(dt)
    end
end

function StoryManager.draw()
    if not StoryManager.is_active or not StoryManager.current_talk then return end
    
    -- 1. 기본 대화창
    local speaker_key = StoryManager.current_talk.name or StoryManager.current_talk.speaker
    UIDialogue.draw(
        L(speaker_key) or speaker_key,
        StoryManager.current_talk.portrait,
        StoryManager.current_talk.side
    )
    
    -- 2. 선택지 렌더링 (상수 참조 적용)
    if StoryManager.choices then
        local UI = require("ui.theme")
        local cfg = UI.layout.choice
        for i, choice in ipairs(StoryManager.choices) do
            UI.drawButton(
                cfg.x, 
                cfg.y + (i-1) * cfg.gap, 
                cfg.w, 
                cfg.h, 
                L(choice.text), 
                StoryManager.selected_choice == i, 
                UI.color.accent
            )
        end
    end
end

function StoryManager.keypressed(key)
    if not StoryManager.is_active then return false end
    
    -- 선택지 모드일 때
    if StoryManager.choices then
        if key == "up" then StoryManager.selected_choice = (StoryManager.selected_choice - 2) % #StoryManager.choices + 1
        elseif key == "down" then StoryManager.selected_choice = StoryManager.selected_choice % #StoryManager.choices + 1
        elseif key == "return" or key == "space" then
            local choice = StoryManager.choices[StoryManager.selected_choice]
            StoryManager.choices = nil
            if not choice then StoryManager.next(); return true end

            -- [추가] 선택지에 따른 액션 실행
            if choice.actions and #choice.actions > 0 then
                local Inventory = require("systems.inventory")
                
                for _, action in ipairs(choice.actions) do
                    if action.type == "set_flag" then
                        StoryManager.world_flags[action.key] = action.val
                        print("🚩 World Flag Set: " .. action.key .. " = " .. tostring(action.val))
                    elseif action.type == "give_credits" then
                        Inventory.credits = Inventory.credits + action.val
                        print("💰 Earned Credits: " .. action.val)
                    elseif action.type == "unlock_merc" then
                        local Roster = require("systems.roster")
                        Roster.unlockMerc(action.id)
                    elseif action.type == "end_game" then
                        StoryManager.is_game_cleared = true
                        print("🏁 ENDING REACHED")
                    elseif action.type == "dialogue" then
                        -- 즉시 추가 대사 출력 등을 원할 경우 여기에 구현
                    end
                end
            end
            
            if choice.callback then choice.callback() end
            StoryManager.next()
        end
        return true
    end
    
    if key == "space" or key == "return" then
        StoryManager.next()
        return true
    end
    return true
end

return StoryManager
