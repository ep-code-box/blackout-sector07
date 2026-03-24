-- 사이버펑크 글리치 및 CRT 셰이더 매니저
local ShaderManager = {}

local glitch_shader_code = [[
    uniform float time;
    uniform float intensity;

    vec4 effect(vec4 vcolor, Image tex, vec2 tc, vec2 pc) {
        // 색수차 (Chromatic Aberration) 오프셋
        float r_offset = 0.01 * intensity * sin(time * 50.0);
        float b_offset = -0.01 * intensity * cos(time * 40.0);
        
        // 화면 찢어짐 (Scanline Glitch)
        float glitch_line = step(0.98, sin(tc.y * 100.0 + time * 10.0));
        vec2 uv = tc;
        uv.x += glitch_line * 0.05 * intensity * sin(time * 20.0);

        vec4 r_tex = Texel(tex, vec2(uv.x + r_offset, uv.y));
        vec4 g_tex = Texel(tex, uv);
        vec4 b_tex = Texel(tex, vec2(uv.x + b_offset, uv.y));

        return vec4(r_tex.r, g_tex.g, b_tex.b, g_tex.a) * vcolor;
    }
]]

function ShaderManager.load()
    ShaderManager.shader = love.graphics.newShader(glitch_shader_code)
    ShaderManager.intensity = 0.0
    ShaderManager.time = 0.0
end

function ShaderManager.update(dt)
    ShaderManager.time = ShaderManager.time + dt
    -- 글리치 강도가 서서히 줄어듦 (타격 순간에 1.0으로 올리고 서서히 복구)
    ShaderManager.intensity = math.max(0, ShaderManager.intensity - dt * 2.0)
    
    if ShaderManager.shader then
        ShaderManager.shader:send("time", ShaderManager.time)
        ShaderManager.shader:send("intensity", ShaderManager.intensity)
    end
end

function ShaderManager.trigger(amount)
    ShaderManager.intensity = amount or 1.0
end

function ShaderManager.apply()
    if ShaderManager.intensity > 0 then
        love.graphics.setShader(ShaderManager.shader)
    end
end

function ShaderManager.clear()
    love.graphics.setShader()
end

return ShaderManager
