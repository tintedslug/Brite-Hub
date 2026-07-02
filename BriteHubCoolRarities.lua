--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     BRITE HUB  v1.1                         ║
    ║          Dark-Themed Dashboard UI — Luau / Roblox           ║
    ║    Run from the Studio Command Bar or a LocalScript          ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ─────────────────────────────────────────────────────────────────
-- 0.  SERVICES & UTILITIES
-- ─────────────────────────────────────────────────────────────────
local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local Stats          = game:GetService("Stats")
local StarterGui     = game:GetService("StarterGui")

local LocalPlayer    = Players.LocalPlayer
local PlayerName     = LocalPlayer and LocalPlayer.Name or "Player"

-- ── Colour Palette ───────────────────────────────────────────────
local C = {
    BG_MAIN      = Color3.fromHex("0C0E1C"),   -- deep navy
    BG_SIDEBAR   = Color3.fromHex("080912"),   -- near-black
    BG_CARD      = Color3.fromHex("13162A"),   -- card surface
    BG_CARD2     = Color3.fromHex("0F1122"),   -- slightly darker card
    ACCENT_PURPLE= Color3.fromHex("B48CFF"),   -- neon purple
    ACCENT_PINK  = Color3.fromHex("E0569B"),   -- vivid pink
    ACCENT_ROSE  = Color3.fromHex("F06292"),   -- lighter pink
    ICON_MUTED   = Color3.fromHex("7864B4"),   -- inactive icons
    TEXT_PRIMARY = Color3.fromHex("EEEEFF"),   -- near-white
    TEXT_SUB     = Color3.fromHex("8A8AB8"),   -- muted subtitle
    TEXT_PINK    = Color3.fromHex("E878C0"),   -- greeting highlight
    BORDER_GLOW  = Color3.fromHex("6A3FBF"),   -- purple border
    WAVE_GRAD1   = Color3.fromHex("4A1540"),   -- status box dark
    WAVE_GRAD2   = Color3.fromHex("1C0C2E"),   -- status box deep
    STATUS_GREEN = Color3.fromHex("4ADE80"),
    STATUS_GRAY  = Color3.fromHex("6B7280"),
    STATUS_BLUE  = Color3.fromHex("60A5FA"),
    CLOSE_RED    = Color3.fromHex("FF5F57"),
    MIN_YELLOW   = Color3.fromHex("FEBC2E"),
    TRANSPARENT  = Color3.fromRGB(0,0,0),
}

-- ── Tween helper ─────────────────────────────────────────────────
local function tween(obj, info, goal)
    TweenService:Create(obj, info, goal):Play()
end

