--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     BRITE HUB  v2.4                         ║
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
local Stats          = game:GetService("Stats")
local StarterGui     = game:GetService("StarterGui")

local LocalPlayer    = Players.LocalPlayer
local PlayerName     = LocalPlayer and LocalPlayer.Name or "Player"
local sessionStartTime = tick()

-- ── Colour Palette ───────────────────────────────────────────────
local C = {
    BG_MAIN      = Color3.fromHex("0C0E1C"),   -- deep navy
    BG_SIDEBAR   = Color3.fromHex("080912"),   -- near-black
    BG_CARD      = Color3.fromHex("13162A"),   -- card surface
    BG_CARD2     = Color3.fromHex("0F1122"),   -- slightly darker card
    ACCENT_PURPLE= Color3.fromHex("B48CFF"),   -- neon purple
    ACCENT_PINK  = Color3.fromHex("E0569B"),   -- vivid pink
    ICON_MUTED   = Color3.fromHex("7864B4"),   -- inactive letters
    TEXT_PRIMARY = Color3.fromHex("EEEEFF"),   -- near-white
    TEXT_SUB     = Color3.fromHex("8A8AB8"),   -- muted subtitle
    BORDER_GLOW  = Color3.fromHex("6A3FBF"),   -- purple border
    WAVE_GRAD1   = Color3.fromHex("4A1540"),   -- status box dark
    WAVE_GRAD2   = Color3.fromHex("1C0C2E"),   -- status box deep
}

-- ── Shared Configuration State ───────────────────────────────────
_G.CloverFarming = false
_G.CloverWorldMode = false
_G.FarmWaitTime = 0.01
_G.FarmKeybind = "Comma"
local capturingFarmKey = false

-- ── Tween helper ─────────────────────────────────────────────────
local function tween(obj, info, goal)
    TweenService:Create(obj, info, goal):Play()
end

local FAST  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local MED   = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ── Instance factory ─────────────────────────────────────────────
local function make(className, parent, props)
    local obj = Instance.new(className)
    obj.Parent = parent 
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
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
    Position         = UDim2.new(0.5, -360, 0.5, -220),
    BackgroundColor3 = C.BG_MAIN,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex           = 2,
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
    ZIndex           = 1,
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
    ZIndex           = 5,
    Visible          = true,
})

make("Frame", TopBar, {
    Name             = "Divider",
    Size             = UDim2.new(1, 0, 0, 1),
    Position         = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 5,
})

-- Logo
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

-- Title Stack
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

-- Controls
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

local guiVisible = true
local minimised = false

