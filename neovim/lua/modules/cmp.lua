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
    ['cmake'] = {opt = true, need_require = false, setup_args = {}}
}

function setup_lsp(_, opts)
    local navic = require('nvim-navic')
    local on_attach = function(client, bufnr)
        if client.server_capabilities.documentSymbolProvider then
            navic.attach(client, bufnr)
        end
    end
    for source, conf in pairs(opts) do
        if conf.opt then
            if conf.need_require then
                require(source).setup(conf.setup_args)
            else
                conf.setup_args['on_attach'] = on_attach
		vim.lsp.config(source, conf.setup_args)
		vim.lsp.enable(source)
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
    vim.g.rustaceanvim = function()
        return {}
    end
end

return {
    {
        'neovim/nvim-lspconfig',
        version = false,
        dependencies = {
            'nvim-navic'
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
        'mrcjkb/rustaceanvim',
        version = '^6', -- Recommended
        lazy = false, -- This plugin is already lazy
        config = setup_rust
    }
}
