--[[
	SKATE IT  -  Step 2: Skateboards and trick points
	Game designer: Ollie

	How to use:
	  In the Explorer, hover over ServerScriptService, click the +, pick "Script",
	  delete the line that's there and paste all of this in.

	What it does:
	  - Gives every player a skateboard under their feet
	  - Adds a "Points" score in the top corner
	  - Gives you points when you land a trick
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- How many points each trick is worth
local TRICK_POINTS = {
	DarkFlip = 100,
}

-- The tricks script uses this to tell us when someone does a trick
local trickEvent = ReplicatedStorage:FindFirstChild("TrickDone") or Instance.new("RemoteEvent")
trickEvent.Name = "TrickDone"
trickEvent.Parent = ReplicatedStorage

local BOARD_HEIGHT = 0.9 -- how much the board lifts you off the ground

----------------------------------------------------------------------
-- Building the skateboard
----------------------------------------------------------------------

local function makeBoardPart(character, name, size, colour, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = colour
	part.Material = material
	if shape then
		part.Shape = shape
	end
	part.CanCollide = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = character
	return part
end

local function stick(part0, part1, offset, name)
	local weld = Instance.new("Weld")
	weld.Name = name or "Weld"
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = offset
	weld.Parent = part1
	return weld
end

local function giveSkateboard(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	local root = character:WaitForChild("HumanoidRootPart")

	-- Wait for the avatar to finish loading so the board lines up with the feet
	if not player:HasAppearanceLoaded() then
		player.CharacterAppearanceLoaded:Wait()
	end
	if player.Character ~= character then
		return
	end

	-- How far down from the middle of the body the feet are
	local feetDrop
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		feetDrop = root.Size.Y / 2 + humanoid.HipHeight
	else
		feetDrop = root.Size.Y / 2 + 2
	end

	-- Stand on top of the board
	humanoid.HipHeight += BOARD_HEIGHT

	-- The deck
	local deck = makeBoardPart(character, "SkateboardDeck", Vector3.new(2, 0.25, 6),
		Color3.fromRGB(130, 0, 255), Enum.Material.Wood)
	stick(root, deck, CFrame.new(0, -feetDrop - 0.125, 0), "SkateboardWeld")

	-- Black grip tape on top
	local grip = makeBoardPart(character, "SkateboardGrip", Vector3.new(1.9, 0.05, 5.8),
		Color3.fromRGB(20, 20, 20), Enum.Material.Sand)
	stick(deck, grip, CFrame.new(0, 0.15, 0))

	-- Trucks and wheels at the front and back
	for _, z in ipairs({ -2.2, 2.2 }) do
		local truck = makeBoardPart(character, "SkateboardTruck", Vector3.new(1.6, 0.2, 0.4),
			Color3.fromRGB(190, 190, 200), Enum.Material.Metal)
		stick(deck, truck, CFrame.new(0, -0.22, z))
		for _, x in ipairs({ -0.9, 0.9 }) do
			local wheel = makeBoardPart(character, "SkateboardWheel", Vector3.new(0.4, 0.6, 0.6),
				Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			stick(deck, wheel, CFrame.new(x, -0.45, z))
		end
	end
end

----------------------------------------------------------------------
-- Points
----------------------------------------------------------------------

local function setUpPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = 0
	points.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		giveSkateboard(player, character)
	end)
	if player.Character then
		task.spawn(giveSkateboard, player, player.Character)
	end
end

Players.PlayerAdded:Connect(setUpPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setUpPlayer(player)
end

local lastTrickTime = {}
trickEvent.OnServerEvent:Connect(function(player, trickName)
	local points = TRICK_POINTS[trickName]
	if not points then
		return
	end
	-- no spamming: one trick every half a second at most
	local now = os.clock()
	if lastTrickTime[player] and now - lastTrickTime[player] < 0.5 then
		return
	end
	lastTrickTime[player] = now
	player.leaderstats.Points.Value += points
end)

Players.PlayerRemoving:Connect(function(player)
	lastTrickTime[player] = nil
end)
