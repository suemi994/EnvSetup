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
                window = {
                    position = "vertical",
                    split_ratio = 0.5,
                    float = {
                        width = "80%", -- Width: number of columns or percentage string
                        height = "80%", -- Height: number of rows or percentage string
                        row = "center", -- Row position: number, "center", or percentage string
                        col = "center", -- Column position: number, "center", or percentage string
                        relative = "editor", -- Relative to: "editor" or "cursor"
                        border = "rounded" -- Border style: "none", "single", "double", "rounded", "solid", "shadow"
                    }
                },
                git = {use_git_root = false},
                -- command = 'claude',
                command = 'proxychains4 -q pi',
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
            width = 0.85, -- Width of the floating window (0.0 to 1.0)
            height = 0.9, -- Height of the floating window (0.0 to 1.0)
            cmd = {'proxychains4', '-q', 'pi'},
            model = nil, -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
            autoinstall = false, -- Automatically install the Codex CLI if not found
            panel = false, -- Open Codex in a side-panel (vertical split) instead of floating window
            use_buffer = false -- Capture Codex stdout into a normal buffer instead of a terminal buffer
        }
    }
}
