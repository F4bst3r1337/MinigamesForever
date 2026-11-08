-- Minigames Forever: Bejeweled (Match-3)
-- Aufruf: /bj   (Farbmodus umschalten: /bj color)

local ADDON, MG = ...
local T = MG.T

local SIZE  = 8      -- 8x8 Brett
local TYPES = 7      -- Anzahl Edelstein-Arten
local CELL  = 40     -- Pixelgroesse einer Zelle
local GEM   = CELL - 6

local ICONS = {
  "Interface\\Icons\\INV_Misc_Gem_Ruby_01",
  "Interface\\Icons\\INV_Misc_Gem_Sapphire_01",
  "Interface\\Icons\\INV_Misc_Gem_Emerald_01",
  "Interface\\Icons\\INV_Misc_Gem_Amethyst_01",
  "Interface\\Icons\\INV_Misc_Gem_Topaz_01",
  "Interface\\Icons\\INV_Misc_Gem_Diamond_01",
  "Interface\\Icons\\INV_Misc_Gem_Opal_01",
}
local COLORS = {
  {1.0, 0.15, 0.15}, {0.2, 0.45, 1.0}, {0.15, 0.9, 0.25}, {0.7, 0.25, 0.95},
  {1.0, 0.6, 0.1},   {1.0, 1.0, 1.0},  {1.0, 0.9, 0.15},
}

MG.AddLocale("en", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Match three or more gems",
  be_no_moves = "No moves left - reshuffled!", be_combo = "Combo x%d!",
})
MG.AddLocale("de", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Drei oder mehr Steine verbinden",
  be_no_moves = "Keine Züge mehr - neu gemischt!", be_combo = "Combo x%d!",
})
MG.AddLocale("fr", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Alignez trois gemmes ou plus",
  be_no_moves = "Plus de coups - grille mélangée !", be_combo = "Combo x%d !",
})
MG.AddLocale("es", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Une tres o más gemas",
  be_no_moves = "¡Sin movimientos - tablero mezclado!", be_combo = "¡Combo x%d!",
})
MG.AddLocale("it", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Unisci tre o più gemme",
  be_no_moves = "Nessuna mossa - tavola rimescolata!", be_combo = "Combo x%d!",
})
MG.AddLocale("pt", {
  game_bejeweled = "Bejeweled", game_bejeweled_desc = "Combine três ou mais gemas",
  be_no_moves = "Sem jogadas - tabuleiro embaralhado!", be_combo = "Combo x%d!",
})

local grid = {}          -- grid[i] = Edelsteintyp (0 = leer)
local spr = {}           -- spr[i]  = Sprite (Textur), das in Zelle i steht
local buttons = {}
local selected = nil
local busy = false       -- true, solange Animationen laufen
local score, combo = 0, 0
local frame, board, fx, scoreText, bestText, infoText, newBtn

local function idx(r, c) return (r - 1) * SIZE + c end
local function rowOf(i) return math.floor((i - 1) / SIZE) + 1 end
local function colOf(i) return (i - 1) % SIZE + 1 end
local function cx(c) return (c - 0.5) * CELL end
local function cy(r) return -(r - 0.5) * CELL end

local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
local function lerp(a, b, t) return a + (b - a) * t end
local function easeOut(p) return 1 - (1 - p) * (1 - p) end
local function easeOutBack(p)
  local c1 = 1.3
  local q = p - 1
  return 1 + (c1 + 1) * q * q * q + c1 * q * q
end

local infoKey, infoArg
local function renderInfo()
  if not infoText then return end
  if infoKey then
    if infoArg then infoText:SetText(T(infoKey, infoArg)) else infoText:SetText(T(infoKey)) end
  else
    infoText:SetText("")
  end
end
local function setInfo(key, arg)
  infoKey, infoArg = key, arg
  renderInfo()
end

---------------------------------------------------------------- Logik

