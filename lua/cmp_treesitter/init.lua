local treesitter = require('cmp_treesitter.treesitter')

local defaults = {
  keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%([\-]\w*\)*\)]],
  get_bufnrs = function()
    return { vim.api.nvim_get_current_buf() }
  end,
}

local source = {}

source.new = function()
  local self = setmetatable({}, { __index = source })
  self.treesitters = {}
  return self
end

source.get_keyword_pattern = function(_, params)
  params.option = vim.tbl_deep_extend('keep', params.option, defaults)
  vim.validate({
    keyword_pattern = {
      params.option.keyword_pattern,
      'string',
      '`opts.keyword_pattern` must be `string`',
    },
    get_bufnrs = { params.option.get_bufnrs, 'function', '`opts.get_bufnrs` must be `function`' },
  })
  return params.option.keyword_pattern
end

local function trim(s)
  s = s:match('^%s*(.-)%s*$')
  return s:match('^%p*(.-)%p*$')
end

source.complete = function(self, params, callback)
  params.option = vim.tbl_deep_extend('keep', params.option, defaults)
  vim.validate({
    keyword_pattern = {
      params.option.keyword_pattern,
      'string',
      '`opts.keyword_pattern` must be `string`',
    },
    get_bufnrs = { params.option.get_bufnrs, 'function', '`opts.get_bufnrs` must be `function`' },
  })

  local processing = true
  local buf_ts = self:_get_treesitters(params)

  local input = string.sub(params.context.cursor_before_line, params.offset)
  local items = {}
  local words = {}

  for _, ts in pairs(buf_ts) do
    local async_ts = ts:async_get()
    -- note : coroutine does not help with multitasking
    local flg, tsnds = coroutine.resume(async_ts)
    -- print('f', flg)
    if flg and tsnds.words ~= nil then
      for _, word in ipairs(tsnds.words) do
        if not words[word.word] and input ~= word then
          words[word.word] = true
          local w = word.word
          if #w > 25 then
            w = string.sub(w, 1, 25) .. ''
          end
          table.insert(items, { label = w, insertText = word.word, dup = 0 })
        end
      end
    end
  end
  processing = true
  -- print("items", vim.inspect(items))
  callback({ items = items, isIncomplete = processing })
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
