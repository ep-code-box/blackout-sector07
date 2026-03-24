-- 입력 매니저 (Input Manager)
-- 하드웨어 키와 게임 액션을 매핑합니다.
local InputManager = {}

local key_map = {
    up = "up", down = "down", left = "left", right = "right",
    w = "up", s = "down", a = "left", d = "right",
    space = "confirm", ["return"] = "confirm",
    escape = "cancel",
    i = "status",
    tab = "switch",
    r = "reload"
}

function InputManager.getAction(key)
    return key_map[key]
end

return InputManager