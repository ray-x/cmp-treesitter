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
    local query = vim.treesitter.get_query(parser:lang(), 'highlights')

    for i, node in query:iter_captures(tree:root(), 0) do
      local parent = node:parent()
      local grandparent = parent and parent:parent() or nil
      local word = vim.treesitter.get_node_text(node, 0)
      local kind = query.captures[i]

      if word and kind ~= 'punctuation.bracket' and kind ~= 'punctuation.delimiter' then
        table.insert(candidates, {
          word = word,
          kind = kind,
          parent = parent and vim.treesitter.get_node_text(parent, 0) or nil,
          grandparent = grandparent and vim.treesitter.get_node_text(grandparent, 0) or nil
        })
      end
    end
  end
  self.words = candidates
  self.processing = false
  self.ftime = vim.fn.getftime(self.fname)

  -- print("get nodes", vim.inspect(self))
  cache:set(self.bufnr, self)
  return self
end

function treesitter.async_get(self)
  return coroutine.create(function()
    return self:get_nodes()
  end)
end

return treesitter.new()
