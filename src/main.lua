-- Anime Dice — Obsidian UI
-- Fires the game's own remotes (mapped from ReplicatedStorage.Network).
-- Remotes/args from tools/dump.lua + tools/argspy.lua; dropdown data from
-- tools/values.lua; inventory shape from tools/inv.lua. Nothing hidden —
-- every action is a remote the game itself fires when you click.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")
local VU        = game:GetService("VirtualUser")
local UIS       = game:GetService("UserInputService")
local RunSvc    = game:GetService("RunService")
local PPS       = game:GetService("ProximityPromptService")
local Http      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function char() return LocalPlayer.Character end
local function humanoid() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ============================================================
-- remotes
-- ============================================================
local Network = RS:WaitForChild("Network")
local function R(service, folder, name)
	local ok, obj = pcall(function()
		local s = Network:FindFirstChild(service); if not s then return nil end
		local f = s:FindFirstChild(folder);        if not f then return nil end
		return f:FindFirstChild(name)
	end)
	return ok and obj or nil
end

local RollDice     = R("RollService", "RF", "RollDice")
local SpinUse      = R("SpinService", "RE", "Use")
local BoostUse     = R("BoostService", "RE", "Use")
local BuyDice      = R("DiceShopService", "RE", "BuyDice")
local EquipDice    = R("DiceShopService", "RE", "EquipDice")
local CollectBal   = R("PlotService", "RE", "CollectBalance")
local LevelUpSlot  = R("PlotService", "RE", "LevelUpSlot")
local PlotEquipBest= R("PlotService", "RE", "EquipBest")
local Rebirth      = R("RebirthService", "RE", "Rebirth")
local DailyClaim   = R("DailyRewardService", "RE", "Claim")
local GroupClaim   = R("GroupRewardService", "RE", "Claim")
local OfflineClaim = R("OfflineEarningsService", "RE", "Claim")
local QuestClaim   = R("QuestService", "RE", "Claim")
local RedeemCode   = R("MonetizationService", "RE", "RedeemCode")
local GradeRoll    = R("GradeService", "RE", "Roll")
local GradeProtect = R("GradeService", "RE", "SetGradeProtected")
local TraitRoll    = R("TraitService", "RE", "Roll")
local TraitProtect = R("TraitService", "RE", "SetTraitProtected")
local UnitEquip    = R("UnitService", "RF", "Equip")
local UnitUnequip  = R("UnitService", "RF", "Unequip")
local SetLocked    = R("UnitService", "RE", "SetLocked")
local SellInventory= R("SellService", "RF", "SellInventory")
local SellEquipped = R("SellService", "RF", "SellEquipped")
local UpdateAutoSell = R("SellService", "RE", "UpdateAutoSell")
local PlayTower    = R("Towers", "RF", "PlayTower")
local CompleteFloor= R("Towers", "RF", "CompleteTowerFloor")
local CancelTower  = R("Towers", "RF", "CancelTower")
local TowerEquipBest = R("Towers", "RE", "EquipBestTowerTeam")
local RequestTrade = R("TradeService", "RE", "RequestTrade")
local RespondTrade = R("TradeService", "RE", "RespondToRequest")
local SetTradeEnabled = R("TradeService", "RE", "SetTradeRequestsEnabled")

-- ============================================================
-- runtime game data (inventory, rarity)
-- ============================================================
local DataClient, UnitConfig
pcall(function() DataClient = require(RS.Packages.Data.Client) end)
pcall(function() UnitConfig = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitConfig) end)

-- inventory = { uuid = { name, attributes = {mutation,locked,level,grade,trait}, amount } }
local function getInventory()
	local ok, root = pcall(function() return DataClient.data.___X end)
	if ok and type(root) == "table" and type(root.Inventory) == "table" then
		return root.Inventory
	end
	return {}
end

-- rarity of a unit name via UnitConfig.entries[name]
local rarityCache = {}
local function unitRarity(name)
	if rarityCache[name] ~= nil then return rarityCache[name] or nil end
	local r
	pcall(function()
		local e = UnitConfig and UnitConfig.entries and UnitConfig.entries[name]
		if e then r = e.rarity or e.Rarity or e.rarityName end
	end)
	rarityCache[name] = r or false
	return r
end

