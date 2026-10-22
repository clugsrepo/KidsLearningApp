--[[
	SKATE IT  -  Step 1: Build the city skatepark
	Game designer: Ollie

	How to use:
	  1. Open Roblox Studio and start a new "Baseplate" game.
	  2. In the Explorer, hover over ServerScriptService, click the +, and pick "Script".
	  3. Delete the line that is already in the script, then paste all of this in.
	  4. Press Play!

	What it builds:
	  - A city with tall buildings and graffiti walls
	  - Kicker ramps, grind rails, a funbox, ledges, stairs and a half-pipe
	  - A MEGA RAMP (stand on the green pad to get to the top)
	  - A ROCKET that teleports you to SPACE, where gravity is low
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- Remove any old copy of the map so we can rebuild it cleanly
local oldMap = workspace:FindFirstChild("SkateItMap")
if oldMap then
	oldMap:Destroy()
end

-- Remove the Baseplate's own spawn point (we make our own)
for _, thing in ipairs(workspace:GetChildren()) do
	if thing:IsA("SpawnLocation") then
		thing:Destroy()
	end
end

local map = Instance.new("Model")
map.Name = "SkateItMap"
map.Parent = workspace

local rng = Random.new(7)
local SPACE = Vector3.new(0, 1000, 0) -- where space is, high above the city
local SPACE_GRAVITY = 0.25 -- in space you only feel 25% of normal gravity

Lighting.ClockTime = 15

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

-- Makes a part with whatever settings we give it
local function makePart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "ClassName" and key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent or map
	return part
end

-- Puts a floating name sign above a part
local function addSign(part, text, colour)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 220, 0, 50)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 4, 0)
	gui.MaxDistance = 200
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = colour or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = part
end

-- Makes a pad that teleports players somewhere when they step on it
local cooldown = {}
local function makeTeleporter(pad, targetCFrame)
	pad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player or cooldown[player] then
			return
		end
		cooldown[player] = true
		character:PivotTo(targetCFrame)
		task.wait(1)
		cooldown[player] = nil
	end)
end

-- A grind rail between two points on the ground
local function makeRail(from, to, height)
	local up = Vector3.new(0, height, 0)
	makePart({
		Name = "Rail",
		Size = Vector3.new(0.6, 0.6, (to - from).Magnitude),
		CFrame = CFrame.lookAt((from + to) / 2 + up, to + up),
		Color = Color3.fromRGB(255, 200, 0),
		Material = Enum.Material.Metal,
	})
	for _, t in ipairs({ 0.05, 0.5, 0.95 }) do
		local spot = from:Lerp(to, t)
		makePart({
			Size = Vector3.new(0.4, height, 0.4),
			CFrame = CFrame.new(spot + up / 2),
			Color = Color3.fromRGB(60, 60, 60),
			Material = Enum.Material.Metal,
		})
	end
end

-- A curved quarter pipe. Two facing each other make a half-pipe.
local function makeQuarterPipe(origin, radius, width, colour)
	local segments = 10
	for i = 1, segments do
		local a1 = math.rad(90) * (i - 1) / segments
		local a2 = math.rad(90) * i / segments
		local mid = (a1 + a2) / 2
		local length = 2 * radius * math.sin((a2 - a1) / 2) + 0.3
		local spot = Vector3.new(0, radius - radius * math.cos(mid), radius * math.sin(mid))
		makePart({
			Name = "QuarterPipe",
			Size = Vector3.new(width, 1, length),
			CFrame = origin * CFrame.new(spot) * CFrame.Angles(-mid, 0, 0),
			Color = colour,
			Material = Enum.Material.Wood,
		})
	end
	-- the deck you stand on at the top
	makePart({
		Size = Vector3.new(width, radius + 0.5, 10),
		CFrame = origin * CFrame.new(0, (radius + 0.5) / 2, radius + 5),
		Color = Color3.fromRGB(90, 90, 95),
		Material = Enum.Material.Concrete,
	})
	-- the metal edge (coping)
	makePart({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(width, 1, 1),
		CFrame = origin * CFrame.new(0, radius + 0.5, radius),
		Color = Color3.fromRGB(200, 200, 210),
		Material = Enum.Material.Metal,
	})
