-- 다국어 지원 매니저 (i18n - Unified Version)
local i18n = {}
local translations = require("data.translations")
local current_lang = "ko" -- 기본 언어 설정

-- 언어 설정 변경 함수
function i18n.setLanguage(lang_code)
    current_lang = lang_code or "ko"
    print("🌐 Current Language: " .. current_lang)
end

-- 키 값을 현재 언어 텍스트로 변환하는 전역 함수
function L(key)
    local entry = translations[key]
    if entry then
        return entry[current_lang] or entry["en"] or key
    end
    return key
end

return i18n