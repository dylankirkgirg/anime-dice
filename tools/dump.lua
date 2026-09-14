-- Anime Dice dumper — remotes + data modules.
-- Writes AnimeDice_dump.txt to the executor workspace.
-- Our standard recon step: run in any Roblox game to map its remotes + data.

local RS = game:GetService("ReplicatedStorage")
local out = {}
local function line(s) table.insert(out, s) end

line("===== REMOTES (Network) =====")
local net = RS:FindFirstChild("Network")
if net then
	for _, svc in ipairs(net:GetChildren()) do
		for _, folder in ipairs(svc:GetChildren()) do
			for _, r in ipairs(folder:GetChildren()) do
				line(("%s.%s.%s  [%s]"):format(svc.Name, folder.Name, r.Name, r.ClassName))
			end
		end
	end
end

line("")
line("===== ReplicatedStorage children =====")
for _, c in ipairs(RS:GetChildren()) do
	line(("%s  [%s]"):format(c.Name, c.ClassName))
end

line("")
line("===== ModuleScript keys (data lists) =====")
for _, d in ipairs(RS:GetDescendants()) do
	if d:IsA("ModuleScript") then
		local ok, data = pcall(require, d)
		if ok and type(data) == "table" then
			local keys = {}
			for k in pairs(data) do table.insert(keys, tostring(k)) end
			table.sort(keys)
			line(("%s -> %s"):format(d:GetFullName(), table.concat(keys, ", "):sub(1, 500)))
		end
	end
end

local text = table.concat(out, "\n")
if writefile then
	writefile("AnimeDice_dump.txt", text)
	print("[dump] wrote AnimeDice_dump.txt — " .. #out .. " lines")
else
	print(text)
end
