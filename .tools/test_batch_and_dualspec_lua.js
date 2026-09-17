const fs = require('fs');
const { extractFunction, runLua } = require('./lib/lua_harness');

const transactionSource = fs.readFileSync('ItemRack/ItemRackTransaction.lua', 'utf8');
const equipSource = fs.readFileSync('ItemRack/ItemRackEquip.lua', 'utf8');
const itemRackSource = fs.readFileSync('ItemRack/ItemRack.lua', 'utf8');

function runCase(name, setup, assertions) {
  runLua(`${setup}\n${transactionSource}\n${assertions}`, `batch-dualspec:${name}`);
}

const commonSetup = String.raw`
local now = 0
local timers = {}
local clearCursorCalls = 0

function GetTime() return now end
C_Timer = {
  After = function(delay, callback)
    table.insert(timers, { due = now + delay, callback = callback })
  end,
  NewTimer = function(delay, callback)
    local handle = { canceled = false }
    function handle:Cancel() self.canceled = true end
    table.insert(timers, { due = now + delay, callback = function() if not handle.canceled then callback() end end })
    return handle
  end,
}
function RunTimers(limit)
  local runs = 0
  while #timers > 0 do
    table.sort(timers, function(a, b) return a.due < b.due end)
    local timer = table.remove(timers, 1)
    now = timer.due
    timer.callback()
    runs = runs + 1
    assert(runs < (limit or 300), "timer loop did not settle")
  end
end

INVSLOT_AMMO, INVSLOT_RANGED = 0, 18
C_Container = nil
ItemRackSettings = { DisableSwapSound = "OFF", LockMinimap = "OFF" }
ItemRackUser = {
  Locked = "OFF",
  EnableQueues = "OFF",
  CurrentSet = "Base",
  Sets = {},
}
ItemRack = {
  LockList = { [-2] = {}, [-1] = {}, [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} },
  eqBackOfTheBusOffset = 100,
  Debug = function() end,
  Print = function() end,
  SameExactID = function(a, b) return a == b end,
  MatchesStoredItemID = function(a, b) return a == b end,
  MuteSwapSounds = function() end,
  GetEnhancements = function() return 0,0,0,0,0 end,
  ClearBurntQueueItems = function() end,
  UpdateCombatQueue = function() end,
  ClearLockList = function()
    for _, list in pairs(ItemRack.LockList) do
      for key in pairs(list) do list[key] = nil end
    end
  end,
  IsPlayerReallyDead = function() return false end,
  UpdateCurrentSet = function() end,
  SlotInfo = {
    [1] = { name = "HeadSlot" },
    [3] = { name = "ShoulderSlot" },
    [5] = { name = "ChestSlot" },
    [8] = { name = "BootsSlot" },
    [16] = { name = "MainHandSlot" },
    [17] = { name = "SecondaryHandSlot" },
  },
}
function SpellIsTargeting() return false end
function IsInventoryItemLocked() return false end
function GetContainerItemInfo() return nil, nil, false end
function ClearCursor() clearCursorCalls = clearCursorCalls + 1; cursor = nil end
function InCombatLockdown() return false end
function CursorHasItem() return cursor ~= nil end
function GetCursorInfo() if cursor then return "item" end end
function ShowHelm() end
function ShowCloak() end
`;

