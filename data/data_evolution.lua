-- 사이버펑크 성장 & 특성 시스템 (Tier-2 Specialization Full Set V2)
local Evolution = {}

-- 1. 전직(Specialization) 정의 — 전 직업군 tier_2 완성
Evolution.classes = {
    ["class_solo"] = {
        tier_2 = {
            ["버서커"] = {
                desc = "순수 파괴력 특화. 체력이 낮을수록 공격력이 폭등합니다. 광역 격분 공격을 획득합니다.",
                bonus = {str=8, edg=3},
                new_skills = {"skill_berserker_rage"}
            },
            ["센추리온"] = {
                desc = "철벽 방어 특화. 아군 전체의 어그로를 집중시키고 극한의 도발 내구력을 보유합니다.",
                bonus = {con=8, str=3},
                new_skills = {"skill_sentinel_wall"}
            }
        }
    },
    ["class_reflexer"] = {
        tier_2 = {
            ["블레이드댄서"] = {
                desc = "다중 타격 특화. 초고속 3연속 베기로 회피와 공격을 동시에 수행합니다.",
                bonus = {dex=8, agi=3},
                new_skills = {"skill_blade_vortex"}
            },
            ["유령"] = {
                desc = "잠입 특화. 은신 후 극도로 집약된 한 번의 일격으로 적을 제압합니다.",
                bonus = {agi=8, edg=3},
                new_skills = {"skill_shadow_kill"}
            }
        }
    },
    ["class_techie"] = {
        tier_2 = {
            ["사이버스나이퍼"] = {
                desc = "원거리 정밀 타격 특화. 적의 방어력을 완전히 무시하는 고정밀 사격을 발사합니다.",
                bonus = {dex=8, str=3},
                new_skills = {"skill_armor_pierce"}
            },
            ["드론파일럿"] = {
                desc = "드론 군단 특화. 4기의 전투 드론을 소환하여 적을 다각도로 공격합니다.",
                bonus = {int=5, dex=5},
                new_skills = {"skill_drone_swarm"}
            }
        }
    },
    ["class_netrunner"] = {
        tier_2 = {
            ["브리처"] = {
                desc = "광역 디버프 특화. 적 전체의 시스템을 한 번에 마비시키는 대규모 해킹을 시전합니다.",
                bonus = {int=8, edg=3},
                new_skills = {"skill_mass_shutdown"}
            },
            ["아이스브레이커"] = {
                desc = "대인 해킹 특화. 단일 타겟의 신경망을 즉시 소각하는 치명적인 과부하를 가합니다.",
                bonus = {edg=6, int=5},
                new_skills = {"skill_brain_fry"}
            }
        }
    },
    ["class_ripperdoc"] = {
        tier_2 = {
            ["필드메딕"] = {
                desc = "긴급 치료 특화. 전사한 아군을 현장에서 즉시 소생시키는 기적의 처치를 제공합니다.",
                bonus = {int=8, con=3},
                new_skills = {"skill_emergency_revive"}
            },
            ["어거먼터"] = {
                desc = "사이버웨어 강화 특화. 아군 전체의 사이버웨어를 과부하 모드로 전환하여 능력치를 폭발적으로 끌어올립니다.",
                bonus = {int=5, edg=6},
                new_skills = {"skill_overclock"}
            }
        }
    }
}

-- 2. 스탯 임계점 기반 마스터리 (Stat Mastery)
Evolution.perks = {
    str = {
        [20] = { id = "perk_str_20", name = "키네틱 충격파", desc = "물리 공격 명중 시 적을 확률적으로 기절시킵니다." },
        [40] = { id = "perk_str_40", name = "타이탄 그립",  desc = "적의 방어력을 30% 무시하고 피해를 입힙니다." }
    },
    dex = {
        [20] = { id = "perk_dex_20", name = "정밀 타격",   desc = "크리티컬 적중 시 적의 방어력을 영구적으로 깎습니다." },
        [40] = { id = "perk_dex_40", name = "약점 스캔",   desc = "크리티컬 대미지 배율이 1.5배에서 2.0배로 증가합니다." }
    },
    int = {
        [20] = { id = "perk_int_20", name = "RAM 리사이클", desc = "자신의 턴이 끝날 때 SP를 회복합니다." },
        [40] = { id = "perk_int_40", name = "논리 폭탄",   desc = "스킬로 적을 처치하면 스킬의 SP를 전액 환급받습니다." }
    },
    con = {
        [20] = { id = "perk_con_20", name = "진통제 주입",  desc = "전투 시작 시 최대 체력 기반의 실드(Barrier)를 얻습니다." },
        [40] = { id = "perk_con_40", name = "불굴의 육체",  desc = "자신의 체력이 30% 이하일 때 모든 피해를 절반만 받습니다." }
    },
    agi = {
        [20] = { id = "perk_agi_20", name = "그림자 스텝",  desc = "적의 공격을 회피할 때마다 다음 턴의 공격력이 증가합니다." },
        [40] = { id = "perk_agi_40", name = "유령",         desc = "치명적인 피해를 입어도 확률적으로 회피합니다." }
    },
    edg = {
        [20] = { id = "perk_edg_20", name = "위험한 도박",  desc = "HP가 홀수일 때 크리티컬 확률이 20% 증가합니다." },
        [40] = { id = "perk_edg_40", name = "잭팟",         desc = "전투 승리 시 크레딧 획득량이 대폭 증가합니다." }
    }
}

return Evolution
