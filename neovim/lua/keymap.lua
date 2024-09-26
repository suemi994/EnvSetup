function setup_keymap()
	local map = vim.keymap.set
	map('n', '<leader>v', '<cmd>vsplit<cr>', { noremap = true, silent = true, desc = 'Split buffer in vertical direction'})
	map('n', '<leader>h', '<cmd>split<cr>', { noremap = true, silent = true, desc = 'Split buffer in horizontal direction'})
	map({'n', 'i'}, '<C-s>', '<cmd>wall<cr>', { noremap = true, silent = true, desc = 'Save all buffers'})
	map({'n', 'i'}, '<C-q>', '<cmd>qall<cr>', { noremap = true, silent = true, desc = 'Quit all buffers'})
	map({'n', 'i'}, '<C-S-Left>', '<cmd>bp<cr>', { noremap = true, silent = true, desc = 'Goto previous buffer'})
	map({'n', 'i'}, '<C-S-Right>', '<cmd>bn<cr>', { noremap = true, silent = true, desc = 'Goto previous buffer'})
	map({'n', 'i'}, '<C-t>', '<cmd>tabedit<cr>', { noremap = true, silent = true, desc = 'Edit a new tab'})
	map({'n', 'i', 'x'}, '<C-Left>', '<C-W>h', { noremap = true, silent = true, desc = 'Goto left window'})
	map({'n', 'i', 'x'}, '<C-Right>', '<C-W>l', { noremap = true, silent = true, desc = 'Goto right window'})
	map({'n', 'i', 'x'}, '<C-Up>', '<C-W>k', { noremap = true, silent = true, desc = 'Goto upper window'})
	map({'n', 'i', 'x'}, '<C-Down>', '<C-W>j', { noremap = true, silent = true, desc = 'Goto bottom window'})

    map('n', '<leader>e', '<cmd>:lua vim.lsp.buf.hover()<cr>', {noremap = true, silent = true, desc = 'Hover lsp rescription'})
    -- map('n', '<leader>f', '<cmd>:lua vim.lsp.buf.definition()<cr>', {noremap = true, silent = true, desc = 'Hover lsp definition'})
end

setup_keymap()