local function ownedUnitNames()
	local seen, list = {}, { "All" }
	for _, u in pairs(getInventory()) do
		if u.name and not seen[u.name] then seen[u.name] = true; list[#list + 1] = u.name end
	end
	table.sort(list)
	return list
end

-- ============================================================
-- executor http (for webhooks)
-- ============================================================
local httpreq = (syn and syn.request) or (http and http.request) or http_request or request
	or (fluxus and fluxus.request)
local function postJSON(url, body)
	if not httpreq or not url or url == "" then return end
	pcall(function()
		httpreq({
			Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = Http:JSONEncode(body),
		})
	end)
end

-- ============================================================
-- dropdown data (from tools/values.lua)
-- ============================================================
local GRADES   = { "A", "A+", "B", "C", "D", "S", "S+", "Z", "Z+", "神" }
local TRAITS   = { "Damage I", "Damage II", "Damage III", "Eternal", "Health I", "Health II", "Health III", "Monarch", "Money I", "Money II", "Money III", "Samurai", "Shogun", "Transcendent" }
local RARITIES = { "Celestial", "Common", "Divine", "Epic", "Exclusive", "Exotic", "Legendary", "Mythical", "Rare", "Secret1", "Secret2", "Uncommon" }
local DICE     = { "Arcane", "Basic", "Black Hole", "Blood Moon", "Chrono", "Corrupted", "Cyber", "Dragon", "Fire", "Galaxy", "Ice", "Light", "Lightning", "Lunar", "Magma", "Nature", "Normal", "Prismatic", "Royal", "Shadow", "Solar", "Storm", "Titan", "Toxic", "Void", "Water" }
local TOWERS   = { "Cursed Tower", "Dragon Tower", "Hidden Leaf Tower", "Infinity Tower", "Pirate Tower" }
local POTIONS  = { "Cursed Damage I", "Cursed Damage II", "Cursed Damage III", "Cursed Income I", "Cursed Income II", "Cursed Income III", "Cursed Luck I", "Cursed Luck II", "Cursed Luck III", "Damage I", "Damage II", "Damage III", "Damage IV", "Dragon Damage I", "Dragon Damage II", "Dragon Damage III", "Dragon Income I", "Dragon Income II", "Dragon Income III", "Dragon Luck I", "Dragon Luck II", "Dragon Luck III", "Income I", "Income II", "Income III", "Income IV", "Leaf Damage I", "Leaf Damage II", "Leaf Damage III", "Leaf Income I", "Leaf Income II", "Leaf Income III", "Leaf Luck I", "Leaf Luck II", "Leaf Luck III", "Luck I", "Luck II", "Luck III", "Luck IV", "Pirate Damage I", "Pirate Damage II", "Pirate Damage III", "Pirate Income I", "Pirate Income II", "Pirate Income III", "Pirate Luck I", "Pirate Luck II", "Pirate Luck III" }
local CODES    = { "10KCCU", "1KCCU", "20KCCU", "5KCCU", "RELEASE", "UPDATE1", "UPDATE2", "UPDATE3", "UPDATE4" }

-- turn a multi-dropdown value (set) into a plain list
local function setToList(set)
	local out = {}
	if type(set) == "table" then
		for k, v in pairs(set) do if v then out[#out + 1] = k end end
	end
	return out
end

-- ============================================================
-- config readers (potion durations, dice ranking)
-- ============================================================
local BoostConfig, DiceMod
pcall(function() BoostConfig = require(RS.Framework.Features.Inventory.Kinds.Boost.BoostConfig) end)
pcall(function() DiceMod = require(RS.Framework.Features.Rolling.Dice) end)

-- potion fields confirmed via probe2: entry.category / .tier / .duration
local function boostEntry(name) return BoostConfig and BoostConfig.entries and BoostConfig.entries[name] end
local function potionCategory(name)
	local c; pcall(function() local e = boostEntry(name); if e then c = e.category end end)
	return c or (name:gsub("%s+[IVX]+$", ""))
end
local function potionTier(name)
	local t; pcall(function() local e = boostEntry(name); if e then t = e.tier end end)
	return tonumber(t) or 0
end
local function potionDuration(name)
	local d; pcall(function() local e = boostEntry(name); if e then d = e.duration end end)
	return tonumber(d) or 300
end

-- dice fields confirmed: entry.luck / .price. Best = highest luck.
local function diceStat(name)
	local l, p; pcall(function()
		local d = DiceMod and DiceMod.Get and DiceMod.Get(name)
		if d then l = d.luck; p = d.price end
	end)
	return tonumber(l) or 0, tonumber(p) or 0
end
local diceRanked = {} -- best (highest luck) first
for _, n in ipairs(DICE) do diceRanked[#diceRanked + 1] = n end
table.sort(diceRanked, function(a, b)
	local la, pa = diceStat(a); local lb, pb = diceStat(b)
	if la ~= lb then return la > lb end
	return pa > pb
end)

-- ============================================================
-- Obsidian + addons
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title             = "Anime Dice",
	Footer            = "nyx build",
	Size              = UDim2.fromOffset(660, 520), -- wider so long unit names aren't cut off
	Center            = true,
	AutoShow          = true,
	ToggleKeybind     = Enum.KeyCode.RightShift,
	ShowCustomCursor  = false,
	ShowMobileButtons = true,
	MobileButtonsSide = "Left",
})

local Tabs = {
	Farm    = Window:AddTab({ Name = "Farm",    Icon = "coins" }),
	Units   = Window:AddTab({ Name = "Units",   Icon = "swords" }),
	Tower   = Window:AddTab({ Name = "Tower",   Icon = "castle" }),
	Shop    = Window:AddTab({ Name = "Shop",    Icon = "shopping-cart" }),
	Trade   = Window:AddTab({ Name = "Trade",   Icon = "arrow-left-right" }),
	Webhook = Window:AddTab({ Name = "Webhook", Icon = "webhook" }),
	Player  = Window:AddTab({ Name = "Player",  Icon = "user" }),
	Settings= Window:AddTab({ Name = "Settings",Icon = "settings" }),
}

-- adds Select All / Deselect All buttons for a multi-dropdown
local function addSelAll(box, dd, values, setter)
	box:AddButton({ Text = "Select All", Func = function()
		local s = {}; for _, v in ipairs(values) do s[v] = true end
		setter(s); pcall(function() dd:SetValue(s) end)
	end })
	box:AddButton({ Text = "Deselect All", Func = function()
		setter({}); pcall(function() dd:SetValue({}) end)
	end })
end

-- ============================================================
-- state
-- ============================================================
local running = true
-- farm
local autoRoll = false
local autoCollect, plotId = false, 1
local autoRebirth = false
local autoSpin = false
local autoClaimQuest, autoClaimAll = false, false
local autoEquipBest, autoEquipDice = false, false
-- units
local autoGrade, gradeUnit, keepGrades = false, "All", {}
local autoTrait, traitUnit, keepTraits = false, "All", {}
local autoLock, lockRarities = false, {}
local autoSellFull = false
local autoUpgrade, upgradeLevelLimit = false, 200
-- tower
local autoAcceptTrades = false
local autoTower, towerMode = false, "Hidden Leaf Tower"
local autoRotate, rotationMaps = false, {}
local runsPerMap, stopFloor = 20, 0
local towerEquipBest = false
-- shop
local autoUsePotions, selectedPotions = false, {}
local autoBuyDice = false
-- player
local antiAfk = false
local walkSpeedOn, walkSpeedAmt = false, 75
local infJump, noclip, instantPmt = false, false, false
local flying, flySpeed = false, 60
-- webhook
local unitHookOn, unitHookUrl, unitHookInterval, unitHookRarities = false, "", 30, {}
local invHookOn, invHookUrl, invHookInterval = false, "", 15

-- auto-detect plot id via the game's Comm property (RP.PlotId)
task.spawn(function()
	pcall(function()
		local Comm = require(RS.Packages.Network)
		local pc = Comm.ClientComm.new(Network, false, "PlotService")
		local prop = pc:GetProperty("PlotId")
		if prop then
			local v = prop:Get(); if v ~= nil then plotId = v end
			if prop.Observe then prop:Observe(function(nv) if nv ~= nil then plotId = nv end end) end
		end
	end)
end)

-- ============================================================
-- background loops (flag-gated)
-- ============================================================
local function loop(intervalOn, intervalOff, fn)
	task.spawn(function()
		while running do
			local on = fn()
			task.wait(on and intervalOn or intervalOff)
		end
	end)
end

-- fast roll — always max speed (InvokeServer yields → paced by server round-trip)
task.spawn(function()
	while running do
		if autoRoll and RollDice then
			pcall(function() RollDice:InvokeServer() end)
			task.wait()
		else
			task.wait(0.1)
		end
	end
end)

loop(0.5, 0.5, function()
	if autoCollect and CollectBal then pcall(function() CollectBal:FireServer(plotId) end) return true end
end)
loop(2, 0.5, function()
	if autoRebirth and Rebirth then pcall(function() Rebirth:FireServer() end) return true end
end)
loop(1, 1, function()
	local did = false
	if autoClaimQuest and QuestClaim then pcall(function() QuestClaim:FireServer() end) did = true end
	if autoClaimAll then
		for _, r in ipairs({ DailyClaim, GroupClaim, OfflineClaim, QuestClaim }) do
			if r then pcall(function() r:FireServer() end) end
		end
		did = true
	end
	return did
end)
loop(0.5, 0.5, function()
	if autoEquipBest and PlotEquipBest then pcall(function() PlotEquipBest:FireServer() end) return true end
end)
loop(5, 1, function()
	-- equip the best (most expensive) dice; unowned equips are ignored server-side
	if autoEquipDice and EquipDice and diceRanked[1] then pcall(function() EquipDice:FireServer(diceRanked[1]) end) return true end
end)
loop(1, 0.3, function()
	if autoSpin and SpinUse then pcall(function() SpinUse:FireServer("Lucky Spin") end) return true end
end)

-- units: grade / trait reroll, lock, upgrade
loop(0.4, 0.5, function()
	if not autoGrade or not GradeRoll then return false end
	for uuid, u in pairs(getInventory()) do
		if (gradeUnit == "All" or u.name == gradeUnit) then
			local g = u.attributes and u.attributes.grade
			if g and not keepGrades[g] then pcall(function() GradeRoll:FireServer(uuid) end) end
		end
	end
	return true
end)
loop(0.4, 0.5, function()
	if not autoTrait or not TraitRoll then return false end
	for uuid, u in pairs(getInventory()) do
		if (traitUnit == "All" or u.name == traitUnit) then
			local t = u.attributes and u.attributes.trait
			if t and not keepTraits[t] then pcall(function() TraitRoll:FireServer(uuid) end) end
		end
	end
	return true
end)
loop(1, 1, function()
	if not autoLock or not SetLocked then return false end
	for uuid, u in pairs(getInventory()) do
		local rar = unitRarity(u.name)
		if rar and lockRarities[rar] and not (u.attributes and u.attributes.locked) then
			pcall(function() SetLocked:FireServer({ [uuid] = true }) end)
		end
	end
	return true
end)
loop(1, 1, function()
	-- upgrade placed units = level up plot slots (server rejects if maxed/broke)
	if not autoUpgrade or not LevelUpSlot then return false end
	for slot = 1, 12 do pcall(function() LevelUpSlot:FireServer(slot) end) end
	return true
end)

-- shop: potions (re-use only when expired, one per type), buy best dice
local lastUsed = {}
loop(5, 2, function()
	if not autoUsePotions or not BoostUse then return false end
	-- one potion per type: keep only the highest tier of each family
	local best = {}
	for _, p in ipairs(setToList(selectedPotions)) do
		local ty = potionCategory(p)
		if not best[ty] or potionTier(p) > potionTier(best[ty]) then best[ty] = p end
	end
	local now = os.clock()
	for _, p in pairs(best) do
		if not lastUsed[p] or (now - lastUsed[p]) >= potionDuration(p) then
			pcall(function() BoostUse:FireServer(p) end)
			lastUsed[p] = now
		end
	end
	return true
end)
loop(2, 1, function()
	-- buy best: buy every dice; server buys what you can afford (incl. the best)
	if not autoBuyDice or not BuyDice then return false end
	for _, n in ipairs(diceRanked) do pcall(function() BuyDice:FireServer(n) end) end
	return true
end)

-- tower state machine
task.spawn(function()
	while running do
		if autoTower and PlayTower then
			local maps = autoRotate and setToList(rotationMaps) or { towerMode }
			if #maps == 0 then maps = { towerMode } end
			for _, map in ipairs(maps) do
				if not autoTower then break end
				for _ = 1, math.max(1, runsPerMap) do
					if not autoTower then break end
					if towerEquipBest and TowerEquipBest then pcall(function() TowerEquipBest:FireServer() end) end
					pcall(function() PlayTower:InvokeServer(map) end)
					local floor, cap = 0, (stopFloor > 0 and stopFloor or 1000)
					while autoTower and floor < cap do
						local ok = pcall(function() return CompleteFloor:InvokeServer() end)
						floor = floor + 1
						task.wait(0.5)
						if not ok then break end
					end
					pcall(function() CancelTower:InvokeServer() end)
					task.wait(0.5)
				end
			end
		end
		task.wait(1)
	end
end)

-- webhooks
local seenUnits = {}
for uuid in pairs(getInventory()) do seenUnits[uuid] = true end -- don't spam existing on first run
task.spawn(function()
	while running do
		if unitHookOn and unitHookUrl ~= "" then
			for uuid, u in pairs(getInventory()) do
				if not seenUnits[uuid] then
					seenUnits[uuid] = true
					local rar = unitRarity(u.name) or "?"
					if next(unitHookRarities) == nil or unitHookRarities[rar] then
						local a = u.attributes or {}
						postJSON(unitHookUrl, { embeds = { {
							title = "New Unit: " .. tostring(u.name),
							description = ("Rarity: %s\nGrade: %s\nTrait: %s\nMutation: %s"):format(
								rar, tostring(a.grade), tostring(a.trait), tostring(a.mutation)),
							color = 8388736,
						} } })
					end
				end
			end
		end
		task.wait(math.max(5, unitHookInterval))
	end
end)
task.spawn(function()
	while running do
		if invHookOn and invHookUrl ~= "" then
			local count, byRar = 0, {}
			for _, u in pairs(getInventory()) do
				count = count + (u.amount or 1)
				local r = unitRarity(u.name) or "?"
				byRar[r] = (byRar[r] or 0) + 1
			end
			local lines = {}
			for r, n in pairs(byRar) do lines[#lines + 1] = ("%s: %d"):format(r, n) end
			postJSON(invHookUrl, { embeds = { {
				title = "Inventory — " .. LocalPlayer.Name,
				description = ("Total units: %d\n%s"):format(count, table.concat(lines, "\n")),
				color = 8388736,
			} } })
		end
		task.wait(math.max(60, invHookInterval * 60))
	end
end)

-- player: walkspeed + noclip
RunSvc.Heartbeat:Connect(function()
	if walkSpeedOn then local h = humanoid(); if h then h.WalkSpeed = walkSpeedAmt end end
	if noclip then
		local c = char()
		if c then for _, v in ipairs(c:GetDescendants()) do
			if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
		end end
	end
end)
UIS.JumpRequest:Connect(function()
	if infJump then local h = humanoid(); if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end end
end)
PPS.PromptButtonHoldBegan:Connect(function(p)
	if instantPmt then pcall(function() fireproximityprompt(p) end) end
end)

local flyGyro, flyVel
local function startFly()
	local root = hrp(); if not root then return end
	local h = humanoid(); if h then h.PlatformStand = true end
	flyGyro = Instance.new("BodyGyro"); flyGyro.P = 9e4; flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9); flyGyro.CFrame = root.CFrame; flyGyro.Parent = root
	flyVel = Instance.new("BodyVelocity"); flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9); flyVel.Velocity = Vector3.zero; flyVel.Parent = root
