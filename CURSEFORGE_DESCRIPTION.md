# ItemRack — Universal Classic Edition

## Overview

**ItemRack** is a context menu-based inventory manager for quickly swapping equipment and managing gear sets. Create sets for any scenario—PvP, Tanking, Healing, resist fights—and swap with a single click, keybind, or automatically via event triggers.

One download supports **Classic Era, Hardcore, Season of Discovery, Burning Crusade Classic Anniversary, and WoW Forever/Camelot**. Install the same `ItemRack-universal` archive on every supported client; the shared compatibility layer adapts to each client's APIs at runtime.

The archive contains two required addon folders: `ItemRack` and the load-on-demand `ItemRackOptions`. These are two modules of one addon distribution, not separate client releases.

---

## 🚀 Recent Updates

### UI & Quality of Life Improvements

* **Tooltips System Overhaul**: 
  * Options to disable ItemRack's custom tooltips entirely if preferred.
  * **Tiny Tooltips on Quick Access Only**: Keeps your main Set button detailed while shrinking individual gear slot tooltips.
  * Suppresses duplicate overlapping item comparison tooltips from the default WoW UI when holding Shift.
* **Audio System Enhancements**: 
  * Dedicated options to mute all automatic swap sounds.
  * **LibSoundIndex Integration (WIP)**: ItemRack optionally supports LibSoundIndex for surgical equipment-sound muting. If it is not installed, swaps use normal sound; ItemRack does not change the game's global SFX setting.
* **Menu Mutual Exclusivity**: Features like `Menu on Shift` and `Menu on right click` are now mutually exclusive and auto-toggle each other to prevent control conflicts.
* **Shift-Click Equip via Bank**: Holding Shift while clicking an item in an ItemRack popout menu with the bank open will properly equip it instead of depositing it.
* **Diagnostic Debugging Dump (`/itemrack dump`)**: A native diagnostic system built directly into the UI. No more zipping `WTF` folders! Toggle `/itemrack debug` to start a **silent background trace** (holds up to 5,000 lines of combat/UI events). Replicate your bug, and type `/itemrack dump` to instantly extract the exact Event Stack, SV State, Audit History, and Combat Locks directly to your clipboard for easy bug reporting. Want to see the logs in real-time? Use `/itemrack debug chat` to print them to your chat frame.
* **SavedVariables Auto-Repair**: On every login and reload, ItemRack automatically scans your character's saved data for corruption—circular set references, orphaned event stacks, invalid queue slots, and obsolete settings. Issues are silently auto-fixed in the background and a one-line chat notice appears if any repairs were made. Detailed repair logs are persisted in your SavedVariables (`ItemRackUser.LastRepair`) so they survive restarts and can be included in bug reports via `/itemrack dump`. Run `/itemrack debug audit` at any time to trigger a manual scan with full chat output.

---

## ⚠️ FAQ: Flyout Menu Opening on the Wrong Side?

Several users have reported that character sheet flyout menus open in the wrong direction (e.g., left-side slots opening to the left and overlapping the screen edge, or right-side slots going the wrong way). **This is configurable!**

Open **ItemRack Options** (`/itemrack opt`) and look under the **"Character sheet menus"** section. You'll find two checkboxes:

* **"Left slots: menu on right"** — Flips left-side slots (Head, Neck, Shoulder, Back, Chest, Shirt, Tabard, Wrist) to show menus on the **RIGHT**.
* **"Right slots: menu on left"** — Flips right-side slots (Hands, Waist, Legs, Feet, Rings, Trinkets) to show menus on the **LEFT**.

Toggle whichever option fixes the direction for your setup. Bottom weapon slots (Main Hand, Off Hand, Ranged) always dock vertically and are unaffected.

---

## Validated Base Version

This adaptation is based on the **4.23 release by Rottenbeer** (released November 28th, 2024), updated to support the unique requirements of the Anniversary client.

### References to Previous Versions

We stand on the shoulders of giants:

