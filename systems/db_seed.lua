-- DB 시드 함수 모음 (db_manager.lua 서브 모듈)
local json = require("lib.json")
local DBSeed = {}

function DBSeed.install(DB)

    function DB.seedMercs()
        if #DB.data.mercenaries > 0 then return end
        local src = require("data.data_mercs_seed")
        for i, m in ipairs(src) do
            local copy = {}
            for k, v in pairs(m) do copy[k] = v end
            copy.is_unlocked = (i == 1)
            copy.formation_slot = "front"
            copy.exp = 0
            copy.skill_points = 0
            copy.specialization = ""
            table.insert(DB.data.mercenaries, copy)
        end
        print("🌱 mercenaries seeded (memory)")
    end

    function DB.seedEnemies()
        if next(DB.data.enemies) then return end
        local src = require("data.data_enemy_seed")
        for id, e in pairs(src) do
            local copy = {}
            for k, v in pairs(e) do copy[k] = v end
            copy.id = id
            copy.skills_csv = table.concat(e.skills or {}, ",")
            copy.scale_hp  = e.scale and e.scale.hp  or 0
            copy.scale_str = e.scale and e.scale.str or 0
            copy.scale_def = e.scale and e.scale.def or 0
            copy.scale_int = e.scale and e.scale.int or 0
            copy.max_sp = e.sp or 0
            DB.data.enemies[id] = copy
        end
        print("🌱 enemies seeded (memory)")
    end

    function DB.seedSkills()
        if next(DB.data.skills) then return end
        local src = require("data.data_skills_seed")
        for id, s in pairs(src) do
            local copy = {}
            for k, v in pairs(s) do copy[k] = v end
            copy.id = id
            copy.sp_cost = s.sp or 0
            DB.data.skills[id] = copy
        end
        print("🌱 skills seeded (memory)")
    end

    function DB.seedItems()
        if next(DB.data.items) then return end
        local src = require("data.data_items_seed")
        for id, it in pairs(src) do
            local copy = {}
            for k, v in pairs(it) do copy[k] = v end
            copy.id = id
            copy.stats_json = json.encode(it.stats or {})
            if it.replace_skill then
                copy.replace_skill_target = it.replace_skill.target
                copy.replace_skill_new    = it.replace_skill.new_skill
            end
            DB.data.items[id] = copy
        end
        print("🌱 items seeded (memory)")
    end

    function DB.seedQuests()
        if #DB.data.quests > 0 then return end
        local src = require("data.data_quests_seed")
        for _, q in ipairs(src) do
            local copy = {}
            for k, v in pairs(q) do copy[k] = v end
            copy.target_x = q.target_coords and q.target_coords.x or 0
            copy.target_y = q.target_coords and q.target_coords.y or 0
            copy.completed = 0
            table.insert(DB.data.quests, copy)
        end
        print("🌱 quests seeded (memory)")
    end

    function DB.seedStoryChapters()
        if #DB.data.story_chapters > 0 then return end
        local src = require("data.data_story_seed")
        for _, ch in ipairs(src.chapters) do
            local chapter_copy = {
                id            = ch.id,
                chapter_order = ch.chapter_order,
                trigger_type  = ch.trigger_type,
                trigger_id    = ch.trigger_id or "",
                title         = ch.title
            }
            table.insert(DB.data.story_chapters, chapter_copy)

            for _, ev in ipairs(ch.events or {}) do
                local event_id = #DB.data.story_events + 1
                local event_copy = {
                    id            = event_id,
                    chapter_id    = ch.id,
                    event_order   = ev.order,
                    speaker       = ev.speaker,
                    portrait      = ev.portrait or "",
                    side          = ev.side or "left",
                    text          = ev.text,
                    is_choice_node = ev.is_choice_node and 1 or 0,
                    shake         = ev.shake and 1 or 0,
                    shake_intensity = ev.shake_intensity or 10,
                    flash         = ev.flash and 1 or 0,
                    flash_color_json = ev.flash_color_json or "[1,1,1,1]"
                }
                table.insert(DB.data.story_events, event_copy)

                if ev.is_choice_node then
                    for _, ch_item in ipairs(ev.choices or {}) do
                        table.insert(DB.data.story_choices, {
                            id           = #DB.data.story_choices + 1,
                            event_id     = event_id,
                            choice_order = ch_item.order,
                            text         = ch_item.text,
                            actions_json = json.encode(ch_item.actions or {})
                        })
                    end
                end
            end
        end
        print("🌱 story_chapters seeded (memory)")
    end

end

return DBSeed
