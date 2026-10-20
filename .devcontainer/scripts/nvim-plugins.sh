#!/usr/bin/env bash
# 개발 컨테이너가 시작될 때 post-start.sh가 dev 사용자로 실행한다.
# headless nvim으로 플러그인, LSP 서버, treesitter 파서 중 없는 것만 volume(~/.local/share/nvim)에 설치한다.
# 이미 설치된 것은 갱신하지 않는다. 갱신은 nvim 안에서 :Lazy update, :MasonUpdate로 한다 (docs/adr/0003).
set -uo pipefail

log() { echo "[nvim-plugins] $*"; }
failed=0

log '플러그인 확인 (lazy.nvim)'
nvim --headless '+Lazy! install' +qa || failed=1

log 'LSP 서버 확인 (Mason)'
nvim --headless -c "lua
  local registry = require('mason-registry')
  local missing = vim.tbl_filter(function(name)
    return not registry.is_installed(name)
  end, require('config.lsp').mason_packages)
  if #missing > 0 then
    print('설치: ' .. table.concat(missing, ' '))
    vim.cmd('MasonInstall ' .. table.concat(missing, ' '))
  end" -c qa || failed=1

mason_bin="$HOME/.local/share/nvim/mason/bin"
for bin in typescript-language-server jdtls pyright-langserver lua-language-server bash-language-server tree-sitter; do
  if [ ! -x "$mason_bin/$bin" ]; then
    log "설치 실패: $bin"
    failed=1
  fi
done
if [ ! -x /go/bin/gopls ]; then
  log 'go Feature가 gopls를 설치하지 않았습니다: /go/bin/gopls'
  failed=1
fi

log 'treesitter 파서 확인'
nvim --headless -c "lua require('nvim-treesitter').install(require('config.lsp').treesitter_parsers):wait(600000)" -c qa || failed=1

exit "$failed"
