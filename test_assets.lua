-- 에셋 존재 여부 자동 점검 스크립트 (Self-Test)
local Roster = require("client.data.data_mercs_seed")
local Enemy = require("client.data.data_enemy_seed")
local Items = require("client.data.data_items_seed")
local lfs = os -- 표준 Lua에서는 io/os를 사용하지만, 파일 존재 확인용 함수 정의

function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f); return true else return false end
end

local errors = 0
local function check(path, label)
    local full_path = "client/assets/images/" .. path
    if not file_exists(full_path) then
        print("❌ [MISSING] " .. label .. ": " .. full_path)
        errors = errors + 1
    else
        -- print("✅ [OK] " .. label .. ": " .. full_path)
    end
end

print("------------------------------------------")
print("🔍 에셋 무결성 전수 조사 시작...")
print("------------------------------------------")

-- 1. 용병 에셋 체크
for _, char in ipairs(Roster) do
    check(char.sprite, "MERC_SPRITE [" .. char.name .. "]")
    local face = char.sprite:gsub(".png", "_face.png")
    check(face, "MERC_FACE [" .. char.name .. "]")
end

-- 2. 적 유닛 에셋 체크
for id, data in pairs(Enemy) do
    check(data.sprite, "ENEMY_SPRITE [" .. id .. "]")
end

-- 3. 아이템 에셋 체크 (추후 추가될 이미지 대비)
for id, data in pairs(Items) do
    if data.sprite then
        check(data.sprite, "ITEM_SPRITE [" .. id .. "]")
    end
end

print("------------------------------------------")
if errors == 0 then
    print("✨ 모든 에셋이 정상적으로 매핑되었습니다!")
else
    print("⚠️ 총 " .. errors .. "개의 에셋 누락이 발견되었습니다.")
end
print("------------------------------------------")
