--[[
	SKATE IT  -  Step 3: Tricks!
	Game designer: Ollie

	How to use:
	  In the Explorer, open StarterPlayer, hover over StarterPlayerScripts, click the +,
	  pick "LocalScript", delete the line that's there and paste all of this in.

	Controls:
	  F (or the "Dark Flip" button on a tablet) = DARK FLIP!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local trickEvent = ReplicatedStorage:WaitForChild("TrickDone")
local doingTrick = false

----------------------------------------------------------------------
-- Big trick name that pops up on the screen
----------------------------------------------------------------------

local screen = Instance.new("ScreenGui")
screen.Name = "TrickText"
screen.ResetOnSpawn = false
screen.Parent = player:WaitForChild("PlayerGui")

local function showTrickText(text, colour)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0.12, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.35)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = colour
	label.TextStrokeTransparency = 0
	label.Parent = screen

	local floatUp = TweenService:Create(label, TweenInfo.new(1.2), {
		Position = UDim2.fromScale(0.5, 0.25),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	floatUp:Play()
	floatUp.Completed:Connect(function()
		label:Destroy()
	end)
end

----------------------------------------------------------------------
-- DARK FLIP: pop up, the board flips over and back, then lands
----------------------------------------------------------------------

local function darkFlip(_, inputState)
	if inputState ~= Enum.UserInputState.Begin or doingTrick then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local board = character and character:FindFirstChild("SkateboardDeck")
	local weld = board and board:FindFirstChild("SkateboardWeld")
	if not humanoid or not weld or humanoid.Health <= 0 then
		return
	end

	doingTrick = true

	-- Ollie up into the air if we're on the ground
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	local start = weld.C0
	local duration = 0.55
	local startTime = os.clock()
	while true do
		local progress = math.min((os.clock() - startTime) / duration, 1)
		local spin = progress * math.pi * 2 -- one whole flip
		local pop = math.sin(progress * math.pi) -- up and back down
		weld.C0 = start
			* CFrame.new(0, pop * 1.2, 0)
			* CFrame.Angles(pop * 0.35, 0, spin) -- nose tips up while the board flips
		if progress >= 1 then
			break
		end
		RunService.RenderStepped:Wait()
	end
	weld.C0 = start

	trickEvent:FireServer("DarkFlip")

	task.wait(0.15)
	doingTrick = false
end

-- The game tells us how many points we got (better decks give more!)
local TRICK_NAMES = {
	DarkFlip = { Text = "DARK FLIP!", Colour = Color3.fromRGB(170, 0, 255) },
}
trickEvent.OnClientEvent:Connect(function(trickName, points)
	local trick = TRICK_NAMES[trickName]
	if trick then
		showTrickText(trick.Text .. " +" .. points, trick.Colour)
	end
end)

ContextActionService:BindAction("DarkFlip", darkFlip, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("DarkFlip", "Dark Flip")
