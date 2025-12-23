local function change_id()
  local cmd = "jj --ignore-working-copy --quiet log -r @ --template 'self.change_id().shortest()' --no-graph"
  return " " .. io.popen(cmd):read("*a"):gsub("\n", "")
end
return {
  "nvim-lualine/lualine.nvim",
  opts = { sections = { lualine_b = { change_id } } },
}
