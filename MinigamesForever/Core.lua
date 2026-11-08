-- Minigames Forever: Kern (Hauptmenue, Einstellungen, Sprachen, Fenster-Helfer)
-- Neue Sprache: Eintrag in MG.LANGS ergaenzen und in jeder Datei MG.AddLocale("xx", {...}) nutzen.
-- Fehlende Texte fallen auf Englisch zurueck.

local ADDON, MG = ...

MG.games = {}        -- id -> Spiel
MG.gameList = {}     -- Reihenfolge fuers Menue
MG.listeners = {}    -- Funktionen, die bei Einstellungs-/Sprachwechsel laufen
MG.errors = {}       -- id -> Fehlertext beim Starten
MG.lang = "en"

MG.LANGS = {
  { "de", "Deutsch" }, { "en", "English" }, { "fr", "Français" },
  { "es", "Español" }, { "it", "Italiano" }, { "pt", "Português" },
}
local SPEEDS = { { key = "slow", mul = 1.6 }, { key = "normal", mul = 1 }, { key = "fast", mul = 0.6 } }

MG.LOCALES = { en = {}, de = {}, fr = {}, es = {}, it = {}, pt = {} }

function MG.AddLocale(code, tbl)
  local L = MG.LOCALES[code]
  if not L then return end
  for k, v in pairs(tbl) do L[k] = v end
end

function MG.T(key, ...)
  local l = MG.LOCALES[MG.lang]
  local s = (l and l[key]) or MG.LOCALES.en[key] or key
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end
local T = MG.T

MG.AddLocale("en", {
  settings = "Settings", language = "Language", speed = "Animation speed",
  slow = "Slow", normal = "Normal", fast = "Fast",
  effects = "Effects", on = "On", off = "Off",
  style = "Gem style", icons = "Gems", colors = "Colors",
  err = "Minigames Forever error:", hub_title = "Minigames", hub_hint = "Choose a game",
  score = "Score", best = "Best", new_game = "New Game",
})
MG.AddLocale("de", {
  settings = "Einstellungen", language = "Sprache", speed = "Animationsgeschwindigkeit",
  slow = "Langsam", normal = "Normal", fast = "Schnell",
  effects = "Effekte", on = "An", off = "Aus",
  style = "Steinoptik", icons = "Edelsteine", colors = "Farben",
  err = "Minigames Forever Fehler:", hub_title = "Minispiele", hub_hint = "Wähle ein Spiel",
  score = "Punkte", best = "Rekord", new_game = "Neues Spiel",
})
MG.AddLocale("fr", {
  settings = "Paramètres", language = "Langue", speed = "Vitesse d'animation",
  slow = "Lente", normal = "Normale", fast = "Rapide",
  effects = "Effets", on = "Oui", off = "Non",
  style = "Style des gemmes", icons = "Gemmes", colors = "Couleurs",
  err = "Erreur Minigames Forever :", hub_title = "Mini-jeux", hub_hint = "Choisis un jeu",
  score = "Score", best = "Record", new_game = "Nouvelle partie",
})
MG.AddLocale("es", {
  settings = "Ajustes", language = "Idioma", speed = "Velocidad de animación",
  slow = "Lenta", normal = "Normal", fast = "Rápida",
  effects = "Efectos", on = "Sí", off = "No",
  style = "Estilo de gemas", icons = "Gemas", colors = "Colores",
  err = "Error de Minigames Forever:", hub_title = "Minijuegos", hub_hint = "Elige un juego",
  score = "Puntos", best = "Récord", new_game = "Nueva partida",
})
MG.AddLocale("it", {
  settings = "Impostazioni", language = "Lingua", speed = "Velocità animazioni",
  slow = "Lenta", normal = "Normale", fast = "Veloce",
  effects = "Effetti", on = "Sì", off = "No",
  style = "Stile gemme", icons = "Gemme", colors = "Colori",
  err = "Errore Minigames Forever:", hub_title = "Minigiochi", hub_hint = "Scegli un gioco",
  score = "Punti", best = "Record", new_game = "Nuova partita",
})
MG.AddLocale("pt", {
  settings = "Configurações", language = "Idioma", speed = "Velocidade da animação",
  slow = "Lenta", normal = "Normal", fast = "Rápida",
  effects = "Efeitos", on = "Sim", off = "Não",
  style = "Estilo das gemas", icons = "Gemas", colors = "Cores",
  err = "Erro do Minigames Forever:", hub_title = "Minijogos", hub_hint = "Escolha um jogo",
  score = "Pontos", best = "Recorde", new_game = "Novo jogo",
})

