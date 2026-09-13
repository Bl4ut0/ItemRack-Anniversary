# ItemRack Streamlined Architecture (`dev-trimmed`)

This document details the streamlined architecture of ItemRack on the `dev-trimmed` branch, summarizing removed redundant workaround paths, core preserved systems, and supported World of Warcraft client environments.

---

## 1. Supported Client Matrix

The `dev-trimmed` branch maintains 100% active support for all Classic-era client distributions:

| WoW Client Distribution | Interface TOC Version | Status |
| :--- | :--- | :--- |
| **Classic Era** | `11509` (1.15.x) | Supported |
| **Season of Discovery (SoD)** | `11509` (1.15.x) | Supported (with `:runeid:` tracking) |
| **TBC Anniversary** | `20505`, `20506` (2.5.x) | Supported |
| **Classic Era PTR** | `11509` (1.15.x) | Supported |
| **WoW Forever Beta / Future Classic** | Modular engine | Prepared for testing |

---

## 2. Streamlined Code Cleanup Summary

The following redundant or dead workaround paths were trimmed from `dev-trimmed` without affecting client compatibility:

### A. Dead Legion Artifact Data (`ItemRack.PhantomItem`)
- **Removed**: 20-entry hardcoded Legion artifact weapon table (`Blades of the Fallen Prince`, `Twinblades of the Deceiver`, etc., item IDs `128293`–`134553`).
- **Rationale**: Artifact items do not exist in Classic Era, SoD, or TBC Anniversary item databases.

### B. Duplicate Lock-Clearing Calls
- **Streamlined**: Removed redundant `ItemRack.ClearLockList()` calls scattered across intermediate swap failure paths.
- **Rationale**: `ItemRackTransaction.lua`'s `FinishRequest` owns 100% of cursor and reservation cleanup deterministically upon transaction finalization.

### C. Redundant Swap Iteration Timers
- **Streamlined**: Coalesced 200ms `LocksChanged` polling delays into immediate `ITEM_LOCK_CHANGED` frame reconciliation.
- **Rationale**: Immediate lock change reconciliation accelerates multi-item set swaps (up to 10x faster) while remaining 100% transactionally safe.

### D. Obsolete Mount/Zone Unwind & Legacy Reducer (`ItemRackEvents.lua`)
- **Removed**: Over 400 lines of dead legacy code: `ProcessZoneEventLegacy`, `reconcileInvalidMountEvents`, `prepareMountRebase`, `scheduleMountZoneRecheck`, `hasNonRestoringMountLayer`, `hasNonRestoringMountStackLayer`, `isSetPendingOrSwapping`, `mountZoneSwapBusy`, `ensureZoneEventBelowMount`, and `removeEventFromStack`.
- **Rationale**: Completely superseded by canonical event frames in `ItemRackEventState.lua`. Logical frames make mount/zone rebasing a pure insertion operation, rendering intermediate unequip/re-equip unwind cascades and symptom polling loops obsolete.

---

## 3. Core Preserved Systems

All custom features introduced during the TBC Anniversary development remain intact:

1. **Rune Identity (`:runeid:`)**: SoD engraved gear matching across sets, AutoQueue, flyouts, tooltips, and bank caches.
2. **Observed Equipment Transactions (`ItemRackTransaction.lua`)**: Preflight space checks, item pickup handshakes, exact rollback on rejection, and zero-cursor jams.
3. **Canonical Event Frames (`ItemRackEventState.lua`)**: Multi-layered event restoration graph (Ghostwolf, Mounted, PVP, Zone, Specialization) with per-slot prior gear tracking.
4. **Script Event Security Consent Boundary**: Editor source approval tracking, warning prompts for imported scripts, and fail-closed dispatch guards.
5. **Cooldown Proxy Trinkets**: Support for items gated by a secondary cooldown (e.g. Serpent-Coil Braid).