CloseBtn.MouseButton1Click:Connect(function()
    guiVisible = false
    tween(MainFrame, MED, { Size = UDim2.new(0, 720, 0, 0), Position = UDim2.new(0.5, -360, 0.5, 0) })
    tween(GlowFrame, MED, { Size = UDim2.new(0, 740, 0, 0), BackgroundTransparency = 1 })
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
-- 5.  SIDEBAR (FIXED ORDER AND CLAMPED SORTING)
-- ─────────────────────────────────────────────────────────────────
local Sidebar = make("Frame", MainFrame, {
    Name             = "Sidebar",
    Size             = UDim2.new(0, 60, 1, -56),
    Position         = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})
corner(Sidebar, 14)

local LayoutBypasser = make("Folder", Sidebar, { Name = "BypassElements" })

local SidebarFillerTop = make("Frame", LayoutBypasser, {
    Size             = UDim2.new(0, 60, 0, 14),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})
local SidebarFillerRight = make("Frame", LayoutBypasser, {
    Size             = UDim2.new(0, 14, 1, 0),
    Position         = UDim2.new(0, 46, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 4,
})

make("Frame", LayoutBypasser, {
    Name             = "SideDivider",
    Size             = UDim2.new(0, 1, 1, 0),
    Position         = UDim2.new(0, 59, 0, 0),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.7,
    BorderSizePixel  = 0,
    ZIndex           = 5,
})

make("UIListLayout", Sidebar, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder        = Enum.SortOrder.LayoutOrder, -- Ensures strict tracking order
    Padding          = UDim.new(0, 10),
})
make("UIPadding", Sidebar, {
    PaddingTop = UDim.new(0, 14),
})

-- LOCKED ROUTING SEQUENCE DEFINITION
local navDefs = {
    { id = "HOME",     char = "H" },
    { id = "FARM",     char = "F" },
    { id = "TELEPORT", char = "T" },
    { id = "CONFIG",   char = "C" }
}

local NavButtons = {}
local activeTab  = "HOME"

for i, def in ipairs(navDefs) do
    local btn = make("TextButton", Sidebar, {
        Name             = "Nav_" .. def.id,
        LayoutOrder      = i, -- Absolute override for alphabetical layouts
        Size             = UDim2.new(0, 44, 0, 44),
        BackgroundColor3 = C.BG_CARD,
        BackgroundTransparency = i == 1 and 0.4 or 1,
        Text             = "", 
        ZIndex           = 6,
    })
    corner(btn, 10)
    
    local initialColor = i == 1 and C.ACCENT_PURPLE or C.ICON_MUTED
    
    local txtLabel = make("TextLabel", btn, {
        Name             = "IconText",
        Size             = UDim2.new(1, 0, 1, -2),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text             = def.char,
        TextColor3       = initialColor,
        Font             = Enum.Font.GothamBold,
        TextSize         = 20,
        TextXAlignment   = Enum.TextXAlignment.Center,
        TextYAlignment   = Enum.TextYAlignment.Center,
        ZIndex           = 7,
    })

    local navStroke = stroke(btn, 1.5, initialColor, i == 1 and 0.2 or 1)

    NavButtons[def.id] = {
        btn    = btn,
        txt    = txtLabel,
        stroke = navStroke,
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

local function makeCard(parent, name, size, pos, bg, radius)
    local card = make("Frame", parent, {
        Name             = name,
        Size             = size,
        Position         = pos,
        BackgroundColor3 = bg or C.BG_CARD,
        BorderSizePixel  = 0,
        ZIndex           = (parent and parent.ZIndex or 3) + 1,
    })
    corner(card, radius or 10)
    return card
end

-- ─────────────────────────────────────────────────────────────────
-- 7.  HOME TAB
-- ─────────────────────────────────────────────────────────────────
local HomeTab = make("Frame", ContentArea, {
    Name             = "HomeTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = true,
    ZIndex           = 3,
})

local WelcomeCard = makeCard(HomeTab, "WelcomeCard", UDim2.new(1, 0, 0, 72), UDim2.new(0, 0, 0, 0), C.BG_CARD, 12)
stroke(WelcomeCard, 1, C.BORDER_GLOW, 0.5)

gradient(WelcomeCard,
    ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromHex("181B32")),
        ColorSequenceKeypoint.new(1,   Color3.fromHex("0F1222")),
    }), nil, 90)

local ProfileCircle = make("Frame", WelcomeCard, {
    Name             = "ProfileCircle",
    Size             = UDim2.new(0, 52, 0, 52),
    Position         = UDim2.new(0, 22, 0.5, -26), 
    BackgroundColor3 = Color3.fromHex("E05090"),
    BorderSizePixel  = 0,
    ZIndex           = 6,
})
corner(ProfileCircle, 14)
gradient(ProfileCircle, Color3.fromHex("FF60A8"), Color3.fromHex("C03070"), 135)

local SmileyLabel = make("TextLabel", ProfileCircle, {
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint      = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Text             = ":)",
    TextColor3       = Color3.fromHex("FFFFFF"),
    Font             = Enum.Font.GothamBold,
    TextSize         = 22,
    Rotation         = 90,
    TextXAlignment   = Enum.TextXAlignment.Center,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 7,
})

local GreetStack = make("Frame", WelcomeCard, {
    Name             = "GreetStack",
    Size             = UDim2.new(1, -88, 1, 0),
    Position         = UDim2.new(0, 84, 0, 0),
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

-- Splits
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
        corner(head, math.floor(sz / 2))
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
    ZIndex           = 6,
})
textSizeConstraint(SessionTitle, 10, 16)

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
        ZIndex           = parent.ZIndex + 1,
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
        ZIndex           = card.ZIndex + 1,
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
        ZIndex           = card.ZIndex + 1,
    })
    textSizeConstraint(valLabel, 10, 20)

    return card, valLabel
