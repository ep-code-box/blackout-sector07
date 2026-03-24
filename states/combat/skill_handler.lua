-- 전투 스킬 처리기: 모든 스킬의 수치 계산 및 효과 적용 전담
local SkillHandler = {}
local FXManager = require("systems.fx_manager")
local ShaderManager = require("systems.shader_manager")
local shack = require("lib.shack")

function SkillHandler.execute(caster, target_primary, skill_name, skills_db, party_actors, enemy_actor, StateCombat)
    local skill = skills_db[skill_name] or skills_db["skill_attack"]
    local msg = caster.name .. " // " .. L(skill_name):upper()

    -- 1. 자원 소모
    if skill.hp_cost then
        caster.hp = math.max(1, caster.hp - math.floor(caster.max_hp * skill.hp_cost))
    end
    if caster.sp < (skill.sp or 0) then return "NOT ENOUGH SP!" end
    caster.sp = caster.sp - (skill.sp or 0)

    -- [추가] 공통 시각 효과 트리거
    if skill.fx_type == "hack" or skill.fx_type == "glitch" then
        ShaderManager.trigger(0.5) -- 글리치 강도
    elseif skill.fx_type == "impact" then
        FXManager.shake(20, 0.4)
    elseif skill.fx_type == "buff" or skill.fx_type == "heal" then
        FXManager.flash({skill.fx_color[1], skill.fx_color[2], skill.fx_color[3], 0.2}, 0.4)
    end

    -- 2. 타입별 처리
    if skill.type == "attack" or skill.type == "attack_multi" then
        return SkillHandler.handleAttack(caster, target_primary, skill, skill_name, party_actors, enemy_actor, msg, StateCombat)
    elseif skill.type == "heal" then
        return SkillHandler.handleHeal(caster, target_primary, skill, party_actors, msg)
    elseif skill.type == "debuff" then
        return SkillHandler.handleDebuff(caster, target_primary, skill, msg)
    elseif skill.type == "buff" then
        return SkillHandler.handleBuff(caster, skill, party_actors, msg)
    end

    return msg
end

function SkillHandler.handleAttack(caster, target, skill, skill_name, party_actors, enemy_actor, msg, StateCombat)
    local skill_lv = (caster.data.skill_levels and caster.data.skill_levels[skill_name]) or 1
    local lv_bonus = 1.0 + (skill_lv - 1) * 0.2
    if skill.bonus_on_status and enemy_actor:hasEffect(skill.bonus_on_status) then
        lv_bonus = lv_bonus * 2.0
    end

    local is_penetrating = skill.is_penetrating 
        or (caster.data.class == "class_techie" and math.random(1, 100) <= 20)
        or (caster.data.perks and caster.data.perks["perk_str_40"])

    local raw_dmg, is_crit = caster:calculateDamage((skill.power or 1.0) * lv_bonus, skill.is_magic, enemy_actor)

    if is_crit and caster.data.perks and caster.data.perks["perk_dex_20"] then
        enemy_actor.con = math.max(0, enemy_actor.con - 5)
        msg = msg .. " (ARMOR BROKEN)"
    end

    local targets = (skill.effect == "agi_down" and (skill.hits or 1) == 1) and party_actors or {enemy_actor}
    local total_dmg = 0

    for _, tgt in ipairs(targets) do
        local hits = skill.hits or 1
        for _ = 1, hits do
            local d, ev = tgt:takeDamage(raw_dmg, false, is_penetrating)
            total_dmg = total_dmg + d
            if ev and tgt == enemy_actor then msg = msg .. " (EVADED)" end
        end
        if skill.effect == "agi_down" then tgt:addEffect("agi_down", skill.duration or 2) end
    end

    if total_dmg > 0 and caster.data.perks and caster.data.perks["perk_str_20"] and math.random(1, 100) <= 15 then
        enemy_actor:addEffect("stun", 1)
        msg = msg .. " (STUNNED)"
    end

    if enemy_actor.hp <= 0 and skill.is_magic and caster.data.perks and caster.data.perks["perk_int_40"] then
        caster.sp = math.min(caster.max_sp, caster.sp + (skill.sp or 0))
        msg = msg .. " [SP REFUNDED]"
    end

    -- 타격 효과 보강
    if is_crit then 
        FXManager.shake(25, 0.5)
        ShaderManager.trigger(0.8) 
    else
        FXManager.shake(12, 0.2)
    end
    
    FXManager.spawnText(400, 180, tostring(total_dmg), is_crit and {1,0.8,0} or {1,0.2,0.2}, is_crit)
    return msg .. " (" .. total_dmg .. " DMG)"
end

function SkillHandler.handleHeal(caster, target, skill, party_actors, msg)
    if skill.revive then
        for i, p in ipairs(party_actors) do
            if p.hp <= 0 then
                p.hp = math.floor(p.max_hp * 0.3)
                FXManager.spawnText(50 + (i-1)*240 + 60, 400, "REVIVED!", {0.5, 1, 0.8}, true)
                return msg .. " // " .. p.name .. " REVIVED!"
            end
        end
    end

    local best_target, best_idx = party_actors[1], 1
    for i, p in ipairs(party_actors) do
        if p.hp > 0 and (p.hp / p.max_hp) < (best_target.hp / best_target.max_hp) then
            best_target, best_idx = p, i
        end
    end

    local heal_amt = math.floor((caster.int * 8) * (skill.power or 1.0))
    if caster.data.class == "class_ripperdoc" then
        local over = (best_target.hp + heal_amt) - best_target.max_hp
        if over > 0 then
            best_target.barrier = (best_target.barrier or 0) + over
            heal_amt = heal_amt - over
        end
    end

    best_target.hp = math.min(best_target.max_hp, best_target.hp + heal_amt)
    FXManager.spawnText(50 + (best_idx-1)*240 + 60, 400, "+"..heal_amt, {0.2, 1, 0.5}, false)
    return msg .. " // HEALED " .. best_target.name .. " (+" .. heal_amt .. ")"
end

function SkillHandler.handleDebuff(caster, target, skill, msg)
    if skill.effect then target:addEffect(skill.effect, skill.duration) end
    return msg .. " // TARGET COMPROMISED"
end

function SkillHandler.handleBuff(caster, skill, party_actors, msg)
    local buf_targets = (skill.target == "all") and party_actors or {caster}
    for _, bt in ipairs(buf_targets) do
        if bt.hp > 0 and skill.effect then bt:addEffect(skill.effect, skill.duration) end
    end
    return msg .. " // PROTOCOL ACTIVE"
end

return SkillHandler