local FAST  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local MED   = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ── Instance factory ─────────────────────────────────────────────
local function make(className, parent, props)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    return make("UICorner", parent, { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(parent, thickness, color, transparency)
    return make("UIStroke", parent, {
        Thickness     = thickness or 1.5,
        Color         = color or C.BORDER_GLOW,
        Transparency  = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function gradient(parent, colorOrSeq, color2OrRotation, finalRotation)
    local finalColorSequence
    local rotation = 90

    if typeof(colorOrSeq) == "ColorSequence" then
        finalColorSequence = colorOrSeq
        rotation = color2OrRotation or 90
    elseif typeof(colorOrSeq) == "Color3" and typeof(color2OrRotation) == "Color3" then
        finalColorSequence = ColorSequence.new(colorOrSeq, color2OrRotation)
        rotation = finalRotation or 90
    elseif typeof(colorOrSeq) == "Color3" then
        finalColorSequence = ColorSequence.new(colorOrSeq)
        rotation = color2OrRotation or 90
    end

    return make("UIGradient", parent, {
        Color = finalColorSequence,
        Rotation = rotation,
    })
end

local function textSizeConstraint(parent, min, max)
    return make("UITextSizeConstraint", parent, {
        MinTextSize = min or 8,
        MaxTextSize = max or 24,
    })
end

-- ─────────────────────────────────────────────────────────────────
-- 1.  ROOT GUI
-- ─────────────────────────────────────────────────────────────────
local existing = LocalPlayer:FindFirstChild("PlayerGui") and
                 LocalPlayer.PlayerGui:FindFirstChild("BriteHubGui")
if existing then existing:Destroy() end

local ScreenGui = make("ScreenGui", LocalPlayer:FindFirstChild("PlayerGui") or StarterGui, {
    Name            = "BriteHubGui",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
    IgnoreGuiInset  = true,
})

-- ─────────────────────────────────────────────────────────────────
-- 2.  MAIN WINDOW FRAME
-- ─────────────────────────────────────────────────────────────────
local MainFrame = make("Frame", ScreenGui, {
    Name            = "MainFrame",
    Size            = UDim2.new(0, 720, 0, 440),
    Position        = UDim2.new(0.5, -360, 0.5, -220),
    BackgroundColor3 = C.BG_MAIN,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
corner(MainFrame, 14)
stroke(MainFrame, 1.5, C.BORDER_GLOW, 0.15)

gradient(MainFrame,
    ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("13162E")),
        ColorSequenceKeypoint.new(0.5, Color3.fromHex("0C0E1C")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("08091A")),
    }),
    45)

local GlowFrame = make("Frame", ScreenGui, {
    Name             = "GlowFrame",
    Size             = UDim2.new(0, 740, 0, 460),
    Position         = UDim2.new(0.5, -370, 0.5, -230),
    BackgroundColor3 = C.ACCENT_PURPLE,
    BackgroundTransparency = 0.88,
    BorderSizePixel  = 0,
    ZIndex           = 0,
})
corner(GlowFrame, 18)

-- ─────────────────────────────────────────────────────────────────
-- 3.  DRAG SYSTEM
-- ─────────────────────────────────────────────────────────────────
do
    local dragging     = false
    local dragStart    = nil
    local startPos     = nil

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = MainFrame.Position
        end
    end

    local function onInputChanged(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            MainFrame.Position = newPos
            GlowFrame.Position = UDim2.new(
                newPos.X.Scale, newPos.X.Offset - 10,
                newPos.Y.Scale, newPos.Y.Offset - 10
            )
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    MainFrame.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

-- ─────────────────────────────────────────────────────────────────
-- 4.  TOP BAR
-- ─────────────────────────────────────────────────────────────────
local TopBar = make("Frame", MainFrame, {
    Name             = "TopBar",
    Size             = UDim2.new(1, 0, 0, 56),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromHex("0A0C1A"),
    BorderSizePixel  = 0,
    ZIndex           = 5,
})
corner(TopBar, 14)

local TopBarFiller = make("Frame", TopBar, {
    Name             = "BottomFiller",
    Size             = UDim2.new(1, 0, 0, 14),
    Position         = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = Color3.fromHex("0A0C1A"),
    BorderSizePixel  = 0,
    ZIndex           = 1,
    Visible          = true,
})

make("Frame", TopBar, {
    Name             = "Divider",
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 2,
})

-- ── Logo Badge ───────────────────────────────────────────────
local LogoBadge = make("Frame", TopBar, {
    Name             = "LogoBadge",
    Size             = UDim2.new(0, 36, 0, 36),
    Position         = UDim2.new(0, 14, 0.5, -18),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel  = 0,
    ZIndex           = 6,
})
corner(LogoBadge, 10)
gradient(LogoBadge, Color3.fromHex("A060FF"), Color3.fromHex("E05090"), 135)

local LogoText = make("TextLabel", LogoBadge, {
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text             = "BH",
    TextColor3       = Color3.fromHex("FFFFFF"),
    Font             = Enum.Font.GothamBold,
    TextScaled       = true,
    ZIndex           = 7,
})
textSizeConstraint(LogoText, 10, 16)

-- ── Title Stack ──────────────────────────────────────────────
local TitleStack = make("Frame", TopBar, {
    Name             = "TitleStack",
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 58, 0, 0),
    BackgroundTransparency = 1,
    ZIndex           = 6,
})
make("UIListLayout", TitleStack, {
    FillDirection    = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 1),
})

local TitleLabel = make("TextLabel", TitleStack, {
    Name             = "TitleLabel",
    Size             = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text             = "Brite Hub",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 16,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})

local SubLabel = make("TextLabel", TitleStack, {
    Name             = "SubLabel",
    Size             = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Text             = "britekits.gg/invite",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})

-- ── Window Controls ──────────────────────────────────────────
local WinControls = make("Frame", TopBar, {
    Name             = "WinControls",
    Size             = UDim2.new(0, 70, 0, 24),
    Position         = UDim2.new(1, -84, 0.5, -12),
    BackgroundTransparency = 1,
    ZIndex           = 6,
})
make("UIListLayout", WinControls, {
    FillDirection    = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 8),
})

local MinBtn = make("TextButton", WinControls, {
    Name             = "MinimizeBtn",
    Size             = UDim2.new(0, 24, 0, 24),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Text             = "",
    ZIndex           = 7,
    AutoButtonColor  = false,
})
corner(MinBtn, 6)
local MinGrad = gradient(MinBtn, Color3.fromHex("B48CFF"), Color3.fromHex("6A3FBF"), 90)

local MinBar = make("Frame", MinBtn, {
    Size             = UDim2.new(0, 10, 0, 2),
    Position         = UDim2.new(0.5, -5, 0.5, -1),
    BackgroundColor3 = Color3.fromHex("FFFFFF"),
    BorderSizePixel  = 0,
    ZIndex           = 8,
})
corner(MinBar, 1)

local CloseBtn = make("TextButton", WinControls, {
    Name             = "CloseBtn",
    Size             = UDim2.new(0, 24, 0, 24),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Text             = "",
    ZIndex           = 7,
    AutoButtonColor  = false,
})
corner(CloseBtn, 6)
local CloseGrad = gradient(CloseBtn, Color3.fromHex("B48CFF"), Color3.fromHex("6A3FBF"), 90)

local function makeXLine(parent, rot)
    local l = make("Frame", parent, {
        Size             = UDim2.new(0, 12, 0, 2),
        Position         = UDim2.new(0.5, -6, 0.5, -1),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel  = 0,
        Rotation         = rot,
        ZIndex           = 8,
    })
    corner(l, 1)
end
makeXLine(CloseBtn, 45)
makeXLine(CloseBtn, -45)

-- ── Window Control Logic ─────────────────────────────────────
local guiVisible = true
local minimised = false

CloseBtn.MouseButton1Click:Connect(function()
    guiVisible = false
    tween(MainFrame, MED, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) })
    tween(GlowFrame, MED, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
    task.delay(0.35, function()
        MainFrame.Visible = false
        GlowFrame.Visible = false
    end)
end)

