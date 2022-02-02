sy on
au BufRead,BufNewFile *.conf set filetype=conf
au BufRead,BufNewFile pf.conf set filetype=pf
au BufRead,BufNewFile nginx.conf set filetype=nginx

" Just for a visual left padding.
se foldcolumn=2
hi FoldColumn ctermbg=15 guibg=#ffffff

" For scrolling with the mouse wheel.
se mouse=a

" StatusBar. Show the filename and an [+] if its modified.
se laststatus=2
hi StatusLine ctermbg=white ctermfg=grey

" Disable viminfo
set viminfo=
