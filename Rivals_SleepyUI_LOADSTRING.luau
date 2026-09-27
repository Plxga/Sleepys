--[[
  RIVALS — SleepyUI Loadstring (standalone)
  Uso:
    loadstring(game:HttpGet("URL"))()
    o pegar todo el contenido en el executor / Command Bar (Studio)

  Basado en el fragmento de SleepyLibrary.lua proporcionado.
  Versión mínima funcional + ejemplo de GUI para Rivals.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local InputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

-- ====================== LIBRARY CORE ======================

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)
ScreenGui.Name = "SleepyUI_Rivals"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or CoreGui

local Toggles = {}
local Options = {}
getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
    Registry = {},
    RegistryMap = {},
    HudRegistry = {},
    FontColor = Color3.fromRGB(255, 255, 255),
    MainColor = Color3.fromRGB(28, 28, 28),
    BackgroundColor = Color3.fromRGB(20, 20, 20),
    AccentColor = Color3.fromRGB(0, 85, 255),
    OutlineColor = Color3.fromRGB(50, 50, 50),
    RiskColor = Color3.fromRGB(255, 50, 50),
    Black = Color3.new(0, 0, 0),
    Font = Enum.Font.Code,
    OpenedFrames = {},
    DependencyBoxes = {},
    Signals = {},
    ScreenGui = ScreenGui,
    NotifyOnError = true,
}

Library.AccentColorDark = Color3.fromHSV(select(1, Color3.toHSV(Library.AccentColor)), select(2, Color3.toHSV(Library.AccentColor)), select(3, Color3.toHSV(Library.AccentColor)) / 1.5)

-- Rainbow
local RainbowStep, Hue = 0, 0
table.insert(Library.Signals, RenderStepped:Connect(function(dt)
    RainbowStep = RainbowStep + dt
    if RainbowStep >= 1/60 then
        RainbowStep = 0
        Hue = Hue + 1/400
        if Hue > 1 then Hue = 0 end
        Library.CurrentRainbowHue = Hue
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
    end
end))

function Library:SafeCallback(f, ...)
    if not f then return end
    if not Library.NotifyOnError then
        return f(...)
    end
    local ok, err = pcall(f, ...)
    if not ok then
        local _, i = tostring(err):find(":%d+: ")
        Library:Notify(i and tostring(err):sub(i + 1) or tostring(err), 3)
    end
end

function Library:Create(Class, Properties)
    local inst = type(Class) == "string" and Instance.new(Class) or Class
    for k, v in pairs(Properties or {}) do
        inst[k] = v
    end
    return inst
end

function Library:ApplyTextStroke(Inst)
    Inst.TextStrokeTransparency = 1
    Library:Create("UIStroke", {
        Color = Color3.new(0, 0, 0),
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = Inst,
    })
end

function Library:CreateLabel(Properties, IsHud)
    local label = Library:Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextColor3 = Library.FontColor,
        TextSize = 16,
        TextStrokeTransparency = 0,
    })
    Library:ApplyTextStroke(label)
    Library:AddToRegistry(label, { TextColor3 = "FontColor" }, IsHud)
    return Library:Create(label, Properties)
end

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true
    Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(Mouse.X - Instance.AbsolutePosition.X, Mouse.Y - Instance.AbsolutePosition.Y)
            if ObjPos.Y > (Cutoff or 40) then return end
            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0, Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0, Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                )
                RenderStepped:Wait()
            end
        end
    end)
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color)
    return Color3.fromHSV(H, S, V / 1.5)
end

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Data = { Instance = Instance, Properties = Properties }
    table.insert(Library.Registry, Data)
    Library.RegistryMap[Instance] = Data
    if IsHud then
        table.insert(Library.HudRegistry, Data)
    end
end

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance]
    if not Data then return end
    for i = #Library.Registry, 1, -1 do
        if Library.Registry[i] == Data then
            table.remove(Library.Registry, i)
        end
    end
    Library.RegistryMap[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for _, Object in ipairs(Library.Registry) do
        for Property, ColorIdx in pairs(Object.Properties) do
            if type(ColorIdx) == "string" then
                Object.Instance[Property] = Library[ColorIdx]
            elseif type(ColorIdx) == "function" then
                Object.Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:GiveSignal(Signal)
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    for i = #Library.Signals, 1, -1 do
        local c = table.remove(Library.Signals, i)
        if c and c.Disconnect then pcall(c.Disconnect, c) end
    end
    if Library.OnUnload then pcall(Library.OnUnload) end
    ScreenGui:Destroy()
end

function Library:OnUnload(cb)
    Library.OnUnload = cb
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(inst)
    if Library.RegistryMap[inst] then
        Library:RemoveFromRegistry(inst)
    end
end))

