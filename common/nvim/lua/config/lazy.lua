-- 플러그인 관리자 lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    -- vim-airline 대체
    {
      'nvim-lualine/lualine.nvim',
      opts = {
        options = { theme = 'auto', icons_enabled = false },
        tabline = { lualine_a = { 'buffers' } },  -- airline의 tabline(버퍼 목록) 대체
      },
    },

    -- vimrc에서 쓰던 들여쓰기 단위 이동
    { 'jeetsukumaran/vim-indentwise' },

    -- LSP 서버 바이너리 설치 (개발 컨테이너가 시작될 때 nvim-plugins.sh가 설치한다)
    { 'mason-org/mason.nvim', lazy = false, opts = {} },

    -- LSP 서버별 기본 설정 (lsp/*.lua) 제공
    { 'neovim/nvim-lspconfig', lazy = false },

    -- 자동완성
    {
      'saghen/blink.cmp',
      version = '1.*',
      event = 'InsertEnter',
      opts = {
        keymap = { preset = 'default' },
        fuzzy = { implementation = 'lua' },
      },
    },

    -- 구문 강조 (typescript-vim 대체). 파서는 개발 컨테이너가 시작될 때 설치된다.
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      lazy = false,
      build = ':TSUpdate',
      config = function()
        vim.api.nvim_create_autocmd('FileType', {
          callback = function() pcall(vim.treesitter.start) end,
        })
      end,
    },

    -- 파일, 문자열, 심볼 검색
    { 'ibhagwan/fzf-lua', cmd = 'FzfLua', opts = {} },
  },
  -- 설정 디렉터리(~/.config/nvim)는 읽기 전용 mount이므로 잠금 파일은 volume에 둔다.
  lockfile = vim.fn.stdpath('data') .. '/lazy-lock.json',
  install = { colorscheme = { 'retrobox' } },
  checker = { enabled = false },
  change_detection = { enabled = false },
})
