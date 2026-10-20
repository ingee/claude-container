#!/usr/bin/env bash
# 개발 이미지 빌드 시점에 root로 실행된다. dev 사용자 홈에 설치하는 작업은 dev로 실행한다.
set -euo pipefail

USERNAME="${_REMOTE_USER:-dev}"
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
# 공통 설정은 빌드 시점에는 없고, 개발 컨테이너가 실행될 때 이 경로에 mount된다 (docs/adr/0002).
COMMON=/opt/claude-container/common

as_user() {
  sudo -u "$USERNAME" -H "$@"
}

# volume의 mount 지점: 미리 만들어 두어야 volume이 dev 소유로 생성된다.
as_user mkdir -p "$USER_HOME/.claude" "$USER_HOME/.config/gh" "$USER_HOME/.config/glab-cli" "$USER_HOME/work" \
  "$USER_HOME/.local/share/nvim"

# Claude Code: native installer (docs/adr/0001)
as_user bash -c 'curl -fsSL https://claude.ai/install.sh | bash'

# bash 설정
if ! grep -q 'claude-container/common/shell/bashrc' "$USER_HOME/.bashrc"; then
  echo "[ -f $COMMON/shell/bashrc ] && . $COMMON/shell/bashrc" >> "$USER_HOME/.bashrc"
fi

# nvim 설정: mount된 공통 설정을 가리킨다. 플러그인은 시작할 때 volume에 설치한다 (docs/adr/0003).
as_user mkdir -p "$USER_HOME/.config"
as_user rm -rf "$USER_HOME/.config/nvim"
as_user ln -s "$COMMON/nvim" "$USER_HOME/.config/nvim"