-- Notifications
local NotifyContainer = Library:Create("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 280, 1, 0),
    Position = UDim2.new(1, -290, 0, 10),
    Parent = ScreenGui,
})
Library:Create("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Parent = NotifyContainer,
})

function Library:Notify(Text, Time)
    Time = Time or 3
    local Frame = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = NotifyContainer,
    })
    Library:AddToRegistry(Frame, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })

    local Label = Library:CreateLabel({
        Text = tostring(Text),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(6, 6),
        Parent = Frame,
    })
    Library:Create("UIPadding", { PaddingBottom = UDim.new(0, 6), Parent = Frame })

    task.delay(Time, function()
        if Frame and Frame.Parent then
            Frame:Destroy()
        end
    end)
end

-- ====================== WINDOW / TABS / GROUPBOX ======================

function Library:CreateWindow(Title)
    local Window = {
        Tabs = {},
        CurrentTab = nil,
    }

    local Outer = Library:Create("Frame", {
        BackgroundColor3 = Library.OutlineColor,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(100, 100),
        Size = UDim2.fromOffset(560, 420),
        Parent = ScreenGui,
    })
    Library:MakeDraggable(Outer, 40)

    local Inner = Library:Create("Frame", {
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        Parent = Outer,
    })
    Library:AddToRegistry(Inner, { BackgroundColor3 = "BackgroundColor" })

    -- Title bar
    local TitleBar = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = Inner,
    })
    Library:AddToRegistry(TitleBar, { BackgroundColor3 = "MainColor" })

    local TitleLabel = Library:CreateLabel({
        Text = Title or "Rivals — SleepyUI",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Parent = TitleBar,
    })

    -- Close button
    local CloseBtn = Library:CreateLabel({
        Text = "×",
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(1, -32, 0, 0),
        Size = UDim2.fromOffset(32, 32),
        Parent = TitleBar,
    })
    CloseBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Library:Unload()
        end
    end)

    -- Accent line
    Library:Create("Frame", {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -2),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TitleBar,
    })

    -- Tab buttons container
    local TabButtons = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = Inner,
    })
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabButtons,
    })
    Library:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        Parent = TabButtons,
    })

    -- Content area
    local Content = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 66),
        Size = UDim2.new(1, 0, 1, -70),
        Parent = Inner,
    })

    function Window:AddTab(Name)
        local Tab = {
            Name = Name,
            Groupboxes = {},
            Container = nil,
            Button = nil,
        }

        local Btn = Library:CreateLabel({
            Text = Name,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromOffset(90, 24),
            BackgroundTransparency = 0,
            BackgroundColor3 = Library.MainColor,
            Parent = TabButtons,
        })
        Library:AddToRegistry(Btn, { BackgroundColor3 = "MainColor", TextColor3 = "FontColor" })
        Library:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })

        local Container = Library:Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            Visible = false,
            Parent = Content,
        })
        Library:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Container,
        })
        Library:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6),
            Parent = Container,
        })

        Tab.Button = Btn
        Tab.Container = Container

        local function Select()
            for _, t in ipairs(Window.Tabs) do
                t.Container.Visible = false
                t.Button.BackgroundColor3 = Library.MainColor
                if Library.RegistryMap[t.Button] then
                    Library.RegistryMap[t.Button].Properties.BackgroundColor3 = "MainColor"
                end
            end
            Container.Visible = true
            Btn.BackgroundColor3 = Library.AccentColor
            if Library.RegistryMap[Btn] then
                Library.RegistryMap[Btn].Properties.BackgroundColor3 = "AccentColor"
            end
            Window.CurrentTab = Tab
        end

        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Select()
            end
        end)

        function Tab:AddGroupbox(TitleText)
            local Group = {
                Container = nil,
            }

            local OuterG = Library:Create("Frame", {
                BackgroundColor3 = Library.OutlineColor,
                BorderSizePixel = 0,
                Size = UDim2.new(1, -4, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = Container,
            })

            local InnerG = Library:Create("Frame", {
                BackgroundColor3 = Library.MainColor,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(1, 1),
                Size = UDim2.new(1, -2, 1, -2),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = OuterG,
            })
            Library:AddToRegistry(InnerG, { BackgroundColor3 = "MainColor" })

            local TitleG = Library:CreateLabel({
                Text = TitleText or "Group",
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -10, 0, 22),
                Position = UDim2.fromOffset(8, 4),
                Parent = InnerG,
            })

            local Holder = Library:Create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 28),
                Size = UDim2.new(1, -12, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = InnerG,
            })
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Holder,
            })
            Library:Create("UIPadding", {
                PaddingBottom = UDim.new(0, 8),
                Parent = Holder,
            })

            Group.Container = Holder

            function Group:AddLabel(Text)
                local L = Library:CreateLabel({
                    Text = Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 18),
                    Parent = Holder,
                })
                return L
            end

            function Group:AddToggle(Idx, Info)
                Info = Info or {}
                local Toggle = {
                    Value = Info.Default or false,
                    Type = "Toggle",
                    Callback = Info.Callback or function() end,
                }

                local Row = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    Parent = Holder,
                })

                local Box = Library:Create("Frame", {
                    BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderSizePixel = 1,
                    Size = UDim2.fromOffset(18, 18),
                    Position = UDim2.fromOffset(0, 2),
                    Parent = Row,
                })
                Library:AddToRegistry(Box, {
                    BackgroundColor3 = function()
                        return Toggle.Value and Library.AccentColor or Library.BackgroundColor
                    end,
                    BorderColor3 = "OutlineColor",
                })

                local TextL = Library:CreateLabel({
                    Text = Info.Text or Idx,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.fromOffset(26, 0),
                    Size = UDim2.new(1, -30, 1, 0),
                    Parent = Row,
                })

                function Toggle:SetValue(v)
                    Toggle.Value = not not v
                    Box.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.BackgroundColor
                    Library:SafeCallback(Toggle.Callback, Toggle.Value)
                end

                function Toggle:OnChanged(cb)
                    Toggle.Callback = cb
                end

                Row.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Toggle:SetValue(not Toggle.Value)
                    end
                end)

                Toggles[Idx] = Toggle
                return Toggle
            end

            function Group:AddButton(Text, Callback)
                local BtnFrame = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderSizePixel = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    Parent = Holder,
                })
                Library:AddToRegistry(BtnFrame, {
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                })

                local BtnLabel = Library:CreateLabel({
                    Text = Text or "Button",
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.new(1, 0, 1, 0),
                    Parent = BtnFrame,
                })

                BtnFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Library:SafeCallback(Callback)
                    end
                end)

                return BtnFrame
            end

            function Group:AddSlider(Idx, Info)
                Info = Info or {}
                local Slider = {
                    Value = Info.Default or 0,
                    Min = Info.Min or 0,
                    Max = Info.Max or 100,
                    Rounding = Info.Rounding or 0,
                    Type = "Slider",
                    Callback = Info.Callback or function() end,
                }

                local Row = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 40),
                    Parent = Holder,
                })

                local TitleS = Library:CreateLabel({
                    Text = (Info.Text or Idx) .. ": " .. tostring(Slider.Value),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = Row,
                })

                local Track = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderSizePixel = 1,
                    Position = UDim2.fromOffset(0, 20),
                    Size = UDim2.new(1, 0, 0, 14),
                    Parent = Row,
                })
                Library:AddToRegistry(Track, {
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                })

                local Fill = Library:Create("Frame", {
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    Parent = Track,
                })
                Library:AddToRegistry(Fill, { BackgroundColor3 = "AccentColor" })

                local function Update(val)
                    val = math.clamp(val, Slider.Min, Slider.Max)
                    if Slider.Rounding > 0 then
                        local mult = 10 ^ Slider.Rounding
                        val = math.floor(val * mult + 0.5) / mult
                    else
                        val = math.floor(val)
                    end
                    Slider.Value = val
                    local pct = (val - Slider.Min) / (Slider.Max - Slider.Min)
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    TitleS.Text = (Info.Text or Idx) .. ": " .. tostring(val)
                    Library:SafeCallback(Slider.Callback, val)
                end

                function Slider:SetValue(v)
                    Update(v)
                end

                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                            local rel = math.clamp((Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                            Update(Slider.Min + (Slider.Max - Slider.Min) * rel)
                            RenderStepped:Wait()
                        end
                    end
                end)

                Update(Slider.Value)
                Options[Idx] = Slider
                return Slider
            end

            function Group:AddDropdown(Idx, Info)
                Info = Info or {}
                local Dropdown = {
                    Value = Info.Default or (Info.Values and Info.Values[1]) or "",
                    Values = Info.Values or {},
                    Type = "Dropdown",
                    Callback = Info.Callback or function() end,
                }

                local Row = Library:Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 44),
                    Parent = Holder,
                })

                Library:CreateLabel({
                    Text = Info.Text or Idx,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 16),
                    Parent = Row,
                })

                local Box = Library:Create("Frame", {
                    BackgroundColor3 = Library.BackgroundColor,
                    BorderColor3 = Library.OutlineColor,
                    BorderSizePixel = 1,
                    Position = UDim2.fromOffset(0, 18),
                    Size = UDim2.new(1, 0, 0, 22),
                    Parent = Row,
                })
                Library:AddToRegistry(Box, {
                    BackgroundColor3 = "BackgroundColor",
                    BorderColor3 = "OutlineColor",
                })

                local ValLabel = Library:CreateLabel({
                    Text = tostring(Dropdown.Value),
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Position = UDim2.fromOffset(6, 0),
                    Size = UDim2.new(1, -12, 1, 0),
                    Parent = Box,
                })

                function Dropdown:SetValue(v)
                    Dropdown.Value = v
                    ValLabel.Text = tostring(v)
                    Library:SafeCallback(Dropdown.Callback, v)
                end

                -- Simple cycle on click
                Box.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local idx = table.find(Dropdown.Values, Dropdown.Value) or 0
                        idx = idx % #Dropdown.Values + 1
                        Dropdown:SetValue(Dropdown.Values[idx])
                    end
                end)

                Options[Idx] = Dropdown
                return Dropdown
            end

            table.insert(Tab.Groupboxes, Group)
            return Group
        end

        -- aliases
        Tab.AddLeftGroupbox = Tab.AddGroupbox
        Tab.AddRightGroupbox = Tab.AddGroupbox

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            Select()
        end
        return Tab
    end

    return Window
