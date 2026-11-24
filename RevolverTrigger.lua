local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if getgenv().RevolverTriggerRunning then
	getgenv().RevolverTriggerRunning = false
	task.wait(0.1)
end

local TOGGLE_KEY = Enum.KeyCode.F6
local EXIT_KEY = Enum.KeyCode.F10
local SCAN_INTERVAL = 0.03
local SHOT_COOLDOWN = 0.18
local MAX_DISTANCE = 400
local ONLY_LIVING = true

getgenv().RevolverTriggerRunning = true
local enabled = false
local lastShot = 0
local busy = false

local function triggerClick()
	if busy then return end
	busy = true

	pcall(function()
		if typeof(mouse1click) == "function" then
			mouse1click()
		elseif typeof(mouse1press) == "function" and typeof(mouse1release) == "function" then
			mouse1press()
			task.wait(0.02)
			mouse1release()
		end
	end)

	task.wait(0.03)
	busy = false
end

local function getLivingCharacter(part)
	if not part then return nil end
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return nil end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	if ONLY_LIVING and humanoid.Health <= 0 then return nil end

	return model
end

local function isTargetPlayer(model)
	if not model or model == LocalPlayer.Character then
		return false
	end

	local player = Players:GetPlayerFromCharacter(model)
	if not player then
		return false
	end

	if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
		return false
	end

	return true
end

local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == TOGGLE_KEY then
		enabled = not enabled
		print("[Revólver Trigger] " .. (enabled and "ACTIVADO" or "PAUSADO"))
	elseif input.KeyCode == EXIT_KEY then
		enabled = false
		getgenv().RevolverTriggerRunning = false
		print("[Revólver Trigger] Apagado")
	end
end)

task.spawn(function()
	task.wait(0.5)
	print("[Revólver Trigger] Listo. F6 = Activar/Pausar | F10 = Salir")

	while getgenv().RevolverTriggerRunning do
		if enabled and not busy then
			local now = os.clock()
			if (now - lastShot) >= SHOT_COOLDOWN then
				Camera = workspace.CurrentCamera or Camera
				if Camera then
					local mousePos = UserInputService:GetMouseLocation()
					local originPos = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
						and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
						or mousePos

					local ray = Camera:ViewportPointToRay(originPos.X, originPos.Y)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					if LocalPlayer.Character then
						params.FilterDescendantsInstances = { LocalPlayer.Character }
					end

					local hit = workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, params)
					if hit then
						local character = getLivingCharacter(hit.Instance)
						if isTargetPlayer(character) then
							lastShot = now
							triggerClick()
						end
					end
				end
			end
		end

		task.wait(SCAN_INTERVAL)
	end

	if inputConn then
		inputConn:Disconnect()
	end
end)
