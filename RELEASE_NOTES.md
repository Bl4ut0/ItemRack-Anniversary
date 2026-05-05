# Release Notes - ItemRack TBC Anniversary v4.39.3

This update addresses combat taint propagation, Masque skinning compatibility, and adds missing TBC PvP gem support to the unique-gem swap system.

---

## Bug Fixes

- **Action Blocked (Taint Protection)**: Fixed `[ADDON_ACTION_BLOCKED]` errors caused by ItemRack buttons remaining registered in Blizzard's shared action bar event dispatch tables (`ActionBarButtonEventsFrame`, `ActionBarActionEventsFrame`, etc.). When ItemRack's addon code touched these buttons, taint propagated to all real Blizzard action buttons, causing `ActionButtonX:SetShown()`, `SetAttribute()`, `MainActionBar:SetShownBase()`, and related calls to be blocked in combat. The fix unregisters all ItemRack buttons from these dispatch tables immediately on creation — applied to the docked slot buttons via `ButtonOnLoad` and to dynamically-created popup menu buttons in `CreateMenuButton`. This was a pre-existing gap in the original 4.29 taint fix that only affected some users depending on which menus were opened.

- **Ghost Overrides for Events**: Fixed an edge case where transient or disabled Zone events could leave their `ManualOverride` flag stuck on, permanently suppressing gear restorations (e.g. dismounting, dropping a stance) even when no zone set was active.

---

## Improvements

- **Masque Compatibility**: ItemRack slot buttons and popup menu buttons now correctly expose their icon texture under the `button.icon` key that Masque expects. Previously, Masque could register ItemRack buttons but could not identify the icon layer, leaving the Blizzard grey border visible underneath the user's chosen skin. Users with Masque installed will now have their selected skin apply fully with no additional configuration required.

- **Missing Ornate Gem IDs**: Added six missing TBC PvP Honor gems to the unique-gem tracking list — Bold Ornate Ruby, Runed Ornate Ruby, Inscribed Ornate Topaz, Potent Ornate Topaz, Smooth Ornate Dawnstone, and Gleaming Ornate Dawnstone. These gems are now correctly detected when ordering gear swaps, ensuring items socketed with them are unequipped first to avoid unique-gem equip conflicts.
