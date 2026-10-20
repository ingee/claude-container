-- 공통 옵션은 vimscript 파일로 유지한다 (options.vim).
vim.cmd.source(vim.fn.stdpath('config') .. '/options.vim')

require('config.clipboard')
require('config.lazy')
require('config.lsp')
require('config.keymaps')
