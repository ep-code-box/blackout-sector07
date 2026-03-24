-- 파티 편성 매니저 (Narrative Roster System + DB Integrated)
local Roster = {}
local DB = require("systems.db_manager")

Roster.pool = {} -- 고용 가능한 전체 용병 풀
Roster.active_party = {} -- 현재 출격 중인 1~5인 파티

-- 게임 시작 시 초기화
function Roster.init()
    Roster.pool = {}
    Roster.active_party = {}

    for _, m in ipairs(DB.getAllMercs()) do
        m.skill_levels = {}
        table.insert(Roster.pool, m)
    end

    -- 초기 파티 구성 (해금된 첫 번째 용병)
    for _, m in ipairs(Roster.pool) do
        if m.is_unlocked then
            table.insert(Roster.active_party, m)
            break
        end
    end
end

-- 용병 데이터를 DB에 영구 저장
function Roster.saveMercToDB(m)
    local function esc(s) return tostring(s or ""):gsub("'", "''") end
    local skills_csv = table.concat(m.skills or {}, ",")
    local sql = string.format(
        [[INSERT OR REPLACE INTO mercenaries
          (id, name, class, level, exp, stat_points, skill_points, hp, max_hp, sp, max_sp,
           str, dex, int, con, agi, edg, skills_csv, sprite, specialization, is_unlocked, formation_slot)
          VALUES ('%s','%s','%s',%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s','%s',%d,'%s')]],
        esc(m.id), esc(m.name), esc(m.class),
        m.level or 1, m.exp or 0, m.stat_points or 0, m.skill_points or 0,
        m.hp, m.max_hp, m.sp, m.max_sp,
        m.str, m.dex, m.int, m.con, m.agi, m.edg,
        esc(skills_csv), esc(m.sprite), esc(m.specialization or ""),
        m.is_unlocked and 1 or 0, esc(m.formation or "front")
    )
    DB.query(sql)
end

-- 특정 용병 해금 함수 (스토리에서 호출)
function Roster.unlockMerc(merc_id)
    for _, merc in ipairs(Roster.pool) do
        if merc.id == merc_id then
            if not merc.is_unlocked then
                merc.is_unlocked = true
                DB.setMercUnlocked(merc_id, true)

                -- 자리가 있으면 즉시 파티 합류
                if #Roster.active_party < 5 then
                    table.insert(Roster.active_party, merc)
                end
                print("🌟 NEW MEMBER JOINED: " .. merc.name)
                return true
            end
        end
    end
    return false
end

-- 해금된 용병 목록 반환
function Roster.getUnlockedPool()
    local result = {}
    for _, m in ipairs(Roster.pool) do
        if m.is_unlocked then table.insert(result, m) end
    end
    return result
end

-- 진형 변경: "front" ↔ "rear"
function Roster.setFormation(merc_id, slot)
    for _, m in ipairs(Roster.pool) do
        if m.id == merc_id then
            m.formation = slot
            Roster.saveMercToDB(m)
            return true
        end
    end
    return false
end

-- 전열 용병 배열 반환
function Roster.getFront()
    local result = {}
    for _, m in ipairs(Roster.active_party) do
        if (m.formation or "front") == "front" then table.insert(result, m) end
    end
    return result
end

-- 후열 용병 배열 반환
function Roster.getRear()
    local result = {}
    for _, m in ipairs(Roster.active_party) do
        if m.formation == "rear" then table.insert(result, m) end
    end
    return result
end

-- 전열 먼저, 후열 나중 순서로 정렬된 파티 반환
function Roster.getOrderedParty()
    local result = {}
    for _, m in ipairs(Roster.active_party) do
        if (m.formation or "front") == "front" then table.insert(result, m) end
    end
    for _, m in ipairs(Roster.active_party) do
        if m.formation == "rear" then table.insert(result, m) end
    end
    return result
end

-- 파티 편성에 넣기/빼기
function Roster.toggleMerc(merc_id)
    -- 이미 파티에 있는지 확인
    for i, p_merc in ipairs(Roster.active_party) do
        if p_merc.id == merc_id then
            -- 최소 1명은 파티에 남겨둠
            if #Roster.active_party > 1 then
                table.remove(Roster.active_party, i)
                return false -- 제거됨
            end
            return true -- 제거 불가 (마지막 인원)
        end
    end
    
    -- 파티에 없고 빈자리가 있으면 해금된 용병에 한해 추가
    if #Roster.active_party < 5 then
        for _, p_merc in ipairs(Roster.pool) do
            if p_merc.id == merc_id and p_merc.is_unlocked then
                table.insert(Roster.active_party, p_merc)
                return true -- 추가됨
            end
        end
    end
    
    return false -- 빈자리가 없거나 미해금
end

return Roster