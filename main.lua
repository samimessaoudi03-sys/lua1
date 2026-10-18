-- We maken zelf de GUI aan zodat de executor deze op je scherm kan zetten
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Verwijder een eventuele oude knop als je het script opnieuw executeert
if CoreGui:FindFirstChild("SpectateGui") then
	CoreGui.SpectateGui:Destroy()
end

-- GUI Creatie
local sg = Instance.new("ScreenGui")
sg.Name = "SpectateGui"
sg.ResetOnSpawn = false
sg.Parent = CoreGui -- Zorgt ervoor dat de GUI zichtbaar blijft, zelfs als je doodgaat

local button = Instance.new("TextButton")
button.Name = "SpectateButton"
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0.5, -100, 0.85, 0) -- Onderkant/midden van je scherm
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.SourceSansBold
button.TextSize = 18
button.Text = "Spectate"
button.Parent = sg

-- Ronde hoeken voor de knop (ziet er netter uit)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = button

local spectatingIndex = 1
local isSpectating = false

-- Functie om andere actieve spelers op te halen
local function getOtherPlayers()
	local playerList = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Humanoid") then
			table.insert(playerList, player)
		end
	end
	return playerList
end

-- Functie om de camera bij te werken naar het doelwit
local function updateCamera(targetPlayer)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
		camera.CameraSubject = targetPlayer.Character.Humanoid
		button.Text = "Spectating: " .. targetPlayer.Name
		button.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Rood als je spectate
	else
		camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
		button.Text = "Spectate"
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		isSpectating = false
	end
end

-- Klik functionaliteit
button.MouseButton1Click:Connect(function()
	local otherPlayers = getOtherPlayers()
	
	if #otherPlayers == 0 then
		button.Text = "Geen spelers gevonden"
		task.wait(1)
		button.Text = "Spectate"
		return
	end

	if not isSpectating then
		isSpectating = true
		spectatingIndex = 1
		updateCamera(otherPlayers[spectatingIndex])
	else
		spectatingIndex = spectatingIndex + 1
		
		if spectatingIndex > #otherPlayers then
			camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
			button.Text = "Spectate"
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			isSpectating = false
		else
			updateCamera(otherPlayers[spectatingIndex])
		end
	end
end)

-- Reset als de bekeken speler weggaat
Players.PlayerRemoving:Connect(function(player)
	local otherPlayers = getOtherPlayers()
	if isSpectating and otherPlayers[spectatingIndex] == player then
		camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
		button.Text = "Spectate"
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		isSpectating = false
	end
end)
