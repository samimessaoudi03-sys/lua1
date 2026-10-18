-- =============================================================================
-- PRO-LEVEL UTILITY SCRIPT v3 (Smoothness Slider & Raycast Wall-Check)
-- =============================================================================

-- DIENSTEN
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- CONFIGURATIE & STATE
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

local state = {
	fly = { active = false, speed = 50, keys = {} },
	esp = { active = false, storage = {} },
	aimlock = { active = false, targetPart = "Head", fov = 150, smoothness = 0.2 },
	hitbox = { active = false, size = 15 }
}

local flyConstraints = {}

-- =============================================================================
-- UI CREATIE (Clean Dark Menu met Sliders)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoreUtility_Menu_v3"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 420)
mainFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
titleLabel.Text = "  EXPERT PANEL v3"
titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

local function createMenuButton(text, position, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 220, 0, 35)
	btn.Position = position
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.Text = text
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local newState = callback()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = newState and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(40, 40, 40),
			TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
		}):Play()
	end)
	return btn
end

-- =============================================================================
-- INTERACTIEVE SLIDER (Smoothness regelaar)
-- =============================================================================
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(0, 220, 0, 45)
sliderFrame.Position = UDim2.new(0, 20, 0, 280)
sliderFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
sliderFrame.BorderSizePixel = 0
sliderFrame.Parent = mainFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 6)
sliderCorner.Parent = sliderFrame

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1, 0, 0, 20)
sliderLabel.Position = UDim2.new(0, 10, 0, 2)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Text = "Aim Smoothness: 0.20"
sliderLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 11
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderFrame

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(0, 200, 0, 6)
sliderTrack.Position = UDim2.new(0, 10, 0, 26)
sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = sliderFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(state.aimlock.smoothness, 0, 1, 0) -- Standaard op 0.20 (20%)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(0, 14, 0, 14)
sliderBtn.Position = UDim2.new(state.aimlock.smoothness, -7, 0, -4)
sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderBtn.Text = ""
sliderBtn.Parent = sliderTrack

local btnRound = Instance.new("UICorner")
btnRound.CornerRadius = UDim.new(1, 0)
btnRound.Parent = sliderBtn

-- Slider functionaliteit (Sleepbaar)
local dragging = false
sliderBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local trackX = sliderTrack.AbsolutePosition.X
		local trackWidth = sliderTrack.AbsoluteSize.X
		local mouseX = input.Position.X
		local percentage = math.clamp((mouseX - trackX) / trackWidth, 0.01, 1) -- Nooit exact 0 ivm camera lerp delingen
		
		sliderBtn.Position = UDim2.new(percentage, -7, 0, -4)
		sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
		
		state.aimlock.smoothness = percentage
		sliderLabel.Text = string.format("Aim Smoothness: %.2f", percentage)
	end
end)

-- =============================================================================
-- FOV CIRKEL
-- =============================================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(0, 150, 100)
fovCircle.Transparency = 0.7
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
	if state.aimlock.active then
		fovCircle.Position = UserInputService:GetMouseLocation()
		fovCircle.Radius = state.aimlock.fov
		fovCircle.Visible = true
	else
		fovCircle.Visible = false
	end
end)

-- =============================================================================
-- ADVANCED RAYCAST WALL-CHECK & AIMLOCK LOGICA
-- =============================================================================
local function isPartVisible(targetPart, character)
	local origin = camera.CFrame.Position
	local direction = targetPart.Position - origin
	
	local params = RaycastParams.new()
	-- Sluit jezelf, de target en eventuele visuals/hitbox-expanders uit van de berekening
	params.FilterDescendantsInstances = {localPlayer.Character, character, screenGui}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	
	local result = workspace:Raycast(origin, direction, params)
	
	-- Als het resultaat leeg is, raakt de straal niks tussen de camera en de target (dus zichtbaar!)
	return result == nil
end

local function getClosestPlayerToMouse()
	local closest, shortestDistance = nil, state.aimlock.fov
	local mousePos = UserInputService:GetMouseLocation()

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and p.Character then
			local part = p.Character:FindFirstChild(state.aimlock.targetPart)
			local hum = p.Character:FindFirstChild("Humanoid")
			
			if part and hum and hum.Health > 0 then
				local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
					if distance < shortestDistance then
						-- Voer hier de cruciale Wall-Check uit
						if isPartVisible(part, p.Character) then
							closest = part
							shortestDistance = distance
						end
					end
				end
			end
		end
	end
	return closest
end

-- Vloeiende Camera Lock Loop (RenderStepped voor zero-lag framerate interpolatie)
RunService.RenderStepped:Connect(function()
	if state.aimlock.active then
		local target = getClosestPlayerToMouse()
		if target then
			-- Bereken de doel CFrame richting de speler
			local targetCFrame = CFrame.new(camera.CFrame.Position, target.Position)
			-- Gebruik Lerp op basis van de sliderwaarde voor extreme smoothness
			camera.CFrame = camera.CFrame:Lerp(targetCFrame, state.aimlock.smoothness)
		end
	end
end)

-- =============================================================================
-- MODERN FLY MODULE (LinearVelocity & AlignOrientation)
-- =============================================================================
local function toggleFly()
	state.fly.active = not state.fly.active
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	if not state.fly.active or not root or not hum then
		for _, obj in ipairs(flyConstraints) do if obj then obj:Destroy() end end
		table.clear(flyConstraints)
		if hum then hum.PlatformStand = false end
		return false
	end

	hum.PlatformStand = true

	local attachment = Instance.new("Attachment", root)
	local linVel = Instance.new("LinearVelocity", root)
	linVel.MaxForce = 9e9
	linVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	linVel.Attachment0 = attachment

	local alignOri = Instance.new("AlignOrientation", root)
	alignOri.MaxTorque = 9e9
	alignOri.Responsiveness = 200
	alignOri.Mode = Enum.OrientationMode.OneAttachment
	alignOri.Attachment0 = attachment
	alignOri.CFrame = root.CFrame

	table.insert(flyConstraints, attachment)
	table.insert(flyConstraints, linVel)
	table.insert(flyConstraints, alignOri)

	task.spawn(function()
