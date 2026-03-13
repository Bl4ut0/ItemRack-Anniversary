-- ItemRackQueue.lua
local _

-- Compatibility shims for Item APIs (globals may not exist if deprecation fallbacks disabled)
-- GetItemCooldown exists in both C_Container and C_Item - prefer C_Container for consistency
local GetItemCooldown = _G.GetItemCooldown or (C_Container and C_Container.GetItemCooldown) or (C_Item and C_Item.GetItemCooldown)
local GetItemSpell = _G.GetItemSpell or (C_Item and C_Item.GetItemSpell)
local GetItemCount = _G.GetItemCount or (C_Item and C_Item.GetItemCount)
local IsEquippedItem = _G.IsEquippedItem or (C_Item and C_Item.IsEquippedItem)

-- Queue debug prints use the global system:
-- Enable:  /script ItemRack.DebugTags.Queue = true
-- Disable: /script ItemRack.DebugTags.Queue = false

function ItemRack.PeriodicQueueCheck()
	-- Don't process queue during combat, death or while casting
	if ItemRack.inCombat or ItemRack.IsPlayerReallyDead() or ItemRack.NowCasting then return end
	
	-- Only process queues if global EnableQueues is ON and at least one slot is enabled
	if ItemRackUser.EnableQueues=="ON" then
		for i,v in pairs(ItemRack.GetQueuesEnabled()) do
			if v then
				ItemRack.ProcessAutoQueue(i)
			end
		end
		end
	else
		ItemRack.Debug("Queue","Global queues disabled (EnableQueues ~= ON)")
	end
end

-- Helper: Find next valid item in queue for a slot
function ItemRack.GetNextItemInQueue(slot)
	if not slot or IsInventoryItemLocked(slot) then return end

	local list = ItemRack.GetQueues()[slot]
	if not list then return end

	local baseID = ItemRack.GetIRString(GetInventoryItemLink("player",slot),true,true)
	if not baseID then return end

	-- simple loop to find current item in list and return next valid one
	local idx = 0
	for i=1,#(list) do
		local listBaseID = string.match(list[i].id,"(%d+)")
		if listBaseID == baseID then
			idx = i
			break
		end
	end

	-- Look forward from current item
	for i=idx+1,#(list) do
		if list[i].id~=0 then -- 0 is stop marker
			local candidate = string.match(list[i].id,"(%d+)")
			local count = candidate and GetItemCount(candidate) or 0
			if candidate and count>0 then
				return list[i].id
			end
		else
			break -- Hit stop marker
		end
	end
	
	-- Wrap around to start if nothing found after current
	for i=1,idx-1 do
		if list[i].id~=0 then
			local candidate = string.match(list[i].id,"(%d+)")
			local count = candidate and GetItemCount(candidate) or 0
			if candidate and count>0 then
				return list[i].id
			end
		end
	end
end

-- Simpler function for manual queue cycling (right-click advance)
-- Finds next item in queue and equips it directly, or queues for after combat
function ItemRack.ManualQueueAdvance(slot)
	if not slot or IsInventoryItemLocked(slot) then
		ItemRack.Debug("Queue", "ManualAdvance: slot locked or invalid")
		return
	end
	
	local list = ItemRack.GetQueues()[slot]
	if not list or #list == 0 then
		ItemRack.Debug("Queue", "ManualAdvance: no queue for slot", slot)
		return
	end
	
	-- Get currently equipped item's exact ID and base ID
	-- In combat, we might already have an item pending organically. Evaluate from the pending item first.
	local pendingID = ItemRack.CombatQueue[slot]
	local equippedExactID = pendingID or ItemRack.GetID(slot)
	local equippedBaseID = ItemRack.GetIRString(equippedExactID, true)
	ItemRack.Debug("Queue", "ManualAdvance slot", slot, "equipped:", equippedBaseID)
	
	-- Find current item in queue (exact match first)
	local currentIdx = 0
	for i = 1, #list do
		if list[i].id ~= 0 then
			if ItemRack.SameExactID(list[i].id, equippedExactID) then
				currentIdx = i
				break
			end
		end
	end
	
	-- If exact match fails, fallback to base ID match
	if currentIdx == 0 then
		for i = 1, #list do
			if list[i].id ~= 0 then
				local queueBaseID = string.match(tostring(list[i].id), "^(%d+)")
				if queueBaseID == equippedBaseID then
					currentIdx = i
					break
				end
			end
		end
	end
	
	ItemRack.Debug("Queue", "ManualAdvance currentIdx:", currentIdx)
	
	-- Helper to attempt swap
	local function tryEquip(itemID)
		local inv, bag, bagSlot = ItemRack.FindItem(itemID)
		if bag and bagSlot then
			ItemRack.Debug("Queue", "ManualAdvance equipping", itemID, "from bag", bag)
			ItemRack.EquipItemByID(itemID, slot)
			return true
		end
		return false
	end
	
	-- Try items after current index
	for i = currentIdx + 1, #list do
		if list[i].id == 0 then break end -- Stop marker
		if tryEquip(list[i].id) then return true end
	end
	
	-- Wrap around to start of queue
	for i = 1, currentIdx - 1 do
		if list[i].id == 0 then break end
		if tryEquip(list[i].id) then return true end
	end
	
	ItemRack.Debug("Queue", "ManualAdvance: no valid item found in bags")
	return false
