local db = {}-- First aid, id 158741	-- Tailoring	[168835] = 158758,	[125523] = 158758,	[176058] = 158758,	-- Engineering	[177054] = 158739,	[169080] = 158739,	-- Enchanting - 333	[169092] = 158716,	[177043] = 158716,		-- Inscription - 773	[169081] = 158748,	[177045] = 158748,	--Jewelcrafting - 755	[170700] = 158750,	[176087] = 158750,	--Leatherworking - 165	[171391] = 158752,	[176089] = 158752,	--Alchemy - 171	[156587] = 156606,	[175880] = 156606,	-- Blacksmithing - 164	[171690] = 158737,	[176090] = 158737,	-- Mining - 186}

--------------------------------------------

local buttons = {}
local reagents = {}
local frameskillModded = false

local backdropFrame = {	bgFile = [[Interface\BUTTONS\WHITE8X8]], tile = false, tileSize = 0, insets = { left = 1, right = 1, top = 1, bottom = 1}}
local backdropButton = { bgFile = [[Interface\BUTTONS\WHITE8X8]], edgeFile = [[Interface\BUTTONS\WHITE8X8]], edgeSize = 1, tile = false, tileSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0}}

--------------------------------------------

local LazyCrafter_Bar = CreateFrame("Frame","LazyCrafter_Bar",UIParent)
LazyCrafter_Bar:RegisterEvent("PLAYER_LOGIN")
LazyCrafter_Bar:RegisterEvent("QUEST_LOG_UPDATE")

--------------------------------------------

local function updatePositions()
	local visibleButtonCount = 0
	local lastButton

	for skillName, button in next, buttons do
		if not button.Filtered then
			visibleButtonCount = visibleButtonCount + 1
			button:ClearAllPoints()
			if visibleButtonCount == 1 then
				button:SetPoint("BOTTOMLEFT",LazyCrafter_Bar)
			else
				button:SetPoint("LEFT",lastButton,"RIGHT",4,0)
			end
			lastButton = button
		end
	end
	if visibleButtonCount > 0 then
		LazyCrafter_Bar:SetWidth(visibleButtonCount*(LazyCrafter_Vars.buttonSize+4)-4)
		LazyCrafter_Bar:Show()
		LazyCrafter_Bar.empty = false
	else
		LazyCrafter_Bar:Hide()
		LazyCrafter_Bar.empty = true
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
			print("LC: Removed",button.skillName,"from your LazyCrafter Bar, because you changed professions!")
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

local function CraftItem(self)
	for i=1,GetNumTradeSkills() do
		local craftName,_,_=GetTradeSkillInfo(i)
		if craftName==self.skillName then
			DoTradeSkill(i)
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

local function buttonCount(skillName)
	local count = math.huge

	for k, v in next, LazyCrafter_VarsPerCharacter[skillName].reagents do
		local craftCount = math.floor(GetItemCount(k,true)/v)
		if craftCount < count then
			count = craftCount
		end
	end
	return count
end

--------------------------------------------

local function updateButtonCount()
	for buttonName, button in next, buttons do
		button:SetText(buttonCount(buttonName))
	end
end

--------------------------------------------


local function createButton()
	local button = CreateFrame("Button", "LC_CraftButton", LazyCrafter_Bar)
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

	button:SetNormalFontObject(_G["GameFontNormal"])

	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnEnter", showButtonTooltip)
	return button
end

--------------------------------------------

local function LCSkillButton(skill)
	local button = createButton(skill.spellID)

	button.skillName = skill.name
	button.spellID = skill.spellID
	button.professionName = skill.professionName
	button.icon:SetTexture(skill.icon)

	button:SetScript("PreClick", OpenTradeSkill)
	button:SetScript("OnClick", CraftItem)
	-- button:SetScript("PostClick", CraftItem)

	button:SetText(buttonCount(skill.name))

	if onCooldown(skill.spellID) then
		button.Filtered = true
	else
		button.Filtered = false
	end

	if LazyCrafter_Bar.Unlocked then
		button:Hide()
	end

	buttons[button.skillName] = button



