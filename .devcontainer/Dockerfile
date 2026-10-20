# 개발 이미지의 베이스 계층: OS 패키지와 사용자 독립적인 도구
# 사용자(dev)와 언어 툴체인은 devcontainer.json의 Feature가 이 위에 설치한다.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# ubuntu:24.04의 기본 사용자(uid 1000)를 지우고, common-utils Feature가 dev(uid 1000)를 만들게 한다.
RUN userdel -r ubuntu 2>/dev/null || true

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git jq less unzip zip xz-utils \
    build-essential locales tzdata \
    python3 python3-venv python3-pip \
    ripgrep fd-find fzf \
  && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
  && rm -rf /var/lib/apt/lists/*

# 로케일과 시간대
RUN locale-gen ko_KR.UTF-8 en_US.UTF-8 \
  && ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
  && echo 'Asia/Seoul' > /etc/timezone
ENV LANG=ko_KR.UTF-8 \
    TZ=Asia/Seoul

# neovim: 빌드 시점의 최신 릴리스 (apt 버전은 오래되었다)
RUN case "$(uname -m)" in \
      x86_64) arch=x86_64 ;; \
      aarch64) arch=arm64 ;; \
      *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;; \
    esac \
  && curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" \
    | tar -xz -C /opt \
  && ln -sf "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim

# glab: 빌드 시점의 최신 릴리스
RUN arch="$(dpkg --print-architecture)" \
  && version="$(curl -fsSL https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases/permalink/latest | jq -r .tag_name | sed 's/^v//')" \
  && curl -fsSL -o /tmp/glab.deb "https://gitlab.com/gitlab-org/cli/-/releases/v${version}/downloads/glab_${version}_linux_${arch}.deb" \
  && dpkg -i /tmp/glab.deb \
  && rm /tmp/glab.deb

# uv: python 버전과 패키지 관리
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh

# 공통 설정(common/)과 실행 스크립트는 COPY하지 않고 devcontainer.json에서 mount한다 (docs/adr/0002).
# 레포 파일을 COPY하면 공통 설정을 고칠 때마다 빌드 캐시가 깨져 Feature를 모두 다시 설치한다.
