local db = {}-- First aid, id 158741	-- Tailoring	[168835] = 158758,	[125523] = 158758,	[176058] = 158758,	-- Engineering	[177054] = 158739,	[169080] = 158739,	-- Enchanting - 333	[169092] = 158716,	[177043] = 158716,		-- Inscription - 773	[169081] = 158748,	[177045] = 158748,	--Jewelcrafting - 755	[170700] = 158750,	[176087] = 158750,	--Leatherworking - 165	[171391] = 158752,	[176089] = 158752,	--Alchemy - 171	[156587] = 156606,	[175880] = 156606,	-- Blacksmithing - 164	[171690] = 158737,	[176090] = 158737,	-- Mining - 186}

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

	for skillName, button in next, buttons do
		if button:IsShown() then
			visibleButtonCount = visibleButtonCount + 1
			button:ClearAllPoints()
			if visibleButtonCount == 1 then
				button:SetPoint("BOTTOMLEFT",LCButtonFrame)
			else
				button:SetPoint("LEFT",lastButton,"RIGHT",4,0)
			end
			lastButton = button
		end
	end
	
	LCButtonFrame:SetWidth(visibleButtonCount*(LazyCrafter_Vars.buttonSize+4)-4)
end

--------------------------------------------

local function onCooldown(spellID)
	print(spellID)
	return GetSpellCooldown(spellID) ~= 0
end

--------------------------------------------

local function spellIDFromRecipeLink(str)
	local t = {}; local i = 1
	local s = {}; local j = 1
	for str in string.gmatch(str, "([^%:]+)") do t[i] = str; i=i+1 end
	str = t[2]
	for str in string.gmatch(str, "([^%[]+)") do s[j] = str; j=j+1 end
	return(s[1])
end

--------------------------------------------

local function LCCraftItem(self)
	for i=1,GetNumTradeSkills()do
		local craftName,_,_=GetTradeSkillInfo(i)
		if craftName==self.skillName then
			DoTradeSkill(i,1)
		end
	end
end

--------------------------------------------

local function OpenTradeSkill(self)
	if not(TradeSkillFrame and TradeSkillFrame:IsShown() and CURRENT_TRADESKILL==self.professionName) then
		CastSpellByName(self.professionName)
	else
	end
end

--------------------------------------------

local function createButton(buttonID)
	buttonID = 1
	for k in next, buttons do
		buttonID = buttonID + 1
	end

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
	hover:SetTexture(0.8, 0.8, 0.8, 0.3)
	hover:SetAllPoints(icon)
	button:SetHighlightTexture(hover)
	
	local pushed = button:CreateTexture(nil, "OVERLAY")
	pushed:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	pushed:SetVertexColor(0.9, 0.8, 0.1, 0.6)
	pushed:SetAllPoints(icon)
	button:SetPushedTexture(pushed)

	return button
end

--------------------------------------------

local function LCSkillButton(skillName, skill, buttonCount) 
	local button = createButton(buttonCount)

	button.skillName = skillName
	button.buttonID = buttonID
	button.professionName = skill.professionName
	button.Filtered = false
	button.icon:SetTexture(skill.icon)

	button:SetScript("PreClick", OpenTradeSkill)
	button:SetScript("OnClick", LCCraftItem)
	
	if not LazyCrafter_Vars.OpenTradeSkillWindow then
		button:SetScript("PostClick", CloseTradeSkill)
	end
	buttons[skillName] = button
end

--------------------------------------------

local function LCAdd()
	local index 											= GetTradeSkillSelectionIndex()
	local skillName,_,_,_,skillType 	= GetTradeSkillInfo(index)
	local skillIcon 									= GetTradeSkillIcon(index)
	local hyperLink 									= GetTradeSkillRecipeLink(index)
	local professionName 							= GetTradeSkillLine()
	local spellID 										= spellIDFromRecipeLink(GetTradeSkillRecipeLink(index))

	if LazyCrafter_VarsPerCharacter[skillName] then
		LazyCrafter_VarsPerCharacter[skillName] = nil
		buttons[skillName]:Hide()
	else
		LazyCrafter_VarsPerCharacter[skillName] = {
			icon = skillIcon,
			name = skillName,
			professionName = professionName,
			hasCooldown = hasCooldown
		}
		
		print(spellID)
		print(onCooldown(spellID))

		if onCooldown(spellID) then
			print(skillName.." has been added! It's on cooldown, so it is not shown on the list!")
		else
			LCSkillButton(skillName, LazyCrafter_VarsPerCharacter[skillName], buttonCount) 
		end
	
	end
	
	updatePositions()
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

local function LCButtonFrameLockLayout(self, state)
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
	if not LazyCrafter_Vars then
		LazyCrafter_Vars = {x = 200, y = 200, hideOnCombat = true, hideOnInstance = true, OpenTradeSkillWindow = false, unlocked = false, buttonSize = 32	}
	end

	if not LazyCrafter_VarsPerCharacter then
		LazyCrafter_VarsPerCharacter = {}
	end

	if LazyCrafter_VarsPerCharacter then
		local buttonCount = 1

		for skillName, skillProperties in next, LazyCrafter_VarsPerCharacter do
			-- local button = buttons[skillName]

			if not buttons[skillName] then
				button = LCSkillButton(skillName, skillProperties, buttonCount)
				buttonCount = buttonCount + 1
			else
				button:Show()
			end
		end
		
		if not LazyCrafter_VarsPerCharacter then
			LazyCrafter_VarsPerCharacter = {}
		end
	
		updatePositions()
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
				LCButtonskill(skillName, skillProperties)
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
