-- Anime Dice arg spy — logs the EXACT args of every remote the game fires.
-- Run this, then do ONE of each action by hand (reroll a grade, reroll a
-- trait, start a tower, open/confirm a trade, equip a unit, lock a unit,
-- buy dice, use a potion...). Each fire is printed + appended to
-- AnimeDice_args.txt in your executor workspace. Paste that file back.

local RS  = game:GetService("ReplicatedStorage")
local net = RS:WaitForChild("Network")

-- pretty-print one value
local function repr(v, depth)
	depth = depth or 0
	local t = typeof(v)
	if t == "Instance" then
		return ("<%s:%s>"):format(v.ClassName, v:GetFullName())
	elseif t == "table" then
		if depth > 3 then return "{...}" end
		local parts = {}
		for k, val in pairs(v) do
			table.insert(parts, ("[%s]=%s"):format(tostring(k), repr(val, depth + 1)))
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	elseif t == "string" then
		return ('%q'):format(v)
	else
		return tostring(v)
	end
end

local function reprArgs(...)
	local n = select("#", ...)
	local parts = {}
	for i = 1, n do parts[i] = repr((select(i, ...))) end
	return table.concat(parts, ", ")
end

local log = {}
local function record(line)
	table.insert(log, line)
	print("[argspy] " .. line)
	if writefile then pcall(function() writefile("AnimeDice_args.txt", table.concat(log, "\n")) end) end
end

-- namecall hook catches FireServer / InvokeServer / Fire (Comm signals)
local ok = pcall(function()
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local m = getnamecallmethod()
		if (m == "FireServer" or m == "InvokeServer" or m == "Fire")
		   and typeof(self) == "Instance" and self:IsDescendantOf(net) then
			record(("%s :%s(%s)"):format(self:GetFullName(), m, reprArgs(...)))
		end
		return old(self, ...)
	end)
end)

if ok then
	record("=== argspy armed — do your actions now ===")
else
	warn("[argspy] hookmetamethod not available on this executor — tell nyx, we'll use another method")
end
