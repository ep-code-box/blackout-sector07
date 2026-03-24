-- 레벨업 및 성장 로직 매니저
local Progression = {}
local Evolution = require("data.data_evolution")
local Roster = require("systems.roster")

local STAT_CAP = 50  -- 스탯 최대치

function Progression.checkPerks(char)
    char.perks = char.perks or {}
    local stat_list = {"str", "dex", "int", "con", "agi", "edg"}

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
end

-- 스탯 포인트 투자
function Progression.investStat(char, stat_key)
    if not char then return false, "캐릭터 없음" end
    if (char.stat_points or 0) <= 0 then return false, "미분배 포인트 없음" end
    local valid = {str=true, dex=true, int=true, con=true, agi=true, edg=true}
    if not valid[stat_key] then return false, "잘못된 스탯" end
    local current = char[stat_key] or 0
    if current >= STAT_CAP then return false, "최대치 도달 (" .. STAT_CAP .. ")" end

    char[stat_key] = current + 1
    char.stat_points = char.stat_points - 1
    Progression.checkPerks(char)
    Roster.saveMercToDB(char)

    -- 펄크 해제 알림용 플래그
    local perk_unlocked = nil
    local perks_for_stat = Evolution.perks[stat_key]
    if perks_for_stat then
        for threshold, perk in pairs(perks_for_stat) do
            if char[stat_key] == threshold then
                perk_unlocked = perk.name
            end
        end
    end

    local msg = stat_key:upper() .. " → " .. char[stat_key]
    if perk_unlocked then msg = msg .. "  ★ PERK: " .. perk_unlocked end
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

-- EXP 지급 및 자동 레벨업. 레벨업이 발생하면 true 반환.
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
