
-- LocalScript (đặt vào StarterPlayerScripts)
-- Chú ý: client-side teleport có thể bị server chặn trong một số game.
-- Thay đổi config dưới đây nếu cần.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- CONFIG
local FOLLOW_DISTANCE_STUDS = 2        -- distance từ chân target (studs)
local UPDATE_RATE = 0.06               -- giây giữa mỗi update vị trí (nhỏ hơn = mượt hơn/phiền server)
local RAYCAST_DOWN_OFFSET = 5          -- khi tìm "chân" ta bắn ray xuống để biết mặt đất (nếu cần)
local BUTTON_SIZE = UDim2.new(0, 110, 0, 44)

-- UI CREATION
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportFollowGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Name = "Container"
frame.AnchorPoint = Vector2.new(1, 0.5) -- to place on right middle
frame.Position = UDim2.new(1, -10, 0.5, 0)
frame.Size = BUTTON_SIZE
frame.BackgroundTransparency = 0
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = screenGui

-- Rounded corners
local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 14)
uicorner.Parent = frame

-- Gradient background (initial)
local uigradient = Instance.new("UIGradient")
uigradient.Rotation = 0
uigradient.Parent = frame

-- Border (stroke)
local uistroke = Instance.new("UIStroke")
uistroke.Thickness = 2
uistroke.Parent = frame

-- Button Text
local button = Instance.new("TextButton")
button.Name = "ToggleBtn"
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.new(1, -8, 1, -8)
button.Position = UDim2.new(0.5, 0, 0.5, 0)
button.BackgroundTransparency = 1
button.Text = "Follow: OFF"
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = frame

-- small pulse when hover (optional)
local function pulseScale(guiObject)
	local goal = {Size = guiObject.Size + UDim2.new(0,6,0,6)}
	local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(guiObject, info, goal)
	tween:Play()
	delay(0.12, function()
		local back = TweenService:Create(guiObject, info, {Size = guiObject.Size})
		back:Play()
	end)
end

button.MouseEnter:Connect(function()
	pulseScale(frame)
end)

-- RAINBOW ANIMATION
local hue = 0
local HUE_SPEED = 0.12 -- how fast hue cycles (0.0..1.0 per second)
local runningRainbow = true

spawn(function()
	while runningRainbow do
		hue = (hue + HUE_SPEED * task.wait(0.04)) % 1
		-- build a simple two-color gradient using hue and hue+0.25
		local c1 = Color3.fromHSV(hue, 0.9, 0.95)
		local c2 = Color3.fromHSV((hue + 0.25) % 1, 0.9, 0.95)
		uigradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		}
		uistroke.Color = c1
		-- small rotation for dynamic look
		uigradient.Rotation = (uigradient.Rotation + 1) % 360
		task.wait(0.025)
	end
end)

-- HELPER: tìm target (gần nhất, không phải bản thân)
local function findNearestPlayer()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then return nil end

	local nearest = nil
	local nearestDist = math.huge
	for _, pl in pairs(Players:GetPlayers()) do
		if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = pl.Character.HumanoidRootPart
			local dist = (hrp.Position - myHRP.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = pl
			end
		end
	end
	return nearest, nearestDist
end

-- HELPER: get "foot position" of target (attempts to get low point)
local function getTargetFeetPosition(targetCharacter)
	local hrp = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	-- approximate feet position as HRP position with downward offset
	local origin = hrp.Position
	local rayOrigin = origin + Vector3.new(0, RAYCAST_DOWN_OFFSET, 0)
	local rayDir = Vector3.new(0, -RAYCAST_DOWN_OFFSET * 2, 0)
	local ray = Ray.new(rayOrigin, rayDir)
	local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {targetCharacter})
	if hit and pos then
		-- pos is ground under the target -> feet roughly at pos + small offset
		return pos + Vector3.new(0, 0.5, 0)
	else
		-- fallback: a bit below HRP
		return hrp.Position - Vector3.new(0, (hrp.Size.Y / 5) + 1.8, 0)
	end
end

-- FOLLOW LOGIC
local following = false
local followConnection = nil

local function startFollowing()
	if following then return end
	following = true
	button.Text = "Follow: ON"

	local function step()
		local myChar = LocalPlayer.Character
		if not myChar then return end
		local myHRP = myChar:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end

		local target, dist = findNearestPlayer()
		if not target or not target.Character then
			return
		end
		local tChar = target.Character
		local tFeetPos = getTargetFeetPosition(tChar)
		if not tFeetPos then return end

		-- compute desired position: slightly above feet so your feet are ~FOLLOW_DISTANCE_STUDS away
		-- We'll place player's HumanoidRootPart at target feet + up offset
		-- To get "2 studs down from them" along Y we subtract; but we want to be at ground level next to their feet:
		local direction = (myHRP.Position - tFeetPos)
		-- if too small, choose a default lateral offset
		if direction.Magnitude < 0.1 then
			direction = Vector3.new(0, 0, -1)
		end
		local lateral = direction.Unit * FOLLOW_DISTANCE_STUDS
		-- set target position near their feet (preserve ground Y using raycast ideally)
		local desiredPos = tFeetPos + lateral
		-- raise slightly so HRP isn't underground
		desiredPos = Vector3.new(desiredPos.X, tFeetPos.Y + 1.2, desiredPos.Z)

		-- Face towards target feet:
		local lookCFrame = CFrame.new(desiredPos, Vector3.new(tFeetPos.X, desiredPos.Y, tFeetPos.Z))

		-- Apply CFrame directly
		-- Note: some games have anti-teleport; this may be overridden by server
		pcall(function()
			myHRP.CFrame = lookCFrame
		end)
	end

	-- Connect update loop
	followConnection = RunService.Heartbeat:Connect(function(dt)
		-- we run step at UPDATE_RATE spacing to reduce spamming
		local acc = 0
		acc = acc + dt
	end)

	-- We'll run our own loop with wait to control rate
	spawn(function()
		while following do
			step()
			task.wait(UPDATE_RATE)
		end
	end)
end

local function stopFollowing()
	if not following then return end
	following = false
	button.Text = "Follow: OFF"
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
end

-- Toggle
button.MouseButton1Click:Connect(function()
	if following then
		stopFollowing()
	else
		startFollowing()
	end
end)

-- Cleanup on character respawn: ensure follow stops then restarts if player toggled
LocalPlayer.CharacterAdded:Connect(function(char)
	-- small delay to allow HRP to exist
	task.wait(0.3)
	-- if following, keep following automatically (script loop already checks for HRP)
end)

-- Safety: if player leaves or GUI removed, stop rainbow
screenGui.AncestryChanged:Connect(function()
	if not screenGui:IsDescendantOf(game) then
		runningRainbow = false
	end
end)

-- Optional: expose simple commands for debugging in output
return {
	start = startFollowing,
	stop = stopFollowing,
}
