-- 사이버웨어 및 아이템 데이터베이스 (확장 버전)
-- 사이버펑크 특유의 '하이 리스크 하이 리턴' 컨셉을 적용합니다.
local items = {
    -- 안구 (Optics)
    ["kiroshi_mk1"] = {
        id = "kiroshi_mk1", name = "키로시 안구 Mk.1", price = 100, tier = 1,
        slot = "optics", stats = {dex = 2, edg = 1},
        desc = "기본적인 안구 임플란트. 명중률과 운이 약간 상승합니다."
    },
    ["oracle_eye_mk3"] = {
        id = "oracle_eye_mk3", name = "오라클 마안 Mk.3", price = 600, tier = 3,
        slot = "optics", stats = {dex = 8, int = 5, con = -2},
        desc = "적의 약점을 꿰뚫어보지만, 뇌신경에 무리를 주어 체력이 감소합니다."
    },

    -- 신경계 (Nervous System)
    ["sandevistan_mk1"] = {
        id = "sandevistan_mk1", name = "산데비스탄 Mk.1", price = 300, tier = 1,
        slot = "nervous", stats = {agi = 5},
        grant_skill = "산데비스탄 가속",
        desc = "반사 신경을 극대화합니다. [산데비스탄 가속] 스킬을 사용할 수 있게 됩니다."
    },
    ["militech_berserk"] = {
        id = "militech_berserk", name = "밀리테크 버서크 OS", price = 850, tier = 3,
        slot = "nervous", stats = {str = 10, agi = 5, int = -5},
        grant_skill = "아드레날린 펌프",
        desc = "전투용 아드레날린을 폭발시킵니다. [아드레날린 펌프] 스킬이 추가됩니다."
    },

    -- 피부/외장 (Integumentary)
    ["subdermal_armor"] = {
        id = "subdermal_armor", name = "피하 장갑", price = 200, tier = 1,
        slot = "integumentary", stats = {con = 5},
        desc = "피부 아래에 금속판을 이식하여 방어력을 높입니다."
    },
    ["optical_camo_skin"] = {
        id = "optical_camo_skin", name = "광학 위장 피부", price = 900, tier = 3,
        slot = "integumentary", stats = {agi = 4, edg = 10, str = -2},
        desc = "몸을 투명하게 만들어 기적적인 회피 확률(EDG)을 대폭 높입니다."
    },

    -- 팔/무기 개조 (Arms / Weapon Mods)
    ["mantis_blades"] = {
        id = "mantis_blades", name = "맨티스 블레이드", price = 750, tier = 3,
        slot = "weapon", stats = {str = 5, agi = 5},
        replace_skill = {target = "공격", new_skill = "단분자 베기"},
        desc = "팔에 내장된 접이식 칼날. [공격] 스킬이 [단분자 베기]로 영구 변환됩니다."
    },
    ["smart_link"] = {
        id = "smart_link", name = "스마트 타겟팅 링크", price = 500, tier = 2,
        slot = "weapon", stats = {dex = 8, edg = 2},
        desc = "무기와 시신경을 연동하여 백발백중의 명중률을 자랑합니다."
    }
}

return items