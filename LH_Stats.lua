local ADDON_NAME = ...
local HEIGHT = 20
local bar, cells, handle, resizing, moving
local Addon = {}
LH_Stats = Addon
local initialized = false
local freeSlots, totalSlots = 0, 0
local ammoCount = 0
local hasAmmoSlot = (not WOW_PROJECT_MAINLINE or WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)
    and GetInventorySlotInfo and GetInventorySlotInfo("AmmoSlot") ~= nil
local showAmmo
local function StandardWidth()
    local source = LH_ExpBarFrame or Minimap
    if not source then return 140 end
    return source:GetWidth() * source:GetEffectiveScale() / bar:GetEffectiveScale()
end
local function UpdateSize()
    bar:SetSize(math.max(70, StandardWidth() * LH_StatsDB.widthFactor), HEIGHT * LH_StatsDB.heightFactor)
end
local function RestorePosition()
    bar:ClearAllPoints()
    local p = LH_StatsDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    elseif LH_ExpBarFrame and LH_ExpBarFrame:IsShown() then
        bar:SetPoint("TOP", LH_ExpBarFrame, "BOTTOM", 0, -2)
    else
        local cluster = MinimapCluster
        local container = cluster and cluster.MinimapContainer
        bar:SetPoint("TOP", container and container.PlayerCoords or Minimap or UIParent, "BOTTOM", 0, -10)
    end
end
local function SavePosition()
    local x, y = bar:GetCenter()
    if not x or not y then return end
    local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
    LH_StatsDB.position = { x = x * scale, y = y * scale }
    RestorePosition()
end
local function StopMoving()
    bar:StopMovingOrSizing()
    if moving then moving = nil; SavePosition() end
end
local function FinishResize()
    if resizing then
        resizing = nil
        SavePosition()
        if Addon.RefreshSettings then Addon:RefreshSettings() end
    end
