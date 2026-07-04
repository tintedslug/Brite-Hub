--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                     BRITE HUB  v4.6.2                       ║
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
    ICON_MUTED   = Color3.fromHex("4A4D70"),   -- dark muted grey-blue
    TEXT_PRIMARY = Color3.fromHex("EEEEFF"),   -- near-white
    TEXT_SUB     = Color3.fromHex("8A8AB8"),   -- muted subtitle
    BORDER_GLOW  = Color3.fromHex("6A3FBF"),   -- purple border
    WAVE_GRAD1   = Color3.fromHex("4A1540"),   -- status box dark
    WAVE_GRAD2   = Color3.fromHex("1C0C2E"),   -- status box deep
    TOGGLE_BG    = Color3.fromHex("1A1D36"),   -- off toggle track
}

-- ── Shared Configuration State ───────────────────────────────────
_G.CloverFarming     = false
_G.CloverWorldMode   = false

_G.ButtonAutofarm    = false
_G.AutoRoll          = false
_G.RebirthToggle     = false
_G.RebirthBuyToggle  = false
_G.RebirthSequence   = "1,2,3,4"

_G.FarmWaitTime      = 0.01
_G.FarmKeybind       = "Comma"
_G.AutoFarmKeybind   = "J"

-- Rune Farm
_G.RuneFarmMaster      = false
_G.RuneCloverToggle    = false
_G.RunePlantToggle     = false
_G.RuneBaseluckToggle  = false
_G.RunePrestigeToggle  = false
_G.RuneFarmKeybind     = "Y"

-- Button Farm
_G.ButtonFarmToggle      = false
_G.SmartButtonToggle     = false
_G.ButtonFarmKeybind     = "-"
_G.ButtonFarmSelectionIdx = 1

-- Auto Progress
_G.AutoProgressToggle      = false
_G.AutoSuperMultiplyToggle = false
_G.AutoSuperMultiplyNumber = "1m"
_G.AutoPrestigeToggle      = false
_G.AutoPrestigeNumber      = "2"
_G.AutoAscendToggle        = false
_G.AutoProgressKeybind     = "U"

-- GUI & Teleport Keybinds
_G.GuiToggleKeybind  = "RightShift"
_G.TpRollKeybind     = "R"
_G.TpRebirthKeybind  = "T"
_G.TpCloverKeybind   = "C"
_G.TpBaseLuckKeybind = "B"

-- ── Tween helper ─────────────────────────────────────────────────
local function tween(obj, info, goal)
    local t = TweenService:Create(obj, info, goal)
    t:Play()
    return t
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

-- ── Visual Switch Generator ──────────────────────────────────────
local function createToggleSwitch(parent, startState, onClick)
    local track = make("Frame", parent, {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = startState and C.ACCENT_PINK or C.TOGGLE_BG,
        BorderSizePixel = 0,
        ZIndex = parent.ZIndex + 2
    })
    corner(track, 10)
    stroke(track, 1, C.BORDER_GLOW, 0.5)

    local knob = make("Frame", track, {
        Size = UDim2.new(0, 14, 0, 14),
        Position = startState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = track.ZIndex + 1
    })
    corner(knob, 7)

    local clickBtn = make("TextButton", track, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Active = true,
        ZIndex = knob.ZIndex + 1
    })

    local state = startState
    local function updateVisuals(newState)
        state = newState
        if state then
            tween(track, FAST, { BackgroundColor3 = C.ACCENT_PINK })
            tween(knob, FAST, { Position = UDim2.new(1, -17, 0.5, -7) })
        else
            tween(track, FAST, { BackgroundColor3 = C.TOGGLE_BG })
            tween(knob, FAST, { Position = UDim2.new(0, 3, 0.5, -7) })
        end
    end

    clickBtn.Activated:Connect(function()
        onClick(not state, updateVisuals)
    end)

    return updateVisuals
end

-- ─────────────────────────────────────────────────────────────────
-- 1.  ROOT GUI
-- ─────────────────────────────────────────────────────────────────
local existing = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BriteHubGui")
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
local mainFrameStroke = stroke(MainFrame, 1.5, C.BORDER_GLOW, 0.15)

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
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 7,
})
textSizeConstraint(LogoText, 10, 16)

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
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 7,
})

local SubLabel = make("TextLabel", TitleStack, {
    Name             = "SubLabel",
    Size             = UDim2.new(1, 0, 0, 14),
    BackgroundTransparency = 1,
    Text             = "v4.6.2 Custom",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 7,
})

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
    Active           = true,
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
    Active           = true,
    ZIndex           = 7,
    AutoButtonColor  = false,
})
corner(CloseBtn, 6)
local CloseGrad = gradient(CloseBtn, Color3.fromHex("B48CFF"), Color3.fromHex("6A3FBF"), 90)

makeXLine = function(parent, rot)
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

CloseBtn.Activated:Connect(function()
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

MinBtn.Activated:Connect(function()
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

    TopBar.InputBegan:Connect(onInputBegan)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end


-- ─────────────────────────────────────────────────────────────────
-- 5.  SIDEBAR
-- ─────────────────────────────────────────────────────────────────
local Sidebar = make("Frame", MainFrame, {
    Name             = "Sidebar",
    Size             = UDim2.new(0, 60, 1, -56),
    Position         = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 10,
})
corner(Sidebar, 14)

local LayoutBypasser = make("Folder", Sidebar, { Name = "BypassElements" })

local SidebarFillerTop = make("Frame", LayoutBypasser, {
    Size             = UDim2.new(0, 60, 0, 14),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 1,
})
local SidebarFillerRight = make("Frame", LayoutBypasser, {
    Size             = UDim2.new(0, 14, 1, 0),
    Position         = UDim2.new(0, 46, 0, 0),
    BackgroundColor3 = C.BG_SIDEBAR,
    BorderSizePixel  = 0,
    ZIndex           = 1,
})

make("Frame", LayoutBypasser, {
    Name             = "SideDivider",
    Size             = UDim2.new(0, 1, 1, 0),
    Position         = UDim2.new(0, 59, 0, 0),
    BackgroundColor3 = C.BORDER_GLOW,
    BackgroundTransparency = 0.7,
    BorderSizePixel  = 0,
    ZIndex           = 2,
})

make("UIListLayout", Sidebar, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 10),
})
make("UIPadding", Sidebar, {
    PaddingTop = UDim.new(0, 14),
})

local navDefs = {
    { id = "HOME", char = "H" },
    { id = "FARM", char = "F" },
    { id = "TP",   char = "T" },
    { id = "CONFIG", char = "C" }
}

local NavButtons = {}
local activeTab  = "HOME"