end

--------------------------------------------

local function LCAdd()
	local index = GetTradeSkillSelectionIndex()
	local skillName,_,_,_,skillType = GetTradeSkillInfo(index)

	if LazyCrafter_VarsPerCharacter[skillName] then
		print("LazyCrafter: Removed",skillName..".")
		LazyCrafter_VarsPerCharacter[skillName] = nil
		buttons[skillName]:Hide()
		buttons[skillName] = nil
	else
		local tools = {}
		local insertReagents = {}
		local spellID = string.match(GetTradeSkillRecipeLink(index), '|H%a+:(%d+)')

		-- local toolsRaw = {GetTradeSkillTools(index)}
		-- if toolsRaw then
		-- 	for i=1,#toolsRaw/2 do
		-- 		tools[i] = toolsRaw[i*2-1]
		-- 	end

		local anvilRequired = false
		if tContains({GetTradeSkillTools(index)}, "Anvil") then
			anvilRequired = true
		end

		for i=1,GetTradeSkillNumReagents(index) do
			local reagent = GetTradeSkillReagentInfo(index, i)
			_,_,insertReagents[reagent] = GetTradeSkillReagentInfo(index, i)
			reagents[reagent] = GetItemCount(reagent,true)
		end

		LazyCrafter_VarsPerCharacter[skillName] = {
			spellID = spellID,
			name = skillName,
			professionName = GetTradeSkillLine(),
			anvilRequired = anvilRequired,
			reagents = insertReagents,
			icon = GetTradeSkillIcon(index),
		}

		LCSkillButton(LazyCrafter_VarsPerCharacter[skillName])

		if onCooldown(spellID) then
			print("LC: Button added. It's on cooldown, so it is hidden.")
		else
			print("LC: Added",skillName..".")
		end
	end

	updatePositions()
end

--------------------------------------------

local function createButtonFrameskill()
	if TradeSkillFrame and not frameskillModded then
		frameskillModded = true
		local button = CreateFrame("BUTTON", "LC_Check", TradeSkillDetailScrollChildFrame);
		button:SetPoint("TOPRIGHT", "TradeSkillDetailScrollChildFrame", "TOPRIGHT", 0, -5);
		button:SetHeight(16)
		button:SetWidth(95)
		button:SetText("Lazy Crafter")
		button:SetNormalFontObject(_G["GameFontNormalSmall"])

		button:SetScript ("OnClick", LCAdd)

		-- Register to check if tradeskillwindow is from player
		button:RegisterEvent("TRADE_SKILL_SHOW")

		button:SetScript("OnEvent", function()
			if IsTradeSkillGuild() or IsTradeSkillLinked() then
				button:Hide()
			else
				button:Show()
			end
		end)


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

	else
	end
end

local function createButtons()
	if LazyCrafter_VarsPerCharacter then
		for skillName, skill in next, LazyCrafter_VarsPerCharacter do
			if not buttons[skillName] then
				button = LCSkillButton(skill)

				for k, v in next, LazyCrafter_VarsPerCharacter[skillName].reagents do
					reagents[k] = GetItemCount(k,true)
				end
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

local function LazyCrafter_BarUnlock(self, state)

	self:EnableMouse(state)
	self:SetMovable(state)
	self.Unlocked = state
end

--------------------------------------------

local function LazyCrafter_BarLockLayout(self, state)
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

LazyCrafter_Bar:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self,...)
	else
		print('LazyCrafter:',event,'has no function!')
	end
end)

function LazyCrafter_Bar:PLAYER_ENTERING_WORLD()
	createButtonFrameskill()
end

