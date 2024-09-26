local lsp_sources = {
    ['gopls'] = {opt = true, need_require = false, setup_args = {}},
    ['pylsp'] = {opt = true, need_require = false, setup_args = {}},
    ['clangd'] = {
        opt = true,
        need_require = false,
        setup_args = {
            single_file_support = true,
            cmd = {
                'clangd', '--compile-commands-dir=build', '--background-index',
                '--clang-tidy', '--all-scopes-completion',
                '--cross-file-rename', '--pch-storage=disk',
                '--header-insertion=iwyu', '--query-driver=/usr/bin/g++'
            },
            commands = {
                ClangdSwitchSourceHeader = {
                    function()
                        switch_source_header_splitcmd(0, 'edit')
                    end,
                    description = 'Open source/header in current buffer'
                }
            }
        }
    },
    ['codeium'] = {opt = false, need_require = true, setup_args = {}}
}

function setup_lsp(_, opts)
    local navic = require('nvim-navic')
    local on_attach = function(client, bufnr)
        if client.server_capabilities.documentSymbolProvider then
            navic.attach(client, bufnr)
        end
    end
    local nvim_lsp = require('lspconfig')
    for source, conf in pairs(opts) do
        if conf.opt then
            if conf.need_require then
                require(source).setup(conf.setup_args)
            else
                conf.setup_args['on_attach'] = on_attach
                nvim_lsp[source].setup(conf.setup_args)
            end
        end
    end
end

function setup_cmp()
    local cmp = require('cmp')
    local types = require('cmp.types')
    local lsp_kind = require('lspkind')
    local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and
                   vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(
                       col, col):match('%s') == nil
    end
    cmp.setup({
        preselect = cmp.PreselectMode.None,
        sources = cmp.config.sources({
            {name = 'nvim_lsp'}, {name = 'buffer'}, {name = 'path'},
            {name = 'codeium'}
        }),
        completion = {
            autocomplete = {
                types.cmp.TriggerEvent.InsertEnter,
                types.cmp.TriggerEvent.TextChanged
            }
        },
        mapping = {
            ['<Tab>'] = cmp.mapping(function(fallback)
                if has_words_before() then
                    cmp.complete()
                else
                    fallback()
                end
            end, {'i', 's'}),
            ['<Down>'] = cmp.mapping.select_next_item(),
            ['<Up>'] = cmp.mapping.select_prev_item(),
            ['<CR>'] = cmp.mapping.confirm({select = true})
        },
        formatting = {
            format = lsp_kind.cmp_format({
                mode = 'text', -- show only symbol annotations
                maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
                -- can also be a function to dynamically calculate max width such as 
                -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
                ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
                show_labelDetails = true, -- show labelDetails in menu. Disabled by default
                symbol_map = {Codeium = ''}
            })
        }
    })
end

function setup_rust()
    local navic = require('nvim-navic')
    local function on_attach(client, buffer)
        -- ' Show diagnostic popup on cursor hover
        local diag_float_grp = vim.api.nvim_create_augroup('DiagnosticFloat',
                                                           {clear = true})
        vim.api.nvim_create_autocmd('CursorHold', {
            callback = function()
                vim.diagnostic.open_float(nil, {focusable = false})
            end,
            group = diag_float_grp
        })
        if client.server_capabilities.documentSymbolProvider then
            navic.attach(client, buffer)
        end
    end
    rt = require('rust-tools')
    rt.setup({
        tools = {
            runnables = {use_telescope = true},
            inlay_hints = {
                auto = true,
                show_parameter_hints = false,
                parameter_hints_prefix = '<-',
                other_hints_prefix = '=>'
            }
        },
        -- options same as lsp hover / vim.lsp.util.open_floating_preview()
        hover_actions = {

            -- the border that is used for the hover window
            -- see vim.api.nvim_open_win()
            border = {
                {'╭', 'FloatBorder'}, {'─', 'FloatBorder'},
                {'╮', 'FloatBorder'}, {'│', 'FloatBorder'},
                {'╯', 'FloatBorder'}, {'─', 'FloatBorder'},
                {'╰', 'FloatBorder'}, {'│', 'FloatBorder'}
            },

            -- Maximal width of the hover window. Nil means no max.
            max_width = nil,

            -- Maximal height of the hover window. Nil means no max.
            max_height = nil,

            -- whether the hover action window gets automatically focused
            -- default: false
            auto_focus = false
        },
        server = {
            on_attach = on_attach,
            settings = {
                ['rust-analyzer'] = {checkOnSave = {command = 'clippy'}}
            }
        }
    })
end

return {
    {
        'neovim/nvim-lspconfig',
        version = false,
        dependencies = {
            'nvim-navic',
            {'Exafunction/codeium.nvim', enabled = lsp_sources['codeium'].opt}
        },
        opts = lsp_sources,
        config = setup_lsp
    }, {
        'hrsh7th/nvim-cmp',
        version = false,
        event = 'InsertEnter',
        dependencies = {
            'onsails/lspkind.nvim', 'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path', 'nvim-lspconfig'
        },
        config = setup_cmp
    }, {
        'simrat39/rust-tools.nvim',
        version = false,
        event = 'LazyFile',
        ft = {'rs'},
        dependencies = {'telescope.nvim', 'nvim-navic'},
        config = setup_rust
    }
}
