-- 게임 통합 테스트 러너 (love client -- --test 로 실행)
-- 실제 DB, 실제 게임 시스템을 통해 처리하며 검증

local results = { pass = 0, fail = 0, errors = {} }

local function pass(name)
    results.pass = results.pass + 1
    print(string.format("  ✅ PASS  %s", name))
end

local function fail(name, reason)
    results.fail = results.fail + 1
    table.insert(results.errors, name .. ": " .. tostring(reason))
    print(string.format("  ❌ FAIL  %s  —  %s", name, tostring(reason)))
end

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        pass(name)
    else
        fail(name, err)
    end
end

local function assert_eq(a, b, msg)
    if a ~= b then
        error((msg or "") .. string.format(" (expected %s, got %s)", tostring(b), tostring(a)))
    end
end

local function assert_gt(a, b, msg)
    if not (a > b) then
        error((msg or "") .. string.format(" (expected > %s, got %s)", tostring(b), tostring(a)))
    end
end

local function assert_true(v, msg)
    if not v then error(msg or "expected true") end
end

-- ── 테스트 스위트 ─────────────────────────────────────────────────────────────

local function suite_db(DB)
    print("\n[ DB / 시딩 ]")

    test("mercenaries 테이블 — 8명 시드", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM mercenaries")
        assert_eq(rows[1].n, 8, "mercenaries count")
    end)

    test("merc_01(루나)만 is_unlocked=1", function()
        local rows = DB.query("SELECT id, is_unlocked FROM mercenaries ORDER BY id")
        local unlocked = {}
        for _, r in ipairs(rows) do
            if r.is_unlocked == 1 then table.insert(unlocked, r.id) end
        end
        assert_eq(#unlocked, 1, "unlocked count")
        assert_eq(unlocked[1], "merc_01", "unlocked id")
    end)

    test("enemies 테이블 — 1개 이상", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM enemies")
        assert_gt(rows[1].n, 0, "enemies count")
    end)

    test("skills 테이블 — 1개 이상", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM skills")
        assert_gt(rows[1].n, 0, "skills count")
    end)

    test("items 테이블 — 1개 이상", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM items")
        assert_gt(rows[1].n, 0, "items count")
    end)

    test("quests 테이블 — 1개 이상", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM quests")
        assert_gt(rows[1].n, 0, "quests count")
    end)

    test("용병 스킬 CSV 파싱 — merc_01 스킬 3개", function()
        local rows = DB.query("SELECT skills_csv FROM mercenaries WHERE id='merc_01'")
        local csv = rows[1].skills_csv
        local count = 0
        for _ in csv:gmatch("[^,]+") do count = count + 1 end
        assert_eq(count, 3, "skill count for merc_01")
    end)

    test("퀘스트 required_boss_id 실제 존재 여부 (메인 퀘스트)", function()
        -- 플레이스홀더 ID(대문자)는 미래 콘텐츠이므로 소문자 ID만 검사
        local quests = DB.query("SELECT required_boss_id FROM quests WHERE required_boss_id != ''")
        for _, q in ipairs(quests) do
            local bid = q.required_boss_id
            if bid == bid:lower() then  -- 소문자 ID = 구현된 보스
                local res = DB.query(string.format(
                    "SELECT COUNT(*) as n FROM enemies WHERE id='%s'", bid))
                if res[1].n == 0 then
                    error("boss not found: " .. bid)
                end
            end
        end
    end)
end

local function suite_roster(DB, Roster)
    print("\n[ 로스터 ]")

    test("init() — pool에 8명", function()
        Roster.init()
        assert_eq(#Roster.pool, 8, "pool size")
    end)

    test("init() — active_party에 루나만", function()
        assert_eq(#Roster.active_party, 1, "party size")
        assert_eq(Roster.active_party[1].id, "merc_01", "party[1] id")
    end)

    test("is_unlocked 정확도 — merc_01만 true", function()
        local unlocked = 0
        for _, m in ipairs(Roster.pool) do
            if m.is_unlocked then unlocked = unlocked + 1 end
        end
        assert_eq(unlocked, 1, "unlocked count after init")
    end)

    test("unlockMerc('merc_02') — 해금 및 파티 합류", function()
        Roster.unlockMerc("merc_02")
        local found = false
        for _, m in ipairs(Roster.active_party) do
            if m.id == "merc_02" then found = true; break end
        end
        assert_true(found, "merc_02 should be in party")
    end)

    test("DB setMercUnlocked 반영 확인", function()
        local rows = DB.query("SELECT is_unlocked FROM mercenaries WHERE id='merc_02'")
        assert_eq(rows[1].is_unlocked, 1, "merc_02 is_unlocked in DB")
    end)

    test("toggleMerc — 파티 추가/제거", function()
        -- merc_03 해금 (unlockMerc은 자동으로 파티 합류시킴)
        Roster.unlockMerc("merc_03")
        -- 파티에서 제거 후 재추가 테스트
        local before_remove = #Roster.active_party
        Roster.toggleMerc("merc_03")  -- 제거
        assert_eq(#Roster.active_party, before_remove - 1, "toggle remove")
        Roster.toggleMerc("merc_03")  -- 재추가
        assert_eq(#Roster.active_party, before_remove, "toggle re-add")
    end)
end

local function suite_progression(Prog, DB, Roster)
    print("\n[ 레벨업 / EXP ]")

    test("expNeeded(1) == 100", function()
        assert_eq(Prog.expNeeded(1), 100)
    end)

    test("expNeeded(5) == 500", function()
        assert_eq(Prog.expNeeded(5), 500)
    end)

    test("gainExp — 레벨업 발생", function()
        Roster.init()
        local luna = Roster.active_party[1]
        local old_lv = luna.level
        Prog.gainExp(Roster.active_party, 100)
        assert_eq(luna.level, old_lv + 1, "level after gainExp(100)")
    end)

    test("gainExp — EXP 잔여량 정확", function()
        Roster.init()
        local luna = Roster.active_party[1]
        Prog.gainExp(Roster.active_party, 150)  -- 150 - 100 = 50 남음
        assert_eq(luna.exp, 50, "leftover exp")
    end)

    test("levelUp — stat_points +5, skill_points +1", function()
        Roster.init()
        local luna = Roster.active_party[1]
        local sp_before = luna.stat_points
        local skp_before = luna.skill_points
        Prog.levelUp(Roster.active_party)
        assert_eq(luna.stat_points, sp_before + 5, "stat_points")
        assert_eq(luna.skill_points, skp_before + 1, "skill_points")
    end)

    test("investStat — STR +1 반영", function()
        Roster.init()
        local luna = Roster.active_party[1]
        Prog.levelUp(Roster.active_party)  -- stat_points 확보
        local old_str = luna.str
        Prog.investStat(luna, "str")
        assert_eq(luna.str, old_str + 1, "str after invest")
    end)

    test("Lv.5 도달 시 can_promote 활성화", function()
        Roster.init()
        local luna = Roster.active_party[1]
        for i = 1, 4 do Prog.levelUp(Roster.active_party) end
        assert_true(luna.can_promote, "can_promote at lv5")
    end)
end

local function suite_enemy(DB)
    print("\n[ 적 스케일링 ]")

    test("getEnemyScaled — 레벨 1 기본", function()
        local e = DB.getEnemyScaled("drone_security", 1)
        assert_true(e ~= nil, "enemy exists")
        assert_gt(e.max_hp, 0, "max_hp > 0")
        assert_eq(e.level, 1, "level")
    end)

    test("getEnemyScaled — 레벨 5 HP 증가", function()
        local e1 = DB.getEnemyScaled("drone_security", 1)
        local e5 = DB.getEnemyScaled("drone_security", 5)
        if e1 and e5 and (e1.scale_hp or 0) > 0 then
            assert_gt(e5.max_hp, e1.max_hp, "hp scaling")
        end
    end)

    test("skills_csv → skills 배열 변환", function()
        local e = DB.getEnemyScaled("drone_security", 1)
        assert_true(type(e.skills) == "table", "skills is table")
    end)
end

local function suite_combat(DB, Roster, Prog)
    print("\n[ 전투 시뮬레이션 ]")

    test("Actor 생성 — 용병", function()
        Roster.init()
        local Actor = require("systems.combat_actor")
        local luna = Roster.active_party[1]
        local actor = Actor.new(luna, true)
        assert_gt(actor.max_hp, 0, "actor.max_hp")
        assert_true(actor.is_player, "is_player")
    end)

    test("Actor 생성 — 적", function()
        local enemy_data = DB.getEnemyScaled("drone_security", 1)
        local Actor = require("systems.combat_actor")
        local actor = Actor.new(enemy_data, false)
        assert_gt(actor.max_hp, 0, "enemy max_hp")
    end)

    test("데미지 계산 — 양수", function()
        Roster.init()
        local Actor = require("systems.combat_actor")
        local luna_actor = Actor.new(Roster.active_party[1], true)
        local enemy_data = DB.getEnemyScaled("drone_security", 1)
        local enemy_actor = Actor.new(enemy_data, false)
        local dmg = luna_actor:calculateDamage(1.0)
        assert_gt(dmg, 0, "damage > 0")
    end)

    test("takeDamage — HP 감소", function()
        local Actor = require("systems.combat_actor")
        local enemy_data = DB.getEnemyScaled("drone_security", 1)
        local enemy_actor = Actor.new(enemy_data, false)
        local before = enemy_actor.hp
        enemy_actor:takeDamage(20, true, false)
        assert_true(enemy_actor.hp <= before, "hp decreased")
    end)

    test("상태이상 addEffect / hasEffect", function()
        local Actor = require("systems.combat_actor")
        local enemy_data = DB.getEnemyScaled("drone_security", 1)
        local actor = Actor.new(enemy_data, false)
        actor:addEffect("stun", 2)
        assert_true(actor:hasEffect("stun"), "has stun")
    end)
end

local function suite_inventory(DB)
    print("\n[ 인벤토리 / 상점 ]")

    test("items DB 직접 count", function()
        local rows = DB.query("SELECT COUNT(*) as n FROM items")
        assert_gt(rows[1].n, 0, "items in DB")
    end)

    test("getAllItems — 1개 이상", function()
        -- 캐시 초기화 후 재조회
        local items = DB.getAllItems()
        local count = 0
        for _ in pairs(items) do count = count + 1 end
        assert_gt(count, 0, "getAllItems count")
    end)

    test("buyItem — 크레딧 차감 및 stash 추가", function()
        local Inventory = require("systems.inventory")
        local Roster = require("systems.roster")
        Roster.init()
        Inventory.init(Roster.active_party)
        Inventory.credits = 9999
        Inventory.stash = {}

        local items = DB.getAllItems()
        local first_item
        for _, it in pairs(items) do first_item = it; break end

        assert_true(first_item ~= nil, "items not empty for buy test")
        local before = Inventory.credits
        Inventory.buyItem(first_item)
        assert_eq(Inventory.credits, before - first_item.price, "credits after buy")
        assert_eq(#Inventory.stash, 1, "stash size")
    end)
end

local function suite_save(DB)
    print("\n[ 세이브 / 로드 ]")

    test("save() — save_state 레코드 생성", function()
        local SaveManager = require("systems.save_manager")
        local Roster = require("systems.roster")
        Roster.init()
        local ok = SaveManager.save()
        assert_true(ok, "save returned true")
        local rows = DB.query("SELECT COUNT(*) as n FROM save_state WHERE key='main_state'")
        assert_eq(rows[1].n, 1, "save_state exists")
    end)

    test("load() — 세이브 복구 성공", function()
        -- save_state 레코드 직접 확인
        local row = DB.query("SELECT value FROM save_state WHERE key='main_state' LIMIT 1")
        assert_true(row and #row > 0, "save_state record exists")
        local SaveManager = require("systems.save_manager")
        local ok = SaveManager.load()
        assert_true(ok, "load returned true")
    end)

    test("resetQuests() — 모든 퀘스트 미완료로 초기화", function()
        DB.query("UPDATE quests SET completed=1")
        DB.resetQuests()
        local rows = DB.query("SELECT COUNT(*) as n FROM quests WHERE completed=1")
        assert_eq(rows[1].n, 0, "all quests reset")
    end)
end

-- ── 진입점 ────────────────────────────────────────────────────────────────────

function love.load()
    -- 의존하는 전역 함수 설정
    require("systems.i18n").setLanguage("ko")

    -- DB 초기화
    local DB = require("systems.db_manager")
    DB.init()

    -- 테스트 격리: 용병 DB를 항상 초기 시드 상태로 리셋
    DB.query("DELETE FROM mercenaries")
    DB.seedMercs()

    local Roster = require("systems.roster")
    local Prog   = require("systems.progression")

    print("\n════════════════════════════════════")
    print("  SECTOR 07 — 자동 통합 테스트")
    print("════════════════════════════════════")

    suite_db(DB)
    suite_roster(DB, Roster)
    suite_progression(Prog, DB, Roster)
    suite_enemy(DB)
    suite_combat(DB, Roster, Prog)
    suite_inventory(DB)
    suite_save(DB)

    print("\n════════════════════════════════════")
    print(string.format("  결과: ✅ %d PASS  /  ❌ %d FAIL", results.pass, results.fail))
    if #results.errors > 0 then
        print("\n  실패 목록:")
        for _, e in ipairs(results.errors) do print("  • " .. e) end
    end
    print("════════════════════════════════════\n")

    love.event.quit(results.fail > 0 and 1 or 0)
end

-- 테스트 모드에서는 update/draw 불필요
function love.update() end
function love.draw() end