local function findMatches()
  local mark, count = {}, 0
  local function add(i)
    if not mark[i] then mark[i] = true; count = count + 1 end
  end
  for r = 1, SIZE do
    for c = 1, SIZE - 2 do
      local t = grid[idx(r, c)]
      if t ~= 0 and t == grid[idx(r, c + 1)] and t == grid[idx(r, c + 2)] then
        add(idx(r, c)); add(idx(r, c + 1)); add(idx(r, c + 2))
      end
    end
  end
  for c = 1, SIZE do
    for r = 1, SIZE - 2 do
      local t = grid[idx(r, c)]
      if t ~= 0 and t == grid[idx(r + 1, c)] and t == grid[idx(r + 2, c)] then
        add(idx(r, c)); add(idx(r + 1, c)); add(idx(r + 2, c))
      end
    end
  end
  return mark, count
end

local function swapData(a, b)
  grid[a], grid[b] = grid[b], grid[a]
  spr[a], spr[b] = spr[b], spr[a]
end

local function hasMoves()
  for r = 1, SIZE do
    for c = 1, SIZE do
      local a = idx(r, c)
      if c < SIZE then
        local b = idx(r, c + 1)
        grid[a], grid[b] = grid[b], grid[a]
        local _, n = findMatches()
        grid[a], grid[b] = grid[b], grid[a]
        if n > 0 then return true end
      end
      if r < SIZE then
        local b = idx(r + 1, c)
        grid[a], grid[b] = grid[b], grid[a]
        local _, n = findMatches()
        grid[a], grid[b] = grid[b], grid[a]
        if n > 0 then return true end
      end
    end
  end
  return false
end

local function randomGem() return math.random(1, TYPES) end

local function fillBoard()
  repeat
    for r = 1, SIZE do
      for c = 1, SIZE do
        local t
        repeat
          t = randomGem()
          local badH = c > 2 and grid[idx(r, c - 1)] == t and grid[idx(r, c - 2)] == t
          local badV = r > 2 and grid[idx(r - 1, c)] == t and grid[idx(r - 2, c)] == t
        until not badH and not badV
        grid[idx(r, c)] = t
      end
    end
  until hasMoves()
end

local function bestScore() return (MG.db and MG.db.bejeweled_best) or 0 end

local function saveBest()
  if score > bestScore() then MG.db.bejeweled_best = score end
end

local function updateTexts()
  if not scoreText then return end
  scoreText:SetText(T("score") .. ": " .. score)
  bestText:SetText(T("best") .. ": " .. bestScore())
end

---------------------------------------------------------------- Sprites

local pool = {}

local function skin(s, t)
  s.gemType = t
  if MG.UseColors() then
    s:SetTexture("Interface\\Buttons\\WHITE8X8")
    s:SetVertexColor(COLORS[t][1], COLORS[t][2], COLORS[t][3])
  else
    s:SetTexture(ICONS[t])
    s:SetVertexColor(1, 1, 1)
  end
end

local function getSprite(t)
  local s = table.remove(pool)
  if not s then s = board:CreateTexture(nil, "ARTWORK") end
  skin(s, t)
  s:Show()
  return s
end

local function releaseSprite(s)
  s:Hide()
  table.insert(pool, s)
end

local function place(s, x, y, scale, alpha)
  s:ClearAllPoints()
  s:SetPoint("CENTER", board, "TOPLEFT", x, y)
  s:SetWidth(GEM * scale)
  s:SetHeight(GEM * scale)
  s:SetAlpha(alpha or 1)
end

local function placeCell(i)
  if spr[i] then place(spr[i], cx(colOf(i)), cy(rowOf(i)), 1, 1) end
end

local function reskinAll()
  for i = 1, SIZE * SIZE do
    if spr[i] and grid[i] ~= 0 then skin(spr[i], grid[i]) end
  end
end

local function clearSprites()
  for i = 1, SIZE * SIZE do
    if spr[i] then releaseSprite(spr[i]); spr[i] = nil end
  end
end

---------------------------------------------------------------- Effekte (Funken, schwebende Punkte)

local particles, particlePool = {}, {}
local floaters, floaterPool = {}, {}

local function spawnParticles(x, y, t)
  if not MG.EffectsOn() then return end
  for k = 1, 4 do
    local tex = table.remove(particlePool)
    if not tex then
      tex = fx:CreateTexture(nil, "OVERLAY")
      tex:SetTexture("Interface\\Cooldown\\star4")
      tex:SetBlendMode("ADD")
    end
    local ang = math.random() * 6.2832
    local sp = 50 + math.random() * 70
    tex:SetVertexColor(COLORS[t][1], COLORS[t][2], COLORS[t][3])
    tex:Show()
    table.insert(particles, {
      tex = tex, x = x, y = y,
      vx = math.cos(ang) * sp, vy = math.sin(ang) * sp + 30,
      life = 0.4 + math.random() * 0.3, t = 0,
      size = 12 + math.random() * 8,
    })
  end
