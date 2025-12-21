local function change_id()
  return " " .. io.popen("jj log -r @ --template 'self.change_id().shortest()' --no-graph"):read("*a"):gsub("\n", "")
end

return {
  {
    "nicolasgb/jj.nvim",
    config = function()
      require("jj").setup({})
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = { sections = { lualine_b = { change_id } } },
  },
}
