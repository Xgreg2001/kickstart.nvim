vim.g.mapleader = ' '
vim.g.maplocalleader = ' '


local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)


require('lazy').setup({

  -- Core/Utility
  'tpope/vim-sleuth',
  { 'akinsho/toggleterm.nvim', opts = {} },
  { 'stevearc/dressing.nvim',  opts = {} },
  { 'folke/neoconf.nvim',      opts = {} },

  -- UI/Theme
  { 'catppuccin/nvim',         name = 'catppuccin', priority = 1000 },
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false,
        theme = 'catppuccin',
        component_separators = '|',
        section_separators = '',
      },
    },
  },
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },
  { 'Bekaboo/deadcolumn.nvim' },
  {
    "xiyaowong/transparent.nvim",
    opts = {
      extra_groups = {
        "NormalFloat",
        "Comment",
      },
    },
    lazy = false,
  },

  -- Git
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        map({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to next hunk' })
        map({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to previous hunk' })
        map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
          { desc = 'stage git hunk' })
        map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end,
          { desc = 'reset git hunk' })
        map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
        map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
        map('n', '<leader>hS', gs.stage_buffer, { desc = 'git Stage buffer' })
        map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
        map('n', '<leader>hR', gs.reset_buffer, { desc = 'git Reset buffer' })
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
        map('n', '<leader>hb', function() gs.blame_line { full = false } end, { desc = 'git blame line' })
        map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
        map('n', '<leader>hD', function() gs.diffthis '~' end, { desc = 'git diff against last commit' })
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
        map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
      end,
    },
  },

  -- LSP/Completion/Snippets
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim',       opts = { notification = { window = { winblend = 0 } } } },
      'folke/neodev.nvim',
    },
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-buffer',
      'rafamadriz/friendly-snippets',
    },
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({ suggestion = { enabled = false }, panel = { enabled = false } })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    config = function() require("copilot_cmp").setup() end
  },
  {
    "olimorris/codecompanion.nvim",
    opts = {
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "claude-sonnet-4",
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },

  -- Treesitter/Syntax
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    build = ':TSUpdate',
  },
  {
    "echasnovski/mini.diff",
    config = function()
      local diff = require("mini.diff")
      diff.setup({ source = diff.gen_source.none() })
    end,
  },

  -- File Explorer & Navigation
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      commands = {
        parent_or_close = function(state)
          local node = state.tree:get_node()
          if (node.type == "directory" or node:has_children()) and node:is_expanded() then
            state.commands.toggle_node(state)
          else
            require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id())
          end
        end,
        child_or_open = function(state)
          local node = state.tree:get_node()
          if node.type == "directory" or node:has_children() then
            if not node:is_expanded() then
              state.commands.toggle_node(state)
            else
              require("neo-tree.ui.renderer").focus_node(state, node:get_child_ids()[1])
            end
          else
            state.commands.open(state)
          end
        end,
        find_in_dir = function(state)
          local node = state.tree:get_node()
          local path = node:get_id()
          require("telescope.builtin").find_files {
            cwd = node.type == "directory" and path or vim.fn.fnamemodify(path, ":h"),
          }
        end,
      },
      window = {
        width = 30,
        mapping_options = { noremap = true, nowait = true },
        mappings = {
          ["<space>"] = false,
          ["[b"] = "prev_source",
          ["]b"] = "next_source",
          ["F"] = "find_in_dir",
          ["h"] = "parent_or_close",
          ["l"] = "child_or_open",
          ["o"] = "open",
        },
        fuzzy_finder_mappings = {
          ["<C-j>"] = "move_cursor_down",
          ["<C-k>"] = "move_cursor_up",
        },
      },
      event_handlers = {
        {
          event = "file_opened",
          handler = function()
            require("neo-tree.command").execute({ action = "close" })
          end
        },
      },
    }
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Fuzzy Finder
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable 'make' == 1 end,
      },
    },
  },

  -- Markdown/CSV/Docs
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" }
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },
  {
    "cameron-wags/rainbow_csv.nvim",
    config = true,
    ft = {
      "csv", "tsv", "csv_semicolon", "csv_whitespace", "csv_pipe", "rfc_csv", "rfc_semicolon",
    },
    cmd = {
      "RainbowDelim", "RainbowDelimSimple", "RainbowDelimQuoted", "RainbowMultiDelim",
    },
  },

  -- Miscellaneous
  { 'folke/which-key.nvim',  opts = {} },
  { 'numToStr/Comment.nvim', opts = {} },
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    opts = {}
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { highlight = { after = "" } },
    event = "VeryLazy",
    keys = {
      {
        "<leader>T",
        "<cmd>TodoTelescope keywords=TODO,NOTE,BUG,ISSUE,WARN,HACK,OPTIM,TEST<cr>",
        desc = "Open TODOs in Telescope",
      },
    },
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle" },
    config = function() vim.g.undotree_SetFocusWhenToggle = 1 end,
    keys = {
      { "<leader><F5>", "<cmd>UndotreeToggle<cr>", desc = "Toggle undo tree" },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
  {
    "startup-nvim/startup.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
    opts = { theme = "startify" },
    lazy = false,
  },

  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>ld",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>lD",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>ls",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
    },
  },

  -- Kickstart extras
  require 'kickstart.plugins.autoformat',
  require 'kickstart.plugins.debug',
}, {
  ui = {
    boarder = "single",
  },
})


