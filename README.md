# TrinketCDs

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

![Showcase](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_main.png)

- Full database of WotLK/TBC trinkets.
- Ashen rings, cloak, weapon, hands, boots and belt enchants.
- Works both on 3.3 and 3.4 WotLK versions.
- Doesn't depend on combat log.
- Buff duration, stacks, cooldown.
- Cooldown on login and after inventory change.
- Has built-in cooldown text (use [OmniCC](https://www.curseforge.com/wow/addons/omni-cc/files/454434) as alternative).
- Caches cooldown even if trinket was unequiped after proc (useful if server has different iCD on equip).

## Changelog

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

<details><summary><b>Changelog</b></summary>
<details><summary>2.2.0</summary>

    Moved all "Show" checkboxes into main options panel

    Functions used in combat are now local for better perfomance

    Fixed cooldown for enchants

    Added TBC trinkets

    Fixed a bug where ring frame was hidden when top ring slot was empty

    Fixed a bug where ring frame went on cooldown, if a ring was changed in a different slot

    Fixed a bug where item frame whouldn't be updated, if a new equiped item has the same ID but different enchant

    WotLK Classic ready:

    Removed CD swipe texture

    Fixed critical error on addon load, that bricked whole addon

    - Border now requires BackdropTemplate as default template

    Fixed a bug where the frame border was not updating in real time from changing settings

    - SetBackdrop now requires a new table as argument instead of table reference

    Fixed desaturation

    - SetDesaturated now requires true/false instead of 1/nil

    Fixed item reequip with ctrl

    - PLAYER_EQUIPMENT_CHANGED now fired with false/true instead or 1/nil

    - PickupInventoryItem() only checks dafault bag instead of all 5
**Full Changelog:** [2.1.0...2.2.0](https://github.com/Ridepad/TrinketCDs/compare/2.1.0...2.2.0)
</details>
<details><summary>2.1.0</summary>

    Improved button functionality

    Chicken swap works without any additional set up

    Fixed wrong weapon enchantments IDs

    Added Berserking

    Fixed bug on 1st game launch without item cache from server
**Full Changelog:** [2.0.2...2.1.0](https://github.com/Ridepad/TrinketCDs/compare/2.0.2...2.1.0)
</details>
<details><summary>2.0.2</summary>

    Fixed settings defaults
**Full Changelog:** [2.0.1...2.0.2](https://github.com/Ridepad/TrinketCDs/compare/2.0.1...2.0.2)
</details>

<details><summary>2.0.1</summary>

    Better built-in cooldown text

    Fixed chicken swap feature doesn't swap back to previous item after use, if chicken was reequiped

    Fixed visibility out of combat after wipe

    Removed unnecessary code
**Full Changelog:** [2.0.0...2.0.1](https://github.com/Ridepad/TrinketCDs/compare/2.0.0-beta.2...2.0.1)
</details>

<details><summary>2.0.0</summary>

    Added ring, cloak, weapon, boots, belt enchants

    Added item cooldown text.

    Added position settings for each frame.

    Added option to hide item level.

    Added option to hide out of combat.

    Added option to hide if ready.

    Added option to click to use.

    Added option to change stacks text to the bottom.

    Improved min/max values for x,y frame positions.
**Full Changelog:** [1.4.0...2.0.0](https://github.com/Ridepad/TrinketCDs/compare/1.4.0...2.0.0-beta.2)
</details>
</details>

## Install

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

- [Download](https://github.com/Ridepad/TrinketCDs/releases/latest).
- Extract `TrinketCDs` folder into `<WoW Folder>/Interface/Addons/` folder.

## Preview

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

### All items preview

![Showcase all](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_all.png)

### Chicken swap preview

Ctrl+Right mouse click to swap to chicken, left mouse click to use. (Ctrl+Right click again to swap back)
> Automatically swaps back to previous trinket after chicken is used, regardless of how chicken was equipped.

![Showcase chicken](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_chicken.gif)

### Left mouse click preview

Default iCD vs 30 sec forced

#### Ctrl-click

Reequips trinket to force it's cooldown.

![Showcase swap with control](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_ctrl.gif)
![Showcase swap with control and 30](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_ctrl30.gif)

#### Shift-click

Swaps trinkets places to force cooldown for both.

![Showcase swap with shift](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_shift.gif)
![Showcase swap with shift and 30](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_shift30.gif)

#### Alt-click

Swaps for trinket with same name, but different ilvl (if exists in bag).

![Showcase swap with alt](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_alt.gif)
![Showcase swap with alt and 30](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_swap_alt30.gif)

## Perfomance

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

CPU usage from LoD kill

![Showcase cpu usage](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_cpu_usage.png)

## Options

**Fast jump:** [Changelog](#changelog) | [Install](#install) | [Preview](#preview) | [Perfomance](#perfomance) | [Options](#options)

Check in game options for settings

![Showcase options 1](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_options1.png)
![Showcase options 2](https://raw.githubusercontent.com/Ridepad/TrinketCDs/main/showcase/showcase_options2.png)
