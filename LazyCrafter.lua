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
		if not button.Filtered then
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
	print(visibleButtonCount)
	if visibleButtonCount > 0 then
		LCButtonFrame:SetWidth(visibleButtonCount*(LazyCrafter_Vars.buttonSize+4)-4)
		LCButtonFrame:Show()
	else
		LCButtonFrame:Hide()
	end
end

--------------------------------------------

local function checkProfessionChange()
	local c = {}
	c[1],c[2] = GetProfessions()
	if c[1] then c[1] = GetProfessionInfo(c[1]) end
	if c[2] then c[2] = GetProfessionInfo(c[2])	end

	for k,v in next, LazyCrafter_VarsPerCharacter do
		if not (v.professionName == c[1] or v.professionName == c[2]) then
			LazyCrafter_VarsPerCharacter[k] = nil
			buttons[k]:Hide()
			buttons[k] = nil
		else
		end
	end
	updatePositions()
end

--------------------------------------------

local function onCooldown(spellID)
	return GetSpellCooldown(spellID) ~= 0
end

--------------------------------------------

local function spellIDFromRecipeLink(str)

	local s = {}; local i = 1
	local t = {}; local j = 1
	for str in string.gmatch(str, "([^%:]+)") do s[i] = str; i=i+1 end
	str = s[2]
	for str in string.gmatch(str, "([^%D]+)") do t[j] = str; j=j+1 end
	return t[1]
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
	
	local hover = button:CreateTexture(nil, "OVERLAY")
	hover:SetTexture(0.8, 0.8, 0.8, 0.3)
	hover:SetAllPoints(icon)
	button:SetHighlightTexture(hover)
	
	local pushed = button:CreateTexture(nil, "HIGHLIGHT")
	pushed:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
	pushed:SetVertexColor(0.9, 0.8, 0.1, 0.6)
	pushed:SetAllPoints(icon)
	button:SetPushedTexture(pushed)

	return button
end

--------------------------------------------

local function LCSkillButton(skill, buttonCount) 
	local button = createButton(buttonCount)

	button.skillName = skill.name
	button.spellID = skill.spellID
	button.buttonID = buttonID
	button.professionName = skill.professionName
	button.icon:SetTexture(skill.icon)
	button:SetScript("PreClick", OpenTradeSkill)
	button:SetScript("OnClick", LCCraftItem)

	if onCooldown(skill.spellID) then
		button.Filtered = true
	else
		button.Filtered = false
	end

	if LCButtonFrame.Unlocked then
		button:Hide()
	end

	if not LazyCrafter_Vars.OpenTradeSkillWindow then
		button:SetScript("PostClick", CloseTradeSkill)
	end
	buttons[skill.name] = button

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
		buttons[skillName] = nil
	else
		LazyCrafter_VarsPerCharacter[skillName] = {
			icon = skillIcon,
			name = skillName,
			professionName = professionName,
			spellID = spellID,
		}

		LCSkillButton(LazyCrafter_VarsPerCharacter[skillName], buttonCount) 
		
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
		button:RegisterEvent("TRADE_SKILL_SHOW")

		button:SetScript ("OnClick", LCAdd)
		button:SetScript("OnEvent", function() 
			if IsTradeSkillGuild() or IsTradeSkillLinked() then
				button:Hide()
			else
				button:Show()
			end
		end)
	else
	end
end

local function createButtons()
	if LazyCrafter_VarsPerCharacter then
		local buttonCount = 1
		for skillName, skill in next, LazyCrafter_VarsPerCharacter do
			if not buttons[skillName] then
				button = LCSkillButton(skill, buttonCount)
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
end

--------------------------------------------

local function LCButtonFrameUnlock(self, state)
	self:EnableMouse(state)
	self:SetMovable(state)
	self.Unlocked = state
end

--------------------------------------------

local function LCButtonFrameLockLayout(self, state)
	if state then
		self:SetBackdropColor(80/255, 189/255, 220/255)
		for k,v in next, buttons do
			v:Hide()
		end
	else
		self:SetBackdropColor(26/255, 26/255, 26/255)
		for k,v in next, buttons do
			if not v.filtered then
				v:Show()
			end
		end
	end
