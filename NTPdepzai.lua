local ScreenGui = Instance.new("ScreenGui")
local LoadingFrame = Instance.new("Frame")
local Logo = Instance.new("ImageLabel")
local Title = Instance.new("TextLabel")
local ProgressBarBackground = Instance.new("Frame")
local ProgressBar = Instance.new("Frame")

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true

LoadingFrame.Parent = ScreenGui
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingFrame.Size = UDim2.new(0, 300, 0, 140)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.BackgroundTransparency = 0.1
LoadingFrame.ClipsDescendants = true

local UICorner1 = Instance.new("UICorner", LoadingFrame)
UICorner1.CornerRadius = UDim.new(0, 12)

local UIStrokeLoading = Instance.new("UIStroke", LoadingFrame)
UIStrokeLoading.Thickness = 3
UIStrokeLoading.Color = Color3.fromRGB(255, 0, 0)
UIStrokeLoading.Transparency = 0.3

Logo.Parent = LoadingFrame
Logo.BackgroundTransparency = 1
Logo.Size = UDim2.new(0, 60, 0, 60)
Logo.Position = UDim2.new(0.1, -20, 0.20, 18)
Logo.Image = "rbxassetid://135546946645914"

local UICornerLogo = Instance.new("UICorner", Logo)
UICornerLogo.CornerRadius = UDim.new(0, 4)

local UIStrokeLogo = Instance.new("UIStroke", Logo)
UIStrokeLogo.Color = Color3.fromRGB(255, 0, 0)
UIStrokeLogo.Thickness = 2
UIStrokeLogo.Transparency = 0.3

Title.Name = "Title"
Title.Parent = LoadingFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0.2, -25, 0.3, 20)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "PHUCMAXTONGHOP"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextStrokeTransparency = 0.5
Title.TextSize = 30

ProgressBarBackground.Parent = LoadingFrame
ProgressBarBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ProgressBarBackground.Position = UDim2.new(0.1, 0, 0.8, 0)
ProgressBarBackground.Size = UDim2.new(0.8, 0, 0.08, 0)
ProgressBarBackground.BorderSizePixel = 0

local UICorner2 = Instance.new("UICorner", ProgressBarBackground)
UICorner2.CornerRadius = UDim.new(0, 6)

ProgressBar.Parent = ProgressBarBackground
ProgressBar.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BorderSizePixel = 0

local UICorner3 = Instance.new("UICorner", ProgressBar)
UICorner3.CornerRadius = UDim.new(0, 6)

task.spawn(function()
    for i = 1, 100 do
        ProgressBar.Size = UDim2.new(i/100, 0, 1, 0)
        local red = 100 + (155 * (i / 100))
        ProgressBar.BackgroundColor3 = Color3.fromRGB(red, 0, 0)
        task.wait(0.02)
    end

    local CaliText = Instance.new("TextLabel")
    CaliText.Parent = ScreenGui
    CaliText.Text = "CALI CON CARD"
    CaliText.Size = UDim2.new(1, 0, 0, 60)
    CaliText.Position = UDim2.new(0.5, 0, 0.5, 100)
    CaliText.AnchorPoint = Vector2.new(0.5, 0.5)
    CaliText.BackgroundTransparency = 1
    CaliText.Font = Enum.Font.GothamBlack
    CaliText.TextColor3 = Color3.fromRGB(255, 0, 0)
    CaliText.TextStrokeTransparency = 0.4
    CaliText.TextSize = 36

    wait(1)
    CaliText:Destroy()

    ScreenGui:Destroy()

    loadstring(game:HttpGet("https://raw.githubusercontent.com/phucmax/Nhincccc/refs/heads/main/script%20nha%20lam.lua"))()
end)