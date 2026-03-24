-- 적 데이터베이스 (스케일링 지수형 개선 + AI 스킬 추가 V3)
local enemies = {
    ["drone_security"] = {
        id = "enemy_drone", name = "보안 드론",
        hp = 80, str = 8, def = 5, agi = 12, sp = 30, max_sp = 30,
        scale = {hp = 0.15, str = 0.10, def = 0.08},
        skills = {"skill_suppress", "skill_target_mark"},
        sprite = "enemy_drone.png", reward_credits = 50
    },
    ["hacker_rogue"] = {
        id = "enemy_hacker", name = "탈주 해커",
        hp = 120, str = 5, def = 3, agi = 10, int = 20, sp = 60, max_sp = 60,
        scale = {hp = 0.12, str = 0.08, def = 0.06, int = 0.12},
        skills = {"skill_synapse", "skill_shutdown"},
        sprite = "enemy_hacker_rogue.png", reward_credits = 120
    },
    ["corp_enforcer"] = {
        id = "enemy_enforcer", name = "기업 집행관",
        hp = 200, str = 15, def = 15, agi = 8, sp = 50, max_sp = 50,
        scale = {hp = 0.15, str = 0.10, def = 0.10},
        skills = {"skill_target_mark", "skill_suppress_all"},
        sprite = "enemy_corp_enforcer_elite.png", reward_credits = 150
    },
    ["corp_enforcer_elite"] = {
        id = "enemy_enforcer_elite", name = "기업 엘리트 집행관",
        hp = 280, str = 20, def = 18, agi = 10, sp = 70, max_sp = 70,
        scale = {hp = 0.18, str = 0.12, def = 0.12},
        skills = {"skill_target_mark", "skill_suppress_all", "skill_suppress"},
        sprite = "enemy_corp_enforcer_elite.png", reward_credits = 200
    },
    ["cyber_psycho"] = {
        id = "enemy_psycho", name = "사이버 사이코",
        hp = 350, str = 22, def = 12, agi = 15, sp = 80, max_sp = 80,
        scale = {hp = 0.20, str = 0.15, def = 0.10},
        skills = {"skill_punch", "skill_adrenaline", "skill_suppress"},
        sprite = "enemy_cyber_psycho_boss.png", reward_credits = 300, is_boss = true
    },
    ["boss_seraphina"] = {
        id = "boss_seraphina", name = "세라피나",
        hp = 320, str = 12, def = 18, agi = 14, int = 25, sp = 120, max_sp = 120,
        scale = {hp = 0.18, str = 0.08, def = 0.12, int = 0.15},
        skills = {"skill_nano", "skill_shutdown", "skill_stim", "skill_synapse"},
        sprite = "boss_seraphina.png", reward_credits = 280, is_boss = true
    },
}

return enemies
