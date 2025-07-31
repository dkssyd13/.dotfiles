set relativenumber
set tabstop=4
set ts=4

" Highlight relative numbers
highlight LineNrAbove ctermfg=208 guifg=orange
highlight LineNrBelow ctermfg=208 guifg=orange

" Set <space> as leader key
let mapleader = " "
let maplocalleader = " "

" Open file explorer
nnoremap <leader>pv :Ex<CR>

" Move selected lines up and down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Clear search highlight
nnoremap <Esc> :nohlsearch<CR>

" Exit terminal mode with double <Esc>
tnoremap <Esc><Esc> <C-\><C-n>

" Diagnostic keymaps (requires LSP plugin)
nnoremap <leader>q :lopen<CR>
nnoremap <leader>e :echo "Use floating diagnostic here"<CR>
nnoremap [d :cprev<CR>
nnoremap ]d :cnext<CR>

" Yank highlighting (only works in Vim 8.0.1394+)
augroup highlight_yank
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
augroup END

" Keep cursor centered while joining lines
nnoremap J mzJ`z

" Scroll up/down and center cursor
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Keep search result centered
nnoremap n nzzzv
nnoremap N Nzzzv

" Format around a paragraph and return cursor
nnoremap =ap ma=ap'a

" Paste without overwriting default register
xnoremap <leader>p "_dP

" Copy to system clipboard
nnoremap <leader>Y "+Y
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" Delete without affecting registers
nnoremap <leader>d "_d
vnoremap <leader>d "_d

" Use <C-c> as <Esc> in insert mode
inoremap <C-c> <Esc>

" Disable Q
nnoremap Q <nop>

" Open tmux-sessionizer in new tmux window
" nnoremap <C-f> :silent !tmux neww tmux-sessionizer<CR>

" Jump between quickfix/location lists
nnoremap <C-k> :cnext<CR>zz
nnoremap <C-j> :cprev<CR>zz
nnoremap <leader>k :lnext<CR>zz
nnoremap <leader>j :lprev<CR>zz

" Search and replace current word
nnoremap <leader>s :%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>

" Make current file executable
nnoremap <leader>x :!chmod +x %<CR>

set scrolloff=8
set signcolumn=yes
set incsearch
set colorcolumn=80
