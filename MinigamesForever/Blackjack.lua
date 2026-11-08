-- Minigames Forever: Blackjack
-- Aufruf: /bjk  (oder /blackjack, /21)
-- Regeln: 4 Decks, Blackjack zahlt 3:2, Geber bleibt bei 17, Verdoppeln auf die ersten zwei Karten.
-- Gespielt wird mit Spiel-Chips (kein echtes Gold). Splitten ist (noch) nicht eingebaut.

local ADDON, MG = ...
local T = MG.T

local CW, CH = 68, 96            -- Kartengroesse
local FELT_W, FELT_H = 500, 270  -- Spieltisch
local DECK_X, DECK_Y = 455, -62  -- Kartenstapel (hier erscheinen neue Karten)
local DEALER_Y, PLAYER_Y = -74, -212
local COIN_X, COIN_Y = 460, -250 -- Muenzstapel (Einsatz)
local START_CHIPS = 1000
local WHITE = "Interface\\Buttons\\WHITE8X8"

local SUITS = { "H", "D", "C", "S" }
local MEDIA = "Interface\\AddOns\\MinigamesForever\\Media\\"
local SUIT_TEX = {
  H = MEDIA .. "heart",
  D = MEDIA .. "diamond",
  C = MEDIA .. "club",
  S = MEDIA .. "spade",
}
local SUIT_RED = { H = true, D = true }
local RANKS = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K" }

-- Position der Symbole auf Zahlenkarten: { Spalte (-1,0,1), Zeile (0 oben .. 1 unten) }
local PIPS = {
  [2]  = { {0,0}, {0,1} },
  [3]  = { {0,0}, {0,.5}, {0,1} },
  [4]  = { {-1,0}, {1,0}, {-1,1}, {1,1} },
  [5]  = { {-1,0}, {1,0}, {0,.5}, {-1,1}, {1,1} },
  [6]  = { {-1,0}, {1,0}, {-1,.5}, {1,.5}, {-1,1}, {1,1} },
  [7]  = { {-1,0}, {1,0}, {0,.25}, {-1,.5}, {1,.5}, {-1,1}, {1,1} },
  [8]  = { {-1,0}, {1,0}, {0,.25}, {-1,.5}, {1,.5}, {0,.75}, {-1,1}, {1,1} },
  [9]  = { {-1,0}, {1,0}, {-1,1/3}, {1,1/3}, {0,.5}, {-1,2/3}, {1,2/3}, {-1,1}, {1,1} },
  [10] = { {-1,0}, {1,0}, {0,1/6}, {-1,1/3}, {1,1/3}, {-1,2/3}, {1,2/3}, {0,5/6}, {-1,1}, {1,1} },
}

