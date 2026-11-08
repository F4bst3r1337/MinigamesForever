-- Minigames Forever: 2048
-- Aufruf: /2048
-- Steuerung: Pfeiltasten, WASD oder mit der Maus ueber das Brett wischen. Der Spielstand wird gespeichert.

local ADDON, MG = ...
local T = MG.T

local N = 4
local CELL, GAP = 76, 8
local BOARD = N * CELL + (N + 1) * GAP
local WHITE = "Interface\\Buttons\\WHITE8X8"

MG.AddLocale("en", {
  game_2048 = "2048", game_2048_desc = "Merge tiles to reach 2048",
  g2048_over = "Game over!", g2048_win = "You made 2048!", g2048_keep = "Keep going",
  g2048_hint = "Arrow keys, WASD or swipe",
})
MG.AddLocale("de", {
  game_2048 = "2048", game_2048_desc = "Kacheln verschmelzen bis 2048",
  g2048_over = "Game Over!", g2048_win = "2048 erreicht!", g2048_keep = "Weiterspielen",
  g2048_hint = "Pfeiltasten, WASD oder Wischen",
})
MG.AddLocale("fr", {
  game_2048 = "2048", game_2048_desc = "Fusionnez les tuiles jusqu'à 2048",
  g2048_over = "Partie terminée !", g2048_win = "Vous avez atteint 2048 !", g2048_keep = "Continuer",
  g2048_hint = "Flèches, WASD ou glisser",
})
MG.AddLocale("es", {
  game_2048 = "2048", game_2048_desc = "Une fichas hasta llegar a 2048",
  g2048_over = "¡Fin de la partida!", g2048_win = "¡Has llegado a 2048!", g2048_keep = "Seguir jugando",
  g2048_hint = "Flechas, WASD o deslizar",
})
MG.AddLocale("it", {
  game_2048 = "2048", game_2048_desc = "Unisci le tessere fino a 2048",
  g2048_over = "Partita finita!", g2048_win = "Hai raggiunto 2048!", g2048_keep = "Continua",
  g2048_hint = "Frecce, WASD o scorri",
})
MG.AddLocale("pt", {
  game_2048 = "2048", game_2048_desc = "Junte peças até chegar a 2048",
  g2048_over = "Fim de jogo!", g2048_win = "Você chegou a 2048!", g2048_keep = "Continuar",
  g2048_hint = "Setas, WASD ou deslizar",
})

-- Kachelfarben (angelehnt an das Original)
local COLORS = {
  [2]    = { 0.93, 0.89, 0.85 }, [4]    = { 0.93, 0.88, 0.78 },
  [8]    = { 0.95, 0.69, 0.47 }, [16]   = { 0.96, 0.58, 0.39 },
  [32]   = { 0.96, 0.49, 0.37 }, [64]   = { 0.96, 0.37, 0.23 },
  [128]  = { 0.93, 0.81, 0.45 }, [256]  = { 0.93, 0.80, 0.38 },
  [512]  = { 0.93, 0.78, 0.31 }, [1024] = { 0.93, 0.77, 0.25 },
  [2048] = { 0.93, 0.76, 0.18 },
}
local BIG_COLOR = { 0.24, 0.23, 0.2 }

---------------------------------------------------------------- Zustand

local tiles = {}          -- tiles[(r-1)*N + c] = Kachel { f=Frame, v=Wert }
local pool = {}
local score, won = 0, false
local busy = false
local page, board, overlay, ui = nil, nil, nil, {}

local function idx(r, c) return (r - 1) * N + c end
local function cellX(c) return GAP + (c - 1) * (CELL + GAP) + CELL / 2 end
local function cellY(r) return -(GAP + (r - 1) * (CELL + GAP) + CELL / 2) end
local function lerp(a, b, t) return a + (b - a) * t end
local function easeOut(p) return 1 - (1 - p) * (1 - p) end

local function bestScore() return (MG.db and MG.db.g2048_best) or 0 end

local function updateTexts()
  if not ui.scoreText then return end
  ui.scoreText:SetText(T("score") .. ": " .. score)
  ui.bestText:SetText(T("best") .. ": " .. bestScore())
end

local function saveBest()
  if MG.db and score > bestScore() then MG.db.g2048_best = score end
end

local function saveState()
  if not MG.db then return end
  local cells = {}
  for i = 1, N * N do cells[i] = tiles[i] and tiles[i].v or 0 end
  MG.db.g2048_state = { cells = cells, score = score, won = won }
end

---------------------------------------------------------------- Animations-Motor

local tweens = {}
local function addTween(dur, fn, done)
  local t = { t = 0, dur = dur * MG.Speed(), fn = fn, done = done }
  table.insert(tweens, t)
  fn(0)
  return t
