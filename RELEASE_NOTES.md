# Release Notes - ItemRack TBC Anniversary v4.33

### 🐛 Bug Fixes
- **Weapons Stuck on Cursor in Combat**: `MoveItem` now verifies cursor state after each swap attempt. If the game blocks `PickupInventoryItem` (e.g. during combat lockdown), the item is immediately returned via `ClearCursor()` instead of being left stuck on the cursor. Prevents the "Swap stopped. Something is on the cursor." spam.
- **Failed Swaps Losing Items**: `IterateSwapList` no longer removes items from the swap list when `MoveItem` fails. Failed items now stay in the swap list and properly fall through to the CombatQueue fallback instead of being silently dropped.
- **Stale Pending Swap Indicator**: Fixed the pending swap overlay icon persisting after gear had already been swapped:
  - `AddToCombatQueue` now checks `SameID` against the currently equipped item, preventing items that are already equipped from being queued.
  - `UpdateCombatQueue` sweeps stale entries before rendering overlays.
  - `ProcessCombatQueue` now always refreshes overlay indicators at the end, even when the queue was already processed by a different path.
  - `OnUnitInventoryChanged` sweeps the CombatQueue after every gear change, clearing fulfilled entries.
- **Combat API Race Condition**: `EquipSet` and `EquipItemByID` now consistently use `InCombatLockdown()` instead of mixing with `UnitAffectingCombat()`, preventing items from bouncing back into the queue after leaving combat.
- **Partial Swap Cursor Cleanup**: `IterateSwapList` now calls `ClearCursor()` after the swap loop if an item is stuck on the cursor from a partial swap. Failed combat swaps are moved to CombatQueue instead of entering the stuck `SetSwapping` wait state.

### ⚙️ Improvements
- **CombatQueue Debug Tag**: Added `CombatQueue` to the debug tag system for diagnosing swap queue issues. Enable with `/script ItemRack.DebugTags.CombatQueue = true`.
