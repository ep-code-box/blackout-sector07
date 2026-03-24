-- 펍 상점(리퍼닥) UI 모듈
local UI = require("ui.theme")
local Inventory = require("systems.inventory")
local UIHubShop = {}

function UIHubShop.draw(items_db, credits, shop_cursor)
    local item_list = {}
    for id, item in pairs(items_db) do table.insert(item_list, item) end
    table.sort(item_list, function(a, b) return (a.tier or 1) < (b.tier or 1) end)

    local panel_cfg = {
        x = 50, y = 50, w = 700, h = 400, 
        title = "Ripperdoc Clinic: Cyberware Market", color = {1, 0, 1}
    }
    
    local list_cfg = {
        size = #item_list, cursor = shop_cursor, max_visible = 5, item_h = 60
    }

    UI.drawScrollingList(panel_cfg, list_cfg, function(idx, x, y, w, h, is_selected)
        local item = item_list[idx]
        
        -- 배경 하이라이트
        if is_selected then
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.rectangle("fill", x, y, w, h)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(">", x + 5, y + 15)
        end
        
        love.graphics.setColor(UI.color.accent)
        love.graphics.print(item.name .. " (" .. item.price .. " C)", x + 25, y + 5)
        
        love.graphics.setFont(UI.font_small)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.print(item.desc, x + 25, y + 30)
        
        -- 스탯 정보
        local stat_txt = ""
        for s, v in pairs(item.stats) do stat_txt = stat_txt .. s:upper() .. (v>=0 and "+" or "") .. v .. " " end
        love.graphics.setColor(UI.color.highlight)
        love.graphics.printf(stat_txt, x, y + 15, w - 10, "right")
        love.graphics.setFont(UI.font_normal)
    end)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("CREDITS: " .. credits .. " C", 50, 65, 680, "right")
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.print("[Enter] 구매, [ESC] 나가기", 70, 420, 0, 0.8, 0.8)
end

-- 장착 대상 캐릭터 선택 팝업
function UIHubShop.drawEquipSelect(party, item, equip_cursor)
    local pw, ph = 440, 60 + #party * 50 + 40
    local px, py = (1280 - pw) / 2, (720 - ph) / 2

    UI.drawPanel(px, py, pw, ph, "INSTALL: " .. item.name, UI.color.highlight)

    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.printf("SLOT: " .. (item.slot or "?"):upper(), px, py + 38, pw, "center")

    for i, char in ipairs(party) do
        local y = py + 58 + (i - 1) * 50
        local equipped = Inventory.equipped[char.id] and Inventory.equipped[char.id][item.slot]
        local eq_txt = equipped and (" ← " .. equipped.name) or " ← [empty]"
        UI.drawButton(px + 20, y, pw - 40, 38, char.name .. eq_txt, equip_cursor == i, UI.color.highlight)
    end

    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_dim)
    love.graphics.printf("[ENTER] 장착  [ESC] 취소", px, py + ph - 28, pw, "center")
end

function UIHubShop.getItemByIndex(items_db, index)
    local item_list = {}
    for id, item in pairs(items_db) do table.insert(item_list, item) end
    table.sort(item_list, function(a, b) return (a.tier or 1) < (b.tier or 1) end)
    return item_list[index]
end

function UIHubShop.getItemCount(items_db)
    local count = 0
    for _ in pairs(items_db) do count = count + 1 end
    return count
end

return UIHubShop