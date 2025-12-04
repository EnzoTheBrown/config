-----------------------------------------------------------
-- Basic Settings
-----------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.g.mapleader = " "

vim.opt.clipboard = "unnamedplus"
-----------------------------------------------------------
-- lazy.nvim bootstrap
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- Plugins
-----------------------------------------------------------

require("lazy").setup({
  -- Theme
  { "folke/tokyonight.nvim" },

  -- File explorer
  { "nvim-tree/nvim-tree.lua" },

  -- Status line
  { "nvim-lualine/lualine.nvim" },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  ---------------------------------------------------------
  -- LSP & completion
  ---------------------------------------------------------
  -- LSP core
  { "neovim/nvim-lspconfig" },

  -- Mason: LSP/DAP/formatter installer
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
  },
    -- Icons (for nvim-tree, lualine, render-markdown, etc.)
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },
    -- Animated smear cursor
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- defaults are fine to start with
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons", -- icons (also useful for nvim-tree & lualine)
    },
    opts = {
      -- run on markdown (you can add 'quarto', 'gitcommit', etc. later)
      file_types = { "markdown" },
    },
  },
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
  },
{
    "gbprod/yanky.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("yanky").setup({
        highlight = {
          on_put = true,
          on_yank = true,
          timer = 200,
        },
      })

      -- Telescope picker for yank history
      local map = vim.keymap.set
      map("n", "<leader>y", "<cmd>Telescope yank_history<CR>", { desc = "Yank history" })
    end,
  },

  -- none-ls (ex null-ls) + Mason bridge
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "jay-babu/mason-null-ls.nvim",
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8", -- ou à jour, comme tu veux
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
  },
  {
  "rest-nvim/rest.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = function (_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "http")
    end,
  }
}
})

-----------------------------------------------------------
-- Colorscheme & basic plugin setup
-----------------------------------------------------------
vim.cmd.colorscheme("tokyonight")

require("nvim-tree").setup()
require("lualine").setup({
  options = {
    theme = "tokyonight",
  },
})

-----------------------------------------------------------
-- Telescope
-----------------------------------------------------------
local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
  defaults = {
    layout_config = {
      horizontal = { preview_width = 0.55 },
    },
    mappings = {
      i = {
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
    },
  },
})

pcall(telescope.load_extension, "fzf")
-----------------------------------------------------------
-- Completion (nvim-cmp)
-----------------------------------------------------------
local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

-----------------------------------------------------------
-- LSP: on_attach (KEYMAPS HERE)
-----------------------------------------------------------
local on_attach = function(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Go to definition / implementation
  bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
  bufmap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
  bufmap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
  bufmap("n", "gr", vim.lsp.buf.references, "Go to References")

  -- Hover, rename, code actions, etc.
  bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
  bufmap("n", "<leader>fd", function()
    vim.diagnostic.open_float()
  end, "Line Diagnostics")
  bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
  bufmap("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
end

-----------------------------------------------------------
-- Telescope keymaps
-----------------------------------------------------------
local map = vim.keymap.set
local builtin = require("telescope.builtin")

-- Fichiers
map("n", "<leader>sf", builtin.find_files, { desc = "Telescope: find files" })
map("n", "<leader>sg", builtin.live_grep, { desc = "Telescope: live grep" })
map("n", "<leader> ", builtin.buffers, { desc = "Telescope: buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: help" })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })
-- Git (si repo git)
map("n", "<leader>gf", builtin.git_files, { desc = "Telescope: git files" })

-- LSP pickers (en bonus)
map("n", "<leader>lr", builtin.lsp_references, { desc = "Telescope: LSP references" })
map("n", "<leader>ld", builtin.lsp_definitions, { desc = "Telescope: LSP definitions" })
map("n", "<leader>li", builtin.lsp_implementations, { desc = "Telescope: LSP implementations" })
map("n", "<leader>ls", builtin.lsp_document_symbols, { desc = "Telescope: LSP symbols" })

-----------------------------------------------------------
-- LSP servers via mason-lspconfig
-----------------------------------------------------------
local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")

mason.setup()

-- List of LSP servers you want
local servers = {
  "ruff",         -- Python
  "lua_ls",       -- Lua
}

mason_lspconfig.setup({
  ensure_installed = servers,
  automatic_installation = true,
})


-----------------------------------------------------------
-- LSP: on_attach (KEYMAPS)
-----------------------------------------------------------
local on_attach = function(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Navigation
  bufmap("n", "gd", vim.lsp.buf.definition, "Go to Definition")
  bufmap("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
  bufmap("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
  bufmap("n", "gr", vim.lsp.buf.references, "Go to References")

  -- Info / actions
  bufmap("n", "K", vim.lsp.buf.hover, "Hover Documentation")
  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
  bufmap("n", "<leader>fd", function() vim.diagnostic.open_float() end, "Line Diagnostics")
  bufmap("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
  bufmap("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()


-----------------------------------------------------------
-- none-ls (null-ls) + format on save
-----------------------------------------------------------
local null_ls = require("null-ls")
local mason_null_ls = require("mason-null-ls")

-- Tools managed by Mason for none-ls
mason_null_ls.setup({
  ensure_installed = {
    "prettier",             -- JS/TS/JSON formatter
    "eslint_d",             -- JS/TS linter
    "black",                -- Python formatter
  },
  automatic_installation = true,
})

local formatting_group = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
  sources = {
    -- Formatters
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.black,

    -- Diagnostics
    null_ls.builtins.diagnostics.eslint_d,
  },
  on_attach = function(client, bufnr)
    -- Format on save if the server supports it
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = formatting_group, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = formatting_group,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end

    -- Keep other LSP keymaps
    on_attach(client, bufnr)
  end,
})

-----------------------------------------------------------
-- A few useful global keymaps
-----------------------------------------------------------
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>")
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<leader>Q", ":qa!<CR>", { desc = "Quit all without saving" })

-----------------------------------------------------------
-- Highlight on yank
-----------------------------------------------------------

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({
      higroup = "IncSearch", -- or "Visual" or a custom group
      timeout = 200,         -- time in ms
    })
  end,
})
