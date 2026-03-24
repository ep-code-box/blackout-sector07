-- 레벨업 및 성장 로직 매니저 (Advanced V2)
local Progression = {}
local Evolution = require("data.data_evolution")
local Roster = require("systems.roster")

local STAT_CAP = 50  -- 스탯 절대 최대치
local SOFT_CAP = 40  -- 이 지점부터 투자 비용 증가

function Progression.checkPerks(char)
    char.perks = char.perks or {}
    local stat_list = {"str", "dex", "int", "con", "agi", "edg"}

    -- 1. 단일 스탯 펄크 체크
    for _, s_id in ipairs(stat_list) do
        local val = char[s_id] or 0
        local perks_for_stat = Evolution.perks[s_id]
        if perks_for_stat then
            for threshold, perk in pairs(perks_for_stat) do
                if val >= threshold and not char.perks[perk.id] then
                    char.perks[perk.id] = perk.name
                    print("✨ PERK UNLOCKED: " .. char.name .. " gained [" .. perk.name .. "]")
                end
            end
        end
    end

    -- 2. 이중 스탯 시너지 체크 (추가)
    if Evolution.synergies then
        for _, syn in ipairs(Evolution.synergies) do
            local meet = true
            for s_id, req_val in pairs(syn.req) do
                if (char[s_id] or 0) < req_val then meet = false; break end
            end
            if meet and not char.perks[syn.id] then
                char.perks[syn.id] = syn.name
                print("🌀 SYNERGY ACTIVE: " .. char.name .. " unlocked [" .. syn.name .. "]")
            end
        end
    end
end

-- 스탯 포인트 투자 (Soft Cap 로직 추가)
function Progression.investStat(char, stat_key)
    if not char then return false, "캐릭터 없음" end
    
    local current = char[stat_key] or 0
    if current >= STAT_CAP then return false, "최대치 도달 (" .. STAT_CAP .. ")" end

    -- 비용 계산: 40 이상이면 2포인트 소모
    local cost = (current >= SOFT_CAP) and 2 or 1
    if (char.stat_points or 0) < cost then 
        return false, "포인트 부족 (필요: " .. cost .. ")" 
    end

    char[stat_key] = current + 1
    char.stat_points = char.stat_points - cost
    
    Progression.checkPerks(char)
    Roster.saveMercToDB(char)

    local msg = stat_key:upper() .. " → " .. char[stat_key]
    return true, msg
end

-- 직업 전직
function Progression.promoteChar(char, spec_name)
    if not char or not char.can_promote then return false, "전직 조건 미충족" end

    local class_evo = Evolution.classes[char.class]
    if not class_evo or not class_evo.tier_2 then return false, "전직 데이터 없음" end

    local spec = class_evo.tier_2[spec_name]
    if not spec then return false, "선택지 없음: " .. tostring(spec_name) end

    -- 스탯 보너스 적용
    if spec.bonus then
        for stat, val in pairs(spec.bonus) do
            char[stat] = (char[stat] or 0) + val
        end
    end

    -- 전직 전용 스킬 추가
    if spec.new_skills then
        for _, skill_id in ipairs(spec.new_skills) do
            local has = false
            for _, s in ipairs(char.skills) do if s == skill_id then has = true; break end end
            if not has then table.insert(char.skills, skill_id) end
        end
    end

    char.specialization = spec_name
    char.can_promote = false
    Progression.checkPerks(char)
    Roster.saveMercToDB(char)

    print("⚡ PROMOTED: " .. char.name .. " → " .. spec_name)
    return true, spec_name .. " 전직 완료!"
end

local function levelUpChar(char)
    char.level = char.level + 1
    char.max_hp = char.max_hp + 25
    char.hp = math.min(char.max_hp, char.hp + 25)
    char.max_sp = char.max_sp + 10
    char.sp = math.min(char.max_sp, char.sp + 10)
    char.stat_points = (char.stat_points or 0) + 5
    char.skill_points = (char.skill_points or 0) + 1
    if char.level >= 5 and not char.can_promote and (not char.specialization or char.specialization == "") then
        char.can_promote = true
    end
    Roster.saveMercToDB(char)
    print("⬆️ LEVEL UP: " .. char.name .. " → Lv." .. char.level)
end

-- EXP 임계값: level * 100
function Progression.expNeeded(level)
    return (level or 1) * 100
end

-- EXP 지급 및 자동 레벨업
function Progression.gainExp(party, amount)
    local leveled = false
    for _, char in ipairs(party) do
        char.exp = (char.exp or 0) + amount
        local threshold = Progression.expNeeded(char.level)
        if char.exp >= threshold then
            char.exp = char.exp - threshold
            levelUpChar(char)
            leveled = true
        else
            Roster.saveMercToDB(char)
        end
    end
    return leveled
end

-- 퀘스트 보상용 즉시 레벨업 (EXP 무시)
function Progression.levelUp(party)
    for _, char in ipairs(party) do
        levelUpChar(char)
    end
end

return Progression