end
local function stopFly()
	local h = humanoid(); if h then h.PlatformStand = false end
	if flyGyro then flyGyro:Destroy(); flyGyro = nil end
	if flyVel then flyVel:Destroy(); flyVel = nil end
end
RunSvc.RenderStepped:Connect(function()
	if not flying or not flyVel or not flyGyro then return end
	local cam = Workspace.CurrentCamera; if not cam then return end
	flyGyro.CFrame = cam.CFrame
	local dir = Vector3.zero
	if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
	flyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * flySpeed
end)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if flying then startFly() end
end)
LocalPlayer.Idled:Connect(function()
	if not antiAfk then return end
	pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
end)

-- ============================================================
-- FARM tab
-- ============================================================
local FarmBox = Tabs.Farm:AddLeftGroupbox("Auto Farm")
local EquipBox = Tabs.Farm:AddRightGroupbox("Equip")

FarmBox:AddToggle("AutoRoll", { Text = "Auto Roll (max speed)", Default = false,
	Tooltip = "Loops RollDice as fast as the server answers.",
	Callback = function(v) autoRoll = v end })
FarmBox:AddToggle("AutoCollect", { Text = "Auto Collect Money", Default = false,
	Tooltip = "Plot auto-detected.",
	Callback = function(v) autoCollect = v end })
FarmBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false,
	Callback = function(v) autoRebirth = v end })
FarmBox:AddToggle("AutoSpin", { Text = "Auto Spin", Default = false,
	Callback = function(v) autoSpin = v end })
FarmBox:AddToggle("AutoClaimQuest", { Text = "Auto Claim Quest", Default = false,
	Callback = function(v) autoClaimQuest = v end })
FarmBox:AddToggle("AutoClaimAll", { Text = "Auto Claim All (daily/group/offline)", Default = false,
	Callback = function(v) autoClaimAll = v end })
FarmBox:AddInput("Redeem", { Text = "Redeem Code", Placeholder = "code", Default = "",
	Finished = true, Callback = function(v) if RedeemCode and v ~= "" then pcall(function() RedeemCode:FireServer(v) end) end end })

EquipBox:AddToggle("AutoEquipBest", { Text = "Auto Equip Best Units", Default = false,
	Callback = function(v) autoEquipBest = v end })
EquipBox:AddToggle("AutoEquipDice", { Text = "Auto Equip Best Dice", Default = false,
	Tooltip = "Keeps your best (most expensive) dice equipped automatically.",
	Callback = function(v) autoEquipDice = v end })

-- ============================================================
-- UNITS tab
-- ============================================================
local GradeBox = Tabs.Units:AddLeftGroupbox("Grade")
local SellBox  = Tabs.Units:AddLeftGroupbox("Sell")
local LockBox  = Tabs.Units:AddLeftGroupbox("Lock")
local TraitBox = Tabs.Units:AddRightGroupbox("Trait")
local UpBox    = Tabs.Units:AddRightGroupbox("Upgrade")