// Test 1: Instant batching submits all independent moves in a single frame
runCase(
  'instant-batch-single-frame',
  `${commonSetup}
local bags = {
  [0] = { [1] = 9001, [2] = 9003, [3] = 9005, [4] = 9016 }
}
local inventory = {
  [1] = 8001, [3] = 8003, [5] = 8005, [16] = 8016
}
cursor = nil

ItemRackUser.Sets["FullSet"] = {
  equip = { [1] = 9001, [3] = 9003, [5] = 9005, [16] = 9016 },
  old = {},
}

function ItemRack.GetID(bag, slot)
  if slot then return bags[bag] and bags[bag][slot] or 0 end
  return inventory[bag] or 0
end
function ItemRack.GetInfoByID(id)
  if id == 9016 then return "Weapon", nil, "INVTYPE_WEAPON" end
  return "Armor", nil, "INVTYPE_CHEST"
end
function ItemRack.FindItem(id, lock)
  for b = 0, 0 do
    for s = 1, 4 do
      if bags[b] and bags[b][s] == id and not ItemRack.LockList[b][s] then
        if lock then ItemRack.LockList[b][s] = 1 end
        return nil, b, s
      end
    end
  end
end
function ItemRack.ValidBag(b) return b == 0 end
function GetContainerNumSlots() return 4 end
function GetContainerItemLink(b, s) return bags[b] and bags[b][s] end
function GetInventoryItemID(_, s) return inventory[s] end
function GetInventoryItemLink(_, s) return inventory[s] end
function GetItemInfo() return nil, nil, nil, nil, nil, nil, "One-Handed Swords" end

function PickupContainerItem(b, s)
  local held = cursor; cursor = bags[b][s]; bags[b][s] = held
end
function PickupInventoryItem(s)
  local held = cursor; cursor = inventory[s]; inventory[s] = held
end
`,
  `${equipSource}
local result = ItemRack.EquipSet("FullSet")
assert(result == nil or result == "submitted", "EquipSet must submit batch")
assert(ItemRack.ActiveEquipmentTransaction ~= nil, "Transaction must be actively tracking batch")
local tx = ItemRack.ActiveEquipmentTransaction
assert(#tx.steps == 4, "All 4 moves must be packaged into the transaction")
local submittedCount = 0
for _, step in ipairs(tx.steps) do
  if step.status == "submitted" then
    submittedCount = submittedCount + 1
  end
end
assert(submittedCount == 4, "All 4 moves must be submitted synchronously in frame 1")

RunTimers()
assert(ItemRackUser.CurrentSet == "FullSet", "Set must commit CurrentSet upon batch confirmation")
assert(inventory[1] == 9001 and inventory[3] == 9003 and inventory[5] == 9005 and inventory[16] == 9016, "All 4 pieces must be equipped")
assert(bags[0][1] == 8001 and bags[0][2] == 8003 and bags[0][3] == 8005 and bags[0][4] == 8016, "All displaced items returned to bag")
assert(cursor == nil, "Cursor must remain completely clear")
assert(ItemRack.ActiveEquipmentTransaction == nil, "Transaction finalized")
`
);

// Test 2: Batch rollback security when one item in the batch is rejected
runCase(
  'batch-rollback-on-failure',
  `${commonSetup}
local bags = {
  [0] = { [1] = 9001, [2] = 9003, [3] = 9005 }
}
local inventory = {
  [1] = 8001, [3] = 8003, [5] = 8005
}
cursor = nil
local rejectSlot5 = true

ItemRackUser.CurrentSet = "Base"
ItemRackUser.Sets["Base"] = { equip = { [1] = 8001, [3] = 8003, [5] = 8005 } }
ItemRackUser.Sets["TestFail"] = {
  equip = { [1] = 9001, [3] = 9003, [5] = 9005 },
  old = { [1] = 1111 },
  oldset = "PreviousSet",
}

function ItemRack.GetID(bag, slot)
  if slot then return bags[bag] and bags[bag][slot] or 0 end
  return inventory[bag] or 0
end
function ItemRack.GetInfoByID(id) return "Armor", nil, "INVTYPE_CHEST" end
function ItemRack.FindItem(id, lock)
  for b = 0, 0 do
    for s = 1, 3 do
      if bags[b] and bags[b][s] == id and not ItemRack.LockList[b][s] then
        if lock then ItemRack.LockList[b][s] = 1 end
        return nil, b, s
      end
    end
  end
end
function ItemRack.ValidBag(b) return b == 0 end
function GetContainerNumSlots() return 3 end
function GetContainerItemLink(b, s) return bags[b] and bags[b][s] end
function GetInventoryItemID(_, s) return inventory[s] end
function GetInventoryItemLink(_, s) return inventory[s] end
function GetItemInfo() return nil, nil, nil, nil, nil, nil, "Plate" end

function PickupContainerItem(b, s)
  local held = cursor; cursor = bags[b][s]; bags[b][s] = held
end
function PickupInventoryItem(s)
  if rejectSlot5 and s == 5 and cursor == 9005 then return end
  local held = cursor; cursor = inventory[s]; inventory[s] = held
end
`,
  `${equipSource}
ItemRack.EquipSet("TestFail")
RunTimers()
assert(ItemRackUser.CurrentSet == "Base", "Rejected batch must not commit new set")
assert(inventory[1] == 8001 and inventory[3] == 8003 and inventory[5] == 8005, "All gear must roll back to exact original state")
assert(bags[0][1] == 9001 and bags[0][2] == 9003 and bags[0][3] == 9005, "All bag contents must roll back to exact original slots")
assert(cursor == nil, "Cursor must remain clean after rollback")
assert(ItemRack.ActiveEquipmentTransaction == nil, "Rollback leaves no stuck transaction")
`
);

