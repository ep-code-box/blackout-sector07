-- 전투 상태 모듈 (SkillHandler & EnemyAI 분리 V3)
local StateCombat = {}
local UICombat    = require("ui.combat")
local DBManager   = require("systems.db_manager")
local Actor       = require("systems.combat_actor")
local ShaderManager = require("systems.shader_manager")
local AssetManager  = require("systems.asset_manager")
local AudioManager  = require("systems.audio_manager")
local shack         = require("lib.shack")

-- 신규 서브 모듈
local SkillHandler  = require("states.combat.skill_handler")
local EnemyAI       = require("states.combat.enemy_ai")

local party_actors = {}
local enemy_actor  = nil
local enemy_sprite, bg_image
local selected_menu, current_turn = 1, 1

-- 죽은 파티원을 건너뛰어 첫 번째 살아있는 액터로 이동.
-- current_turn을 직접 수정하며, 전멸 시 false 반환.
local function advanceToAliveActor()
    while current_turn <= #party_actors do
        local c = party_actors[current_turn]
        if c and c.hp > 0 then return true end
        print("E2E_HOOK: DEAD_ACTOR_SKIPPED:" .. (c and c.id or "?"))
        current_turn = current_turn + 1
    end
    return false  -- 살아있는 파티원 없음
end
local log_msg = ""
local is_battle_over = false
local battle_result = nil
local combat_timer, shake_timer, flash_alpha = 0, 0, 0
local SkillsDB = nil -- load 시점에 초기화

function StateCombat.load(enemy_id, level)
    local Roster = require("systems.roster")
    SkillsDB = DBManager.getSkillDict()
    party_actors = {}
    for _, data in ipairs(Roster.getOrderedParty()) do
        local actor = Actor.new(data, true)
        if actor.data.perks and actor.data.perks["perk_con_20"] then
            actor.barrier = math.floor(actor.max_hp * 0.2)
        end
        table.insert(party_actors, actor)
    end

    local enemy_data = DBManager.getEnemyScaled(enemy_id or "drone_security", level or 1)
    enemy_actor = Actor.new(enemy_data, false)
    enemy_sprite = AssetManager.loadImage(enemy_data.sprite, "assets/images/monster/" .. enemy_data.sprite)
    bg_image     = AssetManager.loadImage("map_tutorial", "assets/images/map/map_tutorial.png")

    current_turn, selected_menu = 1, 1
    is_battle_over, battle_result = false, nil
    combat_timer, shake_timer, flash_alpha = 0, 0, 0
    UICombat.reset()
    advanceToAliveActor()  -- 로드 직후 죽은 파티원 스킵
    shack:setDimensions(1280, 720)
    log_msg = string.format(L("log_encounter"), enemy_actor.name:upper())

    local bgm = (enemy_data.is_boss == 1 or enemy_data.is_boss == true) and "bgm_boss" or "bgm_combat"
    AudioManager.playBGM(bgm, "assets/audio/bgm/" .. bgm .. ".wav")
end

function StateCombat.update(dt)
    combat_timer = combat_timer + dt
    flash_alpha = math.max(0, flash_alpha - 3 * dt)
    if shake_timer > 0 then
        shake_timer = shake_timer - dt
        if shake_timer <= 0 then shack:setShakeTarget(0) end
    end
    shack:update(dt)
end

function StateCombat.shake(intensity, duration)
    shack:setShakeTarget(intensity or 10)
    shake_timer = duration or 0.25
end

function StateCombat.draw()
    love.graphics.push()
    shack:apply()
    if bg_image then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.draw(bg_image, 0, 0, 0, 1280/bg_image:getWidth(), 720/bg_image:getHeight())
    end
    UICombat.draw(party_actors, enemy_sprite, current_turn, selected_menu, log_msg, enemy_actor, combat_timer)
    love.graphics.pop()
    if flash_alpha > 0 then
        love.graphics.setColor(1, 1, 1, flash_alpha)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
end

function StateCombat.keypressed(key)
    if is_battle_over then
        if key == "return" or key == "space" then return StateCombat.exitBattle() end
        return
    end

    if current_turn <= #party_actors then
        StateCombat.handlePlayerTurn(key)
    elseif key == "return" or key == "space" then
        StateCombat.handleEnemyTurn()
    end
end

function StateCombat.handlePlayerTurn(key)
    if not advanceToAliveActor() then
        StateCombat.setBattleOver("wipe"); return
    end

    local char = party_actors[current_turn]
    local skills = char.skills or {"skill_attack"}
    if key == "up" then
        selected_menu = (selected_menu - 2) % #skills + 1
    elseif key == "down" then
        selected_menu = selected_menu % #skills + 1
    elseif key == "return" or key == "space" then
        log_msg = SkillHandler.execute(char, enemy_actor, skills[selected_menu], SkillsDB, party_actors, enemy_actor, StateCombat)
        if enemy_actor.hp <= 0 then
            StateCombat.setBattleOver("win")
        else
            current_turn = current_turn + 1
            selected_menu = 1
            advanceToAliveActor()  -- 다음 파티원이 죽어있으면 즉시 스킵
        end
    end
end

function StateCombat.handleEnemyTurn()
    local msg = EnemyAI.takeTurn(enemy_actor, party_actors, SkillsDB, StateCombat)
    if msg then log_msg = msg end

    local still_alive = false
    for _, p in ipairs(party_actors) do if p.hp > 0 then still_alive = true; break end end

    if not still_alive then StateCombat.setBattleOver("wipe")
    else
        current_turn = 1
        advanceToAliveActor()  -- 적 턴 후 첫 살아있는 파티원으로 즉시 이동
        for _, p in ipairs(party_actors) do
            p:updateStatus()
            if p.hp > 0 and p.data.perks and p.data.perks["perk_int_20"] then
                p.sp = math.min(p.max_sp, p.sp + math.floor(p.max_sp * 0.1))
            end
        end
    end
end

function StateCombat.setBattleOver(result)
    is_battle_over, battle_result = true, result
    if result == "win" then
        AudioManager.stopBGM()
        local reward = enemy_actor.data.reward_credits or 0
        local Inventory = require("systems.inventory")
        Inventory.credits = Inventory.credits + reward
        log_msg = string.format(L("log_victory_reward"), reward)
    else
        log_msg = L("log_squad_wiped")
    end
end

function StateCombat.exitBattle()
    local Roster = require("systems.roster")
    for i, actor in ipairs(party_actors) do
        if Roster.active_party[i] then
            Roster.active_party[i].hp = actor.hp
            Roster.active_party[i].sp = actor.sp
        end
    end
    return (battle_result == "wipe" and "hub" or "explore"), battle_result, enemy_actor.id
end

return StateCombat
