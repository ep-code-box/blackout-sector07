-- 퀘스트 데이터베이스 (ID 기반)
local quests = {
    {
        id = "tutorial_01",
        title = "연구소 침투",
        desc = "실험 구역 1-A에 있는 보안 드론을 무력화하십시오.",
        target_coords = {x=4, y=2},
        required_boss_id = "drone_security", -- ID로 변경
        reward_lv = 1,
        completed = false
    },
    {
        id = "main_01",
        title = "사이버 사이코 소탕",
        desc = "하층 구역에서 날뛰는 사이버 사이코를 제압하십시오.",
        target_coords = {x=2, y=2},
        required_boss_id = "cyber_psycho", -- ID로 변경
        reward_lv = 1,
        completed = false
    },
    {
        id = "quest_corrupted_nun",
        title = "침묵의 예언자",
        desc = "바텐더 ‘블레이즈’가 씁쓸한 목소리로 웅크린 채 말한다. ‘젠장, 꼬마 녀석. 낡은 성당 ‘아벨’의 안드로이드 수녀 ‘세라피나’가 실종됐다는 소문이 돌아. 그녀는… 지금쯤 도시의 어두운 곳에서 뭔가 하고 있을 거야. 잃어버린 기억과 죄악의 기원을 찾아달라는 부탁을 받았지. 하지만… 그녀의 목적은 결코 숭고하지 않을 거야. 잊지 마, 녀석. 그녀의 빛은 이미 타락했어… 그리고 그녀의 눈은… 감겨가고 있지…",
        target_coords = {x=4, y=2},
        required_boss_id = "boss_seraphina",
        reward_lv = 1,
        completed = false
    },
    {
        id = "REVENANT_MAIDEN",
        title = "회귀의 진주",
        desc = "이 눅눅한 낡은 샴페인 잔을 꽉 쥐어. '알렉산드라'라고 불러줘. 꽤 오래전부터 여기서 일하고 있었지. '고급'이라고 부르기엔 부족하겠지만... 펜트하우스는 여전히 쾌적하고, 손님들은 충성스러워. 하지만... 이제 꼬여버렸어. '모듈러스'라는 이름의 놈이 그녀들을 조종하고 있었지. 펜트하우스 전체를 '진주'라고 부르는 것 같아. 진주를 찾아서 놈을 처단해 줘. 그리고... 진주를 줘. 제발.",
        target_coords = {x=1, y=5},
        required_boss_id = "AURORA_08",
        reward_lv = 1,
        completed = false
    },
    {
        id = "NEON_DREAMS",
        title = "네온 꿈의 춤",
        desc = "바텐더 ‘크롬’이 씁쓸하게 웃으며 웅크린 채 말했다. ‘새벽의 핏빛 그림자가 드리울 때, 그녀는 네 꿈속으로 스며든다. 밤의 여왕, 루나. 그녀는 단순한 댄서가 아니야. 밤의 그림자 속에 숨겨진 붉은 꽃, 즉 ‘아르카나’를 딜리버하는 암살자. 당신에게는 그녀의 마지막 거래를 성사시켜야만 해… 그리고 혹시라도, 그녀의 실수를 발견하면… 당신의 기억은 완벽하게 지워질 거야.’",
        target_coords = {x=5, y=2},
        required_boss_id = "LUNA_VENUS",
        reward_lv = 1,
        completed = false
    },
    {
        id = "DATA_QUEEN_01",
        title = "데이터의 심연에서",
        desc = "어둠 속에서 웅크리는 거대 서버, 그 심장부에는 전뇌 여제 '아스트라'가 존재한다. 그녀는 수십만 개의 데이터 스트림과 융합된 육체, 그리고 그녀의 의지를 구현하는 관능적인 AI '오르페우스'를 통해 존재한다. 그녀는 당신의 선택에 따라 숭배, 파괴, 혹은 끔찍한 쾌락을 선사할 것이다. 하지만 기억하라, 그녀의 데이터는 당신의 모든 것을 소비할 것이다.",
        target_coords = {x=3, y=1},
        required_boss_id = "ASTRAL_CORE",
        reward_lv = 1,
        completed = false
    },
    {
        id = "Q1-003",
        title = "잔혹한 왈츠",
        desc = "세련된 가죽 재킷과 붉은 립스틱, 그리고 끝없이 회전하는 발끝. '루비'는 당신에게 밤의 비밀을 알려줄 준비가 되어있어. 하지만 기억해, 이 밤은 당신의 마지막 밤일 수도 있다는 것을...",
        target_coords = {x=1, y=3},
        required_boss_id = "RB-01",
        reward_lv = 1,
        completed = false
    },
    {
        id = "DC-001",
        title = "데이터의 멜로디",
        desc = "이봐, 어서 와! 젠장, 저 녀석은 이미 너의 생각을 읽고 있을 거야. 너의 모든 추억, 모든 욕망... 전부 다. 이 녀석을 쓰러뜨려야만, 도시의 그림자가 사라질 수 있어. 늦지 마. 데이터는 멈추지 않아.",
        target_coords = {x=1, y=1},
        required_boss_id = "CORE-01",
        reward_lv = 1,
        completed = false
    },
    {
        id = "Q1-007",
        title = "침묵의 멜로디",
        desc = "잠깐만… 이 촉감은 대체… 젠장, 저 녀석이 또 나타났어! 호텔 펜트하우스 전체를 지배하려 하고 있잖아! 그녀의 기억 코드를 재프로그래밍해야만, 이 끔찍한 진화를 막을 수 있어! 빨리, 그녀의 멜로디를 끊어내!",
        target_coords = {x=2, y=1},
        required_boss_id = "B1-012",
        reward_lv = 1,
        completed = false
    },
    {
        id = "NQ-0087",
        title = "잃어버린 스타의 노래",
        desc = "이봐, 바텐더. 최근 며칠 동안, 밤거리에서 '아스트라'라는 이름의 버림받은 아이돌을 흔히 보게 돼. 마지막 공연 이후, 그녀는 도시의 어둠 속에 숨어, 뭔가 심상치 않은 일을 꾸미고 있는 것 같아. 왠지, 오라클의 그림자가 얽혀 있는 기분이 들어.",
        target_coords = {x=5, y=3},
        required_boss_id = "BG-012",
        reward_lv = 1,
        completed = false
    }
}

return quests