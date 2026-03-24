-- Hub 서브 상태: 상점 및 장비 관리
local ShopView = {}
local Inventory   = require("systems.inventory")
local SaveManager = require("systems.save_manager")
local UIHubShop   = require("ui.hub_shop")

function ShopView.new(items_db)
    local self = {
        items_db = items_db,
        cursor = 1,
        equip_cursor = 1,
        equip_item = nil,
        is_equipping = false,
        dialogue = ""
    }
    return setmetatable(self, { __index = ShopView })
end

function ShopView:draw(party, credits)
    UIHubShop.draw(self.items_db, credits, self.cursor)
    if self.is_equipping and self.equip_item then
        UIHubShop.drawEquipSelect(party, self.equip_item, self.equip_cursor)
    end
end

function ShopView:getDialogue()
    local d = self.dialogue
    self.dialogue = ""
    return d
end

function ShopView:keypressed(key, party)
    if self.is_equipping then
        return self:handleEquip(key, party)
    else
        return self:handleShop(key, party)
    end
end

function ShopView:handleShop(key, party)
    if key == "escape" then return "exit" end
    local count = UIHubShop.getItemCount(self.items_db)

    if key == "up" then self.cursor = math.max(1, self.cursor - 1)
    elseif key == "down" then self.cursor = math.min(count, self.cursor + 1)
    elseif key == "return" or key == "space" then
        local item = UIHubShop.getItemByIndex(self.items_db, self.cursor)
        if item then
            local success, msg = Inventory.buyItem(item)
            if success then
                self.equip_item = item
                self.equip_cursor = 1
                self.is_equipping = true
                self.dialogue = L("hub_msg_ripper_target")
            else
                self.dialogue = "리퍼닥: '" .. msg .. "'"
            end
        end
    end
    return nil
end

function ShopView:handleEquip(key, party)
    if key == "escape" then
        self.is_equipping = false
        self.equip_item = nil
        return nil
    end

    if key == "up" then self.equip_cursor = math.max(1, self.equip_cursor - 1)
    elseif key == "down" then self.equip_cursor = math.min(#party, self.equip_cursor + 1)
    elseif key == "return" or key == "space" then
        local char = party[self.equip_cursor]
        if char and self.equip_item then
            local stash_idx = nil
            for i, it in ipairs(Inventory.stash) do
                if it.id == self.equip_item.id then stash_idx = i; break end
            end
            if stash_idx then
                local ok, msg = Inventory.equip(char, stash_idx)
                self.dialogue = "리퍼닥: '" .. msg .. "'"
                if ok then SaveManager.save() end
            end
            self.is_equipping = false
            self.equip_item = nil
        end
    end
    return nil
end

return ShopView
