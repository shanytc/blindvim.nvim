local api = vim.api

local M = {
    config = {}
}

local default = {
    stop = false,
    timer = nil,
    loaded = false,
    started = false,
    isBlind = false,
    isHidden = false,
    flashlight = {},
    hiddenLines = {},
    hiddenLinesIds = {},
    fgColor = M.fg or "#D4D4D4",
    bgColor = M.bg or "#000000",
    bgColorBeforeArr = { '#525252', '#3F3F46', '#27272A', '#18181B', '#000000' },
    fgColorBeforeArr = { '#FAFAFA', '#F4F4F5', '#E4E4E7', '#A1A1AA', '#404040' },
}

M.setup = function(opt)
    M.config = vim.tbl_deep_extend('force', default, opt or {})
    M.config.loaded = true
end

vim.on_key(function(key)
    local loaded = M.config.loaded
    local started = M.config.started
    local isK_or_J_pressed = (key == 'k' or key == 'j')
    local blind = M.config.isBlind

    if not loaded then
        return
    end

    if blind then
        M._closeTimer()
        return
    end

    if isK_or_J_pressed and started then
        M.config.timer = vim.loop.new_timer()
        M.config.timer:start(10, 0, vim.schedule_wrap(function()
            M._blindvim()
            M._closeTimer()
        end))
    end
end)

M._hidelines = function()
    api.nvim_command("call clearmatches()")
    for _, value in pairs(M.config.hiddenLines) do
        api.nvim_command("highlight CustomHideLineNumber".. value .." guibg=#000000 guifg=#000000")
        api.nvim_command("call matchadd('CustomHideLineNumber" .. value .. "', '\\%" .. (value) .. "l')")
    end
end

M._flashlight = function()
    local bgColorBeforeArr = M.config.bgColorBeforeArr
    local fgColorBeforeArr = M.config.fgColorBeforeArr
    local fgColor = M.config.fgColor
    local bgColor = M.config.bgColor
    print("inside flashlight")
    for _, value in pairs(M.config.flashlight) do
        if value >= #bgColorBeforeArr then
            for i = 1, #bgColorBeforeArr do
                local hi = "highlight FlashLineNumber" ..
                    i .. " guibg=" .. bgColorBeforeArr[i] .. " guifg=" .. fgColorBeforeArr[i];
                api.nvim_command(hi)
                api.nvim_command("call matchadd('FlashLineNumber" .. i .. "', '\\%" .. (value - i) .. "l')")
            end
        elseif value < #bgColorBeforeArr then
            for i = 1, value % #bgColorBeforeArr do
                local hi = "highlight FlashLineNumber" ..
                    i .. " guibg=" .. bgColorBeforeArr[i] .. " guifg=" .. fgColorBeforeArr[i];
                api.nvim_command(hi)
                api.nvim_command("call matchadd('FlashLineNumber" .. i .. "', '\\%" .. (value - i) .. "l')")
            end
        end

        api.nvim_command("highlight FlashLineNumber guibg=" .. fgColor .. " guifg=" .. bgColor)
        api.nvim_command("call matchadd('FlashLineNumber', '\\%" .. (value) .. "l')")

        for i = 1, #bgColorBeforeArr do
            local hi = "highlight FlashLineNumber" .. i .. " guibg=" ..
                bgColorBeforeArr[i] .. " guifg=" .. fgColorBeforeArr[i];
            api.nvim_command(hi)
            api.nvim_command("call matchadd('FlashLineNumber" .. i .. "', '\\%" .. (value + i) .. "l')")
        end
    end
end

M._blind = function()
    local totallines = vim.fn.line('$')
    api.nvim_command("call clearmatches()")

    -- Enable blind mode (hide all text)
    for i = 1, totallines do
        local hi = "highlight CustomBlindLineNumber" .. i .. " guibg=#000000 guifg=#000000";
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomBlindLineNumber" .. i .. "', '\\%" .. (i) .. "l')")
    end
end

