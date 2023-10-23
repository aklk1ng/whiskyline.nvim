local api, uv, lsp = vim.api, vim.uv, vim.lsp
local pd = {}

function pd.stl_bg()
  return require('whiskyline').bg
end

local function stl_attr(group, trans)
  local color = api.nvim_get_hl_by_name(group, true)
  trans = trans or false
  return {
    bg = trans and 'NONE' or pd.stl_bg(),
    fg = color.foreground,
  }
end

local function path_sep()
  return uv.os_uname().sysname == 'Windows_NT' and '\\' or '/'
end

function pd.fileicon()
  local ok, devicon = pcall(require, 'nvim-web-devicons')
  local icon, color

  return {
    stl = function()
      if ok then
        icon, color = devicon.get_icon_color_by_filetype(vim.bo.filetype, { default = true })
        api.nvim_set_hl(0, 'Whiskyfileicon', { bg = pd.stl_bg(), fg = color })
        return icon .. ' '
      end
      return ''
    end,
    name = 'fileicon',
    event = { 'BufEnter' },
    attr = {
      bg = pd.stl_bg(),
    },
  }
end

function pd.fileinfo()
  local result = {
    stl = '%t',
    name = 'fileinfo',
    event = { 'BufEnter' },
  }

  result.attr = stl_attr('Normal')

  return result
end

function pd.filesize()
  local function get_size()
    local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
    local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
    fsize = (fsize < 0 and 0) or fsize
    local i = 1
    while fsize > 1024 and i < #suffix do
      fsize = fsize / 1024
      i = i + 1
    end
    local format = i == 1 and '%d%s' or '%.1f%s'
    return string.format(format, fsize, suffix[i])
  end
  local result = {
    stl = get_size,
    name = 'filesize',
    event = { 'BufEnter', 'BufWritePost' },
  }

  result.attr = stl_attr('WarningMsg')

  return result
end

function pd.modify()
  local result = {
    stl = '%m',
    name = 'modify',
    event = { 'BufModifiedSet' },
  }

  result.attr = stl_attr('WarningMsg')

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

local function git_icons(type)
  local tbl = {
    ['added'] = ' ',
    ['changed'] = ' ',
    ['deleted'] = ' ',
  }
  return tbl[type]
end

function pd.gitadd()
  local result = {
    stl = function()
      local res = gitsigns_data('added')
      return #res > 0 and git_icons('added') .. res or ''
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
      return #res > 0 and git_icons('changed') .. res or ''
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
      return #res > 0 and git_icons('deleted') .. res or ''
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
    event = { 'User GitSignsUpdate' },
  }
  result.attr = stl_attr('Include')
  result.attr.bold = true
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

  local signs = {
    ' ',
    ' ',
    ' ',
    ' ',
  }
  local count = #vim.diagnostic.get(0, { severity = severity })
  return count == 0 and '' or signs[severity] .. tostring(count) .. ' '
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

function pd.encoding()
  local result = {
    stl = function()
      return vim.bo.fileencoding:upper()
    end,
    name = 'filencode',
    event = { 'BufEnter' },
  }
  result.attr = stl_attr('Type')
  return result
end

return pd
