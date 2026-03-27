-- 사이버펑크 하이테크 UI 테마 (서브 모듈 분리 버전)
local UI = {}

-- ── 화면 / 컬러 / 레이아웃 상수 ───────────────────────────────────────────

UI.screen_w = 1280
UI.screen_h = 720

function UI.updateScreenSize(w, h)
    UI.screen_w = w
    UI.screen_h = h
end

function UI.relX(ratio) return UI.screen_w * ratio end
function UI.relY(ratio) return UI.screen_h * ratio end
function UI.relW(ratio) return UI.screen_w * ratio end
function UI.relH(ratio) return UI.screen_h * ratio end

UI.color = {
    bg        = {0.02, 0.04, 0.08, 0.95},
    panel     = {0.05, 0.1,  0.15, 0.8 },
    highlight = {0,    1,    0.8       },
    accent    = {1,    0.8,  0         },
    danger    = {1,    0.2,  0.2       },
    text_main = {0.9,  1,    1         },
    text_dim  = {0.5,  0.6,  0.7      }
}

UI.layout = {
    dialogue = {
        x = 240, y = 520, w = 800, h = 160,
        padding = 40,
        portrait_scale = 300,
        portrait_y = 450,
        portrait_left_x  = 150,
        portrait_right_x = 1130,
        typewriter_speed = 0.03,
        continue_blink_speed = 4
    },
    choice = {
        x = 440, y = 200, w = 400, h = 40,
        gap = 50
    },
    panel_header_h = 25
}

-- ── 유틸리티 ──────────────────────────────────────────────────────────────

function UI.getFacePath(sprite_name, char_id)
    local AssetManager = require("systems.asset_manager")
    if not sprite_name or type(sprite_name) ~= "string" then
        return AssetManager.resolvePath("assets/images/" .. (char_id or "unknown") .. "_face.png")
    end
    local base = sprite_name:gsub("%.png$", "")
    local preferred = "assets/images/" .. base .. "_face.png"
    local resolved  = AssetManager.resolvePath(preferred)
    if love.filesystem.getInfo(resolved) then return resolved end
    return AssetManager.resolvePath("assets/images/" .. (char_id or "unknown") .. "_face.png")
end

function UI.drawWindow(rx, ry, rw, rh, title, color)
    local x = UI.relX(rx) - UI.relW(rw)/2
    local y = UI.relY(ry) - UI.relH(rh)/2
    local w = UI.relW(rw)
    local h = UI.relH(rh)
    UI.drawPanel(x, y, w, h, title, color)
    return x, y, w, h
end

-- ── 서브 모듈 설치 ────────────────────────────────────────────────────────

require("ui.theme_primitives").install(UI)
require("ui.theme_layout").install(UI)

return UI
