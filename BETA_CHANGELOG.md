# Beta Changelog - ItemRack v5.0

*This changelog tracks the massive structural overhaul of the ItemRack codebase as we move toward version 5.0.*

## [5.0.0-beta.1] - UNRELEASED
### 🏗️ Architecture & Engine Overhauls
- **Event Stack Replacement (Adaptive Multi-Level State Recovery)**: Replaced the brittle `set.old` variable with a full `ItemRackUser.EventStack`. The addon now remembers a hierarchy of overlapping events. (For example: walking into a City, and then entering an Arena). When you leave the Arena, it seamlessly continues to equip your City gear. When you leave the City, it correctly restores the "adventuring gear" you were wearing before any events fired!
- **LibSoundIndex Integration**: [Pending]