end

local function spawnFloater(x, y, text, comboLevel)
  if not MG.EffectsOn() then return end
  local fs = table.remove(floaterPool)
  if not fs then fs = fx:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") end
  fs:SetText(text)
  if comboLevel >= 3 then fs:SetTextColor(1, 0.4, 0.2)
  elseif comboLevel == 2 then fs:SetTextColor(1, 0.85, 0.2)
  else fs:SetTextColor(1, 1, 1) end
  fs:Show()
  table.insert(floaters, { fs = fs, x = x, y = y, t = 0, life = 0.85 })
end

local function updateEffects(dt)
  local i = 1
  while i <= #particles do
    local p = particles[i]
    p.t = p.t + dt
    if p.t >= p.life then
      p.tex:Hide()
      table.insert(particlePool, p.tex)
      table.remove(particles, i)
    else
      local k = p.t / p.life
      p.x = p.x + p.vx * dt
      p.y = p.y + p.vy * dt
      p.vy = p.vy - 160 * dt
      p.tex:ClearAllPoints()
      p.tex:SetPoint("CENTER", board, "TOPLEFT", p.x, p.y)
      local sz = p.size * (1 - 0.6 * k)
      p.tex:SetWidth(sz)
      p.tex:SetHeight(sz)
      p.tex:SetAlpha(1 - k)
      i = i + 1
    end
  end
  i = 1
  while i <= #floaters do
    local f = floaters[i]
    f.t = f.t + dt
    if f.t >= f.life then
      f.fs:Hide()
      table.insert(floaterPool, f.fs)
      table.remove(floaters, i)
    else
      local k = f.t / f.life
      f.fs:ClearAllPoints()
      f.fs:SetPoint("CENTER", board, "TOPLEFT", f.x, f.y + 36 * easeOut(k))
      f.fs:SetAlpha(k < 0.6 and 1 or (1 - (k - 0.6) / 0.4))
      i = i + 1
    end
  end
end

---------------------------------------------------------------- Animations-Motor

local anim = nil -- { t, dur, fn(p), done }

local function startAnim(dur, fn, done)
  anim = { t = 0, dur = dur * MG.Speed(), fn = fn, done = done }
  fn(0)
end

local function stepAnim(dt)
  if not anim then return end
  anim.t = anim.t + dt
  local p = clamp(anim.t / anim.dur, 0, 1)
  anim.fn(p)
  if p >= 1 then
    local d = anim.done
    anim = nil
    if d then d() end
  end
end

-- items: { s=Sprite, x=Pixel-x, y1=Start-y, y2=Ziel-y, delay=, dur= }
local function runDrops(items, onDone)
  local total = 0
  for _, it in ipairs(items) do
    if it.delay + it.dur > total then total = it.delay + it.dur end
  end
  if total <= 0 then total = 0.01 end
  startAnim(total, function(p)
    local t = p * total
    for _, it in ipairs(items) do
      local lp = clamp((t - it.delay) / it.dur, 0, 1)
      place(it.s, it.x, lerp(it.y1, it.y2, easeOutBack(lp)), 1, 1)
    end
  end, function()
    for _, it in ipairs(items) do place(it.s, it.x, it.y2, 1, 1) end
    if onDone then onDone() end
  end)
end

---------------------------------------------------------------- Spielablauf

local resolve -- Vorwaertsdeklaration

local function updateSelection()
  for i = 1, SIZE * SIZE do
    if selected == i then buttons[i].sel:Show() else buttons[i].sel:Hide() end
  end
end

local function setSelected(i)
  if selected and spr[selected] then placeCell(selected) end
  selected = i
  updateSelection()
end

local function buildBoard(onDone)
  clearSprites()
  fillBoard()
  local items = {}
  for r = 1, SIZE do
    for c = 1, SIZE do
      local i = idx(r, c)
      local s = getSprite(grid[i])
      spr[i] = s
      table.insert(items, {
        s = s, x = cx(c),
        y1 = cy(r) + SIZE * CELL + 20, y2 = cy(r),
        delay = (SIZE - r) * 0.045 + (c - 1) * 0.012, dur = 0.38,
      })
    end
  end
  runDrops(items, onDone)
