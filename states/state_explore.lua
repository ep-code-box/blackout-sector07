-- 탐험 상태 모듈 (Navigator & Interaction 분리 V3)
local StateExplore = {}

local DungeonGen   = require("systems.dungeon_gen")
local UIExplore    = require("ui.explore")
local player       = require("data.data_player")
local AssetManager = require("systems.asset_manager")
local AudioManager = require("systems.audio_manager")

-- 신규 서브 모듈
local Navigator    = require("states.explore.navigator")
local Interaction  = require("states.explore.interaction")

local map        = {}
local bg_images  = {}
local bob_y      = 0
local bob_time   = 0
local cam_offset_x = 0
local blink_alpha  = 0
local interaction_msg = ""
local msg_timer    = 0
local moved_recently = false

local MAP_WIDTH, MAP_HEIGHT = 15, 15

local ENEMY_POOLS = {
    [1] = {"drone_security", "hacker_rogue"},
    [2] = {"drone_security", "hacker_rogue", "corp_enforcer"},
    [3] = {"hacker_rogue",   "corp_enforcer", "corp_enforcer_elite"},
    [4] = {"corp_enforcer",  "corp_enforcer_elite"},
    [5] = {"corp_enforcer_elite"},
}

local function getEnemyPool()
    local StoryManager = require("systems.story_manager")
    local ch = math.max(1, math.min(5, StoryManager.current_chapter - 1))
    return ENEMY_POOLS[ch] or ENEMY_POOLS[1]
end

function StateExplore.load(force_reset)
    if not map or #map == 0 or force_reset then
        map = DungeonGen.generate(MAP_WIDTH, MAP_HEIGHT)
        player.x, player.y = 2, 2
        player.facing = "north"

        -- 보스 퀘스트 배치
        local DBManager = require("systems.db_manager")
        for _, q in ipairs(DBManager.getAllQuests()) do
            if not q.completed and (q.required_boss_id or "") ~= "" then
                local bid = q.required_boss_id
                if bid == bid:lower() then
                    local tx, ty = q.target_coords.x, q.target_coords.y
                    if map[ty] and map[ty][tx] ~= 0 then map[ty][tx] = 2 end
                end
            end
        end
        print("✅ New Dungeon Generated")
    end

    local view_types = {
        "hall_long", "hall_mid", "wall_deadend", "gate",
        "hall_left", "hall_right", "hall_t",
        "deadend_left", "deadend_right", "deadend_sides"
    }
    for _, vt in ipairs(view_types) do
        local path = "assets/images/map/sector_07_" .. vt .. ".png"
        bg_images[vt] = AssetManager.loadImage("sector_07_"..vt, path)
    end
    interaction_msg = ""
    AudioManager.playBGM("bgm_explore", "assets/audio/bgm/bgm_explore.wav")
end

function StateExplore.update(dt)
    if moved_recently then
        bob_time = bob_time + dt * 12
        bob_y    = math.sin(bob_time) * 10
        if math.abs(bob_y) < 1 then moved_recently = false end
    else
        bob_y = bob_y * math.exp(-10 * dt)
        bob_time = 0
    end
    cam_offset_x = cam_offset_x * math.exp(-8 * dt)
    blink_alpha  = math.max(0, blink_alpha - 12 * dt)
    if msg_timer > 0 then
        msg_timer = msg_timer - dt
        if msg_timer <= 0 then interaction_msg = "" end
    end
end

function StateExplore.draw()
    love.graphics.push()
    love.graphics.translate(cam_offset_x, bob_y)
    
    local tile_f  = Navigator.getFrontTile(map, player, 1)
    local tile_f2 = Navigator.getFrontTile(map, player, 2)
    local tile_l  = Navigator.getSideTile(map, player, "left")
    local tile_r  = Navigator.getSideTile(map, player, "right")

    local view_type
    if tile_f == 4 then
        view_type = "gate"
    elseif tile_f == 0 then
        if tile_l ~= 0 and tile_r ~= 0 then view_type = "deadend_sides"
        elseif tile_l ~= 0                then view_type = "deadend_left"
        elseif tile_r ~= 0                then view_type = "deadend_right"
        else                                   view_type = "wall_deadend" end
    else
        if tile_l ~= 0 and tile_r ~= 0 then view_type = "hall_t"
        elseif tile_l ~= 0              then view_type = "hall_left"
        elseif tile_r ~= 0              then view_type = "hall_right"
        elseif tile_f2 == 0             then view_type = "hall_mid"
        else                                 view_type = "hall_long" end
    end

    -- 에셋 없는 타입은 유사한 기존 에셋으로 폴백
    local FALLBACK = {
        hall_left     = "hall_long",
        hall_right    = "hall_long",
        hall_t        = "hall_long",
        deadend_left  = "wall_deadend",
        deadend_right = "wall_deadend",
        deadend_sides = "wall_deadend",
    }
    local bg = bg_images[view_type] or bg_images[FALLBACK[view_type]] or bg_images["hall_long"]
    if bg then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bg, 0, 0, 0, 1280/bg:getWidth(), 720/bg:getHeight())
    end

    if tile_f == 2 then
        local enemy_img = AssetManager.loadImage("enemy_drone", "assets/images/monster/enemy_drone.png")
        if enemy_img then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.draw(enemy_img, 640, 360, 0, 500/enemy_img:getHeight(), 500/enemy_img:getHeight(), enemy_img:getWidth()/2, enemy_img:getHeight()/2)
        end
    end
    love.graphics.pop()
    UIExplore.draw(map, player, blink_alpha, interaction_msg)
end

function StateExplore.keypressed(key)
    if key == "left" then
        Navigator.turn(player, "left")
        cam_offset_x, blink_alpha = 60, 0.1
    elseif key == "right" then
        Navigator.turn(player, "right")
        cam_offset_x, blink_alpha = -60, 0.1
    elseif key == "up" then
        if Navigator.move(map, player, true) then moved_recently, blink_alpha = true, 0.2 end
    elseif key == "down" then
        if Navigator.move(map, player, false) then moved_recently, blink_alpha = true, 0.2 end
    elseif key == "space" then
        local tile = map[player.y][player.x]
        local next_state, arg1, arg2 = Interaction.handle(tile, player, map, getEnemyPool)
        if arg1 and not next_state then -- 상호작용 메시지인 경우
            interaction_msg, msg_timer = arg1, 2
        end
        return next_state, arg1, arg2
    end
    return nil
end

function StateExplore.clearEnemy(x, y)
    local tx, ty = x or player.x, y or player.y
    if map[ty] and map[ty][tx] == 2 then map[ty][tx] = 1 end
end

return StateExplore
