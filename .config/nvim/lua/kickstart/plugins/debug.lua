-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

--[[Spring Boot Configuration]]
function get_spring_boot_runner(profile, port, debug)
  local debug_param = ''
  if debug then
    debug_param =
        ' -Dspring-boot.run.jvmArguments="-Xdebug -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=' ..
        port .. '"'
  end

  local profile_param = ''
  if profile then
    profile_param = ' -Dspring-boot.run.profiles=' .. profile .. ' '
  end

  return 'mvn spring-boot:run ' .. profile_param .. debug_param
end

function run_spring_boot(profile, port, debug)
  vim.cmd(':tabe')
  vim.cmd('term ' .. get_spring_boot_runner(profile, port, debug))
end

function attach_debugger_to_spring_boot()
  local dap = require 'dap'
  dap.configurations.java = {
    {
      type = 'java',
      request = 'attach',
      name = 'Debug (Attach) - Remote',
      hostName = '127.0.0.1',
      port = vim.fn.input('Attach to Port: ')
    }
  }
  dap.continue()
end

--[[Testing]]
function get_test_runner(test_name, debug)
  vim.cmd(':tabe')
  if debug then
    return 'mvn test -Dmaven.surefire.debug -Dtest="' .. test_name .. '"'
  end
  return 'mvn test -Dtest="' .. test_name .. '"'
end

function run_java_test_method(debug)
  local utils = require 'utils'
  local method_name = utils.get_current_full_method_name("\\#")
  vim.cmd('term ' .. get_test_runner(method_name, debug))
end

function run_java_test_class(debug)
  local utils = require 'utils'
  local class_name = utils.get_current_full_class_name()
  vim.cmd('term ' .. get_test_runner(class_name, debug))
end

--[[Spring Boot Keymaps]]
-- Run Spring Boot
vim.keymap.set('n', '<leader>sbr',
  function() run_spring_boot(vim.fn.input('Profile: '), false) end,
  { desc = '[S]pring [B]oot [R]un' })
vim.keymap.set('n', '<leader>sbd',
  function() run_spring_boot(vim.fn.input('Profile: '), vim.fn.input('Debugger Port: '), true) end,
  { desc = '[S]pring [B]oot [D]ebug' })
vim.keymap.set('n', '<leader>sba', function() attach_debugger_to_spring_boot() end,
  { desc = '[S]pring [B]oot [A]ttach Debugger' })
-- Run Tests
vim.keymap.set("n", "<leader>tm", function() run_java_test_method() end)
vim.keymap.set("n", "<leader>dtm", function() run_java_test_method(true) end)
vim.keymap.set("n", "<leader>tc", function() run_java_test_class() end)
vim.keymap.set("n", "<leader>dtc", function() run_java_test_class(true) end)

--[[Main Configuration]]
return {
  'mfussenegger/nvim-dap',

  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = false,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'javadbg',
        'codelldb',
        'python'
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_over, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.step_into, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
