-- DB SQL 에뮬레이터 (db_manager.lua 서브 모듈)
local DBQuery = {}

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function DBQuery.install(DB)

    function DB.query(sql)
        sql = sql:gsub("%s+", " "):trim()
        local lower_sql = sql:lower()

        -- 1. SELECT COUNT(*)
        if lower_sql:match("^select count%(%*%)") then
            local table_name = lower_sql:match("from%s+([%w_]+)")
            local count = 0
            if table_name == "mercenaries" then
                count = #DB.data.mercenaries
            elseif table_name == "enemies" then
                for _ in pairs(DB.data.enemies) do count = count + 1 end
            elseif table_name == "skills" then
                for _ in pairs(DB.data.skills) do count = count + 1 end
            elseif table_name == "items" then
                for _ in pairs(DB.data.items) do count = count + 1 end
            elseif table_name == "quests" then
                count = #DB.data.quests
            elseif table_name == "story_chapters" then
                count = #DB.data.story_chapters
            elseif table_name == "save_state" then
                if lower_sql:match("where key='main_state'") then
                    count = DB.data.save_state["main_state"] and 1 or 0
                else
                    for _ in pairs(DB.data.save_state) do count = count + 1 end
                end
            end
            return {{n = count, ["count(*)"] = count}}
        end

        -- 2. SELECT * FROM table
        if lower_sql:match("^select %* from") then
            local table_name = lower_sql:match("from%s+([%w_]+)")
            local results = {}

            if table_name == "mercenaries" then
                for _, m in ipairs(DB.data.mercenaries) do
                    local row = {}
                    for k, v in pairs(m) do row[k] = v end
                    row.skills_csv  = table.concat(m.skills or {}, ",")
                    row.is_unlocked = m.is_unlocked and 1 or 0
                    table.insert(results, row)
                end
            elseif table_name == "enemies" then
                local id_filter = sql:match("id='([%w_]+)'")
                if id_filter then
                    if DB.data.enemies[id_filter] then
                        table.insert(results, DB.data.enemies[id_filter])
                    end
                else
                    for _, e in pairs(DB.data.enemies) do table.insert(results, e) end
                end
            elseif table_name == "skills" then
                for _, s in pairs(DB.data.skills) do table.insert(results, s) end
            elseif table_name == "items" then
                for _, it in pairs(DB.data.items) do table.insert(results, it) end
            elseif table_name == "quests" then
                for _, q in ipairs(DB.data.quests) do table.insert(results, q) end
            elseif table_name == "save_state" then
                local key_filter = sql:match("key='([%w_]+)'")
                if key_filter then
                    if DB.data.save_state[key_filter] then
                        table.insert(results, {key = key_filter, value = DB.data.save_state[key_filter]})
                    end
                else
                    for k, v in pairs(DB.data.save_state) do
                        table.insert(results, {key = k, value = v})
                    end
                end
            elseif table_name == "story_chapters" then
                local tt = sql:match("trigger_type='([%w_]+)'")
                local ti = sql:match("trigger_id='([%w_]*)'")
                for _, ch in ipairs(DB.data.story_chapters) do
                    if (not tt or ch.trigger_type == tt) and (not ti or ch.trigger_id == ti) then
                        table.insert(results, ch)
                    end
                end
            elseif table_name == "story_events" then
                local cid = tonumber(sql:match("chapter_id=(%d+)"))
                for _, ev in ipairs(DB.data.story_events) do
                    if not cid or ev.chapter_id == cid then table.insert(results, ev) end
                end
            elseif table_name == "story_choices" then
                local eid = tonumber(sql:match("event_id=(%d+)"))
                for _, ch in ipairs(DB.data.story_choices) do
                    if not eid or ch.event_id == eid then table.insert(results, ch) end
                end
            elseif table_name == "generated_quests" then
                for _, q in pairs(DB.data.generated_quests) do
                    if q.completed == 0 then table.insert(results, q) end
                end
            end
            return results
        end

        -- 3. INSERT OR REPLACE / INSERT INTO
        if lower_sql:match("^insert") then
            local table_name = lower_sql:match("into%s+([%w_]+)")
            if table_name == "save_state" then
                local key   = sql:match("VALUES%s*%(%s*'([%w_]+)'")
                local value = sql:match("'%s*,%s*'(.*)'%s*%)")
                if key and value then
                    DB.data.save_state[key] = value:gsub("''", "'")
                end
            elseif table_name == "generated_quests" then
                local id = sql:match("VALUES%s*%(%s*'([%w_]+)'")
                if id then
                    local vals = {}
                    for v in sql:gmatch("'([^']*)'") do table.insert(vals, v) end
                    DB.data.generated_quests[id] = {
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
                local id       = sql:match("where id='([%w_]+)'")
                local unlocked = sql:match("is_unlocked=(%d)")
                if id and unlocked then
                    for _, m in ipairs(DB.data.mercenaries) do
                        if m.id == id then m.is_unlocked = (unlocked == "1"); break end
                    end
                end
            elseif table_name == "quests" then
                local id   = sql:match("where id='([%w_]+)'")
                local comp = sql:match("completed=(%d)")
                if id and comp then
                    for _, q in ipairs(DB.data.quests) do
                        if q.id == id then q.completed = tonumber(comp); break end
                    end
                elseif lower_sql:match("set completed=0") then
                    for _, q in ipairs(DB.data.quests) do q.completed = 0 end
                end
            end
            return {}
        end

        -- 5. DELETE
        if lower_sql:match("^delete") then
            local table_name = lower_sql:match("from%s+([%w_]+)")
            if table_name == "mercenaries" then
                DB.data.mercenaries = {}
                DB.seedMercs()
            elseif table_name == "save_state" then
                DB.data.save_state = {}
            end
            return {}
        end

        return {}
    end

end

return DBQuery
