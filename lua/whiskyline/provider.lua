local api, lsp = vim.api, vim.lsp
local pd = {}

function pd.sep()
  return {
    stl = ' ',
  }
end

function pd.fileinfo()
  local result = {
    stl = '%t%r%m',
    event = { 'BufEnter' },
    attr = 'CursorLineNr',
  }

  return result
end

function pd.search()
  local function res()
    if vim.v.hlsearch == 0 then
      return ''
    end
    local search = vim.fn.searchcount()
    local current = search.current
    local cnt = math.min(search.total, search.maxcount)
    return string.format('[%d/%d]', current, cnt)
  end
  local result = {
    stl = res,
    event = { 'CursorHold' },
    attr = 'Repeat',
  }

  return result
end

function pd.lsp()
  local function lsp_stl(args)
    local client = lsp.get_clients({ bufnr = args.buf })[1]
    if not client then
      return ''
    end

    local msg = client and client.name or ''
    if args.data and args.data.result then
      local val = args.data.result.value
      msg = val.title
        .. ' '
        .. (val.message and val.message .. ' ' or '')
        .. (val.percentage and val.percentage .. '%' or '')
      if not val.message or val.kind == 'end' then
        ---@diagnostic disable-next-line: need-check-nil
        msg = client.name
      end
    elseif args.event == 'BufEnter' then
      msg = client.name
    elseif args.event == 'LspDetach' then
      msg = ''
    end
    return '%.40{"' .. msg .. '"}'
  end

  local result = {
    stl = lsp_stl,
    event = { 'LspProgress', 'LspAttach', 'LspDetach', 'BufEnter' },
    attr = 'Function',
  }

  return result
end

local function gitsigns_data(bufnr, type)
  local ok, dict = pcall(api.nvim_buf_get_var, bufnr, 'gitsigns_status_dict')
  if not ok or vim.tbl_isempty(dict) or not dict[type] then
    return 0
  end

  return dict[type]
end

function pd.gitadd()
  local result = {
    stl = function(args)
      local res = gitsigns_data(args.buf, 'added')
      return res > 0 and '+' .. res or ''
    end,
    event = { 'User GitSignsUpdate' },
    attr = 'DiffAdd',
  }
  return result
end

function pd.gitchange()
  local result = {
    stl = function(args)
      local res = gitsigns_data(args.buf, 'changed')
      return res > 0 and '~' .. res or ''
    end,
    event = { 'User GitSignsUpdate' },
    attr = 'DiffChange',
  }

  return result
end

function pd.gitdelete()
  local result = {
    stl = function(args)
      local res = gitsigns_data(args.buf, 'removed')
      return res > 0 and '-' .. res or ''
    end,
    event = { 'User GitSignsUpdate' },
    attr = 'DiffDelete',
  }

  return result
end

function pd.branch()
  local result = {
    stl = function(args)
      local icon = ' '
      local res = gitsigns_data(args.buf, 'head')
      return res and icon .. res or ''
    end,
    event = { 'BufEnter', 'BufNewFile', 'User GitSignsUpdate' },
    attr = 'Include',
  }
  return result
end

function pd.pad()
  return {
    stl = '%=',
  }
end

function pd.lnumcol()
  local result = {
    stl = '%-4.(%l:%c%)',
    event = { 'CursorHold' },
    attr = 'Number',
  }

  return result
end

local function diagnostic_info(severity)
  if vim.diagnostic.is_disabled(0) then
    return ''
  end

  local tbl = {
    'E',
    'W',
    'I',
    'H',
  }
  local count = vim.diagnostic.count(0)[severity]
  return not count and '' or tbl[severity] .. tostring(count) .. ' '
end

function pd.diagError()
  local result = {
    stl = function()
      return diagnostic_info(1)
    end,
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = 'DiagnosticError',
  }
  return result
end

function pd.diagWarn()
  local result = {
    stl = function()
      return diagnostic_info(2)
    end,
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = 'DiagnosticWarn',
  }
  return result
end

function pd.diagInfo()
  local result = {
    stl = function()
      return diagnostic_info(3)
    end,
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = 'DiagnosticInfo',
  }
  return result
end

function pd.diagHint()
  local result = {
    stl = function()
      return diagnostic_info(4)
    end,
    event = { 'DiagnosticChanged', 'BufEnter' },
    attr = 'DiagnosticHint',
  }
  return result
end

return pd
