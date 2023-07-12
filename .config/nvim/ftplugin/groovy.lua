require('lint').linters_by_ft = {
  groovy = { 'npm-groovy-lint' }
}

vim.api.nvim_create_autocmd('BufWritePost', {
  callback = function()
    require('lint').try_lint()
    -- vim.cmd('!npm-groovy-lint --format %:p')
  end,
})
