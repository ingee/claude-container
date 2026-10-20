# Claude Code는 claude-code Feature 대신 native installer로 설치한다

anthropics의 `claude-code` Dev Container Feature는 npm 전역 설치라서, 개발 컨테이너 안에서 `nvm use`로 node 버전을 바꾸면 그 셸에서 `claude`가 사라진다. 도구 버전은 nvm/sdkman으로 자유롭게 바꾼다는 전제를 지키기 위해, node와 무관하게 `~/.local/bin`에 설치되는 native installer를 쓴다. node·java·go 등 나머지 도구는 공식 Feature를 그대로 쓴다.
