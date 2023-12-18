local co, api = coroutine, vim.api
local whk = {}

local function stl_format(name, val)
  return '%#Whisky' .. name .. '#' .. val .. '%*'
end

local function stl_hl(name, attr)
  api.nvim_set_hl(0, 'Whisky' .. name, attr)
end

local function default()
  local p = require('whiskyline.provider')
  local s = require('whiskyline.seperator')

  local comps = {
    s.l_left(),
    p.fileicon(),
    p.fileinfo(),
    p.modify(),

    s.l_right(),
    --
    s.sep(),
    --
    s.l_left(),
    p.filesize(),
    s.l_right(),
    --
    s.sep(),
    --
    s.l_left(),
    p.lnumcol(),
    s.l_right(),
    --
    s.sep(),
    --
    p.search(),
    s.sep(),
    p.diagError(),
    p.diagWarn(),
    p.diagInfo(),
    p.diagHint(),
    --
    p.pad(),
    p.pad(),
    --
    s.sep(),
    --
    s.r_left(),
    p.lsp(),
    s.r_right(),
    s.sep(),
    --
    s.r_left(),
    p.gitadd(),
    p.gitchange(),
    p.gitdelete(),
    p.branch(),
    s.r_right(),
  }
  local e, pieces = {}, {}
  vim
    .iter(ipairs(comps))
    :map(function(key, item)
      if type(item.stl) == 'string' then
        pieces[#pieces + 1] = stl_format(item.name, item.stl)
      else
        pieces[#pieces + 1] = item.default and stl_format(item.name, item.default) or ''
        for _, event in ipairs({ unpack(item.event or {}) }) do
          if not e[event] then
            e[event] = {}
          end
          e[event][#e[event] + 1] = key
        end
      end

      if item.attr and item.name then
        stl_hl(item.name, item.attr)
      end
    end)
    :totable()
  return comps, e, pieces
end

local function render(comps, events, pieces)
  return co.create(function(args)
    while true do
      local event = args.event == 'User' and args.event .. ' ' .. args.match or args.event
      for _, idx in ipairs(events[event]) do
        pieces[idx] = stl_format(comps[idx].name, comps[idx].stl(args))
      end

      -- because setup use a timer to defer parse and render this will cause missing
      -- `BufEnter` event so add a safe check
      -- NVIM v0.10.0-dev-1571+gba58c6f8a

      -- local keys = { 2, 8, 34 }
      -- for _, idx in ipairs(keys) do
      --   if comps[idx] and #pieces[idx] == 0 then
      --     pieces[idx] = stl_format(comps[idx].name, comps[idx].stl(args))
      --   end
      -- end

      vim.opt.stl = table.concat(pieces)
      args = co.yield()
    end
  end)
end

function whk.setup(opt)
  opt = opt or { bg = '#3e4443' }
  whk.bg = opt.bg

  local comps, events, pieces = default()
  local stl_render = render(comps, events, pieces)
  for _, e in ipairs(vim.tbl_keys(events)) do
    local tmp = e
    local pattern
    if e:find('User') then
      pattern = vim.split(e, '%s')[2]
      tmp = 'User'
    end

    api.nvim_create_autocmd(tmp, {
      pattern = pattern,
      callback = function(args)
        vim.schedule(function()
          local ok, res = co.resume(stl_render, args)
          if not ok then
            vim.notify('[Whisky] render failed ' .. res, vim.log.levels.ERROR)
          end
        end)
      end,
    })
  end
end

return whk