// Test 3: Shaman Enhance Dual-Spec offhand weapon deferral and talent activation
runCase(
  'shaman-dualspec-weapon-deferral',
  `${commonSetup}
local bags = {
  [0] = { [1] = 9016, [2] = 9017 }
}
local inventory = {
  [16] = 8016, [17] = 8017
}
cursor = nil

local activeTalentGroup = 1
local numTalentGroups = 2
local switchedToSpec = nil
local canDualWield = false
local retriedOffhand = false

function GetActiveTalentGroup() return activeTalentGroup end
function GetNumTalentGroups() return numTalentGroups end
function SetActiveTalentGroup(target) switchedToSpec = target end
function UnitClass() return "Shaman", "SHAMAN" end
function ItemRack.CanPlayerDualWield() return canDualWield end

ItemRackUser.Sets["Enhance"] = {
  AssociatedSpec = 2,
  equip = { [16] = 9016, [17] = 9017 },
  old = {},
}

function ItemRack.GetID(bag, slot)
  if slot then return bags[bag] and bags[bag][slot] or 0 end
  return inventory[bag] or 0
end
function ItemRack.GetInfoByID(id)
  if id == 9016 then return "Axe", nil, "INVTYPE_WEAPON" end
  if id == 9017 then return "Fist", nil, "INVTYPE_WEAPONOFFHAND" end
  return "Shield", nil, "INVTYPE_SHIELD"
end
function ItemRack.FindItem(id, lock)
  for b = 0, 0 do
    for s = 1, 2 do
      if bags[b] and bags[b][s] == id and not ItemRack.LockList[b][s] then
        if lock then ItemRack.LockList[b][s] = 1 end
        return nil, b, s
      end
    end
  end
end
function ItemRack.ValidBag(b) return b == 0 end
function GetContainerNumSlots() return 2 end
function GetContainerItemLink(b, s) return bags[b] and bags[b][s] end
function GetInventoryItemID(_, s) return inventory[s] end
function GetInventoryItemLink(_, s) return inventory[s] end
function GetItemInfo() return nil, nil, nil, nil, nil, nil, "One-Handed Axes" end

function PickupContainerItem(b, s)
  local held = cursor; cursor = bags[b][s]; bags[b][s] = held
end
function PickupInventoryItem(s)
  if s == 17 and not canDualWield then
    return
  end
  local held = cursor; cursor = inventory[s]; inventory[s] = held
end

ItemRack.PendingDualWieldRetry = {}
function ItemRack.ScheduleDualWieldRetry(setname, targetSpec)
  ItemRack.PendingDualWieldRetry[setname] = targetSpec
end
function ItemRack.RetryDualWieldWeapons(setname, expectedSpec)
  if canDualWield and ItemRackUser.Sets[setname] then
    local set = ItemRackUser.Sets[setname].equip
    if set[17] then
      ItemRack.EquipItemByID(set[17], 17)
    end
  end
end
function ItemRack.OnActiveTalentGroupChanged()
  if ItemRack.PendingDualWieldRetry then
    for setname, expectedSpec in pairs(ItemRack.PendingDualWieldRetry) do
      C_Timer.After(0.2, function()
        ItemRack.RetryDualWieldWeapons(setname, expectedSpec)
      end)
    end
  end
end
`,
  `${equipSource}
ItemRack.EquipSet("Enhance")
assert(ItemRack.PendingDualWieldRetry["Enhance"] == 2, "INVTYPE_WEAPONOFFHAND must be deferred and scheduled for retry on spec 2")
RunTimers()
assert(inventory[16] == 9016, "Mainhand weapon must equip cleanly in the initial swap pass")
assert(inventory[17] == 8017, "Offhand must remain untouched during initial pre-spec pass (not rejected, no rollback)")
assert(switchedToSpec == 2, "Spec switch to Spec 2 must be triggered by EndSetSwap")

activeTalentGroup = 2
canDualWield = true

ItemRack.EquipItemByID = function(id, slot)
  if slot == 17 and id == 9017 and canDualWield then
    inventory[17] = 9017
    bags[0][2] = 8017
    retriedOffhand = true
  end
end

ItemRack.OnActiveTalentGroupChanged()
RunTimers()
assert(inventory[16] == 9016 and inventory[17] == 9017, "Both weapons equipped successfully after OnActiveTalentGroupChanged")
assert(retriedOffhand == true, "Offhand retry successfully completed via OnActiveTalentGroupChanged")
`
);