M._blindvim = function()
    local bgColorBeforeArr = M.config.bgColorBeforeArr
    local fgColorBeforeArr = M.config.fgColorBeforeArr
    local fgColor = M.config.fgColor
    local bgColor = M.config.bgColor
    local totallines = vim.fn.line('$')
    local isBlind = M.config.isBlind
    local started = M.config.started
    local loaded = M.config.loaded
    local isHidden = M.config.isHidden

    if not loaded then
        return
    end

    if isBlind or isHidden then
        return
    end

    if not started then
        return
    end

    -- Get the current line number
    local lineNum = api.nvim_win_get_cursor(0)[1]
    -- got the current selected text
    --local lineText = api.nvim_buf_get_lines(0, lineNum-1, lineNum, true)[1]

    -- clear whatever selected
    api.nvim_command("call clearmatches()")

    -- hide all code before dimming
    for i = 1, lineNum do
        local hi = "highlight CustomBeforeLineNumber" .. i .. " guibg=#000000 guifg=#000000";
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomBeforeLineNumber" .. i .. "', '\\%" .. (i) .. "l')")
    end

    -- apply dimming highlights before current line
    if lineNum >= #bgColorBeforeArr then
        for i = 1, #bgColorBeforeArr do
            local hi = "highlight CustomLineNumber" .. i ..
                " guibg=" .. bgColorBeforeArr[i] .. " guifg=" .. fgColorBeforeArr[i];
            api.nvim_command(hi)
            api.nvim_command("call matchadd('CustomLineNumber" .. i .. "', '\\%" .. (lineNum - i) .. "l')")
        end
    elseif lineNum < #bgColorBeforeArr then
        for i = 1, lineNum % #bgColorBeforeArr do
            local hi = "highlight CustomLineNumber" .. i ..
                " guibg=" .. bgColorBeforeArr[i] .. " guifg=" .. fgColorBeforeArr[i];
            api.nvim_command(hi)
            api.nvim_command("call matchadd('CustomLineNumber" .. i .. "', '\\%" .. (lineNum - i) .. "l')")
        end
    end

    -- highlight current line
    api.nvim_command("highlight CurrentLineNumber guibg=" .. fgColor .. " guifg=" .. bgColor)
    api.nvim_command("call matchadd('CurrentLineNumber', '\\%" .. (lineNum) .. "l')")

    -- apply dimming lights after current line
    for i = 1, #bgColorBeforeArr do
        local hi = "highlight CustomLineNumber" .. i .. " guibg=" .. bgColorBeforeArr[i] ..
            " guifg=" .. fgColorBeforeArr[i];
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomLineNumber" .. i .. "', '\\%" .. (lineNum + i) .. "l')")
    end

    -- hide all code after dimming
    for i = lineNum + 1 + #bgColorBeforeArr, totallines do
        local hi = "highlight CustomAfterLineNumber" .. i .. " guibg=#000000 guifg=#000000";
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomAfterLineNumber" .. i .. "', '\\%" .. (i) .. "l')")
    end

    -- call flsahlight
    M._flashlight()
end

M.start = function()
    M.config.started = true
    M.config.isBlind = false
    M._blindvim()
end

M._closeTimer = function ()
    if M.config.timer ~= nil then
        M.config.timer:close()
        M.config.timer = nil
    end
end

M.stop = function()
    api.nvim_command("call clearmatches()")
    M.config.started = false
    M.config.isBlind = false
    M.config.isHidden = false
    M.config.flashlight = {}
    M.config.hiddenLines = {}
    M._closeTimer()
end

M.blind = function()
    local loaded = M.config.loaded

    if not loaded then
        return
    end

    M.stop()
    M.config.isBlind = true
    M._blind()
end

M.mark = function()
    local started = M.config.started

    if not started then
        return
    end

    local lineNum = api.nvim_win_get_cursor(0)[1]
    if M.config.flashlight[lineNum] == nil then
        M.config.flashlight[lineNum] = lineNum
    end

    M._blindvim()
end

M.unmark = function()
    local started = M.config.started

    if not started then
        return
    end

    local lineNum = api.nvim_win_get_cursor(0)[1]
    M.config.flashlight[lineNum] = nil
    M._blindvim()
end

M.clear_marks = function()
    local started = M.config.started

    if not started then
        return
    end

    M.config.flashlight = {}
    M._blindvim()
end

M.hide = function()
    local loaded = M.config.loaded

    if not loaded then
        return
    end

    M.config.isHidden = true

    local lineNum = api.nvim_win_get_cursor(0)[1]
    if M.config.hiddenLines[lineNum] == nil then
        M.config.hiddenLines[lineNum] = lineNum
    end

    M._hidelines()
end

M.unhide = function()
    local loaded = M.config.loaded

    if not loaded then
        return
    end

    M.config.isHidden = true

    local lineNum = api.nvim_win_get_cursor(0)[1]
    M.config.hiddenLines[lineNum] = nil

    M._hidelines()
end

M.hideSelectedLines = function()
    local loaded = M.config.loaded
    local mode = api.nvim_get_mode()["mode"]

    if not loaded then
        return
    end

    if mode ~= "V" then
        return
    end

    M.config.isHidden = true

    local get_visual = function()
        local curpos = vim.fn.getcurpos()
        local one = { row = curpos[2], col = curpos[3] }
        local two = { row = vim.fn.line('v'), col = vim.fn.col('v') }

        if one.row == two.row then
            if one.col > two.col then
                local tmp = one
                one = two
                two = tmp
            end
        elseif one.row > two.row then
            local tmp = one
            one = two
            two = tmp
        end

        two.col = two.col + 1
        return { startLine = one, endLine = two }
    end

    local lineresult = get_visual()
    local startline = lineresult.startLine.row
    local endline = lineresult.endLine.row

    for i=startline, endline do
        if M.config.hiddenLines[i] == nil then
            M.config.hiddenLines[i] = i
        end
    end

    M._hidelines()
    -- move cursor to the last selected lines
    api.nvim_win_set_cursor(0,{lineresult.endLine.row, 0})

    -- cancel visual selection mode by sending Esc
    local key = api.nvim_replace_termcodes("<Esc>",true,false,true)
    api.nvim_feedkeys(key,'v',false)
end

M.clear_hidden_lines = function()
    M.stop()
end

return M
