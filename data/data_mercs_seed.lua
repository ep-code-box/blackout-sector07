-- 용병 대기소 데이터 (Mercenary Roster V4: i18n Key Integrated)
local mercs = {
    { 
        id = "merc_01", name = "루나 (Luna)", class = "class_solo", level = 1, stat_points = 0,
        hp = 150, max_hp = 150, sp = 30, max_sp = 30,
        str = 12, dex = 8, int = 6, con = 15, agi = 7, edg = 5,
        skills = {"skill_punch", "skill_taunt", "skill_defend"},
        sprite = "merc_01_luna.png"
    },
    { 
        id = "merc_02", name = "헬레나 (Helena)", class = "class_solo", level = 1, stat_points = 0,
        hp = 180, max_hp = 180, sp = 20, max_sp = 20,
        str = 15, dex = 5, int = 4, con = 18, agi = 5, edg = 3,
        skills = {"skill_punch", "skill_adrenaline", "skill_defend"},
        sprite = "merc_02_helena.png"
    },
    { 
        id = "merc_03", name = "미오 (Mio)", class = "class_reflexer", level = 1, stat_points = 0,
        hp = 120, max_hp = 120, sp = 50, max_sp = 50,
        str = 14, dex = 10, int = 5, con = 10, agi = 12, edg = 15,
        skills = {"skill_slice", "skill_sandevistan", "skill_defend"},
        sprite = "merc_03_mio.png"
    },
    { 
        id = "merc_04", name = "유이 (Yui)", class = "class_reflexer", level = 1, stat_points = 0,
        hp = 100, max_hp = 100, sp = 60, max_sp = 60,
        str = 10, dex = 15, int = 8, con = 8, agi = 16, edg = 10,
        skills = {"skill_slice", "skill_defend"},
        sprite = "merc_04_yui.png"
    },
    { 
        id = "merc_05", name = "노바 (Nova)", class = "class_techie", level = 1, stat_points = 0,
        hp = 90, max_hp = 90, sp = 60, max_sp = 60,
        str = 8, dex = 15, int = 7, con = 8, agi = 10, edg = 8,
        skills = {"skill_suppress", "skill_shotgun", "skill_defend"},
        sprite = "merc_05_nova.png"
    },
    { 
        id = "merc_06", name = "스텔라 (Stella)", class = "class_techie", level = 1, stat_points = 0,
        hp = 110, max_hp = 110, sp = 40, max_sp = 40,
        str = 10, dex = 12, int = 5, con = 12, agi = 8, edg = 5,
        skills = {"skill_suppress", "skill_defend"},
        sprite = "merc_06_stella.png"
    },
    { 
        id = "merc_07", name = "키라 (Kira)", class = "class_netrunner", level = 1, stat_points = 0,
        hp = 80, max_hp = 80, sp = 100, max_sp = 100,
        str = 5, dex = 10, int = 15, con = 7, agi = 9, edg = 12,
        skills = {"skill_synapse", "skill_shutdown", "skill_defend"},
        sprite = "merc_07_kira.png"
    },
    { 
        id = "merc_08", name = "클로이 (Chloe)", class = "class_ripperdoc", level = 1, stat_points = 0,
        hp = 85, max_hp = 85, sp = 90, max_sp = 90,
        str = 6, dex = 8, int = 14, con = 10, agi = 8, edg = 10,
        skills = {"skill_nano", "skill_stim", "skill_defend"},
        sprite = "merc_08_chloe.png"
    }
}

return mercs
