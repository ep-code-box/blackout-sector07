-- 에셋 매니저 (Asset Manager)
-- 모든 이미지와 폰트를 중앙에서 로드하고 관리합니다.
local AssetManager = {}

AssetManager.images = {}
AssetManager.fonts = {}

-- 검색할 하위 디렉토리 목록
local sub_dirs = {"", "ui/", "face/", "tile/", "map/", "item/", "npc/", "monster/"}

-- 특정 파일이 어느 하위 디렉토리에 있는지 실제 경로를 반환
function AssetManager.resolvePath(path)
    if not path then return nil end
    if love.filesystem.getInfo(path) then return path end
    
    -- 파일명만 추출 (예: "assets/images/sector_07_S.png" -> "sector_07_S.png")
    local filename = path:match("([^/]+)$") or path
    
    -- 하위 디렉토리 전수 조사
    for _, dir in ipairs(sub_dirs) do
        local smart_path = "assets/images/" .. dir .. filename
        if love.filesystem.getInfo(smart_path) then
            return smart_path
        end
    end
    
    -- 그래도 없으면 원본 경로 반환
    return path
end

function AssetManager.loadImage(name, path)
    if AssetManager.images[name] then return AssetManager.images[name] end
    
    -- 스마트 경로 해결
    local resolved = AssetManager.resolvePath(path)
    
    if love.filesystem.getInfo(resolved) then
        local img = love.graphics.newImage(resolved)
        AssetManager.images[name] = img
        print("🖼️ Asset Loaded: " .. name .. " from " .. resolved)
        return img
    end
    
    print("⚠️ Asset Not Found: " .. path .. " (Resolved as: " .. tostring(resolved) .. ")")
    return nil
end

function AssetManager.loadFont(name, path, size)
    local key = name .. "_" .. size
    if AssetManager.fonts[key] then return AssetManager.fonts[key] end
    
    if love.filesystem.getInfo(path) then
        local font = love.graphics.newFont(path, size)
        AssetManager.fonts[key] = font
        return font
    else
        print("⚠️ Font Not Found: " .. path)
        return nil
    end
end

-- 캐시된 이미지 가져오기
function AssetManager.getImage(name)
    return AssetManager.images[name]
end

return AssetManager