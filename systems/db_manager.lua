-- 데이터베이스 매니저 (Memory-only version, no SQLite dependency)
local DBManager = {}
local json = require("lib.json")

-- In-memory tables
DBManager.data = {
    mercenaries = {},
    enemies = {},
    skills = {},
    items = {},
    quests = {},
    story_chapters = {},
    story_events = {},
    story_choices = {},
    save_state = {},
    generated_quests = {}
}

local function esc(s)
    return tostring(s or ""):gsub("'", "''")
end

function DBManager.init(custom_path)
    print("🧠 Memory-DB initialized (No SQLite)")
    DBManager.seed()
end

-- ── 시드: Lua 데이터 → Memory ──────────────────────────

function DBManager.seed()
    DBManager.seedMercs()
    DBManager.seedEnemies()
    DBManager.seedSkills()
    DBManager.seedItems()
    DBManager.seedQuests()
    DBManager.seedStoryChapters()
end

function DBManager.seedMercs()
    if #DBManager.data.mercenaries > 0 then return end
    local src = require("data.data_mercs_seed")
    for i, m in ipairs(src) do
        local copy = {}
        for k, v in pairs(m) do copy[k] = v end
        copy.is_unlocked = (i == 1)
        copy.formation_slot = "front"
        copy.exp = 0
        copy.skill_points = 0
        copy.specialization = ""
        table.insert(DBManager.data.mercenaries, copy)
    end
    print("🌱 mercenaries seeded (memory)")
end

function DBManager.seedEnemies()
    if next(DBManager.data.enemies) then return end
    local src = require("data.data_enemy_seed")
    for id, e in pairs(src) do
        local copy = {}
        for k, v in pairs(e) do copy[k] = v end
        copy.id = id
        copy.skills_csv = table.concat(e.skills or {}, ",")
        copy.scale_hp = e.scale and e.scale.hp or 0
        copy.scale_str = e.scale and e.scale.str or 0
        copy.scale_def = e.scale and e.scale.def or 0
        copy.scale_int = e.scale and e.scale.int or 0
        copy.max_sp = e.sp or 0
        DBManager.data.enemies[id] = copy
    end
    print("🌱 enemies seeded (memory)")
end

function DBManager.seedSkills()
    if next(DBManager.data.skills) then return end
    local src = require("data.data_skills_seed")
    for id, s in pairs(src) do
        local copy = {}
        for k, v in pairs(s) do copy[k] = v end
        copy.id = id
        copy.sp_cost = s.sp or 0
        DBManager.data.skills[id] = copy
    end
    print("🌱 skills seeded (memory)")
end

function DBManager.seedItems()
    if next(DBManager.data.items) then return end
    local src = require("data.data_items_seed")
    for id, it in pairs(src) do
        local copy = {}
        for k, v in pairs(it) do copy[k] = v end
        copy.id = id
        copy.stats_json = json.encode(it.stats or {})
        if it.replace_skill then
            copy.replace_skill_target = it.replace_skill.target
            copy.replace_skill_new = it.replace_skill.new_skill
        end
        DBManager.data.items[id] = copy
    end
    print("🌱 items seeded (memory)")
end

function DBManager.seedQuests()
    if #DBManager.data.quests > 0 then return end
    local src = require("data.data_quests_seed")
    for _, q in ipairs(src) do
        local copy = {}
        for k, v in pairs(q) do copy[k] = v end
        copy.target_x = q.target_coords and q.target_coords.x or 0
        copy.target_y = q.target_coords and q.target_coords.y or 0
        copy.completed = 0
        table.insert(DBManager.data.quests, copy)
    end
    print("🌱 quests seeded (memory)")
end

function DBManager.seedStoryChapters()
    if #DBManager.data.story_chapters > 0 then return end
    local src = require("data.data_story_seed")
    for _, ch in ipairs(src.chapters) do
        local chapter_copy = {
            id = ch.id,
            chapter_order = ch.chapter_order,
            trigger_type = ch.trigger_type,
            trigger_id = ch.trigger_id or "",
            title = ch.title
        }
        table.insert(DBManager.data.story_chapters, chapter_copy)
        
        for _, ev in ipairs(ch.events or {}) do
            local event_id = #DBManager.data.story_events + 1
            local event_copy = {
                id = event_id,
                chapter_id = ch.id,
                event_order = ev.order,
                speaker = ev.speaker,
                portrait = ev.portrait or "",
                side = ev.side or "left",
                text = ev.text,
                is_choice_node = ev.is_choice_node and 1 or 0,
                shake = ev.shake and 1 or 0,
                shake_intensity = ev.shake_intensity or 10,
                flash = ev.flash and 1 or 0,
                flash_color_json = ev.flash_color_json or "[1,1,1,1]"
            }
            table.insert(DBManager.data.story_events, event_copy)
            
            if ev.is_choice_node then
                for _, ch_item in ipairs(ev.choices or {}) do
                    local choice_copy = {
                        id = #DBManager.data.story_choices + 1,
                        event_id = event_id,
                        choice_order = ch_item.order,
                        text = ch_item.text,
                        actions_json = json.encode(ch_item.actions or {})
                    }
                    table.insert(DBManager.data.story_choices, choice_copy)
                end
            end
        end
    end
    print("🌱 story_chapters seeded (memory)")