for i, def in ipairs(navDefs) do
    local btn = make("TextButton", Sidebar, {
        Name             = "Nav_" .. def.id,
        LayoutOrder      = i,
        Size             = UDim2.new(0, 44, 0, 44),
        BackgroundColor3 = C.BG_CARD,
        BackgroundTransparency = i == 1 and 0.4 or 1,
        Text             = "", 
        Active           = true,
        Selectable       = true,
        ZIndex           = 12,
    })
    corner(btn, 10)
    
    local initialColor = i == 1 and C.ACCENT_PURPLE or C.TEXT_SUB
    
    local txtLabel = make("TextLabel", btn, {
        Name             = "IconText",
        Size             = UDim2.new(1, 0, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text             = def.char,
        TextColor3       = initialColor,
        Font             = Enum.Font.GothamBold,
        TextSize         = 20,
        TextXAlignment   = Enum.TextXAlignment.Center,
        TextYAlignment   = Enum.TextYAlignment.Center,
        ZIndex           = 13,
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
    PaddingLeft   = UDim.new(0, 12),
    PaddingRight  = UDim.new(0, 12),
    PaddingTop    = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 12),
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
-- 6b. ABBREVIATION DECODER (reverse of Bnum.short())
-- ─────────────────────────────────────────────────────────────────
local shortU8   = {"", "U", "D", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No"}
local shortU9   = {"", "De", "Vg", "Tg", "qg", "Qg", "sg", "Sg", "Og", "Ng"}
local shortU10  = {"", "Ce", "Du", "Tr", "Qa", "Qi", "Se", "Si", "Ot", "Ni"}

local suffixToExp = {}
do
    local function genSuffix(v6)
        if v6 == 0 then return "K" end
        if v6 == 1 then return "M" end
        if v6 == 2 then return "B" end
        local ones  = (v6 % 10) + 1
        local tens  = (math.floor(v6 / 10) % 10) + 1
        local hunds = (math.floor(v6 / 100) % 10) + 1
        return shortU10[hunds] .. shortU9[tens] .. shortU8[ones]
    end
    for v6 = 0, 999 do
        local s = genSuffix(v6)
        suffixToExp[s] = v6 * 3 + 3
    end
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
    TextYAlignment   = Enum.TextYAlignment.Center,
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
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 7,
})
textSizeConstraint(WelcomeSub, 9, 14)

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
    Text             = "Session Metrics",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 6,
})

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
        Position         = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Text             = label,
        TextColor3       = C.TEXT_SUB,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
        ZIndex           = card.ZIndex + 1,
    })

    local valLabel = make("TextLabel", card, {
        Name             = valueName or "MetricValue",
        Size             = UDim2.new(1, -8, 0, 24),
        Position         = UDim2.new(0, 8, 0, 20),
        BackgroundTransparency = 1,
        Text             = valueText,
        TextColor3       = C.TEXT_PRIMARY,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
        ZIndex           = card.ZIndex + 1,
    })
    textSizeConstraint(valLabel, 10, 18)

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
    Text             = "Status Console",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
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
    Position         = UDim2.new(0, 14, 0, 34),
    BackgroundTransparency = 1,
    RichText         = true,
    Text             = "Executor: <font color='#B48BFF'><b>" .. identifiedName .. "</b></font>",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
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

local passCount = 0
local totalTests = 12
if typeof(getgenv) == "function" and getgenv() then passCount = passCount + 1 end
if typeof(getrawmetatable) == "function" then passCount = passCount + 1 end
if typeof(fireclickdetector) == "function" or typeof(fireproximityprompt) == "function" then passCount = passCount + 1 end
if typeof(identifyexecutor) == "function" then passCount = passCount + 1 end
if typeof(lz4compress) == "function" or typeof(lz4decompress) == "function" then passCount = passCount + 1 end
if typeof(loadstring) == "function" then passCount = passCount + 1 end
if typeof(cloneref) == "function" then passCount = passCount + 1 end
if typeof(getgc) == "function" or typeof(getreg) == "function" then passCount = passCount + 1 end
if typeof(hookfunction) == "function" or typeof(replaceclosure) == "function" then passCount = passCount + 1 end
if typeof(hookmetamethod) == "function" then passCount = passCount + 1 end
if typeof(request) == "function" or (typeof(syn) == "table" and syn.request) then passCount = passCount + 1 end
if typeof(getrenv) == "function" then passCount = passCount + 1 end

local uncRate = math.round((passCount / totalTests) * 100)

local cleanEntries = {
    " System environment linked",
    " Modules integrity: OK",
    " Hook Verification Level = " .. tostring(uncRate) .. "%",
    " Running BriteHub Build v4.6.2",
}

for _, entry in ipairs(cleanEntries) do
    make("TextLabel", LogList, {
        Name             = "LogEntry",
        Size             = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text             = entry,
        TextColor3       = entry:find("Build") and C.TEXT_SUB or Color3.fromHex("A0E8A0"),
        Font             = Enum.Font.Code,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
        TextWrapped      = true,
        ZIndex           = 6,
    })
end

-- ─────────────────────────────────────────────────────────────────
-- 8.  FARM TAB
-- ─────────────────────────────────────────────────────────────────
local FarmTab = make("ScrollingFrame", ContentArea, {
    Name             = "FarmTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize       = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
make("UIListLayout", FarmTab, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 8),
})
make("UIPadding", FarmTab, {
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 10),
})

-- ── Auto Progress Card ────────────────────────────────────────
local AutoProgCard = make("Frame", FarmTab, {
    Name = "AutoProgCard",
    Size = UDim2.new(1, 0, 0, 260),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
})

make("TextLabel", AutoProgCard, {
    Name = "AutoProgHeader",
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 14, 0, 8),
    BackgroundTransparency = 1,
    Text = "Auto Progress",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 5,
})

local AutoProgScroll = make("ScrollingFrame", AutoProgCard, {
    Size = UDim2.new(1, -16, 1, -48),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})

make("UIListLayout", AutoProgScroll, {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})

make("UIPadding", AutoProgScroll, {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 10),
})

