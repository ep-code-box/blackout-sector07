-- --test 인자 감지 시 테스트 러너로 분기
for _, v in ipairs(arg or {}) do
    if v == "--test" then
        require("test_runner")
        return
    end
end

-- 상태 머신 메인 엔진 (Story Integrated HD V3)
local UI = require("ui.theme")
local i18n = require("systems.i18n")
local Roster = require("systems.roster")
local SaveManager = require("systems.save_manager")
local InputManager = require("systems.input_manager")
local AssetManager = require("systems.asset_manager")
local DBManager = require("systems.db_manager")
local StatusOverlay = require("ui.status_overlay")
local StoryManager = require("systems.story_manager")
local StateHub = require("states.state_hub")
local StateExplore = require("states.state_explore")
local StateCombat = require("states.state_combat")
local StateTitle = require("states.state_title") -- 추가
local Progression   = require("systems.progression")
local EndingScreen  = require("ui.ending_screen")
local ShaderManager = require("systems.shader_manager")
local FXManager = require("systems.fx_manager")
local AudioManager = require("systems.audio_manager")
local flux = require("lib.flux")

local current_state = "title" -- hub -> title 로 변경
local states = { title = StateTitle, hub = StateHub, explore = StateExplore, combat = StateCombat }

-- 해상도 유연성을 위한 캔버스 (HD 와이드)
local main_canvas

love.window.setMode(1280, 720, {resizable=false, vsync=true})

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    main_canvas = love.graphics.newCanvas(1280, 720)
    
    DBManager.init()
    i18n.setLanguage("ko") 
    UI.load()
    StatusOverlay.load()
    ShaderManager.load()
    
    -- 세이브 로드 시도 (실패 시 타이틀에서 새 게임 유도)
    if not SaveManager.load() then
        Roster.init()
    end
    
    -- 초기 상태 로드만 수행 (BGM 겹침 방지)
    if states[current_state] and states[current_state].load then
        states[current_state].load()
    end
end

function love.update(dt)
    flux.update(dt)
    ShaderManager.update(dt)
    FXManager.update(dt)
    AudioManager.update(dt)

    if StoryManager.is_active then
        StoryManager.update(dt)
        return
    end

    if states[current_state] and states[current_state].update then
        states[current_state].update(dt)
    end
end

function love.draw()
    love.graphics.setCanvas(main_canvas)
    love.graphics.clear(0, 0, 0)
    
    if states[current_state] then states[current_state].draw() end
    if current_state ~= "combat" then StatusOverlay.draw() end
    StoryManager.draw()
    FXManager.draw()
    
    -- [추가] 엔딩 화면 오버레이 (1280x720 대응)
    if StoryManager.is_game_cleared then
        EndingScreen.draw()
    end
    
    UI.drawScanlines(1280, 720)
    love.graphics.setCanvas()

    love.graphics.setColor(1, 1, 1, 1)
    ShaderManager.apply()
    love.graphics.draw(main_canvas, 0, 0)
    ShaderManager.clear()
end

-- 전투 결과 처리
local function handleCombatResult(next_state, result, enemy_id)
    if next_state == "explore" and result == "win" then
        states.explore.clearEnemy()
        for _, q in ipairs(DBManager.getAllQuests()) do
            if not q.completed and q.required_boss_id == enemy_id then
                DBManager.setQuestCompleted(q.id, true)
                for i = 1, (q.reward_lv or 1) do Progression.levelUp(Roster.active_party) end
                break
            end
        end
        StoryManager.triggerChapter("boss_kill", enemy_id)
    elseif next_state == "hub" and result == "wipe" then
        StoryManager.triggerChapter("wipe", enemy_id)
    end
end

function love.keypressed(key)
    -- 엔딩 화면에서 ESC → 타이틀 복귀
    if StoryManager.is_game_cleared then
        if key == "escape" then
            StoryManager.is_game_cleared = false
            current_state = "title"
            if states.title.load then states.title.load() end
        end
        return
    end

    if StoryManager.is_active then
        if StoryManager.keypressed(key) then return end
    end

    local action = InputManager.getAction(key)
    if StatusOverlay.isOpen then
        if StatusOverlay.keypressed(key) then return end
    end

    if action == "status" and current_state ~= "combat" then
        StatusOverlay.isOpen = not StatusOverlay.isOpen
        return
    end

    if states[current_state] then
        local next_state, arg1, arg2 = states[current_state].keypressed(key)
        if next_state and states[next_state] then
            local prev_state = current_state
            
            -- [핵심] 상태가 실제로 바뀔 때만 .load() 호출
            if next_state ~= prev_state then
                current_state = next_state
                if states[current_state].load then
                    if current_state == "combat" then
                        states[current_state].load(arg1, arg2)
                    elseif current_state == "explore" then
                        -- Hub에서 진입할 때만 맵 초기화 (Combat에서 올 때는 유지)
                        local force_reset = (prev_state == "hub")
                        states[current_state].load(force_reset)
                    else
                        states[current_state].load()
                    end
                end
            end

            -- 특별 처리: 전투 종료 시 (승리/패배 처리)
            if prev_state == "combat" then
                handleCombatResult(next_state, arg1, arg2)
            end
        end
    end

    if action == "reload" then
        if states[current_state] and states[current_state].load then
            states[current_state].load()
        end
        StatusOverlay.load()
        print("🔄 Current State Reloaded")
    end
end