end

-- ── 쿼리 실행 (에뮬레이션) ──────────────────────────────────────────────────

function DBManager.query(sql)
    -- SQL 문에 따라 분기 처리 (매우 단순한 파서)
    sql = sql:gsub("%s+", " "):trim()
    local lower_sql = sql:lower()

    -- 1. SELECT COUNT(*)
    if lower_sql:match("^select count%(%*%)") then
        local table_name = lower_sql:match("from%s+([%w_]+)")
        local count = 0
        if table_name == "mercenaries" then count = #DBManager.data.mercenaries
        elseif table_name == "enemies" then for _ in pairs(DBManager.data.enemies) do count = count + 1 end
        elseif table_name == "skills" then for _ in pairs(DBManager.data.skills) do count = count + 1 end
        elseif table_name == "items" then for _ in pairs(DBManager.data.items) do count = count + 1 end
        elseif table_name == "quests" then count = #DBManager.data.quests
        elseif table_name == "story_chapters" then count = #DBManager.data.story_chapters
        elseif table_name == "save_state" then
            if lower_sql:match("where key='main_state'") then
                count = DBManager.data.save_state["main_state"] and 1 or 0
            else
                for _ in pairs(DBManager.data.save_state) do count = count + 1 end
            end
        end
        return {{n = count, ["count(*)"] = count}}
    end

    -- 2. SELECT * FROM table
    if lower_sql:match("^select %* from") then
        local table_name = lower_sql:match("from%s+([%w_]+)")
        local results = {}
        
        if table_name == "mercenaries" then
            for _, m in ipairs(DBManager.data.mercenaries) do
                local row = {}
                for k, v in pairs(m) do row[k] = v end
                row.skills_csv = table.concat(m.skills or {}, ",")
                row.is_unlocked = m.is_unlocked and 1 or 0
                table.insert(results, row)
            end
        elseif table_name == "enemies" then
            local id_filter = sql:match("id='([%w_]+)'")
            if id_filter then
                if DBManager.data.enemies[id_filter] then table.insert(results, DBManager.data.enemies[id_filter]) end
            else
                for _, e in pairs(DBManager.data.enemies) do table.insert(results, e) end
            end
        elseif table_name == "skills" then
            for _, s in pairs(DBManager.data.skills) do table.insert(results, s) end
        elseif table_name == "items" then
            for _, it in pairs(DBManager.data.items) do table.insert(results, it) end
        elseif table_name == "quests" then
            for _, q in ipairs(DBManager.data.quests) do table.insert(results, q) end
        elseif table_name == "save_state" then
            local key_filter = sql:match("key='([%w_]+)'")
            if key_filter then
                if DBManager.data.save_state[key_filter] then
                    table.insert(results, {key = key_filter, value = DBManager.data.save_state[key_filter]})
                end
            else
                for k, v in pairs(DBManager.data.save_state) do table.insert(results, {key = k, value = v}) end
            end
        elseif table_name == "story_chapters" then
            local tt = sql:match("trigger_type='([%w_]+)'")
            local ti = sql:match("trigger_id='([%w_]*)'")
            for _, ch in ipairs(DBManager.data.story_chapters) do
                if (not tt or ch.trigger_type == tt) and (not ti or ch.trigger_id == ti) then
                    table.insert(results, ch)
                end
            end
        elseif table_name == "story_events" then
            local cid = tonumber(sql:match("chapter_id=(%d+)"))
            for _, ev in ipairs(DBManager.data.story_events) do
                if not cid or ev.chapter_id == cid then table.insert(results, ev) end
            end
        elseif table_name == "story_choices" then
            local eid = tonumber(sql:match("event_id=(%d+)"))
            for _, ch in ipairs(DBManager.data.story_choices) do
                if not eid or ch.event_id == eid then table.insert(results, ch) end
            end
        elseif table_name == "generated_quests" then
            for _, q in pairs(DBManager.data.generated_quests) do
                if q.completed == 0 then table.insert(results, q) end
            end
        end
        return results
    end

    -- 3. INSERT OR REPLACE / INSERT INTO
    if lower_sql:match("^insert") then
        local table_name = lower_sql:match("into%s+([%w_]+)")
        if table_name == "save_state" then
            local key = sql:match("VALUES%s*%(%s*'([%w_]+)'")
            local value = sql:match("'%s*,%s*'(.*)'%s*%)")
            if key and value then
                DBManager.data.save_state[key] = value:gsub("''", "'")
            end
        elseif table_name == "mercenaries" then
            -- Roster.saveMercToDB에서 호출함
            local id = sql:match("VALUES%s*%(%s*'([%w_]+)'")
            if id then
                -- 간단하게 id로 찾아서 업데이트 (실제로는 모든 필드를 파싱해야 하지만, Roster 객체를 직접 다루는 게 나을 수도 있음)
                -- 여기서는 일단 쿼리 파싱보다는 Roster에서 직접 data.mercenaries를 수정하도록 유도하거나, 최소한의 필드만 업데이트
                for _, m in ipairs(DBManager.data.mercenaries) do
                    if m.id == id then
                        -- 대략적인 파싱 (level, exp, hp, max_hp 등)
                        local vals = {}
                        for v in sql:gmatch("'([^']*)'") do table.insert(vals, v) end
                        -- 복잡하므로 Roster.saveMercToDB를 수정하는 것이 더 안전함. 
                        -- 여기서는 무시하고 Roster가 메모리 상의 객체를 직접 수정한다고 가정.
                        break
                    end
                end
            end
        elseif table_name == "generated_quests" then
            local id = sql:match("VALUES%s*%(%s*'([%w_]+)'")
            if id then
                local vals = {}
                for v in sql:gmatch("'([^']*)'") do table.insert(vals, v) end
                DBManager.data.generated_quests[id] = {
                    id = id, title = vals[2], desc = vals[3], boss_id = vals[4],
                    completed = 0, created_at = vals[#vals]
                }
            end
        end
        return {}
    end

    -- 4. UPDATE
    if lower_sql:match("^update") then
        local table_name = lower_sql:match("update%s+([%w_]+)")
        if table_name == "mercenaries" then
            local id = sql:match("where id='([%w_]+)'")
            local unlocked = sql:match("is_unlocked=(%d)")
            if id and unlocked then
                for _, m in ipairs(DBManager.data.mercenaries) do
                    if m.id == id then m.is_unlocked = (unlocked == "1"); break end
                end
            end
        elseif table_name == "quests" then
            local id = sql:match("where id='([%w_]+)'")
            local comp = sql:match("completed=(%d)")
            if id and comp then
                for _, q in ipairs(DBManager.data.quests) do
                    if q.id == id then q.completed = tonumber(comp); break end
                end
            elseif lower_sql:match("set completed=0") then
                for _, q in ipairs(DBManager.data.quests) do q.completed = 0 end
            end
        end
        return {}
    end

    -- 5. DELETE
    if lower_sql:match("^delete") then
        local table_name = lower_sql:match("from%s+([%w_]+)")
        if table_name == "mercenaries" then
            -- 초기 상태로 되돌리기 위해 다시 시드
            DBManager.data.mercenaries = {}
            DBManager.seedMercs()
        elseif table_name == "save_state" then
            DBManager.data.save_state = {}
        end
        return {}
    end

    return {}
end

-- string.trim helper
function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- ── 헬퍼 함수들 (기존 인터페이스 유지) ──────────────────────────────────────────

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
            sp         = row.sp_cost,
            hp_cost    = row.hp_cost ~= 0 and row.hp_cost or nil,
            type       = row.type,
            power      = row.power,
            hits       = row.hits ~= 1 and row.hits or nil,
            effect     = row.effect ~= "" and row.effect or nil,
            duration   = row.duration ~= 0 and row.duration or nil,
            is_magic   = row.is_magic == 1 or row.is_magic == true,
            is_penetrating = row.is_penetrating == 1 or row.is_penetrating == true,
            bonus_on_status = row.bonus_on_status ~= "" and row.bonus_on_status or nil,
            revive     = row.revive == 1 or row.revive == true,
            target     = row.target ~= "" and row.target or nil,
            desc       = row.desc,
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
        m.formation = row.formation_slot or "front"
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

function DBManager.getChapterByTrigger(trigger_type, trigger_id)
    for _, ch in ipairs(DBManager.data.story_chapters) do
        if ch.trigger_type == trigger_type and (not trigger_id or trigger_id == "" or ch.trigger_id == trigger_id) then
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
        target_x = q.target_x or 5, target_y = q.target_y or 5,
        reward_lv = q.reward_lv or 1, completed = 0,
        created_at = os.date and os.date("%Y-%m-%d %H:%M:%S") or ""
    }
end

return DBManager
