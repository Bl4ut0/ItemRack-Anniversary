# Release Notes - ItemRack TBC Anniversary v4.36

This release focuses on hardening the auto-queue system — fixing several bugs where queue settings were silently ignored, and adding per-slot inheritance so event sets no longer clobber your queue configuration.

---

## ✨ Improvements

- **Per-Slot Queue Inheritance for Event Sets**: When an event set (like a mount set) only defines a few slots, equipping it no longer wipes the auto-queue state of every other slot. Missing slots now inherit from the previous set in the event stack before falling back to the global queue. Your bottom trinket's auto-queue keeps running normally when the mount event only swaps the top trinket.
- **Per-Set Queue Snapshotting**: Clicking "Save" on a Set now deeply copies all active AutoQueue metadata — enabled slot states, item priority orders, delay timers, and pause markers. Previously, saving a new set omitted this metadata, forcing you to manually rebuild queues for each set.
- **On Movement Debounce Toggle**: Added a "Stop Delay" checkbox to the Events panel for the "On Movement" unequip hook. You can now bypass the 0.5s debounce timer for instantaneous gear swaps (e.g., unequipping your Riding Crop the millisecond you start moving).
- **Queue Context Display**: The Queue Options tab now shows the name and icon of the exact Set whose auto-queue you're editing, preventing confusion during background set changes.

## 🐛 Bug Fixes

### Queue Behavior
- **Pause Queue Bypassed on Movement**: Fixed a critical bug where marking a trinket as "Pause Queue" would only hold while standing still — as soon as you moved, the auto-queue would swap it away. The root cause was `AutoQueueItemToEquip()` (called by the event system on `PLAYER_STARTED_MOVING`) never checking `keep` or `delay` flags on the equipped item.
- **Set Stuck on "Custom" After Queue Advance**: Manually advancing the queue (which temporarily puts you in "Custom" state) would prevent re-equipping your set — it would stay on "Custom" even though all items were equipped. Fixed by the same `IsSetEquipped` correction above.
- **Delay Flag Bypassed by Event System**: The per-item `delay` setting (prevents swapping until X seconds after use) was being ignored when evaluated through the event system's `IsSetEquipped` path.
- **Manual Queue Discarded in Combat**: Right-click queue advances for any slot were silently discarded when leaving combat if auto-queue was disabled for that slot. The combat queue filter now correctly distinguishes manual advances (always honored) from auto-queued entries.
- **Short Cooldown Auto-Queue**: Fixed auto-swap logic for items with short cooldowns (like the Parachute Cloak).

### Queue Editor & Options
- **Queue Editor Race Condition**: Editing auto-queues while the Options menu was open could silently corrupt unrelated sets if a background event (Mount, Combat) caused a gear swap. The editor now locks context to the set being edited regardless of background changes.
- **Queue Menu Empty Table Pollution**: Opening the Queue UI would spam `SavedVariables` with empty `Queues` objects across every set, bloating file sizes.
- **`SaveSet` Queue Context Desync**: Clicking Save could snapshot the wrong set's queue configuration if an event had changed `CurrentSet` while the Options panel was open.
- **`SetQueue` Crash When Options Not Loaded**: Calling `SetQueue()` from a custom event script before the Options panel had ever been opened would crash with a nil error.
- **Missing `UpdateQueueEnable` Function**: Alt-clicking to toggle auto-queue while the Queue Options panel was open would throw a Lua error.

### Queue System Internals
- **`IsSetEquipped` Queue-Awareness Dead Code**: The auto-queue awareness check in `IsSetEquipped` was rendered inactive by using `#set.Queues` on a sparse table (always returns 0 in Lua). Now correctly queries per-slot queue lists so zone/buff events detect pending queue swaps.
- **`RunAfterCombat` Cleanup Skipping Entries**: A forward-loop `table.remove` bug would skip every other deferred function, causing stale callbacks to re-run on every combat exit.

### Events & UI
- **Redundant Zone Events**: Prevented redundant zone-based event triggers in cities and PvP zones with a state-aware zone transition check.
- **Queue Initialization Popup**: Alt+LeftClicking an empty queue slot's quick-access button no longer pops open the Options menu — it silently auto-populates and toggles the queue in the background.
- **Bank Item Tooltips**: Fixed the tooltip engine crashing when inspecting saved items in your bank while the bank frame is closed.
- **Main Bank Empty Tooltips**: Fixed items in the 28-slot main bank returning stripped or broken tooltips by using `BankButtonIDToInvSlotID` directly.
