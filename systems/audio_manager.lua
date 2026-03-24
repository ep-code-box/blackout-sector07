-- 오디오 매니저 (BGM 및 SFX 관리)
local AudioManager = {}

AudioManager.bgm_volume = 0.5
AudioManager.sfx_volume = 0.8
AudioManager.current_bgm = nil
AudioManager.current_bgm_name = nil

local cache = {
    bgm = {},
    sfx = {}
}

-- BGM 부드러운 전환을 위한 변수
local fade_out_source = nil
local fade_timer = 0
local fade_in_timer = 0
local FADE_DURATION = 1.5

function AudioManager.update(dt)
    -- 페이드 아웃 로직
    if fade_out_source and fade_timer > 0 then
        fade_timer = fade_timer - dt
        local vol = (fade_timer / FADE_DURATION) * AudioManager.bgm_volume
        fade_out_source:setVolume(math.max(0, vol))
        
        if fade_timer <= 0 then
            fade_out_source:stop()
            fade_out_source = nil
        end
    end

    -- [신규] 페이드 인 로직
    if AudioManager.current_bgm and fade_in_timer < FADE_DURATION then
        fade_in_timer = fade_in_timer + dt
        local vol = math.min(1, fade_in_timer / FADE_DURATION) * AudioManager.bgm_volume
        AudioManager.current_bgm:setVolume(vol)
    end
end

function AudioManager.playBGM(name, path)
    -- 이미 같은 곡이 재생 중이면 아무것도 하지 않음
    if AudioManager.current_bgm_name == name then 
        print("🎵 BGM already playing: " .. name)
        return 
    end
    
    -- 만약 페이드 아웃 중인 곡이 이번에 요청한 곡과 같다면 페이드 아웃 취소
    if fade_out_source and name == AudioManager.current_bgm_name then
        AudioManager.current_bgm = fade_out_source
        fade_out_source = nil
        fade_in_timer = (fade_timer / FADE_DURATION) * FADE_DURATION
        fade_timer = 0
        print("🎵 Cancelled fade-out for: " .. name)
        return
    end

    print("🎵 Requesting BGM: " .. name .. " from " .. path)
    
    local source = cache.bgm[name]
    
    if not source then
        if not love.filesystem.getInfo(path) then
            print("⚠️ BGM File Not Found: " .. path)
            return
        end
        source = love.audio.newSource(path, "stream")
        source:setLooping(true)
        cache.bgm[name] = source
    end

    -- 기존 음악이 있다면 페이드 아웃 목록으로 이동
    if AudioManager.current_bgm then
        fade_out_source = AudioManager.current_bgm
        fade_timer = FADE_DURATION
        print("🔈 Switching BGM. Fading out previous track.")
    end

    AudioManager.current_bgm = source
    AudioManager.current_bgm_name = name
    
    fade_in_timer = 0
    source:setVolume(0)
    source:play()
    print("🔊 Playing BGM (Fade-in): " .. name)
end

function AudioManager.playSFX(name, path)
    local source = cache.sfx[name]
    
    if not source then
        if not love.filesystem.getInfo(path) then
            print("⚠️ SFX Not Found: " .. path)
            return
        end
        -- SFX는 메모리에 완전히 올려서 지연 없이 재생
        source = love.audio.newSource(path, "static")
        cache.sfx[name] = source
    end
    
    -- 효과음은 여러 번 겹쳐 들릴 수 있도록 복제해서 재생
    local s = source:clone()
    s:setVolume(AudioManager.sfx_volume)
    s:play()
end

function AudioManager.stopBGM()
    if AudioManager.current_bgm then
        fade_out_source = AudioManager.current_bgm
        fade_timer = FADE_DURATION
        AudioManager.current_bgm = nil
        AudioManager.current_bgm_name = nil
    end
end

return AudioManager