local unitNames = ownedUnitNames()

local gradeUnitDD = GradeBox:AddDropdown("GradeUnit", { Text = "Unit", Values = unitNames, Default = "All", Multi = false,
	Callback = function(v) gradeUnit = v end })
local keepGradesDD = GradeBox:AddDropdown("KeepGrades", { Text = "Keep Grades", Values = GRADES, Default = {}, Multi = true,
	Tooltip = "Reroll stops when the unit hits one of these.",
	Callback = function(v) keepGrades = v end })
addSelAll(GradeBox, keepGradesDD, GRADES, function(s) keepGrades = s end)
GradeBox:AddToggle("AutoGrade", { Text = "Auto Grade", Default = false,
	Callback = function(v) autoGrade = v end })

SellBox:AddLabel({ Text = "Uses the game's own Sell remotes." })
SellBox:AddButton({ Text = "Sell Inventory",
	Func = function() pcall(function() SellInventory:InvokeServer() end) end,
	Callback = function() pcall(function() SellInventory:InvokeServer() end) end })
SellBox:AddToggle("SellWhenFull", { Text = "Sell All When Full (native auto-sell)", Default = false,
	Callback = function(v) autoSellFull = v; if UpdateAutoSell then pcall(function() UpdateAutoSell:FireServer(v) end) end end })