end
local function Layout()
    UpdateSize()
    local width = bar:GetWidth()
    if width <= 0 then return end
    local visibleCells = { cells[1], cells[2] }
    if showAmmo then visibleCells[3] = cells[3] end
    -- Spread the stats across the bar; shrink text only if space runs out.
    local textWidths, totalTextWidth = {}, 0
    for i, cell in ipairs(visibleCells) do
        cell.text:SetScale(1)
        textWidths[i] = math.max(1, cell.text:GetStringWidth())
        totalTextWidth = totalTextWidth + textWidths[i]
    end
    local available = math.max(2, width - 18 * #visibleCells - 8)
    local textScale = math.min(1, available / totalTextWidth)
    local gap = math.max(0, (width - 18 * #visibleCells - totalTextWidth * textScale) / (#visibleCells - 1))
    for i, cell in ipairs(visibleCells) do
        cell:SetSize(18 + textWidths[i] * textScale, bar:GetHeight())
        cell:ClearAllPoints()
        if i == 1 then
            cell:SetPoint("LEFT", bar, "LEFT", 0, 0)
        elseif #visibleCells == 2 then
            cell:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
        else
            cell:SetPoint("LEFT", visibleCells[i - 1], "RIGHT", gap, 0)
        end
        cell.text:SetScale(textScale)
    end
end
local function IsThrownWeaponEquipped()
    local rangedSlot = GetInventorySlotInfo("RangedSlot") or INVSLOT_RANGED
    if not rangedSlot then return false end
    local item = GetInventoryItemID and GetInventoryItemID("player", rangedSlot)
    item = item or GetInventoryItemLink("player", rangedSlot)
    if not item then return false end
    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if getInstant then
        local _, _, _, equipLoc, _, classID, subClassID = getInstant(item)
        -- Thrown weapons are weapon class 2, subclass 16, even if their equip type differs.
        if equipLoc == "INVTYPE_THROWN" or (classID == 2 and subClassID == 16) then return true end
    end
    if GetItemInfo then
        local _, _, _, _, _, _, _, _, equipLoc, _, _, classID, subClassID = GetItemInfo(item)
        return equipLoc == "INVTYPE_THROWN" or (classID == 2 and subClassID == 16)
    end
    return false
end

local function UpdateStats()
    if not initialized then return end
    local money = GetMoney() or 0
    cells[1].text:SetText(string.format("|cffffd700%dg|r |cffc7c7cf%ds|r |cffeda55f%dc|r",
        math.floor(money / 10000), math.floor(money / 100) % 100, money % 100))
    freeSlots, totalSlots = 0, 0
    local getSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local getFree = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
    for bag = 0, (NUM_BAG_SLOTS or 4) do
        local free, family = getFree(bag)
        if bag == 0 or family == 0 then
            totalSlots = totalSlots + (getSlots(bag) or 0)
            freeSlots = freeSlots + (free or 0)
        end
    end
    cells[2].text:SetText(tostring(freeSlots))
    cells[2].text:SetTextColor(1, freeSlots == 0 and 0.25 or 1, freeSlots == 0 and 0.2 or 1)
    if cells[3] then
        showAmmo = not IsThrownWeaponEquipped()
        cells[3]:SetShown(showAmmo)
    end
    if showAmmo then
        local ammoSlot = GetInventorySlotInfo("AmmoSlot")
        local ammoTexture = GetInventoryItemTexture("player", ammoSlot)
        -- The ammo slot reports the selected ammunition's total across carried bags.
        ammoCount = ammoTexture and (GetInventoryItemCount("player", ammoSlot) or 0) or 0
        cells[3].icon:SetTexture(ammoTexture or "Interface\\Icons\\INV_Ammo_Arrow_02")
        cells[3].text:SetText(tostring(ammoCount))
        cells[3].text:SetTextColor(1, ammoCount == 0 and 0.25 or 1, ammoCount == 0 and 0.2 or 1)
    end
    Layout()
end
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
    if self.index == 1 then
        GameTooltip:AddLine("Money", 1, 0.82, 0)
        local money = GetMoney() or 0
        GameTooltip:AddLine(string.format("%d gold, %d silver, %d copper", math.floor(money / 10000), math.floor(money / 100) % 100, money % 100), 1, 1, 1)
    elseif self.index == 2 then
        GameTooltip:AddLine("Bag slots", 1, 0.82, 0)
        GameTooltip:AddLine(string.format("%d free / %d total · %d occupied", freeSlots, totalSlots, totalSlots - freeSlots), 1, 1, 1)
        GameTooltip:AddLine("Backpack and regular bags only (excludes specialty bags)", 0.7, 0.7, 0.7)
    else
        GameTooltip:AddLine("Ammo", 1, 0.82, 0)
        GameTooltip:AddLine(string.format("%d remaining", ammoCount), 1, 1, 1)
        GameTooltip:AddLine("Currently selected ammunition in carried bags", 0.7, 0.7, 0.7)
    end
    if not LH_StatsDB.locked then GameTooltip:AddLine("Hold the left mouse button and drag to move", 0.7, 0.7, 0.7) end
    GameTooltip:Show()
end
local function CreateBar()
    local _, class = UnitClass("player")
    showAmmo = hasAmmoSlot and (class == "HUNTER" or class == "ROGUE" or class == "WARRIOR")
    LH_StatsDB = type(LH_StatsDB) == "table" and LH_StatsDB or {}
    if LH_StatsDB.locked == nil then LH_StatsDB.locked = true end
    for _, key in ipairs({"widthFactor", "heightFactor"}) do
        local value = LH_StatsDB[key]
        LH_StatsDB[key] = type(value) == "number" and math.max(0.5, math.min(2, value)) or 1
    end
    LH_LayoutProfiles:Register(ADDON_NAME, LH_StatsDB, LH_StatsDB,
        {"position", "widthFactor", "heightFactor", "locked"})
    bar = CreateFrame("Frame", "LH_StatsFrame", UIParent)
    bar:SetSize(140, HEIGHT)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(not LH_StatsDB.locked)
    bar:RegisterForDrag("LeftButton")
    -- A faint backdrop makes the otherwise transparent bar visible while unlocked.
    bar.preview = bar:CreateTexture(nil, "BACKGROUND")
    bar.preview:SetAllPoints()
    bar.preview:SetColorTexture(0, 0, 0, 0.5)
    bar.preview:SetShown(not LH_StatsDB.locked)
    local function startDrag()
        if LH_StatsDB.locked or resizing then return end
        GameTooltip:Hide(); moving = true; bar:StartMoving()
    end
    local function stopDrag() StopMoving() end
    bar:SetScript("OnDragStart", startDrag)
    bar:SetScript("OnDragStop", stopDrag)
    bar:SetScript("OnHide", function() StopMoving(); FinishResize() end)
    cells = {}
    local icons = { "Interface\\MoneyFrame\\UI-GoldIcon", "Interface\\Icons\\INV_Misc_Bag_08" }
    if showAmmo then icons[3] = "Interface\\Icons\\INV_Ammo_Arrow_02" end
    for i = 1, #icons do
        local cell = CreateFrame("Frame", nil, bar)
        cell.index = i
        cell:SetHeight(20)
        cell:EnableMouse(true)
        cell:RegisterForDrag("LeftButton")
        cell:SetScript("OnDragStart", startDrag)
        cell:SetScript("OnDragStop", stopDrag)
        cell:SetScript("OnEnter", ShowTooltip)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local icon = cell:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", 1, 0)
        icon:SetTexture(icons[i])
        cell.icon = icon
        if i > 1 then icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
        cell.text = cell:CreateFontString(nil, "OVERLAY")
        cell.text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        local style = ObjectiveTrackerLineFont or GameFontHighlightSmall
        if style then
            cell.text:SetFontObject(style)
            local font, _, flags = style:GetFont()
            cell.text:SetFont(font, 10, flags or "")
        else
            cell.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "")
            cell.text:SetShadowColor(0, 0, 0, 1)
            cell.text:SetShadowOffset(1, -1)
        end
        cells[i] = cell
    end
    cells[1].text:SetTextColor(1, 0.82, 0)
    handle = CreateFrame("Button", "LH_StatsResizeHandle", bar)
    handle:SetSize(16, 16)
    handle:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -4)
    handle:SetFrameLevel(bar:GetFrameLevel() + 10)
    handle:EnableMouse(true)
    local circle = handle:CreateTexture(nil, "ARTWORK")
    circle:SetAllPoints()
    circle:SetTexture("Interface\\Buttons\\UI-RadioButton")
    circle:SetTexCoord(0.25, 0.5, 0, 1)
    handle:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or LH_StatsDB.locked then return end
        StopMoving()
        local x, y = GetCursorPosition()
        local scale = bar:GetEffectiveScale()
        local parentScale = UIParent:GetEffectiveScale()
        local left, top = bar:GetLeft(), bar:GetTop()
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * scale / parentScale, top * scale / parentScale)
        resizing = {x = x / scale, y = y / scale, width = LH_StatsDB.widthFactor,
            height = LH_StatsDB.heightFactor, base = StandardWidth()}
    end)
    handle:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then FinishResize() end end)
    handle:SetScript("OnHide", FinishResize)
    handle:SetShown(not LH_StatsDB.locked)
    initialized = true
    RestorePosition()
    UpdateStats()
