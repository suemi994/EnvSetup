local completion = {}

function completion.setup_cmp()
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
end

function completion.setup_lsp_status()
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
end

completion["lsp"] = {
    ["gopls"] = {
        opt = true,
        setup_args = {},
    },
    ["pylsp"] = {
        opt = true,
        setup_args = {},
    },
    ["clangd"] = {
        opt = true,
        setup_args = {
            single_file_support = true,
            cmd = {
                "clangd",
                "--compile-commands-dir=build",
                "--background-index",
                "--clang-tidy",
                "--all-scopes-completion",
                "--cross-file-rename",
                "--pch-storage=disk",
                "--header-insertion=iwyu",
                "--query-driver=/usr/bin/g++",
            },
            commands = {
                ClangdSwitchSourceHeader = {
                    function()
                        switch_source_header_splitcmd(0, "edit")
                    end,
                    description = "Open source/header in current buffer",
                },
            },
        }
    }
}

function completion.setup_lsp()
    completion.setup_lsp_status()
    
    local nvim_lsp = require("lspconfig")
    for source, conf in pairs(completion["lsp"]) do
        if conf.opt then
            nvim_lsp[source].setup(conf.setup_args)
        end
    end
end

function completion.setup()
    completion.setup_cmp()
    completion.setup_lsp()
end

return completion