local lockRaritiesDD = LockBox:AddDropdown("LockRarities", { Text = "Rarities", Values = RARITIES, Default = {}, Multi = true,
	Callback = function(v) lockRarities = v end })
addSelAll(LockBox, lockRaritiesDD, RARITIES, function(s) lockRarities = s end)
LockBox:AddToggle("AutoLock", { Text = "Auto Lock", Default = false,
	Callback = function(v) autoLock = v end })

local traitUnitDD = TraitBox:AddDropdown("TraitUnit", { Text = "Unit", Values = unitNames, Default = "All", Multi = false,
	Callback = function(v) traitUnit = v end })
local keepTraitsDD = TraitBox:AddDropdown("KeepTraits", { Text = "Keep Traits", Values = TRAITS, Default = {}, Multi = true,
	Callback = function(v) keepTraits = v end })
addSelAll(TraitBox, keepTraitsDD, TRAITS, function(s) keepTraits = s end)
TraitBox:AddToggle("AutoTrait", { Text = "Auto Trait", Default = false,
	Callback = function(v) autoTrait = v end })

UpBox:AddSlider("LevelLimit", { Text = "Level Limit", Default = 200, Min = 1, Max = 200, Rounding = 0,
	Callback = function(v) upgradeLevelLimit = v end })
UpBox:AddToggle("AutoUpgrade", { Text = "Auto Upgrade Placed Units", Default = false,
	Tooltip = "Levels your plot slots (server caps at what you can afford).",
	Callback = function(v) autoUpgrade = v end })

