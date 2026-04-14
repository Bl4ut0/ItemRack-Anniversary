-- ItemRackEquip.lua : ItemRack.EquipSet and its supporting functions.
local GetContainerNumSlots, GetContainerItemLink, GetContainerItemCooldown, GetContainerItemInfo, GetItemCooldown, PickupContainerItem, ContainerIDToInventoryID
if C_Container then
	GetContainerNumSlots = C_Container.GetContainerNumSlots
	GetContainerItemLink = C_Container.GetContainerItemLink
	GetContainerItemCooldown = C_Container.GetContainerItemCooldown
	GetItemCooldown = C_Container.GetItemCooldown
	PickupContainerItem = C_Container.PickupContainerItem
	ContainerIDToInventoryID = C_Container.ContainerIDToInventoryID
	GetContainerItemInfo = function(bag, slot)
		local info = C_Container.GetContainerItemInfo(bag, slot)
		if info then
			return info.iconFileID, info.stackCount, info.isLocked, info.quality, info.isReadable, info.hasLoot, info.hyperlink, info.isFiltered, info.hasNoValue, info.itemID, info.isBound
		else
			return
		end
	end
else
	GetContainerNumSlots, GetContainerItemLink, GetContainerItemCooldown, GetContainerItemInfo, GetItemCooldown, PickupContainerItem, ContainerIDToInventoryID =
	_G.GetContainerNumSlots, _G.GetContainerItemLink, _G.GetContainerItemCooldown, _G.GetContainerItemInfo, _G.GetItemCooldown, _G.PickupContainerItem, _G.ContainerIDToInventoryID
end

ItemRack.SwapList = {} -- table of item ids that want to swap in, indexed by slot
ItemRack.AbortSwap = nil -- reasons: 1=not enough room, 2=item on cursor, 3=in spell targeting mode, 4=item lock
ItemRack.AbortReasons = {"Not enough room.","Something is on the cursor.","In spell targeting mode.","Another swap is in progress."}

ItemRack.SetsWaiting = {} -- numerically indexed table of {"setname",func} ie {"pvp",ItemRack.EquipSet}

-- Legion artifact items that act as two items
ItemRack.PhantomItem = {
	[128293] = true, -- Blades of the Fallen Prince (frost death knight)
	[127830] = true, -- Twinblades of the Deceiver (havoc demon hunter)
	[128831] = true, -- Aldrachi Warblades (vengeance demon hunter)
	[128859] = true, -- Fangs of Ashamane (feral druid)
	[128822] = true, -- Claws of Ursoc (guardian druid)
	[133959] = true, -- Heart of the Phoenix (fire mage)
	[133948] = true, -- Fists of the Heavens (windwalker monk)
	[128867] = true, -- Oathseeker (prot pally)
	[133958] = true, -- Secrets of the Void (shadow priest)
	[128869] = true, -- The Kingslayers (assassin rogue)
	[134552] = true, -- The Dreadblades (outlaw rogue)
	[128479] = true, -- Fangs of the Devourer (subtlety rogue)
	[128936] = true, -- The Highkeeper's Ward (ele shaman)
	[128873] = true, -- Fury of the Stonemother (enh shaman)
	[128934] = true, -- Shield of the Sea Queen (resto shaman)
	[128943] = true, -- Skull of the Man'ari (demo lock)
	[134553] = true, -- Warswords of the Valarjar (fury warrior)
	[128289] = true, -- Scale of the Earth-Warder (prot warrior)
}

