local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local button = script.Parent
local spectatingIndex = 1
local isSpectating = false

-- Functie om de lijst met andere spelers op te halen
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
	else
		-- Als de speler niet meer bestaat of dood is, ga terug naar jezelf
		camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
		button.Text = "Spectate"
		isSpectating = false
	end
end

-- Knop functionaliteit
button.MouseButton1Click:Connect(function()
	local otherPlayers = getOtherPlayers()
	
	if #otherPlayers == 0 then
		button.Text = "Geen spelers om te bekijken"
		task.wait(1)
		button.Text = "Spectate"
		return
	end

	if not isSpectating then
		-- Start met spectaten van de eerste beschikbare speler
		isSpectating = true
		spectatingIndex = 1
		updateCamera(otherPlayers[spectatingIndex])
	else
		-- Volgende speler in de lijst
		spectatingIndex = spectatingIndex + 1
		
		if spectatingIndex > #otherPlayers then
			-- Als we het einde van de lijst bereiken, stop met spectaten
			camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
			button.Text = "Spectate"
			isSpectating = false
		else
			-- Spectate de volgende speler
			updateCamera(otherPlayers[spectatingIndex])
		end
	end
end)

-- Zorg ervoor dat de camera teruggaat als de bekeken speler de game verlaat
Players.PlayerRemoving:Connect(function(player)
	local otherPlayers = getOtherPlayers()
	if isSpectating and otherPlayers[spectatingIndex] == player then
		camera.CameraSubject = localPlayer.Character:FindFirstChild("Humanoid")
		button.Text = "Spectate"
		isSpectating = false
	end
end)