---------------------------------------------------------------- Einstellungs-Zugriff

function MG.Speed() return (MG.db and MG.db.speed) or 1 end
function MG.EffectsOn() return not (MG.db and MG.db.effects == false) end
function MG.UseColors() return MG.db and MG.db.colors and true or false end

function MG.OnChange(fn) table.insert(MG.listeners, fn) end
function MG.Changed()
  for _, fn in ipairs(MG.listeners) do pcall(fn) end
end

function MG.RegisterGame(def)
  MG.games[def.id] = def
  table.insert(MG.gameList, def)
end

function MG.Open(id)
  local g = MG.games[id]
  if not g or not MG.main then return end
  if MG.errors[id] or not g.ready then
    print("|cffff4444" .. T("err") .. "|r " .. tostring(MG.errors[id] or "not initialised"))
    return
  end
  if MG.main:IsShown() and MG.current == id then
    MG.main:Hide()
  else
    MG.Select(id)
    MG.main:Show()
  end
end
function MG.Slash(id, cmds, handler)
  local key = "MGF" .. string.upper(id)
  for i, c in ipairs(cmds) do _G["SLASH_" .. key .. i] = c end
  SlashCmdList[key] = handler or function() MG.Open(id) end
end

---------------------------------------------------------------- Fenster-Helfer

local BACKDROP = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

function MG.NewWindow(name, w, h)
  local f = CreateFrame("Frame", name, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f:SetWidth(w)
  f:SetHeight(h)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self) self:StartMoving() end)
  f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
  f:SetBackdrop(BACKDROP)
  f:Hide()
  tinsert(UISpecialFrames, name) -- Esc schliesst

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  f.title:SetPoint("TOP", f, "TOP", 0, -18)

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
  return f
end

---------------------------------------------------------------- Einstellungs-Panel (geteilt)

local panel

local function refreshPanel()
  if not panel then return end
  local db = MG.db
  panel.title:SetText(T("settings"))
  panel.langLabel:SetText(T("language"))
  panel.speedLabel:SetText(T("speed"))
  for n, b in ipairs(panel.langBtns) do
    if MG.LANGS[n][1] == MG.lang then b:Disable() else b:Enable() end
  end
  for n, b in ipairs(panel.speedBtns) do
    b:SetText(T(SPEEDS[n].key))
    if SPEEDS[n].mul == MG.Speed() then b:Disable() else b:Enable() end
  end
  panel.effectsBtn:SetText(T("effects") .. ": " .. (MG.EffectsOn() and T("on") or T("off")))
  panel.styleBtn:SetText(T("style") .. ": " .. (MG.UseColors() and T("colors") or T("icons")))
end

