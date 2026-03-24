-- 세이브/로드 매니저 (SQLite DB Integrated)
local SaveManager = {}
local DB = require("systems.db_manager")
local Roster = require("systems.roster")
local Inventory = require("systems.inventory")
local StoryManager = require("systems.story_manager")
local json = require("lib.json")

local function esc(s) return tostring(s or ""):gsub("'", "''") end

function SaveManager.save()
    -- 1. 개별 용병 데이터는 이미 각 시점(레벨업, 스탯투자 등)에 Roster.saveMercToDB를 통해 저장됨
    -- 2. 전체 게임 상태(챕터, 플래그, 크레딧, 현재 파티 구성)를 DB에 직렬화하여 저장
    local active_ids = {}
    for _, merc in ipairs(Roster.active_party) do table.insert(active_ids, merc.id) end
    
    local state = {
        current_chapter = StoryManager.current_chapter,
        world_flags = StoryManager.world_flags,
        credits = Inventory.credits,
        active_ids = active_ids
    }
    
    local encoded = esc(json.encode(state))
    DB.query(string.format(
        "INSERT OR REPLACE INTO save_state (key, value) VALUES ('main_state', '%s')",
        encoded
    ))

    print("💾 Game State Saved to DB.")
    return true, "저장 완료."
end

function SaveManager.load()
    -- 1. 용병 풀 초기화 (DB에서 해금된 용병들 로드)
    Roster.init()
    
    -- 2. 게임 상태 복구
    local res = DB.query("SELECT value FROM save_state WHERE key='main_state' LIMIT 1")
    if res and #res > 0 then
        local state = json.decode(res[1].value)
        
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
        
        -- 만약 로드했는데 파티가 비어있다면 루나라도 강제 추가
        if #Roster.active_party == 0 and #Roster.pool > 0 then
            table.insert(Roster.active_party, Roster.pool[1])
        end

        print("📂 Game Loaded from DB successfully.")
        return true
    end
    
    print("⚠️ No Save State found in DB.")
    return false
end

return SaveManager
