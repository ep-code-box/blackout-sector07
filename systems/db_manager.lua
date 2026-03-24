-- 데이터베이스 매니저 (SQLite Bridge V3 - Full Data Migration)
local DBManager = {}
local json = require("lib.json")

local sqlite3 = nil
pcall(function() sqlite3 = require("lsqlite3") end)

local function esc(s)
    return tostring(s or ""):gsub("'", "''")
end

function DBManager.init()
    local db_path = "client/game_data.db"
    if not love.filesystem.getRealDirectory(db_path) then
        db_path = "game_data.db"
    end

    if sqlite3 then
        DBManager.db = sqlite3.open(db_path)
        print("🗄️ SQLite connected: " .. db_path)
    else
        print("⚠️ lsqlite3 not found. Shell-Query Mode.")
    end

    -- ── 스키마 생성 ────────────────────────────────────────────────────────────
    -- mercenaries: is_unlocked 컬럼 추가 마이그레이션
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS mercenaries (
            id TEXT PRIMARY KEY, name TEXT, class TEXT, level INTEGER, exp INTEGER,
            stat_points INTEGER, skill_points INTEGER, hp INTEGER, max_hp INTEGER,
            sp INTEGER, max_sp INTEGER, str INTEGER, dex INTEGER, int INTEGER,
            con INTEGER, agi INTEGER, edg INTEGER, skills_csv TEXT, sprite TEXT,
            specialization TEXT, is_unlocked INTEGER DEFAULT 0,
            formation_slot TEXT DEFAULT 'front'
        );
    ]])
    -- 기존 DB 마이그레이션: formation_slot 컬럼 없을 때만 추가
    local col_info = DBManager.query("PRAGMA table_info(mercenaries)")
    local has_formation = false
    for _, col in ipairs(col_info or {}) do
        if col.name == "formation_slot" then has_formation = true; break end
    end
    if not has_formation then
        DBManager.query("ALTER TABLE mercenaries ADD COLUMN formation_slot TEXT DEFAULT 'front'")
    end
    DBManager.query([[CREATE TABLE IF NOT EXISTS save_state (key TEXT PRIMARY KEY, value TEXT);]])

    -- enemies: 기존 스키마 삭제 후 확장 버전으로 재생성
    DBManager.query([[DROP TABLE IF EXISTS enemies;]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS enemies (
            id TEXT PRIMARY KEY, name TEXT,
            hp INTEGER, str INTEGER, def INTEGER, agi INTEGER, int INTEGER,
            sp INTEGER, max_sp INTEGER,
            scale_hp REAL DEFAULT 0, scale_str REAL DEFAULT 0,
            scale_def REAL DEFAULT 0, scale_int REAL DEFAULT 0,
            skills_csv TEXT, sprite TEXT,
            reward_credits INTEGER DEFAULT 0, is_boss INTEGER DEFAULT 0
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS skills (
            id TEXT PRIMARY KEY,
            sp_cost INTEGER DEFAULT 0, hp_cost REAL DEFAULT 0,
            type TEXT, power REAL DEFAULT 1.0, hits INTEGER DEFAULT 1,
            effect TEXT, duration INTEGER DEFAULT 0,
            is_magic INTEGER DEFAULT 0, is_penetrating INTEGER DEFAULT 0,
            bonus_on_status TEXT, revive INTEGER DEFAULT 0,
            target TEXT, desc TEXT
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY, name TEXT,
            price INTEGER DEFAULT 0, tier INTEGER DEFAULT 1, slot TEXT,
            stats_json TEXT, grant_skill TEXT,
            replace_skill_target TEXT, replace_skill_new TEXT, desc TEXT
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS quests (
            id TEXT PRIMARY KEY, title TEXT, desc TEXT,
            target_x INTEGER, target_y INTEGER,
            required_boss_id TEXT, reward_lv INTEGER DEFAULT 1,
            completed INTEGER DEFAULT 0
        );
    ]])

    -- story: 챕터 및 이벤트
    DBManager.query([[DROP TABLE IF EXISTS story_chapters;]])
    DBManager.query([[DROP TABLE IF EXISTS story_events;]])
    DBManager.query([[DROP TABLE IF EXISTS story_choices;]])

    DBManager.query([[
        CREATE TABLE IF NOT EXISTS story_chapters (
            id INTEGER PRIMARY KEY,
            chapter_order INTEGER,
            trigger_type TEXT,
            trigger_id TEXT DEFAULT '',
            title TEXT
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS story_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            chapter_id INTEGER,
            event_order INTEGER,
            speaker TEXT,
            portrait TEXT DEFAULT '',
            side TEXT DEFAULT 'left',
            text TEXT,
            is_choice_node INTEGER DEFAULT 0
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS story_choices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER,
            choice_order INTEGER,
            text TEXT,
            actions_json TEXT DEFAULT '[]'
        );
    ]])
    DBManager.query([[
        CREATE TABLE IF NOT EXISTS generated_quests (
            id TEXT PRIMARY KEY,
            title TEXT,
            desc TEXT,
            boss_id TEXT,
            target_x INTEGER DEFAULT 5,
            target_y INTEGER DEFAULT 5,
            reward_lv INTEGER DEFAULT 1,
            completed INTEGER DEFAULT 0,
            created_at TEXT
        );
    ]])

    DBManager.seed()
end

-- ── 시드: Lua 데이터 → DB (테이블이 비어있을 때만) ──────────────────────────

function DBManager.seed()
    DBManager.seedMercs()
    DBManager.seedEnemies()
    DBManager.seedSkills()
    DBManager.seedItems()
    DBManager.seedQuests()
    DBManager.seedStoryChapters()
end

function DBManager.seedMercs()
    local count = DBManager.query("SELECT COUNT(*) as n FROM mercenaries")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_mercs_seed")
    for i, m in ipairs(src) do
        local skills_csv = table.concat(m.skills or {}, ",")
        local is_unlocked = (i == 1) and 1 or 0  -- merc_01(루나)만 초기 해금
        DBManager.query(string.format(
            [[INSERT OR IGNORE INTO mercenaries
              (id,name,class,level,exp,stat_points,skill_points,hp,max_hp,sp,max_sp,str,dex,int,con,agi,edg,skills_csv,sprite,specialization,is_unlocked)
              VALUES ('%s','%s','%s',%d,0,0,0,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,'%s','%s','',%d)]],
            esc(m.id), esc(m.name), esc(m.class), m.level or 1,
            m.hp, m.max_hp, m.sp, m.max_sp,
            m.str, m.dex, m.int or 0, m.con, m.agi, m.edg,
            esc(skills_csv), esc(m.sprite), is_unlocked
        ))
    end
    print("🌱 mercenaries seeded")
end

function DBManager.seedEnemies()
    local count = DBManager.query("SELECT COUNT(*) as n FROM enemies")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_enemy_seed")
    for id, e in pairs(src) do
        local scale = e.scale or {}
        DBManager.query(string.format(
            [[INSERT OR IGNORE INTO enemies VALUES ('%s','%s',%d,%d,%d,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.4f,'%s','%s',%d,%d)]],
            esc(id), esc(e.name),
            e.hp or 0, e.str or 0, e.def or 0, e.agi or 0, e.int or 0,
            e.sp or 0, e.sp or 0,
            scale.hp or 0, scale.str or 0, scale.def or 0, scale.int or 0,
            esc(table.concat(e.skills or {}, ",")),
            esc(e.sprite), e.reward_credits or 0, e.is_boss and 1 or 0
        ))
    end
    print("🌱 enemies seeded")
end

function DBManager.seedSkills()
    local count = DBManager.query("SELECT COUNT(*) as n FROM skills")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_skills_seed")
    for id, s in pairs(src) do
        DBManager.query(string.format(
            [[INSERT OR IGNORE INTO skills VALUES ('%s',%d,%.4f,'%s',%.4f,%d,'%s',%d,%d,%d,'%s',%d,'%s','%s')]],
            esc(id),
            s.sp or 0, s.hp_cost or 0,
            esc(s.type), s.power or 1.0, s.hits or 1,
            esc(s.effect), s.duration or 0,
            s.is_magic and 1 or 0, s.is_penetrating and 1 or 0,
            esc(s.bonus_on_status), s.revive and 1 or 0,
            esc(s.target), esc(s.desc)
        ))
    end
    print("🌱 skills seeded")
end

function DBManager.seedItems()
    local count = DBManager.query("SELECT COUNT(*) as n FROM items")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_items_seed")
    for id, it in pairs(src) do
        local rs = it.replace_skill or {}
        DBManager.query(string.format(
            [[INSERT OR IGNORE INTO items VALUES ('%s','%s',%d,%d,'%s','%s','%s','%s','%s','%s')]],
            esc(id), esc(it.name),
            it.price or 0, it.tier or 1, esc(it.slot),
            esc(json.encode(it.stats or {})),
            esc(it.grant_skill),
            esc(rs.target), esc(rs.new_skill),
            esc(it.desc)
        ))
    end
    print("🌱 items seeded")
end

function DBManager.seedQuests()
    local count = DBManager.query("SELECT COUNT(*) as n FROM quests")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_quests_seed")
    for _, q in ipairs(src) do
        local tc = q.target_coords or {}
        DBManager.query(string.format(
            [[INSERT OR IGNORE INTO quests VALUES ('%s','%s','%s',%d,%d,'%s',%d,0)]],
            esc(q.id), esc(q.title), esc(q.desc),
            tc.x or 0, tc.y or 0,
            esc(q.required_boss_id), q.reward_lv or 1
        ))
    end
    print("🌱 quests seeded")
end

-- ── 쿼리 실행 ─────────────────────────────────────────────────────────────────

function DBManager.query(sql)
    local db_path = "client/game_data.db"
    if not love.filesystem.getRealDirectory(db_path) then db_path = "game_data.db" end

    if sqlite3 and DBManager.db then
        local results = {}
        for row in DBManager.db:nrows(sql) do table.insert(results, row) end
        return results
    else
        local cmd = string.format("sqlite3 %s -json \"%s\"", db_path, sql:gsub('"', '\\"'))
        local handle = io.popen(cmd)
        local result_str = handle:read("*a")
        handle:close()
        if result_str and result_str ~= "" then
            local ok, data = pcall(json.decode, result_str)
            return ok and data or {}
        end
        return {}
    end
end

-- ── 헬퍼: 적 ─────────────────────────────────────────────────────────────────

function DBManager.getEnemyScaled(id, level)
    local res = DBManager.query(string.format("SELECT * FROM enemies WHERE id='%s' LIMIT 1", esc(id)))
    if not res or #res == 0 then return nil end
    local base = res[1]
    local lv = math.max(1, level or 1)

    local scaled = {}
    for k, v in pairs(base) do scaled[k] = v end

    scaled.max_hp = math.floor(base.hp  * (1 + (base.scale_hp  or 0) * (lv - 1)))
    scaled.hp     = scaled.max_hp
    scaled.str    = math.floor(base.str * (1 + (base.scale_str or 0) * (lv - 1)))
    scaled.def    = math.floor(base.def * (1 + (base.scale_def or 0) * (lv - 1)))
    if (base.scale_int or 0) > 0 then
        scaled.int = math.floor((base.int or 0) * (1 + base.scale_int * (lv - 1)))
    end
    scaled.max_sp = math.floor((base.sp or 30) * (1 + 0.05 * (lv - 1)))
    scaled.sp     = scaled.max_sp
    scaled.level  = lv

    -- skills_csv → skills 배열
    scaled.skills = {}
    for s in (base.skills_csv or ""):gmatch("([^,]+)") do
        table.insert(scaled.skills, s)
    end
    scaled.is_boss = base.is_boss == 1

    return scaled
end

-- ── 헬퍼: 스킬 ───────────────────────────────────────────────────────────────

local _skills_cache = nil
function DBManager.getSkillDict()
    if _skills_cache then return _skills_cache end
    local rows = DBManager.query("SELECT * FROM skills")
    _skills_cache = {}
    for _, row in ipairs(rows or {}) do
        _skills_cache[row.id] = {
            sp         = row.sp_cost,
            hp_cost    = row.hp_cost ~= 0 and row.hp_cost or nil,
            type       = row.type,
            power      = row.power,
            hits       = row.hits ~= 1 and row.hits or nil,
            effect     = row.effect ~= "" and row.effect or nil,
            duration   = row.duration ~= 0 and row.duration or nil,
            is_magic   = row.is_magic == 1 or nil,
            is_penetrating = row.is_penetrating == 1 or nil,
            bonus_on_status = row.bonus_on_status ~= "" and row.bonus_on_status or nil,
            revive     = row.revive == 1 or nil,
            target     = row.target ~= "" and row.target or nil,
            desc       = row.desc,
        }
    end
    return _skills_cache
end

-- ── 헬퍼: 아이템 ─────────────────────────────────────────────────────────────

local _items_cache = nil
function DBManager.getAllItems()
    if _items_cache then return _items_cache end
    local rows = DBManager.query("SELECT * FROM items")
    _items_cache = {}
    for _, row in ipairs(rows or {}) do
        local stats = {}
        if row.stats_json and row.stats_json ~= "" then
            local ok, parsed = pcall(json.decode, row.stats_json)
            if ok then stats = parsed end
        end
        local item = {
            id    = row.id,   name  = row.name,
            price = row.price, tier = row.tier, slot = row.slot,
            stats = stats,
            grant_skill = row.grant_skill ~= "" and row.grant_skill or nil,
            desc  = row.desc,
        }
        if row.replace_skill_target and row.replace_skill_target ~= "" then
            item.replace_skill = { target = row.replace_skill_target, new_skill = row.replace_skill_new }
        end
        _items_cache[row.id] = item
    end
    return _items_cache
end

-- ── 헬퍼: 퀘스트 ─────────────────────────────────────────────────────────────

function DBManager.getAllQuests()
    local rows = DBManager.query("SELECT * FROM quests")
    local result = {}
    for _, row in ipairs(rows or {}) do
        table.insert(result, {
            id              = row.id,
            title           = row.title,
            desc            = row.desc,
            target_coords   = { x = row.target_x, y = row.target_y },
            required_boss_id = row.required_boss_id,
            reward_lv       = row.reward_lv,
            completed       = row.completed == 1,
        })
    end
    return result
end

function DBManager.setQuestCompleted(quest_id, completed)
    DBManager.query(string.format(
        "UPDATE quests SET completed=%d WHERE id='%s'",
        completed and 1 or 0, esc(quest_id)
    ))
end

function DBManager.getAllMercs()
    local rows = DBManager.query("SELECT * FROM mercenaries")
    local result = {}
    for _, row in ipairs(rows or {}) do
        local m = {}
        for k, v in pairs(row) do m[k] = v end
        m.skills = {}
        for s in (row.skills_csv or ""):gmatch("([^,]+)") do table.insert(m.skills, s) end
        m.skill_levels = {}
        m.is_unlocked   = row.is_unlocked == 1
        m.formation     = row.formation_slot or "front"
        table.insert(result, m)
    end
    return result
end

function DBManager.setMercUnlocked(merc_id, unlocked)
    DBManager.query(string.format(
        "UPDATE mercenaries SET is_unlocked=%d WHERE id='%s'",
        unlocked and 1 or 0, esc(merc_id)
    ))
end

function DBManager.resetQuests()
    DBManager.query("UPDATE quests SET completed=0")
end

function DBManager.seedStoryChapters()
    local count = DBManager.query("SELECT COUNT(*) as n FROM story_chapters")
    if count and count[1] and (count[1].n or 0) > 0 then return end

    local src = require("data.data_story_seed")
    for _, ch in ipairs(src.chapters) do
        DBManager.query(string.format(
            "INSERT OR IGNORE INTO story_chapters (id, chapter_order, trigger_type, trigger_id, title) VALUES (%d,%d,'%s','%s','%s')",
            ch.id, ch.chapter_order, esc(ch.trigger_type), esc(ch.trigger_id or ""), esc(ch.title)
        ))
        for _, ev in ipairs(ch.events or {}) do
            DBManager.query(string.format(
                "INSERT INTO story_events (chapter_id, event_order, speaker, portrait, side, text, is_choice_node) VALUES (%d,%d,'%s','%s','%s','%s',%d)",
                ch.id, ev.order, esc(ev.speaker), esc(ev.portrait or ""), esc(ev.side or "left"), esc(ev.text), ev.is_choice_node and 1 or 0
            ))
            if ev.is_choice_node then
                -- last_insert_rowid()는 Shell-Mode에서 동작하지 않으므로 직접 조회
                local ev_row = DBManager.query(string.format(
                    "SELECT id FROM story_events WHERE chapter_id=%d AND event_order=%d",
                    ch.id, ev.order
                ))
                local ev_id = ev_row and ev_row[1] and ev_row[1].id
                if ev_id then
                    for _, ch_item in ipairs(ev.choices or {}) do
                        local json = require("lib.json")
                        DBManager.query(string.format(
                            "INSERT INTO story_choices (event_id, choice_order, text, actions_json) VALUES (%d,%d,'%s','%s')",
                            ev_id, ch_item.order, esc(ch_item.text), esc(json.encode(ch_item.actions or {}))
                        ))
                    end
                end
            end
        end
    end
    print("🌱 story_chapters seeded")
end

function DBManager.getChapterByTrigger(trigger_type, trigger_id)
    local rows
    if trigger_id and trigger_id ~= "" then
        rows = DBManager.query(string.format(
            "SELECT * FROM story_chapters WHERE trigger_type='%s' AND trigger_id='%s' LIMIT 1",
            esc(trigger_type), esc(trigger_id)
        ))
    else
        rows = DBManager.query(string.format(
            "SELECT * FROM story_chapters WHERE trigger_type='%s' LIMIT 1",
            esc(trigger_type)
        ))
    end
    return rows and rows[1] or nil
end

function DBManager.getChapterEvents(chapter_id)
    return DBManager.query(string.format(
        "SELECT * FROM story_events WHERE chapter_id=%d ORDER BY event_order ASC",
        chapter_id
    )) or {}
end

function DBManager.getChoicesForEvent(event_id)
    local rows = DBManager.query(string.format(
        "SELECT * FROM story_choices WHERE event_id=%d ORDER BY choice_order ASC",
        event_id
    )) or {}
    local json = require("lib.json")
    for _, row in ipairs(rows) do
        local ok, decoded = pcall(json.decode, row.actions_json or "[]")
        row.actions = ok and decoded or {}
    end
    return rows
end

function DBManager.getGeneratedQuests()
    local rows = DBManager.query("SELECT * FROM generated_quests WHERE completed=0 ORDER BY created_at DESC") or {}
    return rows
end

function DBManager.insertGeneratedQuest(q)
    DBManager.query(string.format(
        "INSERT OR REPLACE INTO generated_quests (id,title,desc,boss_id,target_x,target_y,reward_lv,completed,created_at) VALUES ('%s','%s','%s','%s',%d,%d,%d,0,'%s')",
        esc(q.id), esc(q.title), esc(q.desc), esc(q.boss_id),
        q.target_x or 5, q.target_y or 5, q.reward_lv or 1,
        esc(os.date and os.date("%Y-%m-%d %H:%M:%S") or "")
    ))
end

return DBManager
