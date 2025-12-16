--================ CONFIG =================--
local UI_BG_IMAGE = "rbxassetid://87746599009295"      -- Ảnh nền UI
local TOGGLE_BG_IMAGE = "rbxassetid://102837028306912"  -- Ảnh nút tròn
local UI_TITLE = "AUTO FARM PHUCMAX"

--================ SERVICES =================--
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--================ GUI =================--
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CleanGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

--================ TOGGLE BUTTON =================--
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0,60,0,60)
ToggleBtn.Position = UDim2.new(0,15,0.5,-30)
ToggleBtn.Image = TOGGLE_BG_IMAGE
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.AutoButtonColor = false
ToggleBtn.Name = "ToggleButton"

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(1,0)

-- Xoay ngược kim đồng hồ
RunService.RenderStepped:Connect(function()
	ToggleBtn.Rotation -= 1
end)

--================ MAIN UI =================--
local MainUI = Instance.new("ImageLabel")
MainUI.Parent = ScreenGui
MainUI.Size = UDim2.new(0,320,0,380)
MainUI.Position = UDim2.new(0.5,-160,0.5,-190)
MainUI.Image = UI_BG_IMAGE
MainUI.BackgroundTransparency = 1
MainUI.Visible = true
MainUI.Active = true
MainUI.Draggable = true
MainUI.Name = "MainUI"

local MainCorner = Instance.new("UICorner", MainUI)
MainCorner.CornerRadius = UDim.new(0,20)

--================ TITLE =================--
local Title = Instance.new("TextLabel")
Title.Parent = MainUI
Title.Size = UDim2.new(1,0,0,50)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = UI_TITLE
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(255,0,255)

--================ BUTTON HOLDER =================--
local Holder = Instance.new("Frame")
Holder.Parent = MainUI
Holder.Size = UDim2.new(1,-20,1,-70)
Holder.Position = UDim2.new(0,10,0,60)
Holder.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Holder)
Layout.Padding = UDim.new(0,10)

--================ TOGGLE BUTTON FUNCTION =================--
local function CreateToggle(name)
	local Button = Instance.new("TextButton")
	Button.Parent = Holder
	Button.Size = UDim2.new(1,0,0,45)
	Button.BackgroundColor3 = Color3.fromRGB(255,50,255)
	Button.Text = name .. " : OFF"
	Button.Font = Enum.Font.Gotham
	Button.TextScaled = true
	Button.TextColor3 = Color3.fromRGB(255,255,255)
	Button.AutoButtonColor = false

	local Corner = Instance.new("UICorner", Button)
	Corner.CornerRadius = UDim.new(0,12)

	local state = false
	Button.MouseButton1Click:Connect(function()
		state = not state
		if state then
			Button.Text = name .. " : ON"
			Button.BackgroundColor3 = Color3.fromRGB(0,170,0)
		else
			Button.Text = name .. " : OFF"
			Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
		end
	end)
end

--================ CREATE BUTTONS =================--
local VirtualInputManager = game:GetService("VirtualInputManager")

local auto1234 = false

CreateToggle("Auto Skill", function(state)
	auto1234 = state
end)