ItemRack.UniqueGems = {
	-- Wrath JC gems
	[36766] = 3, --bright-dragons-eye
	[36767] = 3, --solid-dragons-eye
	[42142] = 3, --bold-dragons-eye
	[42143] = 3, --delicate-dragons-eye
	[42144] = 3, --runed-dragons-eye
	[42145] = 3, --sparkling-dragons-eye
	[42146] = 3, --lustrous-dragons-eye
	[42148] = 3, --brilliant-dragons-eye
	[42149] = 3, --smooth-dragons-eye
	[42150] = 3, --quick-dragons-eye
	[42151] = 3, --subtle-dragons-eye
	[42152] = 3, --flashing-dragons-eye
	[42153] = 3, --fractured-dragons-eye
	[42154] = 3, --precise-dragons-eye
	[42155] = 3, --stormy-dragons-eye
	[42156] = 3, --rigid-dragons-eye
	[42157] = 3, --thick-dragons-eye
	[42158] = 3, --mystic-dragons-eye
	[49110] = 3, --nightmare-tear
	-- Other
	[27679] = 1, --sublime-mystic-dawnstone
	[27777] = 1, --stark-blood-garnet
	[27785] = 1, --notched-deep-peridot
	[27786] = 1, --barbed-deep-peridot
	[27809] = 1, --barbed-deep-peridot
	[27812] = 1, --stark-blood-garnet
	[27820] = 1, --notched-deep-peridot
	[28360] = 1, --mighty-blood-garnet
	[28361] = 1, --mighty-blood-garnet
	[28556] = 1, --swift-windfire-diamond
	[28557] = 1, --swift-starfire-diamond
	[30571] = 1, --don-rodrigos-heart
	[30598] = 1, --don-amancios-heart
	[32634] = 1, --unstable-amethyst
	[32635] = 1, --unstable-peridot
	[32636] = 1, --unstable-sapphire
	[32637] = 1, --unstable-citrine
	[32638] = 1, --unstable-topaz
	[32639] = 1, --unstable-talasite
	[32735] = 1, --radiant-spencerite
	[33131] = 1, --crimson-sun
	[33132] = 1, --delicate-fire-ruby
	[33133] = 1, --don-julios-heart
	[33134] = 1, --kailees-rose
	[33135] = 1, --falling-star
	[33137] = 1, --sparkling-falling-star
	[33138] = 1, --mystic-bladestone
	[33139] = 1, --brilliant-bladestone
	[33140] = 1, --blood-of-amber
	[33141] = 1, --great-bladestone
	[33142] = 1, --rigid-bladestone
	[33143] = 1, --stone-of-blades
	[33144] = 1, --facet-of-eternity
	[34256] = 1, --charmed-amani-jewel
	[34831] = 1, --eye-of-the-sea
	[42701] = 1, --enchanted-pearl
	[42702] = 1, --enchanted-tear
	[44066] = 1, --kharmaas-grace
	--[41492] = 1, --perfect-inscribed-citrine DEBUG
}
ItemRack.eqBackOfTheBusOffset = 100

function ItemRack.ProcessSetsWaiting()
	local setwaiting = ItemRack.SetsWaiting[1][1]
	local whichequip = ItemRack.SetsWaiting[1][2]
	local disableSound = ItemRack.SetsWaiting[1][3]
	table.remove(ItemRack.SetsWaiting,1)
	
	-- Safety: Skip sets that no longer exist (prevents getting stuck)
	if not ItemRackUser.Sets[setwaiting] then
		-- Set was deleted, skip it and try the next one
		if #ItemRack.SetsWaiting > 0 then
			ItemRack.ProcessSetsWaiting()
		end
		return
	end
	
	whichequip(setwaiting, disableSound)
end

function ItemRack.AddSetToSetsWaiting(setwaiting,whichequip,disableSound)
	local wait = ItemRack.SetsWaiting
	for i in pairs(wait) do
		if wait[i][1]==setwaiting and wait[i][2]==whichequip then
			return
		end
	end
	table.insert(wait,{setwaiting,whichequip,disableSound})
end

function ItemRack.OrderSwaps(swap)
	for k,v in pairs(swap) do
		if swap[k] and swap[k] ~= 0 then
			local itemID, enchantID, gem1, gem2, gem3 = ItemRack.GetEnhancements(swap[k])
			if (ItemRack.UniqueGems[gem1] or ItemRack.UniqueGems[gem2] or ItemRack.UniqueGems[gem3])
			and k < ItemRack.eqBackOfTheBusOffset then
				swap[k+ItemRack.eqBackOfTheBusOffset] = v
				swap[k] = nil
			end
		end
	end
