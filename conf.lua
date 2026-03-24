function love.conf(t)
    -- love client -- --test 로 실행 시 창 없이 헤드리스 모드
    for _, v in ipairs(arg or {}) do
        if v == "--test" then
            t.window.width   = 1
            t.window.height  = 1
            t.window.title   = "TEST MODE"
            t.window.visible = false
            return
        end
    end

    t.window.width   = 1280
    t.window.height  = 720
    t.window.title   = "SECTOR 07"
    t.window.vsync   = true
    t.window.resizable = false
end