end

local _, playersVal  = makeMetricCard(GridFrame, "Players Online", "—",       "PlayersValue")
local _, pingVal     = makeMetricCard(GridFrame, "Ping",          "—  ms",    "PingValue")
local _, regionVal   = makeMetricCard(GridFrame, "Region",        "US",       "RegionValue")
local _, sessionVal  = makeMetricCard(GridFrame, "Session Time",  "00:00:00", "SessionValue")

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

-- Status
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
    }), nil, 160)

local StatusHeaderRow = make("Frame", StatusBox, {
    Name             = "StatusHeaderRow",
    Size             = UDim2.new(1, 0, 0, 36),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})

local StatusTitle = make("TextLabel", StatusHeaderRow, {
    Name             = "StatusTitle",
    Size             = UDim2.new(1, -24, 1, 0),
    Position         = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Status",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 6,
})

local identifiedName = "Studio / Unknown"
if type(identifyexecutor) == "function" then
    identifiedName = identifyexecutor()
elseif type(getexecutorname) == "function" then
    identifiedName = getexecutorname()
end

local StatusSub = make("TextLabel", StatusBox, {
    Name             = "StatusSub",
    Size             = UDim2.new(1, -24, 0, 30),
    Position         = UDim2.new(0, 14, 0, 38),
    BackgroundTransparency = 1,
    RichText         = true,
    Text             = "Your executor is <font color='#B48BFF'><b>" .. identifiedName .. "</b></font>",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextWrapped      = true,
    ZIndex           = 6,
})
textSizeConstraint(StatusSub, 10, 15)

local LogList = make("Frame", StatusBox, {
    Name             = "LogList",
    Size             = UDim2.new(1, -16, 1, -80),
    Position         = UDim2.new(0, 8, 0, 74),
    BackgroundTransparency = 1,
    ZIndex           = 5,
})
make("UIListLayout", LogList, {
    FillDirection    = Enum.FillDirection.Vertical,
    Padding          = UDim.new(0, 6),
})

local cleanEntries = {
    "✔  Script environment loaded successfully",
    "✔  Core UI hooks initialized",
    "ℹ  Running BriteHub Build v2.4.0 — Stable",
}

for _, entry in ipairs(cleanEntries) do
    make("TextLabel", LogList, {
        Name             = "LogEntry",
        Size             = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text             = entry,
        TextColor3       = entry:sub(1,1) == "✔" and Color3.fromHex("A0E8A0") or C.TEXT_SUB,
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 6,
    })
end

-- ─────────────────────────────────────────────────────────────────
-- 8.  FARM TAB (INTEGRATED CLOVER AUTOMATION ROUTINES)
-- ─────────────────────────────────────────────────────────────────
local FarmTab = make("Frame", ContentArea, {
    Name             = "FarmTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
})

local FarmCard = makeCard(FarmTab, "FarmCard", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG_CARD, 12)
stroke(FarmCard, 1, C.BORDER_GLOW, 0.5)

local FarmTitle = make("TextLabel", FarmCard, {
    Size             = UDim2.new(1, -20, 0, 24),
    Position         = UDim2.new(0, 12, 0, 10),
    BackgroundTransparency = 1,
    Text             = "Automation & Farming",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 16,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 6,
})

make("Frame", FarmCard, {
    Size             = UDim2.new(1, -20, 0, 1),
    Position         = UDim2.new(0, 10, 0, 38),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 6,
})

-- Dropdown / Options Layout Main Toggle
local MainToggleBtn = make("TextButton", FarmCard, {
    Size             = UDim2.new(0, 140, 0, 30),
    Position         = UDim2.new(0, 12, 0, 50),
    BackgroundColor3 = C.BG_CARD2,
    Text             = "Clover Farm: OFF",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    ZIndex           = 7,
})
corner(MainToggleBtn, 6)
local toggleStroke = stroke(MainToggleBtn, 1.5, C.ICON_MUTED, 0.5)

