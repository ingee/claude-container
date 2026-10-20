"공통 옵션: 개발머신 ~/.vimrc에서 플러그인(Vundle) 관련 설정을 뺀 나머지
"vim에서도 그대로 source할 수 있도록 vimscript로 유지한다.

colorscheme retrobox
let g:markdown_recommended_style=0
filetype plugin indent on
syntax on

set belloff=all
set hls     "hlsearch, 검색 문자열 하이라이트
set ai      "autoindent
set si      "smartindent
set sw=2    "shiftwidth, 들여쓰기 취소 간격
set ts=2    "tabstop, TAB 간격
set et      "expandtab, 탭을 스페이스로
set cul     "cursorline, 커서 라인 하이라이트
set nu      "number, 라인넘버 표시
set sm      "showmatch, 함수닫기 표시
set fenc=utf-8  "fileencoding, utf-8 파일 인코딩
set shortmess-=S  "검색 카운트 표시

"for my work
set suffixesadd+=.js  "gf 파일 이동시 확장자 자동 추가
autocmd BufWritePre * :%s/\s\+$//e  "파일저장시 tailing-space 자동제거
autocmd FileType * set fo-=r fo-=o
