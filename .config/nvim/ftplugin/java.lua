local path_to_java_dap = '/Users/pbell/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/'

local config = {
  cmd = { '/Users/pbell/.local/share/nvim/mason/bin/jdtls' },
  root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew', '.git', 'mvnw' }, { upward = true })[1]),
  init_options = {
    bundles = {
      vim.fn.glob(
        path_to_java_dap .. 'com.microsoft.java.debug.plugin-0.46.0.jar', true)
    },
  },
}
require('jdtls').start_or_attach(config)
