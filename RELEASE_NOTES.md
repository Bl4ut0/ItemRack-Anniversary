# Release Notes - ItemRack TBC Anniversary v4.38

This release fixes a critical issue where zone-based events (like Warsong Gulch) would aggressively override manual gear swaps.

---

## 🐛 Bug Fixes

- **Zone Event Overriding Manual Swaps**: Fixed a bug where zone-based events (like a "WSG" zone event that auto-equips a PVP set) would forcefully re-equip the zone set within seconds of the user manually changing to a different set (like a Flag Carrier set). The event system now detects when a user has manually overridden the zone set and respects that choice for the remainder of the zone stay. The override clears automatically when leaving the zone, allowing normal auto-equip behavior on the next entry.

### How It Works
When you enter a zone with an active zone event, your assigned set equips automatically as before. If you then manually equip a different set while still in that zone, ItemRack will now back off and let you wear whatever you choose. When you leave the zone, the override resets and the event will auto-equip normally the next time you enter.
