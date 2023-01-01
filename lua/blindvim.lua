local M = {}
local api = vim.api
local default = {
  stop = false,
  timer = nil,
  flashlight={},
  blindMode=false,
  fgColor = M.fg or "#D4D4D4",
  bgColor = M.bg or "#000000",
  bgColorBeforeArr = {'#525252','#3F3F46','#27272A','#18181B','#000000'},
  fgColorBeforeArr = {'#FAFAFA','#F4F4F5','#E4E4E7','#A1A1AA','#404040'},
}

M.setup = function(opt)
  M.config = vim.tbl_deep_extend('force', default, opt or {})
end

 M._flashlight = function()
    local bgColorBeforeArr = M.config.bgColorBeforeArr
    local fgColorBeforeArr = M.config.fgColorBeforeArr
    local fgColor = M.config.fgColor
    local bgColor = M.config.bgColor

    for _, value in pairs(M.config.flashlight) do
      if value >= #bgColorBeforeArr then
        for i=1, #bgColorBeforeArr do
          local hi ="highlight FlashLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
          api.nvim_command(hi)
          api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value-i).."l')")
        end
      elseif value < #bgColorBeforeArr then
        for i=1, value % #bgColorBeforeArr do
          local hi ="highlight FlashLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
          api.nvim_command(hi)
          api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value-i).."l')")
        end
      end

      api.nvim_command("highlight FlashLineNumber guibg="..fgColor.." guifg="..bgColor)
      api.nvim_command("call matchadd('FlashLineNumber', '\\%"..(value).."l')")

      for i=1, #bgColorBeforeArr do
        local hi ="highlight FlashLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
        api.nvim_command(hi)
        api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value+i).."l')")
      end
    end
  end

M._blindvim = function()
  local bgColorBeforeArr = M.config.bgColorBeforeArr
  local fgColorBeforeArr = M.config.fgColorBeforeArr
  local fgColor = M.config.fgColor
  local bgColor = M.config.bgColor
  local totallines = vim.fn.line('$')
  local blindMode = M.config.blindMode
  -- Get the current line number
  local lineNum = api.nvim_win_get_cursor(0)[1]
  -- got the current selected text
  --local lineText = api.nvim_buf_get_lines(0, lineNum-1, lineNum, true)[1] 
  -- clear whatever selected
  api.nvim_command("call clearmatches()")

  if blindMode then
    for i=1, totallines do
      local hi ="highlight CustomBeforeLineNumber"..i.." guibg=#000000 guifg=#000000";
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomBeforeLineNumber"..i.."', '\\%"..(i).."l')")
    end
    return
  end
  -- hide all code before dimming
  for i=1, lineNum do
    local hi ="highlight CustomBeforeLineNumber"..i.." guibg=#000000 guifg=#000000";
    api.nvim_command(hi)
    api.nvim_command("call matchadd('CustomBeforeLineNumber"..i.."', '\\%"..(i).."l')")
  end

  -- apply dimming highlights before current line
  if lineNum >= #bgColorBeforeArr then
    for i=1, #bgColorBeforeArr do
      local hi ="highlight CustomLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum-i).."l')")
    end
  elseif lineNum < #bgColorBeforeArr then
    for i=1, lineNum % #bgColorBeforeArr do
      local hi ="highlight CustomLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum-i).."l')")
    end
  end

  -- highlight current line
  api.nvim_command("highlight CurrentLineNumber guibg="..fgColor.." guifg="..bgColor)
  api.nvim_command("call matchadd('CurrentLineNumber', '\\%"..(lineNum).."l')")

  -- apply dimming lights after current line
  for i=1, #bgColorBeforeArr do
    local hi ="highlight CustomLineNumber"..i.." guibg="..bgColorBeforeArr[i].." guifg="..fgColorBeforeArr[i];
    api.nvim_command(hi)
    api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum+i).."l')")
  end

  -- hide all code after dimming
  for i=lineNum+1+#bgColorBeforeArr, totallines do
    local hi ="highlight CustomAfterLineNumber"..i.." guibg=#000000 guifg=#000000";
    api.nvim_command(hi)
    api.nvim_command("call matchadd('CustomAfterLineNumber"..i.."', '\\%"..(i).."l')")
  end

  -- call flsahlight
  M._flashlight()
  end

M.start = function()
  M.config.stop = false
  vim.on_key(function (key)
    if (key == 'k' or key == 'j') and M.config.stop == false then
      M.config.timer = vim.loop.new_timer()
      M.config.timer:start(10, 0, vim.schedule_wrap(function()
        M._blindvim()
      end))
    end
  end)

  M._blindvim()
end

M.stop = function()
  api.nvim_command("call clearmatches()")
  M.config.stop = true
  if M.config.timer ~= nil then
    M.config.timer:close()
    M.config.timer = nil
  end
  M.config.flashlight = {}
end

M.mark = function()
  if M.config.timer == nil or M.config.bgColor then
    return
  end

  local lineNum = api.nvim_win_get_cursor(0)[1]
  if M.config.flashlight[lineNum] == nil then
    M.config.flashlight[lineNum]=lineNum
  end
end

M.blind = function()
  M.config.blindMode = true
  M.start()
end

M.unblind = function()
  M.config.blindMode = false
  M.start()
end

M.unmark = function()
  if M.config.timer == nil then
    return
  end
  local lineNum = api.nvim_win_get_cursor(0)[1]
  M.config.flashlight[lineNum]=nil
end

M.clear = function()
  M.config.flashlight = {}
  M.start()
end

return M
