# Release Notes - ItemRack TBC Anniversary v4.39

This release hardens the manual gear swapping system against unintended event overrides and fixes visual bugs during loss-of-control effects.

---

## 🐛 Bug Fixes

- **Hostile Event Fallback (Fixed FC Gear Bug)**: Fixed a major bug where manually equipping an event set (e.g., your FC gear) when its event condition wasn't active (e.g., you didn't have the flag buff yet) would cause ItemRack to instantly unequip the gear and revert to your previous setup. The fallback logic that caused this has been fixed to strictly respect your manual gear selections (by verifying the `CurrentSet` context) while preserving its ability to clean up genuinely desynced gear states (like dropping a mount state while reloading the UI).
- **Stun / Loss of Control Cooldown Visibility**: Fixed a visual bug where cooldown "swirl" animations on Quick Access buttons and popup menus would completely disappear when the player was stunned, feared, or under loss-of-control effects. The addon now overrides the engine's `enable=0` flag during these states to ensure genuine cooldown animations remain visible.
- **Manual Gear Override Protection**: Fixed a persisting issue where manual gear swaps could still be incorrectly overwritten when buried/nested events ended out-of-order. The `UnequipSet` logic fundamentally relies on the active `CurrentSet` context and now refuses to execute background gear restorations if you have actively manually overridden the set.
- **OnMovement Unequip Failures in Overridden Zones**: Fixed a bug where OnMovement gear (like Riding Crops or Swim Speed items) would fail to unequip when you stopped moving if you were inside a Zone Event that you had manually overridden (such as wearing PvE gear inside WSG). The zone's override suppression was blindly halting all event restorations, trapping you in movement gear permanently. It has been strictly compatibilized to only suppress buried background events, seamlessly allowing the natural active gear context (like your mount set) to unequip properly.
- **Bank Item Tooltip Crash**: Fixed a bug where hovering over bank items from a popout menu would fail to display the tooltip or cause UI lag due to missing cooldown data throwing the UI frame handler into an infinite loop.
- **Popout Menu Tooltip Anchoring (Large Grid Flicker)**: Fixed the GameTooltip positioning for popout menus, correcting a major visibility bug reported on large multi-column grids (like 3x3 setups). Tooltips now cleanly pad outwards from the grid boundaries, completely eradicating the invisible UI overlap loops that prevented them from loading on outer columns.
