-- 상용급 전투 액터 엔진 (OOP 기반 V2: i18n Key Compatible)
local CombatActor = {}
CombatActor.__index = CombatActor

function CombatActor.new(data, is_player)
    local self = setmetatable({}, CombatActor)
    if not data then
        data = { id = "unknown", name = "Unknown Unit", hp = 100, max_hp = 100, str = 10, con = 10 }
    end
    self.data = data 
    self.is_player = is_player
    self.id = data.id or "unknown"
    self.sprite = data.sprite or "enemy_drone.png"
    self.skills = data.skills or {}
    
    -- 이름 결정 로직 (데이터 우선 -> 번역 키 우선 -> ID 기본)
    if data.name then
        self.name = data.name
    elseif _G.L then
        self.name = L(self.id)
    else
        self.name = self.id
    end
    
    self.level = data.level or 1
    self.hp = data.hp or 100
    self.max_hp = data.max_hp or 100
    self.sp = data.sp or 50
    self.max_sp = data.max_sp or 50
    
    self.str = data.str or 10
    self.dex = data.dex or 10
    self.int = data.int or 10
    self.con = data.con or 10
    self.agi = data.agi or 10
    self.edg = data.edg or 5
    
    self.formation = data.formation or "front"
    self.status_effects = {}
    self.taunted_by = nil

    return self
end

function CombatActor:calculateDamage(skill_power, is_magic, target)
    local base = is_magic and (self.int * 3) or (self.str * 2)
    local damage = (base + (self.level * 5)) * (skill_power or 1.0)

    -- [진형] 후열 패널티/보너스
    if self.formation == "rear" then
        if is_magic then
            damage = damage * 1.15  -- 후열 마법 +15%
        else
            damage = damage * 0.7   -- 후열 물리 -30%
        end
    end
    
    -- [클래스 패시브] 솔로: 체력이 낮을수록 공격력 증폭 (Key 체크)
    if self.data.class == "class_solo" then
        local hp_ratio = self.hp / self.max_hp
        damage = damage * (1.0 + ((1.0 - hp_ratio) * 0.5))
    end
    
    -- [클래스 패시브] 넷러너: 상태이상 적에게 추가 대미지 (Key 체크)
    if self.data.class == "class_netrunner" and target then
        local has_debuff = false
        for k, v in pairs(target.status_effects) do
            if v.duration > 0 then has_debuff = true; break end
        end
        if has_debuff then damage = damage * 1.3 end
    end
    
    -- [Perk] AGI 20: 그림자 스텝 (이전 턴 회피 시 공격력 증가)
    if self.data.perks and self.data.perks["perk_agi_20"] and self.shadow_step_active then
        damage = damage * 1.2
        self.shadow_step_active = false -- 1회용 소모
    end
    
    local crit_chance = self.edg
    -- [Perk] EDG 20: 위험한 도박 (HP가 홀수일 때 크리티컬 +20%)
    if self.data.perks and self.data.perks["perk_edg_20"] and self.hp % 2 ~= 0 then
        crit_chance = crit_chance + 20
    end
    
    local is_crit = math.random(1, 100) <= crit_chance
    if is_crit then 
        -- [Perk] DEX 40: 약점 스캔 (크리 배율 2.0)
        local crit_multi = (self.data.perks and self.data.perks["perk_dex_40"]) and 2.0 or 1.5
        damage = damage * crit_multi 
    end
    
    return math.floor(damage), is_crit
end

function CombatActor:takeDamage(raw_dmg, is_guaranteed, is_penetrating)
    local evade_chance = self.agi
    if self.data.class == "class_reflexer" then evade_chance = evade_chance * 2 end
    if self:hasEffect("agi_down") then evade_chance = evade_chance * 0.5 end -- [추가]
    
    if not is_guaranteed and math.random(1, 100) <= evade_chance then
        if self.data.perks and self.data.perks["perk_agi_20"] then
            self.shadow_step_active = true -- 회피 시 다음 공격 강화 트리거
        end
        return 0, true
    end

    local final_dmg = raw_dmg
    local def_val = is_penetrating and 0 or (self.con * 0.5)
    
    if self.data.class == "class_solo" then
        local hp_ratio = self.hp / self.max_hp
        def_val = def_val * (1.0 + ((1.0 - hp_ratio) * 0.5))
    end
    
    final_dmg = final_dmg - def_val
    if self:hasEffect("shield") then final_dmg = final_dmg * 0.5 end
    if self:hasEffect("def_down") then final_dmg = final_dmg * 1.3 end
    if self:hasEffect("marked") then final_dmg = final_dmg * 1.5 end -- [추가]
    
    -- [Perk] CON 40: 불굴의 육체 (HP 30% 이하 시 받는 피해 반감)
    if self.data.perks and self.data.perks["perk_con_40"] and (self.hp / self.max_hp) <= 0.3 then
        final_dmg = final_dmg * 0.5
    end
    
    final_dmg = math.floor(math.max(1, final_dmg))
    
    if self.barrier and self.barrier > 0 then
        if self.barrier >= final_dmg then
            self.barrier = self.barrier - final_dmg
            return 0, false
        else
            final_dmg = final_dmg - self.barrier
            self.barrier = 0
        end
    end
    
    -- [Perk] AGI 40: 유령 (치명상 시 1회 생존)
    if final_dmg >= self.hp and self.data.perks and self.data.perks["perk_agi_40"] and not self.ghost_used then
        self.hp = 1
        self.ghost_used = true
        return 0, true -- 대미지 0 처리 및 강제 회피 판정
    end
    
    self.hp = math.max(0, self.hp - final_dmg)
    return final_dmg, false
end

function CombatActor:addEffect(id, duration, power)
    self.status_effects[id] = { duration = duration or 3, power = power or 0 }
end

function CombatActor:hasEffect(id)
    return self.status_effects[id] and self.status_effects[id].duration > 0
end

function CombatActor:updateStatus()
    for id, effect in pairs(self.status_effects) do
        if effect.duration > 0 then
            effect.duration = effect.duration - 1
            if effect.duration <= 0 then self.status_effects[id] = nil end
        end
    end
end

return CombatActor