end

local function fall()
  local items = {}
  for c = 1, SIZE do
    local write = SIZE
    for r = SIZE, 1, -1 do
      local i = idx(r, c)
      if grid[i] ~= 0 then
        if write ~= r then
          local j = idx(write, c)
          grid[j], spr[j] = grid[i], spr[i]
          grid[i], spr[i] = 0, nil
          local dist = write - r
          table.insert(items, { s = spr[j], x = cx(c), y1 = cy(r), y2 = cy(write), delay = 0, dur = 0.14 + 0.05 * dist })
        end
        write = write - 1
      end
    end
    for r = write, 1, -1 do
      local i = idx(r, c)
      local t = randomGem()
      grid[i] = t
      local s = getSprite(t)
      spr[i] = s
      table.insert(items, { s = s, x = cx(c), y1 = cy(r - write), y2 = cy(r), delay = 0, dur = 0.14 + 0.05 * write })
    end
  end
  runDrops(items, function() resolve() end)
end

local function reshuffle()
  setInfo("be_no_moves")
  local list = {}
  for i = 1, SIZE * SIZE do
    if spr[i] then table.insert(list, spr[i]) end
  end
  startAnim(0.25, function(p)
    for _, s in ipairs(list) do
      local sc = 1 - p
      local x, y = select(4, s:GetPoint())
      place(s, x, y, sc < 0.01 and 0.01 or sc, 1 - p)
    end
  end, function()
    buildBoard(function() busy = false end)
  end)
end

resolve = function()
  local mark, count = findMatches()
  if count == 0 then
    combo = 0
    if not hasMoves() then
      reshuffle()
    else
      setInfo(nil)
      busy = false
    end
    return
  end

  combo = combo + 1
  local pts = count * 10 * combo
  score = score + pts
  saveBest()
  updateTexts()
  if combo > 1 then setInfo("be_combo", combo) else setInfo(nil) end

  local cleared = {}
  local sx, sy = 0, 0
  for i in pairs(mark) do
    table.insert(cleared, i)
    local x, y = cx(colOf(i)), cy(rowOf(i))
    sx, sy = sx + x, sy + y
    spawnParticles(x, y, grid[i])
  end
  spawnFloater(sx / count, sy / count, "+" .. pts, combo)

  startAnim(0.26, function(p)
    for _, i in ipairs(cleared) do
      local s = spr[i]
      if s then
        local sc, a
        if p < 0.3 then
          sc = 1 + 0.35 * (p / 0.3); a = 1
        else
          local k = (p - 0.3) / 0.7
          sc = 1.35 * (1 - k); a = 1 - k
          if sc < 0.01 then sc = 0.01 end
        end
        place(s, cx(colOf(i)), cy(rowOf(i)), sc, a)
      end
    end
  end, function()
    for _, i in ipairs(cleared) do
      if spr[i] then releaseSprite(spr[i]); spr[i] = nil end
      grid[i] = 0
    end
    fall()
  end)
end

local function adjacent(a, b)
  return math.abs(rowOf(a) - rowOf(b)) + math.abs(colOf(a) - colOf(b)) == 1
end

local function trySwap(a, b)
  busy = true
  setSelected(nil)
  local sa, sb = spr[a], spr[b]
  local xa, ya = cx(colOf(a)), cy(rowOf(a))
  local xb, yb = cx(colOf(b)), cy(rowOf(b))
  swapData(a, b)
  startAnim(0.17, function(p)
    local e = easeOut(p)
    place(sa, lerp(xa, xb, e), lerp(ya, yb, e), 1, 1)
    place(sb, lerp(xb, xa, e), lerp(yb, ya, e), 1, 1)
  end, function()
    local _, n = findMatches()
    if n > 0 then
      combo = 0
      resolve()
    else
      swapData(a, b) -- ungueltiger Zug: zurueck tauschen
      startAnim(0.17, function(p)
        local e = easeOut(p)
        place(sa, lerp(xb, xa, e), lerp(yb, ya, e), 1, 1)
        place(sb, lerp(xa, xb, e), lerp(ya, yb, e), 1, 1)
      end, function() busy = false end)
    end
  end)
