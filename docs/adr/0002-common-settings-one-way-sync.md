# 공통 설정은 컨테이너 시작 시마다 빌드 레포 기준으로 덮어쓴다

로그인과 대화 이력을 유지하려고 `~/.claude`를 named volume으로 두면, volume의 옛 공통 설정이 새 설정을 가린다. 그래서 공통 설정은 빌드 레포의 `common/`을 개발 컨테이너의 `/opt/claude-container/common`에 읽기 전용으로 mount하고, 개발 컨테이너가 시작될 때마다 `~/.claude`로 복사해 덮어쓴다. 결과적으로 개발 컨테이너 안에서 공통 설정을 직접 고쳐도 다음 시작 때 사라지며, 공통 설정은 반드시 빌드 레포에서 고쳐야 한다.

처음에는 `common/`을 개발 이미지에 `COPY`했다. 하지만 Feature가 Dockerfile 위에 쌓이는 구조라서, 공통 설정을 한 줄만 고쳐도 빌드 캐시가 깨져 Feature(node, java, go 등)를 모두 다시 설치했고, 그 과정에서 도구 버전까지 바뀌었다. mount로 바꾸면서 공통 설정 변경은 빌드와 무관해졌다. `~/.bashrc`가 source하는 `common/shell/bashrc`와 symlink로 연결한 `~/.config/nvim`은 개발 컨테이너를 다시 만들지 않아도 바로 반영된다. 시작 시점 스크립트(`.devcontainer/scripts/`)도 같은 이유로 `/opt/claude-container/bin`에 mount한다. 대가로 개발 컨테이너가 떠 있는 동안 빌드 레포를 옮기거나 지우면 안 된다.

예외로 `~/.claude/skills`는 덮어쓰지 않는다. 처음 시작할 때 없으면 `ingee/claude-skills`를 clone하고, 이후 갱신은 사용자가 그 디렉터리에서 직접 `git pull`로 한다. skills는 공통 설정이면서 동시에 사용자가 직접 고치고 push하는 레포이기 때문이다.

Claude Code 설정(`settings.json`)은 복사하지 않는다. 공통 키(`hooks`, `statusLine`, `enabledPlugins`)는 `common/claude-managed/`를 `/etc/claude-code`에 mount해 managed settings로 적용하고, `~/.claude/settings.json`은 사용자 몫으로 volume에 남긴다. Claude Code는 테마(`theme`), 화면 모드(`tui`)처럼 개발머신마다 다르게 고를 값을 `/config`로 바꾸면 이 파일에 저장하는데, 덮어쓰면 다음 시작 때 사라지기 때문이다. 덮어쓰기 대신 병합도 검토했지만, 공통 설정에서 지운 키가 기존 개발 컨테이너에 남는 문제가 있었다. managed settings는 지운 키가 바로 사라지고 파일을 고치면 실행 중인 세션에도 반영된다. 대가로 managed 키는 개발머신에서 바꿀 수 없으므로, 머신마다 달라도 되는 키는 managed에 두지 않는다. 또 claude.ai 조직 계정으로 로그인해 조직의 원격 관리 설정이 적용되면, Claude Code는 그쪽만 읽고 이 파일을 무시한다.
