CombatTab:Seperator("Aimbot");
spawn(function()
	while wait() do
		pcall(function()
			local MaxDistance = math.huge;
			for i, v in pairs((game:GetService("Players")):GetPlayers()) do
				if v.Name ~= (game:GetService("Players")).LocalPlayer.Name then
					local Distance = v:DistanceFromCharacter((game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.Position);
					if Distance < MaxDistance then
						MaxDistance = Distance;
						PlayerSelectAimbot = v.Name;
					end;
				end;
			end;
		end);
	end;
end);
CombatTab:Toggle("Aimbot Gun", _G.Settings.Combat["Aimbot Gun"], "Aimbot Skill Gun", function(value)
	_G.Settings.Combat["Aimbot Gun"] = value;
	(getgenv()).SaveSetting();
end);
spawn(function()
	while task.wait() do
		if _G.Settings.Combat["Aimbot Gun"] and (game:GetService("Players")).LocalPlayer.Character:FindFirstChild(SelectWeaponGun) then
			pcall(function()
				(game:GetService("Players")).LocalPlayer.Character[SelectWeaponGun].Cooldown.Value = 0;
				local args = {
					[1] = ((game:GetService("Players")):FindFirstChild(PlayerSelectAimbot)).Character.HumanoidRootPart.Position,
					[2] = ((game:GetService("Players")):FindFirstChild(PlayerSelectAimbot)).Character.HumanoidRootPart
				};
				(game:GetService("Players")).LocalPlayer.Character[SelectWeaponGun].RemoteFunctionShoot:InvokeServer(unpack(args));
				(game:GetService("VirtualUser")):CaptureController();
				(game:GetService("VirtualUser")):Button1Down(Vector2.new(1280, 672));
			end);
		end;
	end;
end);
CombatTab:Toggle("Aimbot Skill Nearest", _G.Settings.Combat["Aimbot Skill Nearest"], "Aim Bot Skill Nearest", function(value)
	_G.Settings.Combat["Aimbot Skill Nearest"] = value;
	(getgenv()).SaveSetting();
end);
spawn(function()
	while wait(0.1) do
		pcall(function()
			local MaxDistance = math.huge;
			for i, v in pairs((game:GetService("Players")):GetPlayers()) do
				if v.Name ~= game.Players.LocalPlayer.Name then
					local Distance = v:DistanceFromCharacter(game.Players.LocalPlayer.Character.HumanoidRootPart.Position);
					if Distance < MaxDistance then
						MaxDistance = Distance;
						TargetPlayerAim = v.Name;
					end;
				end;
			end;
		end);
	end;
end);
spawn(function()
	pcall(function()
		(game:GetService("RunService")).RenderStepped:connect(function()
			if _G.Settings.Combat["Aimbot Skill Nearest"] and TargetPlayerAim ~= nil and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and game.Players.LocalPlayer.Character[(game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")).Name]:FindFirstChild("MousePos") then
				local args = {
					[1] = ((game:GetService("Players")):FindFirstChild(TargetPlayerAim)).Character.HumanoidRootPart.Position
				};
				(game:GetService("Players")).LocalPlayer.Character[(game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")).Name].RemoteEvent:FireServer(unpack(args));
			end;
		end);
	end);
end);
CombatTab:Toggle("Aimbot Skill", _G.Settings.Combat["Aimbot Skill"], "Aimbot All Skill", function(value)
	_G.Settings.Combat["Aimbot Skill"] = value;
	(getgenv()).SaveSetting();
end);
spawn(function()
	pcall(function()
		while task.wait() do
			if _G.Settings.Combat["Aimbot Skill"] and PlayerSelectAimbot ~= nil and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and game.Players.LocalPlayer.Character[(game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")).Name]:FindFirstChild("MousePos") then
				local args = {
					[1] = ((game:GetService("Players")):FindFirstChild(PlayerSelectAimbot)).Character.HumanoidRootPart.Position
				};
				((game:GetService("Players")).LocalPlayer.Character:FindFirstChild((game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")).Name)).RemoteEvent:FireServer(unpack(args));
			end;
		end;
	end);
end);
CombatTab:Toggle("Enable PvP", _G.Settings.Combat["Enable PvP"], "Enable PvP", function(value)
	_G.Settings.Combat["Enable PvP"] = value;
	(getgenv()).SaveSetting();
end);
spawn(function()
	pcall(function()
		while wait(0.1) do
			if _G.Settings.Combat["Enable PvP"] then
				if (game:GetService("Players")).LocalPlayer.PlayerGui.Main.PvpDisabled.Visible == true then
					(game:GetService("ReplicatedStorage")).Remotes.CommF_:InvokeServer("EnablePvp");
				end;
			end;
		end;
	end);
end);
CombatTab:Toggle("Safe Mode", false, "Auto Teleport To Up", function(value)
	_G.Safe_Mode = value;
	StopTween(_G.Safe_Mode);
end);
spawn(function()
	pcall(function()
		while wait(0.2) do
			if _G.Safe_Mode then
				local PlayerPosition = (game:GetService("Players")).LocalPlayer.Character.HumanoidRootPart.CFrame;
				if (game:GetService("Players")).LocalPlayer.Character.Humanoid.Health <= 2000 then
					repeat
						wait();
						topos(PlayerPosition * CFrame.new(0, 400, 0));
					until (game:GetService("Players")).LocalPlayer.Character.Humanoid.Health >= 5000 or (not _g.Safe_Mode);
				end;
			end;
		end;
	end);
end);

PVP = Window:AddTab({ Title = "Tab PVP", Icon = "" })
local Playerslist = {}
for i, player in ipairs(game.Players:GetPlayers()) do
    Playerslist[i] = player.Name
end    
Dropdown = PVP:AddDropdown("Dropdown", {
     Title = "Select Player PVP",
     Values = Playerslist,
     Multi = false,
     Default = false,
})
Dropdown:OnChanged(function(Value)
   getgenv().SelectPlayer = Value
end)
Toggle = PVP:AddToggle("MyToggle", {
    Title = "Teleport Player",
    Default = false
})
Toggle:OnChanged(function(Value)
    getgenv().TeleportPlayer = Value
    if getgenv().TeleportPlayer then
        task.spawn(function()
            while getgenv().TeleportPlayer do
                local player = game:GetService("Players"):FindFirstChild(getgenv().SelectPlayer)
                if player and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        topos(hrp.CFrame)
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)
Toggle = PVP:AddToggle("Toggle", {Title = "Auto Aimbot", Default = false })
Toggle:OnChanged(function(Value)
    getgenv().Aimbot = Value
end)        
spawn(function()
    pcall(function()
        while task.wait(0.1) do
            if getgenv().Aimbot and getgenv().SelectPlayer then
                local player = game.Players:FindFirstChild(getgenv().SelectPlayer)
                local localPlayer = game.Players.LocalPlayer
                local character = localPlayer.Character
                local tool = character and character:FindFirstChildOfClass("Tool")
                if player and player.Character and tool then
                    local remoteEvent = tool:FindFirstChild("RemoteEvent")
                    local mousePos = tool:FindFirstChild("MousePos")
                    local target = player.Character:FindFirstChild("HumanoidRootPart")
                    if remoteEvent and mousePos and target then
                        remoteEvent:FireServer(target.Position)
                    end
                end
            end
        end
    end)
end)
Toggle = PVP:AddToggle("Toggle", {Title = "Auto Aimbot Gun", Default = false })
Toggle:OnChanged(function(Value)
    getgenv().AimbotGun = Value
end)        
spawn(function()
    while task.wait(0.1) do
        if getgenv().AimbotGun and SelectWeaponGun then
            local player = game:GetService("Players").LocalPlayer
            local character = player and player.Character
            local weapon = character and character:FindFirstChild(SelectWeaponGun)
            local targetPlayer = game:GetService("Players"):FindFirstChild(getgenv().SelectPlayer)
            local targetCharacter = targetPlayer and targetPlayer.Character
            local targetHumanoidRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            if weapon and targetHumanoidRootPart then
                pcall(function()
                    weapon.Cooldown.Value = 0
                    local args = {
                        [1] = targetHumanoidRootPart.Position,
                        [2] = targetHumanoidRootPart
                    }
                    weapon.RemoteFunctionShoot:InvokeServer(unpack(args))
                    local virtualUser = game:GetService("VirtualUser")
                    virtualUser:Button1Down(Vector2.new(1280, 672))
                end)
            end
        end
    end
end)
Toggle = PVP:AddToggle("Toggle", {Title = "Safe Modes", Default = false })
Toggle:OnChanged(function(Value)
    getgenv().SafeMode = Value
end)
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if getgenv().SafeMode then
                local CharacterPlayer = game.Players.LocalPlayer.Character
                if CharacterPlayer and CharacterPlayer:FindFirstChild("Humanoid") and CharacterPlayer:FindFirstChild("HumanoidRootPart") then
                    local HealthMinPlayer = CharacterPlayer.Humanoid.MaxHealth * (getgenv().Safe / 100)
                    if CharacterPlayer.Humanoid.Health <= HealthMinPlayer then
                        while getgenv().SafeMode and CharacterPlayer.Humanoid.Health <= HealthMinPlayer do
                            task.wait(0.1)
                            CharacterPlayer.HumanoidRootPart.CFrame = CharacterPlayer.HumanoidRootPart.CFrame + Vector3.new(0, 50, 0)
                        end
                    end
                end
            end
        end)
    end
end)
Slider = PVP:AddSlider("Slider", {
    Title = "Safe Mode At",
    Default = 30,
    Min = 0,
    Max = 100,
    Rounding = 5,
    Callback = function(Value)
        getgenv().Safe = Value
    end
})
Toggle = PVP:AddToggle("Toggle", { Title = "Walk On Water", Default = true })
Toggle:OnChanged(function(Value)
    getgenv().WalkWater = Value    
    local waterPlane = game:GetService("Workspace").Map["WaterBase-Plane"]
    if getgenv().WalkWater then
        waterPlane.Size = Vector3.new(1000, 112, 1000)
    else
        waterPlane.Size = Vector3.new(1000, 80, 1000)
    end
end)
Toggle = PVP:AddToggle("Toggle", {Title = "No Clip", Default = false })
Toggle:OnChanged(function(v)
    getgenv().NoClip = v
    if getgenv().NoClipConnection then getgenv().NoClipConnection:Disconnect() end
    if v then
        getgenv().NoClipConnection = game:GetService("RunService").Stepped:Connect(function()
            for _, p in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    else
        for _, p in ipairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end)
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
getgenv().WalkSpeed = 16
Toggle = PVP:AddToggle("Toggle", {
    Title = "Change WalkSpeed",
    Default = false
})
local SpeedConnection
local function ApplySpeed()
    if not Toggle.Value then return end
    local Character = Player.Character
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = getgenv().WalkSpeed
            if SpeedConnection then
                SpeedConnection:Disconnect()
            end
            SpeedConnection = Humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if Toggle.Value then
                    Humanoid.WalkSpeed = getgenv().WalkSpeed
                end
            end)
        end
    end
end
Toggle:OnChanged(function(Value)
    if Value then
        ApplySpeed()
        Player.CharacterAdded:Connect(ApplySpeed)
    else
        if SpeedConnection then
            SpeedConnection:Disconnect()
            SpeedConnection = nil
        end
        local Character = Player.Character
        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then
                Humanoid.WalkSpeed = 16
            end
        end
    end
end)
Input = PVP:AddInput("Input", {
     Title = "Input WalkSpeed",
     Default = 100,
     Placeholder = "Input",
     Numeric = true,
     Finished = true,
     Callback = function(Value)
         getgenv().WalkSpeed = Value
     end
})