end

local function onCellClick(i)
  if busy then return end
  if not selected then
    setSelected(i)
  elseif selected == i then
    setSelected(nil)
  elseif adjacent(selected, i) then
    trySwap(selected, i)
  else
    setSelected(i)
  end
end

local function newGame()
  saveBest()
  anim = nil
  setSelected(nil)
  score, combo = 0, 0
  busy = true
  setInfo(nil)
  updateTexts()
  buildBoard(function() busy = false end)
end

---------------------------------------------------------------- Fenster

local pulseT = 0

local function onUpdate(self, elapsed)
  if elapsed > 0.1 then elapsed = 0.1 end
  updateEffects(elapsed)
  stepAnim(elapsed)
  if selected and not busy and spr[selected] then
    pulseT = pulseT + elapsed
    local sc = 1.06 + 0.07 * math.sin(pulseT * 8)
    place(spr[selected], cx(colOf(selected)), cy(rowOf(selected)), sc, 1)
  end
end

local function applyTexts()
  if not frame then return end
  frame.title:SetText(T("game_bejeweled"))
  newBtn:SetText(T("new_game"))
  updateTexts()
  renderInfo()
end

local function buildUI()
  frame = MG.NewPage("bejeweled", SIZE * CELL + 40, SIZE * CELL + 110)

  scoreText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  scoreText:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -42)
  bestText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bestText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -42)

  board = CreateFrame("Frame", nil, frame)
  board:SetWidth(SIZE * CELL)
  board:SetHeight(SIZE * CELL)
  board:SetPoint("TOP", frame, "TOP", 0, -62)
  if board.SetClipsChildren then board:SetClipsChildren(true) end

  for r = 1, SIZE do
    for c = 1, SIZE do
      local bg = board:CreateTexture(nil, "BACKGROUND")
      bg:SetPoint("TOPLEFT", board, "TOPLEFT", (c - 1) * CELL, -(r - 1) * CELL)
      bg:SetWidth(CELL)
      bg:SetHeight(CELL)
      bg:SetTexture("Interface\\Buttons\\WHITE8X8")
      if (r + c) % 2 == 0 then bg:SetVertexColor(0, 0, 0, 0.55) else bg:SetVertexColor(0.1, 0.1, 0.15, 0.55) end
    end
  end

  for r = 1, SIZE do
    for c = 1, SIZE do
      local i = idx(r, c)
      local b = CreateFrame("Button", nil, board)
      b:SetWidth(CELL)
      b:SetHeight(CELL)
      b:SetPoint("TOPLEFT", board, "TOPLEFT", (c - 1) * CELL, -(r - 1) * CELL)
      b.sel = b:CreateTexture(nil, "OVERLAY")
      b.sel:SetAllPoints()
      b.sel:SetTexture("Interface\\Buttons\\CheckButtonHilight")
      b.sel:SetBlendMode("ADD")
      b.sel:Hide()
      b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
      b:SetScript("OnClick", function() onCellClick(i) end)
      buttons[i] = b
    end
  end

  fx = CreateFrame("Frame", nil, board)
  fx:SetAllPoints(board)
  fx:SetFrameLevel(board:GetFrameLevel() + 10)

  infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  infoText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 22, 22)

  newBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  newBtn:SetWidth(120)
  newBtn:SetHeight(24)
  newBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 18)
  newBtn:SetScript("OnClick", newGame)

  frame:SetScript("OnUpdate", onUpdate)
end

MG.RegisterGame({
  id = "bejeweled",
  nameKey = "game_bejeweled",
  descKey = "game_bejeweled_desc",
  icon = "Interface\\Icons\\INV_Misc_Gem_Ruby_01",
  init = function()
    buildUI()
    applyTexts()
    newGame()
  end,
})

MG.OnChange(function()
  if frame then
    reskinAll()
    applyTexts()
  end
end)

MG.Slash("bejeweled", { "/bj", "/bejeweled" }, function(msg)
  msg = string.lower(msg or "")
  if (msg == "color" or msg == "farbe") and MG.db then
    MG.db.colors = not MG.UseColors()
    MG.Changed()
    return
  end
  MG.Open("bejeweled")
end)
