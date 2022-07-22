" my simple neovim config
" mdhs <justfly.py@gmail.com>
" enjoy!
"
let mapleader=','

" plugins
call plug#begin('~/.config/nvim/plugged')
Plug 'neovim/nvim-lspconfig'  " builtin language server
Plug 'nvim-lua/lsp-status.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/nvim-cmp'
Plug 'nvim-lualine/lualine.nvim'
Plug 'steelsojka/pears.nvim'  " brackets auto pair
Plug 'nvim-telescope/telescope.nvim'  " fuzzy finder
Plug 'nvim-lua/plenary.nvim'  " depended by telescope
Plug 'akinsho/toggleterm.nvim'  " better terminal
Plug 'lewis6991/spellsitter.nvim' " better spell check
Plug 'famiu/bufdelete.nvim' " better buffer deletion
Plug 'cormacrelf/vim-colors-github'
call plug#end()

" vim settings
set termguicolors
set spell
set signcolumn=number  " use number column to show sign
set number
set fillchars+=vert:\|  " delimiter
set list listchars=tab:>-,eol:↲,trail:◦
set noshowmode  " no need, we already have lightline
set splitbelow splitright
set ignorecase smartcase  " ignore case for searching
set expandtab smarttab shiftwidth=4 tabstop=4
set foldnestmax=5 foldlevel=5
set completeopt=menuone
au FileType go setlocal noexpandtab
au BufReadPost * if line("'\"") > 0 | if line("'\"") <= line("$") | exe("norm '\"") | else |exe "norm $"| endif | endif

colorscheme github
let g:airline_theme = "github"
let g:lightline = { 'colorscheme': 'github' }
set background=light

luafile ~/.config/nvim/conf.lua
hi VertSplit ctermbg=NONE guibg=NONE
call ssh_clipboard#Enable()

" key bindings
nnoremap <silent><leader>f :lua vim.lsp.buf.hover()<cr>
nnoremap <silent><leader>e :lua vim.lsp.buf.definition()<cr>
nnoremap <silent><leader>d <cmd>Telescope lsp_definitions<cr>
nnoremap <silent><leader>s <cmd>Telescope lsp_implementations<cr>
nnoremap <silent><leader>r <cmd>Telescope lsp_references<cr>
nnoremap <silent><leader>t <cmd>Telescope diagnostics bufnr=0<cr>
nnoremap <silent><leader>v <cmd>vsplit<cr>
nnoremap <silent><leader>h <cmd>hsplit<cr>
nnoremap <silent><leader>p <cmd>Telescope git_files<cr>
nnoremap <silent><leader>q <cmd>Bdelete<cr>
nnoremap <silent><C-b> <cmd>Telescope buffers<cr>
nnoremap <silent><C-d> <cmd>Telescope lsp_definitions<cr>
nnoremap <silent><C-p> <cmd>Telescope treesitter<cr>
nnoremap <silent><C-f> <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <silent><C-g> <cmd>Telescope live_grep<cr>
nnoremap <silent><C-S-l> :lua vim.lsp.buf.formatting()<cr>
" nnoremap <silent><C-j> <cmd>terminal<cr>
nnoremap <silent><C-s> <cmd>wall<cr>
nnoremap <silent><C-q> <cmd>qall<cr>
nnoremap <silent><C-h> <cmd>bp<cr>
nnoremap <silent><C-l> <cmd>bn<cr>
nnoremap <silent><C-S-Left> <cmd>tabprevious<cr>
nnoremap <silent><C-S-Right> <cmd>tabnext<cr>
nnoremap <silent><C-t> <cmd>tabedit<cr>
xnoremap gf <cmd>Telescope grep_string<cr>

map <C-Left> <C-W>h
map <C-Right> <C-W>l
