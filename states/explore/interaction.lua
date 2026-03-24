-- 탐험 상호작용: 전투 진입, 보물상자 등 전담
local Interaction = {}
local Inventory = require("systems.inventory")
local Roster    = require("systems.roster")
local DBManager = require("systems.db_manager")

function Interaction.handle(tile, player, map, enemy_pool_func)
    if tile == 2 then -- 적 인카운터
        local next_state, enemy_id, lv = Interaction.triggerCombat(player, enemy_pool_func)
        return next_state, enemy_id, lv
    elseif tile == 3 then -- 보물상자
        local _, msg = Interaction.openTreasure(map, player)
        return nil, msg
    elseif tile == 4 then -- 허브 귀환
        return "hub"
    end
    return nil
end

function Interaction.triggerCombat(player, enemy_pool_func)
    local avg_lv = 1
    local active = Roster.active_party
    if #active > 0 then
        local sum = 0
        for _, m in ipairs(active) do sum = sum + (m.level or 1) end
        avg_lv = math.max(1, math.floor(sum / #active))
    end

    local selected_id = nil
    for _, q in ipairs(DBManager.getAllQuests()) do
        if not q.completed and (q.required_boss_id or "") ~= "" then
            local bid = q.required_boss_id
            if bid == bid:lower() and q.target_coords.x == player.x and q.target_coords.y == player.y then
                selected_id = bid
                break
            end
        end
    end

    if not selected_id then
        local pool = enemy_pool_func()
        selected_id = pool[math.random(#pool)]
    end

    return "combat", selected_id, avg_lv
end

function Interaction.openTreasure(map, player)
    local credits = math.random(30, 80)
    Inventory.credits = Inventory.credits + credits
    map[player.y][player.x] = 1
    return nil, string.format(L("log_treasure"), credits)
end

return Interaction