end
local events = CreateFrame("Frame")
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "BAG_UPDATE", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == ADDON_NAME and not initialized then CreateBar() end
        return
    end
    if not initialized then return end
    UpdateStats()
    if event == "PLAYER_ENTERING_WORLD" and not LH_StatsDB.position then RestorePosition() end
end)
local elapsedSinceCheck = 0
events:SetScript("OnUpdate", function(_, elapsed)
    if resizing then
        if not IsMouseButtonDown("LeftButton") then FinishResize()
        else
            local x, y = GetCursorPosition()
            local scale = bar:GetEffectiveScale()
            LH_StatsDB.widthFactor = math.max(0.5, math.min(2, resizing.width + (x / scale - resizing.x) / resizing.base))
            LH_StatsDB.heightFactor = math.max(0.5, math.min(2, resizing.height + (resizing.y - y / scale) / HEIGHT))
            Layout()
        end
    end
    elapsedSinceCheck = elapsedSinceCheck + elapsed
    if elapsedSinceCheck >= 0.5 then
        elapsedSinceCheck = 0
        if initialized then Layout() end
    end
end)
SLASH_LH_STATS1 = "/lh_stats"
function Addon:IsUnlocked() return LH_StatsDB and LH_StatsDB.locked == false or false end
function Addon:GetSizeFactor(key) return LH_StatsDB and LH_StatsDB[key] or 1 end
function Addon:SetSizeFactor(key, value)
    if not initialized or (key ~= "widthFactor" and key ~= "heightFactor") or type(value) ~= "number" then return end
    FinishResize()
    LH_StatsDB[key] = math.max(0.5, math.min(2, value))
    Layout()
    if self.RefreshSettings then self:RefreshSettings() end
end
SlashCmdList.LH_STATS = function(message)
    if not initialized then return end
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "lock" or command == "unlock" then
        StopMoving()
        FinishResize()
        GameTooltip:Hide()
        LH_StatsDB.locked = command == "lock"
        bar:EnableMouse(not LH_StatsDB.locked)
        bar.preview:SetShown(not LH_StatsDB.locked)
        handle:SetShown(not LH_StatsDB.locked)
        print(LH_StatsDB.locked and "LH_Stats: Position locked." or "LH_Stats: Drag the bar to move; drag the circle to resize.")
    elseif command == "reset" then
        StopMoving()
        FinishResize()
        LH_StatsDB.position = nil
        LH_StatsDB.widthFactor, LH_StatsDB.heightFactor = 1, 1
        RestorePosition()
        UpdateStats()
    else
        print("LH_Stats: /lh_stats unlock | lock | reset")
    end
    if Addon.RefreshSettings then Addon:RefreshSettings() end
end