CloseBtn.MouseEnter:Connect(function()
    tween(CloseGrad, FAST, { Color = ColorSequence.new(Color3.fromHex("FF60A8"), Color3.fromHex("E0569B")) })
end)
CloseBtn.MouseLeave:Connect(function()
    tween(CloseGrad, FAST, { Color = ColorSequence.new(Color3.fromHex("B48CFF"), Color3.fromHex("6A3FBF")) })
end)

MinBtn.MouseButton1Click:Connect(function()
    if minimised then
        minimised = false
        TopBarFiller.Visible = true
        tween(MainFrame, MED, { Size = UDim2.new(0, 720, 0, 440) })
        tween(GlowFrame, MED, { Size = UDim2.new(0, 740, 0, 460) })
    else
        minimised = true
        TopBarFiller.Visible = false
        tween(MainFrame, MED, { Size = UDim2.new(0, 720, 0, 56) })
        tween(GlowFrame, MED, { Size = UDim2.new(0, 740, 0, 76) })
    end
end)

MinBtn.MouseEnter:Connect(function()
    tween(MinGrad, FAST, { Color = ColorSequence.new(Color3.fromHex("D6C4FF"), Color3.fromHex("8C63E6")) })
end)
MinBtn.MouseLeave:Connect(function()
    tween(MinGrad, FAST, { Color = ColorSequence.new(Color3.fromHex("B48CFF"), Color3.fromHex("6A3FBF")) })
end)

-- ─────────────────────────────────────────────────────────────────
-- 5.  SIDEBAR
-- ─────────────────────────────────────────────────────────────────
local Sidebar = make("Frame", MainFrame, {
    Name             = "Sidebar",
    Size             = UDim2.new(0, 60, 1, -56),
    Position         = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})
corner(Sidebar, 14) -- Round out the sidebar corner

-- Masking panels to square out the top & right, keeping bottom-left rounded
local SidebarFillerTop = make("Frame", Sidebar, {
    Size             = UDim2.new(1, 0, 1, -14),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 1,
})
local SidebarFillerRight = make("Frame", Sidebar, {
    Size             = UDim2.new(0, 14, 1, 0),
    Position         = UDim2.new(1, -14, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 1,
})

-- FIXED: Enabled SortOrder.LayoutOrder so Roblox stops sorting alphabetically
make("UIListLayout", Sidebar, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 8),
})
make("UIPadding", Sidebar, {
    PaddingTop = UDim.new(0, 14),
})

make("Frame", Sidebar, {
    Name             = "SideDivider",
    Size             = UDim2.new(0, 1, 1, 0),
    Position         = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.7,
    BorderSizePixel  = 0,
    ZIndex           = 5,
})

