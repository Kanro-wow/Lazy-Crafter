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
local buttonSize=32
local intents=10

local backdropFrame = {
	bgFile = [[Interface\BUTTONS\WHITE8X8]], 
	tile = false,
	tileSize = 0,
	insets = {
		left = -intents,
		right = -intents,
		top = -intents,
		bottom = -intents,
	}
}
local backdropButton = {
	bgFile = [[Interface\BUTTONS\WHITE8X8]], 
	edgeFile = [[Interface\BUTTONS\WHITE8X8]], 
	edgeSize = 1,
	tile = false,
	tileSize = 0,
	insets = {
		left = 0,
		right = 0,
		top = 0,
		bottom = 0,
	}
}

local function saveLocation(self)
	print("laughing out loud")
end


--------------------------------------------

local OCCButtonFrame = CreateFrame("Frame","OCCButtonFrame",UIParent)
OCCButtonFrame:RegisterEvent("PLAYER_LOGIN")

--------------------------------------------

local function updatePositions()
	local visibleButtonCount = 0
	local lastButton 

	for spellID, button in next, buttons do
		if button:IsShown() then
			visibleButtonCount = visibleButtonCount + 1
			OCCButtonFrame:SetWidth(visibleButtonCount*(buttonSize+4)-4)
			button:ClearAllPoints()
			if visibleButtonCount == 1 then
				button:SetPoint("BOTTOMLEFT",OCCButtonFrame)
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
	local button = CreateFrame("Button", "OCC_"..buttonID, OCCButtonFrame, "SecureActionButtonTemplate")
	button:SetSize(buttonSize,buttonSize)

	local icon = button:CreateTexture(nil, "ARTWORK")
	-- icon:SetAllPoints()
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

local function OCCAdd(one,two,three)
	local index = GetTradeSkillSelectionIndex()
	local skillName,_,_,_,skillType = GetTradeSkillInfo(index)
	if not skillType then
		local skillIcon = GetTradeSkillIcon(index)
		updatePositions()

		if OCC_SavedVarsPerCharacter[skillName] then
			OCC_SavedVarsPerCharacter[skillName] = nil
		else
			OCC_SavedVarsPerCharacter[skillName] = skillName
			-- {
			-- 	skillName = skillName,
			-- 	skillIcon = skillIcon,
			-- }
		end
		print('---')
		for k,v in pairs(OCC_SavedVarsPerCharacter) do print(v)	end
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

		local button = CreateFrame("BUTTON", "OCC_Check", TradeSkillDetailScrollChildFrame, "UIPanelButtonTemplate");
		button:SetPoint("TOPRIGHT", "TradeSkillDetailScrollChildFrame", "TOPRIGHT", -10, -24);
		button:SetHeight (16)
		button:SetText("Lazy Crafter")
		button:SetNormalFontObject(_G["GameFontNormalSmall"])
		button:SetHighlightFontObject(_G["GameFontNormalSmall"])
		button:SetDisabledFontObject(_G["GameFontNormalSmall"])
		button:SetScript ("OnClick", OCCAdd)
	else
	end
end

--------------------------------------------

local function OCCCraftItem(self)
	for i=1,GetNumTradeSkills()do
		local craftName,_,_=GetTradeSkillInfo(i)
		if craftName==self.spellName then
			DoTradeSkill(i,1)
		end
	end
end

--------------------------------------------

local function OCCButtonPreClick(self)
	if not(TradeSkillFrame and TradeSkillFrame:IsShown() and CURRENT_TRADESKILL==self.professionName) then
		self:SetAttribute("type", "spell")
		self:SetAttribute("spell", self.professionID)
	else
		self:SetAttribute("spell",nil)			
	end
end

--------------------------------------------

local function OCCButton(spellID, professionID)
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

	button:SetScript("PreClick", OCCButtonPreClick)
	button:HookScript("OnClick", OCCCraftItem)
	button:SetScript("PostClick", CloseTradeSkill)

	if onCooldown(spellID) then
		button:Hide()
	end
	
	if spellIcon then
		button.icon:SetTexture(spellIcon)
	else
		button.icon:SetTexture([[Interface\Icons\inv_misc_questionmark]])
	end
	buttons[spellID] = button
end

--------------------------------------------

local panel
local backupSettings
panel = CreateFrame("Frame", "OCC_Panel", UIParent)
panel.name = "One Click Cooldown"

panel.okay = function(self) 
	backupSettings = OCC_SavedVars
end

panel.cancel = function(self)  
	OCC_SavedVars = backupSettings
end

panel.defaults = function(self)  
	OCC_SavedVars = backupSettings
end

panel.refresh = function(self)
	myCheckButton = CreateFrame("CheckButton", "myCheckButton_GlobalName", OCC_Panel, "ChatConfigCheckButtonTemplate");
	myCheckButton:SetPoint("TOPLEFT", 200, -65);
end

InterfaceOptions_AddCategory(panel)

--------------------------------------------

OCCButtonFrame:SetScript("OnEvent", function(self, event, ...) 
	self[event](self,...)
end)

function OCCButtonFrame:PLAYER_REGEN_DISABLED()
	self:Hide()
end 

function OCCButtonFrame:PLAYER_REGEN_ENABLED()
	self:Show()
end 

function OCCButtonFrame:PLAYER_ENTERING_WORLD()
	createButtonFrameskill()
	if IsInInstance() then
		self:Hide()
	else
		self:Show()
	end
end 

function OCCButtonFrame:ADDON_LOADED(addon)
	if addon == "Blizzard_TradeSkillUI" then
		createButtonFrameskill()
	end
end 

function OCCButtonFrame:PLAYER_LOGIN()
	for spellID, professionID in next, db do
		local button = buttons[spellID]
		if not button then
			OCCButton(spellID, professionID)
		elseif not onCooldown(spellID) then
			button:Show()
		end
	end

	if not OCC_SavedVarsPerCharacter then
		OCC_SavedVarsPerCharacter = {}
	end
	if not OCC_SavedVars then
		OCC_SavedVars = {
			points = {"CENTER",nil, "CENTER", 200,200 },
			x = 200,
			y = 200,
			hideOnCombat = true,
			buttonSize = 32
		}
	end

	self:SetHeight(buttonSize)
	self:EnableMouse(true)
	self:SetMovable(true)
	self:SetClampedToScreen(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart",self.StartMoving)
	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		OCC_SavedVars.x = self:GetLeft()
		OCC_SavedVars.y = self:GetBottom()

		-- OCC_SavedVars.points = {self:GetPoint()}
	end)
	
	-- self:SetPoint(unpack(OCC_SavedVars.points))
	self:SetPoint("BOTTOMLEFT", OCC_SavedVars.x,OCC_SavedVars.y)
	self:SetBackdrop(backdropFrame)
	self:SetBackdropBorderColor(79/255, 79/255, 79/255)
	self:SetBackdropColor(26/255, 26/255, 26/255)

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("ADDON_LOADED")
	self:Show()
	
	updatePositions()
end 

function OCCButtonFrame:SPELL_UPDATE_COOLDOWN()
	if self:IsShown() then
		for spellID, professionID in next, db do
			if onCooldown(spellID) then
				buttons[spellID]:Hide()
			elseif not buttons[spellID] then
				OCCButton(spellID, professionID)
			end
		end
		updatePositions()
	end
end 

--------------------------------------------
