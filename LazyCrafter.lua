local db = {
	-- First aid, id 158741
	-- Tailoring
	[168835] = 158758,
	[125523] = 158758,
	[176058] = 158758,
	-- Engineering
	[177054] = 158739,
	[169080] = 158739,
	-- Enchanting - 333
	[169092] = 158716,
	[177043] = 158716,	
	-- Inscription - 773
	[169081] = 158748,
	[177045] = 158748,
	--Jewelcrafting - 755
	[170700] = 158750,
	[176087] = 158750,
	--Leatherworking - 165
	[171391] = 158752,
	[176089] = 158752,
	--Alchemy - 171
	[156587] = 156606,
	[175880] = 156606,
	-- Blacksmithing - 164
	[171690] = 158737,
	[176090] = 158737,
	-- Mining - 186
}

--------------------------------------------

local buttons = {}
frameskillModded = false
local intents=1

local backdropFrame = {	bgFile = [[Interface\BUTTONS\WHITE8X8]], tile = false, tileSize = 0, insets = { left = -intents, right = -intents, top = -intents, bottom = -intents}}
local backdropButton = { bgFile = [[Interface\BUTTONS\WHITE8X8]], edgeFile = [[Interface\BUTTONS\WHITE8X8]], edgeSize = 1, tile = false, tileSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0}}

--------------------------------------------

local LCButtonFrame = CreateFrame("Frame","LCButtonFrame",UIParent)
LCButtonFrame:RegisterEvent("PLAYER_LOGIN")

--------------------------------------------

local function updatePositions()
	local visibleButtonCount = 0
	local lastButton 

	for spellID, button in next, buttons do
		if button:IsShown() then
			visibleButtonCount = visibleButtonCount + 1
			LCButtonFrame:SetWidth(visibleButtonCount*(LazyCrafter_Vars.buttonSize+4)-4)
			button:ClearAllPoints()
			if visibleButtonCount == 1 then
				button:SetPoint("BOTTOMLEFT",LCButtonFrame)
			else
				button:SetPoint("LEFT",lastButton,"RIGHT",4,0)
			end
			lastButton = button
		end
	end


end

--------------------------------------------

local function onCooldown(spellID)
	return GetSpellCooldown(spellID) ~=0
end

--------------------------------------------

local function createButton(buttonID)
	local button = CreateFrame("Button", "LC_"..buttonID, LCButtonFrame, "SecureActionButtonTemplate")
	button:SetSize(LazyCrafter_Vars.buttonSize,LazyCrafter_Vars.buttonSize)

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT",2,-2)
	icon:SetPoint("BOTTOMRIGHT",-2,2)
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon = icon

	button:SetBackdrop(backdropButton)
	button:SetBackdropBorderColor(79/255, 79/255, 79/255)
	button:SetBackdropColor(26/255, 26/255, 26/255)
	
	local hover = button:CreateTexture(nil, "HIGHLIGHT")
	hover:SetTexture(1, 1, 1, 0.3)
	hover:SetAllPoints(icon)
	button:SetHighlightTexture(hover)
	
	local pushed = button:CreateTexture(nil, "OVERLAY")
	pushed:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	pushed:SetVertexColor(0.9, 0.8, 0.1, 0.3)
	pushed:SetAllPoints(icon)
	button:SetPushedTexture(pushed)

	return button
end

--------------------------------------------

local function LCAdd(one,two,three)
	local index = GetTradeSkillSelectionIndex()
	local skillName,_,_,_,skillType = GetTradeSkillInfo(index)
	if not skillType then
		local skillIcon = GetTradeSkillIcon(index)
		updatePositions()

		if LazyCrafter_VarsPerCharacter[skillName] then
			LazyCrafter_VarsPerCharacter[skillName] = nil
		else
			LazyCrafter_VarsPerCharacter[skillName] = skillName
		end
		print('---')
		for k,v in pairs(LazyCrafter_VarsPerCharacter) do print(v)	end
			print('---')
	else
		print("Error. This ability does not craft, but rather enchants, engrave, tinkers, etc.")
	end
end

--------------------------------------------

local function createButtonFrameskill()
	if (frameskillModded) then
		return
	end
	
	if (TradeSkillFrame) then
		frameskillModded = true
		local button = CreateFrame("BUTTON", "LC_Check", TradeSkillDetailScrollChildFrame, "UIPanelButtonTemplate");
		button:SetPoint("TOPRIGHT", "TradeSkillDetailScrollChildFrame", "TOPRIGHT", -10, -24);
		button:SetHeight (16)
		button:SetText("Lazy Crafter")
		button:SetNormalFontObject(_G["GameFontNormalSmall"])
		button:SetHighlightFontObject(_G["GameFontNormalSmall"])
		button:SetDisabledFontObject(_G["GameFontNormalSmall"])
		button:SetScript ("OnClick", LCAdd)
	else
	end
end

--------------------------------------------

local function LCCraftItem(self)
	for i=1,GetNumTradeSkills()do
		local craftName,_,_=GetTradeSkillInfo(i)
		if craftName==self.spellName then
			DoTradeSkill(i,1)
		end
	end
end

--------------------------------------------

local function LCButtonPreClick(self)
	if not(TradeSkillFrame and TradeSkillFrame:IsShown() and CURRENT_TRADESKILL==self.professionName) then
		self:SetAttribute("type", "spell")
		self:SetAttribute("spell", self.professionID)
	else
		self:SetAttribute("spell",nil)			
	end
