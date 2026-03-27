local UI            = require("ui.theme")
local Roster        = require("systems.roster")
local Inventory     = require("systems.inventory")
local SaveManager   = require("systems.save_manager")
local AssetManager  = require("systems.asset_manager")
local StatusOverlay = require("ui.status_overlay")
local UIHubMain     = require("ui.hub_main")
local AudioManager  = require("systems.audio_manager")

-- 신규 서브 모듈
local SkillsView    = require("states.hub.hub_skills")
local RosterView    = require("states.hub.hub_roster")
local ShopView      = require("states.hub.hub_shop")

local StateHub = {}
local pub_bg, npc_bartender, party, items_db, quests_db

local selected_menu = 1
local dialogue = L("hub_dialogue_welcome")

-- 서브 상태 관리 객체
local sub_views = {}
local current_sub = nil -- nil | "roster" | "skills" | "shop"

local menu_keys = {
    "hub_menu_rest", "hub_menu_roster", "hub_menu_shop",
    "hub_menu_status", "hub_menu_skills", "hub_menu_save", "hub_menu_deploy"
}

function StateHub.load()
    local DBManager = require("systems.db_manager")
    local StoryManager = require("systems.story_manager")
    party     = Roster.active_party
    items_db  = DBManager.getAllItems()
    quests_db = DBManager.getAllQuests()
    
    Inventory.init(party)
    pub_bg        = AssetManager.loadImage("map_pub", "assets/images/map/map_pub.png")
    npc_bartender = AssetManager.loadImage("npc_bartender", "assets/images/npc/npc_bartender.png")

    -- 서브 뷰 초기화
    sub_views.skills = SkillsView.new(party)
    sub_views.roster = RosterView.new()
    sub_views.shop   = ShopView.new(items_db)
    
    current_sub = nil
    AudioManager.playBGM("bgm_hub", "assets/audio/bgm/bgm_hub.wav")

    -- 프롤로그 트리거 (신규 게임)
    if StoryManager.current_chapter == 1 and not StoryManager.is_active then
        StoryManager.triggerChapter("initial")
    end

    -- Director가 직조한 hub_load 챕터 트리거 (바텐더 소문 대사)
    if not StoryManager.is_active then
        StoryManager.triggerChapter("hub_load")
    end
end

function StateHub.draw()
    love.graphics.clear(0, 0, 0)
    UIHubMain.draw(pub_bg, npc_bartender, quests_db, party, menu_keys, selected_menu, dialogue)

    if current_sub and sub_views[current_sub] then
        sub_views[current_sub]:draw(party, Inventory.credits)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(UI.font_normal)
    love.graphics.print(L("ui_credits") .. ": " .. (Inventory.credits or 0) .. " C", 650, 20)
end

function StateHub.keypressed(key)
    -- 1. 서브 상태일 때 로직 위임
    if current_sub and sub_views[current_sub] then
        local res = sub_views[current_sub]:keypressed(key, party)
        
        -- 다이얼로그 업데이트 (있는 경우)
        if sub_views[current_sub].getDialogue then
            local msg = sub_views[current_sub]:getDialogue()
            if msg ~= "" then dialogue = msg end
        end

        if res == "exit" then current_sub = nil end
        return nil
    end

    -- 2. 메인 메뉴 내비게이션
    if key == "up" then
        selected_menu = (selected_menu - 2) % #menu_keys + 1
    elseif key == "down" then
        selected_menu = selected_menu % #menu_keys + 1
    elseif key == "return" or key == "space" then
        return StateHub.handleMainMenu()
    end
    return nil
end

function StateHub.handleMainMenu()
    if selected_menu == 1 then -- 휴식
        for _, char in ipairs(party) do char.hp = char.max_hp; char.sp = char.max_sp end
        dialogue = L("hub_dialogue_rested")
    elseif selected_menu == 2 then current_sub = "roster"
    elseif selected_menu == 3 then current_sub = "shop"; print("E2E_HOOK: SHOP_OPENED")
    elseif selected_menu == 4 then StatusOverlay.isOpen = true
    elseif selected_menu == 5 then current_sub = "skills"
    elseif selected_menu == 6 then
        local _, msg = SaveManager.save()
        dialogue = string.format(L("hub_msg_save_success"), msg)
    elseif selected_menu == 7 then
        if #party == 0 then dialogue = L("hub_msg_party_empty")
        else return "explore" end
    end
    return nil
end

return StateHub
