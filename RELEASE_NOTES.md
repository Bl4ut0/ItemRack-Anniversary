# Release Notes - ItemRack TBC Anniversary v4.39.3

This minor update addresses critical **Action Blocked** errors occurring in combat and hardens the addon against UI taint propagation.

---

## Bug Fixes

- **Action Blocked (Taint Protection)**: Fixed `[ADDON_ACTION_BLOCKED]` errors that occurred when hovering over ItemRack buttons or menu items in combat. This was caused by the buttons inheriting from Blizzard's `ActionButtonTemplate`, which automatically registered them with protected event dispatchers. All custom buttons now explicitly unregister from these dispatchers and strip protected mixins to ensure they cannot propagate taint to the global action bar system.
