
--================ CONFIG =================--
local UI_BG_IMAGE = "rbxassetid://87746599009295"      -- Ảnh nền UI
local TOGGLE_BG_IMAGE = "rbxassetid://87746599009295"  -- Ảnh nút tròn
local UI_TITLE = "AUTO FARM PHUCMAX"

--================ SERVICES =================--
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local LocalPlayer = player

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
-- Sửa: CreateToggle nhận (name, callback). Callback(state) sẽ được gọi khi toggle thay đổi.
local function CreateToggle(name, callback)
	local Button = Instance.new("TextButton")
	Button.Parent = Holder
	Button.Size = UDim2.new(1,0,0,45)
	Button.BackgroundColor3 = Color3.fromRGB(40,40,40) -- default OFF color
	Button.Text = name .. " : OFF"
	Button.Font = Enum.Font.Gotham
	Button.TextScaled = true
	Button.TextColor3 = Color3.fromRGB(255,255,255)
	Button.AutoButtonColor = false

	local Corner = Instance.new("UICorner", Button)
	Corner.CornerRadius = UDim.new(0,12)

	local state = false
	local function update(s)
		state = s
		if state then
			Button.Text = name .. " : ON"
			Button.BackgroundColor3 = Color3.fromRGB(0,170,0)
		else
			Button.Text = name .. " : OFF"
			Button.BackgroundColor3 = Color3.fromRGB(40,40,40)
		end
		if callback then
			-- bảo vệ callback để tránh lỗi runtime
			local ok, err = pcall(callback, state)
			if not ok then
				warn("CreateToggle callback error for", name, err)
			end
		end
	end

	Button.MouseButton1Click:Connect(function()
		update(not state)
	end)

	-- trả về hàm lấy trạng thái nếu cần
	return Button, function() return state end
end

--================ AUTO SKILL =================--
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
				-- Lưu ý: VirtualInputManager có thể bị hạn chế ở môi trường an toàn.
				pcall(function()
					VirtualInputManager:SendKeyEvent(true, key, false, game)
					task.wait(0.05)
					VirtualInputManager:SendKeyEvent(false, key, false, game)
				end)
				task.wait(0.1)
			end
		end
	end
end)

--================ Underfoot TP (scope riêng) =================--
do
	local followEnabled_under = false
	local targetPlayer_under = nil
	local followConnection_under

	local function getNewTarget_under()
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

	CreateToggle("Underfoot TP", function(state)
		followEnabled_under = state

		if not state then
			if followConnection_under then
				followConnection_under:Disconnect()
				followConnection_under = nil
			end
			targetPlayer_under = nil
			return
		end

		targetPlayer_under = getNewTarget_under()

		followConnection_under = RunService.Heartbeat:Connect(function()
			if not followEnabled_under then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if not targetPlayer_under
				or not targetPlayer_under.Character
				or not targetPlayer_under.Character:FindFirstChild("Humanoid")
				or targetPlayer_under.Character.Humanoid.Health <= 0 then
				targetPlayer_under = getNewTarget_under()
				return
			end

			local targetHRP = targetPlayer_under.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			local pos = targetHRP.Position - Vector3.new(0, 2, 0)
			myHRP.CFrame = CFrame.new(pos, targetHRP.Position)
		end)
	end)
end

--================ Backstep TP (scope riêng) =================--
do
	local followEnabled_back = false
	local targetPlayer_back = nil
	local followConnection_back

	local function getNewTarget_back()
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

	CreateToggle("Backstep TP", function(state)
		followEnabled_back = state

		if not state then
			if followConnection_back then
				followConnection_back:Disconnect()
				followConnection_back = nil
			end
			targetPlayer_back = nil
			return
		end

		targetPlayer_back = getNewTarget_back()

		followConnection_back = RunService.Heartbeat:Connect(function()
			if not followEnabled_back then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if not targetPlayer_back
				or not targetPlayer_back.Character
				or not targetPlayer_back.Character:FindFirstChild("Humanoid")
				or targetPlayer_back.Character.Humanoid.Health <= 0 then
				targetPlayer_back = getNewTarget_back()
				return
			end

			local targetHRP = targetPlayer_back.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			local behindPos = targetHRP.Position - targetHRP.CFrame.LookVector * 5
			myHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
		end)
	end)
