-- markdown -> { lines, hls, line_hls, map }
--   lines:    rendered text, one string per preview line
--   hls:      { row, col_start, col_end, group, priority } (0-based rows, byte cols)
--   line_hls: { row, group }
--   map:      map[source_line] = preview_line (both 1-based)

local M = {}

local PRIO_BLOCK = 100
local PRIO_INLINE = 110
local PRIO_CODE = 120

local function rtrim(s)
  return (s:gsub("%s+$", ""))
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function width_of(s)
  return vim.api.nvim_strwidth(s)
end

---------------------------------------------------------------------------
-- inline
---------------------------------------------------------------------------

-- find a closing delimiter that is not preceded by whitespace
local function find_closing(s, delim, from)
  local i = from
  while true do
    local a, b = s:find(delim, i, true)
    if not a then
      return nil
    end
    if a > from and not s:sub(a - 1, a - 1):match("%s") then
      return a, b
    end
    i = a + 1
  end
end

-- s[i] == "[": returns label, url, index after ")"
local function parse_link(s, i)
  local depth, j, n = 0, i, #s
  while j <= n do
    local c = s:sub(j, j)
    if c == "\\" then
      j = j + 1
    elseif c == "[" then
      depth = depth + 1
    elseif c == "]" then
      depth = depth - 1
      if depth == 0 then
        break
      end
    end
    j = j + 1
  end
  if depth ~= 0 or s:sub(j + 1, j + 1) ~= "(" then
    return nil
  end
  local close = s:find(")", j + 2, true)
  if not close then
    return nil
  end
  return s:sub(i + 1, j - 1), s:sub(j + 2, close - 1), close + 1
end

local SPECIAL = "[\\`!%[<*_~]"