MG.AddLocale("en", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Beat the dealer to 21",
  bj_chips = "Chips", bj_bet = "Bet", bj_deal = "Deal", bj_hit = "Hit", bj_stand = "Stand",
  bj_double = "Double", bj_clear = "Clear", bj_dealer = "Dealer", bj_player = "Player",
  bj_win = "You win! +%d", bj_lose = "You lose -%d", bj_push = "Push - bet returned",
  bj_blackjack = "Blackjack! +%d", bj_bust = "Bust! -%d", bj_dealer_bust = "Dealer busts! +%d",
  bj_broke = "Out of chips!", bj_restart = "Restart", bj_reshuffle = "New shoe shuffled",
  bj_rules = "Blackjack pays 3:2 - Dealer stands on 17",
})
MG.AddLocale("de", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Schlage den Geber auf 21",
  bj_chips = "Chips", bj_bet = "Einsatz", bj_deal = "Geben", bj_hit = "Karte", bj_stand = "Halten",
  bj_double = "Verdoppeln", bj_clear = "Löschen", bj_dealer = "Geber", bj_player = "Spieler",
  bj_win = "Gewonnen! +%d", bj_lose = "Verloren -%d", bj_push = "Unentschieden - Einsatz zurück",
  bj_blackjack = "Blackjack! +%d", bj_bust = "Überkauft! -%d", bj_dealer_bust = "Geber überkauft! +%d",
  bj_broke = "Keine Chips mehr!", bj_restart = "Neustart", bj_reshuffle = "Neuer Kartenstapel gemischt",
  bj_rules = "Blackjack zahlt 3:2 - Geber bleibt bei 17",
})
MG.AddLocale("fr", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Battez le croupier à 21",
  bj_chips = "Jetons", bj_bet = "Mise", bj_deal = "Distribuer", bj_hit = "Tirer", bj_stand = "Rester",
  bj_double = "Doubler", bj_clear = "Effacer", bj_dealer = "Croupier", bj_player = "Joueur",
  bj_win = "Gagné ! +%d", bj_lose = "Perdu -%d", bj_push = "Égalité - mise rendue",
  bj_blackjack = "Blackjack ! +%d", bj_bust = "Dépassé ! -%d", bj_dealer_bust = "Le croupier dépasse ! +%d",
  bj_broke = "Plus de jetons !", bj_restart = "Recommencer", bj_reshuffle = "Nouveau sabot mélangé",
  bj_rules = "Blackjack paie 3:2 - le croupier reste à 17",
})
MG.AddLocale("es", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Gana al crupier a 21",
  bj_chips = "Fichas", bj_bet = "Apuesta", bj_deal = "Repartir", bj_hit = "Pedir", bj_stand = "Plantarse",
  bj_double = "Doblar", bj_clear = "Borrar", bj_dealer = "Crupier", bj_player = "Jugador",
  bj_win = "¡Ganas! +%d", bj_lose = "Pierdes -%d", bj_push = "Empate - apuesta devuelta",
  bj_blackjack = "¡Blackjack! +%d", bj_bust = "¡Te pasas! -%d", bj_dealer_bust = "¡El crupier se pasa! +%d",
  bj_broke = "¡Sin fichas!", bj_restart = "Reiniciar", bj_reshuffle = "Nuevo mazo barajado",
  bj_rules = "Blackjack paga 3:2 - el crupier se planta en 17",
})
MG.AddLocale("it", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Batti il banco a 21",
  bj_chips = "Fiches", bj_bet = "Puntata", bj_deal = "Distribuisci", bj_hit = "Carta", bj_stand = "Stai",
  bj_double = "Raddoppia", bj_clear = "Azzera", bj_dealer = "Banco", bj_player = "Giocatore",
  bj_win = "Hai vinto! +%d", bj_lose = "Hai perso -%d", bj_push = "Pareggio - puntata restituita",
  bj_blackjack = "Blackjack! +%d", bj_bust = "Sballato! -%d", bj_dealer_bust = "Il banco sballa! +%d",
  bj_broke = "Fiches esaurite!", bj_restart = "Ricomincia", bj_reshuffle = "Nuovo mazzo mescolato",
  bj_rules = "Il Blackjack paga 3:2 - il banco sta su 17",
})
MG.AddLocale("pt", {
  game_blackjack = "Blackjack", game_blackjack_desc = "Vença a banca no 21",
  bj_chips = "Fichas", bj_bet = "Aposta", bj_deal = "Dar", bj_hit = "Pedir", bj_stand = "Parar",
  bj_double = "Dobrar", bj_clear = "Limpar", bj_dealer = "Banca", bj_player = "Jogador",
  bj_win = "Você ganhou! +%d", bj_lose = "Você perdeu -%d", bj_push = "Empate - aposta devolvida",
  bj_blackjack = "Blackjack! +%d", bj_bust = "Estourou! -%d", bj_dealer_bust = "A banca estourou! +%d",
  bj_broke = "Sem fichas!", bj_restart = "Reiniciar", bj_reshuffle = "Novo baralho embaralhado",
  bj_rules = "Blackjack paga 3:2 - a banca para no 17",
})

---------------------------------------------------------------- Zustand

local shoe = {}
local dealer, player = {}, {}
local cardPool = {}
local chips, bet, baseBet = START_CHIPS, 0, 0
local phase = "bet"      -- bet | dealing | wait | player | dealer | done
local frame, felt, fxFrame, ui = nil, nil, nil, {}
local resultKey, resultArg, resultColor
local noteKey

local function lerp(a, b, t) return a + (b - a) * t end
local function easeOut(p) return 1 - (1 - p) * (1 - p) end

---------------------------------------------------------------- Kartenstapel & Werte

local function newShoe()
  shoe = {}
  for d = 1, 4 do
    for _, s in ipairs(SUITS) do
      for r = 1, 13 do
        local v = r
        if r == 1 then v = 11 elseif r > 10 then v = 10 end
        table.insert(shoe, { rank = r, suit = s, value = v })
      end
    end
  end
  for i = #shoe, 2, -1 do
    local j = math.random(1, i)
    shoe[i], shoe[j] = shoe[j], shoe[i]
  end
end

local function draw()
  if #shoe == 0 then newShoe() end
  return table.remove(shoe)
end

local function handValue(hand, onlyUp)
  local sum, aces = 0, 0
  for _, c in ipairs(hand) do
    if not onlyUp or c.faceUp then
      sum = sum + c.value
      if c.rank == 1 then aces = aces + 1 end
    end
  end
  while sum > 21 and aces > 0 do
    sum = sum - 10
    aces = aces - 1
  end
  return sum
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
    if tw.dead then
      table.remove(tweens, i)
    else
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
end

-- Ablaufsteuerung: Schritte mit Wartezeit davor
local queue, qwait, qcurrent = {}, 0, nil
local function enqueue(delay, fn) table.insert(queue, { delay = delay, fn = fn }) end
local function runQueue(dt)
  if qwait > 0 then
    qwait = qwait - dt
    if qwait <= 0 and qcurrent then
      local f = qcurrent
      qcurrent = nil
      f()
    end
    return
  end
  if not qcurrent and queue[1] then
    local e = table.remove(queue, 1)
    if e.delay > 0 then
      qcurrent = e.fn
      qwait = e.delay * MG.Speed()
    else
      e.fn()
    end
  end