local function updateFarmUI(state)
    if state then
        MainToggleBtn.Text = "Clover Farm: ON"
        MainToggleBtn.TextColor3 = C.ACCENT_PURPLE
        toggleStroke.Color = C.ACCENT_PURPLE
    else
        MainToggleBtn.Text = "Clover Farm: OFF"
        MainToggleBtn.TextColor3 = C.TEXT_SUB
        toggleStroke.Color = C.ICON_MUTED
    end
end

MainToggleBtn.MouseButton1Click:Connect(function()
    _G.CloverFarming = not _G.CloverFarming
    updateFarmUI(_G.CloverFarming)
end)

-- Inner Settings Context Frame Container
local OptionsBox = makeCard(FarmCard, "OptionsBox", UDim2.new(1, -24, 0, 130), UDim2.new(0, 12, 0, 90), C.BG_CARD2, 8)
stroke(OptionsBox, 1, C.BORDER_GLOW, 0.7)

-- Wait Config Row
make("TextLabel", OptionsBox, {
    Size             = UDim2.new(0, 120, 0, 20),
    Position         = UDim2.new(0, 12, 0, 12),
    BackgroundTransparency = 1,
    Text             = "Task Wait Config:",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamSemibold,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})

local WaitInput = make("TextBox", OptionsBox, {
    Size             = UDim2.new(0, 80, 0, 24),
    Position         = UDim2.new(0, 140, 0, 10),
    BackgroundColor3 = C.BG_CARD,
    Text             = "0.01",
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    ZIndex           = 8,
})
corner(WaitInput, 4)
stroke(WaitInput, 1, C.BORDER_GLOW, 0.5)

WaitInput.FocusLost:Connect(function()
    local val = tonumber(WaitInput.Text)
    if val then
        if val < 0.01 then val = 0.01 end -- Lock to specified absolute minimum
        _G.FarmWaitTime = val
        WaitInput.Text = tostring(val)
    else
        WaitInput.Text = tostring(_G.FarmWaitTime)
    end
end)

-- 3. CLOVER WORLD MODIFIER TOGGLE
local WorldToggleBtn = make("TextButton", OptionsBox, {
    Size             = UDim2.new(0, 140, 0, 26),
    Position         = UDim2.new(0, 12, 0, 48),
    BackgroundColor3 = C.BG_CARD,
    Text             = "Clover World: No", -- CHANGED
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 11,
    ZIndex           = 8,
})
corner(WorldToggleBtn, 6)
local worldStroke = stroke(WorldToggleBtn, 1, C.ICON_MUTED, 0.6)

WorldToggleBtn.MouseButton1Click:Connect(function()
    _G.CloverWorldMode = not _G.CloverWorldMode
    if _G.CloverWorldMode then
        WorldToggleBtn.Text = "Clover World: Yes" -- CHANGED
        WorldToggleBtn.TextColor3 = C.ACCENT_PINK
        worldStroke.Color = C.ACCENT_PINK
    else
        WorldToggleBtn.Text = "Clover World: No" -- CHANGED
        WorldToggleBtn.TextColor3 = C.TEXT_SUB
        worldStroke.Color = C.ICON_MUTED
    end
end)

-- Inline Custom Loop Trigger Bind Selector
make("TextLabel", OptionsBox, {
    Size             = UDim2.new(0, 120, 0, 20),
    Position         = UDim2.new(0, 12, 0, 88),
    BackgroundTransparency = 1,
    Text             = "Macro Toggle Keybind:",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 7,
})

local FarmBindBox = makeCard(OptionsBox, "FarmBindBox", UDim2.new(0, 80, 0, 24), UDim2.new(0, 140, 0, 86), C.BG_CARD, 4)
stroke(FarmBindBox, 1, C.BORDER_GLOW, 0.5)

local FarmBindText = make("TextBox", FarmBindBox, {
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text             = "[ Comma ]",
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    ClearTextOnFocus = false,
    ZIndex           = 8,
})

FarmBindText.Focused:Connect(function()
    capturingFarmKey = true
    FarmBindText.Text = "..."
end)