function LazyCrafter_Bar:PLAYER_LOGIN()
	for k,v in next, {GetProfessions()} do
		GetProfessionInfo(v)
	end

	checkProfessionChange()

	if not LazyCrafter_Vars then
		LazyCrafter_Vars = {x = 200, y = 200, OpenTradeSkillWindow = false, unlocked = false, buttonSize = 32	}
	end

	if not LazyCrafter_VarsPerCharacter then
		LazyCrafter_VarsPerCharacter = {}
	end

	if self.BlizzardTradeSkillFrame ~= nil then
		if (not IsAddOnLoaded("Blizzard_TradeSkillUI")) then
			LoadAddOn("Blizzard_TradeSkillUI");
		end
		TradeSkillFrame = self.BlizzardTradeSkillFrame
		TradeSkillFrame_Show = self.BlizzardTradeSkillFrame_Show
		self.BlizzardTradeSkillFrame = nil
		self.BlizzardTradeSkillFrame_Show = nil
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
		LazyCrafter_Vars.x = math.ceil(self:GetLeft())
		LazyCrafter_Vars.y = math.ceil(self:GetBottom())
	end)

	self:SetPoint("BOTTOMLEFT", LazyCrafter_Vars.x,LazyCrafter_Vars.y)
	self:SetBackdrop(backdropFrame)

	LazyCrafter_BarLockLayout(self, LazyCrafter_Vars.unlocked)

	for _,event in next, {
		"PLAYER_REGEN_DISABLED",
		"PLAYER_REGEN_ENABLED",
		"PLAYER_ENTERING_WORLD",
		"PLAYER_ALIVE",
		"PLAYER_DEAD",
		"ADDON_LOADED",
		"SKILL_LINES_CHANGED",
		"CHAT_MSG_TRADESKILLS",
		"BAG_UPDATE_DELAYED",
	} do
		self:RegisterEvent(event)
	end

	self:Show()
end

function LazyCrafter_Bar:QUEST_LOG_UPDATE()
	if GetQuestResetTime() > 0 then
		self:UnregisterEvent("QUEST_LOG_UPDATE")
		C_Timer.After(GetQuestResetTime(), function()
			checkCooldowns(LazyCrafter_Bar)
		end)
	end
end

function LazyCrafter_Bar:BAG_UPDATE_DELAYED()
	for reagent, reagentCount in next, reagents do
		if GetItemCount(reagent, true) ~= reagentCount then
			updateButtonCount()
			return
		end
	end
end

local _TRADESKILL_LOG_FIRSTPERSON = string.gsub(TRADESKILL_LOG_FIRSTPERSON,"%%s",".+")
function LazyCrafter_Bar:CHAT_MSG_TRADESKILLS(message)
	if string.match(message, _TRADESKILL_LOG_FIRSTPERSON) then
		checkCooldowns(self)
	end
end

function LazyCrafter_Bar:PLAYER_REGEN_ENABLED()
	if not LazyCrafter_Bar.empty then
		self:Show()
	end
end

function LazyCrafter_Bar:PLAYER_REGEN_DISABLED()
	if not LazyCrafter_Bar.empty then
		self:Hide()
	end
end

function LazyCrafter_Bar:PLAYER_ALIVE()
	if not LazyCrafter_Bar.empty then
		self:Show()
	end
end

function LazyCrafter_Bar:PLAYER_DEAD()
	if not LazyCrafter_Bar.empty then
		self:Hide()
	end
end

function LazyCrafter_Bar:ADDON_LOADED(addon)
	if addon == "Blizzard_TradeSkillUI" then
		createButtonFrameskill()
	end
end

function LazyCrafter_Bar:SKILL_LINES_CHANGED(addon)
	checkProfessionChange()
end



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
		print([[LazyCrafter is now unlocked. Type "/lc lock" to lock the bar.]])
		LazyCrafter_BarUnlock(LazyCrafter_Bar, true)
		LazyCrafter_BarLockLayout(LazyCrafter_Bar, true)
		LazyCrafter_Vars.unlocked = true
	elseif msg == "lock" then
		print([[LazyCrafter is now locked. Type "/lc unlock" to unlock the bar.]])
		LazyCrafter_BarUnlock(LazyCrafter_Bar, false)
		LazyCrafter_BarLockLayout(LazyCrafter_Bar, false)
		LazyCrafter_Vars.unlocked = false
	elseif msg == "clear" then
		print([[LazyCrafter has now removed all crafts from the bar.]])
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