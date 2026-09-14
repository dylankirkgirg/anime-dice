-- Anime Dice values dumper — pulls the real dropdown lists.
-- Writes AnimeDice_values.txt to the executor workspace. Paste it back.

local RS = game:GetService("ReplicatedStorage")
local F  = RS:WaitForChild("Framework"):WaitForChild("Features")
local Other = RS.Framework:FindFirstChild("Other")

local out = {}
local function line(s) table.insert(out, s) end

local function keysOf(tbl)
	local ks = {}
	for k, v in pairs(tbl) do
		ks[#ks + 1] = (type(k) == "number") and tostring(v) or tostring(k)
	end
	table.sort(ks)
	return table.concat(ks, ", ")
end

-- require by walking a dotted path under Framework
local function reqPath(...)
	local node = RS.Framework
	for _, seg in ipairs({ ... }) do
		node = node and node:FindFirstChild(seg)
	end
	if not node then return nil end
	local ok, m = pcall(require, node)
	return ok and m or nil
end

local function dump(label, tbl)
	if type(tbl) ~= "table" then line(label .. " -> (nil/none)"); return end
	line(label .. " -> " .. keysOf(tbl))
end

-- static config tables (key list = the values)
dump("Grades",    reqPath("Features", "Grades", "Grades"))
dump("Traits",    reqPath("Features", "Traits", "Traits"))
dump("Upgrades",  reqPath("Features", "Upgrades", "Upgrades"))
dump("Mutations", reqPath("Features", "Inventory", "Kinds", "Unit", "Mutations"))
dump("Variants",  reqPath("Features", "Inventory", "Kinds", "Unit", "Variants"))

-- config modules with an `entries` table
local function entries(label, m)
	if m and type(m) == "table" and type(m.entries) == "table" then
		dump(label, m.entries)
	else
		dump(label, m)
	end
end
entries("Units",   reqPath("Features", "Inventory", "Kinds", "Unit", "UnitConfig"))
entries("Boosts",  reqPath("Features", "Inventory", "Kinds", "Boost", "BoostConfig"))
entries("Spins",   reqPath("Features", "Inventory", "Kinds", "Spin", "SpinConfig"))
entries("Tokens",  reqPath("Features", "Inventory", "Kinds", "Token", "TokenConfig"))

-- modules exposing GetAll()/Get()
local function getAll(label, m)
	if not m then dump(label, nil); return end
	local ok, res = pcall(function() return m.GetAll and m:GetAll() or (m.Get and m.Get()) end)
	if ok and type(res) == "table" then dump(label, res) else dump(label, m) end
end
getAll("Dice",     reqPath("Features", "Rolling", "Dice"))
getAll("Towers",   reqPath("Features", "Towers", "Towers"))

-- rarities (RS.Framework.Other.Rarities -> Refs)
if Other then
	local rar = reqPath("Other", "Rarities")
	if rar then dump("Rarities", rar.Refs or rar) end
end

-- monetization codes
local mon = reqPath("Features", "Monetization", "MonetizationConfig")
if mon then dump("Codes", mon.Codes) end

local text = table.concat(out, "\n")
if writefile then
	writefile("AnimeDice_values.txt", text)
	print("[values] wrote AnimeDice_values.txt — " .. #out .. " lines")
else
	print(text)
end
