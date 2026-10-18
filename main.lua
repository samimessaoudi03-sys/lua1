-- DIENSTEN
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- VARIABELEN
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Vliegen variabelen
local flying = false
local flySpeed = 50
local bodyGyro, bodyVelocity
local keysDown = {}

-- ESP variabelen
local espActive = false
local highlightStorage = {}

-- UI AANMAKEN
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UtilityGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Knop om ESP aan/uit te zetten
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 150, 0, 40)
espButton.Position = UDim2.new(0.02, 0, 0.78, 0)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.TextSize = 18
espButton.Text = "ESP: OFF"
espButton.Parent = screenGui

-- Knop/Indicator voor Vliegen
local flyIndicator = Instance.new("TextLabel")
flyIndicator.Size = UDim2.new(0, 150, 0, 40)
flyIndicator.Position = UDim2.new(0.02, 0, 0.71, 0)
flyIndicator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
flyIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
flyIndicator.TextSize = 14
flyIndicator.Text = "Fly: OFF [Druk F]"
flyIndicator.Parent = screenGui


-- ==========================================
-- 1. VLIEGEN LOGICA (F-TOETS)
-- ==========================================

local function startFlying()
	local character = localPlayer.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end

	flying = true
	flyIndicator.Text = "Fly: ON [Druk F]"
	flyIndicator.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	
	humanoid.PlatformStand = true -- Zorgt dat de speler niet valt of loopt

	-- Krachten aanmaken om in de lucht te zweven/bewegen
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.P = 9e4
	bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	bodyGyro.cframe = rootPart.CFrame
	bodyGyro.Parent = rootPart

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
	bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Parent = rootPart

	-- Loop om de beweging soepel te berekenen op basis van de camerarichting
	task.spawn(function()
		while flying and rootPart and humanoid do
			local moveDirection = Vector3.new(0, 0, 0)
			
			if keysDown[Enum.KeyCode.W] then moveDirection = moveDirection + camera.CFrame.LookVector end
			if keysDown[Enum.KeyCode.S] then moveDirection = moveDirection - camera.CFrame.LookVector end
			if keysDown[Enum.KeyCode.A] then moveDirection = moveDirection - camera.CFrame.RightVector end
			if keysDown[Enum.KeyCode.D] then moveDirection = moveDirection + camera.CFrame.RightVector end
			if keysDown[Enum.KeyCode.Space] then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
			if keysDown[Enum.KeyCode.LeftShift] then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

			bodyVelocity.velocity = moveDirection.Magnitude > 0 and moveDirection.Unit * flySpeed or Vector3.new(0, 0, 0)
			bodyGyro.cframe = camera.CFrame
			RunService.RenderStepped:Wait()
		end
	end)
end

local function stopFlying()
	flying = false
	flyIndicator.Text = "Fly: OFF [Druk F]"
	flyIndicator.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end

	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then humanoid.PlatformStand = false end
	end
end

-- Toetsenbord input registreren
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Negeer als je in de chat typt

	if input.KeyCode == Enum.KeyCode.F then
		if flying then stopFlying() else startFlying() end
	end

	-- Houd bij welke bewegingstoetsen zijn ingedrukt
	keysDown[input.KeyCode] = true
end)

UserInputService.InputEnded:Connect(function(input)
	keysDown[input.KeyCode] = nil
end)


-- ==========================================
-- 2. ESP LOGICA (HIGHLIGHTS DOOR MUREN)
-- ==========================================

local function createESP(player)
	if player == localPlayer then return end

	local function applyHighlight(character)
		if not espActive then return end
		if highlightStorage[player] then highlightStorage[player]:Destroy() end

		-- Maak een Highlight object aan (modern Roblox ESP systeem)
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESPHighlight"
		highlight.FillColor = Color3.fromRGB(255, 0, 0)     -- Kleur van de vulling (Rood)
		highlight.FillTransparency = 0.5                     -- Doorschijnendheid van de vulling
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Kleur van de rand (Wit)
		highlight.OutlineTransparency = 0                   -- Rand is volledig zichtbaar
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Zorgt dat het door muren heen te zien is
		highlight.Parent = character

		highlightStorage[player] = highlight
	end

	-- Pas toe als de character laadt
	if player.Character then applyHighlight(player.Character) end
	player.CharacterAdded:Connect(applyHighlight)
end

local function removeESP()
	for player, highlight in pairs(highlightStorage) do
		if highlight then highlight:Destroy() end
	end
	table.clear(highlightStorage)
end

local function updateESP()
	if espActive then
		for _, player in ipairs(Players:GetPlayers()) do
			createESP(player)
		end
	else
		removeESP()
	end
end

-- ESP Knop klikgedrag
espButton.MouseButton1Click:Connect(function()
	espActive = not espActive
	if espActive then
		espButton.Text = "ESP: ON"
		espButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		updateESP()
	else
		espButton.Text = "ESP: OFF"
		espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		updateESP()
	end
end)

-- Luister naar nieuwe spelers die de server betreden voor ESP
Players.PlayerAdded:Connect(function(player)
	if espActive then
		createESP(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if highlightStorage[player] then
		highlightStorage[player]:Destroy()
		highlightStorage[player] = nil
	end
end)
