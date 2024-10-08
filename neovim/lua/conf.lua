-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system({
        'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo,
        lazypath
    })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            {'Failed to clone lazy.nvim:\n', 'ErrorMsg'}, {out, 'WarningMsg'},
            {'\nPress any key to exit...'}
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
local opt = vim.opt
vim.g.mapleader = ','
vim.g.maplocalleader = ','
opt.signcolumn = 'yes'
opt.termguicolors = true
opt.laststatus = 3
opt.number = true
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = true
opt.smarttab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.completeopt = menuone
opt.foldnestmax = 5
opt.foldlevel = 5

vim.cmd('hi VertSplit ctermbg=NONE guibg=NONE')
vim.cmd('call ssh_clipboard#Enable()')

-- Setup lazy.nvim
local Events = require('lazy.core.handler.event')
Events.mappings.LazyFile = {
    id = 'LazyFile',
    event = {'BufReadPost', 'BufNewFile', 'BufWritePre'}
}
require('lazy').setup({
    spec = {
        -- import your plugins
        {import = 'modules'}
    },
    defaults = {lazy = false, version = false},
    -- Configure any other settings here. See the documentation for more details.
    -- colorscheme that will be used when installing plugins.
    install = {colorscheme = {'github_light_default'}},
    -- automatically check for plugin updates
    checker = {enabled = false}
})
