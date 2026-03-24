-- 절차적 던전 생성기 (Procedural Dungeon Generator)
local DungeonGen = {}

function DungeonGen.generate(width, height)
    local map = {}
    -- 1. 전체를 벽(0)으로 초기화
    for y = 1, height do
        map[y] = {}
        for x = 1, width do
            map[y][x] = 0
        end
    end

    -- 2. 미로 생성 알고리즘 (Recursive Backtracking)
    local function walk(x, y)
        map[y][x] = 1 -- 길(길)로 만듦
        
        local directions = {
            {dx=0, dy=-2}, {dx=0, dy=2}, {dx=-2, dy=0}, {dx=2, dy=0}
        }
        -- 무작위 방향 셔플
        for i = #directions, 2, -1 do
            local j = math.random(i)
            directions[i], directions[j] = directions[j], directions[i]
        end

        for _, d in ipairs(directions) do
            local nx, ny = x + d.dx, y + d.dy
            if nx > 1 and nx < width and ny > 1 and ny < height and map[ny][nx] == 0 then
                -- 중간 벽 허물기
                map[y + d.dy/2][x + d.dx/2] = 1
                walk(nx, ny)
            end
        end
    end

    -- 시작점 (2, 2)
    walk(2, 2)

    -- 3. 적(2) 무작위 배치
    local enemy_count = math.random(5, 8)
    local placed = 0
    while enemy_count > placed do
        local rx, ry = math.random(1, width), math.random(1, height)
        if map[ry][rx] == 1 and (rx ~= 2 or ry ~= 2) then
            map[ry][rx] = 2
            placed = placed + 1
        end
    end

    -- 4. 보물상자(3) 무작위 배치
    local chest_count = math.random(2, 4)
    placed = 0
    while chest_count > placed do
        local rx, ry = math.random(1, width), math.random(1, height)
        if map[ry][rx] == 1 and (rx ~= 2 or ry ~= 2) then
            map[ry][rx] = 3
            placed = placed + 1
        end
    end

    -- 5. 출구(4) 배치 (시작점에서 가장 먼 곳 중 하나)
    local exit_placed = false
    while not exit_placed do
        local rx, ry = math.random(width-5, width), math.random(height-5, height)
        if map[ry] and map[ry][rx] == 1 then
            map[ry][rx] = 4
            exit_placed = true
        end
    end

    return map
end

return DungeonGen