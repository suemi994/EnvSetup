local keymap = {}

function keymap.setup_auto_cmd()
    local api = vim.api

    local format_group = api.nvim_create_augroup("FormatAutoGroup", {clear = true})
    api.nvim_create_autocmd("BufWritePost", {
        pattern = "*", command = "FormatWrite", group = format_group
    })

    local linter = require('lint')
    api.nvim_create_autocmd("BufWritePost", {
        callback = function()
            linter.try_lint()
        end
    })
end

function keymap.setup()
    keymap.setup_auto_cmd()
end

return keymap
