local editor = {}

function editor.setup_treesitter()
    require("nvim-treesitter.configs").setup({
        ensure_installed = {"cpp", "go", "python"},
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

function editor.setup_lualine()
    require("lualine").setup({
        sections = {
            lualine_b = {"branch"},
            lualine_c = {{"buffers", buffers_color = {active = 'white'}}},
            lualine_x = {"diff", "diagnostics", "filetype"},
        },
        options = {section_separators = "", component_separators = "", globalstatus = true},
    })
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
                vertical = {width = 0.5, height = 0.5}
            },
            layout_strategy = "vertical",
        },
    })
end

function editor.setup_toggleterm()
    require("toggleterm").setup({
        size = function(term)
            if term.direction == "horizontal" then
                return 15
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.5
            end
        end,
        open_mapping = [[<c-j>]],
        direction = 'vertical'
    })
    function _G.set_terminal_keymaps()
        local opts = {noremap = true}
        vim.api.nvim_buf_set_keymap(0, "t", "<esc>", [[<C-\><C-n>]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-Left>", [[<C-\><C-n><C-W>h]], opts)
        vim.api.nvim_buf_set_keymap(0, "t", "<C-Right>", [[<C-\><C-n><C-W>l]], opts)
    end
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end

function editor.setup()
    require("pears").setup()
    require('spellsitter').setup()

    editor.setup_treesitter()
    editor.setup_telescope()
    editor.setup_lualine()
    editor.setup_toggleterm()
end

return editor
