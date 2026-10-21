#!/usr/bin/env bash
# 개발 컨테이너가 시작될 때마다 dev 사용자로 실행된다 (postStartCommand).
# 각 단계는 실패해도 컨테이너 시작을 막지 않는다.
set -uo pipefail

COMMON=/opt/claude-container/common
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
export PATH="$HOME/.local/bin:$PATH"

log() { echo "[post-start] $*"; }

# 1. 공통 설정 덮어쓰기 (docs/adr/0002). skills는 제외한다.
log '공통 설정을 ~/.claude에 반영합니다'
mkdir -p "$CLAUDE_DIR/hooks"
cp "$COMMON/claude/settings.json" "$COMMON/claude/CLAUDE.md" \
   "$COMMON/claude/statusline-command.sh" "$COMMON/claude/statusline-wrapper.sh" "$CLAUDE_DIR/"
cp "$COMMON/claude/hooks/"* "$CLAUDE_DIR/hooks/"
# statusline의 ccstatusline 설정: ~/.config는 volume이 아니므로 시작할 때마다 다시 쓴다.
mkdir -p "$HOME/.config/ccstatusline"
cp "$COMMON/ccstatusline/settings.json" "$HOME/.config/ccstatusline/"

# 2. git 설정: ~/.gitconfig는 volume이 아니므로 시작할 때마다 다시 쓴다.
[ -n "${GIT_USER_NAME:-}" ] && git config --global user.name "$GIT_USER_NAME"
[ -n "${GIT_USER_EMAIL:-}" ] && git config --global user.email "$GIT_USER_EMAIL"
# bind mount된 작업 루트의 파일 소유자가 달라도 git이 거부하지 않게 한다.
git config --global --replace-all safe.directory '*'
# HTTPS 인증 (push와 private 레포 clone에 쓰인다): 로그인되어 있으면 gh·glab을 credential helper로 쓴다.
if gh auth status >/dev/null 2>&1; then
  gh auth setup-git
fi
if [ -n "${GITLAB_HOST:-}" ]; then
  git config --global "credential.https://${GITLAB_HOST}.helper" '!glab auth git-credential'
fi

# 3. skills: 없을 때만 clone한다. 이후 갱신은 사용자가 직접 git pull 한다.
if [ ! -e "$CLAUDE_DIR/skills" ]; then
  log 'skills 레포를 clone합니다'
  # 인증 입력을 기다리며 멈추지 않게 한다. 실패해도 다음 단계는 진행된다.
  GIT_TERMINAL_PROMPT=0 git clone https://github.com/ingee/claude-skills.git "$CLAUDE_DIR/skills" || log 'skills clone 실패 (다음 시작 때 다시 시도됩니다)'
fi

# 4. 플러그인: 설치되어 있지 않을 때만 설치한다.
if ! grep -qs '"mattpocock-skills@claude-plugins-official"' "$CLAUDE_DIR/plugins/installed_plugins.json"; then
  log 'mattpocock-skills 플러그인을 설치합니다'
  claude plugin marketplace add anthropics/claude-plugins-official >/dev/null 2>&1 || true
  claude plugin install mattpocock-skills@claude-plugins-official || log '플러그인 설치 실패 (나중에 다시 시도됩니다)'
fi

# 5. atlassian MCP: .env에 Confluence 또는 Jira URL이 있을 때만 등록한다.
#    토큰은 설정 파일에 쓰지 않고, 컨테이너 환경변수를 MCP 서버가 물려받는다.
claude mcp remove --scope user atlassian >/dev/null 2>&1 || true
if [ -n "${CONFLUENCE_URL:-}" ] || [ -n "${JIRA_URL:-}" ]; then
  log 'atlassian MCP를 등록합니다'
  claude mcp add --scope user atlassian -- uvx mcp-atlassian >/dev/null || log 'atlassian MCP 등록 실패'
fi

# 6. nvim 플러그인, LSP 서버, treesitter 파서: 없는 것만 volume에 설치한다 (docs/adr/0003).
#    volume이 비어 있는 첫 시작에는 몇 분 걸린다.
log 'nvim 플러그인을 확인합니다'
"$(dirname "${BASH_SOURCE[0]}")/nvim-plugins.sh" || log 'nvim 플러그인 설치 일부 실패 (다음 시작 때 다시 시도됩니다)'

log '완료'
