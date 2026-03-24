-- 적군 AI: 행동 선택 및 타겟팅 로직 전담
local EnemyAI = {}
local FXManager = require("systems.fx_manager")
local ShaderManager = require("systems.shader_manager")
local shack = require("lib.shack")

function EnemyAI.takeTurn(enemy, party_actors, skills_db, StateCombat)
    enemy:updateStatus()
    if enemy:hasEffect("stun") then
        return enemy.name .. " // SYSTEM STUNNED"
    end

    local alive = {}
    for _, p in ipairs(party_actors) do if p.hp > 0 then table.insert(alive, p) end end
    if #alive == 0 then return nil end

    -- [진형] 전열 생존자가 있으면 후열은 타겟 불가
    local front_alive = {}
    for _, p in ipairs(alive) do
        if (p.formation or "front") == "front" then table.insert(front_alive, p) end
    end
    local target_pool = #front_alive > 0 and front_alive or alive
    local target = enemy.taunted_by or target_pool[math.random(#target_pool)]
    local skills = enemy.data and enemy.data.skills or {}
    
    -- 스킬 사용 확률 계산
    local is_boss = enemy.data.is_boss
    local hp_ratio = enemy.hp / enemy.max_hp
    local skill_chance = is_boss and (hp_ratio <= 0.5 and 80 or 50) or 30

    if #skills > 0 and (enemy.sp or 0) >= 10 and math.random(1, 100) <= skill_chance then
        local res = EnemyAI.useSkill(enemy, target, skills, skills_db, party_actors, alive)
        if res then return res end
    end

    -- 일반 공격
    return EnemyAI.basicAttack(enemy, target, party_actors, StateCombat)
end

function EnemyAI.useSkill(enemy, target, skills, skills_db, party_actors, alive)
    local usable = {}
    for _, s_name in ipairs(skills) do
        local sd = skills_db[s_name]
        if sd and (enemy.sp or 0) >= (sd.sp or 0) then table.insert(usable, {name=s_name, data=sd}) end
    end
    if #usable == 0 then return nil end

    local chosen = usable[math.random(#usable)]
    local sd = chosen.data
    enemy.sp = math.max(0, (enemy.sp or 0) - (sd.sp or 0))

    if sd.type == "attack" or sd.type == "attack_multi" then
        local raw = enemy:calculateDamage((sd.power or 1.0) * 1.1)
        local total = 0
        for _ = 1, (sd.hits or 1) do total = total + target:takeDamage(raw, false, false) end
        
        local t_idx = 1
        for i, p in ipairs(party_actors) do if p == target then t_idx = i; break end end
        FXManager.spawnText(50+(t_idx-1)*240+60, 380, "-"..math.floor(total), {1, 0.4, 0}, false)
        ShaderManager.trigger(0.4)
        return enemy.name .. " >> " .. L(chosen.name):upper() .. " (" .. math.floor(total) .. " DMG)"

    elseif sd.type == "debuff" and sd.effect then
        for _, p in ipairs(alive) do p:addEffect(sd.effect, sd.duration or 2) end
        return enemy.name .. " >> " .. L(chosen.name):upper() .. " // SQUAD COMPROMISED"
    end
    return nil
end

function EnemyAI.basicAttack(enemy, target, party_actors, StateCombat)
    local raw = enemy:calculateDamage(1.5)
    local dmg, evaded = target:takeDamage(raw, false, false)
    
    local t_idx = 1
    for i, p in ipairs(party_actors) do if p == target then t_idx = i; break end end
    local tx = 50 + (t_idx-1)*240 + 60

    if evaded then
        FXManager.spawnText(tx, 380, "EVADED", {0.5, 1, 0.5}, false)
        local msg = enemy.name .. " ATTACKS " .. target.name .. " (MISSED)"
        if target.data.class == "class_reflexer" then
            local c_dmg = target:calculateDamage(1.0)
            enemy:takeDamage(c_dmg, true, false)
            FXManager.spawnText(400, 180, "-"..math.floor(c_dmg), {1,0.5,0}, false)
            ShaderManager.trigger(0.3)
            msg = msg .. string.format(L("log_reflex_counter"), math.floor(c_dmg))
        end
        return msg
    else
        if StateCombat and StateCombat.shake then
            StateCombat.shake(10, 0.25)
        end
        ShaderManager.trigger(0.5)
        FXManager.spawnText(tx, 380, "-"..math.floor(dmg), {1,0,0}, false)
        return enemy.name .. " ATTACKS " .. target.name .. " (" .. math.floor(dmg) .. " DMG)"
    end
end

return EnemyAI