* **Original Base Version**: [ItemRack on CurseForge](https://www.curseforge.com/wow/addons/itemrack)
* **WoW Classic Version**: [ItemRack Classic on CurseForge](https://www.curseforge.com/wow/addons/itemrack-classic/)

---

## Shared compatibility layer

Classic clients now expose different combinations of legacy functions, modern namespaces, protected values, and UI frames. This release keeps those differences behind one tested code path instead of maintaining separate Forever and TBC editions.

### Core Compatibility Fixes

* **"On-Use" Item Functionality Restored**: Solved "Action Blocked" errors by implementing **Secure Item Attributes** (`type="item"`). Trinkets and on-use items work directly from the rack without error, just like standard action bar buttons.
* **API Compatibility Layer**: Full support for migrated WoW APIs including `C_Container`, `C_Item`, and `C_AddOns`. Cooldown tracking displays correctly on buttons.
* **No More Yellow Triangles**: Fixed the graphical glitch in the Options menu caused by missing Atlas textures in the Anniversary client.
* **Secure Button Templates**: Rewrote button initialization with a custom icon layering system, ensuring buttons look correct and function securely.

### Dual Spec Support

* Automatically swaps gear sets when you change talent specializations.
* UI adapts to show spec options only if Dual Spec is learned.
* Spec checkboxes are dynamically labeled with your talent tree name (e.g., "Holy", "Arms").

### Blizzard Keybinding Integration

* All 20 equipment slots are registered in the Blizzard Keybindings panel under **AddOns > ItemRack**.
* Each slot has a descriptive label (e.g., "Head (Slot 1)", "Off Hand / Shield / Held In Off-hand (Slot 17)").
* Keybinds are saved immediately and persist through reloads.

### Improved Cooldown Display

* **Large Numbers mode**: Cooldown text uses `mm:ss` / `h:mm` format with dynamic coloring—white above 60s, yellow under 60s, red under 5s.
* WoW's native countdown numbers are suppressed on ItemRack buttons to prevent duplicate text.
* **Stun & CC Immunity**: Cooldown indicator "swirls" on Quick Access buttons and popout menus are no longer falsely hidden by the game engine when your character is stunned or feared.

### Event System Reliability

* Buff events (Mounting, Drinking) properly track active state and cleanly revert gear when ending.
* Nested event transitions (e.g., Drinking ending while Mounted) correctly restore the original gear state.
* Stance events (Shapeshifting, Ghost Wolf) reliably revert gear even when the equipment API reports inconsistencies.
* **Manual Override Protection**: If you manually swap gear while an event is active (like equipping a PvP flag-carry set before grabbing the flag), ItemRack will strictly respect your choice and won't aggressively fight to unequip or re-equip the background gear.

### Tooltip Set Info

* "Show set info in tooltips" now reliably displays which sets contain an item when hovering in your bags or character panel.
* Uses exact item-field matching—correctly differentiates items with different enchants or gems.
* Internal system sets are hidden from tooltips.

### Queue System

* **Per-Set Auto-Queue**: Each gear set now automatically saves which slot queues are enabled when created. Swapping sets cleanly activates or deactivates queues based on what the incoming set requires.
* Fixed item duplication and multiple stop markers in queue lists.
* Right-click queue cycling works reliably, including during combat (queued for after combat ends).
* Combat queue shows overlay icons on slot buttons indicating pending swaps.
* Advanced Queue configuration (Delay and Keep flags) accurately flow through the queue system.

### UI Polish

* **Smart Menu Docking**: Left-side character sheet slots default to opening menus to the left, and right-side slots open to the right. If this automatic direction is wrong for your setup, you can override it per-side in **Options** (under "Character sheet menus"):
  * **"Left slots: menu on right"** — Flips left-side slots (Head, Neck, Shoulder, Back, Chest, Shirt, Tabard, Wrist) to show menus on the RIGHT instead of the left.
  * **"Right slots: menu on left"** — Flips right-side slots (Hands, Waist, Legs, Feet, Rings, Trinkets) to show menus on the LEFT instead of the right.
  * Bottom weapon slots (Main Hand, Off Hand, Ranged) always dock vertically and are unaffected by these settings.
* Hotkey text renders in subtle gray with proper hide/show behavior.
* Set icon and label accurately reflect the equipped set after combat, spec changes, and event transitions.

---

## Core Features

* **Quick Swapping**: Hover over a slot on your character sheet to pop out a menu of available items for that slot.
* **Sets**: Create and save gear sets and swap them with a single click or keybind.
* **Events**: Automate gear swaps based on events (mounting, entering a zone, shapeshifting, drinking, etc.).
* **Auto-Queue**: Automatically cycle items based on cooldown availability—equip your best-in-slot trinket as soon as the current one goes on cooldown.
* **Combat Queue**: Swaps attempted during combat are queued and executed automatically when combat ends.

---

## Complete Control Scheme

### 📌 Character Sheet Controls

| Action | Effect |
|--------|--------|
| **Alt+Click** any equipment slot | Creates an on-screen "Quick Access" button for that slot |
| **Alt+Click** the Character Model | Creates a "Set Button" (slot 20) for gear set management |
| **Hover** over an equipment slot | Opens the item selection flyout menu (if enabled) |
| **Shift+Hover** over slot | Opens the flyout menu when "Menu on Shift" option is enabled |

---

### 🎮 Quick Access Slot Button Controls

| Action | Effect |
|--------|--------|
| **Left-Click** | Uses the item (activates on-use trinkets, equippables, etc.) |
| **Right-Click** | Advances to the next item in the queue for that slot |
| **Hover** | Opens the item selection flyout menu |
| **Shift+Left-Click** | Links the equipped item to chat (if chat edit box is open) |
| **Alt+Left-Click** | Toggles Auto-Queue ON/OFF for that slot |
| **Alt+Right-Click** | Opens the Queue configuration panel for that slot |
| **Drag** | Moves the button group (if unlocked); Shift+Drag moves only that button |

---

### 🔘 Set Button (Slot 20) Controls

| Action | Effect |
|--------|--------|
| **Left-Click** | Equips the current set (or toggles if "Equip Toggle" is ON) |
| **Right-Click** | Opens the Sets tab in Options |
| **Shift+Left-Click** | Unequips the current gear set |
| **Alt+Left-Click** | Toggles ItemRack Events ON/OFF |
| **Alt+Right-Click** | Opens the Sets tab in Options |

---

### 📋 Flyout Menu (Item Selection) Controls

| Action | Effect |
|--------|--------|
| **Left-Click** item | Equips that item to the slot |
| **Right-Click** item | Equips item (TrinketMenuMode: chooses slot 14) |
| **Shift+Click** item | Links the item to chat (if chat edit box is open) |
| **Alt+Click** item | Toggles the item as "Hidden" (if AllowHidden is ON) |
| **Left-Click** while bank is open | Pulls item from bank to bags, or pushes to bank |
| **Right-Click** menu frame | Toggles menu orientation (Vertical ↔ Horizontal) |
| **Drag** menu frame border | Re-docks the menu to a different corner of the button |

---

### 🌐 Minimap / Data Broker Button Controls

| Action | Effect |
|--------|--------|
| **Left-Click** | Opens the gear set selection menu |
| **Right-Click** | Opens the ItemRack Options window |
| **Shift+Click** | Unequips the current gear set |
| **Alt+Left-Click** | Shows hidden sets in the menu |
| **Alt+Right-Click** | Toggles ItemRack Events ON/OFF |

---

### ⌨️ Slash Commands

| Command | Effect |
|---------|--------|
| `/itemrack opt` or `/itemrack options` | Opens the Options window |
| `/itemrack equip <set name>` | Equips the specified set |
| `/itemrack toggle <set name>` | Toggles the specified set on/off |
| `/itemrack toggle <set1>, <set2>` | Toggles between two sets |
| `/itemrack lock` | Locks all buttons in place |
| `/itemrack unlock` | Unlocks buttons for repositioning |
| `/itemrack dump` | Opens a copyable window with session logs, runtime state, and audit history |
| `/itemrack debug` | Toggles the diagnostic logging framework (silent background mode) |
| `/itemrack debug chat` | Toggles printing diagnostic traces to the chat window in real-time |
| `/itemrack debug status` | Shows the current state of all debug tags |
| `/itemrack debug clear` | Clears the log buffer |
| `/itemrack debug audit` | Runs a full SavedVariables scan and prints results to chat |
| `/itemrack debug help` | Shows all available debug subcommands |
| `/itemrack debug <tag>` | Toggles a specific debug tag (e.g. `events`, `equip`, `queue`, `api`) |
| `/itemrack reset` | Resets all buttons and positions |
| `/itemrack reset everything` | Wipes all ItemRack data and reloads UI |

---

### 🔄 Auto-Queue System

The Auto-Queue system automatically swaps items based on cooldown availability:

1. **Enable Queue**: Alt+Left-Click a slot button, or use the Queue tab in Options.
2. **Configure Priority**: In the Queue tab, rank items from highest to lowest priority.
3. **How it works**: When an equipped item goes on cooldown, ItemRack swaps to the next ready item.
4. **Pause Queue**: Check "Pause Queue" on items to prevent them from being swapped out during use.

---

### ⚡ Combat Queue

If you try to swap items while in combat, ItemRack will:

1. Queue the swap for when combat ends.
2. Show a small overlay icon on the slot button indicating what's queued.
3. Automatically perform the swap when you leave combat.

---

### 📝 Notes

* Most actions that modify buttons or swap gear are **blocked during combat** due to Blizzard's secure action restrictions.
* The "Set Button" (slot 20) appears when you Alt+Click the character model frame.
* Hidden items can still be seen by holding Alt while hovering over menus (if AllowHidden is enabled).
* TrinketMenuMode combines both trinket slots into a single menu for easier management.

---

## Credits

* **Gello**: Original code and concept.
* **Rottenbeer, Roadblock, Rozil & Other Maintainers**: For keeping the Classic versions alive.