end

local function updateTweens(dt)
  local i = 1
  while i <= #tweens do
    local tw = tweens[i]
    tw.t = tw.t + dt
    local p = tw.t / tw.dur
    if p > 1 then p = 1 end
    tw.fn(p)
    if p >= 1 then
      table.remove(tweens, i)
      if tw.done then tw.done() end
    else
      i = i + 1
    end
  end
end

---------------------------------------------------------------- Kacheln

local function safeFont(fs, path, size, flags, fallback)
  local ok = fs:SetFont(path, size, flags)
  if not ok then fs:SetFontObject(fallback or "GameFontNormalLarge") end
end

local function makeTile()
  local f = CreateFrame("Frame", nil, board)
  f:SetWidth(CELL)
  f:SetHeight(CELL)
  f.bg = f:CreateTexture(nil, "BACKGROUND", nil, 0)
  f.bg:SetAllPoints()
  f.bg:SetTexture(WHITE)
  f.shine = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  f.shine:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  f.shine:SetPoint("BOTTOMRIGHT", f, "RIGHT", 0, 0)
  f.shine:SetTexture(WHITE)
  f.shine:SetVertexColor(1, 1, 1, 0.12)
  f.shade = f:CreateTexture(nil, "BACKGROUND", nil, 1)
  f.shade:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  f.shade:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, 4)
  f.shade:SetTexture(WHITE)
  f.shade:SetVertexColor(0, 0, 0, 0.14)
  f.text = f:CreateFontString(nil, "OVERLAY")
  safeFont(f.text, "Fonts\\FRIZQT__.TTF", 30, "OUTLINE", "GameFontNormalLarge")
  f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
  return f
end

local function skin(t)
  local v = t.v
  local c = COLORS[v] or BIG_COLOR
  t.f.bg:SetVertexColor(c[1], c[2], c[3], 1)
  local size = 32
  if v >= 100000 then size = 15 elseif v >= 10000 then size = 18
  elseif v >= 1000 then size = 22 elseif v >= 100 then size = 26 end
  safeFont(t.f.text, "Fonts\\FRIZQT__.TTF", size, "OUTLINE", "GameFontNormalLarge")
  t.f.text:SetText(v)
  if v <= 4 then t.f.text:SetTextColor(0.42, 0.38, 0.34) else t.f.text:SetTextColor(1, 1, 1) end
end

local function newTile(v)
  local t = { v = v }
  t.f = table.remove(pool) or makeTile()
  t.f:Show()
  skin(t)
  return t
end

local function releaseTile(t)
  t.f:Hide()
  t.f:SetScale(1)
  table.insert(pool, t.f)
end

-- Position/Skalierung (Skalierung ueber SetScale, Versatz wird kompensiert)
local function place(t, x, y, s)
  s = s or 1
  if s < 0.01 then s = 0.01 end
  local f = t.f
  f:SetScale(s)
  f:ClearAllPoints()
  f:SetPoint("CENTER", board, "TOPLEFT", x / s, y / s)
end

local function placeCell(t, r, c, s) place(t, cellX(c), cellY(r), s) end

local function emptyCells()
  local list = {}
  for r = 1, N do
    for c = 1, N do
      if not tiles[idx(r, c)] then table.insert(list, { r, c }) end
    end
  end
  return list
end

