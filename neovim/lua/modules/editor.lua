return {
    { -- basic functions for neovim
        'nvim-lua/plenary.nvim'
    }, { -- [optional] brackets auto pair
        'steelsojka/pears.nvim',
        event = 'LazyFile',
        config = function() require('pears').setup() end
    }, { -- [optional] delete neovim buffers without losing window layout
        'famiu/bufdelete.nvim',
        cmd = {'Bdelete', 'BdeleteRange', 'BdeleteAll'},
        keys = {
            {
                '<leader>q',
                '<cmd>Bdelete<cr>',
                silent = true,
                noremap = true,
                desc = 'Delete and quit current buffer'
            }
        },
        config = function()
            vim.api.nvim_create_user_command('BdeleteRange', function(args)
                bufs = {}
                if (args['fargs']) then
                    for k, v in ipairs(args['fargs']) do
                        local bstart = tonumber(k)
                        local bend = tonumber(v)
                        for i = bstart, bend do
                            table.insert(bufs, i)
                        end
                    end
                elseif (args['args']) then
                    table.insert(bufs, tonumber(args['args']))
                else
                    table.insert(bufs, 0)
                end
                require('bufdelete').bufdelete(bufs, true, nil)
            end, {
                nargs = '+',
                bang = true,
                bar = true,
                count = true,
                addr = 'buffers',
                complete = 'buffer',
                desc = 'Delete buffers in range'
            })
            vim.api.nvim_create_user_command('BdeleteAll', function(args)
                local bufs = vim.api.nvim_list_bufs()
                require('bufdelete').bufdelete(bufs, true, nil)
            end, {
                nargs = 0,
                bang = true,
                bar = true,
                count = true,
                addr = 'buffers',
                desc = 'Delete all buffers'
            })
        end
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
        ft = {'cpp', 'python'},
        opts = {
            events = {'BufWritePost', 'BufReadPost'},
            linters_by_ft = {cpp = {'clangtidy'}, python = {'pylint'}}
        },
        config = function(_, opts)
            local lint = require('lint')
            if (opts['linters']) then
                for name, linter in pairs(opts.linters) do
                    if type(linter) == "table" and type(lint.linters[name]) ==
                        "table" then
                        lint.linters[name] =
                            vim.tbl_deep_extend("force", lint.linters[name],
                                                linter)
                        if type(linter.prepend_args) == "table" then
                            lint.linters[name].args =
                                lint.linters[name].args or {}
                            vim.list_extend(lint.linters[name].args,
                                            linter.prepend_args)
                        end
                    else
                        lint.linters[name] = linter
                    end
                end
            end
            lint.linters_by_ft = opts.linters_by_ft

            local M = {}
            function M.debounce(ms, fn)
                local timer = vim.uv.new_timer()
                return function(...)
                    local argv = {...}
                    timer:start(ms, 0, function()
                        timer:stop()
                        vim.schedule_wrap(fn)(unpack(argv))
                    end)
                end
            end

            function M.lint()
                -- Use nvim-lint's logic first:
                -- * checks if linters exist for the full filetype first
                -- * otherwise will split filetype by "." and add all those linters
                -- * this differs from conform.nvim which only uses the first filetype that has a formatter
                local names = lint._resolve_linter_by_ft(vim.bo.filetype)

                -- Create a copy of the names table to avoid modifying the original.
                names = vim.list_extend({}, names)

                -- Add fallback linters.
                if #names == 0 then
                    vim.list_extend(names, lint.linters_by_ft["_"] or {})
                end

                -- Add global linters.
                vim.list_extend(names, lint.linters_by_ft["*"] or {})

                -- Filter out linters that don't exist or don't match the condition.
                local ctx = {filename = vim.api.nvim_buf_get_name(0)}
                ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
                names = vim.tbl_filter(function(name)
                    local linter = lint.linters[name]
                    return linter and
                               not (type(linter) == "table" and linter.condition and
                                   not linter.condition(ctx))
                end, names)

                -- Run linters.
                if #names > 0 then lint.try_lint(names) end
            end

            vim.api.nvim_create_autocmd(opts.events, {
                group = vim.api.nvim_create_augroup('nvim-lint', {clear = true}),
                callback = M.debounce(100, M.lint)
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
            require('nvim-treesitter').setup(opts)
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
                '<leader>p',
                '<cmd>Telescope treesitter<cr>',
                silent = true,
                noremap = true,
                desc = 'Fuzzy search symbols in current buffer'
            }, {
                '<leader>m',
                '<cmd>:lua require("telescope.builtin").lsp_document_symbols({symbols = {"method", "function", "constructor"}})<cr>',
                silent = true,
                noremap = true,
                desc = 'Find function symbols with filters in current buffer'
            }, {
                '<leader>s',
                '<cmd>:lua require("telescope.builtin").lsp_document_symbols({symbols = {"interface", "class", "struct"}})<cr>',
                silent = true,
                noremap = true,
                desc = 'Find struct symbols with filters in current buffer'
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
        dependencies = {
            {
                'yorickpeterse/nvim-pqf',
                config = function() require('pqf').setup() end
            }
        },
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
                    require('which-key').show({global = true})
                end,
                desc = 'Buffer Local Keymaps (which-key)'
            }, {
                '<C-h>',
                function()
                    require('which-key').show({global = false})
                end,
                mode = {'n', 'i'},
                desc = 'Buffer Local Keymaps (which-key)'
            }, {
                'Civitasv/cmake-tools.nvim',
		        dependencies = { 'nvim-lua/plenary.nvim' },
		        opts = {}
            }
        }
    }
}

