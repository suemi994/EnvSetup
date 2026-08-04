return {
    {
        'greggh/claude-code.nvim',
        event = 'VeryLazy',
        enabled = true,
        dependencies = {
            "nvim-lua/plenary.nvim" -- Required for git operations
        },
        config = function()
            require('claude-code').setup({
                window = {position = "vertical", split_ratio = 0.5},
                git = {use_git_root = true},
                -- command = 'NO_COLOR=1 codex',
                command = 'claude',
                command_variants = {
                    continue = "--continue",
                    resume = "--resume"
                },
                keymaps = {
                    toggle = {normal = "<C-a>", terminal = "<C-a>"},
                    window_navigation = true
                }

            })
        end
    }, {
        'kkrampis/codex.nvim',
        lazy = true,
        cmd = {'Codex', 'CodexToggle'}, -- Optional: Load only on command execution
        keys = {
            {
                '<leader>a', -- Change this to your preferred keybinding
                function() require('codex').toggle() end,
                desc = 'Toggle Codex popup or side-panel',
                mode = {'n', 't'}
            }
        },
        opts = {
            keymaps = {
                toggle = nil, -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
                quit = '<C-q>' -- Keybind to close the Codex window (default: Ctrl + q)
            }, -- Disable internal default keymap (<leader>cc -> :CodexToggle)
            border = 'rounded', -- Options: 'single', 'double', or 'rounded'
            width = 0.5, -- Width of the floating window (0.0 to 1.0)
            height = 0.5, -- Height of the floating window (0.0 to 1.0)
            model = nil, -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
            autoinstall = false, -- Automatically install the Codex CLI if not found
            panel = true, -- Open Codex in a side-panel (vertical split) instead of floating window
            use_buffer = false -- Capture Codex stdout into a normal buffer instead of a terminal buffer
        }
    }
}
