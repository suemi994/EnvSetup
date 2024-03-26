local editor = {}

function editor.setup_treesitter()
    require("nvim-treesitter.configs").setup({
        ensure_installed = {"cpp", "go", "python", "rust"},
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<CR>",
                node_incremental = "<CR>",
                node_decremental = "<BS>",
                scope_incremental = "<TAB>"
            }
        }
    })
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "nvim_treesitter#foldexpr()"
end

function editor.setup_telescope()
    require("telescope").setup({
        defaults = {
            mappings = {
                i = {
                    ["<C-j>"] = require("telescope.actions").move_selection_next,
                    ["<C-k>"] = require("telescope.actions").move_selection_previous,
                    ["<esc>"] = require("telescope.actions").close
                }
            },
            layout_config = {
                vertical = {width = 0.8, height = 0.8}
            },
            layout_strategy = "vertical",
        },
    })
end

function editor.setup_formatter()
    require('formatter').setup({
        filetype = {
            cpp = require("formatter.filetypes.cpp").clangformat,
            go = require("formatter.filetypes.go").gofmt,
            rust = require("formatter.filetypes.rust").rustfmt,
            cmake = require("formatter.filetypes.cmake").cmakeformat
        }
    })
end

function editor.setup_linter()
    require('lint').linters_by_ft = {
        cpp = {'clangtidy'},
        python = {'pylint'}
    }
end

function editor.setup()
    require('pears').setup()
    require('spellsitter').setup()

    editor.setup_treesitter()
    editor.setup_telescope()
    editor.setup_formatter()
    editor.setup_linter()
end

return editor
