-- configurations for lua plugins
--

-- cmp
local cmp = require("cmp")
local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end
cmp.setup({
    preselect = cmp.PreselectMode.None,
    sources = cmp.config.sources(
        {
            {name = "nvim_lsp"},
            {name = "buffer"},
            {name = "path"}
        }
    ),
    completion = {
        autocomplete = true
    },
     mapping = {
          ["<Tab>"] = cmp.mapping(
              function(fallback)
                  if has_words_before() then
                      cmp.complete()
                  else
                      fallback()
                  end
              end,
              {"i", "s"}
          ),
         ["<Down>"] = cmp.mapping.select_next_item(),
         ["<Up>"] = cmp.mapping.select_prev_item(),
         ["<CR>"] = cmp.mapping.confirm({select = true})
     }
})

-- lsp
local lsp_status = require('lsp-status')
lsp_status.register_progress()
lsp_status.config({
    indicator_errors = "❌",
    indicator_warnings = "⚠️ ",
    indicator_info = "ℹ️ ",
    -- https://emojipedia.org/tips/
    indicator_hint = "💡",
    indicator_ok = "✅",
})

local mix_attach = function(client)
  lsp_status.on_attach(client)
  cmp.on_attach(client)
end

local servers = {"gopls", "clangd", "pylsp"}
local nvim_lsp = require("lspconfig")
-- nvim_lsp.clangd.setup({
--   handlers = lsp_status.extensions.clangd.setup(),
--   init_options = {
--     clangdFileStatus = true
--   },
--   on_attach = lsp_status.on_attach,
--   capabilities = lsp_status.capabilities
-- })
for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup({})
end

-- treesitter
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

-- lualine
require("lualine").setup({
    sections = {
        lualine_b = {"branch"},
        lualine_c = {{"buffers", buffers_color = {active = 'white'}}},
        lualine_x = {"diff", "diagnostics", "filetype"},
    },
    options = {section_separators = "", component_separators = "", globalstatus = true},
})

-- pears
require("pears").setup()


-- telescope
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

-- toggleterm
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

-- spell check
require('spellsitter').setup()
