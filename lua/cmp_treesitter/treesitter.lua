local lru = require 'cmp_treesitter.lru'
local treesitter = {}
local cache = lru.new(512 * 1024, 8 * 1024 * 1024)

function treesitter.new(bufnr)
  local fname = vim.fn.expand("%:p:f")
  local uri = vim.uri_from_fname(fname)

  if bufnr ~= 0 and bufnr ~= nil then
    uri = vim.uri_from_bufnr(bufnr)
    fname = vim.uri_to_fname(uri)
  else
    bufnr = vim.fn.bufnr()
  end

  local ftime = vim.fn.getftime(fname)
  local result = cache:get(bufnr)
  if result ~= nil and result.ftime == ftime then
    return result
  end
  local self = setmetatable({}, {__index = treesitter})
  self.bufnr = bufnr -- dict bufnr : buf timestamp
  self.words = {}
  self.fname = fname
  self.ftime = 0
  self.processing = true
  cache:set(bufnr, self)
  return self
end

-- get all nodes
function treesitter.get_nodes(self)
  local result = cache:get(self.bufnr)
  if result ~= nil and result.ftime == vim.fn.getftime(self.fname) then
    return result
  end

  local ok, parser = pcall(vim.treesitter.get_parser)
  if not ok then
    return {}
  end
  local candidates = {}
  for _, tree in pairs(parser:parse()) do
    local query = vim.treesitter.get_query(parser:lang(), 'Highlights')
    for i, node in query:iter_captures(tree:root(), 0) do
      local parent = node:parent()
      local grandparent = parent and parent:parent() or nil
      local word = vim.treesitter.get_node_text(node, 0)
      if word then
        table.insert(candidates, {
          word = word,
          kind = query.captures[i],
          parent = parent and vim.treesitter.get_node_text(parent, 0) or nil,
          grandparent = grandparent and vim.treesitter.get_node_text(grandparent, 0) or nil
        })
      end
    end
  end
  self.words = candidates
  self.processing = false
  cache:set(self.bufnr, self)
  return self
end

return treesitter.new()
