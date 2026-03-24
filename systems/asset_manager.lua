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
    
    -- 1. 이미 정확한 경로인 경우
    if love.filesystem.getInfo(path) then return path end
    
    -- 2. "assets/images/" 로 시작하지 않는 경우에만 접두사 시도
    local filename = path:match("([^/]+)$") or path
    
    for _, dir in ipairs(sub_dirs) do
        local smart_path = "assets/images/" .. dir .. filename
        if love.filesystem.getInfo(smart_path) then
            return smart_path
        end
    end
    
    -- 3. 경로가 "assets/images/"를 포함하고 있으나 파일만 찾으려는 경우 대비
    if not path:find("assets/images/") then
        local full_path = "assets/images/" .. path
        if love.filesystem.getInfo(full_path) then return full_path end
    end

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