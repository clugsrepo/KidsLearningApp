--[[
	SKATE IT  -  Step 4: The skate shop screen
	Game designer: Ollie

	How to use:
	  In the Explorer, open StarterPlayer, hover over StarterPlayerScripts, click the +,
	  pick "LocalScript", delete the line that's there and paste all of this in.

	Click the SHOP button on the left of the screen to buy decks, trucks and wheels.
	(The things for sale, and their prices, are in the Skateboard script.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local shopItems = ReplicatedStorage:WaitForChild("ShopItems")
local shopRequest = ReplicatedStorage:WaitForChild("ShopRequest")
local points = player:WaitForChild("leaderstats"):WaitForChild("Points")

local CATEGORIES = {
	{ Key = "Deck", Label = "Decks" },
	{ Key = "Trucks", Label = "Trucks" },
	{ Key = "Wheels", Label = "Wheels" },
}
local currentCategory = "Deck"

----------------------------------------------------------------------
-- Helpers for making the screen
----------------------------------------------------------------------

local function new(className, props, parent)
	local thing = Instance.new(className)
	for key, value in pairs(props) do
		thing[key] = value
	end
	thing.Parent = parent
	return thing
end

local function round(guiObject, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, guiObject)
end

local function text(className, props, parent)
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	if className == "TextLabel" then
		props.BackgroundTransparency = 1
	end
	return new(className, props, parent)
end

----------------------------------------------------------------------
-- The screen
----------------------------------------------------------------------

local screen = new("ScreenGui", { Name = "SkateShop", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local openButton = text("TextButton", {
	Text = "SHOP",
	Size = UDim2.new(0, 110, 0, 50),
	Position = UDim2.new(0, 12, 0.5, -25),
	BackgroundColor3 = Color3.fromRGB(255, 170, 0),
}, screen)
round(openButton)

local panel = new("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.75, 0.8),
	BackgroundColor3 = Color3.fromRGB(25, 25, 40),
}, screen)
round(panel, 16)
new("UISizeConstraint", { MaxSize = Vector2.new(620, 460) }, panel)

text("TextLabel", {
	Text = "SKATE SHOP",
	Position = UDim2.new(0, 16, 0, 10),
	Size = UDim2.new(0.45, 0, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 200, 0),
}, panel)

local pointsLabel = text("TextLabel", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -66, 0, 14),
	Size = UDim2.new(0.4, 0, 0, 32),
	TextXAlignment = Enum.TextXAlignment.Right,
}, panel)

local closeButton = text("TextButton", {
	Text = "X",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 10),
	Size = UDim2.new(0, 44, 0, 40),
	BackgroundColor3 = Color3.fromRGB(220, 50, 50),
}, panel)
round(closeButton)

local tabs = new("Frame", {
	Position = UDim2.new(0, 16, 0, 60),
	Size = UDim2.new(1, -32, 0, 40),
	BackgroundTransparency = 1,
}, panel)
new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabs)

local list = new("ScrollingFrame", {
	Position = UDim2.new(0, 16, 0, 110),
	Size = UDim2.new(1, -32, 1, -160),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 8,
}, panel)

local messageLabel = text("TextLabel", {
	Text = "",
	Position = UDim2.new(0, 16, 1, -44),
	Size = UDim2.new(1, -32, 0, 32),
	TextColor3 = Color3.fromRGB(120, 255, 120),
}, panel)

----------------------------------------------------------------------
-- Filling in the shop
----------------------------------------------------------------------

local messageNumber = 0
local function showMessage(message)
	messageNumber += 1
	local myNumber = messageNumber
	messageLabel.Text = message
	task.delay(3, function()
		if messageNumber == myNumber then
			messageLabel.Text = ""
		end
	end)
end

local busy = false
local tabButtons = {}
local refresh -- (defined below)

local function makeRow(category, entry)
	local id = entry.Name
	local price = entry:GetAttribute("Price")
	local owned = player:GetAttribute("Owns_" .. category .. "_" .. id)
	local isEquipped = player:GetAttribute(category) == id

	local row = new("Frame", {
		Size = UDim2.new(1, -12, 0, 64),
		LayoutOrder = entry:GetAttribute("Order"),
		BackgroundColor3 = Color3.fromRGB(45, 45, 65),
	}, list)
	round(row)

	local swatch = new("Frame", {
		Position = UDim2.new(0, 10, 0.5, -22),
		Size = UDim2.new(0, 44, 0, 44),
		BackgroundColor3 = entry:GetAttribute("Colour"),
	}, row)
	round(swatch, 8)

	text("TextLabel", {
		Text = entry:GetAttribute("DisplayName"),
		Position = UDim2.new(0, 64, 0, 6),
		Size = UDim2.new(1, -214, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	text("TextLabel", {
		Text = entry:GetAttribute("Info"),
		Font = Enum.Font.Gotham,
		Position = UDim2.new(0, 64, 0, 34),
		Size = UDim2.new(1, -214, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(190, 190, 210),
	}, row)

	local button = text("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 130, 0, 44),
	}, row)
	round(button, 8)

	if isEquipped then
		button.Text = "USING"
		button.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		button.AutoButtonColor = false
	elseif owned then
		button.Text = "USE"
		button.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
	else
		button.Text = "BUY " .. price
		if points.Value >= price then
			button.BackgroundColor3 = Color3.fromRGB(0, 190, 80)
		else
			button.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
		end
	end

	button.Activated:Connect(function()
		if isEquipped or busy then
			return
		end
		busy = true
		local ok, message = pcall(function()
			return shopRequest:InvokeServer(category, id)
		end)
		busy = false
		showMessage(ok and message or "Hmm, that didn't work. Try again!")
		refresh()
	end)
end

function refresh()
	pointsLabel.Text = "Points: " .. points.Value

	for key, button in pairs(tabButtons) do
		if key == currentCategory then
			button.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		else
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
		end
	end

	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if not list:FindFirstChildOfClass("UIListLayout") then
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	end

	local categoryFolder = shopItems:FindFirstChild(currentCategory)
	if categoryFolder then
		for _, entry in ipairs(categoryFolder:GetChildren()) do
			makeRow(currentCategory, entry)
		end
	end
end

for order, category in ipairs(CATEGORIES) do
	local tab = text("TextButton", {
		Text = category.Label,
		LayoutOrder = order,
		Size = UDim2.new(1 / #CATEGORIES, -6, 1, 0),
	}, tabs)
	round(tab, 8)
	tabButtons[category.Key] = tab
	tab.Activated:Connect(function()
		currentCategory = category.Key
		refresh()
	end)
end

----------------------------------------------------------------------
-- Opening, closing and keeping it up to date
----------------------------------------------------------------------

openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		refresh()
	end
end)

closeButton.Activated:Connect(function()
	panel.Visible = false
end)

points.Changed:Connect(function()
	if panel.Visible then
		refresh()
	end
end)

player.AttributeChanged:Connect(function()
	if panel.Visible then
		refresh()
	end
end)