end

-- A wall covered in colourful glowing graffiti stripes
local graffitiColours = {
	Color3.fromRGB(255, 0, 170),
	Color3.fromRGB(0, 230, 255),
	Color3.fromRGB(120, 255, 0),
	Color3.fromRGB(255, 140, 0),
	Color3.fromRGB(170, 0, 255),
	Color3.fromRGB(255, 255, 0),
}
local function makeGraffitiWall(cf)
	makePart({
		Name = "GraffitiWall",
		Size = Vector3.new(40, 12, 2),
		CFrame = cf * CFrame.new(0, 6, 0),
		Color = Color3.fromRGB(110, 100, 100),
		Material = Enum.Material.Brick,
	})
	for _, side in ipairs({ -1, 1 }) do
		for i = 1, #graffitiColours do
			makePart({
				Size = Vector3.new(rng:NextNumber(4, 12), rng:NextNumber(1, 3), 0.2),
				CFrame = cf
					* CFrame.new(rng:NextNumber(-14, 14), rng:NextNumber(2, 10), side * 1.1)
					* CFrame.Angles(0, 0, rng:NextNumber(-0.6, 0.6)),
				Color = graffitiColours[i],
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
		end
	end
end

-- A tall city building with glowing windows
local buildingColours = {
	Color3.fromRGB(120, 130, 150),
	Color3.fromRGB(160, 110, 90),
	Color3.fromRGB(80, 90, 110),
	Color3.fromRGB(190, 180, 160),
	Color3.fromRGB(70, 110, 120),
}
local function makeBuilding(x, z, sizeX, sizeZ)
	local height = rng:NextInteger(40, 110)
	makePart({
		Name = "Building",
		Size = Vector3.new(sizeX, height, sizeZ),
		CFrame = CFrame.new(x, 1 + height / 2, z),
		Color = buildingColours[rng:NextInteger(1, #buildingColours)],
		Material = Enum.Material.Concrete,
	})
	for y = 8, height - 6, 10 do
		makePart({
			Size = Vector3.new(sizeX + 0.2, 2, sizeZ + 0.2),
			CFrame = CFrame.new(x, 1 + y, z),
			Color = Color3.fromRGB(255, 230, 150),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
end

----------------------------------------------------------------------
-- THE CITY
----------------------------------------------------------------------

-- Ground (top of it is at height 1)
makePart({
	Name = "Ground",
	Size = Vector3.new(400, 1, 400),
	CFrame = CFrame.new(0, 0.5, 0),
	Color = Color3.fromRGB(150, 150, 150),
	Material = Enum.Material.Concrete,
})

-- Buildings all the way round the edge
for x = -180, 180, 40 do
	makeBuilding(x, 190, 34, 20)
	makeBuilding(x, -190, 34, 20)
end
for z = -140, 140, 40 do
	makeBuilding(190, z, 20, 34)
	makeBuilding(-190, z, 20, 34)
end

-- Spawn point with the game's name above it
local spawn = makePart({
	ClassName = "SpawnLocation",
	Name = "CitySpawn",
	Size = Vector3.new(12, 1, 12),
	CFrame = CFrame.new(0, 1.5, -150),
	Color = Color3.fromRGB(255, 0, 170),
	Material = Enum.Material.Neon,
})
spawn.Neutral = true
spawn.Duration = 0
addSign(spawn, "SKATE IT", Color3.fromRGB(255, 255, 0))

-- Graffiti walls
makeGraffitiWall(CFrame.new(-60, 1, -40) * CFrame.Angles(0, math.rad(90), 0))
makeGraffitiWall(CFrame.new(-60, 1, 40) * CFrame.Angles(0, math.rad(90), 0))
makeGraffitiWall(CFrame.new(0, 1, -172))

-- Kicker ramps
makePart({ ClassName = "WedgePart", Name = "Kicker", Size = Vector3.new(12, 4, 10),
	CFrame = CFrame.new(-25, 3, -80), Color = Color3.fromRGB(0, 170, 255), Material = Enum.Material.Wood })
makePart({ ClassName = "WedgePart", Name = "Kicker", Size = Vector3.new(12, 4, 10),
	CFrame = CFrame.new(25, 3, -80), Color = Color3.fromRGB(255, 80, 80), Material = Enum.Material.Wood })

-- Grind rails
makeRail(Vector3.new(0, 1, -45), Vector3.new(0, 1, -15), 2.5)
makeRail(Vector3.new(30, 1, -45), Vector3.new(30, 1, -15), 2.5)

-- Funbox: a box with a ramp on each side and a rail on top
makePart({ Name = "Funbox", Size = Vector3.new(16, 3, 16), CFrame = CFrame.new(0, 2.5, 30),
	Color = Color3.fromRGB(100, 100, 105), Material = Enum.Material.Concrete })
makePart({ ClassName = "WedgePart", Size = Vector3.new(16, 3, 10), CFrame = CFrame.new(0, 2.5, 17),
	Color = Color3.fromRGB(100, 100, 105), Material = Enum.Material.Concrete })
makePart({ ClassName = "WedgePart", Size = Vector3.new(16, 3, 10),
	CFrame = CFrame.new(0, 2.5, 43) * CFrame.Angles(0, math.pi, 0),
	Color = Color3.fromRGB(100, 100, 105), Material = Enum.Material.Concrete })
makePart({ Name = "Rail", Size = Vector3.new(0.6, 0.6, 16), CFrame = CFrame.new(0, 4.8, 30),
	Color = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Metal })

-- Ledges
makePart({ Name = "Ledge", Size = Vector3.new(4, 2, 24), CFrame = CFrame.new(-30, 2, 25),
	Color = Color3.fromRGB(180, 180, 175), Material = Enum.Material.Marble })
makePart({ Name = "Ledge", Size = Vector3.new(4, 2, 24), CFrame = CFrame.new(30, 2, 25),
	Color = Color3.fromRGB(180, 180, 175), Material = Enum.Material.Marble })

-- Stairs up to a plaza, with a handrail to grind down
for step = 1, 5 do
	makePart({
		Name = "Step",
		Size = Vector3.new(20, step, 3),
		CFrame = CFrame.new(0, 1 + step / 2, 60 + (step - 1) * 3 + 1.5),
		Color = Color3.fromRGB(170, 170, 170),
		Material = Enum.Material.Concrete,
	})
end
makePart({ Name = "Plaza", Size = Vector3.new(40, 5, 30), CFrame = CFrame.new(0, 3.5, 90),
	Color = Color3.fromRGB(170, 170, 170), Material = Enum.Material.Concrete })
makeRail(Vector3.new(12, 2, 61), Vector3.new(12, 6, 75), 2.5)

-- Half-pipe (two quarter pipes facing each other)
makeQuarterPipe(CFrame.new(80, 1, 15), 12, 30, Color3.fromRGB(200, 150, 90))
makeQuarterPipe(CFrame.new(80, 1, -15) * CFrame.Angles(0, math.pi, 0), 12, 30, Color3.fromRGB(200, 150, 90))

----------------------------------------------------------------------
-- THE MEGA RAMP
----------------------------------------------------------------------

local megaColour = Color3.fromRGB(255, 120, 0)

-- Tall tower you start from (top is at height 61)
local tower = makePart({ Name = "MegaTower", Size = Vector3.new(24, 60, 20), CFrame = CFrame.new(-120, 31, 160),
	Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.DiamondPlate })
addSign(tower, "MEGA RAMP", megaColour)
for _, side in ipairs({ -1, 1 }) do
	makePart({ Size = Vector3.new(1, 4, 20), CFrame = CFrame.new(-120 + side * 12.5, 63, 160),
		Color = megaColour, Material = Enum.Material.Metal })
end

-- Huge slope down
makePart({ ClassName = "WedgePart", Name = "MegaRollIn", Size = Vector3.new(24, 60, 120),
	CFrame = CFrame.new(-120, 31, 90), Color = megaColour, Material = Enum.Material.Wood })

-- Jump at the bottom...
makePart({ ClassName = "WedgePart", Name = "MegaKicker", Size = Vector3.new(24, 6, 14),
	CFrame = CFrame.new(-120, 4, 3) * CFrame.Angles(0, math.pi, 0), Color = megaColour, Material = Enum.Material.Wood })

-- ...over a big gap onto the landing
makePart({ ClassName = "WedgePart", Name = "MegaLanding", Size = Vector3.new(24, 6, 30),
	CFrame = CFrame.new(-120, 4, -49), Color = megaColour, Material = Enum.Material.Wood })

-- Green pad that takes you to the top of the mega ramp
local megaPad = makePart({ Name = "MegaPad", Size = Vector3.new(8, 0.4, 8), CFrame = CFrame.new(-95, 1.2, 140),
	Color = Color3.fromRGB(0, 255, 100), Material = Enum.Material.Neon })
addSign(megaPad, "TO THE TOP!", Color3.fromRGB(0, 255, 100))
makeTeleporter(megaPad, CFrame.lookAt(Vector3.new(-120, 65, 163), Vector3.new(-120, 65, 100)))

----------------------------------------------------------------------
-- THE ROCKET
----------------------------------------------------------------------

local ROCKET = Vector3.new(120, 1, 140)
local upright = CFrame.Angles(0, 0, math.rad(90)) -- turns cylinders to stand up

-- Launch pad
makePart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 30, 30),
	CFrame = CFrame.new(ROCKET + Vector3.new(0, 1, 0)) * upright,
	Color = Color3.fromRGB(70, 70, 75), Material = Enum.Material.DiamondPlate })

local base = ROCKET.Y + 2 -- top of the launch pad

-- Body, stripe and nose
makePart({ Name = "Rocket", Shape = Enum.PartType.Cylinder, Size = Vector3.new(40, 12, 12),
	CFrame = CFrame.new(ROCKET.X, base + 20, ROCKET.Z) * upright,
	Color = Color3.fromRGB(240, 240, 245), Material = Enum.Material.Metal })
makePart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 12.3, 12.3),
	CFrame = CFrame.new(ROCKET.X, base + 30, ROCKET.Z) * upright,
	Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.Metal })
makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(12, 12, 12),
	CFrame = CFrame.new(ROCKET.X, base + 40, ROCKET.Z), Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.Metal })
makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(6, 6, 6),
	CFrame = CFrame.new(ROCKET.X, base + 46, ROCKET.Z), Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.Metal })

-- Fins
for i = 0, 3 do
	local angle = i * math.pi / 2 + math.pi / 4
	local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local spot = Vector3.new(ROCKET.X, base + 6, ROCKET.Z) + outward * 10
	makePart({ ClassName = "WedgePart", Size = Vector3.new(1, 12, 8),
		CFrame = CFrame.lookAt(spot, spot + outward), Color = Color3.fromRGB(220, 30, 30), Material = Enum.Material.Metal })
end

-- Glowing door: walk into it to blast off to space!
local rocketDoor = makePart({ Name = "RocketDoor", Size = Vector3.new(6, 9, 0.6),
	CFrame = CFrame.new(ROCKET.X, base + 4.5, ROCKET.Z - 6.2), Color = Color3.fromRGB(0, 200, 255), Material = Enum.Material.Neon })
addSign(rocketDoor, "ROCKET TO SPACE", Color3.fromRGB(0, 200, 255))
makeTeleporter(rocketDoor, CFrame.lookAt(SPACE + Vector3.new(0, 6, -10), SPACE + Vector3.new(0, 6, 10)))

