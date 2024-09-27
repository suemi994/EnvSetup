return {
    { -- basic functions for neovim
        'nvim-lua/plenary.nvim'
    }, { -- [optional] brackets auto pair
        'steelsojka/pears.nvim',
        event = 'VeryLazy'
    }, { -- [optional] delete neovim buffers without losing window layout
        'famiu/bufdelete.nvim',
        cmd = 'Bdelete',
        -- event = 'VeryLazy',
        keys = {
            {
                '<leader>q',
                '<cmd>Bdelete<cr>',
                silent = true,
                noremap = true,
                desc = 'Delete and qiuit current buffer'
            }
        }
    }, { -- copy text through SSH with OSC52
        'ojroques/nvim-osc52',
        event = 'VeryLazy',
        config = function()
            local osc = require('osc52')
            osc.setup({
                max_length = 0, -- Maximum length of selection (0 for no limit)
                silent = false, -- Disable message on successful copy
                trim = false, -- Trim surrounding whitespaces before copy
                tmux_passthrough = true -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
            })
            local function copy(lines, _)
                osc.copy(table.concat(lines, '\n'))
            end

            local function paste()
                return {
                    vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')
                }
            end
            vim.g.clipboard = {
                name = 'osc52',
                copy = {['+'] = copy, ['*'] = copy},
                paste = {['+'] = paste, ['*'] = paste}
            }
        end
    },
    { -- async linter complementary to the built-in Language Server Protocol support
        'mfussenegger/nvim-lint',
        event = 'VeryLazy',
        opts = {
            events = {'BufWritePost', 'BufReadPost', 'InsertLeave'},
            linters_by_ft = {cpp = {'clangtidy'}, python = {'pylint'}}
        },
        config = function(_, opts)
            local linter = require('lint')
            linter.linters_by_ft = opts.linters_by_ft
            vim.api.nvim_create_autocmd(opts.events, {
                group = vim.api.nvim_create_augroup('nvim-lint', {clear = true}),
                callback = function() linter.try_lint() end
            })
        end
    }, { -- auto formatter
        'mhartington/formatter.nvim',
        event = 'LazyFile',
        cmd = {'Format', 'FormatWrite'},
        dependencies = {'nvim-lspconfig'},
        opts = function()
            return {
                filetype = {
                    cpp = require('formatter.filetypes.cpp').clangformat,
                    go = require('formatter.filetypes.go').gofmt,
                    rust = require('formatter.filetypes.rust').rustfmt,
                    cmake = require('formatter.filetypes.cmake').cmakeformat,
                    lua = require('formatter.filetypes.lua').luaformat
                }
            }
        end,
        config = function(_, opts)
            require('formatter').setup(opts)
            vim.api.nvim_create_autocmd('BufWritePost', {
                pattern = '*',
                command = 'FormatWrite',
                group = vim.api.nvim_create_augroup('FormatAutoGroup',
                                                    {clear = true})
            })
        end
    }, { -- parser generator tool, syntax highlight
        'nvim-treesitter/nvim-treesitter',
        version = false,
        build = ':TSUpdate',
        event = {'LazyFile', 'VeryLazy'},
        cmd = {'TSUpdateSync', 'TSUpdate', 'TSInstall'},
        opts_extend = {'ensure_installed'},
        opts = {
            ensure_installed = {'cpp', 'go', 'python', 'rust'},
            highlight = {
                enable = true,
                disable = {'css'},
                additional_vim_regex_highlighting = false
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<CR>',
                    node_incremental = '<CR>',
                    node_decremental = '<BS>',
                    scope_incremental = '<TAB>'
                }
            }
        },
        config = function(_, opts)
            require('nvim-treesitter.configs').setup(opts)
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
        end
    }, { -- fuzzy finder
        'nvim-telescope/telescope.nvim',
        cmd = 'Telescope',
        event = 'VeryLazy',
        keys = {
            {
                '<leader>d',
                '<cmd>Telescope lsp_definitions<cr>',
                silent = true,
                noremap = true,
                desc = 'LSP definitions'
            }, {
                '<leader>i',
                '<cmd>Telescope lsp_implementations<cr>',
                silent = true,
                noremap = true,
                desc = 'LSP implementations'
            }, {
                '<leader>r',
                '<cmd>Telescope lsp_references<cr>',
                silent = true,
                noremap = true,
                desc = 'LSP references'
            }, {
                '<leader>s',
                '<cmd>Telescope treesitter<cr>',
                silent = true,
                noremap = true,
                desc = 'Search symbols in current buffer'
            }, {
                'gf',
                '<cmd>Telescope grep_string<cr>',
                mode = 'x',
                desc = 'Grep string in current buffer'
            }, {
                '<C-p>',
                '<cmd>Telescope git_files<cr>',
                mode = {'n', 'i'},
                silent = true,
                noremap = true,
                desc = 'Search git files'
            }, {
                '<C-b>',
                '<cmd>Telescope buffers<cr>',
                mode = {'n', 'i'},
                silent = true,
                noremap = true,
                desc = 'Search opened buffers'
            }, {
                '<C-f>',
                '<cmd>Telescope current_buffer_fuzzy_find<cr>',
                mode = {'n', 'i'},
                silent = true,
                noremap = true,
                desc = 'Fuzzy search in current buffer'
            }, {
                '<C-g>',
                '<cmd>Telescope live_grep<cr>',
                mode = {'n', 'i'},
                silent = true,
                noremap = true,
                desc = 'Fuzzy search in whole project'
            }
        },
        opts = {
            defaults = {
                mappings = {
                    i = {['<C-h>'] = 'which_key', ['<esc>'] = 'close'},
                    n = {
                        ['<C-]>'] = 'move_selection_next',
                        ['<C-[>'] = 'move_selection_previous',
                        ['<C-h>'] = 'which_key',
                        ['<esc>'] = 'close',
                        ['q'] = 'close'
                    }
                },
                layout_config = {vertical = {width = 0.8, height = 0.8}},
                layout_strategy = 'vertical'
            }
        }
    }, {
        'akinsho/git-conflict.nvim',
        dependencies = {'yorickpeterse/nvim-pqf'},
        event = 'VeryLazy',
        config = true
    }, {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        opts = {keys = {scroll_down = '<C-]>', scroll_up = '<C-[>'}},
        keys = {
            {
                '<leader>?',
                function()
                    require('which-key').show({global = false})
                end,
                desc = 'Buffer Local Keymaps (which-key)'
            }, {
                '<C-h>',
                function()
                    require('which-key').show({global = true})
                end,
                mode = {'n', 'i'},
                desc = 'Buffer Local Keymaps (which-key)'
            }
        }
    }
}
