local api, lsp = vim.api, vim.lsp
local pd = {}

function pd.stl_bg()
  local res = api.nvim_get_hl(0, { name = 'StatusLine' })
  if vim.tbl_isempty(res) then
    vim.notify('[Whisky] colorschem missing StatusLine config')
    return
  end
  return res.bg
end

local function stl_attr(group, trans)
  local color = api.nvim_get_hl(0, { name = group, link = false })
  trans = trans or false
  return {
    bg = trans and 'NONE' or pd.stl_bg(),
    fg = color.fg,
  }
end

function pd.sep()
  return {
    stl = ' ',
    name = 'sep',
    attr = {
      background = 'NONE',
      foreground = 'NONE',
    },
  }
end

function pd.fileinfo()
  local result = {
    stl = '%t%r%m',
    name = 'fileinfo',
    event = { 'BufEnter' },
  }

  result.attr = stl_attr('CursorLineNr')

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
    name = 'search',
    event = { 'CursorHold' },
  }
  result.attr = stl_attr('Repeat', true)

  return result
end

function pd.lsp()
  local function lsp_stl(args)
    local client = lsp.get_client_by_id(args.data.client_id)
    local msg = client and client.name or ''
    if args.data.result then
      local val = args.data.result.value
      msg = val.title
        .. ' '
        .. (val.message and val.message .. ' ' or '')
        .. (val.percentage and val.percentage .. '%' or '')
      if not val.message or val.kind == 'end' then
        ---@diagnostic disable-next-line: need-check-nil
        msg = client.name
      end
    elseif args.event == 'LspDetach' then
      msg = ''
    end
    return '%.40{"' .. msg .. '"}'
  end

  local result = {
    stl = lsp_stl,
    name = 'Lsp',
    event = { 'LspProgress', 'LspAttach', 'LspDetach' },
  }

  result.attr = stl_attr('Function')
  return result
end

local function gitsigns_data(type)
  if not vim.b.gitsigns_status_dict then
    return ''
  end

  local val = vim.b.gitsigns_status_dict[type]
  val = (val == 0 or not val) and '' or tostring(val) .. (type == 'head' and '' or ' ')
  return val
end

function pd.gitadd()
  local result = {
    stl = function()
      local res = gitsigns_data('added')
      return #res > 0 and '+' .. res or ''
    end,
    name = 'gitadd',
    event = { 'User GitSignsUpdate' },
  }
  result.attr = stl_attr('DiffAdd')
  return result
end

function pd.gitchange()
  local result = {
    stl = function()
      local res = gitsigns_data('changed')
      return #res > 0 and '~' .. res or ''
    end,
    name = 'gitchange',
    event = { 'User GitSignsUpdate' },
  }

  result.attr = stl_attr('DiffChange')
  return result
end

function pd.gitdelete()
  local result = {
    stl = function()
      local res = gitsigns_data('removed')
      return #res > 0 and '-' .. res or ''
    end,
    name = 'gitdelete',
    event = { 'User GitSignsUpdate' },
  }

  result.attr = stl_attr('DiffDelete')
  return result
end

function pd.branch()
  local result = {
    stl = function()
      local icon = ' '
      local res = gitsigns_data('head')
      return #res > 0 and icon .. res or ''
    end,
    name = 'gitbranch',
    event = { 'BufEnter', 'BufNewFile', 'User GitSignsUpdate' },
  }
  result.attr = stl_attr('Include')
  return result
end

function pd.pad()
  return {
    stl = '%=',
    name = 'pad',
    attr = {
      background = 'NONE',
      foreground = 'NONE',
    },
  }
end

function pd.lnumcol()
  local result = {
    stl = '%-4.(%l:%c%)',
    name = 'linecol',
    event = { 'CursorHold' },
  }

  result.attr = stl_attr('Number')
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
    name = 'diagError',
    event = { 'DiagnosticChanged', 'BufEnter' },
  }
  result.attr = stl_attr('DiagnosticError', true)
  return result
end

function pd.diagWarn()
  local result = {
    stl = function()
      return diagnostic_info(2)
    end,
    name = 'diagWarn',
    event = { 'DiagnosticChanged', 'BufEnter' },
  }
  result.attr = stl_attr('DiagnosticWarn', true)
  return result
end

function pd.diagInfo()
  local result = {
    stl = function()
      return diagnostic_info(3)
    end,
    name = 'diaginfo',
    event = { 'DiagnosticChanged', 'BufEnter' },
  }
  result.attr = stl_attr('DiagnosticInfo', true)
  return result
end

function pd.diagHint()
  local result = {
    stl = function()
      return diagnostic_info(4)
    end,
    name = 'diaghint',
    event = { 'DiagnosticChanged', 'BufEnter' },
  }
  result.attr = stl_attr('DiagnosticHint', true)
  return result
end

return pd
