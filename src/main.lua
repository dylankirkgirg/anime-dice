-- Anime Dice — Obsidian UI
-- Fires the game's own remotes (mapped from ReplicatedStorage.Network via Dex).
-- Loaded by loader.lua. Nothing here is hidden: it only fires the same
-- remotes the game fires when you click.

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting  = game:GetService("Lighting")
local VU        = game:GetService("VirtualUser")
local UIS       = game:GetService("UserInputService")
local RunSvc    = game:GetService("RunService")
local PPS       = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer

local function char() return LocalPlayer.Character end
local function humanoid()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
	local c = char()
	return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- remotes
-- ============================================================
local Network     = RS:WaitForChild("Network")
local RollService = Network:WaitForChild("RollService")
local SellService = Network:WaitForChild("SellService")

local RollDice       = RollService.RF:WaitForChild("RollDice")       -- RemoteFunction
local UpdateAutoSell = SellService.RE:WaitForChild("UpdateAutoSell") -- RemoteEvent (bool)
local SellInventory  = SellService.RF:WaitForChild("SellInventory")  -- RemoteFunction
local SellEquipped   = SellService.RF:WaitForChild("SellEquipped")   -- RemoteFunction

-- optional remotes (nil if the game's layout differs — every use is guarded)
local function getRemote(service, folder, name)
	local ok, obj = pcall(function()
		local s = Network:FindFirstChild(service); if not s then return nil end
		local f = s:FindFirstChild(folder);        if not f then return nil end
		return f:FindFirstChild(name)
	end)
	return ok and obj or nil
end

local SpinUse      = getRemote("SpinService",           "RE", "Use")
local DailyClaim   = getRemote("DailyRewardService",    "RE", "Claim")
local GroupClaim   = getRemote("GroupRewardService",    "RE", "Claim")
local OfflineClaim = getRemote("OfflineEarningsService","RE", "Claim")
local QuestClaim   = getRemote("QuestService",          "RE", "Claim")
local Rebirth      = getRemote("RebirthService",        "RE", "Rebirth")
local RedeemCode   = getRemote("MonetizationService",   "RE", "RedeemCode")
local CollectBal   = getRemote("PlotService",           "RE", "CollectBalance")
local EquipBest    = getRemote("PlotService",           "RE", "EquipBest")
local claimRemotes = { DailyClaim, GroupClaim, OfflineClaim, QuestClaim }

-- ============================================================
-- Obsidian + addons
-- ============================================================
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title            = "Anime Dice",
	Footer           = "nyx build",
	Center           = true,
	AutoShow         = true,
	ToggleKeybind    = Enum.KeyCode.RightShift, -- show/hide
	ShowCustomCursor = false,                   -- use native Mac/Roblox cursor, not the plus
	ShowMobileButtons = true,                   -- on-screen open/close button
	MobileButtonsSide = "Left",
})

local Tabs = {
	Main   = Window:AddTab({ Name = "Main",   Icon = "dices" }),
	Farm   = Window:AddTab({ Name = "Farm",   Icon = "coins" }),
	Player = Window:AddTab({ Name = "Player", Icon = "user" }),
}

-- ============================================================
-- shared state
-- ============================================================
local running = true
-- rolling / selling
local fastRoll   = false
local rollDelay  = 0     -- 0 = as fast as the server answers
local autoSellOn = false
-- farm
local autoSpin    = false
local autoClaim   = false
local autoRebirth = false
-- player
local antiAfk      = false
local walkSpeedOn  = false
local walkSpeedAmt = 75
local infJump      = false
local noclip       = false
local instantPmt   = false
local flying       = false
local flySpeed     = 60

-- ============================================================
-- background loops / hooks (all flag-gated)
-- ============================================================

-- fast roll: InvokeServer yields until the server answers, so no wait needed
-- at rollDelay 0 — it's paced by round-trip, not a busy loop.
task.spawn(function()
	while running do
		if fastRoll then
			pcall(function() RollDice:InvokeServer() end)
			if rollDelay > 0 then task.wait(rollDelay) else task.wait() end
		else
			task.wait(0.1)
		end
	end
end)

-- farm loops
task.spawn(function()
	while running do
		if autoSpin and SpinUse then pcall(function() SpinUse:FireServer() end) end
		task.wait(autoSpin and 1 or 0.3)
	end
end)
task.spawn(function()
	while running do
		if autoClaim then
			for _, r in ipairs(claimRemotes) do
				if r then pcall(function() r:FireServer() end) end
			end
		end
		task.wait(autoClaim and 30 or 1)
	end
end)
task.spawn(function()
	while running do
		if autoRebirth and Rebirth then pcall(function() Rebirth:FireServer() end) end
		task.wait(autoRebirth and 2 or 0.5)
	end
end)

-- walkspeed enforce + noclip (per physics step)
RunSvc.Heartbeat:Connect(function()
	if walkSpeedOn then
		local h = humanoid()
		if h then h.WalkSpeed = walkSpeedAmt end
	end
	if noclip then
		local c = char()
		if c then
			for _, v in ipairs(c:GetDescendants()) do
				if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
			end
		end
	end
end)