UserInputService.InputBegan:Connect(function(input)
    if capturingFarmKey and input.UserInputType == Enum.UserInputType.Keyboard then
        local name = input.KeyCode.Name
        if name ~= "Unknown" then
            _G.FarmKeybind = name
            FarmBindText.Text = "[ " .. name .. " ]"
            capturingFarmKey = false
            FarmBindText:ReleaseFocus()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 9. TELEPORTATION TAB
-- ─────────────────────────────────────────────────────────────────
local TeleportTab = make("Frame", ContentArea, {
    Name             = "TeleportTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
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

make("TextLabel", TeleportTab, {
    Name             = "TeleportPlaceholder",
    Size             = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Text             = "World Teleportation  —  Map waypoints go here.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 6,
})

-- ─────────────────────────────────────────────────────────────────
-- 10. CONFIG TAB
-- ─────────────────────────────────────────────────────────────────
local ConfigTab = make("Frame", ContentArea, {
    Name             = "ConfigTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
})

local ConfigCard = makeCard(ConfigTab, "ConfigCard", UDim2.new(1, 0, 0, 190), UDim2.new(0, 0, 0, 0), C.BG_CARD, 12)
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
    ZIndex           = 6,
})

make("Frame", ConfigCard, {
    Name             = "ConfigDivider",
    Size             = UDim2.new(1, -20, 0, 1),
    Position         = UDim2.new(0, 10, 0, 38),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.6,
    BorderSizePixel  = 0,
    ZIndex           = 6,
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
    ZIndex           = 6,
})

make("TextLabel", ConfigCard, {
    Name             = "KeybindHint",
    Size             = UDim2.new(1, -20, 0, 14),
    Position         = UDim2.new(0, 12, 0, 68),
    BackgroundTransparency = 1,
    Text             = "Click the box below, then press any key to bind the UI frame window toggle.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 10,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextWrapped      = true,
    ZIndex           = 6,
})

local KeybindBox = makeCard(ConfigCard, "KeybindBox", UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 0, 88), C.BG_CARD2, 8)
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
    ZIndex           = 7,
})

local capturingKeybind = false
KeybindText.Focused:Connect(function()
    capturingKeybind = true
    KeybindText.Text = "Press any key..."
    KeybindText.TextColor3 = C.ACCENT_PINK
    tween(KeybindBox, FAST, { BackgroundColor3 = Color3.fromHex("1C1035") })
end)

KeybindText.FocusLost:Connect(function()
    capturingKeybind = false
    KeybindText.TextColor3 = C.ACCENT_PURPLE
    tween(KeybindBox, FAST, { BackgroundColor3 = C.BG_CARD2 })
end)

UserInputService.InputBegan:Connect(function(input)
    if capturingKeybind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            if keyName ~= "Unknown" then
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
    ZIndex           = 6,
})

