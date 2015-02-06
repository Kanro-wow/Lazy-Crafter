local db = {}-- First aid, id 158741	-- Tailoring	[168835] = 158758,	[125523] = 158758,	[176058] = 158758,	-- Engineering	[177054] = 158739,	[169080] = 158739,	-- Enchanting - 333	[169092] = 158716,	[177043] = 158716,		-- Inscription - 773	[169081] = 158748,	[177045] = 158748,	--Jewelcrafting - 755	[170700] = 158750,	[176087] = 158750,	--Leatherworking - 165	[171391] = 158752,	[176089] = 158752,	--Alchemy - 171	[156587] = 156606,	[175880] = 156606,	-- Blacksmithing - 164	[171690] = 158737,	[176090] = 158737,	-- Mining - 186}

--------------------------------------------

local buttons = {}
frameskillModded = false

local backdropFrame = {	bgFile = [[Interface\BUTTONS\WHITE8X8]], tile = false, tileSize = 0, insets = { left = 1, right = 1, top = 1, bottom = 1}}
local backdropButton = { bgFile = [[Interface\BUTTONS\WHITE8X8]], edgeFile = [[Interface\BUTTONS\WHITE8X8]], edgeSize = 1, tile = false, tileSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0}}

--------------------------------------------

local LCButtonFrame = CreateFrame("Frame","LCButtonFrame",UIParent)
LCButtonFrame:RegisterEvent("PLAYER_LOGIN")
LCButtonFrame:RegisterEvent("QUEST_LOG_UPDATE")

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
	if visibleButtonCount > 0 then
		LCButtonFrame:SetWidth(visibleButtonCount*(LazyCrafter_Vars.buttonSize+4)-4)
		LCButtonFrame:Show()
		LCButtonFrame.empty = false
	else
		LCButtonFrame:Hide()
		LCButtonFrame.empty = true
	end
end

--------------------------------------------

local function checkProfessionChange()
	local professions = {}

	for k,v in next, {GetProfessions()} do
		table.insert(professions, (GetProfessionInfo(v)))
	end

	for skill,button in next, LazyCrafter_VarsPerCharacter do
		if not tContains(professions, button.professionName) then
			print("Removed",button.skillName,"from your LazyCrafter Bar, because you changed professions!")
			LazyCrafter_VarsPerCharacter[k] = nil
			buttons[skill]:Hide()
			buttons[skill] = nil
		end
	end

	updatePositions()
end

--------------------------------------------

local function onCooldown(spellID)
	return GetSpellCooldown(spellID) ~= 0
end

--------------------------------------------

local function checkCooldowns(self)
	local change = false
	for _, button in next, buttons do
		local cooldown = onCooldown(button.spellID)
		if cooldown and not button.Filtered then
			button.Filtered = true
			button:Hide()
			change = true
		elseif not cooldown and button.Filtered then
			button.Filtered = false
			button:Show()
			change = true
		end
	end
	if change then
		updatePositions()
	end
end

--------------------------------------------

local function spellIDFromRecipeLink(str)
	return string.match(str, '|H%a+:(%d+)')
end

--------------------------------------------

local function LCCraftItem(self)
	for i=1,GetNumTradeSkills()do
		local craftName,_,_=GetTradeSkillInfo(i)
		if craftName==self.skillName then
			self.skillIndex = i
			DoTradeSkill(self.skillIndex)
			SelectTradeSkill(self.skillIndex)
			return
		end
	end
end

--------------------------------------------

local function OpenTradeSkill(self)
	if not(TradeSkillFrame and TradeSkillFrame:IsShown() and CURRENT_TRADESKILL==self.professionName) then
		CastSpellByName(self.professionName)
	end


end

--------------------------------------------

local function showButtonTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	GameTooltip:SetSpellByID(self.spellID)
	GameTooltip:Show()
end

--------------------------------------------


local function createButton()
	buttonID = 1
	for _ in next, buttons do
		buttonID = buttonID + 1
	end

	local button = CreateFrame("Button", "LC_"..buttonID, LCButtonFrame)
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

	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnEnter", showButtonTooltip)
	return button
end

--------------------------------------------

local function LCSkillButton(skill)
	local button = createButton(skill.spellID)

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
	local reagents = {}
	spellID = spellIDFromRecipeLink(GetTradeSkillRecipeLink(index))

	for i=1,GetTradeSkillNumReagents(index) do
		reagents[i] = {GetTradeSkillReagentInfo(index, i)}
	end

	if LazyCrafter_VarsPerCharacter[skillName] then
		LazyCrafter_VarsPerCharacter[skillName] = nil
		buttons[skillName]:Hide()
		buttons[skillName] = nil
	else
		LazyCrafter_VarsPerCharacter[skillName] = {
			icon = GetTradeSkillIcon(index),
			name = skillName,
			professionName = GetTradeSkillLine(),
			spellID = spellID,
			reagents = reagents
		}

		LCSkillButton(LazyCrafter_VarsPerCharacter[skillName])

		if onCooldown(spellID) then
			print("LazyCrafter: Button added. Because it is on cooldown it will not be shown until it becomes available again.")
		end
	end
	updatePositions()
end

--------------------------------------------

local function createButtonFrameskill()
	if TradeSkillFrame and not frameskillModded then
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
		for skillName, skill in next, LazyCrafter_VarsPerCharacter do
			if not buttons[skillName] then
				button = LCSkillButton(skill)
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
end

function LCButtonFrame:PLAYER_LOGIN()
	checkProfessionChange()

	if not LazyCrafter_Vars then
		LazyCrafter_Vars = {x = 200, y = 200, OpenTradeSkillWindow = false, unlocked = false, buttonSize = 32	}
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

	for _,event in next, {
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
		"PLAYER_ENTERING_WORLD",
		"PLAYER_ALIVE",
		"PLAYER_DEAD",
		"ADDON_LOADED",
		"SKILL_LINES_CHANGED",
		"CHAT_MSG_TRADESKILLS"
	} do
		self:RegisterEvent(event)
	end

	self:Show()

end

function LCButtonFrame:QUEST_LOG_UPDATE()
	if GetQuestResetTime() > 0 then
		self:UnregisterEvent("QUEST_LOG_UPDATE")
		print(GetQuestResetTime())
		C_Timer.After(GetQuestResetTime(), function()
			checkCooldowns(LCButtonFrame)
		end)
	end
end

local _TRADESKILL_LOG_FIRSTPERSON = string.gsub(TRADESKILL_LOG_FIRSTPERSON,"%%s",".+")
function LCButtonFrame:CHAT_MSG_TRADESKILLS(message)
	if string.match(message, _TRADESKILL_LOG_FIRSTPERSON) then
		checkCooldowns(self)
	end
end

function LCButtonFrame:PLAYER_REGEN_ENABLED()
	if not LCButtonFrame.empty then
		self:Show()
	end
end

function LCButtonFrame:ADDON_LOADED(addon)
	if addon == "Blizzard_TradeSkillUI" then
		createButtonFrameskill()
	end
end


LCButtonFrame.PLAYER_ALIVE = LCButtonFrame.Show
LCButtonFrame.PLAYER_DEAD = LCButtonFrame.Hide
LCButtonFrame.PLAYER_REGEN_DISABLED = LCButtonFrame.Hide
LCButtonFrame.SKILL_LINES_CHANGED = checkProfessionChange

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