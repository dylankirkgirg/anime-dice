-- Anime Dice loader.
-- This is the file your loadstring points at. It just pulls the latest
-- src/main.lua from your repo, so you can update the script without
-- ever re-pasting the loadstring in your executor.
--
-- SETUP: change GITHUB_USER below to your GitHub username.

local GITHUB_USER = "YOUR_GITHUB_USERNAME"
local REPO        = "anime-dice"
local BRANCH      = "main"

local url = ("https://raw.githubusercontent.com/%s/%s/%s/src/main.lua")
	:format(GITHUB_USER, REPO, BRANCH)

loadstring(game:HttpGet(url))()
