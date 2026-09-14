-- Confirms field names: potion duration (BoostConfig) + dice price (Dice).
-- Writes AnimeDice_probe2.txt. Lets nyx fix potionDuration()/dicePrice().

local RS   = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
local out  = {}
local function line(s) table.insert(out, s) end
local function enc(v) local ok, s = pcall(function() return Http:JSONEncode(v) end); return ok and s or ("<" .. typeof(v) .. ">") end

line("=== BoostConfig.entries sample (potion duration field?) ===")
pcall(function()
	local B = require(RS.Framework.Features.Inventory.Kinds.Boost.BoostConfig)
	local n = 0
	for k, v in pairs(B.entries or {}) do
		n = n + 1; line(tostring(k) .. " -> " .. enc(v):sub(1, 500))
		if n >= 3 then break end
	end
end)

line("")
line("=== Dice sample (price/tier field?) ===")
pcall(function()
	local D = require(RS.Framework.Features.Rolling.Dice)
	local all
	pcall(function() all = D.GetAll and D.GetAll() end)
	if type(all) ~= "table" then pcall(function() all = D:GetAll() end) end
	if type(all) == "table" then
		local n = 0
		for k, v in pairs(all) do n = n + 1; line(tostring(k) .. " -> " .. enc(v):sub(1, 500)); if n >= 4 then break end end
	end
	pcall(function() line("Dice.Get('Void') -> " .. enc(D.Get and D.Get("Void")):sub(1, 500)) end)
end)

local text = table.concat(out, "\n")
if writefile then writefile("AnimeDice_probe2.txt", text) end
print(text)
print("[probe2] done")
