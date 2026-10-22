local addonName = ...
local Addon = LH_Stats
local variables = {}

function Addon:RefreshSettings()
    if self.notifying or not Settings or not Settings.NotifyUpdate then return end
    self.notifying = true
    for _, variable in ipairs(variables) do Settings.NotifyUpdate(variable) end
    self.notifying = false
end

local function Command(message) SlashCmdList.LH_STATS(message) end
local function Header(layout, text)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end
local function Defaults()
    Command("lock")
    Command("reset")
end

local function Build(category, layout)
    Header(layout, "Position and size")
    local variable = "LH_Stats_unlocked"
    variables[#variables + 1] = variable
    local unlocked = Settings.RegisterProxySetting(category, variable, "boolean", "Unlock the stats bar", false,
        function() return Addon:IsUnlocked() end,
        function(value) Command(value and "unlock" or "lock") end)
    Settings.CreateCheckbox(category, unlocked,
        "Left-drag the bar to move it. Drag the small circle below its right edge to resize width and height. Disable to lock the position. Saved per character.")
    for _, option in ipairs({{key = "widthFactor", label = "Bar width"}, {key = "heightFactor", label = "Bar height"}}) do
        local key = option.key
        local name = "LH_Stats_" .. key
        variables[#variables + 1] = name
        local setting = Settings.RegisterProxySetting(category, name, "number", option.label, 100,
            function() return Addon:GetSizeFactor(key) * 100 end,
            function(value) Addon:SetSizeFactor(key, value / 100) end)
        local options = Settings.CreateSliderOptions(50, 200, 5)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return string.format("%.0f%%", value) end)
        Settings.CreateSlider(category, setting, options,
            (key == "widthFactor" and "Width relative to LH_ExpBar (or the minimap); minimum width is 70 UI units." or "Height relative to the default 20 UI units.") .. " Font size stays at 10 points. Saved per character.")
    end
    layout:AddInitializer(CreateSettingsButtonInitializer("Restore the default size and position", "Reset layout",
        function() Command("reset") end,
        "Match the width of LH_ExpBar, restore the default height and place the bar 2 pixels below LH_ExpBar. Keep the current lock setting.", true))
    EventRegistry:RegisterCallback("Settings.CategoryDefaulted", function(_, selected)
        if selected == category then Defaults() end
    end, Addon)
    EventRegistry:RegisterCallback("Settings.Defaulted", Defaults, Addon)
end

LH_Tweaks:RegisterModule(addonName, "LH Stats", Build)