local function spawnTile()
  local e = emptyCells()
  if #e == 0 then return end
  local cell = e[math.random(1, #e)]
  local t = newTile(math.random() < 0.9 and 2 or 4)
  tiles[idx(cell[1], cell[2])] = t
  addTween(0.16, function(p) placeCell(t, cell[1], cell[2], 0.3 + 0.7 * easeOut(p)) end)
end

local function pop(t, r, c, big)
  local peak = big and 1.35 or 1.2
  addTween(0.18, function(p)
    local s
    if p < 0.5 then s = lerp(1, peak, p * 2) else s = lerp(peak, 1, (p - 0.5) * 2) end
    placeCell(t, r, c, s)
  end)
end

local function canMove()
  if #emptyCells() > 0 then return true end
  for r = 1, N do
    for c = 1, N do
      local v = tiles[idx(r, c)].v
      if c < N and tiles[idx(r, c + 1)].v == v then return true end
      if r < N and tiles[idx(r + 1, c)].v == v then return true end
    end
  end
  return false
end

---------------------------------------------------------------- Overlay (Game over / Gewonnen)

local function showOverlay(kind)
  overlay.kind = kind
  if kind == "win" then
    overlay.text:SetText(T("g2048_win"))
    overlay.text:SetTextColor(1, 0.85, 0.2)
    overlay.keep:SetText(T("g2048_keep"))
    overlay.keep:Show()
  else
    overlay.text:SetText(T("g2048_over"))
    overlay.text:SetTextColor(1, 0.4, 0.35)
    overlay.keep:Hide()
  end
  overlay.newBtn:SetText(T("new_game"))
  overlay:Show()
end

local function refreshOverlayTexts()
  if overlay and overlay:IsShown() then showOverlay(overlay.kind) end
end

---------------------------------------------------------------- Spielzug

local function lineCells(dir, i)
  local list = {}
  if dir == "L" then for c = 1, N do list[#list + 1] = { i, c } end
  elseif dir == "R" then for c = N, 1, -1 do list[#list + 1] = { i, c } end
  elseif dir == "U" then for r = 1, N do list[#list + 1] = { r, i } end
  else for r = N, 1, -1 do list[#list + 1] = { r, i } end end
  return list
end

local function doMove(dir)
  if busy or (overlay and overlay:IsShown()) then return end
  local newTiles = {}
  local moving, merges = {}, {}
  local anyMoved, gained = false, 0

  for i = 1, N do
    local list = lineCells(dir, i)
    local k = 0
    local last = nil
    for _, cell in ipairs(list) do
      local r, c = cell[1], cell[2]
      local t = tiles[idx(r, c)]
      if t then
        if last and last.v == t.v and not last.merged then
          local d = list[k]
          last.merged = true
          table.insert(merges, { keep = last, gone = t, r = d[1], c = d[2] })
          table.insert(moving, { t = t, r1 = r, c1 = c, r2 = d[1], c2 = d[2] })
          gained = gained + last.v * 2
          anyMoved = true
        else
          k = k + 1
          local d = list[k]
          newTiles[idx(d[1], d[2])] = t
          if d[1] ~= r or d[2] ~= c then
            table.insert(moving, { t = t, r1 = r, c1 = c, r2 = d[1], c2 = d[2] })
            anyMoved = true
          end
          last = t
        end
      end
    end
  end

  if not anyMoved then return end
  busy = true

  addTween(0.13, function(p)
    local e = easeOut(p)
    for _, m in ipairs(moving) do
      place(m.t, lerp(cellX(m.c1), cellX(m.c2), e), lerp(cellY(m.r1), cellY(m.r2), e), 1)
    end
  end, function()
    tiles = newTiles
    local reached = false
    for _, m in ipairs(merges) do
      releaseTile(m.gone)
      m.keep.merged = nil
      m.keep.v = m.keep.v * 2
      skin(m.keep)
      pop(m.keep, m.r, m.c, m.keep.v >= 128)
      if m.keep.v == 2048 and not won then reached = true end
    end
    score = score + gained
    saveBest()
    updateTexts()
    spawnTile()
    busy = false

    if reached then
      won = true
      saveState()
      showOverlay("win")
    elseif not canMove() then
      if MG.db then MG.db.g2048_state = nil end
      showOverlay("over")
    else
      saveState()
    end
  end)
end

local function newGame()
  for i = 1, N * N do
    if tiles[i] then releaseTile(tiles[i]) end
  end
  tiles = {}
  tweens = {}
  score, won, busy = 0, false, false
  overlay:Hide()
  updateTexts()
  spawnTile()
  spawnTile()
  saveState()
end

local function restoreOrNew()
  local st = MG.db and MG.db.g2048_state
  if st and st.cells and #st.cells == N * N then
    local any = false
    for i = 1, N * N do
      local v = st.cells[i]
      if v and v > 0 then
        local t = newTile(v)
        tiles[i] = t
        placeCell(t, math.floor((i - 1) / N) + 1, (i - 1) % N + 1, 1)
        any = true
      end
    end
    if any then
      score, won = st.score or 0, st.won and true or false
      overlay:Hide()
      updateTexts()
      return
    end
  end
  newGame()
end

---------------------------------------------------------------- Fenster

local KEYS = { UP = "U", DOWN = "D", LEFT = "L", RIGHT = "R", W = "U", S = "D", A = "L", D = "R" }

local function applyTexts()
  if not page then return end
  page.title:SetText(T("game_2048"))
  ui.newBtn:SetText(T("new_game"))
  ui.hint:SetText(T("g2048_hint"))
  updateTexts()
  refreshOverlayTexts()
end

local function arrowBtn(label, x, dir)
  local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  b:SetWidth(30)
  b:SetHeight(24)
  b:SetPoint("TOPLEFT", page, "TOPLEFT", x, -420)
  b:SetText(label)
  b:SetScript("OnClick", function() doMove(dir) end)
  return b
end

local function buildUI()
  page = MG.NewPage("2048", 400, 470)

  ui.scoreText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ui.scoreText:SetPoint("TOPLEFT", page, "TOPLEFT", 28, -42)
  ui.bestText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ui.bestText:SetPoint("TOPRIGHT", page, "TOPRIGHT", -28, -42)

  board = CreateFrame("Frame", nil, page)
  board:SetWidth(BOARD)
  board:SetHeight(BOARD)
  board:SetPoint("TOP", page, "TOP", 0, -62)
  board:EnableMouse(true)

  local bg = board:CreateTexture(nil, "BACKGROUND", nil, -2)
  bg:SetAllPoints()
  bg:SetTexture(WHITE)
  bg:SetVertexColor(0.43, 0.4, 0.36, 1)
  for r = 1, N do
    for c = 1, N do
      local cell = board:CreateTexture(nil, "BACKGROUND", nil, -1)
      cell:SetWidth(CELL)
      cell:SetHeight(CELL)
      cell:SetPoint("CENTER", board, "TOPLEFT", cellX(c), cellY(r))
      cell:SetTexture(WHITE)
      cell:SetVertexColor(0.8, 0.75, 0.7, 0.35)
    end
  end

  -- Wischen mit der Maus
  local sx, sy
  board:SetScript("OnMouseDown", function() sx, sy = GetCursorPosition() end)
  board:SetScript("OnMouseUp", function(self)
    if not sx then return end
    local ex, ey = GetCursorPosition()
    local dx, dy = ex - sx, ey - sy
    sx, sy = nil, nil
    local minDist = 25 * self:GetEffectiveScale()
    if math.abs(dx) < minDist and math.abs(dy) < minDist then return end
    if math.abs(dx) > math.abs(dy) then
      doMove(dx > 0 and "R" or "L")
    else
      doMove(dy > 0 and "U" or "D")
    end
  end)

  -- Overlay
  overlay = CreateFrame("Frame", nil, board)
  overlay:SetAllPoints(board)
  overlay:SetFrameLevel(board:GetFrameLevel() + 30)
  overlay:EnableMouse(true)
  local shade = overlay:CreateTexture(nil, "BACKGROUND")
  shade:SetAllPoints()
  shade:SetTexture(WHITE)
  shade:SetVertexColor(0.07, 0.06, 0.05, 0.78)
  overlay.text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  overlay.text:SetPoint("CENTER", overlay, "CENTER", 0, 30)
  overlay.newBtn = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
  overlay.newBtn:SetWidth(140)
  overlay.newBtn:SetHeight(26)
  overlay.newBtn:SetPoint("CENTER", overlay, "CENTER", 0, -14)
  overlay.newBtn:SetScript("OnClick", function() newGame() end)
  overlay.keep = CreateFrame("Button", nil, overlay, "UIPanelButtonTemplate")
  overlay.keep:SetWidth(140)
  overlay.keep:SetHeight(26)
  overlay.keep:SetPoint("CENTER", overlay, "CENTER", 0, -46)
  overlay.keep:SetScript("OnClick", function() overlay:Hide() end)
  overlay:Hide()

  -- Steuerung unten
  arrowBtn("<", 126, "L")
  arrowBtn("^", 160, "U")
  arrowBtn("v", 194, "D")
  arrowBtn(">", 228, "R")

  ui.newBtn = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
  ui.newBtn:SetWidth(110)
  ui.newBtn:SetHeight(24)
  ui.newBtn:SetPoint("TOPRIGHT", page, "TOPRIGHT", -28, -420)
  ui.newBtn:SetScript("OnClick", function() newGame() end)

  ui.hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ui.hint:SetPoint("TOPLEFT", page, "TOPLEFT", 28, -450)

  -- Tastatur (nur solange die Seite sichtbar ist); nicht benutzte Tasten gehen weiter ans Spiel
  page:EnableKeyboard(true)
  page:SetScript("OnKeyDown", function(self, key)
    local dir = KEYS[key]
    if dir then
      if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end
      doMove(dir)
    else
      if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
    end
  end)

  page:SetScript("OnUpdate", function(self, elapsed)
    if elapsed > 0.1 then elapsed = 0.1 end
    updateTweens(elapsed)
  end)
end

MG.RegisterGame({
  id = "2048",
  nameKey = "game_2048",
  descKey = "game_2048_desc",
  icon = "Interface\\AddOns\\MinigamesForever\\Media\\2048",
  init = function()
    buildUI()
    restoreOrNew()
    applyTexts()
  end,
})

MG.OnChange(applyTexts)

MG.Slash("2048", { "/2048" })
