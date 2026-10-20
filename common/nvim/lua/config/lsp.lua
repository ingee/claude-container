-- LSP 서버 설정 (nvim 0.11+ 내장 vim.lsp.config / vim.lsp.enable)
-- 서버 바이너리는 Mason이 설치하고, 기본 설정은 nvim-lspconfig가 제공한다.

local M = {}

-- 개발 컨테이너가 시작될 때 Mason으로 설치할 패키지 (nvim-plugins.sh가 읽는다)
-- gopls는 go Feature가 /go/bin에 설치하므로 여기서 설치하지 않는다.
M.mason_packages = {
  'typescript-language-server',  -- node.js / typescript
  'jdtls',                       -- java
  'pyright',                     -- python
  'lua-language-server',         -- nvim 설정 편집
  'bash-language-server',        -- shell script
  'tree-sitter-cli',             -- nvim-treesitter 파서 빌드
}

-- 개발 컨테이너가 시작될 때 설치할 treesitter 파서
M.treesitter_parsers = {
  'bash', 'go', 'gomod', 'java', 'javascript', 'typescript', 'tsx',
  'json', 'yaml', 'lua', 'python', 'markdown', 'markdown_inline',
  'vim', 'vimdoc', 'dockerfile',
}

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
    },
  },
})

vim.lsp.enable({ 'ts_ls', 'jdtls', 'gopls', 'pyright', 'lua_ls', 'bashls' })

vim.diagnostic.config({ virtual_text = true })

return M
