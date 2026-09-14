-- Full game-data export. Dumps every config table as JSON to
-- AnimeDice_gamedata.txt. This IS the encyclopedia — more accurate than
-- any fan wiki. Paste it back and nyx builds a clean reference + organizes
-- the potion/dice/unit lists.

local RS   = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local F    = RS.Framework.Features
local out  = {}

local function section(name, tbl)
	out[#out + 1] = "\n===== " .. name .. " ====="
	local ok, j = pcall(function() return Http:JSONEncode(tbl) end)
	out[#out + 1] = ok and j or ("<unencodable: " .. typeof(tbl) .. ">")
end
local function req(node) local ok, m = pcall(require, node); return ok and m or nil end
local function call(m, ...) local ok, r = pcall(function(...) return m(...) end, ...); return ok and r or nil end

local Boost = req(F.Inventory.Kinds.Boost.BoostConfig); if Boost then section("POTIONS", Boost.entries) end
local Spin  = req(F.Inventory.Kinds.Spin.SpinConfig);   if Spin then section("SPINS", Spin.entries) end
local Unit  = req(F.Inventory.Kinds.Unit.UnitConfig);   if Unit then section("UNITS", Unit.entries) end
local Boostk= req(F.Inventory.Kinds.Boost.BoostConfig)  -- categories live in entries

local Dice = req(F.Rolling.Dice)
if Dice then
	local all = call(Dice.GetAll) or (Dice.GetAll and Dice:GetAll())
	section("DICE", all)
end
local Up = req(F.Upgrades.Upgrades);   if Up then section("UPGRADES", Up) end
local Tr = req(F.Traits.Traits);       if Tr then section("TRAITS", Tr) end
local Gr = req(F.Grades.Grades);       if Gr then section("GRADES", Gr) end
local Mon= req(F.Monetization.MonetizationConfig); if Mon then section("CODES", Mon.Codes) end

local Tow = req(F.Towers.Towers)
if Tow then
	local all = call(Tow.GetAll) or (Tow.GetAll and Tow:GetAll())
	section("TOWERS", all)
end

local Reb = req(F.Rebirth.Rebirths)
if Reb then
	local list = {}
	pcall(function() for i = 1, 60 do local r = Reb.Get and Reb.Get(i); if r then list[i] = r end end end)
	section("REBIRTHS", list)
end

local text = table.concat(out, "\n")
if writefile then writefile("AnimeDice_gamedata.txt", text) end
print("[exportall] wrote AnimeDice_gamedata.txt — " .. #text .. " chars")