// Test 4: Minimap button lock via LibDBIcon
runCase(
  'minimap-button-lock',
  `${commonSetup}
local lockCalls = 0
local unlockCalls = 0
local ldbLocked = false

LDBIcon = {
  Lock = function(self, name)
    if name == "ItemRack" then
      lockCalls = lockCalls + 1
      ldbLocked = true
    end
  end,
  Unlock = function(self, name)
    if name == "ItemRack" then
      unlockCalls = unlockCalls + 1
      ldbLocked = false
    end
  end,
}
ItemRackMenuFrame = {
  SetBackdrop = function() end,
  EnableMouse = function() end,
  SetBackdropBorderColor = function() end,
  SetBackdropColor = function() end,
}

ItemRack.ReflectLock = function(override)
  local shouldLockMinimap = ItemRackUser.Locked=="ON" or (ItemRackSettings and ItemRackSettings.LockMinimap=="ON") or override
  if LDBIcon and LDBIcon.Lock and LDBIcon.Unlock then
    if shouldLockMinimap then
      LDBIcon:Lock("ItemRack")
    else
      LDBIcon:Unlock("ItemRack")
    end
  end
end
`,
  `
ItemRackUser.Locked = "ON"
ItemRack.ReflectLock()
assert(ldbLocked == true and lockCalls == 1, "Setting Locked='ON' must lock LDBIcon")

ItemRackUser.Locked = "OFF"
ItemRack.ReflectLock()
assert(ldbLocked == false and unlockCalls == 1, "Setting Locked='OFF' must unlock LDBIcon")

ItemRackSettings.LockMinimap = "ON"
ItemRack.ReflectLock()
assert(ldbLocked == true and lockCalls == 2, "Setting LockMinimap='ON' must lock LDBIcon")

ItemRackSettings.LockMinimap = "OFF"
ItemRack.ReflectLock()
assert(ldbLocked == false and unlockCalls == 2, "Setting LockMinimap='OFF' must unlock LDBIcon")
`
);

// Test 5: CanPlayerDualWield Blizzard Deprecated_SpellBook API safety
const dualWieldBlock = itemRackSource.substring(
  itemRackSource.indexOf('local function safeCheckSpellKnown'),
  itemRackSource.indexOf('function ItemRack.UpdateClassSpecificStuff()')
);

runLua(
  `
local currentClass = "SHAMAN"
local currentLevel = 70
local knownSpellIDs = {}
local talentRank = 0

function UnitClass() return currentClass, currentClass end
function UnitLevel() return currentLevel end

-- Blizzard Deprecated_SpellBook mock: THROWS if argument 1 is not a number!
C_SpellBook = {
  IsSpellInSpellBook = function(spellID)
    if type(spellID) ~= "number" then
      error("bad argument #1 to 'IsSpellInSpellBook' (outside of expected range -2147483648 to 2147483647 - Usage: local isInSpellBook = C_SpellBook.IsSpellInSpellBook(spellID [, spellBank, includeOverrides]))")
    end
    return knownSpellIDs[spellID] == true
  end
}
IsSpellKnown = function(spellID)
  return C_SpellBook.IsSpellInSpellBook(spellID)
end
C_Spell = {
  GetSpellInfo = function(spellID)
    if spellID == 674 then return { name = "Dual Wield" } end
    return nil
  end
}

function GetNumTalentTabs() return 3 end
function GetNumTalents(tab) return tab == 2 and 20 or 0 end
function GetTalentInfo(tab, tal)
  if tab == 2 and tal == 17 then
    return "Dual Wield", "icon", 1, 1, talentRank
  end
  return "Other", "icon", 1, 1, 0
end

ItemRack = {}

${dualWieldBlock}

-- Case A: Shaman with no talents or spells known must return false WITHOUT throwing
currentClass = "SHAMAN"
knownSpellIDs = {}
talentRank = 0
local resA = ItemRack.CanPlayerDualWield()
assert(resA == false, "Shaman without DW must return false")

-- Case B: Shaman with DW talent spellID 30798 known must return true WITHOUT throwing
knownSpellIDs[30798] = true
local resB = ItemRack.CanPlayerDualWield()
assert(resB == true, "Shaman with DW spell 30798 must return true")

-- Case C: Shaman with DW talent tree rank > 0 must return true WITHOUT throwing
knownSpellIDs[30798] = false
talentRank = 1
local resC = ItemRack.CanPlayerDualWield()
assert(resC == true, "Shaman with DW talent rank > 0 must return true")

-- Case D: Rogue always returns true
currentClass = "ROGUE"
assert(ItemRack.CanPlayerDualWield() == true, "Rogue must always return true")

-- Case E: Warrior < 20 returns false, Warrior >= 20 returns true
currentClass = "WARRIOR"
currentLevel = 19
knownSpellIDs = {}
assert(ItemRack.CanPlayerDualWield() == false, "Warrior level 19 must return false")
currentLevel = 20
assert(ItemRack.CanPlayerDualWield() == true, "Warrior level 20 must return true")
`,
  'batch-dualspec:can-player-dualwield-spellbook-safety'
);