GradeBox:AddButton({ Text = "Refresh Unit List", Func = function()
	local names = ownedUnitNames()
	pcall(function() gradeUnitDD:SetValues(names) end)
	pcall(function() traitUnitDD:SetValues(names) end)
	Library:Notify("Unit list refreshed (" .. (#names - 1) .. " units)")
end })

-- ============================================================
-- TOWER tab
-- ============================================================
local TowerBox = Tabs.Tower:AddLeftGroupbox("Tower")
TowerBox:AddDropdown("TowerMode", { Text = "Mode", Values = TOWERS, Default = "Hidden Leaf Tower", Multi = false,
	Callback = function(v) towerMode = v end })
TowerBox:AddToggle("AutoRotate", { Text = "Auto Rotate Maps", Default = false,
	Callback = function(v) autoRotate = v end })
local rotationMapsDD = TowerBox:AddDropdown("RotationMaps", { Text = "Rotation Maps", Values = TOWERS, Default = {}, Multi = true,
	Callback = function(v) rotationMaps = v end })
addSelAll(TowerBox, rotationMapsDD, TOWERS, function(s) rotationMaps = s end)
TowerBox:AddSlider("RunsPerMap", { Text = "Runs Per Map", Default = 20, Min = 1, Max = 20, Rounding = 0,
	Callback = function(v) runsPerMap = v end })
TowerBox:AddSlider("StopFloor", { Text = "Stop At Floor (0 = max)", Default = 0, Min = 0, Max = 1000, Rounding = 0,
	Callback = function(v) stopFloor = v end })
TowerBox:AddToggle("TowerEquipBest", { Text = "Auto Equip Best Team", Default = false,
	Callback = function(v) towerEquipBest = v end })
TowerBox:AddToggle("AutoTower", { Text = "Auto Tower", Default = false,
	Callback = function(v) autoTower = v end })

-- ============================================================
-- SHOP tab
-- ============================================================
local PotBox  = Tabs.Shop:AddLeftGroupbox("Potions")
local DiceBox = Tabs.Shop:AddRightGroupbox("Dice")
local UpgBox  = Tabs.Shop:AddRightGroupbox("Upgrades")

local potionsDD = PotBox:AddDropdown("Potions", { Text = "Potions", Values = POTIONS, Default = {}, Multi = true,
	Callback = function(v) selectedPotions = v end })
addSelAll(PotBox, potionsDD, POTIONS, function(s) selectedPotions = s end)
PotBox:AddToggle("AutoUsePotions", { Text = "Auto Use Potions", Default = false,
	Tooltip = "Re-uses each potion only when it expires; one per type.",
	Callback = function(v) autoUsePotions = v end })

DiceBox:AddToggle("AutoBuyDice", { Text = "Auto Buy Best Dice", Default = false,
	Tooltip = "Buys every dice; server buys what you can afford (incl. the best).",
	Callback = function(v) autoBuyDice = v end })

UpgBox:AddLabel({ Text = "Auto-buy upgrades: needs its remote captured — deferred.", Visible = true })

-- ============================================================
-- TRADE tab (partial — offer/confirm not captured yet)
-- ============================================================
local TradeBox = Tabs.Trade:AddLeftGroupbox("Trade")
TradeBox:AddInput("TradePartner", { Text = "Request trade (username)", Placeholder = "player", Default = "",
	Finished = true, Callback = function(name)
		local target = Players:FindFirstChild(name)
		if target and RequestTrade then pcall(function() RequestTrade:FireServer(target) end) end
	end })
TradeBox:AddToggle("AcceptTrades", { Text = "Auto Accept Trade Requests", Default = false,
	Tooltip = "Responds true to incoming requests.",
	Callback = function(v)
		autoAcceptTrades = v
		if v and RespondTrade then pcall(function() RespondTrade:FireServer(true) end) end
	end })
TradeBox:AddToggle("TradeRequestsEnabled", { Text = "Trade Requests Enabled", Default = true,
	Callback = function(v) if SetTradeEnabled then pcall(function() SetTradeEnabled:FireServer(v) end) end end })
TradeBox:AddLabel({ Text = "Auto-offer + confirm need a captured trade — spy a full trade to unlock." })

-- ============================================================
-- WEBHOOK tab
-- ============================================================
local UHook = Tabs.Webhook:AddLeftGroupbox("Unit Webhook")
local IHook = Tabs.Webhook:AddRightGroupbox("Inventory Webhook")

UHook:AddInput("UnitHookUrl", { Text = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Default = "",
	Callback = function(v) unitHookUrl = v end })
local unitHookRaritiesDD = UHook:AddDropdown("UnitHookRarities", { Text = "Only these rarities (empty = all)", Values = RARITIES, Default = {}, Multi = true,
	Callback = function(v) unitHookRarities = v end })
addSelAll(UHook, unitHookRaritiesDD, RARITIES, function(s) unitHookRarities = s end)
UHook:AddSlider("UnitHookInterval", { Text = "Check every (s)", Default = 30, Min = 5, Max = 300, Rounding = 0,
	Callback = function(v) unitHookInterval = v end })
UHook:AddToggle("UnitHookOn", { Text = "Unit Webhook", Default = false,
	Tooltip = "Posts new units you roll to your Discord webhook.",
	Callback = function(v) unitHookOn = v end })

IHook:AddInput("InvHookUrl", { Text = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Default = "",
	Callback = function(v) invHookUrl = v end })
IHook:AddSlider("InvHookInterval", { Text = "Every (min)", Default = 15, Min = 1, Max = 240, Rounding = 0,
	Callback = function(v) invHookInterval = v end })
IHook:AddToggle("InvHookOn", { Text = "Inventory Webhook", Default = false,
	Callback = function(v) invHookOn = v end })
IHook:AddButton({ Text = "Send Now", Func = function()
	if invHookUrl == "" then return end
	local count = 0
	for _, u in pairs(getInventory()) do count = count + (u.amount or 1) end
	postJSON(invHookUrl, { content = ("Inventory: %d units"):format(count) })
	Library:Notify("Inventory webhook sent")
end })

-- ============================================================
-- PLAYER tab
-- ============================================================
local MoveBox = Tabs.Player:AddLeftGroupbox("Movement")
local FlyBox  = Tabs.Player:AddLeftGroupbox("Fly")
local PerfBox = Tabs.Player:AddRightGroupbox("Performance")

MoveBox:AddToggle("WalkSpeed", { Text = "WalkSpeed", Default = false,
	Callback = function(v) walkSpeedOn = v; if not v then local h = humanoid(); if h then pcall(function() h.WalkSpeed = 16 end) end end end })
MoveBox:AddSlider("WalkSpeedAmount", { Text = "WalkSpeed Amount", Default = 75, Min = 16, Max = 250, Rounding = 0,
	Callback = function(v) walkSpeedAmt = v end })
MoveBox:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false, Callback = function(v) infJump = v end })
MoveBox:AddToggle("NoClip", { Text = "NoClip", Default = false, Callback = function(v) noclip = v end })
MoveBox:AddToggle("InstantPrompt", { Text = "Instant ProximityPrompt", Default = false, Callback = function(v) instantPmt = v end })

