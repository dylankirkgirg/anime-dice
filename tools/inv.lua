-- Anime Dice inventory + plot probe.
-- Finds where owned units live in the client data so nyx can wire
-- auto grade/trait/lock/sell + the Unit dropdowns. Writes AnimeDice_inv.txt.

local RS   = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local out  = {}
local function line(s) table.insert(out, s) end

local function enc(v)
	local ok, s = pcall(function() return Http:JSONEncode(v) end)
	return ok and s or ("<" .. typeof(v) .. ">")
end

-- 1) the generic data lib
local Client
pcall(function() Client = require(RS.Packages.Data.Client) end)

local data
if Client then
	pcall(function() data = Client.data end)
	if typeof(data) ~= "table" then pcall(function() data = Client:get() end) end
	if typeof(data) ~= "table" then pcall(function() data = Client.get() end) end
end

if typeof(data) == "table" then
	line("=== client data top-level keys ===")
	for k, v in pairs(data) do line(("%s : %s"):format(tostring(k), typeof(v))) end

	-- find the units/inventory subtable and sample it
	for _, key in ipairs({ "Units", "units", "Inventory", "inventory", "Entries", "entries", "Backpack" }) do
		local sub = data[key]
		if typeof(sub) == "table" then
			line("")
			line("=== sample of data." .. key .. " (first 3 entries) ===")
			local n = 0
			for uuid, info in pairs(sub) do
				n = n + 1
				line(("[%s] -> %s"):format(tostring(uuid), enc(info):sub(1, 400)))
				if n >= 3 then break end
			end
		end
	end
else
	line("could not read Client.data directly.")
	if Client then
		line("Client keys: ")
		for k, v in pairs(Client) do line(("  %s : %s"):format(tostring(k), typeof(v))) end
	end
end

-- 2) plot id (CollectBalance/LevelUpSlot take it)
local PC
pcall(function() PC = require(RS.Framework.Features.Plot.PlotController) end)
if PC then
	line("")
	line("=== PlotController ===")
	line("plot -> " .. enc(PC.plot):sub(1, 300))
end

-- 3) equipped units
local UC
pcall(function() UC = require(RS.Framework.Features.Inventory.Kinds.Unit.UnitController) end)
if UC and typeof(UC.EquippedUnit) == "function" then
	local ok, eq = pcall(function() return UC:EquippedUnit() end)
	if ok then line("EquippedUnit() -> " .. enc(eq):sub(1, 300)) end
end

local text = table.concat(out, "\n")
if writefile then writefile("AnimeDice_inv.txt", text) end
print(text)
print("[inv] done — AnimeDice_inv.txt")
