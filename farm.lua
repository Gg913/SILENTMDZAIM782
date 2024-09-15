-- Carrega a biblioteca OrionLib
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Variável para controle do Auto Farm
local AutoFarmAtivo = false

-- Função de coleta automática de orbes
local function AutoFarm()
    while AutoFarmAtivo do
        local orbs = {
            {name = "Gem", location = "City"},
            {name = "Yellow Orb", location = "City"},
            {name = "Orange Orb", location = "City"},
            {name = "Blue Orb", location = "City"}
        }
        local orbEvent = game:GetService("ReplicatedStorage").rEvents.orbEvent
        
        for _, orb in pairs(orbs) do
            orbEvent:FireServer("collectOrb", orb.name, orb.location)
        end
        wait(0.001)  -- Muito rápido, mas com um pequeno intervalo para evitar sobrecarga
    end
end

-- Cria o menu Auto Farm usando a OrionLib
local Window = OrionLib:MakeWindow({
    Name = "Auto Farm Menu", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "AutoFarmConfig"
})

-- Aba principal do menu
local MainTab = Window:MakeTab({
    Name = "Auto Farm",
    Icon = "rbxassetid://4483345998",  -- Ícone do menu
    PremiumOnly = false
})

-- Toggle para ativar/desativar o Auto Farm
MainTab:AddToggle({
    Name = "Ativar Auto Farm",
    Default = false,
    Callback = function(value)
        AutoFarmAtivo = value
        
        if value then
            AutoFarm()
        end
    end
})

-- Inicializa o menu Orion
OrionLib:Init()