task.spawn(function()
	while task.wait() do
		if auto1234 then
			for _, key in ipairs({
				Enum.KeyCode.One,
				Enum.KeyCode.Two,
				Enum.KeyCode.Three,
				Enum.KeyCode.Four
			}) do
				VirtualInputManager:SendKeyEvent(true, key, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, key, false, game)
				task.wait(0.1)
			end
		end
	end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local followEnabled = false
local targetPlayer = nil
local followConnection

-- tìm player hợp lệ (không phải mình, còn sống)
local function getNewTarget()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
			and plr.Character
			and plr.Character:FindFirstChild("Humanoid")
			and plr.Character.Humanoid.Health > 0 then
			return plr
		end
	end
	return nil
end

CreateToggle("Underfoot TP",
	function(state)
		followEnabled = state

		if not state then
			if followConnection then
				followConnection:Disconnect()
				followConnection = nil
			end
			targetPlayer = nil
			return
		end

		targetPlayer = getNewTarget()

		followConnection = RunService.Heartbeat:Connect(function()
			if not followEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			-- đổi mục tiêu nếu cần
			if not targetPlayer
				or not targetPlayer.Character
				or not targetPlayer.Character:FindFirstChild("Humanoid")
				or targetPlayer.Character.Humanoid.Health <= 0 then
				targetPlayer = getNewTarget()
				return
			end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			-- vị trí dưới chân mục tiêu (2 studs)
			local pos = targetHRP.Position - Vector3.new(0, 2, 0)

			-- luôn hướng mặt về mục tiêu
			myHRP.CFrame = CFrame.new(pos, targetHRP.Position)
		end)
	end)
	
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local followEnabled = false
local targetPlayer = nil
local followConnection

-- tìm mục tiêu hợp lệ
local function getNewTarget()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
			and plr.Character
			and plr.Character:FindFirstChild("Humanoid")
			and plr.Character.Humanoid.Health > 0 then
			return plr
		end
	end
	return nil
end

CreateToggle(
	"Backstep TP",
	function(state)
		followEnabled = state

		if not state then
			if followConnection then
				followConnection:Disconnect()
				followConnection = nil
			end
			targetPlayer = nil
			return
		end

		targetPlayer = getNewTarget()

		followConnection = RunService.Heartbeat:Connect(function()
			if not followEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			-- đổi mục tiêu nếu chết / mất
			if not targetPlayer
				or not targetPlayer.Character
				or not targetPlayer.Character:FindFirstChild("Humanoid")
				or targetPlayer.Character.Humanoid.Health <= 0 then
				targetPlayer = getNewTarget()
				return
			end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			-- SAU LƯNG MỤC TIÊU (theo LookVector)
			local behindPos =
				targetHRP.Position
				- targetHRP.CFrame.LookVector * 2

			-- teleport + luôn nhìn vào mục tiêu
			myHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
		end)
	end)
	
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local followEnabled = false
local targetPlayer = nil
local followConnection

-- tìm player hợp lệ
local function getNewTarget()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
			and plr.Character
			and plr.Character:FindFirstChild("Humanoid")
			and plr.Character.Humanoid.Health > 0 then
			return plr
		end
	end
	return nil
end

CreateToggle(
	" Overhead TP",
	function(state)
		followEnabled = state

		if not state then
			if followConnection then
				followConnection:Disconnect()
				followConnection = nil
			end
			targetPlayer = nil
			return
		end

		targetPlayer = getNewTarget()

		followConnection = RunService.Heartbeat:Connect(function()
			if not followEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			-- đổi mục tiêu khi chết / mất
			if not targetPlayer
				or not targetPlayer.Character
				or not targetPlayer.Character:FindFirstChild("Humanoid")
				or targetPlayer.Character.Humanoid.Health <= 0 then
				targetPlayer = getNewTarget()
				return
			end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			-- TRÊN ĐẦU MỤC TIÊU
			local abovePos =
				targetHRP.Position
				+ Vector3.new(0, 3, 0)

			-- teleport + luôn nhìn xuống mục tiêu
			myHRP.CFrame = CFrame.new(abovePos, targetHRP.Position)
		end)
	end)
	
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local orbitEnabled = false
local targetPlayer = nil
local orbitConnection
local angle = 0

-- tìm mục tiêu hợp lệ
local function getNewTarget()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
			and plr.Character
			and plr.Character:FindFirstChild("Humanoid")
			and plr.Character.Humanoid.Health > 0 then
			return plr
		end
	end
	return nil
end

CreateToggle(
	"Orbit TP",
	function(state)
		orbitEnabled = state

		if not state then
			if orbitConnection then
				orbitConnection:Disconnect()
				orbitConnection = nil
			end
			targetPlayer = nil
			return
		end

		targetPlayer = getNewTarget()
		angle = 0

		orbitConnection = RunService.Heartbeat:Connect(function(dt)
			if not orbitEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			-- đổi mục tiêu nếu chết / mất
			if not targetPlayer
				or not targetPlayer.Character
				or not targetPlayer.Character:FindFirstChild("Humanoid")
				or targetPlayer.Character.Humanoid.Health <= 0 then
				targetPlayer = getNewTarget()
				return
			end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			-- tốc độ xoay
			angle += dt * 2  -- tăng = xoay nhanh hơn

			local radius = 4     -- khoảng cách vòng
			local height = 0.5 -- cao hơn mặt đất

			-- tính vị trí xoay vòng
			local offset = Vector3.new(
				math.cos(angle) * radius,
				height,
				math.sin(angle) * radius
			)

			local orbitPos = targetHRP.Position + offset

			-- teleport + luôn nhìn mặt mục tiêu
			myHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)
		end)
	end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local orbitEnabled = false
local targetPlayer = nil
local orbitConnection
local noclipConnection
local angle = 0

-- tìm mục tiêu hợp lệ
local function getNewTarget()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer
			and plr.Character
			and plr.Character:FindFirstChild("Humanoid")
			and plr.Character.Humanoid.Health > 0 then
			return plr
		end
	end
	return nil
end

-- bật noclip
local function enableNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- tắt noclip
local function disableNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
end

CreateToggle(
	"heal TP",
	function(state)
		orbitEnabled = state

		if not state then
			if orbitConnection then
				orbitConnection:Disconnect()
				orbitConnection = nil
			end
			disableNoclip()
			targetPlayer = nil
			return
		end

		targetPlayer = getNewTarget()
		angle = 0
		enableNoclip()

		orbitConnection = RunService.Heartbeat:Connect(function(dt)
			if not orbitEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			-- đổi mục tiêu khi chết / mất
			if not targetPlayer
				or not targetPlayer.Character
				or not targetPlayer.Character:FindFirstChild("Humanoid")
				or targetPlayer.Character.Humanoid.Health <= 0 then
				targetPlayer = getNewTarget()
				return
			end

			local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			-- tốc độ xoay
			angle += dt * 50

			local radius = 500   -- khoảng cách xoay
			local height = 50  -- độ cao

			local offset = Vector3.new(
				math.cos(angle) * radius,
				height,
				math.sin(angle) * radius
			)

			local orbitPos = targetHRP.Position + offset

			-- teleport + luôn nhìn mặt mục tiêu
			myHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)
		end)
	end)

--================ TOGGLE UI =================--
ToggleBtn.MouseButton1Click:Connect(function()
	MainUI.Visible = not MainUI.Visible
end)

--================ DRAG TOGGLE BUTTON =================--
do
	local dragging = false
	local dragStart, startPos

	ToggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = ToggleBtn.Position
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			ToggleBtn.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end 