end

function ItemRack.EquipSet(setname, disableSound)
	if not setname or not ItemRackUser.Sets[setname] then
		ItemRack.Print("Set \""..tostring(setname).."\" doesn't exist.")
		return
	end
	if ItemRack.AnythingLocked() then
		-- a swap is in progress, add this set to the wait list and leave
		ItemRack.AddSetToSetsWaiting(setname,ItemRack.EquipSet, disableSound)
		return
	end
	local set = ItemRackUser.Sets[setname]
	local swap = ItemRack.SwapList
	for i in pairs(swap) do
		swap[i] = nil
	end
	local inv,bag,slot
	local couldntFind
	local inCombat = InCombatLockdown()
	local isInternalSet = setname and string.sub(setname, 1, 1) == "~" -- Internal sets like ~Unequip, ~CombatQueue, ~DualWieldRetry
	
	if ItemRack.BurntQueueItems then
		for i in pairs(set.equip) do
			if type(i) == "number" then
				ItemRack.BurntQueueItems[i] = nil
			end
		end
	end
	
	for i in pairs(set.equip) do
		if type(i) == "number" then
			if ItemRack.GetID(i)~=set.equip[i] then -- if intended item is not worn (exact match)
				inv,bag,slot = ItemRack.FindItem(set.equip[i])
				if not inv and not bag then
					-- if not found at all, then start/add to list of items not found
					-- Suppress these messages during combat or for internal sets (they're noise)
					if not inCombat and not isInternalSet then
						couldntFind = couldntFind or "Could not find: "
						couldntFind = couldntFind.."["..tostring(ItemRack.GetInfoByID(set.equip[i])).."] "
					end
				elseif inv~=i then -- and finding intended item doesn't point to worn
					swap[i] = set.equip[i] -- then note this item for a swap
				end
			end
		end
	end
	ItemRack.Print(couldntFind) -- if couldntFind is nil then nothing will print

	-- at this point, ItemRack.SwapList has only what needs to be swapped, indexed by slot
	if not next(swap) then
--		ItemRack.Print("Set already equipped.")
		ItemRack.EndSetSwap(setname) -- end swap if set already equipped
		return
	end

	if set.old then
		for i in pairs(set.old) do
			set.old[i] = nil -- wipe old items
		end
		set.oldset = ItemRackUser.CurrentSet
	end

	-- if in combat, dead, or casting, queue ALL items for later
	-- PickupInventoryItem is blocked by the game during InCombatLockdown() for all items including weapons
	if InCombatLockdown() or ItemRack.IsPlayerReallyDead() or ItemRack.NowCasting then
		for i in pairs(swap) do
			ItemRack.AddToCombatQueue(i,swap[i])
			swap[i] = nil
			if set.old then
				set.old[i] = ItemRack.GetID(i)
				ItemRack.CombatSet = setname
			elseif set.oldset then
				ItemRack.CombatSet = set.oldset
			end
		end
	end
	if not next(swap) then
		return
	end

	if ItemRackUser.Sets[setname].ShowHelm ~= nil then
		if ItemRackUser.Sets[setname].ShowHelm == 1 then
			ShowHelm(true)
		else
			ShowHelm(false)
		end
	end
	
	if ItemRackUser.Sets[setname].ShowCloak ~= nil then
		if ItemRackUser.Sets[setname].ShowCloak == 1 then
			ShowCloak(true)
		else
			ShowCloak(false)
		end
	end

	ItemRack.OrderSwaps(swap) -- bump items with unique gems to the end of the line

	ItemRack.IterateSwapList(setname, disableSound) -- run SwapList swaps
	if not next(swap) then
		ItemRack.EndSetSwap(setname)
		return -- leave if swap completed on first pass
	end

	-- If we're in combat and weapon swaps failed (e.g. cursor issue), move remaining
	-- items to CombatQueue instead of entering SetSwapping wait state, which can get
	-- stuck. The CombatQueue will process them cleanly when combat ends.
	if InCombatLockdown() then
		for i in pairs(swap) do
			ItemRack.AddToCombatQueue(i, swap[i])
			if set.old then
				set.old[i] = ItemRack.GetID(i)
				ItemRack.CombatSet = setname
			end
			swap[i] = nil
		end
		return
	end

	-- a second pass is needed. ItemRack.SwapList (swap) has the list of remaining items to swap.
	-- With ItemRack.SetSwapping defined, ITEM_LOCK_CHANGED will call LockChangedDuringSetSwap()
	-- to determine when to run a second pass.
	ItemRack.SetSwapping = setname
	ItemRack.SetSwappingDisableSound = disableSound

	-- Safety timeout: if SetSwapping is never cleared (e.g. locks never fire for a failed swap),
	-- force-clear after 5s to prevent the permanent "stuck until logout" state.
	ItemRack.StartSetSwapTimeout()
end

-- Starts (or restarts) a 5-second safety timer that force-clears SetSwapping if it
-- hasn't been resolved by then. Prevents the addon from getting permanently stuck.
function ItemRack.StartSetSwapTimeout()
	if ItemRack.SetSwapTimeout then
		ItemRack.SetSwapTimeout:Cancel()
	end
	ItemRack.SetSwapTimeout = C_Timer.NewTimer(5, function()
		if ItemRack.SetSwapping then
			ItemRack.Debug("Equip", "SetSwapping safety timeout — force clearing stuck state for:", ItemRack.SetSwapping)
			ItemRack.SetSwapping = nil
			ItemRack.SetSwappingDisableSound = nil
			ItemRack.SetSwapTimeout = nil
			-- Clear any remaining swap list entries that can't complete
			for i in pairs(ItemRack.SwapList) do
				ItemRack.SwapList[i] = nil
			end
			-- Try to process any sets that were waiting
			if #ItemRack.SetsWaiting > 0 and not ItemRack.AnythingLocked() and not ItemRack.NowCasting then
				ItemRack.ProcessSetsWaiting()
			end
		end
	end)
end

function ItemRack.AnythingLocked()
	-- Guard: if the cursor is holding an item (e.g. from a failed swap), treat as locked
	if CursorHasItem() then
		return 1
	end
	for i=1,19 do
		if IsInventoryItemLocked(i) then
			return 1
		end
	end
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			if select(3,GetContainerItemInfo(i,j)) then
				return 1
			end
		end
	end
end

function ItemRack.LockChangedDuringSetSwap()
	if not ItemRack.AnythingLocked() then
		local setname = ItemRack.SetSwapping
		local disableSound = ItemRack.SetSwappingDisableSound
		ItemRack.SetSwapping = nil
		ItemRack.SetSwappingDisableSound = nil
		ItemRack.IterateSwapList(setname, disableSound)

		-- Re-check: if the second pass locked new items or left work undone,
		-- re-enter swap-waiting mode instead of immediately starting the next swap.
		if next(ItemRack.SwapList) or ItemRack.AnythingLocked() then
			ItemRack.SetSwapping = setname
			ItemRack.SetSwappingDisableSound = disableSound
			-- Restart the safety timeout for this new waiting period
			ItemRack.StartSetSwapTimeout()
			return
		end

		ItemRack.EndSetSwap(setname)

		if #ItemRack.SetsWaiting > 0 and not ItemRack.NowCasting then
			-- Defer to next frame to let lock state fully settle before starting
			-- the next swap. This prevents the "Internal bag error" from rapid swaps.
			C_Timer.After(0, function()
				if not ItemRack.AnythingLocked() and not ItemRack.NowCasting and #ItemRack.SetsWaiting > 0 then
					ItemRack.ProcessSetsWaiting()
				end
			end)
		end
	end
end

function ItemRack.IterateSwapList(setname, disableSound)
 
	local set = ItemRackUser.Sets[setname]
	local swap = ItemRack.SwapList

	local useSound = GetCVar("Sound_EnableSFX")
	local overrideSound = false
	local usedSurgicalMute = false
	if (disableSound or ItemRackSettings.DisableSwapSound == "ON") and useSound == "1" then
		-- Try surgical muting via LibSoundIndex (mutes equip and UI sounds)
		if ItemRack.MuteSwapSounds(1.5) then
			usedSurgicalMute = true
		else
			-- Fallback: blunt CVar mute (silences ALL SFX)
			SetCVar("Sound_EnableSFX", "0")
			overrideSound = true
		end
	end

	ItemRack.AbortSwap = nil
	ItemRack.ClearLockList()

	local treatAs2H = nil
	local skip, inv, bag, slot
	for k=0,19+ItemRack.eqBackOfTheBusOffset do
		local i = k
		if k >= ItemRack.eqBackOfTheBusOffset then
			i = k-ItemRack.eqBackOfTheBusOffset
		end
		if skip or ItemRack.AbortSwap then
			skip = nil
		elseif swap[k] then
			if swap[k]==0 then -- if intended to be empty
				bag,slot = ItemRack.FindSpace()
				if bag then
					if set.old then
						set.old[i] = ItemRack.GetID(i)
					end
					ItemRack.MoveItem(i,nil,bag,slot) -- empty slot
					if not ItemRack.AbortSwap then
						swap[k] = nil
					end
				else
					ItemRack.AbortSwap = 1
					return
				end
			else
				inv,bag,slot = ItemRack.FindItem(swap[k],1)
				if bag then
					if i==16 and ItemRack.HasTitansGrip then
						local subtype = select(7,GetItemInfo(GetContainerItemLink(bag,slot)))
						if subtype and ItemRack.NoTitansGrip[subtype] then
							treatAs2H = 1
						end
					end
					-- TODO: Polarms, Fishing Poles and Staves (7th GetItemInfo) cannot
					-- be equipped alongside Two-Handed Axes, Two-Handed Maces and Two-Handed Swords
					if (not ItemRack.HasTitansGrip or treatAs2H) and select(3,ItemRack.GetInfoByID(swap[k]))=="INVTYPE_2HWEAPON" then
						-- this is a 2H weapon. swap both slots at once if offhand equipped
						if set.old then
							set.old[i] = ItemRack.GetID(i)
							set.old[i+1] = ItemRack.GetID(i+1)
						end
						if GetInventoryItemLink("player",17) then
							local freeBag,freeSlot = ItemRack.FindSpace()
							if freeBag then
								ItemRack.MoveItem(17,nil,freeBag,freeSlot)
							else
								ItemRack.AbortSwap=1
							end
						end
						if not ItemRack.AbortSwap then
							ItemRack.MoveItem(bag,slot,16,nil)
						end
						if not ItemRack.AbortSwap then
							swap[k] = nil
							swap[k+1] = nil -- fix by Romracer
						end
						skip = 1
					else
						if set.old then
							set.old[i] = ItemRack.GetID(i)
						end
						ItemRack.MoveItem(bag,slot,i,nil)
						if not ItemRack.AbortSwap then
							swap[k] = nil
						end
					end
				elseif inv==(i+1) and ItemRack.SameID(swap[k+1],ItemRack.GetID(i)) then
					-- item is in other slot and other slot wants to go to this one
					if set.old then
						set.old[i] = ItemRack.GetID(i)
						set.old[i+1] = ItemRack.GetID(i+1)
					end
					ItemRack.MoveItem(i,nil,i+1,nil)
					if not ItemRack.AbortSwap then
						swap[k] = nil
						swap[k+1] = nil
					end
					skip = 1
				end
			end
		end
	end
	-- Only print abort message if there are no remaining items to retry.
	-- During multi-pass swaps, AbortSwap=4 (locked items) is expected and will
	-- be retried via SetSwapping — printing "Another swap is in progress" here is misleading.
	if ItemRack.AbortSwap and not InCombatLockdown() and not next(swap) then
		ItemRack.Print("Swap stopped. "..(ItemRack.AbortReasons[ItemRack.AbortSwap] or ""))
	end
	-- Safety: if cursor still has an item from a partial swap, clear it so it doesn't
	-- block subsequent swaps. ClearCursor() returns the item to its original location.
	if CursorHasItem() then
		ClearCursor()
	end
	-- CVar fallback restore
	if overrideSound then
		if ItemRack.CVarMuteTimer then
			ItemRack.CVarMuteTimer:Cancel()
		end
		ItemRack.CVarMuteTimer = C_Timer.NewTimer(1.5, function()
			SetCVar("Sound_EnableSFX", "1")
			ItemRack.CVarMuteTimer = nil
		end)
	end
end

function ItemRack.EndSetSwap(setname)
	ItemRack.SetSwapping = nil
	-- Cancel safety timeout since swap completed normally
	if ItemRack.SetSwapTimeout then
		ItemRack.SetSwapTimeout:Cancel()
		ItemRack.SetSwapTimeout = nil
	end
	if setname then
		if not string.match(setname,"^~") then --do not list internal sets, prefixed with ~
			ItemRackUser.CurrentSet = setname
			C_Timer.After(0.5, ItemRack.UpdateCurrentSet)
			
			-- Dual Spec Support: Auto-Swap Spec if Set is bound
			local set = ItemRackUser.Sets[setname]
			if set.AssociatedSpec then
				if GetActiveTalentGroup and GetNumTalentGroups then
					local currentSpec = GetActiveTalentGroup()
					local numGroups = GetNumTalentGroups()
					local neededSpec = set.AssociatedSpec
					
					if numGroups > 1 and currentSpec ~= neededSpec then
						ItemRack.Print("Set "..setname.." requires Spec "..neededSpec.." (Current: "..currentSpec.."). Switching...")
						if SetActiveTalentGroup then
							SetActiveTalentGroup(neededSpec)
						end
					else
						-- Diagnostic for when it doesn't switch
						-- ItemRack.Print("Spec Check: No switch needed. neededSpec="..tostring(neededSpec).." current="..tostring(currentSpec).." numGroups="..tostring(numGroups))
					end
				end
			end
		elseif ItemRackUser.Sets[setname].oldset then
			-- Internal set (e.g. ~Unequip, ~CombatQueue) finished restoring gear.
			-- Set CurrentSet back to the set name stored in oldset.
			ItemRackUser.CurrentSet = ItemRackUser.Sets[setname].oldset
			ItemRackUser.Sets[setname].oldset = nil
			C_Timer.After(0.5, ItemRack.UpdateCurrentSet)
		end
		if ItemRackOptFrame and ItemRackOptFrame:IsVisible() then
			-- Only jump to the equipped set if the user isn't currently editing one
			if not ItemRackOptSetsSaveButton:IsEnabled() then
				ItemRackOpt.ChangeEditingSet()
			end
		end
		
		ItemRack.UpdateCombatQueue() -- update button gear icon if per set queues is active
	end
--	ItemRack.Print("End of set swap. CurrentSet: "..tostring(ItemRackUser.CurrentSet))
end

-- moves an item from bag,slot to bag,slot (slot is nil for bag=inv)
function ItemRack.MoveItem(fromBag,fromSlot,toBag,toSlot)
	local destSlot = toSlot and "bag" or toBag -- for debug: which inv slot is the target
	local abort
	if CursorHasItem() then
		abort = 2
		ItemRack.Debug("CombatQueue", "MoveItem ABORT=2 (CursorHasItem) dest="..tostring(destSlot))
	elseif SpellIsTargeting() then
		abort = 3
		ItemRack.Debug("CombatQueue", "MoveItem ABORT=3 (SpellIsTargeting) dest="..tostring(destSlot))
	elseif not fromSlot and ItemRack.PhantomItem[GetInventoryItemID("player",fromBag) or 1] then
		ItemRack.Debug("CombatQueue", "MoveItem SKIP (PhantomItem) dest="..tostring(destSlot))
		return  -- oscarucb: ignore swap requests on slots containing "phantom" artifact items
	elseif (not fromSlot and IsInventoryItemLocked(fromBag)) or (not toSlot and IsInventoryItemLocked(toBag)) then
		abort = 4
		ItemRack.Debug("CombatQueue", "MoveItem ABORT=4 (InventoryItemLocked) dest="..tostring(destSlot).." fromLocked="..tostring(not fromSlot and IsInventoryItemLocked(fromBag)).." toLocked="..tostring(not toSlot and IsInventoryItemLocked(toBag)))
	elseif (fromSlot and select(3,GetContainerItemInfo(fromBag,fromSlot))) or (toSlot and select(3,GetContainerItemInfo(toBag,toSlot))) then
		abort = 4
		ItemRack.Debug("CombatQueue", "MoveItem ABORT=4 (ContainerItemLocked) dest="..tostring(destSlot))
	end
	if abort then
		ItemRack.AbortSwap = abort
		return
	else
		ItemRack.Debug("CombatQueue", "MoveItem ATTEMPT from=("..tostring(fromBag)..","..tostring(fromSlot)..") to=("..tostring(toBag)..","..tostring(toSlot)..") combat="..tostring(InCombatLockdown()))
		if fromSlot then
			PickupContainerItem(fromBag,fromSlot)
		else
			PickupInventoryItem(fromBag)
		end
		if toSlot then
			PickupContainerItem(toBag,toSlot)
		else
			if toBag == INVSLOT_AMMO then -- workaround for classic ammo slot weirdness
				toBag = INVSLOT_RANGED
			end
			PickupInventoryItem(toBag)
		end
		-- Post-swap safety: if cursor still has an item, the target pickup was
		-- blocked (e.g. by combat timing, GCD, animation). Return the item to
		-- its source immediately so nothing gets stuck on the cursor.
		if CursorHasItem() then
			ItemRack.Debug("CombatQueue", "MoveItem POST-SWAP FAIL: cursor still has item after swap to dest="..tostring(destSlot)..". ClearCursor called.")
			ClearCursor()
			ItemRack.AbortSwap = 4
		else
			ItemRack.Debug("CombatQueue", "MoveItem SUCCESS dest="..tostring(destSlot))
		end
	end
end

function ItemRack.IsSetEquipped(setname,exact)
	if setname and ItemRackUser.Sets[setname] then
		local set = ItemRackUser.Sets[setname].equip
		local id
		local same = ItemRack.SameID
		
		-- Special handling for Trinkets and Rings to allow swapped slots
		local check11_12 = (set[11] and set[12])
		local check13_14 = (set[13] and set[14])
		
		local anyChecked = false
		for i in pairs(set) do
			if type(i) == "number" then
				anyChecked = true
				id = ItemRack.GetID(i)
				local match = false
				
				if (exact and set[i]==id) or (not exact and same(set[i],id)) then
					match = true
				elseif not exact then
					-- Try cross-slot check for Rings (11/12)
					if (i==11 or i==12) and check11_12 then
						local otherID = ItemRack.GetID(i==11 and 12 or 11)
						if same(set[i], otherID) then match = true end
					-- Try cross-slot check for Trinkets (13/14)
					elseif (i==13 or i==14) and check13_14 then
						local otherID = ItemRack.GetID(i==13 and 14 or 13)
						if same(set[i], otherID) then match = true end
					end
				end
				
				-- If the slot has an active auto-queue, verify that the equipped item is what the queue wants
				-- (prevents zone/buff events from seeing the set as "equipped" when a queue swap is pending)
				local slotQueue = ItemRack.GetQueues(setname)[i]
				if slotQueue and #slotQueue > 0 and ItemRack.GetQueuesEnabled(setname)[i] then
					if match then
						local baseID = ItemRack.GetIRString(GetInventoryItemLink("player",i),true,true)
						local start,duration,enable = GetInventoryItemCooldown("player",i)
						local ready = ItemRack.ItemNearReady(baseID, i)
						local active = ItemRack.AutoQueueItemToEquip(i, baseID, enable, ready)
						if active and not same(active, id) then
							match = false   -- Auto Queue would swap to a different item
						end
						-- if active is nil, no swap would occur → keep match as is
					end
				end
				
				if not match then return false end
			end
		end
		
		return anyChecked
	end
end

function ItemRack.UnequipSet(setname, disableSound)
	if setname and ItemRackUser.Sets[setname] and ItemRackUser.Sets[setname].old then
		if ItemRack.AnythingLocked() then
			ItemRack.AddSetToSetsWaiting(setname,ItemRack.UnequipSet, disableSound)
			return
		end
		
		-- Stack Splicing Logic:
		-- Check if another set (e.g. "Zoomies") is currently holding this set (e.g. "Drank") as its 'oldset'.
		-- If so, we are unequipping a set that is "buried" in the stack (Drinking stopped while Mounted).
		-- We must splice it out: update parent's oldset, restore items, but DO NOT update CurrentSet.
		local parentSet = nil
		for sName, sData in pairs(ItemRackUser.Sets) do
			if not string.match(sName, "^~") and sData.oldset == setname and sData.key ~= setname then -- ensure not self-referential
				parentSet = sName
				break 
			end
		end

		local old = ItemRackUser.Sets[setname].old
		local unequip = ItemRackUser.Sets["~Unequip"].equip
		for i in pairs(unequip) do
			unequip[i] = nil
		end
		for i in pairs(old) do
			if type(i) == "number" then
				unequip[i] = old[i]
			end
		end
		
		local shouldRestore = false
		if parentSet then
			-- We are buried. Patch the chain.
			-- Parent ("Zoomies") should now point to Our Previous ("Normal") instead of Us ("Drank")
			ItemRackUser.Sets[parentSet].oldset = ItemRackUser.Sets[setname].oldset
			
			-- Only restore items if the parent is an active event.
			-- If it's a manual set, the user's gear choice should be respected.
			if ItemRackUser.EventStack then
				for _, eName in ipairs(ItemRackUser.EventStack) do
					if ItemRackUser.Events.Set[eName] == parentSet then
						shouldRestore = true
						break
					end
				end
			end
			-- Prepare ~Unequip to restore items, but set oldset to nil so EndSetSwap doesn't change CurrentSet
			ItemRackUser.Sets["~Unequip"].oldset = nil
		elseif ItemRackUser.CurrentSet == setname then
			-- Normal unequip (Top of stack and matches CurrentSet)
			shouldRestore = true
			ItemRackUser.Sets["~Unequip"].oldset = ItemRackUser.Sets[setname].oldset
			if ItemRackUser.Sets[ItemRackUser.Sets["~Unequip"].oldset] then
				ItemRackUser.Sets["~Unequip"].ShowHelm = ItemRackUser.Sets[ItemRackUser.Sets["~Unequip"].oldset].ShowHelm
				ItemRackUser.Sets["~Unequip"].ShowCloak = ItemRackUser.Sets[ItemRackUser.Sets["~Unequip"].oldset].ShowCloak
			end
		end
		
		if shouldRestore then
			ItemRack.EquipSet("~Unequip", disableSound)
		else
			-- Restore was suppressed (manual override). Clean up stale old/oldset
			-- on the popped set so it doesn't linger in SavedVariables.
			for k in pairs(old) do
				old[k] = nil
			end
			ItemRackUser.Sets[setname].oldset = nil
		end
	end
end

function ItemRack.ToggleSet(setname,exact,disableSound)
	if ItemRack.IsSetEquipped(setname,exact) then
--		print("remove "..setname)
		ItemRack.UnequipSet(setname,disableSound)
	else
--		print("equip "..setname)
		ItemRack.EquipSet(setname,disableSound)
	end
end
