-- yank는 OSC 52로 터미널(iTerm2, Windows Terminal)을 거쳐 OS 클립보드에 보낸다.
-- Windows Terminal은 OSC 52 읽기를 지원하지 않으므로, p는 nvim 내부 레지스터를 쓴다.
-- OS 클립보드의 내용은 터미널 붙여넣기(Cmd+V, Ctrl+Shift+V)로 넣는다.
local osc52 = require('vim.ui.clipboard.osc52')

local function paste()
  return { vim.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
end

vim.g.clipboard = {
  name = 'OSC 52 (copy only)',
  copy = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
  paste = { ['+'] = paste, ['*'] = paste },
}

vim.opt.clipboard = 'unnamedplus'
