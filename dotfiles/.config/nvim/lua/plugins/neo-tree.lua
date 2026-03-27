local function get_paths(state)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local paths = {}
  for line = start_line, end_line do
    local node = state.tree:get_node(line)
    if node and node:get_id() then
      table.insert(paths, vim.fn.fnamemodify(node:get_id(), ":."))
    end
  end
  return paths
end

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        mappings = {
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local relative = vim.fn.fnamemodify(node:get_id(), ":.")
              vim.fn.setreg("+", relative, "c")
              vim.notify("Copied relative path", vim.log.levels.INFO)
            end,
            desc = "Copy Relative Path to Clipboard",
          },
          ["YY"] = {
            function(state)
              local path = state.tree:get_node():get_id()
              vim.fn.setreg("+", path, "c")
              vim.notify("Copied absolute path", vim.log.levels.INFO)
            end,
            desc = "Copy Absolute Path to Clipboard",
          },
        },
      },
    },
    keys = {
      {
        "Y",
        function()
          local state = require("neo-tree.sources.manager").get_state("filesystem")
          local paths = get_paths(state)
          local text = table.concat(paths, "\n")
          vim.fn.setreg("+", text, "c")
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
          vim.notify("Copied " .. #paths .. " relative paths", vim.log.levels.INFO)
        end,
        mode = "v",
        ft = "neo-tree",
        desc = "Copy Relative Paths to Clipboard",
      },
    },
  },
}
