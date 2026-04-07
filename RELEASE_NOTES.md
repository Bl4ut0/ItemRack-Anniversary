# Release Notes - ItemRack TBC Anniversary v4.37

This release focuses on heavily expanding the Auto-Queue system configuration, granting you fine-grained control over exactly when and how items enter and leave your queue rotations.

---

## ✨ New Features

- **Burn on Use**: Added a per-item "Burn on Use" check-box for the queue editor (Replacing the old "Swap on Use" label). When enabled, using an item (and putting it on cooldown) flags it as "burnt." The auto-queue system gracefully skips burnt items on subsequent rotations. This allows for true single-use queue logic, preventing an item from ever automatically rotating back into your slot until you manually jog the queue or organically re-equip the set.
- **Custom Swap-In Cooldowns**: Added a custom "Swap In" timer explicitly for queued items. By default, ItemRack tries to aggressively pre-equip Trinkets and Rings exactly 30 seconds before their cooldown completes to overlap the 30-second penalty equip timer. You can now use the `[x] Swap in ___ sec` input box to override this mechanic on a per-item basis. You can set it to `0` to wait until the item is completely off cooldown before it rotates in, or set it to `60` to force an item back into your slot a full minute early.

## 🐛 Bug Fixes

- **UI Editing Context Desync**: Fixed a major UI issue where the Queue Editing tab failed to bind strictly to the "Equip in options" checkbox configuration. Setting it to OFF will now correctly bind the configuration window strictly to the dropdown layer you were explicitly viewing (even though the dropdown goes invisible when changing tabs), completely ignoring your "equipped" state.
- **Queue Cooldown Crashing (`bad argument #1`)**: Fixed a `GetItemCooldown` Lua failure during queue processing where it erroneously tried to validate ItemRack's pseudo-string format instead of reducing it back to the pure numeric integer ID required by the C engine, which occasionally caused background Lua crashes.
- **Visual Alignments**: Polished the Options window layout to correctly anchor the new custom Queue Editor toggle switches cleanly along the bottom pane.