end

---------------------------------------------------------------- Effekte (Funken, schwebende Zahlen)

local particles, particlePool = {}, {}
local floaters, floaterPool = {}, {}

local function burst(x, y, count, gold)
  if not MG.EffectsOn() then return end
  for k = 1, count do
    local tex = table.remove(particlePool)
    if not tex then
      tex = fxFrame:CreateTexture(nil, "OVERLAY")
      tex:SetTexture("Interface\\Cooldown\\star4")
      tex:SetBlendMode("ADD")
    end
    local ang = math.random() * 6.2832
    local sp = 60 + math.random() * 120
    if gold then
      tex:SetVertexColor(1, 0.75 + math.random() * 0.25, 0.2 + math.random() * 0.4)
    else
      tex:SetVertexColor(1, 1, 1)
    end
    tex:Show()
    table.insert(particles, {
      tex = tex, x = x, y = y,
      vx = math.cos(ang) * sp, vy = math.sin(ang) * sp + 40,
      life = 0.6 + math.random() * 0.5, t = 0,
      size = 10 + math.random() * 12,
    })
  end
end

local function floater(x, y, text, r, g, b)
  if not MG.EffectsOn() then return end
  local fs = table.remove(floaterPool)
  if not fs then fs = fxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge") end
  fs:SetText(text)
  fs:SetTextColor(r, g, b)
  fs:Show()
  table.insert(floaters, { fs = fs, x = x, y = y, t = 0, life = 1.1 })
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
      p.vy = p.vy - 170 * dt
      p.tex:ClearAllPoints()
      p.tex:SetPoint("CENTER", felt, "TOPLEFT", p.x, p.y)
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
      f.fs:SetPoint("CENTER", felt, "TOPLEFT", f.x, f.y + 40 * easeOut(k))
      f.fs:SetAlpha(k < 0.6 and 1 or (1 - (k - 0.6) / 0.4))
      i = i + 1
    end
  end
end

---------------------------------------------------------------- Karten-Frames

local function placeFrame(f, x, y)
  f:ClearAllPoints()
  f:SetPoint("CENTER", felt, "TOPLEFT", x, y)
end

local function tex(parent, layer, sub, color, a)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetTexture(WHITE)
  t:SetVertexColor(color[1], color[2], color[3], a or 1)
  return t
end

local function inset(t, parent, l, tp, r, b)
  t:ClearAllPoints()
  t:SetPoint("TOPLEFT", parent, "TOPLEFT", l, -tp)
  t:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -r, b)
end

local function safeFont(fs, path, size, flags, fallback)
  local ok = fs:SetFont(path, size, flags)
  if not ok then fs:SetFontObject(fallback or "GameFontNormalLarge") end
end

local GOLD_BACK = { 0.88, 0.7, 0.28 }