----------------------------------------------------------------------
-- SPACE
----------------------------------------------------------------------

-- Main floating platform
makePart({ Name = "SpacePlatform", Size = Vector3.new(100, 2, 100), CFrame = CFrame.new(SPACE),
	Color = Color3.fromRGB(40, 20, 70), Material = Enum.Material.SmoothPlastic })
for _, edge in ipairs({
	{ Vector3.new(0, 1.1, 50), Vector3.new(100, 0.4, 1) },
	{ Vector3.new(0, 1.1, -50), Vector3.new(100, 0.4, 1) },
	{ Vector3.new(50, 1.1, 0), Vector3.new(1, 0.4, 100) },
	{ Vector3.new(-50, 1.1, 0), Vector3.new(1, 0.4, 100) },
}) do
	makePart({ Size = edge[2], CFrame = CFrame.new(SPACE + edge[1]),
		Color = Color3.fromRGB(0, 255, 255), Material = Enum.Material.Neon })
end

-- Space kickers (huge jumps in low gravity!)
makePart({ ClassName = "WedgePart", Size = Vector3.new(12, 4, 10), CFrame = CFrame.new(SPACE + Vector3.new(-25, 3, 0)),
	Color = Color3.fromRGB(255, 0, 200), Material = Enum.Material.Neon })
