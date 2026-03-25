-- 세이브/로드 매니저 (Disk-based Persistence V1)
local SaveManager = {}
local DB = require("systems.db_manager")
local Roster = require("systems.roster")
local Inventory = require("systems.inventory")
local StoryManager = require("systems.story_manager")
local json = require("lib.json")

local SAVE_FILENAME = "save_data.json"

function SaveManager.save()
    -- 1. 현재 파티 구성 및 게임 메인 상태 업데이트
    local active_ids = {}
    for _, merc in ipairs(Roster.active_party) do table.insert(active_ids, merc.id) end
    
    local main_state = {
        current_chapter = StoryManager.current_chapter,
        world_flags = StoryManager.world_flags,
        credits = Inventory.credits,
        active_ids = active_ids
    }
    
    -- DB memory state에 저장
    DB.data.save_state["main_state"] = json.encode(main_state)

    -- 2. 전체 DB 데이터를 파일로 저장 (Persistence)
    local ok, err = pcall(function()
        local full_data = json.encode(DB.data)
        love.filesystem.write(SAVE_FILENAME, full_data)
    end)

    if ok then
        print("💾 Game State Saved to disk: " .. SAVE_FILENAME)
        return true, "저장 완료."
    else
        print("❌ Save Failed: " .. tostring(err))
        return false, "저장 실패."
    end
end

function SaveManager.load()
    -- 1. 파일에서 데이터 읽기
    if not love.filesystem.getInfo(SAVE_FILENAME) then
        print("⚠️ No Save File found on disk.")
        -- 파일이 없으면 초기 상태로 시작하도록 Roster.init 호출
        Roster.init()
        return false
    end

    local ok, err = pcall(function()
        local content = love.filesystem.read(SAVE_FILENAME)
        local loaded_data = json.decode(content)
        if loaded_data then
            -- DB.data 업데이트 (메모리에 로드)
            for k, v in pairs(loaded_data) do
                DB.data[k] = v
            end
        end
    end)

    if not ok then
        print("❌ Load Failed: " .. tostring(err))
        Roster.init()
        return false
    end

    -- 2. 용병 풀 초기화 (DB 메모리에서 해금된 용병들 로드)
    Roster.pool = {}
    Roster.active_party = {}
    for _, m in ipairs(DB.getAllMercs()) do
        m.skill_levels = {}
        table.insert(Roster.pool, m)
    end
    
    -- 3. 게임 상태 복구
    local main_state_json = DB.data.save_state["main_state"]
    if main_state_json then
        local state = json.decode(main_state_json)
        
        StoryManager.current_chapter = state.current_chapter or 1
        StoryManager.world_flags = state.world_flags or {}
        Inventory.credits = state.credits or 500
        
        -- 현재 출격 파티 구성 복구
        Roster.active_party = {}
        local added_ids = {}
        for _, id in ipairs(state.active_ids or {}) do
            if not added_ids[id] then
                for _, merc in ipairs(Roster.pool) do
                    if merc.id == id then 
                        table.insert(Roster.active_party, merc) 
                        added_ids[id] = true
                        break 
                    end
                end
            end
        end
        
        -- 만약 로드했는데 파티가 비어있다면 초기 멤버(루나) 강제 추가
        if #Roster.active_party == 0 and #Roster.pool > 0 then
            table.insert(Roster.active_party, Roster.pool[1])
        end

        print("📂 Game Loaded from disk successfully.")
        return true
    end
    
    return false
end

return SaveManager
