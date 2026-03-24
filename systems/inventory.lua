-- 인벤토리 및 장비 관리 매니저
local Inventory = {}
local Roster = require("systems.roster")

Inventory.credits = 500
Inventory.stash = {}
Inventory.equipped = {}

function Inventory.init(party)
    for _, char in ipairs(party) do
        if not Inventory.equipped[char.id] then
            Inventory.equipped[char.id] = {
                optics       = nil,
                nervous      = nil,
                integumentary = nil,
                weapon       = nil,
            }
        end
    end
end

-- 아이템 구매 (창고로 이동)
function Inventory.buyItem(item_data)
    if Inventory.credits >= item_data.price then
        Inventory.credits = Inventory.credits - item_data.price
        local newItem = {}
        for k, v in pairs(item_data) do newItem[k] = v end
        table.insert(Inventory.stash, newItem)
        
        return true, "구매 완료! 창고에 보관되었습니다."
    else
        return false, "크레딧이 부족합니다."
    end
end

-- 특정 캐릭터의 슬롯에 아이템 장착
function Inventory.equip(char, item_index)
    local item = Inventory.stash[item_index]
    if not item then return false, "아이템이 없습니다." end

    local slots = Inventory.equipped[char.id]
    if not slots then return false, "장비 슬롯 초기화 필요" end

    local old_item = slots[item.slot]

    -- 1. 기존 장비 해제 (스탯 및 스킬 원복)
    if old_item then
        if old_item.stats then
            for stat, val in pairs(old_item.stats) do
                -- NaN 방지: 기존 값이 없으면 0 기본
                char[stat] = (char[stat] or 0) - val
                if stat == "max_hp" then char.hp = math.max(1, math.min(char.max_hp, char.hp)) end
                if stat == "max_sp" then char.sp = math.max(0, math.min(char.max_sp, char.sp)) end
            end
        end

        if old_item.grant_skill then
            for i, s in ipairs(char.skills) do
                if s == old_item.grant_skill then table.remove(char.skills, i); break end
            end
        end
        if old_item.replace_skill then
            for i, s in ipairs(char.skills) do
                if s == old_item.replace_skill.new_skill then
                    char.skills[i] = old_item.replace_skill.target; break
                end
            end
        end

        table.insert(Inventory.stash, old_item)
    end

    -- 2. 새 장비 장착 (스탯 및 스킬 적용)
    slots[item.slot] = item
    if item.stats then
        for stat, val in pairs(item.stats) do
            local old_val = char[stat] or 0
            char[stat] = old_val + val
            if stat == "max_hp" then char.hp = char.hp + val end
            if stat == "max_sp" then char.sp = char.sp + val end
        end
    end

    if item.grant_skill then
        local has_skill = false
        for _, s in ipairs(char.skills) do if s == item.grant_skill then has_skill = true; break end end
        if not has_skill then table.insert(char.skills, item.grant_skill) end
    end
    if item.replace_skill then
        for i, s in ipairs(char.skills) do
            if s == item.replace_skill.target then
                char.skills[i] = item.replace_skill.new_skill; break
            end
        end
    end

    -- 3. 창고에서 제거
    table.remove(Inventory.stash, item_index)

    -- 캐릭터 스탯 변경사항 DB 반영
    Roster.saveMercToDB(char)

    return true, char.name .. "에게 " .. item.name .. " 이식 성공."
end

return Inventory