makePart({ ClassName = "WedgePart", Size = Vector3.new(12, 4, 10), CFrame = CFrame.new(SPACE + Vector3.new(25, 3, 0)),
	Color = Color3.fromRGB(255, 0, 200), Material = Enum.Material.Neon })

-- Floating platforms to jump between
local platformColours = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 255, 120), Color3.fromRGB(80, 160, 255), Color3.fromRGB(255, 220, 60) }
for i = 1, 8 do
	local angle = i / 8 * math.pi * 2
	makePart({ Name = "FloatingPlatform", Size = Vector3.new(18, 2, 18),
		CFrame = CFrame.new(SPACE + Vector3.new(math.cos(angle) * 75, (i % 3) * 8, math.sin(angle) * 75)),
		Color = platformColours[(i % #platformColours) + 1], Material = Enum.Material.SmoothPlastic })
end

-- A big planet with a ring
local planetSpot = SPACE + Vector3.new(250, 80, 250)
makePart({ Name = "Planet", Shape = Enum.PartType.Ball, Size = Vector3.new(120, 120, 120), CFrame = CFrame.new(planetSpot),
	Color = Color3.fromRGB(255, 150, 60), Material = Enum.Material.Sand, CanCollide = false })
makePart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 220, 220),
	CFrame = CFrame.new(planetSpot) * CFrame.Angles(0, 0, math.rad(70)),
	Color = Color3.fromRGB(255, 220, 160), Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false })

-- Stars
for _ = 1, 80 do
	local direction = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1)).Unit
	local size = rng:NextNumber(1, 3)
	makePart({ Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size),
		CFrame = CFrame.new(SPACE + direction * rng:NextNumber(300, 500)),
		Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
end

-- Orange pad that takes you back down to the city
local returnPad = makePart({ Name = "ReturnPad", Size = Vector3.new(10, 0.4, 10), CFrame = CFrame.new(SPACE + Vector3.new(0, 1.2, 35)),
	Color = Color3.fromRGB(255, 140, 0), Material = Enum.Material.Neon })
addSign(returnPad, "BACK TO CITY", Color3.fromRGB(255, 140, 0))
makeTeleporter(returnPad, CFrame.lookAt(Vector3.new(120, 6, 118), Vector3.new(120, 6, 100)))

----------------------------------------------------------------------
-- PLAYERS: skater speed, and low gravity in space
----------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 32 -- fast, like a skater (until we add the skateboard!)
	end)
end)

-- Every half a second, make anyone up in space float
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local float = root:FindFirstChild("SpaceFloat")
				if root.Position.Y > SPACE.Y - 200 then
					if not float then
						local attachment = Instance.new("Attachment")
						attachment.Name = "SpaceFloatAttachment"
						attachment.Parent = root
						float = Instance.new("VectorForce")
						float.Name = "SpaceFloat"
						float.Attachment0 = attachment
						float.RelativeTo = Enum.ActuatorRelativeTo.World
						float.ApplyAtCenterOfMass = true
						float.Parent = root
					end
					-- push up against most of gravity so it feels like the moon
					float.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * (1 - SPACE_GRAVITY), 0)
				elseif float then
					float:Destroy()
					local attachment = root:FindFirstChild("SpaceFloatAttachment")
					if attachment then
						attachment:Destroy()
					end
				end
			end
		end
		task.wait(0.5)
	end
end)

print("Skate It skatepark built!")
