local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()

-- Configuração da chave
local correctKey = "sua-chave-aqui" -- Substitua com a chave desejada
local enteredKey = ""

-- Função para verificar a chave
local function checkKey()
	return enteredKey == correctKey
end

-- Função para encontrar a pasta de NPCs
local function findNpcFolder()
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Folder") then
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
					return obj
				end
			end
		end
	end
	return nil
end

-- Função para clicar automaticamente no NPC
local function clickNpc(npc)
	local player = game.Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local npcRootPart = npc:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and npcRootPart then
			-- Teleporta para o NPC
			humanoidRootPart.CFrame = npcRootPart.CFrame
			wait(0.1) -- Pequena pausa para garantir que o jogador esteja posicionado corretamente

			-- Simula um clique do mouse (M1) para interagir com o NPC
			local userInputService = game:GetService("UserInputService")
			local inputService = game:GetService("VirtualInputManager")

			-- Envia um clique para o jogador
			inputService:SendInputBegin(Enum.UserInputType.MouseButton1)
			wait(0.1)
			inputService:SendInputEnd(Enum.UserInputType.MouseButton1)
		end
	end
end

-- Criando uma janela no OrionLib
local Window = OrionLib:MakeWindow({Name = "Testando Anti-Cheat", HidePremium = true, SaveConfig = true, ConfigFolder = "OrionLib"})

-- Adicionando uma aba de autenticação
local AuthTab = Window:MakeTab({
	Name = "Autenticação",
	PremiumOnly = false
})

-- Adicionando um campo de entrada para a chave
AuthTab:AddTextbox({
	Name = "Digite a chave",
	Default = "",
	TextDisappear = false,
	Callback = function(value)
		enteredKey = value
		if checkKey() then
			OrionLib:MakeNotification({
				Name = "Autenticação",
				Content = "Chave correta! Acesse a aba Funções.",
				Image = "rbxassetid://4483345998",
				Time = 5
			})
			-- Exibe a aba de funções após a autenticação
			Window:SelectTab("Funções")
		else
			OrionLib:MakeNotification({
				Name = "Autenticação",
				Content = "Chave incorreta! Tente novamente.",
				Image = "rbxassetid://4483345998",
				Time = 5
			})
		end
	end    
})

-- Adicionando uma aba de funções
local Tab = Window:MakeTab({
	Name = "Funções",
	PremiumOnly = false,
	Visible = false
})

-- Variáveis para armazenar o estado das funções
local godModeEnabled = false
local bringAllPlayersEnabled = false
local instantKillEnabled = false
local autofarmEnabled = false
local npcFolder = findNpcFolder()

-- Função para atualizar o estado das funções
local function updateFunctions()
	local player = game.Players.LocalPlayer
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if godModeEnabled and humanoid then
			humanoid.MaxHealth = math.huge
			humanoid.Health = math.huge
		elseif humanoid then
			humanoid.MaxHealth = 100
			humanoid.Health = humanoid.Health
		end

		for _, otherPlayer in ipairs(game.Players:GetPlayers()) do
			if otherPlayer ~= player then
				local otherCharacter = otherPlayer.Character
				if otherCharacter then
					local otherHumanoidRootPart = otherCharacter:FindFirstChild("HumanoidRootPart")
					if bringAllPlayersEnabled and otherHumanoidRootPart then
						otherHumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame
					end
					
					local otherHumanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
					if instantKillEnabled and otherHumanoid then
						otherHumanoid.Health = 0
					end
				end
			end
		end

		-- Autofarm: Teleportar e atacar NPCs
		if autofarmEnabled and npcFolder then
			for _, npc in ipairs(npcFolder:GetChildren()) do
				if npc:IsA("Model") and npc:FindFirstChildOfClass("Humanoid") then
					clickNpc(npc)
					wait(0.5) -- Aguarda um tempo para garantir que a ação seja registrada antes de mover para o próximo NPC
				end
			end
		end
	end
end

-- Adicionando um botão toggle para GodMode
Tab:AddToggle({
	Name = "GodMode",
	Default = false,
	Callback = function(state)
		godModeEnabled = state
		updateFunctions()
	end    
})

-- Adicionando um botão toggle para Bring All Players
Tab:AddToggle({
	Name = "Bring All Players",
	Default = false,
	Callback = function(state)
		bringAllPlayersEnabled = state
		updateFunctions()
	end    
})

-- Adicionando um botão toggle para Instant Kill
Tab:AddToggle({
	Name = "Instant Kill",
	Default = false,
	Callback = function(state)
		instantKillEnabled = state
		updateFunctions()
	end    
})

-- Adicionando um botão toggle para Autofarm
Tab:AddToggle({
	Name = "Autofarm",
	Default = false,
	Callback = function(state)
		autofarmEnabled = state
		updateFunctions()
	end    
})
