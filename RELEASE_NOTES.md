# Release Notes - ItemRack TBC Anniversary v4.39.1

This hotfix hardens cooldown display during loss-of-control effects, reduces cooldown debug spam, and adds an arena-only quick access hide toggle.

---

## Bug Fixes

- **Robust Loss-of-Control Cooldown Guard**: Quick Access buttons now preserve real item cooldown swirls when Blizzard reports false `start=0` / `dur=0` states or clears the cooldown frame during stuns and other loss-of-control effects. Popup menu cooldowns now use the same cached-cooldown guard.
- **Cooldown Debug Spam**: `IR-Cooldown` now logs only when a slot's cooldown state actually changes, preventing heavy chat spam from repeated cooldown refresh events.

## Improvements

- **Arena Quick Access Hiding**: Added a `Hide in arenas` option for the docked Quick Access buttons. When enabled, the on-screen quick access bar and its menu automatically hide inside arena instances and restore when you leave.
