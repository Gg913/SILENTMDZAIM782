-- Carregar a OrionLib
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Configurações do Menu
local Window = OrionLib:MakeWindow({Name = "Exploit Menu", HidePremium = false, SaveConfig = true, ConfigFolder = "ExploitConfig"})

-- Criando uma aba principal
local Tab = Window:MakeTab({
    Name = "Principal",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variável para armazenar o alcance do Kill Aura
local auraRange = 10

-- Função ESP Line para todos os jogadores
local function EsplineForAll(range)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    -- Remover todas as linhas anteriores
    for _, beam in pairs(workspace:GetChildren()) do
        if beam:IsA("Beam") and beam.Name == "ESPBeam" then
            beam:Destroy()
        end
    end

    -- Adiciona ESP para todos os jogadores dentro do alcance
    for _, targetPlayer in pairs(game.Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (targetPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
            if distance <= range then
                -- Criar a linha (Espline) para cada jogador
                local Line = Instance.new("Beam")
                Line.Name = "ESPBeam"
                Line.Attachment0 = Instance.new("Attachment", character.HumanoidRootPart)
                Line.Attachment1 = Instance.new("Attachment", targetPlayer.Character.HumanoidRootPart)
                Line.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                Line.FaceCamera = true
                Line.Width0 = 0.1
                Line.Width1 = 0.1
                Line.Parent = workspace
            end
        end
    end
end

-- Função Kill Aura (Ataca todos os inimigos ao redor)
local function KillAura(range)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    while true do
        wait(0.1)  -- Executar a cada 0.1 segundos
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (v.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= range then
                    v.Character.Humanoid.Health = 0 -- Mata o jogador inimigo
                end
            end
        end
    end
end

-- Função Kill All (Mata todos os jogadores de uma vez)
local function KillAll()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= game.Players.LocalPlayer then
            if v.Character and v.Character:FindFirstChild("Humanoid") then
                v.Character.Humanoid.Health = 0 -- Mata todos os jogadores
            end
        end
    end
end

-- Adicionando um slider para ajustar o alcance
Tab:AddSlider({
    Name = "Ajustar Alcance",
    Min = 10,
    Max = 100,
    Default = 10,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Alcance",
    Callback = function(Value)
        auraRange = Value
        -- Atualizar o ESP para refletir o novo alcance
        EsplineForAll(auraRange)
    end
})

-- Adicionando um botão para ESP Line para todos os jogadores
Tab:AddButton({
    Name = "ESP Line para Todos os Jogadores",
    Callback = function()
        EsplineForAll(auraRange)  -- Desenha linhas de ESP para todos os jogadores dentro do alcance
    end    
})

-- Adicionando Kill Aura
Tab:AddToggle({
    Name = "Kill Aura",
    Default = false,
    Callback = function(Value)
        if Value then
            KillAura(auraRange)  -- Ativa o Kill Aura com o alcance definido
        else
            -- Desative Kill Aura (se necessário, pode implementar uma maneira de parar)
        end
    end    
})

-- Adicionando Kill All
Tab:AddButton({
    Name = "Kill All",
    Callback = function()
        KillAll()  -- Mata todos os jogadores
    end    
})

-- Notificação de carregamento
OrionLib:MakeNotification({
    Name = "Exploit Carregado",
    Content = "Menu de exploit com ESP Line, Kill Aura e Kill All foi carregado!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Abrir o menu
OrionLib:Init()