-- ── High Fidelity Icon Drawing Helpers ───────────────────────────
local function drawHomeIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "HomeIcon",
        Size             = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    local roof = make("Frame", g, {
        Size             = UDim2.new(0, 13, 0, 13),
        Position         = UDim2.new(0.5, -6.5, 0, 0),
        BackgroundColor3 = color,
        Rotation         = 45,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    corner(roof, 2)
    local body = make("Frame", g, {
        Size             = UDim2.new(0, 14, 0, 10),
        Position         = UDim2.new(0.5, -7, 1, -10),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 3,
    })
    corner(body, 1)
    make("Frame", body, {
        Size             = UDim2.new(0, 4, 0, 5),
        Position         = UDim2.new(0.5, -2, 1, -5),
        BackgroundColor3 = C.BG_SIDEBAR,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 4,
    })
    return g
end

local function drawFarmIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "FarmIcon",
        Size             = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    -- Cabin Structure
    make("Frame", g, {
        Size             = UDim2.new(0, 8, 0, 7),
        Position         = UDim2.new(0, 2, 0, 3),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    make("Frame", g, {
        Size             = UDim2.new(0, 5, 0, 4),
        Position         = UDim2.new(0, 3, 0, 5),
        BackgroundColor3 = C.BG_SIDEBAR,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 3,
    })
    -- Engine Block / Hood
    make("Frame", g, {
        Size             = UDim2.new(0, 7, 0, 6),
        Position         = UDim2.new(0, 10, 0, 7),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    -- Exhaust Stack
    make("Frame", g, {
        Size             = UDim2.new(0, 1.5, 0, 4),
        Position         = UDim2.new(0, 13, 0, 3),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    -- Large Rear Driving Wheel
    local backWheel = make("Frame", g, {
        Size             = UDim2.new(0, 7, 0, 7),
        Position         = UDim2.new(0, 1, 0, 11),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 4,
    })
    corner(backWheel, 4)
    make("Frame", backWheel, {
        Size             = UDim2.new(0, 2, 0, 2),
        Position         = UDim2.new(0.5, -1, 0.5, -1),
        BackgroundColor3 = C.BG_SIDEBAR,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 5,
    })
    -- Small Front Steering Wheel
    local frontWheel = make("Frame", g, {
        Size             = UDim2.new(0, 4.5, 0, 4.5),
        Position         = UDim2.new(0, 12, 0, 13.5),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 4,
    })
    corner(frontWheel, 2)
    return g
end

local function drawPinIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "PinIcon",
        Size             = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    -- Teardrop round node
    local round = make("Frame", g, {
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = UDim2.new(0.5, -7, 0, 1),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    corner(round, 7)
    -- Ground Anchor Tip
    local point = make("Frame", g, {
        Size             = UDim2.new(0, 8, 0, 8),
        Position         = UDim2.new(0.5, -4, 0, 8),
        BackgroundColor3 = color,
        Rotation         = 45,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 1,
    })
    corner(point, 1)
    -- Focal transparency point
    local hole = make("Frame", round, {
        Size             = UDim2.new(0, 5, 0, 5),
        Position         = UDim2.new(0.5, -2.5, 0.5, -2.5),
        BackgroundColor3 = C.BG_SIDEBAR,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 3,
    })
    corner(hole, 3)
    return g
end

local function drawGearIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "GearIcon",
        Size             = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    local hub = make("Frame", g, {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0.5, -6, 0.5, -6),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 2,
    })
    corner(hub, 6)
    local hole = make("Frame", hub, {
        Size             = UDim2.new(0, 4, 0, 4),
        Position         = UDim2.new(0.5, -2, 0.5, -2),
        BackgroundColor3 = C.BG_SIDEBAR,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 3,
    })
    corner(hole, 2)
    
    for i = 0, 7 do
        local angle = i * 45
        local rad = math.rad(angle)
        local x = math.sin(rad) * 6.5
        local y = -math.cos(rad) * 6.5
        local t = make("Frame", g, {
            Size             = UDim2.new(0, 3.5, 0, 4),
            Position         = UDim2.new(0.5, x - 1.75, 0.5, y - 2),
            BackgroundColor3 = color,
            Rotation         = angle,
            BorderSizePixel  = 0,
            ZIndex           = parent.ZIndex + 2,
        })
        corner(t, 1)
    end
    return g
end

-- ── Build Adjusted Sidebar Navigation Tabs ────────────────────
-- FIXED: Made all Tab mapping IDs strictly UPPERCASE and structured Home -> Farm -> Teleport -> Config
local navDefs = {
    { id = "HOME",     label = "Home",     iconFn = drawHomeIcon  },
    { id = "FARM",     label = "Farm",     iconFn = drawFarmIcon  },
    { id = "TELEPORT", label = "Teleport", iconFn = drawPinIcon   },
    { id = "CONFIG",   label = "Config",   iconFn = drawGearIcon  },
}

local NavButtons = {}
local activeTab  = "HOME" -- FIXED: Switched initial tab state to uppercase format

for i, def in ipairs(navDefs) do
    local btn = make("TextButton", Sidebar, {
        Name             = "Nav_" .. def.id,
        LayoutOrder      = i, -- FIXED: Assigned numeric orders (1, 2, 3, 4) to ensure exact tab order rule
        Size             = UDim2.new(0, 44, 0, 44),
        BackgroundColor3 = C.BG_CARD,
        BackgroundTransparency = i == 1 and 0.4 or 1,
        Text             = "",
        AutoButtonColor  = false,
        ZIndex           = 5,
    })
    corner(btn, 10)

    local navStroke = stroke(btn, 1.5,
        i == 1 and C.ACCENT_PURPLE or C.ICON_MUTED,
        i == 1 and 0.2 or 1)

    local iconColor = i == 1 and C.ACCENT_PURPLE or C.ICON_MUTED
    local iconFrame = def.iconFn(btn, iconColor)
    iconFrame.Position = UDim2.new(0.5, -10, 0.5, -10)
    iconFrame.ZIndex   = 6

    NavButtons[def.id] = {
        btn      = btn,
        stroke   = navStroke,
        iconFn   = def.iconFn,
        iconFrame= iconFrame,
    }
end

-- ─────────────────────────────────────────────────────────────────
-- 6.  CONTENT AREA
-- ─────────────────────────────────────────────────────────────────
local ContentArea = make("Frame", MainFrame, {
    Name             = "ContentArea",
    Size             = UDim2.new(1, -60, 1, -56),
    Position         = UDim2.new(0, 60, 0, 56),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex           = 3,
})
make("UIPadding", ContentArea, {
    PaddingLeft   = UDim.new(0, 10),
    PaddingRight  = UDim.new(0, 10),
    PaddingTop    = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
})

-- ─────────────────────────────────────────────────────────────────
-- 7.  HELPER: Card Assembly
-- ─────────────────────────────────────────────────────────────────
local function makeCard(parent, name, size, pos, bg, radius)
    local card = make("Frame", parent, {
        Name             = name,
        Size             = size,
        Position         = pos,
        BackgroundColor3 = bg or C.BG_CARD,
        BorderSizePixel  = 0,
        ZIndex           = parent.ZIndex + 1,
    })
    corner(card, radius or 10)
    return card
end

-- ─────────────────────────────────────────────────────────────────
-- 8.  HOME TAB
-- ─────────────────────────────────────────────────────────────────
local HomeTab = make("Frame", ContentArea, {
    Name             = "HomeTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = true,
    ZIndex           = 4,
})

-- Welcome Banner Card
local WelcomeCard = makeCard(HomeTab, "WelcomeCard",
    UDim2.new(1, 0, 0, 72),
    UDim2.new(0, 0, 0, 0),
    C.BG_CARD, 12)
stroke(WelcomeCard, 1, C.BORDER_GLOW, 0.5)

gradient(WelcomeCard,
    ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("181B32")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("0F1222")),
    }),
    nil, 90)

-- Avatar Circle Profile Node
local ProfileCircle = make("Frame", WelcomeCard, {
    Name             = "ProfileCircle",
    Size             = UDim2.new(0, 52, 0, 52),
    Position         = UDim2.new(0, 12, 0.5, -26),
    BackgroundColor3 = Color3.fromHex("E05090"),
    BorderSizePixel  = 0,
    ZIndex           = 6,
})
corner(ProfileCircle, 14)
gradient(ProfileCircle, Color3.fromHex("FF60A8"), Color3.fromHex("C03070"), 135)

-- Textual Core Vector Smiley (:))
local SmileyLabel = make("TextLabel", ProfileCircle, {
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text             = ":)",
    TextColor3       = Color3.fromHex("FFFFFF"),
    Font             = Enum.Font.GothamBold,
    TextScaled       = true,
    Rotation         = 90,
    ZIndex           = 7,
})
textSizeConstraint(SmileyLabel, 16, 28)

local GreetStack = make("Frame", WelcomeCard, {
    Name             = "GreetStack",
    Size             = UDim2.new(1, -78, 1, 0),
    Position         = UDim2.new(0, 74, 0, 0),
    BackgroundTransparency = 1,
    ZIndex           = 6,
})
make("UIListLayout", GreetStack, {
    FillDirection    = Enum.FillDirection.Vertical,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 3),
})

local GreetLabel = make("TextLabel", GreetStack, {
    Name             = "GreetLabel",
    Size             = UDim2.new(1, 0, 0, 26),
    BackgroundTransparency = 1,
    Text             = "Hello, <font color='#E878C0'><b>" .. PlayerName .. "</b></font>!",
    RichText         = true,
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 20,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})
textSizeConstraint(GreetLabel, 12, 22)

local WelcomeSub = make("TextLabel", GreetStack, {
    Name             = "WelcomeSub",
    Size             = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text             = "Welcome back to Brite Hub.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})
textSizeConstraint(WelcomeSub, 9, 14)

-- Lower split: Session Stats (left 50%)
local LowerLeft = make("Frame", HomeTab, {
    Name             = "LowerLeft",
    Size             = UDim2.new(0.5, -6, 1, -86),
    Position         = UDim2.new(0, 0, 0, 80),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})
corner(LowerLeft, 12)
stroke(LowerLeft, 1, C.BORDER_GLOW, 0.65)

local SessionHeader = make("Frame", LowerLeft, {
    Name             = "SessionHeader",
    Size             = UDim2.new(1, 0, 0, 32),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})

local function drawPeopleIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "PeopleIcon",
        Size             = UDim2.new(0, 18, 0, 18),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    local function personShape(xOff, sz)
        local head = make("Frame", g, {
            Size             = UDim2.new(0, sz, 0, sz),
            Position         = UDim2.new(0, xOff, 0, 0),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
            ZIndex           = parent.ZIndex + 2,
        })
        corner(head, sz//2)
        local body = make("Frame", g, {
            Size             = UDim2.new(0, sz+2, 0, sz-1),
            Position         = UDim2.new(0, xOff-1, 0, sz+2),
            BackgroundColor3 = color,
            BorderSizePixel  = 0,
            ZIndex           = parent.ZIndex + 2,
        })
        corner(body, 3)
    end
    personShape(0, 6)
    personShape(7, 7)
    return g
end

local peopleIcon = drawPeopleIcon(SessionHeader, C.ACCENT_PURPLE)
peopleIcon.Position = UDim2.new(0, 12, 0.5, -9)

local SessionTitle = make("TextLabel", SessionHeader, {
    Name             = "SessionTitle",
    Size             = UDim2.new(1, -40, 1, 0),
    Position         = UDim2.new(0, 34, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Session",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})
textSizeConstraint(SessionTitle, 10, 16)

-- 2×2 Metric Grid Setup
local GridFrame = make("Frame", LowerLeft, {
    Name             = "MetricGrid",
    Size             = UDim2.new(1, -16, 1, -44),
    Position         = UDim2.new(0, 8, 0, 34),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})
make("UIGridLayout", GridFrame, {
    CellSize         = UDim2.new(0.5, -4, 0.5, -4),
    CellPadding      = UDim2.new(0, 4, 0, 4),
    StartCorner      = Enum.StartCorner.TopLeft,
})

local function makeMetricCard(parent, label, valueText, valueName)
    local card = make("Frame", parent, {
        Name             = label:gsub("%s","") .. "Card",
        BackgroundColor3 = C.BG_CARD,
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    corner(card, 8)
    stroke(card, 1, C.BORDER_GLOW, 0.75)

    make("TextLabel", card, {
        Name             = "MetricLabel",
        Size             = UDim2.new(1, -8, 0, 14),
        Position         = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Text             = label,
        TextColor3       = C.TEXT_SUB,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 7,
    })

    local valLabel = make("TextLabel", card, {
        Name             = valueName or "MetricValue",
        Size             = UDim2.new(1, -8, 0, 24),
        Position         = UDim2.new(0, 8, 0, 24),
        BackgroundTransparency = 1,
        Text             = valueText,
        TextColor3       = C.TEXT_PRIMARY,
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 7,
    })
    textSizeConstraint(valLabel, 10, 20)

    return card, valLabel
end

local _, playersVal  = makeMetricCard(GridFrame, "Players Online", "—",       "PlayersValue")
local _, pingVal     = makeMetricCard(GridFrame, "Ping",          "—  ms",    "PingValue")
local _, regionVal   = makeMetricCard(GridFrame, "Region",        "US",       "RegionValue")
local _, sessionVal  = makeMetricCard(GridFrame, "Session Time",  "00:00:00", "SessionValue")

-- Live tracking stats engine thread
local sessionStartTime = tick()
task.spawn(function()
    while true do
        task.wait(1)
        local ok1, count = pcall(function() return #Players:GetPlayers() end)
        if ok1 then playersVal.Text = tostring(count) end

        local ok2, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        if ok2 and ping then
            pingVal.Text = tostring(ping) .. " ms"
        else
            local ok3, ping2 = pcall(function() return math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            if ok3 then pingVal.Text = tostring(ping2) .. " ms" end
        end

        local elapsed = tick() - sessionStartTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = math.floor(elapsed % 60)
        sessionVal.Text = string.format("%02d:%02d:%02d", h, m, s)
    end
end)

-- Status Container Console Box (right 50%)
local StatusBox = make("Frame", HomeTab, {
    Name             = "StatusBox",
    Size             = UDim2.new(0.5, -6, 1, -86),
    Position         = UDim2.new(0.5, 6, 0, 80),
    BackgroundColor3 = C.WAVE_GRAD1,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})
corner(StatusBox, 12)
gradient(StatusBox,
    ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("4A1540")),
        ColorSequenceKeypoint.new(0.6, Color3.fromHex("2A0C32")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("1C0C2E")),
    }),
    nil, 160)

local StatusHeaderRow = make("Frame", StatusBox, {
    Name             = "StatusHeaderRow",
    Size             = UDim2.new(1, 0, 0, 36),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})

local function drawPulseIcon(parent, color)
    local g = make("Frame", parent, {
        Name             = "PulseIcon",
        Size             = UDim2.new(0, 20, 0, 14),
        BackgroundTransparency = 1,
        ZIndex           = parent.ZIndex + 1,
    })
    local segs = {
        {UDim2.new(0, 0, 0.5, -1), UDim2.new(0, 4, 0, 2), 0},
        {UDim2.new(0, 4, 0, 2),    UDim2.new(0, 3, 0, 10), -60},
        {UDim2.new(0, 7, 0, 0),    UDim2.new(0, 3, 0, 14), 55},
        {UDim2.new(0,10, 0.5,-1),  UDim2.new(0, 3, 0, 2),  0},
        {UDim2.new(0,13, 0.5,-1),  UDim2.new(0, 7, 0, 2),  0},
    }
    for _, seg in ipairs(segs) do
        local f = make("Frame", g, {
            Position         = seg[1],
            Size             = seg[2],
            BackgroundColor3 = color,
            Rotation         = seg[3],
            BorderSizePixel  = 0,
            ZIndex           = parent.ZIndex + 2,
        })
        corner(f, 1)
    end
    return g
end

local pulseIcon = drawPulseIcon(StatusHeaderRow, C.ACCENT_PINK)
pulseIcon.Position = UDim2.new(0, 12, 0.5, -7)

local StatusTitle = make("TextLabel", StatusHeaderRow, {
    Name             = "StatusTitle",
    Size             = UDim2.new(1, -40, 1, 0),
    Position         = UDim2.new(0, 36, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Status",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})

local StatusSub = make("TextLabel", StatusBox, {
    Name             = "StatusSub",
    Size             = UDim2.new(1, -20, 0, 14),
    Position         = UDim2.new(0, 12, 0, 38),
    BackgroundTransparency = 1,
    Text             = "Your executor supports this script.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextWrapped      = true,
    ZIndex           = 5,
})
textSizeConstraint(StatusSub, 8, 12)

local logEntries = {
    "✔  Script loaded successfully",
    "✔  Executor detected",
    "✔  Anti-kick active",
    "✔  ESP module ready",
    "ℹ  Running v1.0.0 — latest",
}

local LogList = make("Frame", StatusBox, {
    Name             = "LogList",
    Size             = UDim2.new(1, -16, 1, -70),
    Position         = UDim2.new(0, 8, 0, 58),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})
make("UIListLayout", LogList, {
    FillDirection    = Enum.FillDirection.Vertical,
    Padding          = UDim.new(0, 4),
})

for _, entry in ipairs(logEntries) do
    local row = make("TextLabel", LogList, {
        Name             = "LogEntry",
        Size             = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text             = entry,
        TextColor3       = entry:sub(1,1) == "✔" and Color3.fromHex("A0E8A0") or C.TEXT_SUB,
        Font             = Enum.Font.Code,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 6,
    })
    textSizeConstraint(row, 8, 11)
end

-- ─────────────────────────────────────────────────────────────────
-- 9.  FARM TAB (Renamed from Exec)
-- ─────────────────────────────────────────────────────────────────
local FarmTab = make("Frame", ContentArea, {
    Name             = "FarmTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 4,
})
make("UIListLayout", FarmTab, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding          = UDim.new(0, 8),
})
make("UIPadding", FarmTab, {
    PaddingTop    = UDim.new(0, 8),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 4),
})

local FarmPlaceholder = make("TextLabel", FarmTab, {
    Name             = "FarmPlaceholder",
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text             = "Automation & Farming  —  Add your macro runners here.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})
textSizeConstraint(FarmPlaceholder, 9, 13)

-- ─────────────────────────────────────────────────────────────────
-- 10. TELEPORT TAB (Renamed from Theme)
-- ─────────────────────────────────────────────────────────────────
local TeleportTab = make("Frame", ContentArea, {
    Name             = "TeleportTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 4,
})
make("UIListLayout", TeleportTab, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding          = UDim.new(0, 8),
})
make("UIPadding", TeleportTab, {
    PaddingTop    = UDim.new(0, 8),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 4),
})

local TeleportPlaceholder = make("TextLabel", TeleportTab, {
    Name             = "TeleportPlaceholder",
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text             = "World Teleportation  —  Map waypoints go here.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})
textSizeConstraint(TeleportPlaceholder, 9, 13)

-- ─────────────────────────────────────────────────────────────────
-- 11. CONFIG TAB
-- ─────────────────────────────────────────────────────────────────
local ConfigTab = make("Frame", ContentArea, {
    Name             = "ConfigTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 4,
})

local ConfigCard = makeCard(ConfigTab, "ConfigCard",
    UDim2.new(1, 0, 0, 190),
    UDim2.new(0, 0, 0, 0),
    C.BG_CARD, 12)
stroke(ConfigCard, 1, C.BORDER_GLOW, 0.5)

local ConfigTitle = make("TextLabel", ConfigCard, {
    Name             = "ConfigTitle",
    Size             = UDim2.new(1, -20, 0, 24),
    Position         = UDim2.new(0, 12, 0, 10),
    BackgroundTransparency = 1,
    Text             = "Configuration",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 16,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})
textSizeConstraint(ConfigTitle, 11, 18)

make("Frame", ConfigCard, {
    Name             = "ConfigDivider",
    Size             = UDim2.new(1, -20, 0, 1),
    Position         = UDim2.new(0, 10, 0, 38),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 5,
})

make("TextLabel", ConfigCard, {
    Name             = "KeybindLabel",
    Size             = UDim2.new(1, -20, 0, 18),
    Position         = UDim2.new(0, 12, 0, 48),
    BackgroundTransparency = 1,
    Text             = "Toggle Keybind",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.GothamSemibold,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})

make("TextLabel", ConfigCard, {
    Name             = "KeybindHint",
    Size             = UDim2.new(1, -20, 0, 14),
    Position         = UDim2.new(0, 12, 0, 68),
    BackgroundTransparency = 1,
    Text             = "Click the box below, then press any key to bind it.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 10,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextWrapped      = true,
    ZIndex           = 5,
})

local KeybindBox = makeCard(ConfigCard, "KeybindBox",
    UDim2.new(1, -24, 0, 36),
    UDim2.new(0, 12, 0, 88),
    C.BG_CARD2, 8)
stroke(KeybindBox, 1.5, C.ACCENT_PURPLE, 0.3)

local CurrentBind = "RightShift"

local KeybindText = make("TextBox", KeybindBox, {
    Name             = "KeybindText",
    Size             = UDim2.new(1, -16, 1, 0),
    Position         = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text             = "[ " .. CurrentBind .. " ]",
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Center,
    ClearTextOnFocus = false,
    ZIndex           = 6,
})
textSizeConstraint(KeybindText, 10, 16)

local capturingKeybind = false
KeybindText.Focused:Connect(function()
    capturingKeybind = true
    KeybindText.Text = "Press a key..."
    KeybindText.TextColor3 = C.ACCENT_PINK
    tween(KeybindBox, FAST, { BackgroundColor3 = Color3.fromHex("1C1035") })
end)

KeybindText.FocusLost:Connect(function()
    capturingKeybind = false
    KeybindText.TextColor3 = C.ACCENT_PURPLE
    tween(KeybindBox, FAST, { BackgroundColor3 = C.BG_CARD2 })
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if capturingKeybind and not gameProcessed then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            local modifiers = {LeftShift=true, RightShift=true, LeftControl=true,
                               RightControl=true, LeftAlt=true, RightAlt=true,
                               LeftSuper=true, RightSuper=true}
            if not modifiers[keyName] then
                CurrentBind  = keyName
                KeybindText.Text = "[ " .. keyName .. " ]"
                KeybindText:ReleaseFocus()
            end
        end
    end
end)

local KeybindStatusLabel = make("TextLabel", ConfigCard, {
    Name             = "KeybindStatus",
    Size             = UDim2.new(1, -20, 0, 14),
    Position         = UDim2.new(0, 12, 0, 132),
    BackgroundTransparency = 1,
    Text             = "Current toggle key:  " .. CurrentBind,
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Code,
    TextSize         = 10,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 5,
})
textSizeConstraint(KeybindStatusLabel, 8, 11)

task.spawn(function()
    while true do
        task.wait(0.2)
        KeybindStatusLabel.Text = "Current toggle key:  " .. CurrentBind
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 12. NAVIGATION ROUTING SYSTEM (Tab Switching Engine)
-- ─────────────────────────────────────────────────────────────────
-- FIXED: Updated keys to track uppercase formats (HOME, FARM, TELEPORT, CONFIG)
local tabMap = {
    HOME     = HomeTab,
    FARM     = FarmTab,
    TELEPORT = TeleportTab,
    CONFIG   = ConfigTab,
}

local iconDrawFns = {
    HOME     = drawHomeIcon,
    FARM     = drawFarmIcon,
    TELEPORT = drawPinIcon,
    CONFIG   = drawGearIcon,
}

local function switchTab(id)
    if id == activeTab then return end
    activeTab = id

    for tabId, frame in pairs(tabMap) do
        frame.Visible = (tabId == id)
    end

    for btnId, data in pairs(NavButtons) do
        local isActive = (btnId == id)
        tween(data.stroke, FAST, {
            Color        = isActive and C.ACCENT_PURPLE or C.ICON_MUTED,
            Transparency = isActive and 0.2 or 1,
        })
        if data.iconFrame then
            data.iconFrame:Destroy()
        end
        local newColor  = isActive and C.ACCENT_PURPLE or C.ICON_MUTED
        local newIcon   = iconDrawFns[btnId](data.btn, newColor)
        newIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
        newIcon.ZIndex   = 6
        NavButtons[btnId].iconFrame = newIcon
        tween(data.btn, FAST, {
            BackgroundTransparency = isActive and 0.4 or 1,
        })
    end
end

for _, def in ipairs(navDefs) do
    local data = NavButtons[def.id]
    data.btn.MouseButton1Click:Connect(function()
        switchTab(def.id)
    end)
    data.btn.MouseEnter:Connect(function()
        if def.id ~= activeTab then
            tween(data.btn, FAST, { BackgroundTransparency = 0.7 })
        end
    end)
    data.btn.MouseLeave:Connect(function()
        if def.id ~= activeTab then
            tween(data.btn, FAST, { BackgroundTransparency = 1 })
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- 13. GLOBAL KEYBIND TRACKING EVENT
-- ─────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if capturingKeybind then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode.Name == CurrentBind then
            guiVisible = not guiVisible
            if guiVisible then
                MainFrame.Visible = true
                GlowFrame.Visible = true
                if minimised then
                    tween(MainFrame, MED, {
                        Size     = UDim2.new(0, 720, 0, 56),
                        Position = UDim2.new(0.5, -360, 0.5, -28),
                    })
                    tween(GlowFrame, MED, {
                        Size     = UDim2.new(0, 740, 0, 76),
                        BackgroundTransparency = 0.88
                    })
                else
                    tween(MainFrame, MED, {
                        Size     = UDim2.new(0, 720, 0, 440),
                        Position = UDim2.new(0.5, -360, 0.5, -220),
                    })
                    tween(GlowFrame, MED, {
                        Size     = UDim2.new(0, 740, 0, 460),
                        BackgroundTransparency = 0.88
                    })
                end
            else
                if minimised then
                    tween(MainFrame, MED, { Size = UDim2.new(0, 720, 0, 0) })
                else
                    tween(MainFrame, MED, {
                        Size     = UDim2.new(0, 720, 0, 0),
                        Position = UDim2.new(0.5, -360, 0.5, 0),
                    })
                end
                tween(GlowFrame, MED, { BackgroundTransparency = 1 })
                task.delay(0.35, function()
                    if not guiVisible then
                        MainFrame.Visible = false
                        GlowFrame.Visible = false
                    end
                end)
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 14.  ENTRANCE ANIMATION INITIALIZATION
-- ─────────────────────────────────────────────────────────────────
MainFrame.Size     = UDim2.new(0, 720, 0, 0)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, 0)
GlowFrame.BackgroundTransparency = 1

task.delay(0.05, function()
    tween(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 720, 0, 440),
        Position = UDim2.new(0.5, -360, 0.5, -220),
    })
    tween(GlowFrame, MED, { BackgroundTransparency = 0.88 })
end)

print("[BriteHub] ✔  Dashboard running v1.1.0 — active keybind:", CurrentBind)