end

--------------------------------------------

local function LCButton(spellID, professionID)
	local buttonID = #buttons + 1
	local spellName = GetSpellInfo(spellID)
	local _,_,_,_,_,_,_,_,_,spellIcon = GetItemInfo(spellName)
	local professionName = GetSpellInfo(professionID)
	
	local button = createButton(buttonID)

	button.spellName = spellName
 	button.spellID = spellID
 	button.buttonID = buttonID
 	button.professionName = professionName
 	button.professionID = professionID
 	button.Filtered = false

	button:SetScript("PreClick", LCButtonPreClick)
	button:HookScript("OnClick", LCCraftItem)
	button:SetScript("PostClick", CloseTradeSkill)

	if onCooldown(spellID) then
		button:Hide()
		button.Filtered = true
	end
	
	if spellIcon then
		button.icon:SetTexture(spellIcon)
	else
		button.icon:SetTexture([[Interface\Icons\inv_misc_questionmark]])
	end
	buttons[spellID] = button
end

--------------------------------------------

local function LCButtonFrameLockLayout(self, state)

	print(self:GetNumChildren())
	local test = self:GetChildren()

	for k,v in pairs(test) do
		print(k,v)
	end

	-- for i=1,self:GetNumChildren() do
	-- 	print(type(test[i]))
	-- end

	if state then
		self:SetBackdropBorderColor(66/255, 176/255, 207/255)
		self:SetBackdropColor(80/255, 189/255, 220/255)
	else
		self:SetBackdropBorderColor(79/255, 79/255, 79/255)
		self:SetBackdropColor(26/255, 26/255, 26/255)
	end
end

--------------------------------------------

local function LCButtonFrameUnlock(self, state)
	self:EnableMouse(state)
	self:SetMovable(state)
end

--------------------------------------------

LCButtonFrame:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then
		self[event](self,...)
	else 
		print(event..' has no function!')
	end

end)

function LCButtonFrame:PLAYER_REGEN_DISABLED()
	self:Hide()
end 

function LCButtonFrame:PLAYER_REGEN_ENABLED()
	self:Show()
end 

function LCButtonFrame:PLAYER_ENTERING_WORLD()
	createButtonFrameskill()
	if IsInInstance() then
		self:Hide()
	else
		self:Show()
	end
end 

function LCButtonFrame:ADDON_LOADED(addon)
	if addon == "Blizzard_TradeSkillUI" then
		createButtonFrameskill()
	end
end 

function LCButtonFrame:PLAYER_LOGIN()
	for spellID, professionID in next, db do
		local button = buttons[spellID]
		if not button then
			LCButton(spellID, professionID)
		elseif not onCooldown(spellID) then
			button:Show()
		end
	end

	-- LazyCrafter_Vars = nil
	if not LazyCrafter_VarsPerCharacter then
		LazyCrafter_VarsPerCharacter = {}
	end
	if not LazyCrafter_Vars then
		LazyCrafter_Vars = {
			x = 200,
			y = 200,
			hideOnCombat = true,
			hideOnInstance = true,
			unlocked = false,
			buttonSize = 32
		}
	end

	self:SetHeight(LazyCrafter_Vars.buttonSize)
	self:EnableMouse(LazyCrafter_Vars.unlocked)
	self:SetMovable(LazyCrafter_Vars.unlocked)
	self:SetClampedToScreen(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart",self.StartMoving)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		LazyCrafter_Vars.x = self:GetLeft()
		LazyCrafter_Vars.y = self:GetBottom()

		-- LazyCrafter_Vars.points = {self:GetPoint()}
	end)
	
	-- self:SetPoint(unpack(LazyCrafter_Vars.points))
	self:SetPoint("BOTTOMLEFT", LazyCrafter_Vars.x,LazyCrafter_Vars.y)
	self:SetBackdrop(backdropFrame)

	LCButtonFrameLockLayout(self, LazyCrafter_Vars.unlocked)

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("ADDON_LOADED")
	self:Show()
	
	updatePositions()

	SLASH_MYADDON1 = "/lc"
	SLASH_MYADDON2 = "/lazycrafter"
	SlashCmdList["MYADDON"] = function(msg, editbox)
		if not msg:match("%S") then 
		  print("Slash command usage for '/lc' or '/lazycrafter':")
		  print("  /lc unlock - Let's you move around the bar")
		  print("  /lc lock - Let's you lock the bar in place")
	  end
	  if msg == "unlock" then
	  	LCButtonFrameUnlock(LCButtonFrame, true)
			LCButtonFrameLockLayout(LCButtonFrame, true)
			LazyCrafter_Vars.unlocked = true
	  elseif msg == "lock" then
	  	LCButtonFrameUnlock(LCButtonFrame, false)
			LCButtonFrameLockLayout(LCButtonFrame, false)
			LazyCrafter_Vars.unlocked = false
	  end
	end 
end 

function LCButtonFrame:SPELL_UPDATE_COOLDOWN()
	if self:IsShown() then
		for spellID, professionID in next, db do
			if onCooldown(spellID) then
				buttons[spellID]:Hide()
			elseif not buttons[spellID] then
				LCButton(spellID, professionID)
			end
		end
		updatePositions()
	end
end 

function LCButtonFrame:PLAYER_ALIVE()
	self:Show()
end 

function LCButtonFrame:PLAYER_DEAD()
	self:Hide()
end 

--------------------------------------------