end

function ItemRack.ProcessAutoQueue(slot)
	
	if not slot or IsInventoryItemLocked(slot) then return end

	local start,duration,enable = GetInventoryItemCooldown("player",slot)
	local timeLeft = math.max(start + duration - GetTime(),0)
	local baseID = ItemRack.GetIRString(GetInventoryItemLink("player",slot),true,true)
	local icon = _G["ItemRackButton"..slot.."Queue"]

	if not baseID then return end
	
	local list = ItemRack.GetQueues()[slot]
	local keepValue, delayValue, priorityValue
	
	-- Find the equipped item in the queue to get its priority/keep/delay settings
	if list then
		for i=1, #list do
			if list[i].id== 0 then
				-- Stop marker.  If we get here before finding our item, we'll just use defaults 
				-- since these values probably aren't intentionally set for any item not in our queue.
				keepValue = false
				delayValue = 0
				priorityValue = false
				break
			else
				if list[i].id == baseID then
					keepValue = list[i].keep
					delayValue = list[i].delay
					priorityValue = list[i].priority
					break
				end
			end
		end
	end
	
	-- Visual updates logic (keep/delay/buff checks)
	local buff = GetItemSpell(baseID)
	if buff and AuraUtil.FindAuraByName(buff,"player") then
		if icon then icon:SetDesaturated(true) end
		return
	end

	if keepValue then
		if icon then icon:SetVertexColor(1,.5,.5) end
		return
	end
	
	if delayValue then
		if start>0 and timeLeft>30 and timeLeft <= delayValue then
			if icon then icon:SetDesaturated(true) end
			return
		end
	end

	if icon then
		icon:SetDesaturated(false)
		icon:SetVertexColor(1,1,1)
	end

	-- logic to actually swap
	local ready = ItemRack.ItemNearReady(baseID)
	if ready and ItemRack.CombatQueue[slot] then
		ItemRack.CombatQueue[slot] = nil
		ItemRack.UpdateCombatQueue()
	end

	if not list then return end

	local nextItem, nextItemID = ItemRack.AutoQueueItemToEquip(slot, baseID, enable, ready)
	if nextItem then
		if GetItemCount(nextItem)>0 and not IsEquippedItem(nextItem) then
			local _,bag = ItemRack.FindItem(nextItemID)
			if bag and not (ItemRack.CombatQueue[slot]==nextItemID) then
				ItemRack.EquipItemByID(nextItemID,slot,true)
			end
		end
		
	end
end

function ItemRack.AutoQueueItemToEquip(slot, baseID, enable, ready)
	local list = ItemRack.GetQueues()[slot]
	local candidate
	-- reuse the loop structure but optimized for auto-queue logic (priority checks etc)
	-- This will return nil if no new item should be equipped.  
	--    - This is either because there is no auto queue or what we have equipped is already what we want.
	for i=1,#(list) do
		candidate = string.match(list[i].id,"(%d+)")
		-- If there is nothing at the top of our queue, return nil.
		if list[i].id==0 then
			return nil
		-- If baseID is near ready but our candidate IS baseID, return nil.
		elseif ready and candidate==baseID then
			return nil
		else
			local canSwap = not ready or enable==0 or list[i].priority
			if canSwap then
				if ItemRack.ItemNearReady(candidate) then
					return candidate, list[i].id
				end
			end
		end
	end
	
	return nil
end

function ItemRack.ItemNearReady(id)
	local start,duration = GetItemCooldown(id)
	if not tonumber(start) then return end -- can return nil shortly after loading screen
	if start==0 or math.max(start + duration - GetTime(),0)<=30 then
		return true
	end
end

function ItemRack.SetQueue(slot,newQueue)
	if not newQueue then
		ItemRack.GetQueuesEnabled()[slot] = nil
	elseif type(newQueue)=="table" then
		ItemRack.GetQueues()[slot] = ItemRack.GetQueues()[slot] or {}
		for i in pairs(ItemRack.GetQueues()[slot]) do
			ItemRack.GetQueues()[slot][i] = nil
		end
		for i=1,#(newQueue) do
			table.insert(ItemRack.GetQueues()[slot],newQueue[i])
		end
		if ItemRackOptFrame:IsVisible() then
			if ItemRackOptSubFrame7:IsVisible() and ItemRackOpt.SelectedSlot==slot then
				ItemRackOpt.SetupQueue(slot)
			else
				ItemRackOpt.UpdateInv()
			end
		end
		ItemRack.GetQueuesEnabled()[slot] = true
	end
	ItemRack.UpdateCombatQueue()
end