-- [[ Options ]]
-- General
vim.o.hlsearch = false
vim.o.exrc = true
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menuone,noselect'
vim.o.termguicolors = true
vim.o.colorcolumn = "100"

-- Window-local
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.wrap = false
vim.wo.signcolumn = 'yes'

-- Spelling
vim.opt.spelllang = "en_us"
vim.opt.spell = true
vim.opt.scrolloff = 8
vim.opt.spr = true

-- Theme
vim.cmd.colorscheme "catppuccin"

-- [[ which-key groups ]]
require('which-key').add({
  { "<leader>f",  group = "[F]ind" },
  { "<leader>f_", hidden = true },
  { "<leader>c",  group = "[C]hat" },
  { "<leader>c_", hidden = true },
  { "<leader>g",  group = "[G]it" },
  { "<leader>g_", hidden = true },
  { "<leader>h",  group = "Git [H]unk" },
  { "<leader>h_", hidden = true },
  { "<leader>l",  group = "[L]SP" },
  { "<leader>l_", hidden = true },
  { "<leader>t",  group = "[T]oggle" },
  { "<leader>t_", hidden = true },
  { "<leader>",   group = "VISUAL <leader>", mode = "v" },
  { "<leader>h",  desc = "Git [H]unk",       mode = "v" },
})

-- [[ Keymaps ]]
-- General
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set('i', 'jj', '<ESC>', { silent = true })
vim.keymap.set('n', '<leader>w', "<cmd>w<cr>", { desc = "[w]rite file" })
vim.keymap.set('n', '<leader>q', "<cmd>confirm q<cr>", { desc = "[q]uit" })
vim.keymap.set('n', '<leader>n', "<cmd>enew<cr>", { desc = "[n]ew file" })
vim.keymap.set('n', '<C-s>', ':w!<cr>', { desc = 'Save File' })
vim.keymap.set('n', '@@', '@q', { silent = true })

-- Navigation
vim.keymap.set('n', '<C-h>', "<cmd> TmuxNavigateLeft<cr>", { desc = "windows left" })
vim.keymap.set('n', '<C-l>', "<cmd> TmuxNavigateRight<cr>", { desc = "windows right" })
vim.keymap.set('n', '<C-j>', "<cmd> TmuxNavigateDown<cr>", { desc = "windows down" })
vim.keymap.set('n', '<C-k>', "<cmd> TmuxNavigateUp<cr>", { desc = "windows up" })
vim.keymap.set('n', '<leader>e', "<cmd>Neotree toggle reveal<cr>", { desc = "File [e]xplorer" })

-- Editing
vim.keymap.set('n', '<leader>o', 'o<Esc>0"_D', { desc = "add new line below" })
vim.keymap.set('n', '<leader>O', 'O<Esc>0"_D', { desc = "add new line above" })
vim.keymap.set('n', '<leader>v', 'viw"0p', { desc = "replace word under cursor" })

-- Diagnostics
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end,
  { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>le', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.diagnostic.config {
  signs = true,
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  update_in_insert = true,
  float = {
    border = 'rounded',
    focusable = true,
  },
}

-- [[ Highlight on yank ]]
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ lazygit ]]
local Terminal = require('toggleterm.terminal').Terminal
local lazygit  = Terminal:new({
  cmd = "lazygit",
  dir = "git_dir",
  direction = "float",
  float_opts = {
    border = "double",
  },
  on_open = function(term)
    vim.cmd("startinsert!")
    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  end,
  on_close = function()
    vim.cmd("startinsert!")
  end,
})