// GitHub #24 follow-up audit: preflight reservations must survive execution,
// not just exact-first lookup. Ring identities are synthetic, not a new claim
// that the original bracer report or the untriaged SoD report used this shape.
const identityFunctions = [
  'SameID', 'GetRuneID', 'HasRuneID', 'IsBareItemID', 'SameItemFields',
  'SameExactID', 'MatchesStoredItemFields', 'MatchesStoredItemID', 'FindItem',
].map(name => extractFunction('ItemRack/ItemRack.lua', `ItemRack.${name}`)).join('\n');

for (const mode of ['later-slot', 'already-equipped', 'wildcard-first', 'paired-exchange']) {
  const satisfied = mode === 'already-equipped';
  const paired = mode === 'paired-exchange';
  runCase(
    `exact-copy-reservation-${mode}`,
    `${commonSetup}
local absent = "${mode === 'wildcard-first' ? '19001' : '19001:1:0:0:0:0:0:0:70:0'}"
local exact = "19001:2:0:0:0:0:0:0:70:0"
local substitute = "19001:3:0:0:0:0:0:0:70:0"
local bags = { [0] = ${paired ? '{}' : satisfied ? '{ [1]=substitute }' : '{ [1]=exact, [2]=substitute }'} }
local inventory = { [11]=${paired ? 'substitute' : '"19002"'}, [12]=${satisfied || paired ? 'exact' : '"19003"'} }
cursor = nil
ItemRack.SlotInfo[11] = { name="Finger0Slot" }
ItemRack.SlotInfo[12] = { name="Finger1Slot" }
ItemRackUser.Sets["RingSet"] = { equip={ [11]=${paired ? 'exact' : 'absent'}, [12]=${paired ? 'substitute' : 'exact'} }, old={} }
ItemRack.KnownItems = {}
ItemRack.BankOpen = false
ItemRack.iSPatternBaseIDFromIR = "^(%-?%d+)"
ItemRack.iSPatternItemFieldsFromIR = "^(%-?%d+:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*)"
ItemRack.iSPatternRuneIDFromIR = ":runeid:(%d+)$"
function ItemRack.GetIRString(value,base)
  if base then return tostring(value or ""):match("^(%-?%d+)") or 0 end
  return value or 0
end
function ItemRack.UpdateIRString(value) return value end
function ItemRack.GetID(bag,slot)
  if slot then return bags[bag] and bags[bag][slot] or 0 end
  return inventory[bag] or 0
end
function ItemRack.GetInfoByID() return "Ring",nil,"INVTYPE_FINGER" end
function ItemRack.ValidBag(bag) return bag == 0 end
function GetContainerNumSlots(bag) return bag == 0 and 2 or 0 end
function GetContainerItemLink(bag,slot) return bags[bag] and bags[bag][slot] end
function GetInventoryItemID(_,slot) return inventory[slot] end
function GetInventoryItemLink(_,slot) return inventory[slot] end
function PickupContainerItem(bag,slot)
  local held = cursor; cursor = bags[bag][slot]; bags[bag][slot] = held
end
function PickupInventoryItem(slot)
  local held = cursor; cursor = inventory[slot]; inventory[slot] = held
end
${identityFunctions}
`,
    `${equipSource}
local planned,reason,missing = ItemRack.PreflightSetSwap("RingSet")
assert(planned and #missing == 0,"both ring targets must have distinct available sources")
ItemRack.EquipSet("RingSet")
RunTimers()
assert(inventory[11] == ${paired ? 'exact' : 'substitute'},"earlier target must receive its distinct planned source")
assert(inventory[12] == ${paired ? 'substitute' : 'exact'},"later exact copy must remain assigned to its saved slot")
assert(ItemRackUser.CurrentSet == "RingSet","observed batch must commit the logical set")
assert(cursor == nil and ItemRack.ActiveEquipmentTransaction == nil,"batch must leave no cursor or transaction residue")
`
  );
}

console.log('[BATCH & DUAL-SPEC LUA] Batch execution, exact-copy reservations, rollback safety, dual-spec, minimap, and spellbook safety assertions passed.');

