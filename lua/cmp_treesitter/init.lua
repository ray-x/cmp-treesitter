local treesitter = require('cmp_treesitter.treesitter')

local defaults = {
  keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-]\w*\)*\)]],
  get_bufnrs = function()
    return {vim.api.nvim_get_current_buf()}
  end
}

local source = {}

source.new = function()
  local self = setmetatable({}, {__index = source})
  self.treesitters = {}
  return self
end

source.get_keyword_pattern = function(_, params)
  params.option = vim.tbl_deep_extend('keep', params.option, defaults)
  vim.validate({
    keyword_pattern = {
      params.option.keyword_pattern, 'string', '`opts.keyword_pattern` must be `string`'
    },
    get_bufnrs = {params.option.get_bufnrs, 'function', '`opts.get_bufnrs` must be `function`'}
  })
  return params.option.keyword_pattern
end

source.complete = function(self, params, callback)
  vim.validate({
    keyword_pattern = {
      params.option.keyword_pattern, 'string', '`opts.keyword_pattern` must be `string`'
    },
    get_bufnrs = {params.option.get_bufnrs, 'function', '`opts.get_bufnrs` must be `function`'}
  })

  local processing = false
  for _, ts in ipairs(self:_get_treesitters(params)) do
    processing = processing or ts.processing
  end

  vim.defer_fn(vim.schedule_wrap(function()
    local input = string.sub(params.context.cursor_before_line, params.offset)
    local items = {}
    local words = {}
    for _, ts in ipairs(self:_get_treesitters(params)) do
      for _, word in ipairs(ts:get_nodes().words) do
        if not words[word.word] and input ~= word then
          words[word.word] = true
          table.insert(items, {label = word.word, dup = 0})
        end
      end
    end
    callback({items = items, isIncomplete = processing})
  end), processing and 10 or 0)
end

--- _get_treesitters
source._get_treesitters = function(self, params)
  for _, bufnr in ipairs(params.option.get_bufnrs()) do
    local new_treesitter = treesitter.new(bufnr)
    self.treesitters[bufnr] = new_treesitter
  end

  return self.treesitters
end

return source
