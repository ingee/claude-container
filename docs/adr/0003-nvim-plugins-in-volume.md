# nvim 플러그인은 빌드 시점이 아니라 시작 시점에 volume에 설치한다

처음에는 nvim 플러그인, LSP 서버, treesitter 파서를 개발 이미지 빌드 시점에 설치했다. 그러려면 빌드가 nvim 설정(설치 목록)을 읽어야 해서 `common/nvim`을 이미지에 복사해야 했고, 옵션이나 키 매핑만 고쳐도 빌드 캐시가 깨져 Feature를 모두 다시 설치했다. 사용자가 neovim에 적응하는 중이라 nvim 설정은 자주 고친다.

그래서 nvim 설정은 다른 공통 설정처럼 mount하고(`~/.config/nvim` → `/opt/claude-container/common/nvim` symlink, docs/adr/0002), 플러그인·LSP·파서는 named volume `claude-dev-nvim`(`~/.local/share/nvim`)에 둔다. 개발 컨테이너가 시작될 때 `nvim-plugins.sh`가 없는 것만 설치한다. 설정 디렉터리가 읽기 전용이므로 lazy.nvim의 잠금 파일도 volume에 둔다.

대가는 다음과 같다.

- volume이 비어 있는 첫 시작은 몇 분 걸리고 네트워크가 필요하다. 개발머신마다 한 번이다.
- 플러그인과 LSP는 `rebuild`로 갱신되지 않는다. nvim 안에서 `:Lazy update`, `:MasonUpdate`로 갱신한다.
- 잠금 파일이 개발머신마다 따로 있어서 개발머신 사이에 플러그인 버전이 다를 수 있다. 맞춰야 할 필요가 생기면 잠금 파일을 빌드 레포에서 관리하는 방안을 검토한다.