end

--================ Overhead TP (scope riêng) =================--
do
	local followEnabled_over = false
	local targetPlayer_over = nil
	local followConnection_over

	local function getNewTarget_over()
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

	CreateToggle("Overhead TP", function(state)
		followEnabled_over = state

		if not state then
			if followConnection_over then
				followConnection_over:Disconnect()
				followConnection_over = nil
			end
			targetPlayer_over = nil
			return
		end

		targetPlayer_over = getNewTarget_over()

		followConnection_over = RunService.Heartbeat:Connect(function()
			if not followEnabled_over then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if not targetPlayer_over
				or not targetPlayer_over.Character
				or not targetPlayer_over.Character:FindFirstChild("Humanoid")
				or targetPlayer_over.Character.Humanoid.Health <= 0 then
				targetPlayer_over = getNewTarget_over()
				return
			end

			local targetHRP = targetPlayer_over.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			local abovePos = targetHRP.Position + Vector3.new(0, 5, 0)
			myHRP.CFrame = CFrame.new(abovePos, targetHRP.Position)
		end)
	end)
end

--================ Orbit TP (scope riêng) =================--
do
	local orbitEnabled_orb = false
	local targetPlayer_orb = nil
	local orbitConnection_orb
	local angle_orb = 0

	local function getNewTarget_orb()
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

	CreateToggle("Orbit TP", function(state)
		orbitEnabled_orb = state

		if not state then
			if orbitConnection_orb then
				orbitConnection_orb:Disconnect()
				orbitConnection_orb = nil
			end
			targetPlayer_orb = nil
			return
		end

		targetPlayer_orb = getNewTarget_orb()
		angle_orb = 0

		orbitConnection_orb = RunService.Heartbeat:Connect(function(dt)
			if not orbitEnabled_orb then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if not targetPlayer_orb
				or not targetPlayer_orb.Character
				or not targetPlayer_orb.Character:FindFirstChild("Humanoid")
				or targetPlayer_orb.Character.Humanoid.Health <= 0 then
				targetPlayer_orb = getNewTarget_orb()
				return
			end

			local targetHRP = targetPlayer_orb.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			angle_orb += dt * 5

			local radius = 15
			local height = 0.5

			local offset = Vector3.new(
				math.cos(angle_orb) * radius,
				height,
				math.sin(angle_orb) * radius
			)

			local orbitPos = targetHRP.Position + offset
			myHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)
		end)
	end)
end

--================ Heal TP (lớn / cao / noclip) =================--
do
	local healEnabled = false
	local targetPlayer_heal = nil
	local healConnection = nil
	local noclipConnection = nil
	local angle_heal = 0

	local function getNewTarget_heal()
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

	local function enableNoclip_heal()
		if noclipConnection then return end
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

	local function disableNoclip_heal()
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
	end

	CreateToggle("heal TP", function(state)
		healEnabled = state

		if not state then
			if healConnection then
				healConnection:Disconnect()
				healConnection = nil
			end
			disableNoclip_heal()
			targetPlayer_heal = nil
			return
		end

		targetPlayer_heal = getNewTarget_heal()
		angle_heal = 0
		enableNoclip_heal()

		healConnection = RunService.Heartbeat:Connect(function(dt)
			if not healEnabled then return end

			local myChar = LocalPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

			if not targetPlayer_heal
				or not targetPlayer_heal.Character
				or not targetPlayer_heal.Character:FindFirstChild("Humanoid")
				or targetPlayer_heal.Character.Humanoid.Health <= 0 then
				targetPlayer_heal = getNewTarget_heal()
				return
			end

			local targetHRP = targetPlayer_heal.Character:FindFirstChild("HumanoidRootPart")
			if not (myHRP and targetHRP) then return end

			angle_heal += dt * 50

			local radius = 500
			local height = 50

			local offset = Vector3.new(
				math.cos(angle_heal) * radius,
				height,
				math.sin(angle_heal) * radius
			)

			local orbitPos = targetHRP.Position + offset
			myHRP.CFrame = CFrame.new(orbitPos, targetHRP.Position)
		end)
	end)
end

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