-- infinite jump
UIS.JumpRequest:Connect(function()
	if infJump then
		local h = humanoid()
		if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end)

-- instant proximity prompts
PPS.PromptButtonHoldBegan:Connect(function(prompt)
	if instantPmt then pcall(function() fireproximityprompt(prompt) end) end
end)

-- fly
local flyGyro, flyVel
local function startFly()
	local root = hrp()
	if not root then return end
	local h = humanoid()
	if h then h.PlatformStand = true end
	flyGyro = Instance.new("BodyGyro")
	flyGyro.P = 9e4
	flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyGyro.CFrame = root.CFrame
	flyGyro.Parent = root
	flyVel = Instance.new("BodyVelocity")
	flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	flyVel.Velocity = Vector3.zero
	flyVel.Parent = root
end
local function stopFly()
	local h = humanoid()
	if h then h.PlatformStand = false end
	if flyGyro then flyGyro:Destroy(); flyGyro = nil end
	if flyVel then flyVel:Destroy(); flyVel = nil end
end

RunSvc.RenderStepped:Connect(function()
	if not flying or not flyVel or not flyGyro then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
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

-- re-apply after a respawn
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if autoSellOn then pcall(function() UpdateAutoSell:FireServer(true) end) end
	if flying then startFly() end
end)

-- anti-afk: defeat the 20-min idle kick
LocalPlayer.Idled:Connect(function()
	if not antiAfk then return end
	pcall(function()
		VU:CaptureController()
		VU:ClickButton2(Vector2.new())
	end)
end)

-- ============================================================
-- MAIN tab — rolling + selling
-- ============================================================
local RollBox = Tabs.Main:AddLeftGroupbox("Rolling")
local SellBox = Tabs.Main:AddRightGroupbox("Selling")

RollBox:AddToggle("FastRoll", {
	Text = "Fast Roll", Default = false,
	Tooltip = "Loops RollDice as fast as the server answers.",
	Callback = function(v)
		fastRoll = v
		Library:Notify("Fast Roll " .. (v and "ON" or "OFF"))
	end,
})
RollBox:AddSlider("RollDelay", {
	Text = "Roll delay (s) — 0 = max", Default = 0, Min = 0, Max = 1, Rounding = 2,
	Callback = function(v) rollDelay = v end,
})

SellBox:AddToggle("AutoSell", {
	Text = "Auto Sell (native)", Default = false,
	Callback = function(v)
		autoSellOn = v
		pcall(function() UpdateAutoSell:FireServer(v) end)
	end,
})
-- Func + Callback both set: Obsidian versions differ on which key the
-- button reads; the unused one is ignored, so the button always fires.
SellBox:AddButton({
	Text = "Sell Inventory",
	Func = function() pcall(function() SellInventory:InvokeServer() end) end,
	Callback = function() pcall(function() SellInventory:InvokeServer() end) end,
})
SellBox:AddButton({
	Text = "Sell Equipped",
	Func = function() pcall(function() SellEquipped:InvokeServer() end) end,
	Callback = function() pcall(function() SellEquipped:InvokeServer() end) end,
})

-- ============================================================
-- FARM tab — auto spin / claim / rebirth / codes
-- ============================================================
local FarmBox = Tabs.Farm:AddLeftGroupbox("Auto Farm")
local ExtraBox = Tabs.Farm:AddRightGroupbox("Extras")

FarmBox:AddToggle("AutoSpin", {
	Text = "Auto Spin", Default = false,
	Callback = function(v) autoSpin = v end,
})
FarmBox:AddToggle("AutoClaim", {
	Text = "Auto Claim Rewards", Default = false,
	Tooltip = "Daily / Group / Offline / Quest every 30s.",
	Callback = function(v) autoClaim = v end,
})
FarmBox:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth", Default = false,
	Tooltip = "Fires Rebirth on a loop. Server rejects it until you can afford it.",
	Callback = function(v) autoRebirth = v end,
})

ExtraBox:AddButton({
	Text = "Collect Balance",
	Func = function() if CollectBal then pcall(function() CollectBal:FireServer() end) end end,
	Callback = function() if CollectBal then pcall(function() CollectBal:FireServer() end) end end,
})
ExtraBox:AddButton({
	Text = "Equip Best",
	Func = function() if EquipBest then pcall(function() EquipBest:FireServer() end) end end,
	Callback = function() if EquipBest then pcall(function() EquipBest:FireServer() end) end end,
})

local codeText = ""
ExtraBox:AddInput("RedeemCode", {
	Text = "Code", Default = "", Placeholder = "enter code",
	Callback = function(v) codeText = v end,
})
ExtraBox:AddButton({
	Text = "Redeem Code",
	Func = function() if RedeemCode and codeText ~= "" then pcall(function() RedeemCode:FireServer(codeText) end) end end,
	Callback = function() if RedeemCode and codeText ~= "" then pcall(function() RedeemCode:FireServer(codeText) end) end end,
})

-- ============================================================
-- PLAYER tab — movement / fly / performance / config
-- ============================================================
local MoveBox = Tabs.Player:AddLeftGroupbox("Movement")
local FlyBox  = Tabs.Player:AddLeftGroupbox("Fly")
local PerfBox = Tabs.Player:AddRightGroupbox("Performance")