local function buildPanel()
  panel = CreateFrame("Frame", "MinigamesForeverSettings", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetWidth(240)
  panel:SetHeight(284)
  panel:SetFrameStrata("DIALOG")
  panel:SetBackdrop(BACKDROP)
  panel:Hide()

  panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  panel.title:SetPoint("TOP", panel, "TOP", 0, -16)
  panel.langLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  panel.langLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -44)

  panel.langBtns = {}
  for n, entry in ipairs(MG.LANGS) do
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetWidth(98); b:SetHeight(22)
    local col, row = (n - 1) % 2, math.floor((n - 1) / 2)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", 16 + col * 104, -62 - row * 24)
    b:SetText(entry[2])
    b:SetScript("OnClick", function()
      MG.lang = entry[1]
      MG.db.lang = entry[1]
      MG.Changed()
    end)
    panel.langBtns[n] = b
  end

  panel.speedLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  panel.speedLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -142)
  panel.speedBtns = {}
  for n, sp in ipairs(SPEEDS) do
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetWidth(66); b:SetHeight(22)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", 14 + (n - 1) * 70, -160)
    b:SetScript("OnClick", function()
      MG.db.speed = sp.mul
      MG.Changed()
    end)
    panel.speedBtns[n] = b
  end

  panel.effectsBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.effectsBtn:SetWidth(208); panel.effectsBtn:SetHeight(22)
  panel.effectsBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -192)
  panel.effectsBtn:SetScript("OnClick", function()
    MG.db.effects = not MG.EffectsOn()
    MG.Changed()
  end)

  panel.styleBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  panel.styleBtn:SetWidth(208); panel.styleBtn:SetHeight(22)
  panel.styleBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -218)
  panel.styleBtn:SetScript("OnClick", function()
    MG.db.colors = not MG.UseColors()
    MG.Changed()
  end)

  panel.credit = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.credit:SetPoint("BOTTOM", panel, "BOTTOM", 0, 18)
  panel.credit:SetText("Vibe-coded by @f4bst3r")
  MG.OnChange(refreshPanel)
end

function MG.ToggleSettings(owner)
  if not panel then buildPanel() end
  if panel:IsShown() and panel.owner == owner then
    panel:Hide()
    return
  end
  panel.owner = owner
  panel:ClearAllPoints()
  panel:SetPoint("TOPLEFT", owner, "TOPRIGHT", 34, -20)
  refreshPanel()
  panel:Show()
end

-- Zahnrad-Knopf an der rechten Fensterseite
function MG.AddGear(f)
  local gear = CreateFrame("Button", nil, f)
  gear:SetWidth(32)
  gear:SetHeight(32)
  gear:SetPoint("TOPLEFT", f, "TOPRIGHT", -2, -50)
  local icon = gear:CreateTexture(nil, "ARTWORK")
  icon:SetAllPoints()
  icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
  gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
  gear:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T("settings"))
    GameTooltip:Show()
  end)
  gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
  gear:SetScript("OnClick", function() MG.ToggleSettings(f) end)
  f:HookScript("OnHide", function()
    if panel and panel.owner == f then panel:Hide() end
  end)
  return gear
end

---------------------------------------------------------------- Hauptfenster mit Spielauswahl (links) und Spiel (rechts)

local SIDE = 140          -- Breite der Seitenleiste
local main
MG.pages = {}
MG.current = nil
local sideRows = {}
local sideHeader

-- Spiele legen ihre Oberflaeche als "Seite" im Hauptfenster an
function MG.NewPage(id, w, h)
  local p = CreateFrame("Frame", nil, main)
  p:SetWidth(w)
  p:SetHeight(h)
  p:SetPoint("TOPLEFT", main, "TOPLEFT", SIDE, 0)
  p:Hide()
  p.pw, p.ph = w, h
  p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  p.title:SetPoint("TOP", p, "TOP", 0, -18)
  MG.pages[id] = p
  return p
end

local function refreshSidebar()
  if not main then return end
  if sideHeader then sideHeader:SetText(T("hub_title")) end
  for _, r in ipairs(sideRows) do
    r.name:SetText(T(r.g.nameKey))
    if r.g.id == MG.current then r.sel:Show() else r.sel:Hide() end
  end
end

function MG.Select(id)
  local p = MG.pages[id]
  if not p or not main then return end
  for _, q in pairs(MG.pages) do q:Hide() end
  p:Show()
  main:SetWidth(SIDE + p.pw)
  main:SetHeight(p.ph)
  MG.current = id
  if MG.db then MG.db.lastGame = id end
  refreshSidebar()
end

local function buildMain()
  main = MG.NewWindow("MinigamesForeverFrame", 600, 440)
  main.title:SetText("")
  MG.AddGear(main)
  MG.main = main
