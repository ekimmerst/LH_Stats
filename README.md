# LH_Stats

Version: 1.1.0

**A compact World of Warcraft addon for WoW Forever Beta.**

LH_Stats displays your gold, silver, copper, free bag slots, and remaining ammunition in a transparent bar below the minimap.

## Features

- Color-coded money display with a coin icon.
- Free slots in the backpack and regular bags; excludes specialty bags, the bank, and keyring.
- Remaining selected ammunition with its item icon, including ammunition carried in quivers and ammo pouches.
- Automatic updates and tooltips with additional details.
- Lockable bar: unlock it to move it and resize width and height; position and size are saved per character.
- Matches the width of LH_ExpBar or the minimap. LH_ExpBar is optional.

## Installation

1. Name the addon folder `LH_Stats`.
2. Copy it to `World of Warcraft/<game-version>/Interface/AddOns/`. The files `LH_Stats.toc` and `LH_Stats.lua` must be directly inside the `LH_Stats` folder.
3. Restart the game and enable **LH_Stats** in the addon list on the character selection screen.

## Usage

The bar automatically appears below LH_ExpBar, if available, or below the minimap. The bag number shows only free slots. Ammo shows the remaining count of your currently selected ammunition, or `0` if none is selected.

Open WoW Settings > AddOns > LH Tweaks > LH Stats. **Unlock the stats bar** shows a preview backdrop and a small circle below the right edge: left-drag the bar to move it, drag the circle to resize width and height. The page also has width/height sliders (50-200%) and **Reset layout**, which matches the width of LH_ExpBar (or the minimap), restores the default height and places the bar 5 pixels below LH_ExpBar. The bar is locked by default.

```text
/lh_stats unlock | lock | reset
```

## Compatibility

Designed for **WoW Forever Beta**, interface version **16001**. Requires LH_Tweaks; LH_ExpBar is optional.

## Upgrading from MiniStats

Replace the old folder with **LH_Stats** and fully restart WoW. Do not enable both versions together. The reset command is now `/lh_stats reset`.

To retain your position, close WoW and back up each character's `WTF/Account/<account>/<realm>/<character>/SavedVariables/MiniStats.lua` file. Copy it to `LH_Stats.lua` in the same SavedVariables folder, then change `MiniStatsDB` to `LH_StatsDB` inside the copy. Migrate before first using the renamed addon; do not overwrite an existing `LH_Stats.lua` containing settings you want to keep. Without migration, the display uses its default position.

## Changelog

### 1.1.0 - 2026-10-21

- Added LH Tweaks grouping (title, group, part-of metadata) and the shared LH Tweaks icon (`Media/Icon`).
- Added a native LH Stats settings page: unlock/lock, width and height sliders, resize circle and Reset layout (LH_ExpBar width, 5 pixels below it). The bar is now locked by default; `/lh_stats unlock` and `lock` were added.

### 1.0.2 - 2026-10-21

- Matched the money, bag-slot and ammunition text font and shadow to LH_Skills.

### 1.0.1 - 2026-10-21

- Renamed MiniStats to LH_Stats, including the folder, Lua/TOC and icon filenames, metadata, icon path, frame name, chat messages and saved-variable table.
- Changed the reset command to `/lh_stats reset`.
- Updated the optional LH_ExpBar integration and English documentation, including saved-position migration instructions.

## Required core addon

Install and enable **LH_Tweaks** alongside this addon. LH_Tweaks is the shared LiteHawk configuration host and must load first. CurseForge releases must list LH_Tweaks as a required dependency so the client installs it automatically.
