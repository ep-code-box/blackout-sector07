-- 탐험 네비게이터: 좌표 및 방향 계산 전담
local Navigator = {}

local DIRS = {
    north = { dx = 0, dy = -1, left = "west",  right = "east" },
    south = { dx = 0, dy =  1, left = "east",  right = "west" },
    east  = { dx = 1, dy =  0, left = "north", right = "south" },
    west  = { dx = -1, dy =  0, left = "south", right = "north" }
}

function Navigator.getSideTile(map, p, side)
    local side_dir = DIRS[DIRS[p.facing][side]]
    local tx = p.x + side_dir.dx
    local ty = p.y + side_dir.dy
    if map[ty] and map[ty][tx] then return map[ty][tx] end
    return 0
end

function Navigator.getFrontTile(map, p, dist)
    local d = DIRS[p.facing]
    local tx, ty = p.x + d.dx * (dist or 1), p.y + d.dy * (dist or 1)
    if map[ty] and map[ty][tx] then return map[ty][tx], tx, ty end
    return 0, tx, ty
end

function Navigator.turn(p, side)
    p.facing = DIRS[p.facing][side]
end

function Navigator.move(map, p, is_forward)
    local d = DIRS[p.facing]
    local mult = is_forward and 1 or -1
    local nx, ny = p.x + d.dx * mult, p.y + d.dy * mult
    
    if map[ny] and map[ny][nx] and map[ny][nx] ~= 0 then
        p.x, p.y = nx, ny
        return true
    end
    return false
end

return Navigator
