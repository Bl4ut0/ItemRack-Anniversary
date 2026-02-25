## 🚀 New in v4.29.1

### 🐛 Bug Fixes
- **Specialization Re-equip Fix**: Resolved an issue where switching zones or reloading would aggressively re-equip spec-tied sets, overwriting manual gear changes (like equipping a shield). The system now "primes" its state on startup and uses `.Active` flag tracking to respect manual overrides until a real spec change occurs.

### 🎨 UI & Quality of Life
- **Optimized Popout Menus**: Redesigned popout menus (BuildMenu) with dynamic wrapping. High item counts (like necklaces) now wrap into multiple columns, and bottom slots (weapons/ammo) grow horizontally to prevent going off-screen or covering other gear.
- **Enhanced Tooltip Anchoring**: Improved tooltip positioning for all ItemRack toolbar buttons to prevent overlap with menus, action bars, or Blizzard's default UI elements.

---

## 🚀 New in v4.29

### 🐛 Bug Fixes
- **Action Bar Taint Fix**: Fixed `ADDON_ACTION_BLOCKED` errors that caused Blizzard action bar buttons to break (e.g. `MultiBar5Button1:SetShown()`). Two taint vectors were addressed: (1) GameTooltip table key taint from tooltip anchoring, and (2) shared action bar dispatcher taint from ItemRack button registration. Item-use clicks on ItemRack quick access buttons are now fully functional.
- **Button Nil Errors**: Fixed `attempt to index field '?' (a nil value)` scaling errors that occurred when mousing over buttons or dragging buttons on clients carrying over older profile data (common in Season of Discovery / Classic Era).

### ⚡ New Features
- **Tooltip Highlight Unequipped**: Added a new setting "Highlight unequipped in tooltip". When enabled, viewing a set's tooltip will highlight items that are in your bags (but not currently equipped) in **Orange**, making it easy to quickly see what you are missing from your active set!

### 🎨 UI & Quality of Life
- **Improved Tooltip Placement**: Tooltips for character slots now explicitly anchor depending on their side and settings (right-side slots fall neatly below the menus, instead of overlapping them).

---

## 🚀 New in v4.28

### 🐛 Bug Fixes
- **Tooltip Set Info**: Fixed "Show set info in tooltips" not reliably displaying `ItemRack Set:` labels when hovering items in bags or character panel. The old exact string comparison broke after the TBC Anniversary launch changed item string field counts. Replaced with a new `SameExactID` comparison that matches the first 8 item-identifying fields (itemID, enchant, gems, suffix, unique) while ignoring trailing context fields — correctly differentiates enchanted/gemmed variants and is immune to format changes.

### ⚡ New Features
- **Blizzard Keybinding Integration**: All 20 equipment slots now appear in the Blizzard Keybindings panel under **AddOns > ItemRack** with descriptive slot labels (e.g., "Head (Slot 1)", "Off Hand / Shield / Held In Off-hand (Slot 17)"). No more hunting through slash commands to bind slots.
- **Improved Cooldown Display (Large Numbers)**: When "Large Numbers" is enabled, cooldown text now uses a clean `mm:ss` / `h:mm` format with dynamic coloring — **white** above 60s, **yellow** under 60s, **red** under 5s. Uses `THICKOUTLINE` for better readability. Small numbers mode retains the original `30 s` / `2 m` / `1 h` format.

### 🎨 UI & Quality of Life
- **Native Countdown Suppression**: WoW's built-in `CooldownFrame` countdown numbers are now suppressed on ItemRack buttons to prevent duplicate text overlapping with ItemRack's own cooldown system.
- **Hotkey Display**: Keybinding text on slot buttons now renders in a subtle gray and properly hides when no key is bound, with added nil-safety checks.
- **Smart Menu Defaults**: Left-side character sheet slots now default to opening menus on the **right** to prevent overlap with the character model. Configurable per-side under Options.
- **Tooltip Cleanup**: Internal system sets (`~Unequip`, `~CombatQueue`) are now filtered from item tooltips.

### 🛠️ Upgrading from v4.27.5?
Simply overwrite your existing `ItemRack` and `ItemRackOptions` folders. Your sets, keybinds, and settings will be preserved.