local function makeCardFrame()
  local f = CreateFrame("Frame", nil, felt)
  f:SetWidth(CW)
  f:SetHeight(CH)

  -- Schatten (liegt ausserhalb der Karte, deshalb nicht im beschnittenen Inneren)
  f.shadow = tex(f, "BACKGROUND", 0, { 0, 0, 0 }, 0.4)
  f.shadow:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -4)
  f.shadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -4)

  -- Inneres (wird beim Umdrehen schmaler und beschneidet seinen Inhalt)
  local inner = CreateFrame("Frame", nil, f)
  inner:SetPoint("CENTER", f, "CENTER", 0, 0)
  inner:SetWidth(CW)
  inner:SetHeight(CH)
  if inner.SetClipsChildren then inner:SetClipsChildren(true) end
  f.inner = inner

  f.border = tex(inner, "BACKGROUND", 0, { 0.08, 0.08, 0.1 })
  f.border:SetAllPoints()
  f.faceLine = tex(inner, "BACKGROUND", 1, { 0.72, 0.62, 0.42 })
  inset(f.faceLine, inner, 2, 2, 2, 2)
  f.face = tex(inner, "BACKGROUND", 2, { 0.98, 0.96, 0.9 })
  inset(f.face, inner, 3, 3, 3, 3)
  f.sheen = tex(inner, "BACKGROUND", 3, { 0.85, 0.8, 0.65 }, 0.3)
  f.sheen:SetPoint("BOTTOMLEFT", inner, "BOTTOMLEFT", 3, 3)
  f.sheen:SetPoint("TOPRIGHT", inner, "RIGHT", -3, 0)

  -- Zierrahmen fuer Bildkarten (J, Q, K)
  f.frameLines = {}
  local function fline(p1, p2, x1, y1, x2, y2, w, h)
    local t = tex(inner, "ARTWORK", 0, { 0.4, 0.3, 0.2 }, 0.6)
    t:SetPoint(p1, inner, p1, x1, y1)
    t:SetPoint(p2, inner, p2, x2, y2)
    if w then t:SetWidth(w) end
    if h then t:SetHeight(h) end
    t:Hide()
    table.insert(f.frameLines, t)
  end
  fline("TOPLEFT", "TOPRIGHT", 17, -23, -17, -23, nil, 1)
  fline("BOTTOMLEFT", "BOTTOMRIGHT", 17, 23, -17, 23, nil, 1)
  fline("TOPLEFT", "BOTTOMLEFT", 17, -23, 17, 23, 1, nil)
  fline("TOPRIGHT", "BOTTOMRIGHT", -17, -23, -17, 23, 1, nil)

  f.rank = inner:CreateFontString(nil, "OVERLAY")
  safeFont(f.rank, "Fonts\\ARIALN.TTF", 16, "", "GameFontNormalLarge")
  f.rank:SetPoint("TOPLEFT", inner, "TOPLEFT", 5, -4)
  f.rank2 = inner:CreateFontString(nil, "OVERLAY")
  safeFont(f.rank2, "Fonts\\ARIALN.TTF", 16, "", "GameFontNormalLarge")
  f.rank2:SetPoint("BOTTOMRIGHT", inner, "BOTTOMRIGHT", -5, 4)
  f.big = inner:CreateFontString(nil, "OVERLAY")
  safeFont(f.big, "Fonts\\MORPHEUS.TTF", 46, "", "GameFontNormalHuge")
  f.big:SetPoint("CENTER", inner, "CENTER", 0, 0)

  f.corner = inner:CreateTexture(nil, "ARTWORK", nil, 3)
  f.corner:SetWidth(11)
  f.corner:SetHeight(11)
  f.corner:SetPoint("TOP", f.rank, "BOTTOM", 0, -1)
  f.corner2 = inner:CreateTexture(nil, "ARTWORK", nil, 3)
  f.corner2:SetWidth(11)
  f.corner2:SetHeight(11)
  f.corner2:SetPoint("BOTTOM", f.rank2, "TOP", 0, 1)
  if f.corner2.SetRotation then f.corner2:SetRotation(math.pi) end

  f.pips = {}
  for i = 1, 10 do
    local p = inner:CreateTexture(nil, "ARTWORK", nil, 3)
    p:Hide()
    f.pips[i] = p
  end

  -- Rueckseite: dunkelrot, Goldrahmen, Rautenmuster
  f.backParts = {}
  local function bpart(t) table.insert(f.backParts, t) return t end
  f.back = bpart(tex(inner, "ARTWORK", 0, { 0.45, 0.07, 0.1 }))
  inset(f.back, inner, 3, 3, 3, 3)
  local line = bpart(tex(inner, "ARTWORK", 1, GOLD_BACK))
  inset(line, inner, 6, 6, 6, 6)
  local lineIn = bpart(tex(inner, "ARTWORK", 2, { 0.32, 0.04, 0.07 }))
  inset(lineIn, inner, 7, 7, 7, 7)
  local function diamond(x, y, size, a)
    local d = inner:CreateTexture(nil, "ARTWORK", nil, 4)
    d:SetTexture(SUIT_TEX.D)
    d:SetVertexColor(GOLD_BACK[1], GOLD_BACK[2], GOLD_BACK[3])
    d:SetAlpha(a)
    d:SetWidth(size)
    d:SetHeight(size)
    d:SetPoint("CENTER", inner, "CENTER", x, y)
    bpart(d)
  end
  diamond(0, 0, 30, 0.95)
  diamond(-15, 28, 10, 0.55)
  diamond(15, 28, 10, 0.55)
  diamond(-15, -28, 10, 0.55)
  diamond(15, -28, 10, 0.55)
  diamond(0, 40, 8, 0.45)
  diamond(0, -40, 8, 0.45)
  return f
end

local function setPip(p, texPath, x, y, size, r, g, b, a, rot)
  p:SetTexture(texPath)
  p:SetVertexColor(r, g, b)
  p:SetAlpha(a or 1)
  p:SetWidth(size)
  p:SetHeight(size)
  if p.SetRotation then p:SetRotation(rot or 0) end
  p:ClearAllPoints()
  p:SetPoint("CENTER", p:GetParent(), "CENTER", x, y)
  p:Show()
end

