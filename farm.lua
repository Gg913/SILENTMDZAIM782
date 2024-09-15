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

-- Função para exibir notificação
local function EnviarNotificacao(titulo, texto, duracao)
    OrionLib:MakeNotification({
        Name = titulo,
        Content = texto,
        Image = "rbxassetid://4483345998",
        Time = duracao
    })
end

-- Cria o menu Auto Farm usando a OrionLib
OrionLib:MakeWindow({Name = "Mdz Menu", HidePremium = false, SaveConfig = true, ConfigFolder = "AutoFarmConfig"})

-- Aba principal do menu
local MainTab = OrionLib:MakeTab({
    Name = "Auto Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Toggle para ativar/desativar o Auto Farm
MainTab:AddToggle({
    Name = "Auto Farm All Orbs (Only City)",
    Default = false,
    Callback = function(value)
        AutoFarmAtivo = value
        
        if value then
            AutoFarm()
        else
            -- Notificação quando o Auto Farm é interrompido
            EnviarNotificacao("Auto Farm", "Auto Farm interrompido", 5)
        end
    end
})

-- Inicializa o menu
OrionLib:Init()
