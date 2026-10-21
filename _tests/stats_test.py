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
UIParent = CreateFrame('Frame'); Minimap = CreateFrame('Frame'); Minimap.width = 160
GameTooltip = CreateFrame('Frame')
function GameTooltip:IsOwned() return false end
cursorX, cursorY, mouseDown = 0, 0, false
function GetCursorPosition() return cursorX, cursorY end
function IsMouseButtonDown() return mouseDown end
function GetMoney() return 12345 end
function GetInventorySlotInfo() return 0 end
function GetInventoryItemTexture() return nil end
function GetContainerNumSlots() return 16 end
function GetContainerNumFreeSlots() return 4, 0 end
''')
lua.execute((addon / 'LH_Stats.lua').read_text(encoding='utf-8'), 'LH_Stats')
lua.execute('''
local events
for _, f in ipairs(frames) do if f.scripts.OnEvent then events = f end end
events.scripts.OnEvent(events, 'ADDON_LOADED', 'LH_Stats')
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
assert(LH_StatsFrame.width == 200 and LH_StatsFrame.point[2] == LH_ExpBarFrame and LH_StatsFrame.point[5] == -5)
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
assert(LH_StatsFrame.point[2] == LH_ExpBarFrame and LH_StatsFrame.point[5] == -5)
SlashCmdList.LH_STATS('lock'); assert(not LH_StatsFrame.mouse and not LH_StatsResizeHandle.visible)
''')
print('PASS: LH_Stats lock/unlock, move, resize and reset below LH_ExpBar')
