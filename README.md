# claude-container

어느 개발머신(Mac, WSL)에서나 같은 방식으로 Claude Code 기반 개발을 할 수 있도록 개발 컨테이너를 정의하는 빌드 레포입니다.
각 개발머신에서 이 레포로 개발 이미지를 로컬 빌드하고, 터미널에서 `docker exec`로 접속해 사용합니다. IDE는 쓰지 않습니다.

용어는 [CONTEXT.md](./CONTEXT.md), 주요 설계 결정은 [docs/adr/](./docs/adr/)를 참고하세요.

## 개발 컨테이너에 들어 있는 것

| 구분 | 내용 |
|---|---|
| OS, 사용자 | Ubuntu 24.04, `dev`(sudo 가능), bash, `ko_KR.UTF-8`, `Asia/Seoul` |
| 언어 | node.js LTS(nvm), java LTS(sdkman), go 최신, python3 + uv |
| 에디터 | neovim 최신 (`vim`, `vi`는 nvim alias), LSP: ts_ls, jdtls, gopls, pyright, lua_ls, bashls |
| CLI | Claude Code(native installer), gh, glab, git, ripgrep, fd, fzf, jq |
| Claude 공통 설정 | settings.json, hook(git 가드), 전역 CLAUDE.md, statusline, skills(`ingee/claude-skills`), `mattpocock-skills` 플러그인, atlassian MCP(선택) |

도구 버전은 개발 이미지를 빌드하는 시점의 최신 LTS(또는 최신)입니다. 다른 버전이 필요하면 개발 컨테이너 안에서 `nvm`, `sdk`, `uv python`으로 바꿉니다.

## 사전 준비

개발머신에 다음이 필요합니다.

- Docker
  - Mac: Docker Desktop
  - WSL: Docker Desktop(WSL integration) 또는 WSL 안의 Docker Engine
- [devcontainer CLI](https://github.com/devcontainers/cli)

  ```bash
  npm install -g @devcontainers/cli
  devcontainer --version
  ```

## 설정 (.env)

```bash
git clone <이 레포> ~/work/claude-container
cd ~/work/claude-container
cp .env.sample .env
nvim .env
```

| 항목 | 필수 | 설명 |
|---|---|---|
| `WORK_ROOT` | 필수 | 개발 컨테이너의 `/home/dev/work`에 mount할 작업 루트. 예) `~/work` |
| `GIT_USER_NAME`, `GIT_USER_EMAIL` | 권장 | 개발 컨테이너 안 git 커밋 작성자 |
| `GITLAB_HOST` | 선택 | 회사 GitLab 호스트 이름. glab 기본 호스트와 git HTTPS 인증에 쓰입니다 |
| `CONFLUENCE_URL`, `CONFLUENCE_PERSONAL_TOKEN` | 선택 | 값이 있으면 atlassian MCP가 등록됩니다 |
| `JIRA_URL`, `JIRA_PERSONAL_TOKEN` | 선택 | 위와 같습니다 |

주의할 점:

- `.env`는 docker `--env-file` 형식입니다. 값에 **따옴표를 쓰지 않습니다.** 공백이 있어도 그대로 씁니다. 예) `GIT_USER_NAME=InGee Kim`
- WSL에서는 `WORK_ROOT`를 `/mnt/c/...`가 아니라 WSL 파일시스템(예: `~/work`)으로 지정합니다. Windows 파일시스템은 파일 I/O가 매우 느립니다.
- `.env`는 git에 커밋되지 않습니다(`.gitignore`).

## 실행 명령

`bin/claude-dev`가 `.env`의 `WORK_ROOT`를 읽어 `devcontainer up`을 실행합니다.

```bash
# 개발 컨테이너 만들기 / 다시 시작 (처음에는 개발 이미지 빌드로 시간이 걸립니다)
./bin/claude-dev up

# 접속
docker exec -it claude-dev bash
# 또는
./bin/claude-dev shell

# 중지 (개발 컨테이너는 지워지고, 컨테이너 상태 volume은 유지됩니다)
./bin/claude-dev down

# 개발 컨테이너를 새로 만들어 시작 시점 처리(post-start.sh)를 다시 실행 (빌드 캐시 사용)
./bin/claude-dev refresh

# 개발 이미지를 캐시 없이 다시 빌드 (도구 추가·변경, 최신 LTS로 갱신)
./bin/claude-dev rebuild
```