end

local function buildSidebar()
  local div = main:CreateTexture(nil, "ARTWORK")
  div:SetTexture("Interface\\Buttons\\WHITE8X8")
  div:SetVertexColor(1, 0.82, 0, 0.35)
  div:SetWidth(1)
  div:SetPoint("TOPLEFT", main, "TOPLEFT", SIDE - 4, -16)
  div:SetPoint("BOTTOMLEFT", main, "BOTTOMLEFT", SIDE - 4, 16)

  sideHeader = main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sideHeader:SetPoint("TOPLEFT", main, "TOPLEFT", 18, -22)

  for i, g in ipairs(MG.gameList) do
    local b = CreateFrame("Button", nil, main)
    b:SetWidth(118)
    b:SetHeight(40)
    b:SetPoint("TOPLEFT", main, "TOPLEFT", 14, -46 - (i - 1) * 44)
    local sel = b:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints()
    sel:SetTexture("Interface\\Buttons\\WHITE8X8")
    sel:SetVertexColor(1, 0.82, 0, 0.22)
    sel:Hide()
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(32)
    icon:SetHeight(32)
    icon:SetPoint("LEFT", b, "LEFT", 4, 0)
    icon:SetTexture(g.icon)
    local name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    name:SetWidth(74)
    name:SetJustifyH("LEFT")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    b:SetScript("OnClick", function()
      if MG.errors[g.id] or not g.ready then
        print("|cffff4444" .. T("err") .. "|r " .. tostring(MG.errors[g.id] or "not initialised"))
      else
        MG.Select(g.id)
      end
    end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(T(g.nameKey))
      GameTooltip:AddLine(T(g.descKey), 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    sideRows[i] = { g = g, name = name, sel = sel }
  end
  MG.OnChange(refreshSidebar)
  refreshSidebar()
end

MG.Slash("hub", { "/mgf", "/minigames", "/games" }, function()
  if MG.errors.hub or not MG.main then
    print("|cffff4444" .. T("err") .. "|r " .. tostring(MG.errors.hub or "not initialised"))
    return
  end
  if MG.main:IsShown() then MG.main:Hide() return end
  local id = MG.current or (MG.db and MG.db.lastGame)
  if not (id and MG.pages[id] and MG.games[id] and MG.games[id].ready) then
    id = nil
    for _, g in ipairs(MG.gameList) do
      if g.ready then id = g.id break end
    end
  end
  if id then MG.Select(id) end
  MG.main:Show()
end)

---------------------------------------------------------------- Start

local function detectLang()
  local loc = GetLocale and GetLocale() or "enUS"
  local code = string.sub(loc, 1, 2)
  if MG.LOCALES[code] then return code end
  return "en"
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(self, event, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")

  MinigamesForeverDB = MinigamesForeverDB or {}
  local db = MinigamesForeverDB
  MG.db = db

  -- Uebernahme der Werte aus dem alten Einzel-Add-on "Bejeweled Forever"
  local old = BejeweledForeverDB
  if old and not db.migrated then
    db.migrated = true
    if db.bejeweled_best == nil then db.bejeweled_best = old.best end
    if db.lang == nil then db.lang = old.lang end
    if db.speed == nil then db.speed = old.speed end
    if db.effects == nil then db.effects = old.effects end
    if db.colors == nil then db.colors = old.colors end
  end

  if not db.lang or not MG.LOCALES[db.lang] then db.lang = detectLang() end
  MG.lang = db.lang

  local okMain, errMain = pcall(buildMain)
  if not okMain then MG.errors.hub = tostring(errMain) end

  if okMain then
    for _, g in ipairs(MG.gameList) do
      local ok, err = pcall(g.init)
      if ok then g.ready = true else MG.errors[g.id] = tostring(err) end
    end
    local okSide, errSide = pcall(buildSidebar)
    if not okSide then MG.errors.hub = tostring(errSide) end
  end
  MG.Changed()
end)
