-- 통합 상태창 오버레이 (Coordinator V2)
local UI = require("ui.theme")
local Inventory = require("systems.inventory")
local Roster = require("systems.roster")
local StatusInfo = require("ui.status_info")
local StatusPreview = require("ui.status_preview")
local AssetManager = require("systems.asset_manager")

local StatusOverlay = {}

local bg_scan
local frame_holo
local slot_keys = {"optics", "nervous", "skeleton", "integumentary"}

StatusOverlay.isOpen = false
StatusOverlay.cursor = 1
StatusOverlay.equip_mode = nil
StatusOverlay.slot_cursor = 1
StatusOverlay.stash_cursor = 1
StatusOverlay.boot_timer = 0 -- 부팅 타이머 추가

function StatusOverlay.load()
    bg_scan = AssetManager.loadImage("ui_bg_scan", "assets/images/ui_bg_scan.png")
    frame_holo = AssetManager.loadImage("ui_frame_holo", "assets/images/ui_frame_holo.png")
end

function StatusOverlay.draw()
    if not StatusOverlay.isOpen then 
        StatusOverlay.boot_timer = 0
        return 
    end
    
    -- 0. 부팅/스캔 시퀀스 (0.5초간 노이즈 출력)
    StatusOverlay.boot_timer = StatusOverlay.boot_timer + love.timer.getDelta()
    if StatusOverlay.boot_timer < 0.5 then
        love.graphics.setColor(0, 0.05, 0.1, 0.92)
        love.graphics.rectangle("fill", 0, 0, UI.screen_w, UI.screen_h)
        UI.drawNoiseLine(UI.relX(0.1), UI.relY(0.5), UI.relW(0.8))
        love.graphics.setFont(UI.font_large)
        love.graphics.setColor(UI.color.highlight)
        love.graphics.printf("INITIALIZING NEURAL LINK... " .. math.floor(StatusOverlay.boot_timer * 200) .. "%", 0, UI.relY(0.52), UI.screen_w, "center")
        return
    end

    local char = Roster.active_party[StatusOverlay.cursor]
    if not char then return end

    -- 1. 고급 배경 효과 (그라데이션 암전)
    love.graphics.setColor(0, 0.05, 0.1, 0.92)
    love.graphics.rectangle("fill", 0, 0, UI.screen_w, UI.screen_h)
    
    -- 배경 스캔 라인 이미지가 있으면 출력
    if bg_scan then 
        love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.15)
        love.graphics.draw(bg_scan, 0, 0, 0, UI.screen_w/bg_scan:getWidth(), UI.screen_h/bg_scan:getHeight()) 
    end

    -- 2. 미세한 그리드 (전체 화면)
    love.graphics.setColor(UI.color.highlight[1], UI.color.highlight[2], UI.color.highlight[3], 0.03)
    for i = 0, UI.screen_w, 40 do love.graphics.line(i, 0, i, UI.screen_h) end
    for i = 0, UI.screen_h, 40 do love.graphics.line(0, i, UI.screen_w, i) end

    -- 3. 모듈화된 UI 컴포넌트 호출 (1280x720 황금 비율 배치)
    -- 캐릭터 프리뷰를 왼쪽, 스탯 정보를 오른쪽에 밸런스 있게 배치
    StatusPreview.draw(char, UI.relX(0.32), UI.relY(0.5), frame_holo)
    StatusInfo.draw(char, UI.relX(0.55), UI.relY(0.1), StatusOverlay.equip_mode, StatusOverlay.slot_cursor, slot_keys)

    -- 4. 하단 네비게이션 가이드 (중앙 하단 배치)
    local gx, gy, gw, gh = UI.drawWindow(0.5, 0.95, 0.4, 0.05, nil, UI.color.text_dim)
    love.graphics.setFont(UI.font_small)
    love.graphics.setColor(UI.color.text_main)
    love.graphics.printf("[I] CLOSE  [TAB/LR] SWITCH  [SPACE] MOD-MODE", gx, gy + 10, gw, "center")

    -- 5. 창고 팝업
    if StatusOverlay.equip_mode == "stash" then
        StatusOverlay.drawStashPopup()
    end
end