| 하려는 일 | 명령 |
|---|---|
| `common/shell/bashrc`, `common/nvim/`의 옵션·키 매핑 변경 반영 | 없음 (새 셸, nvim을 다시 실행하면 반영) |
| `common/claude/`, `common/nvim/`의 플러그인·LSP 목록, `post-start.sh` 변경 반영 | `refresh` |
| `Dockerfile`, `devcontainer.json`의 Feature 변경 반영 (도구 추가·변경) | `rebuild` |
| 도구를 최신 버전으로 갱신 | `rebuild` |
| nvim 플러그인·LSP를 최신 버전으로 갱신 | nvim 안에서 `:Lazy update`, `:MasonUpdate` |

`common/`과 `.devcontainer/scripts/`는 개발 이미지에 복사되지 않고 개발 컨테이너에 읽기 전용으로 mount됩니다. 그래서 공통 설정을 고쳐도 빌드 캐시가 깨지지 않고, `refresh`의 빌드 단계는 모두 캐시로 끝납니다.

`rebuild`가 캐시를 쓰지 않는 이유: Dockerfile과 Feature는 빌드 시점의 최신 버전(`latest`, LTS)을 받아 옵니다. Docker 빌드 캐시는 명령 문자열이 같으면 이전 결과를 재사용하므로, 캐시를 쓰면 새 버전이 나와도 옛 버전이 그대로 남습니다.

`bin/claude-dev up`은 내부적으로 다음 명령과 같습니다.

```bash
WORK_ROOT=~/work devcontainer up --workspace-folder ~/work/claude-container
```

개발 컨테이너는 개발머신당 하나(`claude-dev`)이며, 작업 루트 아래의 여러 프로젝트를 함께 작업합니다.

개발 컨테이너는 `docker run --rm`으로 실행되므로, 중지되면(`down`, Docker 재시작, 개발머신 재부팅) 바로 지워지고 다음 `up`에서 개발 이미지로부터 새로 만들어집니다. 그래서 다음은 중지할 때 사라집니다.

- 컨테이너 상태 volume 밖의 모든 변경: `~/.bash_history`, 개발 컨테이너 안에서 직접 설치한 도구(`nvm install`, `sdk install`, `npm -g`, `go install`, `apt install` 등), 패키지 캐시
- 계속 쓰려는 도구는 `Dockerfile`이나 `devcontainer.json`의 Feature에 추가하고 `./bin/claude-dev rebuild`로 반영합니다.

## 처음 접속한 뒤 한 번만 할 일

로그인 정보는 컨테이너 상태 volume에 저장되므로, 개발머신마다 한 번만 하면 됩니다. 개발 이미지를 다시 빌드해도 유지됩니다.

```bash
claude                                   # Claude 로그인
gh auth login                            # GitHub 로그인 (HTTPS 선택)
glab auth login --hostname "$GITLAB_HOST"  # GitLab 로그인, git 인증 설정 질문에 Yes
```

로그인한 뒤 개발 컨테이너를 한 번 다시 시작합니다.

```bash
./bin/claude-dev down && ./bin/claude-dev up
```

다시 시작하면 다음 두 가지가 처리됩니다.

- `gh`가 git HTTPS 인증에 연결됩니다(`gh auth setup-git`).
- skills 레포(`ingee/claude-skills`)가 `~/.claude/skills`에 clone됩니다. private 레포라서 **gh 로그인 전에는 clone이 실패하는 것이 정상**입니다. 실패하면 시작 로그에 안내가 표시됩니다.

## 컨테이너 상태와 개발머신의 관계

| 개발 컨테이너 경로 | 저장 위치 | 내용 |
|---|---|---|
| `/home/dev/work` | 개발머신의 `WORK_ROOT` (bind mount) | 프로젝트 소스 |
| `/home/dev/.claude` | Docker volume `claude-dev-claude` | Claude 로그인, 대화 이력, skills, 플러그인 |
| `/home/dev/.config/gh` | Docker volume `claude-dev-gh` | gh 로그인 |
| `/home/dev/.config/glab-cli` | Docker volume `claude-dev-glab` | glab 로그인 |
| `/home/dev/.local/share/nvim` | Docker volume `claude-dev-nvim` | nvim 플러그인, LSP 서버, treesitter 파서 |
| `/opt/claude-container/common` | 빌드 레포의 `common/` (bind mount, 읽기 전용) | 공통 설정 |
| `/opt/claude-container/bin` | 빌드 레포의 `.devcontainer/scripts/` (bind mount, 읽기 전용) | 시작 시점 스크립트 |

- Docker volume은 개발머신의 `~/.claude`와 **무관합니다.** 개발머신의 claude와 개발 컨테이너의 claude는 로그인과 이력을 따로 가집니다.
- 개발머신의 `~/.vimrc`, `~/.config/nvim`, `~/.claude`는 전혀 바뀌지 않습니다.
- volume 확인: `docker volume ls | grep claude-dev`
- 완전히 초기화하려면 개발 컨테이너를 중지한 뒤 `docker volume rm claude-dev-claude claude-dev-gh claude-dev-glab claude-dev-nvim`을 실행합니다. 로그인을 다시 해야 합니다.
- 개발 컨테이너가 떠 있는 동안 빌드 레포를 옮기거나 지우면 공통 설정과 시작 시점 스크립트를 찾지 못합니다.