end

--------------------------------------------

LCButtonFrame:SetScript("OnEvent", function(self, event, ...) 
	if self[event] then
		self[event](self,...)
	else 
		print(event..' has no function!')
	end

end)

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

	checkProfessionChange()

	if not LazyCrafter_Vars then
		LazyCrafter_Vars = {x = 200, y = 200, hideOnCombat = true, hideOnInstance = true, OpenTradeSkillWindow = false, unlocked = false, buttonSize = 32	}
	end

	if not LazyCrafter_VarsPerCharacter then
		LazyCrafter_VarsPerCharacter = {}
	end

	createButtons()

	self:SetHeight(LazyCrafter_Vars.buttonSize)
	self:EnableMouse(LazyCrafter_Vars.unlocked)
	self:SetMovable(LazyCrafter_Vars.unlocked)
	self.Unlocked = LazyCrafter_Vars.unlocked
	self:SetClampedToScreen(true)
	self:RegisterForDrag("LeftButton")
	
	self:SetScript("OnDragStart",self.StartMoving)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		LazyCrafter_Vars.x = self:GetLeft()
		LazyCrafter_Vars.y = self:GetBottom()
	end)

	self:SetPoint("BOTTOMLEFT", LazyCrafter_Vars.x,LazyCrafter_Vars.y)
	self:SetBackdrop(backdropFrame)

	LCButtonFrameLockLayout(self, LazyCrafter_Vars.unlocked)

	local eventsTable = {"PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","SPELL_UPDATE_COOLDOWN","PLAYER_ALIVE","PLAYER_DEAD","ADDON_LOADED","SKILL_LINES_CHANGED"}
	
	for k,v in next, eventsTable do
		self:RegisterEvent(v)
	end
	
	self:Show()
end 

function LCButtonFrame:SPELL_UPDATE_COOLDOWN()
	if self:IsShown() then
		for k, button in next, buttons do
			local cooldown = onCooldown(button.spellID)
			if cooldown and not button.Filtered then
				button.Filtered = true
				button:Hide()
			elseif not cooldown and button.Filtered then
				button.Filtered = false
				button:Show()
			end 
		end
		updatePositions()
	end
end 

function LCButtonFrame:PLAYER_ALIVE() self:Show() end 
function LCButtonFrame:PLAYER_DEAD() self:Hide() end 
function LCButtonFrame:PLAYER_REGEN_DISABLED() self:Hide() end 
function LCButtonFrame:PLAYER_REGEN_ENABLED() self:Show() end 
function LCButtonFrame:PLAYER_REGEN_ENABLED() self:Show() end 
function LCButtonFrame:PLAYER_REGEN_ENABLED() self:Show() end 
function LCButtonFrame:SKILL_LINES_CHANGED() checkProfessionChange() end 

--------------------------------------------

SLASH_LAZYCRAFTER1 = "/lc"
SLASH_LAZYCRAFTER2 = "/lazycrafter"
SlashCmdList["LAZYCRAFTER"] = function(msg, editbox)
	if not msg:match("%S") then 
		print("Slash command usage for '/lc' or '/lazycrafter':")
		print("/lc unlock - Move the bar around to wherever you want")
		print("/lc lock - Locks the bar in place")
		print("/lc clear - Removes all buttons from your bar")
	end

	if msg == "unlock" then
		LCButtonFrameUnlock(LCButtonFrame, true)
		LCButtonFrameLockLayout(LCButtonFrame, true)
		LazyCrafter_Vars.unlocked = true
	elseif msg == "lock" then
		LCButtonFrameUnlock(LCButtonFrame, false)
		LCButtonFrameLockLayout(LCButtonFrame, false)
		LazyCrafter_Vars.unlocked = false
	elseif msg == "clear" then
		LazyCrafter_VarsPerCharacter = nil
		LazyCrafter_VarsPerCharacter = {}

		for k,button in pairs(buttons) do
			button:Hide()
		end
		buttons = nil
		buttons = {}
		updatePositions()
	end
end 