-- Master toggle row
local apMasterRow = make("Frame", AutoProgScroll, {
    Name = "APMasterRow",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel = 0,
    LayoutOrder = 1,
})
corner(apMasterRow, 8)
stroke(apMasterRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", apMasterRow, {
    Size = UDim2.new(0, 230, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Auto Progress",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})

local updateAPSwitch = createToggleSwitch(apMasterRow, _G.AutoProgressToggle, function(newState, triggerUpdate)
    _G.AutoProgressToggle = newState
    triggerUpdate(newState)
end)

-- Auto Super Multiply row
local apSMRow = make("Frame", AutoProgScroll, {
    Name = "APSMRow",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel = 0,
    LayoutOrder = 2,
})
corner(apSMRow, 8)
stroke(apSMRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", apSMRow, {
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Super Multiply",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})

local updateAPSM = createToggleSwitch(apSMRow, _G.AutoSuperMultiplyToggle, function(newState, triggerUpdate)
    _G.AutoSuperMultiplyToggle = newState
    triggerUpdate(newState)
end)

local apSMInput = make("TextBox", apSMRow, {
    Size = UDim2.new(0, 90, 0, 26),
    Position = UDim2.new(0, 250, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.AutoSuperMultiplyNumber,
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextYAlignment = Enum.TextYAlignment.Center,
    ClearTextOnFocus = false,
})
corner(apSMInput, 5)
stroke(apSMInput, 1, C.BORDER_GLOW, 0.4)

apSMInput.FocusLost:Connect(function()
    local raw = apSMInput.Text:match("^%s*(.-)%s*$")
    if raw and raw ~= "" then
        local okNum
        if raw:match("^%d+$") then
            okNum = tonumber(raw)
        else
            local upper = string.upper(raw)
            local numPart, suffix = upper:match("^(%d+)([%a]+)$")
            if numPart and suffix then
                local num = tonumber(numPart)
                local exp = suffixToExp[suffix]
                if num and exp and num >= 1 then
                    okNum = num * (10 ^ exp)
                end
            end
        end
        if okNum then
            _G.AutoSuperMultiplyNumber = raw
            apSMInput.Text = raw
        else
            apSMInput.Text = _G.AutoSuperMultiplyNumber
        end
    else
        apSMInput.Text = _G.AutoSuperMultiplyNumber
    end
end)

-- Auto Prestige row
local apPreRow = make("Frame", AutoProgScroll, {
    Name = "APPreRow",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel = 0,
    LayoutOrder = 3,
})
corner(apPreRow, 8)
stroke(apPreRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", apPreRow, {
    Size = UDim2.new(0, 150, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Prestige",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})

local updateAPPre = createToggleSwitch(apPreRow, _G.AutoPrestigeToggle, function(newState, triggerUpdate)
    _G.AutoPrestigeToggle = newState
    triggerUpdate(newState)
end)

local apPreDisplay = make("TextButton", apPreRow, {
    Size = UDim2.new(0, 90, 0, 26),
    Position = UDim2.new(0, 250, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.AutoPrestigeNumber,
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextYAlignment = Enum.TextYAlignment.Center,
    Active = true,
    ZIndex = 6,
})
corner(apPreDisplay, 5)
stroke(apPreDisplay, 1, C.BORDER_GLOW, 0.4)

local apPreInput = make("TextBox", apPreRow, {
    Size = UDim2.new(0, 90, 0, 26),
    Position = UDim2.new(0, 250, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.AutoPrestigeNumber,
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.Code,
    TextSize = 11,
    TextYAlignment = Enum.TextYAlignment.Center,
    Visible = false,
    ClearTextOnFocus = false,
    ZIndex = 7,
})
corner(apPreInput, 5)
stroke(apPreInput, 1, C.BORDER_GLOW, 0.4)

apPreDisplay.Activated:Connect(function()
    apPreInput.Text = _G.AutoPrestigeNumber
    apPreInput.Visible = true
    apPreInput:CaptureFocus()
end)

local apPreTyped = _G.AutoPrestigeNumber

apPreInput:GetPropertyChangedSignal("Text"):Connect(function()
    if apPreInput:IsFocused() then apPreTyped = apPreInput.Text end
end)

apPreInput.FocusLost:Connect(function()
    apPreInput.Visible = false
    local num = tonumber(apPreTyped)
    if num and num >= 1 then
        local r = math.floor(num / 2 + 0.5) * 2
        if r < 2 then r = 2 end
        local rs = tostring(r)
        _G.AutoPrestigeNumber = rs
        apPreDisplay.Text = rs
    end
end)

-- Auto Ascend row (no textbox)
local apAscRow = make("Frame", AutoProgScroll, {
    Name = "APAscRow",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel = 0,
    LayoutOrder = 4,
})
corner(apAscRow, 8)
stroke(apAscRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", apAscRow, {
    Size = UDim2.new(0, 230, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Ascend (auto when req met)",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamMedium,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})

local updateAPAsc = createToggleSwitch(apAscRow, _G.AutoAscendToggle, function(newState, triggerUpdate)
    _G.AutoAscendToggle = newState
    triggerUpdate(newState)
end)

-- Auto Progress keybind row
local apKeyRow = make("Frame", AutoProgScroll, {
    Name = "APKeyRow",
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel = 0,
    LayoutOrder = 5,
})
corner(apKeyRow, 8)
stroke(apKeyRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", apKeyRow, {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Auto Progress Hotkey:",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})

local APKeyBtn = make("TextButton", apKeyRow, {
    Size = UDim2.new(0, 100, 0, 26),
    Position = UDim2.new(0, 170, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.AutoProgressKeybind,
    TextColor3 = C.ACCENT_PURPLE,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextYAlignment = Enum.TextYAlignment.Center,
    Active = true,
})
corner(APKeyBtn, 5)
stroke(APKeyBtn, 1.2, C.BORDER_GLOW, 0.4)

APKeyBtn.Activated:Connect(function()
    _G.captureTarget = APKeyBtn
    _G.captureCallback = function(k) _G.AutoProgressKeybind = k end
    APKeyBtn.Text = "..."
    APKeyBtn.TextColor3 = C.TEXT_SUB
end)

local FarmCardRow = make("Frame", FarmTab, {
    Name = "FarmCardRow",
    Size = UDim2.new(1, 0, 0, 400),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
})

local CloverCard = makeCard(FarmCardRow, "CloverCard", UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0), C.BG_CARD, 12)
stroke(CloverCard, 1, C.BORDER_GLOW, 0.5)

local CloverHeaderLabel = make("TextLabel", CloverCard, {
    Name             = "CloverHeaderLabel",
    Size             = UDim2.new(1, -20, 0, 32),
    Position         = UDim2.new(0, 14, 0, 8),
    BackgroundTransparency = 1,
    Text             = "Clover Farming",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 5
})

local CloverScroll = make("ScrollingFrame", CloverCard, {
    Size             = UDim2.new(1, -16, 1, -48),
    Position         = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize       = UDim2.new(0, 0, 0, 0), 
    AutomaticCanvasSize = Enum.AutomaticSize.Y
})

make("UIListLayout", CloverScroll, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 8)
})

make("UIPadding", CloverScroll, {
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 10)
})

local AutoFarmCard = makeCard(FarmCardRow, "AutoFarmCard", UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0), C.BG_CARD, 12)
stroke(AutoFarmCard, 1, C.BORDER_GLOW, 0.5)

local AutoFarmHeaderLabel = make("TextLabel", AutoFarmCard, {
    Name             = "AutoFarmHeaderLabel",
    Size             = UDim2.new(1, -20, 0, 32),
    Position         = UDim2.new(0, 14, 0, 8),
    BackgroundTransparency = 1,
    Text             = "Auto Farm Loop",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ZIndex           = 5
})

local AutoFarmScroll = make("ScrollingFrame", AutoFarmCard, {
    Size             = UDim2.new(1, -16, 1, -48),
    Position         = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize       = UDim2.new(0, 0, 0, 0), 
    AutomaticCanvasSize = Enum.AutomaticSize.Y
})

make("UIListLayout", AutoFarmScroll, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 8)
})

make("UIPadding", AutoFarmScroll, {
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 10)
})

-- Clover Farm Config Block
local CloverRow = makeCard(CloverScroll, "CloverRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
CloverRow.LayoutOrder = 1

local cloverTxt = make("TextLabel", CloverRow, {
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Clover Farm Loop",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

local updateCloverSwitch = createToggleSwitch(CloverRow, _G.CloverFarming, function(newState, triggerUpdate)
    _G.CloverFarming = newState
    triggerUpdate(_G.CloverFarming)
end)

-- Clover Capture Hotkey Box
local KeyRow1 = makeCard(CloverScroll, "KeyRow1", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
KeyRow1.LayoutOrder = 2

make("TextLabel", KeyRow1, {
    Size             = UDim2.new(0, 140, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Clover Farm Hotkey:",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

local KeyBtn1 = make("TextButton", KeyRow1, {
    Size             = UDim2.new(0, 120, 0, 26),
    Position         = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text             = _G.FarmKeybind,
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextYAlignment   = Enum.TextYAlignment.Center,
    Active           = true,
})
corner(KeyBtn1, 5)
stroke(KeyBtn1, 1.2, C.BORDER_GLOW, 0.4)

KeyBtn1.Activated:Connect(function()
    _G.captureTarget = KeyBtn1
    _G.captureCallback = function(k) _G.FarmKeybind = k end
    KeyBtn1.Text = "..."
    KeyBtn1.TextColor3 = C.TEXT_SUB
end)

-- Clover World toggle row
local WorldRow = makeCard(CloverScroll, "WorldRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
WorldRow.LayoutOrder = 3

make("TextLabel", WorldRow, {
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Clover World?",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

createToggleSwitch(WorldRow, _G.CloverWorldMode, function(newState, triggerUpdate)
    _G.CloverWorldMode = newState
    triggerUpdate(_G.CloverWorldMode)
end)

-- Clover Farm Speed textbox
local SpeedRow = makeCard(CloverScroll, "SpeedRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
SpeedRow.LayoutOrder = 4

make("TextLabel", SpeedRow, {
    Size             = UDim2.new(0, 140, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Farm Speed (s):",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

local CloverSpeedInput = make("TextBox", SpeedRow, {
    Size             = UDim2.new(0, 90, 0, 26),
    Position         = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text             = tostring(_G.FarmWaitTime),
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ClearTextOnFocus = false,
})
corner(CloverSpeedInput, 5)
stroke(CloverSpeedInput, 1, C.BORDER_GLOW, 0.4)

CloverSpeedInput.FocusLost:Connect(function()
    local val = tonumber(CloverSpeedInput.Text)
    if val and val >= 0.005 then
        _G.FarmWaitTime = val
        if TimeInput then TimeInput.Text = tostring(val) end
    else
        CloverSpeedInput.Text = tostring(_G.FarmWaitTime)
    end
end)

-- Touch Autofarm Master Block
local Row3 = makeCard(AutoFarmScroll, "DropdownRow3", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
Row3.LayoutOrder = 1

make("TextLabel", Row3, {
    Size             = UDim2.new(0, 240, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Autofarm",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})
local bfUpdateSwitch       -- forward-declared for mutual exclusion
local updateRebirthSwitch   -- forward-declared
local updateRebirthBuySwitch -- forward-declared
local updateAutoFarmSwitch = createToggleSwitch(Row3, _G.ButtonAutofarm, function(newState, triggerUpdate)
    _G.ButtonAutofarm = newState
    triggerUpdate(_G.ButtonAutofarm)
end)

-- Auto Roll Rarity Block (independent toggle)
local RollRow = makeCard(AutoFarmScroll, "RollRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
RollRow.LayoutOrder = 2

make("TextLabel", RollRow, {
    Size             = UDim2.new(0, 240, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Auto Roll Rarity",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})
local updateAutoRollSwitch = createToggleSwitch(RollRow, _G.AutoRoll, function(newState, triggerUpdate)
    _G.AutoRoll = newState
    -- explicitly: this toggle only manages Auto Roll Rarity.
    -- Turning it ON or OFF must never touch _G.ButtonAutofarm.
    triggerUpdate(_G.AutoRoll)
end)

-- Rebirth Get Block
local Row1 = makeCard(AutoFarmScroll, "DropdownRow1", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
Row1.LayoutOrder = 3

make("TextLabel", Row1, {
    Size             = UDim2.new(0, 240, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Collect Rebirth Multipliers",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})
updateRebirthSwitch = createToggleSwitch(Row1, _G.RebirthToggle, function(newState, triggerUpdate)
    _G.RebirthToggle = newState
    if newState and _G.ButtonFarmToggle then
        _G.ButtonFarmToggle = false
        if bfUpdateSwitch then bfUpdateSwitch(false) end
    end
    triggerUpdate(_G.RebirthToggle)
end)

-- Buy Rebirths Block
local Row2 = makeCard(AutoFarmScroll, "DropdownRow2", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
Row2.LayoutOrder = 4

make("TextLabel", Row2, {
    Size             = UDim2.new(0, 240, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Automate Rebirth Tier Purchases",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})
updateRebirthBuySwitch = createToggleSwitch(Row2, _G.RebirthBuyToggle, function(newState, triggerUpdate)
    _G.RebirthBuyToggle = newState
    if newState and _G.ButtonFarmToggle then
        _G.ButtonFarmToggle = false
        if bfUpdateSwitch then bfUpdateSwitch(false) end
    end
    if not newState then
        _G.RebirthCurrentIndex = 1
    end
    triggerUpdate(_G.RebirthBuyToggle)
end)

-- Sequence Input Config Box — toggleable number chips
local SeqRow = makeCard(AutoFarmScroll, "SeqRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
SeqRow.LayoutOrder = 5

make("UIListLayout", SeqRow, {
    FillDirection    = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 6),
})
make("UIPadding", SeqRow, {
    PaddingLeft   = UDim.new(0, 10),
    PaddingRight  = UDim.new(0, 4),
})

make("TextLabel", SeqRow, {
    Size             = UDim2.new(0, 130, 1, 0),
    BackgroundTransparency = 1,
    Text             = "Rebirth Order Index:",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

-- Parse current sequence into a set of active numbers
local activeSet = {}
for choice in string.gmatch(_G.RebirthSequence, "([^,]+)") do
    local n = tonumber(choice:match("^%s*(.-)%s*$"))
    if n then activeSet[n] = true end
end

local ON_COLOR = C.ACCENT_PURPLE
local OFF_COLOR = C.ICON_MUTED

local chipContainer = make("Frame", SeqRow, {
    Size             = UDim2.new(0, 154, 1, 0),
    BackgroundTransparency = 1,
})
make("UIListLayout", chipContainer, {
    FillDirection    = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding          = UDim.new(0, 6),
})

local function rebuildSequence()
    local parts = {}
    for i = 1, 4 do
        if activeSet[i] then table.insert(parts, tostring(i)) end
    end
    _G.RebirthSequence = table.concat(parts, ",")
end

local chips = {}
for i = 1, 4 do
    local active = activeSet[i] or false
    local chip = make("TextButton", chipContainer, {
        Name             = "Chip" .. tostring(i),
        Size             = UDim2.new(0, 32, 0, 28),
        BackgroundColor3 = active and ON_COLOR or OFF_COLOR,
        Text             = tostring(i),
        TextColor3       = Color3.fromRGB(255, 255, 255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextYAlignment   = Enum.TextYAlignment.Center,
        Active           = true,
        ZIndex           = 5,
    })
    corner(chip, 6)
    local chipStroke = stroke(chip, 1, C.BORDER_GLOW, active and 0.2 or 0.5)

    chip.Activated:Connect(function()
        activeSet[i] = not activeSet[i]
        local newActive = activeSet[i]
        chip.BackgroundColor3 = newActive and ON_COLOR or OFF_COLOR
        tween(chip, FAST, { BackgroundColor3 = newActive and ON_COLOR or OFF_COLOR })
        tween(chipStroke, FAST, { Transparency = newActive and 0.2 or 0.5 })
        rebuildSequence()
    end)

    chips[i] = chip
end

-- Delay Rate Config Slider Box
local TimeRow = makeCard(AutoFarmScroll, "TimeRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
TimeRow.LayoutOrder = 6

make("TextLabel", TimeRow, {
    Size             = UDim2.new(0, 140, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Refresh Threshold (s):",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

local TimeInput = make("TextBox", TimeRow, {
    Size             = UDim2.new(0, 90, 0, 26),
    Position         = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text             = tostring(_G.FarmWaitTime),
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.Code,
    TextSize         = 12,
    TextYAlignment   = Enum.TextYAlignment.Center,
    ClearTextOnFocus = false
})
corner(TimeInput, 5)
stroke(TimeInput, 1, C.BORDER_GLOW, 0.4)

TimeInput.FocusLost:Connect(function()
    local val = tonumber(TimeInput.Text)
    if val and val >= 0.005 then
        _G.FarmWaitTime = val
        if CloverSpeedInput then CloverSpeedInput.Text = tostring(val) end
    else
        TimeInput.Text = tostring(_G.FarmWaitTime)
    end
end)

-- Touch Capture Hotkey Box
local KeyRow2 = makeCard(AutoFarmScroll, "KeyRow2", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
KeyRow2.LayoutOrder = 7

make("TextLabel", KeyRow2, {
    Size             = UDim2.new(0, 140, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Touch Farm Hotkey:",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextYAlignment   = Enum.TextYAlignment.Center,
    Active           = true,
})

local KeyBtn2 = make("TextButton", KeyRow2, {
    Size             = UDim2.new(0, 120, 0, 26),
    Position         = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text             = _G.AutoFarmKeybind,
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    TextYAlignment   = Enum.TextYAlignment.Center,
    Active           = true,
})
corner(KeyBtn2, 5)
stroke(KeyBtn2, 1.2, C.BORDER_GLOW, 0.4)

KeyBtn2.Activated:Connect(function()
    _G.captureTarget = KeyBtn2
    _G.captureCallback = function(k) _G.AutoFarmKeybind = k end
    KeyBtn2.Text = "..."
    KeyBtn2.TextColor3 = C.TEXT_SUB
end)

-- ─────────────────────────────────────────────────────────────────
--  Rune Farm + Button Farm Cards
-- ─────────────────────────────────────────────────────────────────
local FarmRow2 = make("Frame", FarmTab, {
    Name = "FarmRow2",
    Size = UDim2.new(1, 0, 0, 400),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
})

-- ── Rune Farm Card (left) ─────────────────────────────────────
local RuneFarmCard = makeCard(FarmRow2, "RuneFarmCard", UDim2.new(0.5, -6, 1, 0), UDim2.new(0, 0, 0, 0), C.BG_CARD, 12)
stroke(RuneFarmCard, 1, C.BORDER_GLOW, 0.5)

make("TextLabel", RuneFarmCard, {
    Name = "RuneFarmHeader",
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 14, 0, 8),
    BackgroundTransparency = 1,
    Text = "Rune Farm",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 5,
})

local RuneScroll = make("ScrollingFrame", RuneFarmCard, {
    Size = UDim2.new(1, -16, 1, -48),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
make("UIListLayout", RuneScroll, {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})
make("UIPadding", RuneScroll, {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 10),
})

local MasterRow = makeCard(RuneScroll, "MasterRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
MasterRow.LayoutOrder = 1
make("TextLabel", MasterRow, {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Rune Farm",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
local updateRuneMaster = createToggleSwitch(MasterRow, _G.RuneFarmMaster, function(newState, triggerUpdate)
    _G.RuneFarmMaster = newState
    triggerUpdate(newState)
end)

local runeUpdates = {}
local function runeRow(name, layoutOrder)
    local row = makeCard(RuneScroll, name.."Row", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
    row.LayoutOrder = layoutOrder
    make("TextLabel", row, {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = C.TEXT_PRIMARY,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    local update = createToggleSwitch(row, _G["Rune"..name.."Toggle"], function(newState, triggerUpdate)
        _G["Rune"..name.."Toggle"] = newState
        triggerUpdate(newState)
    end)
    runeUpdates[name] = update
end

runeRow("Clover", 2)
runeRow("Plant", 3)
runeRow("Baseluck", 4)
runeRow("Prestige", 5)

local RuneKeyRow = makeCard(RuneScroll, "RuneKeyRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
RuneKeyRow.LayoutOrder = 6
make("TextLabel", RuneKeyRow, {
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Rune Farm Hotkey:",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
local RuneKeyBtn = make("TextButton", RuneKeyRow, {
    Size = UDim2.new(0, 120, 0, 26),
    Position = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.RuneFarmKeybind,
    TextColor3 = C.ACCENT_PURPLE,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextYAlignment = Enum.TextYAlignment.Center,
    Active = true,
})
corner(RuneKeyBtn, 5)
stroke(RuneKeyBtn, 1.2, C.BORDER_GLOW, 0.4)
RuneKeyBtn.Activated:Connect(function()
    _G.captureTarget = RuneKeyBtn
    _G.captureCallback = function(k) _G.RuneFarmKeybind = k end
    RuneKeyBtn.Text = "..."
    RuneKeyBtn.TextColor3 = C.TEXT_SUB
end)

-- ── Button Farm Card (right) ──────────────────────────────────
local ButtonFarmCard = makeCard(FarmRow2, "ButtonFarmCard", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), C.BG_CARD, 12)
stroke(ButtonFarmCard, 1, C.BORDER_GLOW, 0.5)

make("TextLabel", ButtonFarmCard, {
    Name = "ButtonFarmHeader",
    Size = UDim2.new(1, -20, 0, 32),
    Position = UDim2.new(0, 14, 0, 8),
    BackgroundTransparency = 1,
    Text = "Button Farm",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 5,
})

local BFScroll = make("ScrollingFrame", ButtonFarmCard, {
    Size = UDim2.new(1, -16, 1, -48),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
make("UIListLayout", BFScroll, {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})
make("UIPadding", BFScroll, {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 10),
})

-- Button Farm data collection
local ButtonFarmData = {}
do
    local allButtons = workspace.Buttons:GetChildren()
    for _, btn in ipairs(allButtons) do
        local s = btn:FindFirstChild("Script")
        local r = s and s:FindFirstChild("Requiredrarity")
        if r then
            local raw = r.Value
            local a, b = raw:match("^(%d+);(.+)$")
            if a and b then
                local base = tonumber(a)
                local exp = tonumber(b:match("^%d+"))
                local val
                if base == 0 then val = exp else val = base * (10 ^ #b) end
                if val and val > 0 then
                    local up3 = btn:FindFirstChild("Up3")
                    local tl = up3 and up3:FindFirstChild("TextLabel")
                    local text = tl and tl.Text or btn.Name
                    table.insert(ButtonFarmData, {btn=btn, name=btn.Name, req=val, raw=raw, text=text})
                end
            end
        end
    end
    table.sort(ButtonFarmData, function(a,b) return a.req < b.req end)
end

if #ButtonFarmData == 0 then
    table.insert(ButtonFarmData, {btn=nil, name="None", req=0, raw="0;0", text="(None)"})
end

-- Button Farm Master toggle
local BFRow = makeCard(BFScroll, "ButtonFarmRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
BFRow.LayoutOrder = 1
make("TextLabel", BFRow, {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Button Farm",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
bfUpdateSwitch = createToggleSwitch(BFRow, _G.ButtonFarmToggle, function(newState, triggerUpdate)
    _G.ButtonFarmToggle = newState
    if newState then
        if _G.RebirthToggle then
            _G.RebirthToggle = false
            if updateRebirthSwitch then updateRebirthSwitch(false) end
        end
        if _G.RebirthBuyToggle then
            _G.RebirthBuyToggle = false
            if updateRebirthBuySwitch then updateRebirthBuySwitch(false) end
        end
    end
    triggerUpdate(newState)
end)

-- Smart Button toggle
local SmartRow = makeCard(BFScroll, "SmartButtonRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
SmartRow.LayoutOrder = 2
make("TextLabel", SmartRow, {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Smart Button",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
createToggleSwitch(SmartRow, _G.SmartButtonToggle, function(newState, triggerUpdate)
    _G.SmartButtonToggle = newState
    triggerUpdate(newState)
end)

-- Dropdown row
local BFDropdownRow = makeCard(BFScroll, "BFDropdownRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
BFDropdownRow.LayoutOrder = 3
BFDropdownRow.ClipsDescendants = false

local bfDropdownHeader = make("TextButton", BFDropdownRow, {
    Size = UDim2.new(1, -16, 0, 30),
    Position = UDim2.new(0, 8, 0, 7),
    BackgroundColor3 = C.BG_CARD,
    Text = ButtonFarmData[_G.ButtonFarmSelectionIdx] and ButtonFarmData[_G.ButtonFarmSelectionIdx].text or "Rare",
    TextColor3 = C.ACCENT_PURPLE,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Active = true,
    ZIndex = 10,
})
corner(bfDropdownHeader, 5)
stroke(bfDropdownHeader, 1, C.BORDER_GLOW, 0.4)

local BFDropdownList = make("ScrollingFrame", BFDropdownRow, {
    Size = UDim2.new(1, -16, 0, 0),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundColor3 = C.BG_CARD,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 15,
    ScrollBarThickness = 6,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
corner(BFDropdownList, 5)
stroke(BFDropdownList, 1, C.BORDER_GLOW, 0.6)

make("UIListLayout", BFDropdownList, {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
})
make("UIPadding", BFDropdownList, {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
})

local function closeBFDropdown()
    BFDropdownList.Visible = false
    BFDropdownRow.Size = UDim2.new(1, 0, 0, 44)
end

local bfDropdownBtns = {}
for i, data in ipairs(ButtonFarmData) do
    local item = make("TextButton", BFDropdownList, {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = C.BG_CARD2,
        Text = data.text,
        TextColor3 = i == _G.ButtonFarmSelectionIdx and C.ACCENT_PINK or C.TEXT_PRIMARY,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Active = true,
        ZIndex = 16,
        LayoutOrder = i,
    })
    corner(item, 3)
    item.Activated:Connect(function()
        _G.ButtonFarmSelectionIdx = i
        bfDropdownHeader.Text = data.text
        closeBFDropdown()
        for _, b in ipairs(bfDropdownBtns) do b.TextColor3 = C.TEXT_PRIMARY end
        item.TextColor3 = C.ACCENT_PINK
    end)
    table.insert(bfDropdownBtns, item)
end

bfDropdownHeader.Activated:Connect(function()
    if BFDropdownList.Visible then
        closeBFDropdown()
    else
        BFDropdownList.Visible = true
        local itemCount = math.min(#ButtonFarmData, 8)
        local ddHeight = itemCount * 26 + 10
        BFDropdownList.Size = UDim2.new(1, -16, 0, ddHeight)
        BFDropdownRow.Size = UDim2.new(1, 0, 0, 44 + ddHeight + 4)
    end
end)

-- Button Farm keybind row
local BFKeyRow = makeCard(BFScroll, "BFKeyRow", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), C.BG_CARD2, 6)
BFKeyRow.LayoutOrder = 4
make("TextLabel", BFKeyRow, {
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "Button Farm Hotkey:",
    TextColor3 = C.TEXT_PRIMARY,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
})
local BFKeyBtn = make("TextButton", BFKeyRow, {
    Size = UDim2.new(0, 120, 0, 26),
    Position = UDim2.new(0, 160, 0.5, -13),
    BackgroundColor3 = C.BG_CARD,
    Text = _G.ButtonFarmKeybind,
    TextColor3 = C.ACCENT_PURPLE,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextYAlignment = Enum.TextYAlignment.Center,
    Active = true,
})
corner(BFKeyBtn, 5)
stroke(BFKeyBtn, 1.2, C.BORDER_GLOW, 0.4)
BFKeyBtn.Activated:Connect(function()
    _G.captureTarget = BFKeyBtn
    _G.captureCallback = function(k) _G.ButtonFarmKeybind = k end
    BFKeyBtn.Text = "..."
    BFKeyBtn.TextColor3 = C.TEXT_SUB
end)

-- Smart Button: find best match below player rarity
local function getSmartButtonTarget()
    local pd = LocalPlayer and LocalPlayer:FindFirstChild("PlayerData")
    local rs = pd and pd:FindFirstChild("Rarity")
    if not rs then return nil end
    local raw = rs.Value
    local a, b = raw:match("^(%d+);(.+)$")
    if not a then return nil end
    local base = tonumber(a)
    local exp = tonumber(b:match("^%d+"))
    if not exp then return nil end
    local playerVal
    if base == 0 then playerVal = exp else playerVal = base * (10 ^ #b) end
    if not playerVal then return nil end
    local best
    for _, data in ipairs(ButtonFarmData) do
        if data.req <= playerVal then best = data end
    end
    return best
end

-- Keybind Processing Core Engine Connection
UserInputService.InputBegan:Connect(function(input, processed)
    -- Block shiftlock from Right Shift when it's the GUI toggle key
    if input.KeyCode == Enum.KeyCode.RightShift then
        -- consume without triggering shiftlock by checking early
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local keyName = input.KeyCode.Name

    -- Farm / GUI toggle hotkeys — FIRST, before capture mode, so they never lag
    if keyName == _G.FarmKeybind then
        _G.CloverFarming = not _G.CloverFarming
        updateCloverSwitch(_G.CloverFarming)
        return
    elseif keyName == _G.AutoFarmKeybind then
        _G.ButtonAutofarm = not _G.ButtonAutofarm
        updateAutoFarmSwitch(_G.ButtonAutofarm)
        return
    elseif keyName == _G.RuneFarmKeybind then
        _G.RuneFarmMaster = not _G.RuneFarmMaster
        if updateRuneMaster then updateRuneMaster(_G.RuneFarmMaster) end
        return
    elseif keyName == _G.ButtonFarmKeybind then
        _G.ButtonFarmToggle = not _G.ButtonFarmToggle
        if bfUpdateSwitch then bfUpdateSwitch(_G.ButtonFarmToggle) end
        return
    elseif keyName == _G.AutoProgressKeybind then
        _G.AutoProgressToggle = not _G.AutoProgressToggle
        if updateAPSwitch then updateAPSwitch(_G.AutoProgressToggle) end
        return
    elseif keyName == _G.GuiToggleKeybind then
        guiVisible = not guiVisible
        MainFrame.Visible = guiVisible
        GlowFrame.Visible = guiVisible
        return
    end

    -- Capture mode — single generic pointer works regardless of closure scoping
    if _G.captureTarget then
        if _G.captureCallback then _G.captureCallback(keyName) end
        _G.captureTarget.Text = keyName
        _G.captureTarget.TextColor3 = C.ACCENT_PURPLE
        _G.captureTarget = nil
        _G.captureCallback = nil
        return
    end

    if processed then return end

    -- Teleport hotkeys (require processed = false to avoid double-triggering)
    if keyName == _G.TpRollKeybind then pcall(function()
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local rr = workspace:FindFirstChild("Roll System") and workspace["Roll System"]:FindFirstChild("RollRarity")
            if rr then root.CFrame = CFrame.new(rr.Position.X, rr.Position.Y+5, rr.Position.Z) end
        end
    end)
    elseif keyName == _G.TpRebirthKeybind then pcall(function()
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local rb = workspace:FindFirstChild("Buttons") and workspace.Buttons:FindFirstChild("Rebirth Get")
            if rb then root.CFrame = CFrame.new(rb.Position.X, rb.Position.Y+5, rb.Position.Z) end
        end
    end)
    elseif keyName == _G.TpCloverKeybind then pcall(function()
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(-1035, 26, 21379) end
    end)
    elseif keyName == _G.TpBaseLuckKeybind then pcall(function()
        local char = LocalPlayer.Character local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(-678, 312, -195) end
    end)
    end
end)




-- ─────────────────────────────────────────────────────────────────
-- 9.  CONFIG TAB — GUI toggle keybind
-- ─────────────────────────────────────────────────────────────────
local ConfigTab = make("Frame", ContentArea, {
    Name             = "ConfigTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
})

local ConfigScroll = make("ScrollingFrame", ConfigTab, {
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize       = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
})
make("UIListLayout", ConfigScroll, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 4)
})
make("UIPadding", ConfigScroll, {
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 4)
})

-- Subtitle
make("TextLabel", ConfigScroll, {
    Name             = "ConfigSubtitle",
    Size             = UDim2.new(1, -8, 0, 40),
    LayoutOrder      = 0,
    BackgroundTransparency = 1,
    Text             = "Configure your GUI toggle keybind. Press Right Shift to open/close the hub by default.",
    TextColor3       = C.TEXT_SUB,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
    TextWrapped      = true,
})

-- GUI Toggle keybind row
local guiRow = make("Frame", ConfigScroll, {
    Name             = "ConfigGuiRow",
    Size             = UDim2.new(1, 0, 0, 42),
    LayoutOrder      = 1,
    BackgroundColor3 = C.BG_CARD2,
    BorderSizePixel  = 0,
})
corner(guiRow, 8)
stroke(guiRow, 1, C.BORDER_GLOW, 0.55)

make("TextLabel", guiRow, {
    Size             = UDim2.new(0.6, -20, 1, 0),
    Position         = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text             = "GUI Close / Open Key",
    TextColor3       = C.TEXT_PRIMARY,
    Font             = Enum.Font.GothamMedium,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Center,
})

local guiKeyBtn = make("TextButton", guiRow, {
    Size             = UDim2.new(0, 70, 0, 28),
    Position         = UDim2.new(1, -82, 0.5, -14),
    BackgroundColor3 = C.BG_CARD,
    Text             = _G.GuiToggleKeybind,
    TextColor3       = C.ACCENT_PURPLE,
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextYAlignment   = Enum.TextYAlignment.Center,
    Active           = true,
    ZIndex           = 5,
})
corner(guiKeyBtn, 6)
stroke(guiKeyBtn, 1, C.BORDER_GLOW, 0.35)

guiKeyBtn.Activated:Connect(function()
    _G.captureTarget = guiKeyBtn
    _G.captureCallback = function(k) _G.GuiToggleKeybind = k end
    guiKeyBtn.Text = "..."
    guiKeyBtn.TextColor3 = C.TEXT_SUB
end)

-- ─────────────────────────────────────────────────────────────────
-- 10. TP TAB — dropdown-style teleport list
-- ─────────────────────────────────────────────────────────────────
local TPTab = make("Frame", ContentArea, {
    Name             = "TPTab",
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Visible          = false,
    ZIndex           = 3,
})

local TPScroll = make("ScrollingFrame", TPTab, {
    Size             = UDim2.new(1, 0, 1, 0),
    Position         = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.ACCENT_PURPLE,
    CanvasSize       = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
})
make("UIListLayout", TPScroll, {
    FillDirection    = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder        = Enum.SortOrder.LayoutOrder,
    Padding          = UDim.new(0, 4)
})
make("UIPadding", TPScroll, {
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 12),
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 4)
})

-- shared teleport helpers
local function tpToPos(x, y, z)
    pcall(function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(x, y, z) end
    end)
end

local function tpToInstance(inst)
    pcall(function()
        if not inst then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(inst.Position.X, inst.Position.Y + 5, inst.Position.Z) end
    end)
end

-- Builds one dropdown-style row: click anywhere = teleport, click keybind badge = rebind
local function makeTPRow(order, label, defaultKey, onTeleport)
    local row = make("Frame", TPScroll, {
        Name             = "TPRow_" .. tostring(order),
        Size             = UDim2.new(1, 0, 0, 42),
        LayoutOrder      = order,
        BackgroundColor3 = C.BG_CARD2,
        BorderSizePixel  = 0,
    })
    corner(row, 8)
    stroke(row, 1, C.BORDER_GLOW, 0.55)

    local labelTxt = make("TextLabel", row, {
        Size             = UDim2.new(1, -100, 1, 0),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text             = label,
        TextColor3       = C.TEXT_PRIMARY,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
    })

    local keyBtn = make("TextButton", row, {
        Size             = UDim2.new(0, 70, 0, 28),
        Position         = UDim2.new(1, -82, 0.5, -14),
        BackgroundColor3 = C.BG_CARD,
        Text             = defaultKey,
        TextColor3       = C.ACCENT_PURPLE,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextYAlignment   = Enum.TextYAlignment.Center,
        Active           = true,
        ZIndex           = 5,
    })
    corner(keyBtn, 6)
    stroke(keyBtn, 1, C.BORDER_GLOW, 0.35)

    -- Click the row body = teleport
    local clickArea = make("TextButton", row, {
        Size             = UDim2.new(1, -90, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text             = "",
        Active           = true,
        ZIndex           = 4,
    })
    clickArea.Activated:Connect(onTeleport)

    return keyBtn
end

-- Row 1: Roll
rollKeyBtn = makeTPRow(1, "Roll", _G.TpRollKeybind, function()
    pcall(function()
        local rr = workspace:FindFirstChild("Roll System") and workspace["Roll System"]:FindFirstChild("RollRarity")
        tpToInstance(rr)
    end)
end)

-- Row 2: Rebirth
rebirthKeyBtn = makeTPRow(2, "Rebirth", _G.TpRebirthKeybind, function()
    pcall(function()
        local rb = workspace:FindFirstChild("Buttons") and workspace.Buttons:FindFirstChild("Rebirth Get")
        tpToInstance(rb)
    end)
end)

-- Row 3: Clover World
cloverKeyBtn = makeTPRow(3, "Clover World", _G.TpCloverKeybind, function()
    tpToPos(-1035, 26, 21379)
end)

-- Row 4: Base Luck
baseluckKeyBtn = makeTPRow(4, "Base Luck", _G.TpBaseLuckKeybind, function()
    tpToPos(-678, 312, -195)
end)

-- Keybind capture triggers
rollKeyBtn.Activated:Connect(function()
    _G.captureTarget = rollKeyBtn
    _G.captureCallback = function(k) _G.TpRollKeybind = k end
    rollKeyBtn.Text = "..."
    rollKeyBtn.TextColor3 = C.TEXT_SUB
end)
rebirthKeyBtn.Activated:Connect(function()
    _G.captureTarget = rebirthKeyBtn
    _G.captureCallback = function(k) _G.TpRebirthKeybind = k end
    rebirthKeyBtn.Text = "..."
    rebirthKeyBtn.TextColor3 = C.TEXT_SUB
end)
cloverKeyBtn.Activated:Connect(function()
    _G.captureTarget = cloverKeyBtn
    _G.captureCallback = function(k) _G.TpCloverKeybind = k end
    cloverKeyBtn.Text = "..."
    cloverKeyBtn.TextColor3 = C.TEXT_SUB
end)
baseluckKeyBtn.Activated:Connect(function()
    _G.captureTarget = baseluckKeyBtn
    _G.captureCallback = function(k) _G.TpBaseLuckKeybind = k end
    baseluckKeyBtn.Text = "..."
    baseluckKeyBtn.TextColor3 = C.TEXT_SUB
end)

-- ─────────────────────────────────────────────────────────────────
-- 11. TAB CONTROL MOTOR SYSTEM ENGAGEMENT
-- ─────────────────────────────────────────────────────────────────
local tabs = {
    HOME = HomeTab,
    FARM = FarmTab,
    TP   = TPTab,
    CONFIG = ConfigTab,
}

local function switchTab(targetId)
    if targetId == activeTab then return end
    
    local oldData = NavButtons[activeTab]
    if oldData then
        tween(oldData.btn, FAST, { BackgroundTransparency = 1 })
        tween(oldData.txt, FAST, { TextColor3 = C.TEXT_SUB })
        tween(oldData.stroke, FAST, { Transparency = 1 })
    end
    tabs[activeTab].Visible = false
    
    activeTab = targetId
    tabs[activeTab].Visible = true
    
    local newData = NavButtons[activeTab]
    if newData then
        tween(newData.btn, FAST, { BackgroundTransparency = 0.4 })
        tween(newData.txt, FAST, { TextColor3 = C.ACCENT_PURPLE })
        tween(newData.stroke, FAST, { Transparency = 0.2 })
    end
end

for id, def in pairs(NavButtons) do
    def.btn.Activated:Connect(function()
        switchTab(id)
    end)
    def.btn.MouseEnter:Connect(function()
        if activeTab ~= id then
            tween(def.txt, FAST, { TextColor3 = C.TEXT_PRIMARY })
        end
    end)
    def.btn.MouseLeave:Connect(function()
        if activeTab ~= id then
            tween(def.txt, FAST, { TextColor3 = C.TEXT_SUB })
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- 12. RUNTIME REBIRTH / CLOVER WORKSPACE HOOK INTERACTION THREADS
-- ─────────────────────────────────────────────────────────────────
local function fireTouch(part)
    if not part or not part:IsA("BasePart") then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        if typeof(firetouchinterest) == "function" then
            firetouchinterest(part, root, 0)
            task.wait(0.01)
            firetouchinterest(part, root, 1)
        else
            -- Teleport player to the part and then immediately back to simulate a touch if firetouchinterest is missing (e.g. in Studio or non-exploit environment)
            local oldCFrame = root.CFrame
            root.CFrame = part.CFrame
            task.wait(0.05)
            root.CFrame = oldCFrame
        end
    end
end

local function findRightColumnBtn(name)
    local kids = workspace.Buttons:GetChildren()
    local candidates = {}
    for _, v in ipairs(kids) do
        if v.Name == name then
            local pos = v:IsA("BasePart") and v.Position
            if pos and pos.X > 100 then
                table.insert(candidates, v)
            end
        end
    end
    if #candidates == 1 then
        return candidates[1]
    elseif #candidates > 1 then
        table.sort(candidates, function(a, b) return a.Position.Z < b.Position.Z end)
        return candidates[1]
    end
end

-- Clover Farm Loop Thread
task.spawn(function()
    while true do
        if _G.CloverFarming then
            pcall(function()
                local folderName = _G.CloverWorldMode and "clova1" or "clova"
                local folder = workspace:FindFirstChild(folderName)
                if folder then
                    for _, clover in ipairs(folder:GetChildren()) do
                        local rootPart = clover:FindFirstChild("Root")
                        if rootPart and rootPart:IsA("BasePart") then
                            fireTouch(rootPart)
                        end
                    end
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Auto Roll Rarity Spam Thread (_G.AutoRoll)
task.spawn(function()
    while true do
        if _G.AutoRoll then
            pcall(function()
                local rollSystem = workspace:FindFirstChild("Roll System")
                local rollPart = rollSystem and rollSystem:FindFirstChild("RollRarity")
                if rollPart and rollPart:IsA("BasePart") then
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root and typeof(firetouchinterest) == "function" then
                        firetouchinterest(rollPart, root, 0)
                        firetouchinterest(rollPart, root, 1)
                    end
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Button Autofarm Loop Thread (Autofarm)
-- Handles rebirth get + rebirth tier purchases with scrolling priority
_G.RebirthCurrentIndex = 1

task.spawn(function()
    while true do
        if _G.ButtonAutofarm then
            pcall(function()
                if _G.RebirthToggle then
                    local btn = workspace:FindFirstChild("Buttons") and workspace.Buttons:FindFirstChild("Rebirth Get")
                    if btn then fireTouch(btn) end

                    if _G.RebirthBuyToggle and _G.RebirthSequence ~= "" then
                        local choices = {}
                        for choice in string.gmatch(_G.RebirthSequence, "[^,]+") do
                            local trimmed = choice:match("^%s*(.-)%s*$")
                            if trimmed and trimmed ~= "" then
                                table.insert(choices, trimmed)
                            end
                        end

                        if #choices > 0 then
                            local offset = ((_G.RebirthCurrentIndex - 1) % #choices) + 1
                            for i = 1, #choices do
                                local idx = ((offset + i - 2) % #choices) + 1
                                local choice = choices[idx]
                                local BTN_NAMES = {
                                    ["1"] = "Rebirth Upgrade11",
                                    ["2"] = "Rebirth Upgrade 5",
                                    ["3"] = "Rebirth Upgrade 6",
                                    ["4"] = "Rebirth Upgrade 7",
                                }
                                local upg = findRightColumnBtn(BTN_NAMES[choice])
                                if upg then fireTouch(upg) end
                            end
                            _G.RebirthCurrentIndex = _G.RebirthCurrentIndex + 1
                            if _G.RebirthCurrentIndex > #choices then
                                _G.RebirthCurrentIndex = 1
                            end
                        end
                    end
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Rune Farm Loop Thread
task.spawn(function()
    local runePaths = {
        Clover   = "runez",
        Plant    = "runeth",
        Baseluck = "runezzz",
        Prestige = "runezz",
    }
    while true do
        if _G.RuneFarmMaster and (_G.RuneCloverToggle or _G.RunePlantToggle or _G.RuneBaseluckToggle or _G.RunePrestigeToggle) then
            pcall(function()
                for name, folderName in pairs(runePaths) do
                    if _G["Rune"..name.."Toggle"] then
                        local folder = workspace:FindFirstChild(folderName)
                        local part = folder and folder:FindFirstChild("RollRarity")
                        if part and part:IsA("BasePart") then
                            local char = LocalPlayer.Character
                            local root = char and char:FindFirstChild("HumanoidRootPart")
                            if root and typeof(firetouchinterest) == "function" then
                                firetouchinterest(part, root, 0)
                                task.wait(0.01)
                                firetouchinterest(part, root, 1)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Button Farm Loop Thread
task.spawn(function()
    while true do
        if _G.ButtonFarmToggle and #ButtonFarmData > 0 then
            pcall(function()
                local target
                if _G.SmartButtonToggle then
                    target = getSmartButtonTarget()
                else
                    target = ButtonFarmData[_G.ButtonFarmSelectionIdx]
                end
                if target and target.btn then
                    fireTouch(target.btn)
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- Auto Progress Loop Thread
task.spawn(function()
    while true do
        if _G.AutoProgressToggle then
            pcall(function()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end

                -- 1. Super Multiply
                if _G.AutoSuperMultiplyToggle then
                    local btn = workspace:FindFirstChild("Buttons") and workspace.Buttons:FindFirstChild("Super Multi Get")
                    if btn then
                        local scriptObj = btn:FindFirstChild("Script")
                        local gives = scriptObj and scriptObj:FindFirstChild("UpgradesMultiMulti")
                        local currentVal = gives and tonumber(gives.Value) or 0
                        local target = valOrDecodeAbbr(_G.AutoSuperMultiplyNumber) or 1
                        if currentVal < target then
                            fireTouch(btn)
                        end
                    end
                end

                -- 2. Prestige
                if _G.AutoPrestigeToggle then
                    local btn = workspace:FindFirstChild("Buttons") and workspace.Buttons:FindFirstChild("Prestige Get")
                    if btn then
                        local upper = btn:FindFirstChild("Up2")
                        local ppText = upper and upper:FindFirstChild("TextLabel")
                        local pp = ppText and tonumber(ppText.Text:match("%+([%d%.]+)")) or 0
                        local target = tonumber(_G.AutoPrestigeNumber) or 2
                        if pp ~= nil and pp < target then
                            fireTouch(btn)
                        end
                    end
                end

                -- 3. Ascend
                if _G.AutoAscendToggle then
                    local ascend = workspace:FindFirstChild("asecnd")
                    local roll = ascend and ascend:FindFirstChild("RollRarity")
                    if roll then
                        local upper = roll:FindFirstChild("Up3")
                        local reqText = upper and upper:FindFirstChild("TextLabel")
                        local reqNum = reqText and tonumber(reqText.Text:match("%((%d+)%)"))
                        if reqNum then
                            local pd = LocalPlayer and LocalPlayer:FindFirstChild("PlayerData")
                            local rs = pd and pd:FindFirstChild("Rarity")
                            local rarityId = rs and tonumber(rs.Value:match("^(%d+);"))
                            if rarityId and rarityId >= reqNum then
                                fireTouch(roll)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(_G.FarmWaitTime)
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- 13. ENTRANCE ANIMATION (CLEANED INPUT PASS-THROUGH VERSION)
-- ─────────────────────────────────────────────────────────────────
MainFrame.Size     = UDim2.new(0, 720, 0, 440)
MainFrame.Position = UDim2.new(0.5, -360, 0.5, -220)
GlowFrame.Size     = UDim2.new(0, 740, 0, 460)
GlowFrame.Position = UDim2.new(0.5, -370, 0.5, -230)

GlowFrame.BackgroundTransparency = 1
tween(GlowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.88 })