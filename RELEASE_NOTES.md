# Release Notes - ItemRack TBC Anniversary v4.39.2

This update fully restores **OmniCC compatibility** for all cooldown overlays, firmly fixes item-hiding in dropdown menus, and brings a robust set of queue edge-case fixes alongside native event-stack support for custom scripts!

---

## Bug Fixes

- **OmniCC Compatibility**: Fixed an issue where the native cooldown overlay provided by OmniCC would fail to display on ItemRack buttons. The addon now dynamically routes its CC-guard bypasses through the engine's natively hooked metatable so that OmniCC securely receives `OnSetCooldown` events.
- **Trinket Cooldown Desync**: Enhanced the precision of the CC-guard cache evaluation (with a 0.1s epsilon rounding) to prevent a jarring flash-to-ready UI state when trinkets exit cooldown.
- **Popout Menu Alt+Click Hiding**: Fixed a regression where using Alt+Click on items within a popout dropdown menu would try to toggle the Quick Access Queue instead of correctly hiding items (e.g., fishing poles or mining picks).
- **Arena Cooldown Reset**: Quick Access and popup-menu cooldown displays now clear their cached cooldown state when entering a fresh arena, with a delayed second pass on arena entry so fresh matches correctly show reset trinkets and other items.
- **Stale Combat Queue Context**: Auto-queued combat swaps now remember which set/queue context created them and are discarded if that context changes before combat ends. This fixes cases where leaving combat after mount or event transitions could still apply a trinket or queued item chosen for an older set context.
- **Parachute Burn-on-Use**: Burn-on-use queue items are now marked from the real item-use event, fixing short post-buff cooldown cases like parachute cloaks that were staying in place after the buff faded.
- **Detailed Burn State Matching**: Burn-on-use queue state now tracks the exact queued item variant instead of only the base item ID, so duplicate same-base items no longer burn each other and per-item swap-in timing stays tied to the precise item variant.
- **Per-Set Queue Save Completeness**: Saving a set now preserves all queue metadata, including Burn on Use and Custom Swap In settings. Previously, re-saving a set could silently drop those newer per-item queue options and cause later queue behavior to drift from what the user configured.
- **Queue/Event Slot Ownership**: Per-set queue inheritance no longer bleeds into slots that the active set explicitly defines, preventing inherited queues from fighting event gear on the same slot.
- **Queued Item Set Detection**: The current set display now correctly treats the active queued item as valid for that set, fixing minimap/current-set display drift when auto queues swap items.

## Improvements

- **Script Event Stack Helpers**: Script events now support `EquipEventSet("setname")` and `UnequipEventSet()` so custom scripted swaps participate in the same event stack, nested restore, and manual-override logic as built-in events.
- **Script Event Backward Compatibility**: Existing simple script events that use bare `EquipSet(...)` and `UnequipSet(...)` inside the script editor continue to work without user edits.
- **Swimming Script Migration**: The default Swimming script now uses the stack-aware helper API, and legacy saved copies are migrated automatically on load.