local function setFace(f, card, up)
  f.border:SetVertexColor(0.08, 0.08, 0.1, 1)
  for _, p in ipairs(f.pips) do p:Hide() end
  for _, l in ipairs(f.frameLines) do l:Hide() end
  for _, t in ipairs(f.backParts) do
    if up then t:Hide() else t:Show() end
  end

  if not up then
    f.rank:Hide(); f.rank2:Hide(); f.big:Hide(); f.corner:Hide(); f.corner2:Hide()
    return
  end

  local texPath = SUIT_TEX[card.suit]
  local r, g, b = 0.08, 0.08, 0.12
  if SUIT_RED[card.suit] then r, g, b = 0.82, 0.1, 0.12 end
  f.rank:SetText(RANKS[card.rank])
  f.rank2:SetText(RANKS[card.rank])
  f.rank:SetTextColor(r, g, b)
  f.rank2:SetTextColor(r, g, b)
  f.rank:Show(); f.rank2:Show()
  f.corner:SetTexture(texPath); f.corner:SetVertexColor(r, g, b); f.corner:Show()
  f.corner2:SetTexture(texPath); f.corner2:SetVertexColor(r, g, b); f.corner2:Show()

  local n = card.rank
  if n == 1 then
    f.big:Hide()
    setPip(f.pips[1], texPath, 0, 0, 44, r, g, b, 1, 0)
  elseif n >= 11 then
    for _, l in ipairs(f.frameLines) do
      l:SetVertexColor(r, g, b, 0.55)
      l:Show()
    end
    setPip(f.pips[1], texPath, 0, 0, 46, r, g, b, 0.18, 0)
    f.big:SetText(RANKS[n])
    f.big:SetTextColor(r, g, b)
    f.big:Show()
  else
    f.big:Hide()
    local size = (n <= 6) and 14 or 12
    for i, pos in ipairs(PIPS[n]) do
      local rot = (pos[2] > 0.5) and math.pi or 0
      setPip(f.pips[i], texPath, pos[1] * 11, (0.5 - pos[2]) * 54, size, r, g, b, 1, rot)
    end
  end
end

local function glow(hand)
  for _, c in ipairs(hand) do
    c.f.border:SetVertexColor(1, 0.82, 0.2, 1)
  end
end

---------------------------------------------------------------- Anzeige

local function colorVal(v)
  if v > 21 then return "|cffff4040" .. v .. "|r" end
  if v == 21 then return "|cff40ff60" .. v .. "|r" end
  return "|cffffffff" .. v .. "|r"
end

local function updateTotals()
  if not ui.dealerLabel then return end
  if #dealer > 0 then
    ui.dealerLabel:SetText(T("bj_dealer") .. ": " .. colorVal(handValue(dealer, true)))
  else
    ui.dealerLabel:SetText(T("bj_dealer"))
  end
  if #player > 0 then
    ui.playerLabel:SetText(T("bj_player") .. ": " .. colorVal(handValue(player)))
  else
    ui.playerLabel:SetText(T("bj_player"))
  end
end

local function updateButtons()
  if not ui.dealBtn then return end
  local canBet = (phase == "bet" or phase == "done") and chips > 0
  for _, cb in ipairs(ui.chipBtns) do
    if canBet and bet < chips then cb:Enable() else cb:Disable() end
  end
  if canBet and bet > 0 then ui.clearBtn:Enable() else ui.clearBtn:Disable() end
  if phase == "player" then ui.hitBtn:Enable() ui.standBtn:Enable() else ui.hitBtn:Disable() ui.standBtn:Disable() end
  if phase == "player" and #player == 2 and chips >= bet then ui.doubleBtn:Enable() else ui.doubleBtn:Disable() end
  if chips <= 0 then
    ui.dealBtn:SetText(T("bj_restart"))
    if phase == "bet" or phase == "done" then ui.dealBtn:Enable() else ui.dealBtn:Disable() end
  else
    ui.dealBtn:SetText(T("bj_deal"))
    if (phase == "bet" or phase == "done") and bet > 0 then ui.dealBtn:Enable() else ui.dealBtn:Disable() end
  end
end

local function updateCoins()
  if not ui.coins then return end
  local n = 0
  if bet > 0 then n = math.min(8, math.max(1, math.ceil(bet / 60))) end
  for i, c in ipairs(ui.coins) do
    if i <= n then c:Show() else c:Hide() end
  end
end

local function updateTexts()
  if not ui.chipsText then return end
  ui.chipsText:SetText(T("bj_chips") .. ": " .. chips)
  ui.betText:SetText(T("bj_bet") .. ": " .. bet)
  updateCoins()
end

local function renderResult()
  if not ui.result then return end
  if resultKey then
    local text = resultArg and T(resultKey, resultArg) or T(resultKey)
    if chips <= 0 and phase == "done" then text = text .. "  " .. T("bj_broke") end
    ui.result:SetText(text)
    local c = resultColor or { 1, 1, 1 }
    ui.result:SetTextColor(c[1], c[2], c[3])
    ui.result:Show()
    ui.banner:Show()
  else
    ui.result:SetText("")
    ui.result:Hide()
    ui.banner:Hide()
  end
  if noteKey then ui.note:SetText(T(noteKey)) else ui.note:SetText("") end
end