end

-- ====================== RIVALS DEMO UI ======================

local Window = Library:CreateWindow("Rivals — SleepyUI")

local MainTab = Window:AddTab("Main")
local VisualsTab = Window:AddTab("Visuals")
local MiscTab = Window:AddTab("Misc")
local SettingsTab = Window:AddTab("Settings")

-- Main
local Combat = MainTab:AddGroupbox("Combat (Demo)")
Combat:AddToggle("Aimbot", {
    Text = "Aimbot (demo)",
    Default = false,
    Callback = function(v)
        Library:Notify("Aimbot: " .. tostring(v))
    end,
})
Combat:AddSlider("AimFOV", {
    Text = "FOV",
    Default = 80,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(v) end,
})
Combat:AddDropdown("AimPart", {
    Text = "Target Part",
    Values = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head",
    Callback = function(v)
        Library:Notify("Target: " .. v)
    end,
})
Combat:AddButton("Reset Config", function()
    if Toggles.Aimbot then Toggles.Aimbot:SetValue(false) end
    if Options.AimFOV then Options.AimFOV:SetValue(80) end
    Library:Notify("Config reset")
end)

local Movement = MainTab:AddGroupbox("Movement")
Movement:AddToggle("Speed", {
    Text = "Speed Boost (demo)",
    Default = false,
    Callback = function(v)
        Library:Notify("Speed: " .. tostring(v))
    end,
})
Movement:AddSlider("SpeedValue", {
    Text = "Speed Multiplier",
    Default = 16,
    Min = 16,
    Max = 50,
    Rounding = 0,
})

