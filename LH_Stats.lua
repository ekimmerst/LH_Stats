local ADDON_NAME = ...
local bar, cells
local initialized = false
local freeSlots, totalSlots = 0, 0
local ammoCount = 0
local function RestorePosition()
    bar:ClearAllPoints()
    local p = LH_StatsDB.position
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        bar:SetPoint("CENTER", UIParent, "BOTTOMLEFT", p.x, p.y)
    elseif LH_ExpBarFrame and LH_ExpBarFrame:IsShown() then
        bar:SetPoint("TOP", LH_ExpBarFrame, "BOTTOM", 0, -3)
    else
        bar:SetPoint("TOP", Minimap or UIParent, "BOTTOM", 0, -31)
    end
end
local function SavePosition()
    local x, y = bar:GetCenter()
    if not x or not y then return end
    local scale = bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
    LH_StatsDB.position = { x = x * scale, y = y * scale }
    RestorePosition()
end
local function Layout()
    local source = LH_ExpBarFrame or Minimap
    if not source then return end
    local width = source:GetWidth() * source:GetEffectiveScale() / bar:GetEffectiveScale()
    if width <= 0 then return end
    bar:SetWidth(width)
    -- Spread the stats across the bar; shrink text only if space runs out.
    local textWidths, totalTextWidth = {}, 0
    for i, cell in ipairs(cells) do
        cell.text:SetScale(1)
        textWidths[i] = math.max(1, cell.text:GetStringWidth())
        totalTextWidth = totalTextWidth + textWidths[i]
    end
    local available = math.max(2, width - 18 * #cells - 8)
    local textScale = math.min(1, available / totalTextWidth)
    local gap = math.max(0, (width - 18 * #cells - totalTextWidth * textScale) / (#cells - 1))
    for i, cell in ipairs(cells) do
        cell:SetWidth(18 + textWidths[i] * textScale)
        cell:ClearAllPoints()
        if i == 1 then
            cell:SetPoint("LEFT", bar, "LEFT", 0, 0)
        else
            cell:SetPoint("LEFT", cells[i - 1], "RIGHT", gap, 0)
        end
        cell.text:SetScale(textScale)
    end
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
    local ammoSlot = GetInventorySlotInfo("AmmoSlot") or 0
    local ammoTexture = GetInventoryItemTexture("player", ammoSlot)
    -- The ammo slot reports the selected ammunition's total across carried bags.
    -- An empty slot can report 1, so check its texture before using the count.
    ammoCount = ammoTexture and (GetInventoryItemCount("player", ammoSlot) or 0) or 0
    cells[3].icon:SetTexture(ammoTexture or "Interface\\Icons\\INV_Ammo_Arrow_02")
    cells[3].text:SetText(tostring(ammoCount))
    cells[3].text:SetTextColor(1, ammoCount == 0 and 0.25 or 1, ammoCount == 0 and 0.2 or 1)
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
    GameTooltip:AddLine("Hold the left mouse button and drag to move", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end
local function CreateBar()
    LH_StatsDB = type(LH_StatsDB) == "table" and LH_StatsDB or {}
    bar = CreateFrame("Frame", "LH_StatsFrame", UIParent)
    bar:SetSize(140, 20)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    local function startDrag() GameTooltip:Hide(); bar:StartMoving() end
    local function stopDrag() bar:StopMovingOrSizing(); SavePosition() end
    bar:SetScript("OnDragStart", startDrag)
    bar:SetScript("OnDragStop", stopDrag)
    cells = {}
    local icons = { "Interface\\MoneyFrame\\UI-GoldIcon", "Interface\\Icons\\INV_Misc_Bag_08", "Interface\\Icons\\INV_Ammo_Arrow_02" }
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
        cell.text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        cell.text:SetShadowColor(0, 0, 0, 1)
        cell.text:SetShadowOffset(1, -1)
        cells[i] = cell
    end
    cells[1].text:SetTextColor(1, 0.82, 0)
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
    elapsedSinceCheck = elapsedSinceCheck + elapsed
    if elapsedSinceCheck >= 0.5 then
        elapsedSinceCheck = 0
        if initialized then Layout() end
    end
end)
SLASH_LH_STATS1 = "/lh_stats"
SlashCmdList.LH_STATS = function(message)
    if not initialized then return end
    if (message or ""):lower():match("^%s*reset%s*$") then
        LH_StatsDB.position = nil
        RestorePosition()
        UpdateStats()
    else
        print("LH_Stats: /lh_stats reset - Reset position. Hold the left mouse button and drag to move.")
    end
end
