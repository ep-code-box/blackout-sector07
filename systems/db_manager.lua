-- 데이터베이스 매니저 (Memory-only, 서브 모듈 분리 버전)
local json   = require("lib.json")
local DBSeed  = require("systems.db_seed")
local DBQuery = require("systems.db_query")

local DBManager = {}

-- In-memory tables
DBManager.data = {
    mercenaries    = {},
    enemies        = {},
    skills         = {},
    items          = {},
    quests         = {},
    story_chapters = {},
    story_events   = {},
    story_choices  = {},
    save_state     = {},
    generated_quests = {}
}

-- 서브 모듈에서 함수 설치
DBSeed.install(DBManager)
DBQuery.install(DBManager)

function DBManager.init(custom_path)
    print("🧠 Memory-DB initialized (No SQLite)")
    DBManager.seed()
end

function DBManager.seed()
    DBManager.seedMercs()
    DBManager.seedEnemies()
    DBManager.seedSkills()
    DBManager.seedItems()
    DBManager.seedQuests()
    DBManager.seedStoryChapters()
end

-- ── 헬퍼 함수들 ────────────────────────────────────────────────────────────

function DBManager.getEnemyScaled(id, level)
    local base = DBManager.data.enemies[id]
    if not base then return nil end
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
    scaled.skills = {}
    for s in (base.skills_csv or ""):gmatch("([^,]+)") do
        table.insert(scaled.skills, s)
    end
    scaled.is_boss = base.is_boss == 1 or base.is_boss == true
    return scaled
end

function DBManager.getSkillDict()
    local dict = {}
    for id, row in pairs(DBManager.data.skills) do
        dict[id] = {
            sp              = row.sp_cost,
            hp_cost         = row.hp_cost ~= 0 and row.hp_cost or nil,
            type            = row.type,
            power           = row.power,
            hits            = row.hits ~= 1 and row.hits or nil,
            effect          = row.effect ~= "" and row.effect or nil,
            duration        = row.duration ~= 0 and row.duration or nil,
            is_magic        = row.is_magic == 1 or row.is_magic == true,
            is_penetrating  = row.is_penetrating == 1 or row.is_penetrating == true,
            bonus_on_status = row.bonus_on_status ~= "" and row.bonus_on_status or nil,
            revive          = row.revive == 1 or row.revive == true,
            target          = row.target ~= "" and row.target or nil,
            desc            = row.desc,
        }
    end
    return dict
end

function DBManager.getAllItems()
    local dict = {}
    for id, row in pairs(DBManager.data.items) do
        local stats = {}
        if row.stats_json and row.stats_json ~= "" then
            pcall(function() stats = json.decode(row.stats_json) end)
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
        dict[id] = item
    end
    return dict
end

function DBManager.getAllQuests()
    local result = {}
    for _, row in ipairs(DBManager.data.quests) do
        table.insert(result, {
            id               = row.id,
            title            = row.title,
            desc             = row.desc,
            target_coords    = { x = row.target_x, y = row.target_y },
            required_boss_id = row.required_boss_id,
            reward_lv        = row.reward_lv,
            completed        = row.completed == 1,
        })
    end
    return result
end

function DBManager.setQuestCompleted(quest_id, completed)
    for _, q in ipairs(DBManager.data.quests) do
        if q.id == quest_id then q.completed = completed and 1 or 0; break end
    end
end

function DBManager.getAllMercs()
    local result = {}
    for _, row in ipairs(DBManager.data.mercenaries) do
        local m = {}
        for k, v in pairs(row) do m[k] = v end
        if row.skills_csv then
            m.skills = {}
            for s in row.skills_csv:gmatch("([^,]+)") do table.insert(m.skills, s) end
        end
        m.is_unlocked = (row.is_unlocked == 1 or row.is_unlocked == true)
        m.formation   = row.formation_slot or "front"
        table.insert(result, m)
    end
    return result
end

function DBManager.setMercUnlocked(merc_id, unlocked)
    for _, m in ipairs(DBManager.data.mercenaries) do
        if m.id == merc_id then m.is_unlocked = unlocked; break end
    end
end

function DBManager.resetQuests()
    for _, q in ipairs(DBManager.data.quests) do q.completed = 0 end
end

function DBManager.getChapterByOrder(order)
    for _, ch in ipairs(DBManager.data.story_chapters) do
        if ch.chapter_order == order then return ch end
    end
    return nil
end

function DBManager.getChapterByTrigger(trigger_type, trigger_id, shown_ids)
    for _, ch in ipairs(DBManager.data.story_chapters) do
        local id_match  = (not trigger_id or trigger_id == "" or ch.trigger_id == trigger_id)
        local not_shown = (not shown_ids or not shown_ids[ch.id])
        if ch.trigger_type == trigger_type and id_match and not_shown then
            return ch
        end
    end
    return nil
end

function DBManager.getChapterEvents(chapter_id)
    local result = {}
    for _, ev in ipairs(DBManager.data.story_events) do
        if ev.chapter_id == chapter_id then table.insert(result, ev) end
    end
    table.sort(result, function(a, b) return a.event_order < b.event_order end)
    return result
end

function DBManager.getChoicesForEvent(event_id)
    local result = {}
    for _, row in ipairs(DBManager.data.story_choices) do
        if row.event_id == event_id then
            local choice = {}
            for k, v in pairs(row) do choice[k] = v end
            local ok, decoded = pcall(json.decode, row.actions_json or "[]")
            choice.actions = ok and decoded or {}
            table.insert(result, choice)
        end
    end
    table.sort(result, function(a, b) return a.choice_order < b.choice_order end)
    return result
end

function DBManager.getGeneratedQuests()
    local result = {}
    for _, q in pairs(DBManager.data.generated_quests) do
        if q.completed == 0 then table.insert(result, q) end
    end
    return result
end

function DBManager.insertGeneratedQuest(q)
    DBManager.data.generated_quests[q.id] = {
        id = q.id, title = q.title, desc = q.desc, boss_id = q.boss_id,
        target_x  = q.target_x or 5, target_y = q.target_y or 5,
        reward_lv = q.reward_lv or 1, completed = 0,
        created_at = os.date and os.date("%Y-%m-%d %H:%M:%S") or ""
    }
end

return DBManager