-- Visuals
local ESPBox = VisualsTab:AddGroupbox("ESP")
ESPBox:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        Library:Notify("ESP: " .. tostring(v))
    end,
})
ESPBox:AddToggle("ESPBoxes", { Text = "Boxes", Default = true })
ESPBox:AddToggle("ESPNames", { Text = "Names", Default = true })
ESPBox:AddToggle("ESPTracers", { Text = "Tracers", Default = false })
ESPBox:AddSlider("ESPDistance", {
    Text = "Max Distance",
    Default = 500,
    Min = 50,
    Max = 2000,
    Rounding = 0,
})

-- Misc
local Info = MiscTab:AddGroupbox("Info")
Info:AddLabel("PlaceId: " .. tostring(game.PlaceId))
Info:AddLabel("JobId: " .. tostring(game.JobId))
Info:AddLabel("Player: " .. LocalPlayer.Name)
Info:AddButton("Copy JobId", function()
    if setclipboard then
        setclipboard(tostring(game.JobId))
        Library:Notify("JobId copied")
    else
        Library:Notify("setclipboard not available")
    end
end)
Info:AddButton("Print Players", function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(list, p.Name)
    end
    print(table.concat(list, ", "))
    Library:Notify(#list .. " players printed to console")
end)

-- Settings
local Theme = SettingsTab:AddGroupbox("Theme")
Theme:AddButton("Accent Blue", function()
    Library.AccentColor = Color3.fromRGB(0, 85, 255)
    Library:UpdateColorsUsingRegistry()
end)
Theme:AddButton("Accent Red", function()
    Library.AccentColor = Color3.fromRGB(255, 50, 50)
    Library:UpdateColorsUsingRegistry()
end)
Theme:AddButton("Accent Green", function()
    Library.AccentColor = Color3.fromRGB(50, 200, 80)
    Library:UpdateColorsUsingRegistry()
end)
Theme:AddButton("Accent Purple", function()
    Library.AccentColor = Color3.fromRGB(160, 60, 255)
    Library:UpdateColorsUsingRegistry()
end)

local UnloadBox = SettingsTab:AddGroupbox("Unload")
UnloadBox:AddButton("Unload UI", function()
    Library:Unload()
end)

Library:Notify("Rivals SleepyUI loaded", 4)

print("[SleepyUI] Rivals script loaded successfully")
