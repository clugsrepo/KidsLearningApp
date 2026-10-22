--[[
	SKATE IT  -  Step 2: Skateboards, trick points and the skate shop
	Game designer: Ollie

	How to use:
	  In the Explorer, hover over ServerScriptService, click the +, pick "Script",
	  delete the line that's there and paste all of this in.
	  (If you already have this script, select everything in it and paste over the top.)

	What it does:
	  - Gives every player a skateboard under their feet
	  - Adds a "Points" score in the top corner
	  - Gives you points when you land a trick
	  - Runs the skate shop: spend points on better decks, trucks and wheels
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- How many points each trick is worth (before your deck bonus)
local TRICK_POINTS = {
	DarkFlip = 100,
}

----------------------------------------------------------------------
-- THE SHOP: change names, prices and colours here!
-- The first thing in each list is free and everyone starts with it.
----------------------------------------------------------------------

local SHOP = {
	-- Decks give you more points for tricks
	Deck = {
		{ Id = "Classic", Name = "Classic Deck", Price = 0, Info = "Normal trick points",
			Colour = Color3.fromRGB(130, 0, 255), Material = Enum.Material.Wood, Bonus = 1 },
		{ Id = "Flame", Name = "Flame Deck", Price = 500, Info = "1.5x trick points",
			Colour = Color3.fromRGB(255, 90, 0), Material = Enum.Material.Wood, Bonus = 1.5 },
		{ Id = "Galaxy", Name = "Galaxy Deck", Price = 2000, Info = "2x trick points",
			Colour = Color3.fromRGB(110, 0, 255), Material = Enum.Material.Neon, Bonus = 2 },
		{ Id = "Gold", Name = "Gold Deck", Price = 5000, Info = "3x trick points!",
			Colour = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Foil, Bonus = 3 },
	},
	-- Trucks make you jump higher
	Trucks = {
		{ Id = "Basic", Name = "Basic Trucks", Price = 0, Info = "Normal jumps",
			Colour = Color3.fromRGB(190, 190, 200), Material = Enum.Material.Metal, Jump = 7.2 },
		{ Id = "Pro", Name = "Pro Trucks", Price = 400, Info = "Jump higher",
			Colour = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal, Jump = 10 },
		{ Id = "Rocket", Name = "Rocket Trucks", Price = 1500, Info = "Jump SUPER high!",
			Colour = Color3.fromRGB(255, 40, 40), Material = Enum.Material.Neon, Jump = 14 },
	},
	-- Wheels make you faster
	Wheels = {
		{ Id = "Basic", Name = "Basic Wheels", Price = 0, Info = "Normal speed",
			Colour = Color3.fromRGB(255, 255, 255), Material = Enum.Material.SmoothPlastic, Speed = 32 },
		{ Id = "Speedy", Name = "Speedy Wheels", Price = 300, Info = "Go faster",
			Colour = Color3.fromRGB(0, 200, 255), Material = Enum.Material.SmoothPlastic, Speed = 40 },
		{ Id = "Turbo", Name = "Turbo Wheels", Price = 1200, Info = "Go really fast",
			Colour = Color3.fromRGB(0, 255, 100), Material = Enum.Material.SmoothPlastic, Speed = 50 },
		{ Id = "Lightning", Name = "Lightning Wheels", Price = 3000, Info = "Go LIGHTNING fast!",
			Colour = Color3.fromRGB(255, 255, 0), Material = Enum.Material.Neon, Speed = 62 },
	},
}

local BOARD_HEIGHT = 0.9 -- how much the board lifts you off the ground

----------------------------------------------------------------------
-- Messages between the game and each player's screen
----------------------------------------------------------------------

local function getOrMake(className, name)
	local thing = ReplicatedStorage:FindFirstChild(name) or Instance.new(className)
	thing.Name = name
	thing.Parent = ReplicatedStorage
	return thing
end

local trickEvent = getOrMake("RemoteEvent", "TrickDone")
local shopRequest = getOrMake("RemoteFunction", "ShopRequest")

-- Put the shop list where the shop screen can read it
local oldShopItems = ReplicatedStorage:FindFirstChild("ShopItems")
if oldShopItems then
	oldShopItems:Destroy()
end
local shopItems = Instance.new("Folder")
shopItems.Name = "ShopItems"
for category, items in pairs(SHOP) do
	local categoryFolder = Instance.new("Folder")
	categoryFolder.Name = category
	for order, item in ipairs(items) do
		local entry = Instance.new("Configuration")
		entry.Name = item.Id
		entry:SetAttribute("DisplayName", item.Name)
		entry:SetAttribute("Price", item.Price)
		entry:SetAttribute("Info", item.Info)
		entry:SetAttribute("Colour", item.Colour)
		entry:SetAttribute("Order", order)
		entry.Parent = categoryFolder
	end
	categoryFolder.Parent = shopItems
end
shopItems.Parent = ReplicatedStorage

local function findItem(category, id)
	for _, item in ipairs(SHOP[category] or {}) do
		if item.Id == id then
			return item
		end
	end
	return nil
end

-- What the player is using right now
local function equipped(player, category)
	return findItem(category, player:GetAttribute(category)) or SHOP[category][1]
end

----------------------------------------------------------------------
-- Building the skateboard
----------------------------------------------------------------------

local function makeBoardPart(character, name, size, item, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = item.Colour
	part.Material = item.Material
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

local function buildBoard(player, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local feetDrop = character:GetAttribute("FeetDrop")
	if not root or not feetDrop then
		return
	end

	-- Take off the old board
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and string.sub(part.Name, 1, 10) == "Skateboard" then
			part:Destroy()
		end
	end

	local deckItem = equipped(player, "Deck")
	local truckItem = equipped(player, "Trucks")
	local wheelItem = equipped(player, "Wheels")

	-- The deck
	local deck = makeBoardPart(character, "SkateboardDeck", Vector3.new(2, 0.25, 6), deckItem)
	stick(root, deck, CFrame.new(0, -feetDrop - 0.125, 0), "SkateboardWeld")

	-- Black grip tape on top
	local grip = makeBoardPart(character, "SkateboardGrip", Vector3.new(1.9, 0.05, 5.8),
		{ Colour = Color3.fromRGB(20, 20, 20), Material = Enum.Material.Sand })
	stick(deck, grip, CFrame.new(0, 0.15, 0))

	-- Trucks and wheels at the front and back
	for _, z in ipairs({ -2.2, 2.2 }) do
		local truck = makeBoardPart(character, "SkateboardTruck", Vector3.new(1.6, 0.2, 0.4), truckItem)
		stick(deck, truck, CFrame.new(0, -0.22, z))
		for _, x in ipairs({ -0.9, 0.9 }) do
			local wheel = makeBoardPart(character, "SkateboardWheel", Vector3.new(0.4, 0.6, 0.6),
				wheelItem, Enum.PartType.Cylinder)
			stick(deck, wheel, CFrame.new(x, -0.45, z))
		end
	end
end

-- Speed from your wheels, jump height from your trucks
local function applyStats(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = equipped(player, "Wheels").Speed
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = equipped(player, "Trucks").Jump
end

local function applyGear(player)
	if player.Character then
		buildBoard(player, player.Character)
	end
	applyStats(player)
end

local function onCharacter(player, character)
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
	character:SetAttribute("FeetDrop", feetDrop)

	-- Stand on top of the board
	humanoid.HipHeight += BOARD_HEIGHT

	applyGear(player)
	-- check again in a second, in case another script changed our speed
	task.delay(1, applyStats, player)
end

----------------------------------------------------------------------
-- Players joining
----------------------------------------------------------------------

local function setUpPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = 0
	points.Parent = leaderstats

	-- Everyone starts with the free gear
	for category, items in pairs(SHOP) do
		player:SetAttribute(category, items[1].Id)
		player:SetAttribute("Owns_" .. category .. "_" .. items[1].Id, true)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

Players.PlayerAdded:Connect(setUpPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setUpPlayer(player)
end

----------------------------------------------------------------------
-- Trick points
----------------------------------------------------------------------

local lastTrickTime = {}
trickEvent.OnServerEvent:Connect(function(player, trickName)
	local basePoints = TRICK_POINTS[trickName]
	if not basePoints then
		return
	end
	-- no spamming: one trick every half a second at most
	local now = os.clock()
	if lastTrickTime[player] and now - lastTrickTime[player] < 0.5 then
		return
	end
	lastTrickTime[player] = now

	local points = math.floor(basePoints * equipped(player, "Deck").Bonus)
	player.leaderstats.Points.Value += points
	trickEvent:FireClient(player, trickName, points)
end)

Players.PlayerRemoving:Connect(function(player)
	lastTrickTime[player] = nil
end)

----------------------------------------------------------------------
-- Buying and equipping in the shop
----------------------------------------------------------------------

shopRequest.OnServerInvoke = function(player, category, id)
	local item = typeof(category) == "string" and typeof(id) == "string" and findItem(category, id)
	if not item then
		return "Hmm, that didn't work. Try again!"
	end

	local ownsKey = "Owns_" .. category .. "_" .. id
	if not player:GetAttribute(ownsKey) then
		local points = player.leaderstats.Points
		if points.Value < item.Price then
			return "Not enough points! Do more tricks!"
		end
		points.Value -= item.Price
		player:SetAttribute(ownsKey, true)
		player:SetAttribute(category, id)
		applyGear(player)
		return "You bought the " .. item.Name .. "!"
	end

	player:SetAttribute(category, id)
	applyGear(player)
	return "Now using the " .. item.Name .. "!"
end
