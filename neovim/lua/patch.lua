local ok, _ = pcall(require, 'lspconfig')
if not ok then
  -- 0.11+ 已移除模块，手动造一个空表，让 rust-tools 能索引
  package.loaded.lspconfig = {
    rust_analyzer = {
      setup = function(opts)
        vim.lsp.config('rust_analyzer', opts)
        vim.lsp.enable('rust_analyzer')
      end,
      util = vim.lsp,
    }
  }
end
