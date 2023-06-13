local completion = {}

function completion.setup_cmp()
    local cmp = require("cmp")
    local types = require("cmp.types")
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
            autocomplete = { types.cmp.TriggerEvent.InsertEnter, types.cmp.TriggerEvent.TextChanged },
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
--    nvim_lsp.rust_analyzer.setup({
--            settings = {
--                ["rust-analyzer"] = {
--                    assist = {
--                        importEnforceGranularity = true,
--                        importPrefix = "crate"
--                    },
--                    cargo = {
--                       allFeatures = true
--                    },
--                    procMacro = { enable = true },
--                    checkOnSave = {
--                        command = "clippy"
--                    }
--                },
--                inlayHints = {
--                    lifetimeElisionHints = {
--                        enable = true,
--                        useParameterNames = true
--                    }
--                }
--            }
--    })
end

function completion.setup_rust()
    local function on_attach(client, buffer)
        -- " Show diagnostic popup on cursor hover
        local diag_float_grp = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true })
        vim.api.nvim_create_autocmd("CursorHold", {
          callback = function()
            vim.diagnostic.open_float(nil, { focusable = false })
          end,
          group = diag_float_grp,
        })
    end
    rt = require('rust-tools')
    rt.setup({
        tools = {
            runnables = {
                use_telescope = true,
            },
            inlay_hints = {
                auto = true,
                show_parameter_hints = false,
                parameter_hints_prefix = "<-",
                other_hints_prefix = "=>",
            }
        },
        -- options same as lsp hover / vim.lsp.util.open_floating_preview()
        hover_actions = {

          -- the border that is used for the hover window
          -- see vim.api.nvim_open_win()
          border = {
            { "╭", "FloatBorder" },
            { "─", "FloatBorder" },
            { "╮", "FloatBorder" },
            { "│", "FloatBorder" },
            { "╯", "FloatBorder" },
            { "─", "FloatBorder" },
            { "╰", "FloatBorder" },
            { "│", "FloatBorder" },
          },

          -- Maximal width of the hover window. Nil means no max.
          max_width = nil,

          -- Maximal height of the hover window. Nil means no max.
          max_height = nil,

          -- whether the hover action window gets automatically focused
          -- default: false
          auto_focus = false,
        },
        server = {
            on_attach = on_attach,
            settings = {
                ["rust-analyzer"] = {
                    checkOnSave = { command = "clippy" }
                }
            }
        }
    })
end

function completion.setup()
    completion.setup_rust()
    completion.setup_cmp()
    completion.setup_lsp()
end

return completion