MoveBox:AddToggle("WalkSpeed", {
	Text = "WalkSpeed", Default = false,
	Callback = function(v)
		walkSpeedOn = v
		if not v then
			local h = humanoid()
			if h then pcall(function() h.WalkSpeed = 16 end) end
		end
	end,
})
MoveBox:AddSlider("WalkSpeedAmount", {
	Text = "WalkSpeed Amount", Default = 75, Min = 16, Max = 250, Rounding = 0,
	Callback = function(v) walkSpeedAmt = v end,
})
MoveBox:AddToggle("InfiniteJump", {
	Text = "Infinite Jump", Default = false,
	Callback = function(v) infJump = v end,
})
MoveBox:AddToggle("NoClip", {
	Text = "NoClip", Default = false,
	Callback = function(v) noclip = v end,
})
MoveBox:AddToggle("InstantPrompt", {
	Text = "Instant ProximityPrompt", Default = false,
	Callback = function(v) instantPmt = v end,
})

FlyBox:AddToggle("Fly", {
	Text = "Fly", Default = false,
	Tooltip = "WASD + Space/Shift. Camera-relative.",
	Callback = function(v)
		flying = v
		if v then startFly() else stopFly() end
	end,
})
FlyBox:AddSlider("FlySpeed", {
	Text = "Fly Speed", Default = 60, Min = 10, Max = 400, Rounding = 0,
	Callback = function(v) flySpeed = v end,
})

-- FPS boost: low quality, no shadows, kill visual clutter, flatten water.
-- Reversible — toggling off restores what it changed (rejoin fully resets).
local perf = { disabled = {}, shadows = nil, water = nil }
local function setQuality(level)
	pcall(function() settings().Rendering.QualityLevel = level end)
end
local function fpsBoost(on)
	local Terrain = Workspace:FindFirstChildOfClass("Terrain")
	if on then
		setQuality(Enum.QualityLevel.Level01)
		perf.shadows = Lighting.GlobalShadows
		pcall(function() Lighting.GlobalShadows = false end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke")
			   or v:IsA("Fire") or v:IsA("Sparkles") then
				if v.Enabled then v.Enabled = false; table.insert(perf.disabled, v) end
			end
		end
		if Terrain then
			perf.water = { Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.WaterTransparency }
			pcall(function()
				Terrain.WaterWaveSize, Terrain.WaterWaveSpeed = 0, 0
				Terrain.WaterReflectance, Terrain.WaterTransparency = 0, 0
			end)
		end
	else
		setQuality(Enum.QualityLevel.Automatic)
		if perf.shadows ~= nil then pcall(function() Lighting.GlobalShadows = perf.shadows end) end
		for _, v in ipairs(perf.disabled) do pcall(function() v.Enabled = true end) end
		perf.disabled = {}
		if Terrain and perf.water then
			pcall(function()
				Terrain.WaterWaveSize, Terrain.WaterWaveSpeed = perf.water[1], perf.water[2]
				Terrain.WaterReflectance, Terrain.WaterTransparency = perf.water[3], perf.water[4]
			end)
		end
	end
end

-- GPU saver: stop rendering the 3D scene entirely. UI stays up.
local function gpuSaver(on)
	pcall(function() RunSvc:Set3dRenderingEnabled(not on) end)
end

PerfBox:AddToggle("FPSBoost", {
	Text = "FPS Boost", Default = false,
	Tooltip = "Low quality, no shadows, no particles, flat water.",
	Callback = fpsBoost,
})
PerfBox:AddToggle("GPUSaver", {
	Text = "GPU Saver (disable 3D)", Default = false,
	Tooltip = "Stops rendering the 3D world. UI stays. Toggle off to see again.",
	Callback = gpuSaver,
})
PerfBox:AddToggle("AntiAfk", {
	Text = "Anti-AFK", Default = false,
	Tooltip = "Blocks the 20-minute idle kick.",
	Callback = function(v)
		antiAfk = v
		Library:Notify("Anti-AFK " .. (v and "ON" or "OFF"))
	end,
})

-- config + theme (Obsidian addons)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("AnimeDice")
SaveManager:SetFolder("AnimeDice")
SaveManager:BuildConfigSection(Tabs.Player) -- save / load / autoload
ThemeManager:ApplyToTab(Tabs.Player)        -- theme picker

-- ============================================================
-- cleanup
-- ============================================================
Library:OnUnload(function()
	running = false
	fastRoll, autoSpin, autoClaim, autoRebirth = false, false, false, false
	walkSpeedOn, infJump, noclip, instantPmt, antiAfk = false, false, false, false, false
	if flying then stopFly() end
	flying = false
	if autoSellOn then pcall(function() UpdateAutoSell:FireServer(false) end) end
	fpsBoost(false)
	gpuSaver(false)
end)

-- auto-execute: load autoload config last so saved toggles re-fire on inject.
SaveManager:LoadAutoloadConfig()

Library:Notify("Anime Dice loaded — RightShift to toggle UI")
