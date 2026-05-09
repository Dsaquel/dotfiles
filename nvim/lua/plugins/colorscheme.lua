local function read_flavour()
  local path = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-flavour"
  local ok, fd = pcall(io.open, path, "r")
  if not ok or not fd then return "mocha" end
  local val = fd:read("*l") or "mocha"
  fd:close()
  if val == "latte" or val == "mocha" then return val end
  return "mocha"
end

local function apply_flavour(flavour)
  pcall(function()
    require("catppuccin").setup({ flavour = flavour, transparent_background = true })
    vim.cmd.colorscheme("catppuccin")
  end)
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      apply_flavour(read_flavour())
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        callback = function()
          apply_flavour(read_flavour())
        end,
      })
    end,
  },
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    priority = 100,
    opts = function()
      return { transparent = true }
    end,
  },
}
