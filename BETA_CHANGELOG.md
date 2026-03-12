# Beta Changelog - ItemRack

*This changelog tracks the structural overhaul of the ItemRack codebase during beta development.*

## [4.30] - 2026-03-11 (Merged to Stable)
### 🏗️ Architecture & Engine Overhauls
- **Event Stack Replacement (Adaptive Multi-Level State Recovery)**: Replaced the brittle `set.old` variable with a full `ItemRackUser.EventStack`. The addon now remembers a hierarchy of overlapping events. (For example: walking into a City, and then entering an Arena). When you leave the Arena, it seamlessly continues to equip your City gear. When you leave the City, it correctly restores the "adventuring gear" you were wearing before any events fired!
- **`PushEvent` / `PopEvent` System**: All event handlers (Stance, Zone, Specialization, Buff) now use a centralized stack-based equip/unequip flow instead of direct `EquipSet`/`UnequipSet` calls.
- **`~BaseGear` Internal Set**: Initialized on load as the fallback base layer for the event stack.
- **Combat-Safe Stack Restoration**: Fixed events ending during combat failing to restore gear and losing set tracking.

### 🔧 Auto-Queue Awareness (PR #10)
- **`IsSetEquipped` Auto-Queue Awareness**: `IsSetEquipped` now queries the auto-queue to verify that equipped items match what the queue would select. (Thanks to [UDrew](https://github.com/UDrew) for [PR #10](https://github.com/Bl4ut0/ItemRack-Anniversary/pull/10)!)
- **`AutoQueueItemToEquip` Extraction**: Refactored the swap-candidate loop from `ProcessAutoQueue` into a reusable function.

### 🐛 Bug Fixes
- Quick Access Queue Toggle (Alt+Left-Click) re-implemented
- Right-Click Queue Advance fixed (table-to-string coercion errors)
- Right-Click Item Use (`type2` attribute) fixed
- Menu Cooldown Refresh crash protection
- "Disable Alt+Click" moved to "Global Settings"

### 📦 Status
This beta has been merged into master as version 4.30.
