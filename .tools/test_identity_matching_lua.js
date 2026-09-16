const fs = require('fs');
const { extractFunction, runLua } = require('./lib/lua_harness');

const core = 'ItemRack/ItemRack.lua';
const queue = 'ItemRack/ItemRackQueue.lua';
const options = 'ItemRackOptions/ItemRackOptions.lua';
const functions = [
  extractFunction(core, 'ItemRack.SameID'),
  extractFunction(core, 'ItemRack.GetRuneID'),
  extractFunction(core, 'ItemRack.HasRuneID'),
  extractFunction(core, 'ItemRack.IsBareItemID'),
  extractFunction(core, 'ItemRack.SameItemFields'),
  extractFunction(core, 'ItemRack.SameExactID'),
  extractFunction(core, 'ItemRack.MatchesStoredItemFields'),
  extractFunction(core, 'ItemRack.MatchesStoredItemID'),
  extractFunction(core, 'ItemRack.FindItem'),
  extractFunction(core, 'ItemRack.FindItemInBags'),
  extractFunction(queue, 'ItemRack.QueueHasExplicitIdentityEntry'),
  extractFunction(queue, 'ItemRack.IsQueueEntryUnambiguous'),
  extractFunction(queue, 'ItemRack.FindQueueEntryIndex'),
  extractFunction(options, 'ItemRackOpt.AddToSortList'),
].join('\n');

runLua(String.raw`
local wrong = "33881:2647:24028:0:0:0:0:0:70:0"
local wanted = "33881:2648:24028:0:0:0:0:0:70:0"
local wantedLong = "33881:2648:24028:0:0:0:0:0:70:0:0:0:0"
local bags = { [0]={ [1]=wrong, [2]=wantedLong } }
local inventory = { [9]=wrong }

ItemRack = {
  iSPatternBaseIDFromIR="^(%-?%d+)",
  iSPatternItemFieldsFromIR="^(%-?%d+:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*)",
  iSPatternRuneIDFromIR=":runeid:(%d+)$",
  LockList={ [-2]={}, [0]={}, [1]={}, [2]={}, [3]={}, [4]={} },
  KnownItems={}, BankOpen=false,
  GetIRString=function(value,base)
    if base then return tostring(value or ""):match("^(%-?%d+)") or 0 end
    return value or 0
  end,
  UpdateIRString=function(value) return value end,
  GetID=function(bag,slot)
    if slot then return bags[bag] and bags[bag][slot] or 0 end
    return inventory[bag] or 0
  end,
  FindInBank=function() end,
}
ItemRackOpt = {}
function GetContainerNumSlots(bag) return bag == 0 and 2 or 0 end

${functions}

local checks = 0
local function check(value,message) assert(value,message); checks = checks + 1 end

check(not ItemRack.MatchesStoredItemID(wanted,wrong),
  "a different enchant on the same base item must not satisfy a saved set slot")
check(ItemRack.MatchesStoredItemID("33881",wrong),
  "an intentionally bare default ID must retain base-item compatibility")
check(ItemRack.MatchesStoredItemID(wanted,wantedLong),
  "variable-length live item strings must match by stable item fields")

local inv,bag,slot = ItemRack.FindItem(wanted,true)
check(not inv and bag == 0 and slot == 2,
  "exact bag copy must win over a wrong-enchant equipped or earlier bag copy")
bags[0][2] = nil
ItemRack.LockList[0] = {}
ItemRack.LockList[-2] = {}
inv,bag,slot = ItemRack.FindItem(wanted,true)
check((bag == 0 and slot == 1) or inv == 9,
  "same-base fallback must remain available when the recorded copy is absent")

local runeWanted = wanted..":runeid:7"
local runeOther = wantedLong..":runeid:9"
check(not ItemRack.MatchesStoredItemID(runeWanted,runeOther),
  "a saved rune identity must reject a different rune")
check(ItemRack.MatchesStoredItemID(wanted,runeOther),
  "a pre-rune full identity may follow the same physical copy after engraving")

local queueList = { { id=wrong }, { id=wanted } }
check(ItemRack.FindQueueEntryIndex(queueList,wantedLong) == 2,
  "queue lookup must distinguish same-base copies by enchant")
local mixedList = { { id="33881" }, { id=wanted } }
check(not ItemRack.IsQueueEntryUnambiguous(mixedList,1),
  "a bare wildcard must not shadow an explicit same-base queue identity")

local sortList = { { id=wrong } }
ItemRackOpt.AddToSortList(sortList,wanted)
check(#sortList == 2, "queue editor must list differently enchanted copies separately")
ItemRackOpt.AddToSortList(sortList,wantedLong)
check(#sortList == 2, "queue editor must coalesce only the same stable item identity")

print(string.format("[IDENTITY MATCHING LUA] %d exact-copy compatibility checks passed.",checks))
`, 'identity-matching');
