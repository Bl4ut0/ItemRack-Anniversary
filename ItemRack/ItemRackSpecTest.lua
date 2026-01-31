-- Temporary test frame to verify spec change events fire
local testFrame = CreateFrame("Frame")
testFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
testFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
testFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
testFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

testFrame:SetScript("OnEvent", function(self, event, ...)
	print("[SPEC TEST] Event fired: " .. event)
	if GetActiveTalentGroup then
		print("[SPEC TEST] Current spec: " .. tostring(GetActiveTalentGroup()))
	end
end)

print("[SPEC TEST] Test frame loaded. Switch specs to see if events fire.")