function StatusOverlay.drawStashPopup()
    local target_slot = slot_keys[StatusOverlay.slot_cursor]
    local valid_items = StatusOverlay.getValidStashItems()
    
    -- 중앙에 대형 윈도우 생성 (rx, ry, rw, rh)
    local wx, wy, ww, wh = UI.drawWindow(0.5, 0.5, 0.7, 0.75, "AVAILABLE HARDWARE ARCHIVE: " .. target_slot:upper(), UI.color.accent)
    
    local panel_cfg = { x = wx, y = wy, w = ww, h = wh, title = nil, color = UI.color.accent }
    local list_cfg = { size = #valid_items, cursor = StatusOverlay.stash_cursor, max_visible = 10, item_h = 50 }

    if #valid_items == 0 then
        love.graphics.setFont(UI.font_normal)
        love.graphics.setColor(UI.color.text_dim)
        love.graphics.printf("NO COMPATIBLE HARDWARE FOUND IN STASH.", wx, wy + wh/2 - 10, ww, "center")
    else
        UI.drawScrollingList(panel_cfg, list_cfg, function(idx, x, y, w, h, is_selected)
            local entry = valid_items[idx]
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.rectangle("fill", x, y, w, h)
            
            if is_selected then
                love.graphics.setColor(UI.color.accent[1], UI.color.accent[2], UI.color.accent[3], 0.2)
                love.graphics.rectangle("fill", x, y, w, h)
                love.graphics.setColor(UI.color.accent)
                love.graphics.rectangle("line", x, y, w, h)
                love.graphics.print(">>", x + 15, y + 15)
            end
            
            love.graphics.setFont(UI.font_normal)
            love.graphics.setColor(UI.color.text_main)
            love.graphics.print(entry.data.name, x + 50, y + 15)
            
            local stat_summary = ""
            for s, v in pairs(entry.data.stats) do 
                stat_summary = stat_summary .. s:upper() .. (v>=0 and "+" or "") .. v .. " " 
            end
            love.graphics.setFont(UI.font_small)
            love.graphics.setColor(UI.color.accent)
            love.graphics.printf(stat_summary, x, y + 18, w - 20, "right")
        end)
    end
end

function StatusOverlay.getValidStashItems()
    local target_slot = slot_keys[StatusOverlay.slot_cursor]
    local valid = {}
    for idx, item in ipairs(Inventory.stash) do
        if item.slot == target_slot then table.insert(valid, {data=item, original_idx=idx}) end
    end
    return valid
end

function StatusOverlay.keypressed(key)
    if not StatusOverlay.isOpen then return end

    if StatusOverlay.equip_mode == "stash" then
        local valid = StatusOverlay.getValidStashItems()
        if key == "escape" then StatusOverlay.equip_mode = "slot"
        elseif key == "up" then StatusOverlay.stash_cursor = math.max(1, StatusOverlay.stash_cursor - 1)
        elseif key == "down" then StatusOverlay.stash_cursor = math.min(#valid, StatusOverlay.stash_cursor + 1)
        elseif key == "return" or key == "space" then
            local entry = valid[StatusOverlay.stash_cursor]
            if entry then
                Inventory.equip(Roster.active_party[StatusOverlay.cursor], entry.original_idx)
                StatusOverlay.equip_mode = nil
            end
        end
        return true
    end

    if StatusOverlay.equip_mode == "slot" then
        if key == "escape" then StatusOverlay.equip_mode = nil
        elseif key == "up" then StatusOverlay.slot_cursor = math.max(1, StatusOverlay.slot_cursor - 1)
        elseif key == "down" then StatusOverlay.slot_cursor = math.min(4, StatusOverlay.slot_cursor + 1)
        elseif key == "return" or key == "space" then
            StatusOverlay.equip_mode = "stash"
            StatusOverlay.stash_cursor = 1
        end
        return true
    end

    if key == "tab" or key == "right" then
        StatusOverlay.cursor = (StatusOverlay.cursor % #Roster.active_party) + 1
    elseif key == "left" then
        StatusOverlay.cursor = StatusOverlay.cursor - 1
        if StatusOverlay.cursor < 1 then StatusOverlay.cursor = #Roster.active_party end
    elseif key == "space" then
        StatusOverlay.equip_mode = "slot"
        StatusOverlay.slot_cursor = 1
    elseif key == "escape" or key == "i" then
        StatusOverlay.isOpen = false
    end
    
    -- [추가] 스탯 포인트 투자 로직
    local char = Roster.active_party[StatusOverlay.cursor]
    if char and (char.stat_points or 0) > 0 then
        local stat_map = {"str", "dex", "int", "con", "agi", "edg"}
        local num = tonumber(key)
        if num and num >= 1 and num <= 6 then
            local stat_id = stat_map[num]
            char[stat_id] = (char[stat_id] or 0) + 1
            char.stat_points = char.stat_points - 1
            
            -- [추가] 스탯 임계점 도달 시 특성 해금 체크
            local Progression = require("systems.progression")
            Progression.checkPerks(char)
            
            print("Allocated point to " .. stat_id .. " | Remaining: " .. char.stat_points)
        end
    end
    
    return true
end

return StatusOverlay