local function inline(s)
  local out, hls, len = {}, {}, 0

  local function emit(t)
    out[#out + 1] = t
    len = len + #t
  end

  local function emit_group(t, group)
    local start = len
    emit(t)
    hls[#hls + 1] = { start, len, group, PRIO_INLINE }
  end

  local function emit_nested(src, group)
    local text, inner = inline(src)
    local start = len
    for _, h in ipairs(inner) do
      hls[#hls + 1] = { h[1] + start, h[2] + start, h[3], h[4] }
    end
    emit(text)
    if group then
      hls[#hls + 1] = { start, len, group, PRIO_INLINE - 1 }
    end
  end

  local i, n = 1, #s
  while i <= n do
    local j = s:find(SPECIAL, i)
    if j ~= i then
      local stop = (j or n + 1) - 1
      emit(s:sub(i, stop))
      i = stop + 1
    else
      local c = s:sub(i, i)
      local consumed = false

      if c == "\\" then
        local nxt = s:sub(i + 1, i + 1)
        if nxt:match("%p") then
          emit(nxt)
          i = i + 2
          consumed = true
        end
      elseif c == "`" then
        local run = s:match("^`+", i)
        local from = i + #run
        while true do
          local a, b = s:find(run, from, true)
          if not a then
            break
          end
          if s:sub(b + 1, b + 1) ~= "`" then
            local code = s:sub(i + #run, a - 1)
            if #code > 2 and code:match("^ .* $") then
              code = code:sub(2, -2)
            end
            emit_group(code, "GlanceCode")
            i = b + 1
            consumed = true
            break
          end
          from = b + 1 + #(s:match("^`*", b + 1))
        end
        if not consumed then
          emit(run)
          i = i + #run
          consumed = true
        end
      elseif c == "!" and s:sub(i + 1, i + 1) == "[" then
        local alt, _, nxt = parse_link(s, i + 1)
        if alt then
          emit_group("[image" .. (alt ~= "" and (": " .. alt) or "") .. "]", "GlanceImage")
          i = nxt
          consumed = true
        end
      elseif c == "[" then
        local label, _, nxt = parse_link(s, i)
        if label then
          emit_nested(label, "GlanceLink")
          i = nxt
          consumed = true
        end
      elseif c == "<" then
        local url = s:match("^<(%a[%w+.%-]*:[^%s<>]+)>", i)
        if url then
          emit_group(url, "GlanceLink")
          i = i + #url + 2
          consumed = true
        end
      elseif c == "*" or c == "_" or c == "~" then
        local run = s:match("^%" .. c .. "+", i)
        local k = #run
        local d = math.min(k, 3)
        local after = s:sub(i + d, i + d)
        local intraword = c == "_" and i > 1 and s:sub(i - 1, i - 1):match("%w")
        if not intraword and not (c == "~" and k ~= 2) and after ~= "" and not after:match("%s") then
          local delim = c:rep(d)
          local a, b = find_closing(s, delim, i + d)
          if a and c == "_" and s:sub(b + 1, b + 1):match("%w") then
            a = nil
          end
          if a then
            local group = (c == "~" and "GlanceStrike")
              or (d == 1 and "GlanceItalic")
              or (d == 2 and "GlanceBold")
              or "GlanceBoldItalic"
            emit_nested(s:sub(i + d, a - 1), group)
            i = b + 1
            consumed = true
          end
        end
        if not consumed then
          emit(run)
          i = i + k
          consumed = true
        end
      end

      if not consumed then
        emit(c)
        i = i + 1
      end
    end
  end

  return table.concat(out), hls
end

M.inline = inline

---------------------------------------------------------------------------
-- code block highlighting via treesitter (optional)
---------------------------------------------------------------------------

local lang_cache = {}

local function resolve_lang(info)
  if info == "" then
    return nil
  end
  local cached = lang_cache[info]
  if cached ~= nil then
    return cached or nil
  end
  local candidates = { info, vim.treesitter.language.get_lang(info) }
  local ok_ft, ft = pcall(vim.filetype.match, { filename = "x." .. info })
  if ok_ft and ft then
    candidates[#candidates + 1] = vim.treesitter.language.get_lang(ft) or ft
  end
  for _, lang in ipairs(candidates) do
    local ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
    if ok and query then
      lang_cache[info] = { lang = lang, query = query }
      return lang_cache[info]
    end
  end
  lang_cache[info] = false
  return nil
end

-- cache of highlighted blocks, rebuilt every render so stale entries drop
local code_cache, next_code_cache = {}, {}

local function code_highlights(code_lines, info)
  local key = info .. "\0" .. table.concat(code_lines, "\n")
  local hit = code_cache[key] or next_code_cache[key]
  if hit then
    next_code_cache[key] = hit
    return hit
  end

  local result = {}
  local entry = resolve_lang(info)
  if entry then
    local code = table.concat(code_lines, "\n")
    local ok, parser = pcall(vim.treesitter.get_string_parser, code, entry.lang)
    local trees = ok and select(2, pcall(parser.parse, parser))
    local tree = type(trees) == "table" and trees[1]
    if tree then
      for id, node in entry.query:iter_captures(tree:root(), code, 0, -1) do
        local name = entry.query.captures[id]
        if name:sub(1, 1) ~= "_" and name ~= "spell" and name ~= "nospell" and name ~= "conceal" then
          local group = "@" .. name .. "." .. entry.lang
          local sr, sc, er, ec = node:range()
          for r = sr, er do
            local line = code_lines[r + 1]
            if not line then
              break
            end
            local cs = (r == sr) and sc or 0
            local ce = (r == er) and ec or #line
            if ce > cs then
              result[#result + 1] = { r, cs, ce, group }
            end
          end
        end
      end
    end
  end

  next_code_cache[key] = result
  return result
end

---------------------------------------------------------------------------
-- blocks
---------------------------------------------------------------------------

local BULLETS = { "•", "◦", "▪", "▫" }
local QUOTE_BAR = "▎ "

local function is_hr(line)
  local t = line:gsub("%s", "")
  return #t >= 3 and (t:match("^%-+$") or t:match("^%*+$") or t:match("^_+$")) ~= nil
end

local function heading(line)
  local hashes, text = line:match("^%s?%s?%s?(#+)%s+(.-)%s*$")
  if not hashes then
    hashes = line:match("^%s?%s?%s?(#+)%s*$")
    text = ""
  end
  if hashes and #hashes <= 6 then
    text = text:gsub("%s+#+$", "")
    return #hashes, text
  end
end

local function fence_open(line)
  local indent, fence, info = line:match("^(%s*)(```+)%s*([^`]*)$")
  if not fence then
    indent, fence, info = line:match("^(%s*)(~~~+)%s*(.*)$")
  end
  if fence then
    return { indent = #indent, char = fence:sub(1, 1), len = #fence, lang = (info:match("^(%S+)") or ""):lower() }
  end
end

local function fence_close(line, f)
  local run = line:match("^%s*(" .. (f.char == "`" and "`" or "~") .. "+)%s*$")
  return run ~= nil and #run >= f.len
end

local function split_cells(line)
  local s = trim(line)
  if s:sub(1, 1) == "|" then
    s = s:sub(2)
  end
  if s:sub(-1) == "|" and s:sub(-2, -2) ~= "\\" then
    s = s:sub(1, -2)
  end
  local cells, cur, in_code = {}, {}, false
  local i = 1
  while i <= #s do
    local c = s:sub(i, i)
    if c == "\\" and s:sub(i + 1, i + 1) == "|" then
      cur[#cur + 1] = "|"
      i = i + 1
    elseif c == "`" then
      in_code = not in_code
      cur[#cur + 1] = c
    elseif c == "|" and not in_code then
      cells[#cells + 1] = trim(table.concat(cur))
      cur = {}
    else
      cur[#cur + 1] = c
    end
    i = i + 1
  end
  cells[#cells + 1] = trim(table.concat(cur))
  return cells
end

local function table_aligns(line)
  if not line or not line:find("-", 1, true) then
    return nil
  end
  local aligns = {}
  for _, cell in ipairs(split_cells(line)) do
    if not cell:match("^:?%-+:?$") then
      return nil
    end
    local l, r = cell:sub(1, 1) == ":", cell:sub(-1) == ":"
    aligns[#aligns + 1] = (l and r) and "center" or r and "right" or "left"
  end
  return aligns
end

function M.render(src, opts)
  opts = opts or {}
  local width = math.max(opts.width or 80, 10)

  local R = { lines = {}, hls = {}, line_hls = {}, map = {} }
  code_cache, next_code_cache = next_code_cache, {}

  local function add(text, hls, line_hl, prio)
    local row = #R.lines
    R.lines[row + 1] = text
    if hls then
      for _, h in ipairs(hls) do
        R.hls[#R.hls + 1] = { row, h[1], h[2], h[3], h[4] or prio or PRIO_BLOCK }
      end
    end
    if line_hl then
      R.line_hls[#R.line_hls + 1] = { row, line_hl }
    end
    return row
  end

  local function map(i)
    R.map[i] = #R.lines + 1
  end

  local function shift(hls, by)
    for _, h in ipairs(hls) do
      h[1], h[2] = h[1] + by, h[2] + by
    end
    return hls
  end

  -- paragraph / list item / task item
  local function simple(line)
    local ind, marker, rest = line:match("^(%s*)([-*+])%s+(.*)$")
    local num, delim
    if not ind then
      ind, num, delim, rest = line:match("^(%s*)(%d+)([.)])%s+(.*)$")
    end
    if not ind then
      return inline(rtrim(line))
    end
    ind = ind:gsub("\t", "    ")
    local text, hls = inline(rtrim(rest))
    local prefix, prefix_group, text_group
    if marker then
      local box, body = text:match("^%[([ xX])%]%s+(.*)$")
      if not box then
        box = text:match("^%[([ xX])%]$")
        body = box and ""
      end
      if box then
        local done = box ~= " "
        shift(hls, #body - #text)
        text = body
        prefix = ind .. (done and "☑ " or "☐ ")
        prefix_group = done and "GlanceDone" or "GlanceTodo"
        text_group = done and "GlanceDoneText" or nil
      else
        local level = math.floor(#ind / 2) % #BULLETS + 1
        prefix = ind .. BULLETS[level] .. " "
        prefix_group = "GlanceBullet"
      end
    else
      prefix = ind .. num .. delim .. " "
      prefix_group = "GlanceBullet"
    end
    shift(hls, #prefix)
    table.insert(hls, 1, { #ind, #prefix - 1, prefix_group, PRIO_BLOCK })
    if text_group then
      table.insert(hls, 1, { #prefix, #prefix + #text, text_group, PRIO_BLOCK })
    end
    return prefix .. text, hls
  end

  local function add_heading(level, text_src, underline_src)
    local group = "GlanceH" .. level
    local text, hls = inline(text_src)
    table.insert(hls, 1, { 0, #text, group, PRIO_BLOCK })
    add(text, hls)
    if level <= 2 then
      if underline_src then
        map(underline_src)
      end
      local w = math.max(math.min(width_of(text), width), 1)
      local bar = (level == 1 and "━" or "─"):rep(w)
      add(bar, { { 0, #bar, group } })
    end
  end

  local function add_table(start, aligns)
    local rows, srcs = {}, {}
    local i = start
    while i <= #src and src[i]:find("|", 1, true) and src[i]:match("%S") do
      if i ~= start + 1 then
        local cells = {}
        for c, raw in ipairs(split_cells(src[i])) do
          local text, hls = inline(raw)
          cells[c] = { text = text, hls = hls, w = width_of(text) }
        end
        rows[#rows + 1] = cells
        srcs[#srcs + 1] = i
      end
      i = i + 1
    end

    local ncols = #aligns
    for _, r in ipairs(rows) do
      ncols = math.max(ncols, #r)
    end
    local widths = {}
    for c = 1, ncols do
      widths[c] = 1
      for _, r in ipairs(rows) do
        if r[c] then
          widths[c] = math.max(widths[c], r[c].w)
        end
      end
    end

    local function border(l, m, r)
      local parts = {}
      for c = 1, ncols do
        parts[c] = ("─"):rep(widths[c] + 2)
      end
      local s = l .. table.concat(parts, m) .. r
      add(s, { { 0, #s, "GlanceTableBorder" } })
    end

    local function row(cells, header)
      local buf, hls, len = {}, {}, 0
      local function push(t, group)
        buf[#buf + 1] = t
        if group then
          hls[#hls + 1] = { len, len + #t, group, PRIO_BLOCK }
        end
        len = len + #t
      end
      push("│", "GlanceTableBorder")
      for c = 1, ncols do
        local cell = cells[c] or { text = "", hls = {}, w = 0 }
        local gap = widths[c] - cell.w
        local align = aligns[c] or "left"
        local lpad = align == "right" and gap or align == "center" and math.floor(gap / 2) or 0
        push(" " .. (" "):rep(lpad))
        local start = len
        push(cell.text, header and "GlanceTableHeader" or nil)
        for _, h in ipairs(cell.hls) do
          hls[#hls + 1] = { h[1] + start, h[2] + start, h[3], h[4] }
        end
        push((" "):rep(gap - lpad) .. " ")
        push("│", "GlanceTableBorder")
      end
      add(table.concat(buf), hls)
    end

    border("┌", "┬", "┐")
    for idx, cells in ipairs(rows) do
      map(srcs[idx])
      row(cells, idx == 1)
      if idx == 1 then
        map(start + 1)
        border("├", "┼", "┤")
      end
    end
    border("└", "┴", "┘")
    return i
  end

  local i = 1

  -- yaml front matter
  if src[1] == "---" then
    for j = 2, #src do
      if src[j] == "---" or src[j] == "..." then
        for k = 1, j do
          map(k)
          add(src[k], { { 0, #src[k], "GlanceFrontmatter" } })
        end
        i = j + 1
        break
      end
    end
  end

  while i <= #src do
    local line = src[i]
    local fence = fence_open(line)
    local aligns = line:find("|", 1, true) and table_aligns(src[i + 1])
    local next_line = src[i + 1] or ""

    if fence then
      map(i)
      local label = fence.lang ~= "" and (" " .. fence.lang) or ""
      add(label, { { 0, #label, "GlanceCodeLang" } }, "GlanceCodeBlock")
      local code, rows = {}, {}
      local j = i + 1
      while j <= #src and not fence_close(src[j], fence) do
        local l = src[j]
        local strip = math.min(fence.indent, #(l:match("^%s*")))
        l = l:sub(strip + 1)
        code[#code + 1] = l
        map(j)
        rows[#rows + 1] = add(" " .. l, nil, "GlanceCodeBlock")
        j = j + 1
      end
      for _, h in ipairs(code_highlights(code, fence.lang)) do
        R.hls[#R.hls + 1] = { rows[h[1] + 1], h[2] + 1, h[3] + 1, h[4], PRIO_CODE }
      end
      if j <= #src then
        map(j)
        add("", nil, "GlanceCodeBlock")
      end
      i = j + 1
    elseif aligns then
      i = add_table(i, aligns)
    elseif line:match("^%s*$") then
      map(i)
      add("")
      i = i + 1
    else
      local level, htext = heading(line)
      if level then
        map(i)
        add_heading(level, htext)
        i = i + 1
      elseif line:match("^%s*>") then
        map(i)
        local depth, rest = 0, line
        while true do
          local r = rest:match("^%s*>%s?(.*)$")
          if not r then
            break
          end
          depth, rest = depth + 1, r
        end
        local prefix = QUOTE_BAR:rep(depth)
        local hl_level, hl_text = heading(rest)
        local text, hls
        if hl_level then
          text, hls = inline(hl_text)
          table.insert(hls, 1, { 0, #text, "GlanceH" .. hl_level, PRIO_BLOCK })
        else
          text, hls = simple(rest)
        end
        shift(hls, #prefix)
        table.insert(hls, 1, { #prefix, #prefix + #text, "GlanceQuote", PRIO_BLOCK - 1 })
        table.insert(hls, 1, { 0, #prefix, "GlanceQuoteBar", PRIO_BLOCK })
        add(prefix .. text, hls)
        i = i + 1
      elseif is_hr(line) then
        map(i)
        local bar = ("─"):rep(width)
        add(bar, { { 0, #bar, "GlanceRule" } })
        i = i + 1
      elseif not line:match("^%s*[-*+]%s") and not line:match("^%s*%d+[.)]%s")
        and (next_line:match("^%s*=+%s*$") or next_line:match("^%s*%-+%s*$"))
      then
        map(i)
        add_heading(next_line:find("=", 1, true) and 1 or 2, trim(line), i + 1)
        i = i + 2
      else
        map(i)
        add(simple(line))
        i = i + 1
      end
    end
  end

  return R
end

return M