task.spawn(function()
    while true do
        task.wait(0.2)
        if not capturingKeybind then
            KeybindStatusLabel.Text = "Current toggle key:  " .. CurrentBind
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 11. NAVIGATION ROUTING ENGINE
-- ─────────────────────────────────────────────────────────────────
local tabMap = {
    HOME     = HomeTab,
    FARM     = FarmTab,
    TELEPORT = TeleportTab,
    CONFIG   = ConfigTab,
}

local function switchTab(id)
    if id == activeTab then return end
    activeTab = id

    for tabId, frame in pairs(tabMap) do
        frame.Visible = (tabId == id)
    end

    for btnId, data in pairs(NavButtons) do
        local isActive = (btnId == id)
        local targetColor = isActive and C.ACCENT_PURPLE or C.ICON_MUTED
        
        tween(data.stroke, FAST, {
            Color        = targetColor,
            Transparency = isActive and 0.2 or 1,
        })
        tween(data.btn, FAST, {
            BackgroundTransparency = isActive and 0.4 or 1,
        })
        tween(data.txt, FAST, {
            TextColor3 = targetColor,
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
-- 12. GLOBAL VISIBILITY KEYBIND TRACKING
-- ─────────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or capturingKeybind or capturingFarmKey then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode.Name == CurrentBind then
            guiVisible = not guiVisible
            
            if guiVisible then
                MainFrame.Visible = true
                GlowFrame.Visible = true
                
                local targetHeight = minimised and 56 or 440
                local targetOffsetY = minimised and -28 or -220
                local glowHeight = minimised and 76 or 460
                
                tween(MainFrame, MED, {
                    Size     = UDim2.new(0, 720, 0, targetHeight),
                    Position = UDim2.new(0.5, -360, 0.5, targetOffsetY),
                })
                tween(GlowFrame, MED, {
                    Size     = UDim2.new(0, 740, 0, glowHeight),
                    BackgroundTransparency = 0.88
                })
            else
                tween(MainFrame, MED, {
                    Size     = UDim2.new(0, 720, 0, 0),
                    Position = UDim2.new(0.5, -360, 0.5, 0),
                })
                tween(GlowFrame, MED, {
                    Size     = UDim2.new(0, 740, 0, 0),
                    BackgroundTransparency = 1
                })
                
                task.delay(0.31, function()
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
-- 13. CLOVER CORE TELEPORT MACRO RUNNER
-- ─────────────────────────────────────────────────────────────────
local function getPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function refreshClovaFolder()
    local folderTarget = _G.CloverWorldMode and "clova1" or "clova"
    local clova = nil
    pcall(function() clova = workspace:WaitForChild(folderTarget, 2) end)
    return clova
end

local function findPriority(clovaFolder)
    if not clovaFolder then return nil end
    local priorTargets = _G.CloverWorldMode and { "fivew", "fourw", "threew" } or { "five", "four", "three" }
    
    for _, name in ipairs(priorTargets) do
        local found = clovaFolder:FindFirstChild(name, true)
        if found then
            local part = getPart(found)
            if part then return part end
        end
    end
    return nil
end

task.spawn(function()
    while true do
        if _G.CloverFarming then
            local ok, err = pcall(function()
                local character = LocalPlayer.Character
                if not character or not character.Parent then return end
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp or not hrp.Parent then return end
                
                local clova = refreshClovaFolder()
                if not clova then return end
                
                local models = clova:GetDescendants()
                for _, model in ipairs(models) do
                    if not _G.CloverFarming then break end
                    if model and model.Parent then
                        local priorityPart = nil
                        local target
                        while _G.CloverFarming and not target do
                            target = findPriority(clova)
                            if not target then
                                task.wait(_G.FarmWaitTime)
                                clova = refreshClovaFolder()
                                if not clova then return end
                            end
                        end
                        priorityPart = target
                        if priorityPart and priorityPart.Parent then
                            hrp.CFrame = priorityPart.CFrame
                            task.wait(_G.FarmWaitTime)
                        end
                        local part = getPart(model)
                        if part and part.Parent then
                            hrp.CFrame = part.CFrame
                        end
                        task.wait(_G.FarmWaitTime)
                    end
                end
            end)
            if not ok and err then warn("[BriteHub Clover-Engine]", err) end
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Hook for physical keystroke triggers updates to dynamic UI bindings
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or capturingKeybind or capturingFarmKey then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode.Name == _G.FarmKeybind then
            _G.CloverFarming = not _G.CloverFarming
            updateFarmUI(_G.CloverFarming)
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 14.  ENTRANCE ANIMATION INITIALIZATION
-- ─────────────────────────────────────────────────────────────────
MainFrame.Size     = UDim2.new(0, 720, 0, 0)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, 0)
GlowFrame.Size     = UDim2.new(0, 740, 0, 0)
GlowFrame.BackgroundTransparency = 1

task.delay(0.05, function()
    tween(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size     = UDim2.new(0, 720, 0, 440),
        Position = UDim2.new(0.5, -360, 0.5, -220),
    })
    tween(GlowFrame, MED, { 
        Size = UDim2.new(0, 740, 0, 460),
        BackgroundTransparency = 0.88 
    })
end)

print("[BriteHub] ✔ Active with capital letters. Order: H ➔ F ➔ T ➔ C. Farm Automation loaded.")