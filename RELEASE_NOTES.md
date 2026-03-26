# Release Notes - ItemRack TBC Anniversary v4.35

### ✨ Improvements
- **Per-Set Queue Snapshotting**: When `Enable per-set queues` is active, clicking "Save" on a Set now deeply copies all active AutoQueue metadata (including enabled slot states, item priority orders, explicit delay timers, and pause markers). Previously, saving a new set omitted this metadata, forcing users to manually rebuild their queues for each set.
- **On Movement Debounce Toggle**: Added a "Stop Delay" check button to the Events option panel for the "On Movement" unequip hook. Users can now bypass the 0.5s debounce timer, initiating instantaneous gear swaps (e.g., unequipping your Riding Crop) the exact millisecond you press your movement key.

### 🐛 Bug Fixes
- **Bank Item Tooltips**: Sanitized the internal `IRStringToItemString` generator to safely truncate custom trailing attributes. This prevents the WoW client's `GameTooltip:SetHyperlink()` function from crashing and rendering an empty UI when inspecting saved item sets located inside your Bank while the bank frame is closed.
- **Main Bank Empty Tooltips**: Fixed a core engine bug where inspecting items residing natively in the 28-slot main Bank (`bag == -1`) returned stripped or broken tooltips (making other addons like VendorPrice append to an empty record). ItemRack now bypasses the failing `GameTooltip:SetBagItem` on this specific container, natively translating the slot into a player inventory ID using `BankButtonIDToInvSlotID` directly matching the Blizzard UI implementation.