vim.keymap.set("n", "<leader>gg",
  function()
    lazygit:toggle()
  end,
  { desc = "Toggle LazyGit", noremap = true, silent = true })

-- [[ Configure Telescope ]]
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
        ['<Tab>'] = require('telescope.actions').move_selection_next,
        ['<S-Tab>'] = require('telescope.actions').move_selection_previous,
      },
    },
  },
}

pcall(require('telescope').load_extension, 'fzf')

local function find_git_root()
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  if current_file == '' then
    current_dir = cwd
  else
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

local function telescope_live_grep_open_files()
  require('telescope.builtin').live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end

-- [[ Keymaps for Telescope ]]
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers, { desc = '[f]ind existing [b]uffers' })
vim.keymap.set('n', '<leader>/', require('telescope.builtin').current_buffer_fuzzy_find,
  { desc = '[/] Fuzzily search in current buffer' })
vim.keymap.set('n', '<leader>f/', telescope_live_grep_open_files, { desc = '[f]ind [/] in Open Files' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [g]it [f]iles' })
vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[f]ind [f]iles' })
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '[f]ind [h]elp' })
vim.keymap.set('n', '<leader>fw', require('telescope.builtin').grep_string, { desc = '[f]ind current [w]ord' })
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = '[f]ind by [g]rep' })
vim.keymap.set('n', '<leader>fG', ':LiveGrepGitRoot<cr>', { desc = '[f]ind by grep on [G]it Root' })
vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = '[f]ind [d]iagnostics' })
vim.keymap.set('n', '<leader>f<cr>', require('telescope.builtin').resume, { desc = '[f]ind resume [<cr>]' })


-- [[ Treesitter Configuration ]]
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    ensure_installed = {
      'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript',
      'vimdoc', 'vim', 'bash', 'julia'
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<c-space>',
        node_incremental = '<c-space>',
        scope_incremental = '<c-s>',
        node_decremental = '<M-space>',
      },
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
    },
  }
end, 0)

-- [[ LSP servers configuration ]]
local lspconfig = require('lspconfig')

lspconfig.lua_ls.setup {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = {
          'vim',
          'require'
        },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

require('mason').setup()
require('mason-lspconfig').setup()

-- [[ LSP keymaps ]]
local nmap = function(keys, func, desc)
  if desc then desc = 'LSP: ' .. desc end
  vim.keymap.set('n', keys, func, { desc = desc })
end
nmap('<leader>lr', vim.lsp.buf.rename, '[r]ename')
nmap('<leader>la', vim.lsp.buf.code_action, 'Code [a]ction')
nmap('gd', require('telescope.builtin').lsp_definitions, '[g]oto [d]efinition')
nmap('gr', require('telescope.builtin').lsp_references, '[g]oto [r]eferences')
nmap('gI', require('telescope.builtin').lsp_implementations, '[g]oto [I]mplementation')
nmap('<leader>ly', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'workspace s[y]mbols')
nmap('K', function() vim.lsp.buf.hover({ border = "rounded" }) end, 'Hover Documentation')
nmap('<leader>lk', function() vim.lsp.buf.signature_help({ border = "rounded" }) end, 'Signature Documentation')
nmap('gD', vim.lsp.buf.declaration, '[g]oto [D]eclaration')

-- [[ Configure nvim-cmp ]]
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
end

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noselect',
  },
  preselect = cmp.PreselectMode.None,
  mapping = {
    ["<Tab>"] = vim.schedule_wrap(function(fallback)
      if cmp.visible() and has_words_before() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end),
    ["<CR>"] = cmp.mapping.confirm({ selected = true }),
  },
  sources = {
    { name = 'nvim_lsp',      priority = 500 },
    { name = 'luasnip',       priority = 500 },
    { name = 'copilot',       priority = 1000 },
    { name = 'path',          priority = 300 },
    { name = 'buffer',        priority = 300 },
    { name = 'codecompanion', priority = 700 },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
}

-- [[ Configure Harpoon ]]
local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon [a]dd" })
vim.keymap.set("n", "<leader><space>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
  { desc = "[ ] Harpoon ui" })

vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)

require("which-key").add({
  { "<leader>1", hidden = true },
  { "<leader>2", hidden = true },
  { "<leader>3", hidden = true },
  { "<leader>4", hidden = true },
})

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "[h", function() harpoon:list():prev() end, { desc = "Harpoon previous" })
vim.keymap.set("n", "]h", function() harpoon:list():next() end, { desc = "Harpoon next" })