local function setResult(key, arg, color)
  resultKey, resultArg, resultColor = key, arg, color
  renderResult()
  if key then
    addTween(0.3, function(p)
      ui.result:SetAlpha(p)
      ui.banner:SetAlpha(p * 0.65)
    end)
  end
end

local function save()
  if MG.db then MG.db.bj_chips = chips end
end

---------------------------------------------------------------- Karten legen

local function relayout(hand, y)
  local n = #hand
  local spacing = CW + 10
  if n > 1 then spacing = math.min(CW + 10, (330 - CW) / (n - 1)) end
  local total = (n - 1) * spacing
  local startX = FELT_W / 2 - total / 2
  for i, c in ipairs(hand) do
    local tx, ty = startX + (i - 1) * spacing, y
    if c.mv then c.mv.dead = true end
    local x1, y1 = c.cx, c.cy
    c.mv = addTween(0.3, function(p)
      local e = easeOut(p)
      c.cx = lerp(x1, tx, e)
      c.cy = lerp(y1, ty, e)
      placeFrame(c.f, c.cx, c.cy)
    end)
  end
end

local function dealCard(hand, y, up)
  local c = draw()
  c.faceUp = up
  c.mv = nil
  c.f = table.remove(cardPool) or makeCardFrame()
  c.f.inner:SetWidth(CW)
  c.f:SetFrameLevel(felt:GetFrameLevel() + 6 + #hand + (y == PLAYER_Y and 20 or 0))
  setFace(c.f, c, up)
  c.f:Show()
  c.cx, c.cy = DECK_X, DECK_Y
  placeFrame(c.f, c.cx, c.cy)
  table.insert(hand, c)
  relayout(hand, y)
  local f = c.f
  addTween(0.2, function(p) f:SetAlpha(p) end)
  updateTotals()
  return c
end

local function flip(c, up)
  local inner = c.f.inner
  local swapped = false
  addTween(0.32, function(p)
    local w
    if p < 0.5 then
      w = lerp(CW, 2, p * 2)
    else
      if not swapped then
        swapped = true
        c.faceUp = up
        setFace(c.f, c, up)
      end
      w = lerp(2, CW, (p - 0.5) * 2)
    end
    inner:SetWidth(w)
  end, function()
    inner:SetWidth(CW)
    updateTotals()
  end)
end

local function reveal()
  local hole = dealer[2]
  if hole and not hole.faceUp then flip(hole, true) end
end

local function clearTable()
  for _, hand in ipairs({ dealer, player }) do
    for _, c in ipairs(hand) do
      if c.mv then c.mv.dead = true end
      c.f:Hide()
      c.f:SetAlpha(1)
      table.insert(cardPool, c.f)
    end
  end
  dealer, player = {}, {}
  updateTotals()
end

---------------------------------------------------------------- Rundenablauf

local GREEN, RED, GOLD = { 0.3, 1, 0.4 }, { 1, 0.3, 0.3 }, { 1, 0.85, 0.2 }

local function finish()
  local pv, dv = handValue(player), handValue(dealer)
  local pBJ = (#player == 2 and pv == 21)
  local dBJ = (#dealer == 2 and dv == 21)
  local key, arg, color
  local outcome -- "win" | "lose" | "push" | "bj"
  local function lose()
    outcome = "lose"
    if pv > 21 then key, arg, color = "bj_bust", bet, RED else key, arg, color = "bj_lose", bet, RED end
  end
  local function win()
    outcome = "win"
    chips = chips + bet * 2
    key, arg, color = "bj_win", bet, GREEN
  end
  local function push()
    outcome = "push"
    chips = chips + bet
    key, arg, color = "bj_push", nil, GOLD
  end
  if pv > 21 then
    lose()
  elseif pBJ and not dBJ then
    local w = math.floor(bet * 1.5)
    outcome = "bj"
    chips = chips + bet + w
    key, arg, color = "bj_blackjack", w, GOLD
  elseif dBJ and not pBJ then
    lose()
  elseif pBJ and dBJ then
    push()
  elseif dv > 21 then
    win()
    key, arg = "bj_dealer_bust", bet
  elseif pv > dv then
    win()
  elseif pv < dv then
    lose()
  else
    push()
  end

  phase = "done"
  local shownBet = bet
  bet = math.min(baseBet, chips)
  save()
  setResult(key, arg, color)
  updateTexts()
  updateButtons()

  -- Effekte
  if outcome == "win" or outcome == "bj" then
    glow(player)
    local gain = (outcome == "bj") and math.floor(shownBet * 1.5) or shownBet
    burst(FELT_W / 2, PLAYER_Y, outcome == "bj" and 30 or 14, true)
    floater(COIN_X, COIN_Y + 30, "+" .. gain, 1, 0.85, 0.2)
  elseif outcome == "lose" then
    glow(dealer)
    floater(COIN_X, COIN_Y + 30, "-" .. shownBet, 1, 0.3, 0.3)
  end
end

local dealerStep
dealerStep = function()
  if handValue(dealer) < 17 then
    dealCard(dealer, DEALER_Y, true)
    enqueue(0.55, dealerStep)
  else
    enqueue(0.35, finish)
  end
end

local function startDealerPlay()
  phase = "dealer"
  updateButtons()
  reveal()
  enqueue(0.6, dealerStep)
end

local function afterDeal()
  local pv, dv = handValue(player), handValue(dealer)
  if pv == 21 or dv == 21 then
    phase = "dealer"
    updateButtons()
    reveal()
    enqueue(0.6, finish)
  else
    phase = "player"
    updateButtons()
  end
end

local function startDeal()
  if chips <= 0 then
    chips = START_CHIPS
    bet = math.min(10, chips)
    save()
    setResult(nil)
    noteKey = nil
    clearTable()
    phase = "bet"
    updateTexts()
    updateButtons()
    return
  end
  if phase ~= "bet" and phase ~= "done" then return end
  if bet <= 0 or bet > chips then return end
  baseBet = bet
  chips = chips - bet
  save()
  clearTable()
  setResult(nil)
  if #shoe < 52 then
    local had = #shoe > 0
    newShoe()
    noteKey = had and "bj_reshuffle" or nil
  else
    noteKey = nil
  end
  renderResult()
  phase = "dealing"
  updateTexts()
  updateButtons()
  enqueue(0, function() dealCard(player, PLAYER_Y, true) end)
  enqueue(0.3, function() dealCard(dealer, DEALER_Y, true) end)
  enqueue(0.3, function() dealCard(player, PLAYER_Y, true) end)
  enqueue(0.3, function() dealCard(dealer, DEALER_Y, false) end)
  enqueue(0.6, afterDeal)
end

local function afterPlayerCard(doubled)
  local pv = handValue(player)
  if pv > 21 then
    phase = "dealer"
    updateButtons()
    reveal()
    enqueue(0.6, finish)
  elseif pv == 21 or doubled then
    startDealerPlay()
  else
    phase = "player"
    updateButtons()
  end
end

local function doHit()
  if phase ~= "player" then return end
  phase = "wait"
  updateButtons()
  dealCard(player, PLAYER_Y, true)
  enqueue(0.45, function() afterPlayerCard(false) end)
end

local function doStand()
  if phase ~= "player" then return end
  startDealerPlay()
end

local function doDouble()
  if phase ~= "player" or #player ~= 2 or chips < bet then return end
  chips = chips - bet
  bet = bet * 2
  save()
  updateTexts()
  phase = "wait"
  updateButtons()
  dealCard(player, PLAYER_Y, true)
  enqueue(0.45, function() afterPlayerCard(true) end)
end

local function addBet(v)
  if phase ~= "bet" and phase ~= "done" then return end
  bet = math.min(bet + v, chips)
  updateTexts()
  updateButtons()
end

local function clearBet()
  if phase ~= "bet" and phase ~= "done" then return end
  bet = 0
  updateTexts()
  updateButtons()
end

---------------------------------------------------------------- Fenster

local function applyTexts()
  if not frame then return end
  frame.title:SetText(T("game_blackjack"))
  ui.hitBtn:SetText(T("bj_hit"))
  ui.standBtn:SetText(T("bj_stand"))
  ui.doubleBtn:SetText(T("bj_double"))
  ui.clearBtn:SetText(T("bj_clear"))
  ui.rules:SetText(T("bj_rules"))
  ui.mark:SetText("BLACKJACK")
  updateTexts()
  updateTotals()
  renderResult()
  updateButtons()
end

local function mkBtn(text, w, x, y, fn)
  local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  b:SetWidth(w)
  b:SetHeight(24)
  b:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  if text then b:SetText(text) end
  b:SetScript("OnClick", fn)
  return b
end

local function buildTable()
  felt = CreateFrame("Frame", nil, frame)
  felt:SetWidth(FELT_W)
  felt:SetHeight(FELT_H)
  felt:SetPoint("TOP", frame, "TOP", 0, -58)

  -- Holzrand
  local wood = frame:CreateTexture(nil, "BACKGROUND")
  wood:SetPoint("TOPLEFT", felt, "TOPLEFT", -5, 5)
  wood:SetPoint("BOTTOMRIGHT", felt, "BOTTOMRIGHT", 5, -5)
  wood:SetTexture(WHITE)
  wood:SetVertexColor(0.3, 0.17, 0.07, 1)
  local woodIn = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  woodIn:SetPoint("TOPLEFT", felt, "TOPLEFT", -2, 2)
  woodIn:SetPoint("BOTTOMRIGHT", felt, "BOTTOMRIGHT", 2, -2)
  woodIn:SetTexture(WHITE)
  woodIn:SetVertexColor(0.16, 0.09, 0.04, 1)

  -- Filz
  local cloth = tex(felt, "BACKGROUND", 0, { 0.03, 0.24, 0.1 })
  cloth:SetAllPoints()
  local light = tex(felt, "BACKGROUND", 1, { 0.1, 0.45, 0.22 }, 0.45)
  inset(light, felt, 36, 30, 36, 30)
  local lighter = tex(felt, "BACKGROUND", 2, { 0.14, 0.52, 0.27 }, 0.35)
  inset(lighter, felt, 100, 70, 100, 70)

  -- Goldene Zierlinie
  local function line(a, b, c, d, w, h)
    local t = tex(felt, "BACKGROUND", 3, { 0.9, 0.72, 0.28 }, 0.55)
    t:SetPoint(a, felt, a, c, d)
    t:SetPoint(b, felt, b, c, d)
    if w then t:SetWidth(w) end
    if h then t:SetHeight(h) end
  end
  line("TOPLEFT", "TOPRIGHT", 0, -7, nil, 1)
  line("BOTTOMLEFT", "BOTTOMRIGHT", 0, 7, nil, 1)
  line("TOPLEFT", "BOTTOMLEFT", 7, 0, 1, nil)
  line("TOPRIGHT", "BOTTOMRIGHT", -7, 0, 1, nil)

  -- Wasserzeichen und Ergebnis-Banner
  ui.mark = felt:CreateFontString(nil, "ARTWORK")
  ui.mark:SetFont(STANDARD_TEXT_FONT, 34, "OUTLINE")
  ui.mark:SetPoint("CENTER", felt, "TOPLEFT", FELT_W / 2, -148)
  ui.mark:SetTextColor(0.9, 0.72, 0.28)
  ui.mark:SetAlpha(0.13)

  ui.banner = tex(felt, "ARTWORK", 1, { 0, 0, 0 }, 0.65)
  ui.banner:SetWidth(330)
  ui.banner:SetHeight(32)
  ui.banner:SetPoint("CENTER", felt, "TOPLEFT", FELT_W / 2, -148)
  ui.banner:Hide()

  ui.result = felt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  ui.result:SetPoint("CENTER", felt, "TOPLEFT", FELT_W / 2, -148)

  -- Kartenstapel (drei Rueckseiten)
  for k = 2, 0, -1 do
    local d = makeCardFrame()
    setFace(d, nil, false)
    d:SetFrameLevel(felt:GetFrameLevel() + 1 + (2 - k))
    placeFrame(d, DECK_X + k * 2, DECK_Y - k * 2)
    d:Show()
  end

  ui.dealerLabel = felt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.dealerLabel:SetPoint("TOPLEFT", felt, "TOPLEFT", 14, -14)
  ui.playerLabel = felt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ui.playerLabel:SetPoint("TOPLEFT", felt, "TOPLEFT", 14, -122)
  ui.note = felt:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ui.note:SetPoint("BOTTOM", felt, "BOTTOM", 0, 12)

  -- Effekt-Ebene ganz oben
  fxFrame = CreateFrame("Frame", nil, felt)
  fxFrame:SetAllPoints(felt)
  fxFrame:SetFrameLevel(felt:GetFrameLevel() + 80)
end

local function buildUI()
  frame = MG.NewPage("blackjack", 540, 440)

  ui.chipsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ui.chipsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -40)
  ui.betText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  ui.betText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -40)

  buildTable()

  -- Einsatz-Knoepfe
  ui.chipBtns = {}
  local amounts = { 10, 50, 100, 500 }
  for i, v in ipairs(amounts) do
    ui.chipBtns[i] = mkBtn("+" .. v, 76, 22 + (i - 1) * 84, -338, function() addBet(v) end)
  end
  ui.clearBtn = mkBtn(nil, 76, 22 + 4 * 84, -338, clearBet)

  -- Aktionen
  ui.hitBtn = mkBtn(nil, 96, 22, -368, doHit)
  ui.standBtn = mkBtn(nil, 96, 126, -368, doStand)
  ui.doubleBtn = mkBtn(nil, 96, 230, -368, doDouble)
  ui.dealBtn = mkBtn(nil, 150, 360, -368, startDeal)

  ui.rules = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  ui.rules:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -404)

  frame:SetScript("OnUpdate", function(self, elapsed)
    if elapsed > 0.1 then elapsed = 0.1 end
    updateTweens(elapsed)
    updateEffects(elapsed)
    runQueue(elapsed)
  end)
end

MG.RegisterGame({
  id = "blackjack",
  nameKey = "game_blackjack",
  descKey = "game_blackjack_desc",
  icon = MEDIA .. "blackjack",
  init = function()
    buildUI()
    chips = (MG.db and MG.db.bj_chips) or START_CHIPS
    bet = math.min(10, chips)
    phase = "bet"
    newShoe()
    applyTexts()
  end,
})

MG.OnChange(applyTexts)

MG.Slash("blackjack", { "/bjk", "/blackjack", "/21" })
