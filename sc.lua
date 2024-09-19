-- Carregar a biblioteca OrionLib
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Variáveis de controle
local clickActive = false
local menuOpen = true

-- Função para simular cliques rápidos e infinitos
local function simulateClicks()
    while clickActive do
        mouse1click() -- Simula o clique do mouse esquerdo
        task.wait() -- Sem delay para clicar o mais rápido possível
    end
end

-- Função para abrir o menu principal
local function openMenu()
    if not menuOpen then
        OrionLib:Init()
        menuOpen = true
    end
end

-- Criação do menu usando OrionLib
local Window = OrionLib:MakeWindow({
    Name = "Simulador de Cliques", 
    HidePremium = false, 
    SaveConfig = true, 
    ConfigFolder = "OrionConfig"
})

-- Aba principal
local Tab = Window:MakeTab({
    Name = "Auto Clicker",
    Icon = "rbxassetid://4483345998", -- Ícone opcional
    PremiumOnly = false
})

-- Seção do menu
Tab:AddToggle({
    Name = "Ativar Auto Clique",
    Default = false,
    Callback = function(Value)
        clickActive = Value
        if clickActive then
            simulateClicks()
        end
    end    
})

-- Botão para fechar o menu
Tab:AddButton({
    Name = "Fechar Menu",
    Callback = function()
        OrionLib:Destroy() -- Fecha o menu principal
        menuOpen = false
    end    
})

-- Criação de uma janelinha flutuante com o botão "Open"
local ScreenGui = Instance.new("ScreenGui")
local OpenButton = Instance.new("TextButton")

-- Configurações da janela "Open"
ScreenGui.Name = "OpenMenuGUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

OpenButton.Name = "OpenButton"
OpenButton.Parent = ScreenGui
OpenButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
OpenButton.Position = UDim2.new(0, 50, 0, 50) -- Posição inicial da janelinha
OpenButton.Size = UDim2.new(0, 100, 0, 50) -- Tamanho do botão
OpenButton.Text = "Open"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Função do botão "Open" para reabrir o menu
OpenButton.MouseButton1Click:Connect(function()
    openMenu() -- Reabre o menu
end)

-- Exibir notificação ao iniciar
OrionLib:MakeNotification({
    Name = "Script Iniciado",
    Content = "Menu de auto clique ativado!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

-- Iniciar o menu principal
OrionLib:Init()
