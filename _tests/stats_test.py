import sys
from pathlib import Path

addon = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(addon.parent / 'LH_Tweaks' / '.test-runtime'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute('''
SlashCmdList = {}; frames = {}
local m = {}
function m:SetScript(k, v) self.scripts[k] = v end
function m:SetSize(w, h) self.width, self.height = w, h end
function m:SetWidth(w) self.width = w end
function m:SetHeight(h) self.height = h end
function m:GetWidth() return self.width or 140 end
function m:GetHeight() return self.height or 20 end
function m:GetEffectiveScale() return 1 end
function m:GetFrameLevel() return 1 end
function m:GetLeft() return 100 end
function m:GetTop() return 300 end
function m:GetCenter() return 700, 400 end
function m:EnableMouse(v) self.mouse = v end
function m:SetShown(v) self.visible = v end
function m:Show() self.visible = true end
function m:Hide() self.visible = false end
function m:SetPoint(...) self.point = {...} end
function m:ClearAllPoints() self.point = nil end
function m:GetStringWidth() return 20 end
function m:CreateTexture() return CreateFrame('Texture') end
function m:CreateFontString() return CreateFrame('Font') end
function m:StartMoving() self.movingNow = true end
function m:StopMovingOrSizing() self.movingNow = false end
setmetatable(m, {__index = function() return function() end end})
function CreateFrame(kind, name, parent)
  local f = setmetatable({kind = kind, parent = parent, scripts = {}, movingNow = false, mouse = false, visible = false}, {__index = m})
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end
WOW_PROJECT_MAINLINE = 1; WOW_PROJECT_ID = 1
UIParent = CreateFrame('Frame'); Minimap = CreateFrame('Frame'); Minimap.width = 160
GameTooltip = CreateFrame('Frame')
GameTooltip.lines = {}
function GameTooltip:SetOwner(owner) self.owner = owner; self.lines = {} end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = {text} end
function GameTooltip:AddDoubleLine(left, right, lr, lg, lb)
  self.lines[#self.lines + 1] = {left, right, lr, lg, lb}
end
function GameTooltip:Hide() self.owner = nil end
cursorX, cursorY, mouseDown = 0, 0, false
function GetCursorPosition() return cursorX, cursorY end
function IsMouseButtonDown() return mouseDown end
playerName, playerRealm, playerClass, playerMoney = 'Zara', 'Realm', 'WARRIOR', 12345
function UnitName() return playerName end
function GetRealmName() return playerRealm end
function UnitClass() return playerClass, playerClass end
function GetMoney() return playerMoney end
function GetInventorySlotInfo() return 0 end
function GetInventoryItemTexture() return nil end
function GetContainerNumSlots() return 16 end
function GetContainerNumFreeSlots() return 4, 0 end
LH_LayoutProfiles = {Register = function() end}
RAID_CLASS_COLORS = {WARRIOR = {r = 0.8, g = 0.6, b = 0.4}, MAGE = {r = 0.2, g = 0.8, b = 1}}
''')
lua.execute((addon / 'LH_Stats.lua').read_text(encoding='utf-8'), 'LH_Stats')
lua.execute('''
local events
for _, f in ipairs(frames) do if f.scripts.OnEvent then events = f end end
events.scripts.OnEvent(events, 'ADDON_LOADED', 'LH_Stats')
local textures = 0
for _, f in ipairs(frames) do if f.kind == 'Texture' then textures = textures + 1 end end
assert(textures == 4) -- Preview, two stat icons, and resize handle; no Retail ammo cell.
local ev
for _, f in ipairs(frames) do if f.scripts.OnUpdate then ev = f end end
function tick() ev.scripts.OnUpdate(ev, 0.6) end
-- Defaults: locked, no drag, below the minimap, handle hidden.
assert(LH_StatsDB.locked and not LH_StatsFrame.mouse and not LH_StatsResizeHandle.visible)
assert(LH_StatsFrame.width == 160 and LH_StatsFrame.height == 20)
assert(LH_StatsFrame.point[2] == Minimap and LH_StatsFrame.point[5] == -10)
-- Dragging is ignored while locked.
LH_StatsFrame.scripts.OnDragStart(); assert(not LH_StatsFrame.movingNow)
-- LH_ExpBar sets width and anchor.
LH_ExpBarFrame = CreateFrame('Frame', 'LH_ExpBarFrame'); LH_ExpBarFrame.width = 200; LH_ExpBarFrame.visible = true
function LH_ExpBarFrame:IsShown() return self.visible end
SlashCmdList.LH_STATS('reset'); tick()
assert(LH_StatsFrame.width == 200 and LH_StatsFrame.point[2] == LH_ExpBarFrame and LH_StatsFrame.point[5] == -2)
-- Unlock: move and resize become available.
SlashCmdList.LH_STATS('unlock')
assert(LH_StatsFrame.mouse and LH_StatsResizeHandle.visible and LH_StatsFrame.preview.visible)
LH_StatsFrame.scripts.OnDragStart(); assert(LH_StatsFrame.movingNow)
LH_StatsFrame.scripts.OnDragStop(); assert(LH_StatsDB.position.x == 700 and LH_StatsDB.position.y == 400)
mouseDown = true; cursorX, cursorY = 100, -100
LH_StatsResizeHandle.scripts.OnMouseDown(nil, 'LeftButton')
cursorX, cursorY = 140, -110; tick()
assert(LH_StatsDB.widthFactor > 1 and LH_StatsDB.heightFactor == 1.5)
assert(LH_StatsFrame.width > 200 and LH_StatsFrame.height == 30)
mouseDown = false; tick()
-- Reset: back to the ExpBar width and 10 px below it.
SlashCmdList.LH_STATS('reset'); tick()
assert(LH_StatsDB.position == nil and LH_StatsFrame.width == 200 and LH_StatsFrame.height == 20)
assert(LH_StatsFrame.point[2] == LH_ExpBarFrame and LH_StatsFrame.point[5] == -2)
SlashCmdList.LH_STATS('lock'); assert(not LH_StatsFrame.mouse and not LH_StatsResizeHandle.visible)
-- Account-wide money: current character remains in alphabetical order and is counted only once.
events.scripts.OnEvent(events, 'PLAYER_ENTERING_WORLD')
assert(LH_StatsMoneyDB['Realm\\031Zara'].money == 12345)
assert(LH_StatsMoneyDB['Realm\\031Zara'].class == 'WARRIOR')
playerName, playerClass, playerMoney = 'Ada', 'MAGE', 25007
events.scripts.OnEvent(events, 'PLAYER_ENTERING_WORLD')
playerName, playerClass, playerMoney = 'Zara', 'WARRIOR', 10005
events.scripts.OnEvent(events, 'PLAYER_MONEY')
local moneyCell
for _, f in ipairs(frames) do if f.index == 1 then moneyCell = f end end
moneyCell.scripts.OnEnter(moneyCell)
assert(GameTooltip.lines[2][1] == 'Ada' and GameTooltip.lines[2][2]:find('2g', 1, true))
assert(GameTooltip.lines[2][3] == 0.2 and GameTooltip.lines[2][4] == 0.8)
assert(GameTooltip.lines[3][1] == '> Zara')
assert(GameTooltip.lines[3][3] == 0.8 and GameTooltip.lines[3][4] == 0.6)
assert(GameTooltip.lines[5][1] == 'Total' and GameTooltip.lines[5][2]:find('3g', 1, true))
assert(GameTooltip.lines[5][2]:find('|cffffd700', 1, true))
-- A stale record under a legacy key must not duplicate the current character.
LH_StatsMoneyDB.legacy = {name = 'Zara', realm = 'Realm', class = 'WARRIOR', money = 999999}
LH_StatsMoneyDB['Realm\\031Bert'] = {name = 'Bert', realm = 'Realm', class = 'MAGE', money = 1000000}
function UnitName() return nil end
function GetRealmName() return nil end
moneyCell.scripts.OnEnter(moneyCell)
assert(#GameTooltip.lines == 6)
assert(GameTooltip.lines[4][1] == '> Zara' and GameTooltip.lines[4][2]:find('1g', 1, true))
assert(GameTooltip.lines[6][1] == 'Total' and GameTooltip.lines[6][2]:find('103g', 1, true))
local function plainMoney(line)
  return (line[2]:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
end
local ada, bert, zara = plainMoney(GameTooltip.lines[2]), plainMoney(GameTooltip.lines[3]), plainMoney(GameTooltip.lines[4])
assert(ada:find('g') == bert:find('g') and bert:find('g') == zara:find('g'))
assert(ada:find('c') == zara:find('c'))
assert(bert:match('^%s*100g$') and not bert:find('s') and not bert:find('c'))
assert(zara:find('1g', 1, true) and zara:find('5c', 1, true) and not zara:find('s'))
assert(not zara:find('01g', 1, true) and not zara:find('05c', 1, true))
''')
print('PASS: LH_Stats layout and account-wide money tooltip')
