function love.conf(t)
    t.window = t.window or {}
    t.window.highdpi = true
    t.window.title = "Diablo2D"
    -- Set background color to dark gray instead of black
    t.window.backgroundColor = { 0.05, 0.05, 0.05, 1 }
end
