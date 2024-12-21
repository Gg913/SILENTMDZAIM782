local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "🔥 AlmazniTrade v2 🔥", HidePremium = false, IntroEnabled = false})

local scam0 = print(1)
local scam1 = print(2)
local scam2 = print(3)

local VisualTab = Window:MakeTab({
    Name = "Scam Trade",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisualTab:AddToggle({
    Name = "Turn on scam",
    Default = false,
    Callback = function(scam0)
    end    
})

VisualTab:AddToggle({
    Name = "Freeze Trade",
    Default = false,
    Callback = function(scam1)
    end    
})

VisualTab:AddButton({
    Name = "Force Accept",
    Callback = function(scam2)
        OrionLib:MakeNotification({
        Name = "Force Trade",
        Content = "Successfully accepted the trade",
        Image = "rbxassetid://4483345998",
        Time = 3
    })

      end    
})


local CreditTab = Window:MakeTab({
    Name = "Credit",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CreditTab:AddParagraph("Credits", "YouTube: Almaz0")

OrionLib:Init()
--new version of this shit 
--added force accept
