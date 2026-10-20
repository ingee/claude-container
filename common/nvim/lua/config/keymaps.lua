-- nvim 0.11+ 기본 LSP 키맵: K(문서), grn(이름 변경), gra(코드 액션), grr(참조), gri(구현), gO(심볼)
-- 여기서는 vim 사용자에게 익숙한 몇 가지만 추가한다.

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  end,
})

-- vimrc의 <F9> TagbarToggle 대체: 현재 파일의 LSP 심볼 목록
vim.keymap.set('n', '<F9>', '<cmd>FzfLua lsp_document_symbols<CR>')

-- 검색
vim.keymap.set('n', '<leader>ff', '<cmd>FzfLua files<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>FzfLua live_grep<CR>')
vim.keymap.set('n', '<leader>fb', '<cmd>FzfLua buffers<CR>')