FlyBox:AddToggle("Fly", { Text = "Fly", Default = false, Tooltip = "WASD + Space/Shift, camera-relative.",
	Callback = function(v) flying = v; if v then startFly() else stopFly() end end })
FlyBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 60, Min = 10, Max = 400, Rounding = 0,
	Callback = function(v) flySpeed = v end })

local perf = { disabled = {}, shadows = nil, water = nil }
local function setQuality(l) pcall(function() settings().Rendering.QualityLevel = l end) end
local function fpsBoost(on)
	local Terrain = Workspace:FindFirstChildOfClass("Terrain")
	if on then
		setQuality(Enum.QualityLevel.Level01)
		perf.shadows = Lighting.GlobalShadows; pcall(function() Lighting.GlobalShadows = false end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
				if v.Enabled then v.Enabled = false; table.insert(perf.disabled, v) end
			end
		end
		if Terrain then
			perf.water = { Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.WaterTransparency }
			pcall(function() Terrain.WaterWaveSize, Terrain.WaterWaveSpeed = 0, 0; Terrain.WaterReflectance, Terrain.WaterTransparency = 0, 0 end)
		end
	else
		setQuality(Enum.QualityLevel.Automatic)
		if perf.shadows ~= nil then pcall(function() Lighting.GlobalShadows = perf.shadows end) end
		for _, v in ipairs(perf.disabled) do pcall(function() v.Enabled = true end) end
		perf.disabled = {}
		if Terrain and perf.water then
			pcall(function() Terrain.WaterWaveSize, Terrain.WaterWaveSpeed = perf.water[1], perf.water[2]; Terrain.WaterReflectance, Terrain.WaterTransparency = perf.water[3], perf.water[4] end)
		end
	end
end
local function gpuSaver(on) pcall(function() RunSvc:Set3dRenderingEnabled(not on) end) end

PerfBox:AddToggle("FPSBoost", { Text = "FPS Boost", Default = false,
	Tooltip = "Low quality, no shadows, no particles, flat water.", Callback = fpsBoost })
PerfBox:AddToggle("GPUSaver", { Text = "GPU Saver (disable 3D)", Default = false,
	Tooltip = "Stops rendering the 3D world. UI stays.", Callback = gpuSaver })
PerfBox:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = false,
	Callback = function(v) antiAfk = v end })

-- ============================================================
-- SETTINGS tab — config + theme
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("AnimeDice")
SaveManager:SetFolder("AnimeDice")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- ============================================================
-- cleanup + autoload
-- ============================================================
Library:OnUnload(function()
	running = false
	autoRoll, autoCollect, autoRebirth, autoClaimQuest, autoClaimAll = false, false, false, false, false
	autoEquipBest, autoEquipDice, autoSpin = false, false, false
	autoGrade, autoTrait, autoLock, autoUpgrade = false, false, false, false
	autoTower, autoUsePotions, autoBuyDice = false, false, false
	unitHookOn, invHookOn = false, false
	walkSpeedOn, infJump, noclip, instantPmt, antiAfk = false, false, false, false, false
	if flying then stopFly() end; flying = false
	if autoSellFull and UpdateAutoSell then pcall(function() UpdateAutoSell:FireServer(false) end) end
	fpsBoost(false); gpuSaver(false)
end)

SaveManager:LoadAutoloadConfig()
Library:Notify("Anime Dice loaded — RightShift to toggle UI")
