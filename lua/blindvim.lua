local M = {}
local api = vim.api
local default = {
  stop = false,
  timer = nil,
  flashlight={},
  fgColor = M.fg or "#D4D4D4",
  bgColor = M.bg or "#000000",
  bgColorBeforeArr = {'#525252','#3F3F46','#27272A','#18181B','#000000'},
  fgColorBeforeArr = {'#FAFAFA','#F4F4F5','#E4E4E7','#A1A1AA','#404040'},
}

M.setup = function(opt)
  M.config = vim.tbl_deep_extend('force', default, opt or {})
end

 M._flashlight = function()
    for key, value in pairs(M.flashlight) do
      if value >= #M.bgColorBeforeArr then
        for i=1, #M.bgColorBeforeArr do
          local hi ="highlight FlashLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
          api.nvim_command(hi)
          api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value-i).."l')")
        end
      elseif value < #M.bgColorBeforeArr then
        for i=1, value % #M.bgColorBeforeArr do
          local hi ="highligrt FlashLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
          api.nvim_command(hi)
          api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value-i).."l')")
        end
      end

      api.nvim_command("highlight FlashLineNumber guibg="..M.fgColor.." guifg="..M.bgColor)
      api.nvim_command("call matchadd('FlashLineNumber', '\\%"..(value).."l')")

      for i=1, #M.bgColorBeforeArr do
        local hi ="highlight FlashLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
        api.nvim_command(hi)
        api.nvim_command("call matchadd('FlashLineNumber"..i.."', '\\%"..(value+i).."l')")
      end
    end
  end


M._blindvim = function()
    local totallines = vim.fn.line('$')
    -- Get the current line number
    local lineNum = api.nvim_win_get_cursor(0)[1]
    -- got the current selected text
    --local lineText = api.nvim_buf_get_lines(0, lineNum-1, lineNum, true)[1] 
    -- clear whatever selected
    api.nvim_command("call clearmatches()")

    -- hide all code before dimming
    for i=1, lineNum do
      local hi ="highlight CustomBeforeLineNumber"..i.." guibg=#000000 guifg=#000000";
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomBeforeLineNumber"..i.."', '\\%"..(i).."l')")
    end

    -- apply dimming highlights before current line
    if lineNum >= #M.bgColorBeforeArr then
      for i=1, #M.bgColorBeforeArr do
        local hi ="highlight CustomLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum-i).."l')")
      end
    elseif lineNum < #M.bgColorBeforeArr then
      for i=1, lineNum % #M.bgColorBeforeArr do
        local hi ="highlight CustomLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
        api.nvim_command(hi)
        api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum-i).."l')")
      end
    end

    -- highlight current line
    api.nvim_command("highlight CurrentLineNumber guibg="..M.fgColor.." guifg="..M.bgColor)
    api.nvim_command("call matchadd('CurrentLineNumber', '\\%"..(lineNum).."l')")

    -- apply dimming lights after current line
    for i=1, #M.bgColorBeforeArr do
      local hi ="highlight CustomLineNumber"..i.." guibg="..M.bgColorBeforeArr[i].." guifg="..M.fgColorBeforeArr[i];
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomLineNumber"..i.."', '\\%"..(lineNum+i).."l')")
    end

    -- hide all code after dimming
    for i=lineNum+1+#M.bgColorBeforeArr, totallines do
      local hi ="highlight CustomAfterLineNumber"..i.." guibg=#000000 guifg=#000000";
      api.nvim_command(hi)
      api.nvim_command("call matchadd('CustomAfterLineNumber"..i.."', '\\%"..(i).."l')")
    end

    -- call flsahlight
    M._flashlight()
  end

M.start = function()
  M.stop = false
  vim.on_key(function (key)
    if (key == 'k' or key == 'j') and M.stop == false then
      M.timer = vim.loop.new_timer()
      M.timer:start(10, 0, vim.schedule_wrap(function()
        M._blindvim()
      end))
    end
  end)

  M._blindvim()
end

M.stop = function()
  api.nvim_command("call clearmatches()")
  M.stop = true
  if M.timer ~= nil then
	  M.timer:close()
	  M.timer = nil
  end
  M.flashlight = {}
end

M.mark = function()
  if M.timer == nil then
	  print("blindvim not active")
	  return
  end

  local lineNum = api.nvim_win_get_cursor(0)[1]
  if M.flashlight[lineNum] == nil then
	  M.flashlight[lineNum]=lineNum
  end
end

M.unmark = function()
  if M.timer == nil then
	  return
  end
  local lineNum = api.nvim_win_get_cursor(0)[1]
  M.flashlight[lineNum]=nil
end

M.clear = function()
  M.flashlight = {}
  M.start()
end

return M
