# Technical Changes for TBC Anniversary Edition

This document details all modifications made to port ItemRack Classic to the TBC Anniversary Edition (2.5.4/2.5.5).

---

## Recent Feature Refinements (Spec Switching & UI Persistence)

### Specialization & Gear Synchronization
**File:** `ItemRackEvents.lua`, `ItemRackEquip.lua`
In the TBC engine, talent switching often fires events before the client is ready to swap gear, leading to race conditions.
- **Stability Timer:** Implemented a `0.5s` stability timer (`SpecChangeTimer`) to allow the client state to settle after a spec switch before triggering gear automation.
- **State Tracking:** Added `ItemRack.LastLastSpec` to track the active talent group index. This prevents "spec change" gear sets from fighting with temporary event sets (like "Drinking" or "Mounted") by ensuring a swap only triggers when the talent group actually transitions.
- **Redundancy Filter:** Added checks to avoid redundant `EquipSet` calls if the correct gear is already worn, significantly cleaning up the combat log and chat output.

### Options UI Persistence
**File:** `ItemRackOptions.lua`, `ItemRackEquip.lua`
- **Editing Stability:** Added logic to prevent the Options UI from automatically "jumping" back to the currently equipped set while the user is mid-edit. The UI now respects the `ItemRackOptSetsSaveButton` state to maintain the user's focus on the set they are currently configuring.
- **Spec Checkbox Management:** Introduced a `SpecDirty` flag to properly manage the state of Primary/Secondary spec checkboxes, ensuring they save correctly without being reset by background UI updates.

### Visual & Layout Polish
**File:** `ItemRackButtons.lua`, `ItemRackOptions.lua`, `ItemRack.lua`
- **Item Count Display:** Fixed logic to correctly show/hide item counts. Stacks and charges are now visible, but "1" counts for gear are hidden. Specifically addressed the **Ranged/Ammo slot** to correctly hide the "0" count when empty.
- **Dual Spec UI Layout:** Optimized the spacing of spec-related checkboxes in the Sets tab (4px overlap) to ensure all elements (Spec 1, Spec 2, Hide) fit within the frame without clipping.
- **Flyout Menus:** Multi-slot flyout menus now correctly display stack counts and charges for all items.

---

## API Namespace Migrations

### C_AddOns Namespace
**File:** `ItemRack.lua`, `ItemRackButtons.lua`
Addon management APIs have moved to the `C_AddOns` namespace.
- `LoadAddOn` → `C_AddOns.LoadAddOn`
- `GetAddOnMetadata` → `C_AddOns.GetAddOnMetadata`

### C_Container Namespace
**File:** `ItemRack.lua`, `ItemRackEquip.lua`, `ItemRackQueue.lua`
Container-related APIs have moved to `C_Container`.
- `GetContainerNumSlots` → `C_Container.GetContainerNumSlots`
- `GetContainerItemLink` → `C_Container.GetContainerItemLink`
- `GetContainerItemInfo` → `C_Container.GetContainerItemInfo`

### C_Item Namespace
**File:** `ItemRack.lua`, `ItemRackButtons.lua`
Item information APIs have moved to `C_Item`.
- `GetItemInfo` → `C_Item.GetItemInfo`
- `GetItemCount` → `C_Item.GetItemCount`

---

## Button Template Fix and Icon Layer Strategy
**File:** `ItemRackButtons.xml`, `ItemRackButtons.lua`, `ItemRack.lua`
The original `ActionButtonTemplate` interfered with secure click handling in the modern engine.
- **Template Migration:** Switched to `ActionBarButtonTemplate` for working secure clicks.
- **Custom Icon Layer:** Implemented a separate `$parentItemRackIcon` texture layer to bypass the modern Mixin's tendency to clear icons it doesn't recognize as "Actions".

---

## Options Menu Texture Cleanup
**File:** `ItemRackOptions/ItemRackOptions.xml`
- **Yellow Triangle Fix:** Implemented programmatic cleanup of anonymous textures in `ItemRackOptInvTemplate` to remove visual artifacts caused by modern template inherited overlays in the Options menu.

---

## Files Modified (Anniversary Port)

| File | Changes |
|------|---------|
| `ItemRack/ItemRack.toc` | Updated to v4.27, Interface 20505 |
| `ItemRack/ItemRack.lua` | API Shims, AuraUtil cleanup, Menu item count logic |
| `ItemRack/ItemRackButtons.lua` | Item count/Ammo slot display logic |
| `ItemRack/ItemRackEvents.lua` | Spec stability timer, redundancy filters |
| `ItemRack/ItemRackEquip.lua` | Spec-to-Gear logic, UI persistence checks |
| `ItemRackOptions/ItemRackOptions.lua` | Dual Spec UI spacing, SpecDirty tracking, Save Set consistency |
