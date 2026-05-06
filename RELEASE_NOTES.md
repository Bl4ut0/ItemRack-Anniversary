# Release Notes - ItemRack TBC Anniversary v4.39.3

This update fixes a ghost override edge case in the event system and adds missing TBC PvP gem support to the unique-gem swap system.

---

## Bug Fixes

- **Ghost Overrides for Events**: Fixed an edge case where transient or disabled Zone events could leave their `ManualOverride` flag stuck on, permanently suppressing gear restorations (e.g. dismounting, dropping a stance) even when no zone set was active.

---

## Improvements

- **Missing Ornate Gem IDs**: Added six missing TBC PvP Honor gems to the unique-gem tracking list — Bold Ornate Ruby, Runed Ornate Ruby, Inscribed Ornate Topaz, Potent Ornate Topaz, Smooth Ornate Dawnstone, and Gleaming Ornate Dawnstone. These gems are now correctly detected when ordering gear swaps, ensuring items socketed with them are unequipped first to avoid unique-gem equip conflicts.