## 공통 설정 고치기

공통 설정의 단일 출처는 이 레포의 `common/`입니다.

| 고치는 대상 | 반영 시점 |
|---|---|
| `common/claude/` (settings.json, hooks, CLAUDE.md, statusline) | `./bin/claude-dev refresh` 후, 개발 컨테이너가 시작될 때 `~/.claude`에 덮어씁니다 |
| `common/nvim/` 옵션·키 매핑 | 바로 (nvim을 다시 실행) |
| `common/nvim/lua/config/lazy.lua`의 플러그인, `lsp.lua`의 설치 목록 | `./bin/claude-dev refresh` 후, 시작할 때 추가분만 설치합니다 |
| `common/shell/bashrc` | 바로 (새 셸을 열거나 `source ~/.bashrc`) |

- 개발 컨테이너 안의 `~/.claude/settings.json` 등을 직접 고치면 **다음 시작 때 덮어써집니다** ([ADR 0002](./docs/adr/0002-common-settings-one-way-sync.md)).
- **skills는 예외입니다.** `~/.claude/skills`는 처음 시작할 때만 clone되고, 이후에는 직접 관리합니다.

  ```bash
  cd ~/.claude/skills && git pull
  ```

## neovim

- 공통 옵션은 `common/nvim/options.vim`(개발머신 `~/.vimrc`에서 플러그인 설정을 뺀 것)에 있고, `init.lua`가 source합니다.
- 플러그인(lazy.nvim): lualine, vim-indentwise, mason, nvim-lspconfig, blink.cmp, nvim-treesitter, fzf-lua
- `~/.config/nvim`은 mount된 `common/nvim`을 가리키는 symlink입니다. 읽기 전용이므로 설정은 개발머신의 빌드 레포에서 고칩니다.
- 플러그인, LSP 서버, treesitter 파서는 개발 컨테이너가 시작될 때 volume `claude-dev-nvim`에 없는 것만 설치됩니다([ADR 0003](./docs/adr/0003-nvim-plugins-in-volume.md)). volume이 비어 있는 첫 시작은 몇 분 걸립니다.
- 플러그인과 LSP는 `rebuild`로 갱신되지 않습니다. nvim 안에서 `:Lazy update`, `:MasonUpdate`로 갱신합니다.

| 키 | 동작 |
|---|---|
| `K` | 문서 보기 (LSP) |
| `gd` / `gD` | 정의 / 선언으로 이동 |
| `grr` / `gri` | 참조 / 구현 목록 |
| `grn` / `gra` | 이름 바꾸기 / 코드 액션 |
| `<F9>` | 현재 파일의 심볼 목록 (vimrc의 Tagbar 대체) |
| `\ff` / `\fg` / `\fb` | 파일 / 문자열 / 버퍼 검색 |

### 클립보드

- nvim에서 yank한 내용은 OSC 52로 터미널을 거쳐 OS 클립보드에 복사됩니다.
- OS 클립보드의 내용을 붙여 넣을 때는 터미널 붙여넣기를 씁니다(Mac `Cmd+V`, Windows Terminal `Ctrl+Shift+V`). nvim의 `p`는 nvim 내부 레지스터를 씁니다.

| 터미널 | 필요한 설정 |
|---|---|
| iTerm2 | *Settings → General → Selection → "Applications in terminal may access clipboard"* 켜기 |
| Windows Terminal | 없음 (기본 지원) |

## 레포 구조

```
.devcontainer/
  devcontainer.json          개발 컨테이너 정의 (Feature, mount, volume, 환경변수)
  Dockerfile                 OS 패키지, neovim, glab, uv
  features/claude-env/       로컬 Feature: Claude Code, bash·nvim 설정 연결
  scripts/                   /opt/claude-container/bin에 mount
    post-start.sh            시작 시 공통 설정 반영, skills·플러그인·MCP·git 설정
    nvim-plugins.sh          시작 시 nvim 플러그인·LSP·파서 중 없는 것 설치
common/                      공통 설정 (단일 출처, /opt/claude-container/common에 mount)
  claude/                    ~/.claude에 반영되는 파일
  nvim/                      ~/.config/nvim (symlink)
  shell/bashrc               ~/.bashrc에서 source
bin/claude-dev               up / refresh / rebuild / shell / down
.env.sample                  실행 설정 예시
```
