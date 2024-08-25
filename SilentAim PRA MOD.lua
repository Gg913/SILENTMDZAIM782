local ev = require('lib.samp.events')
local imgui = require 'mimgui'
local encoding = require 'encoding'
local inicfg = require 'inicfg'

encoding.default = 'CP1251'
u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local frontX, frontY, frontZ, camX, camY, camZ = 0, 0, 0, 0, 0, 0

local selectedTab = 1
local shootingAtMe = -1
local tabSize = imgui.ImVec2(300, 30)

local settings = {
    search = {
        canSee = imgui.new.bool(true),
        --needKey = imgui.new.bool(false),
        radius = imgui.new.float(1000),
        ignoreCars = imgui.new.bool(true),
        searchMethod = imgui.new.int(0),
        useWeaponRadius = imgui.new.bool(true),
        ignoreObj = imgui.new.bool(true)
    },
    render = {
        line = imgui.new.bool(true),
        circle = imgui.new.bool(true),
        printString = imgui.new.bool(true)
    },
    shoot = {
        misses = imgui.new.bool(false),
        shotsPerMiss = imgui.new.int(3),
        removeAmmo = imgui.new.bool(false)
    }
}

local state = false
local canShoot = true
local targetId = 0

local miss = false
local toMiss = 0

local cRadius = 0
local cMaxRadius = 1
local cInvert = false
local fakemode = imgui.new.bool(false)
local xyi = false
math.randomseed(os.time())


imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    darkpurpletTheme()
end)

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 1000, 800
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
         imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
         if imgui.Begin('Silent Aim V2 By @gringomdz', renderWindow) then
             imgui.BeginChild('##tabs', imgui.ImVec2(-1, 30))
             if imgui.Button(u8'Search for target', tabSize) then
                 selectedTab = 1
             end
             imgui.SameLine()
             if imgui.Button(u8'Display', tabSize) then
                 selectedTab = 2
             end
             imgui.SameLine()
             if imgui.Button(u8'Shooting', tabSize) then
                 selectedTab = 3
             end
             imgui.EndChild()
             imgui.Separator()
             imgui.BeginChild('##options', imgui.ImVec2(-1, -1))
             if selectedTab == 1 then
                 imgui.Text(u8"Target search priority")
                 imgui.RadioButtonIntPtr(u8'Lowest health', settings.search.searchMethod, 0)
                 imgui.RadioButtonIntPtr(u8'By proximity to you', settings.search.searchMethod, 1)
                 imgui.RadioButtonIntPtr(u8'You are being attacked', settings.search.searchMethod, 2)
                 imgui.Separator()
                 imgui.Checkbox(u8'Ignore cars', settings.search.ignoreCars)
                 imgui.Checkbox(u8'Ignore objects', settings.search.ignoreObj)
                 imgui.Separator()
                 imgui.Checkbox(u8'Target must be on screen', settings.search.canSee)
                 imgui.Separator()
                 imgui.Checkbox(u8'Use maximum weapon range as radius', settings.search.useWeaponRadius)
                 if not settings.search.useWeaponRadius[0] then
                     imgui.SliderFloat(u8'Target search radius', settings.search.radius, 1, 50)
                 end
             end
             if selectedTab == 2 then
                 imgui.Checkbox(u8'Render line to target', settings.render.line)
                 imgui.Checkbox(u8'Render circle around target', settings.render.circle)
                 imgui.Checkbox(u8'Write below about the attacked target', settings.render.printString)
             end
             if selectedTab == 3 then
                 imgui.Checkbox(u8'Misses', settings.shoot.misses)
                 if settings.shoot.misses[0] then
                     imgui.PushItemWidth(200)
                     imgui.SliderInt(u8'Number of shots in a row without missing', settings.shoot.shotsPerMiss, 1, 10)
                     imgui.PopItemWidth()
                 end
                 imgui.Checkbox(u8'Change camera', fakemode)
                 --imgui.SliderFloat(u8'deagle delay', deagle, 0, 2000)
                 --imgui.Checkbox(u8'Remove ammo when shooting', settings.shoot.removeAmmo)
            end
            imgui.EndChild()
        imgui.End()
    end
end)

function main()
    while not isSampAvailable() do wait(0) end
    loadSettings()
    sampRegisterChatCommand('amenu', function()
        renderWindow[0] = not renderWindow[0]
    end)
    sampRegisterChatCommand("aim", function()
        state = not state
        shootingAtMe = -1
        sendMessage(state and 'Included' or 'Switched off')
        if state then
            lua_thread.create(function() 
                while state do
                    wait(50)
                    --sendData()
                end
            end)
            lua_thread.create(function() 
                while state do
                    wait(0)
                    local ped = findPlayer()
                    if ped ~= nil then
                        local _, id = sampGetPlayerIdByCharHandle(ped)
                        if _ then
                            targetId = id
                            local mx, my, mz = getCharCoordinates(PLAYER_PED)
                            local x, y, z = getCharCoordinates(ped)

                            local mxw, myw = convert3DCoordsToScreen(mx, my, mz)
                            local xw, yw = convert3DCoordsToScreen(x, y, z)

                            if settings.render.line[0] and isPointOnScreen(x, y, z, 1) then
                                renderDrawLine(mxw, myw, xw, yw, 4.0, 0xFFFF0000)
                            end
                            if settings.render.circle[0] then
                                Draw3DCircle(x, y, z, cRadius, 0xFFFF0000)
                            end
                        end
                    else
                        targetId = -1
                    end
                end
            end)
            lua_thread.create(function() 
                while state do
                    wait(10)
                    if cInvert then
                        cRadius = cRadius - 0.01
                        if cRadius <= 0.15 then
                            cInvert = false
                        end
                    else
                        cRadius = cRadius + 0.01
                        if cRadius >= cMaxRadius then
                            cInvert = true
                        end
                    end
                end
            end)
        end
    end)
end

function loadSettings()
    local ini = inicfg.load(nil, 'aim.ini')
    if ini == nil then
        saveSettings()
    else
        settings.search.canSee[0] = ini.search.canSee
        settings.search.radius[0] = ini.search.radius
        settings.search.ignoreCars[0] = ini.search.ignoreCars
        settings.search.searchMethod[0] = ini.search.searchMethod
        settings.search.useWeaponRadius[0] = ini.search.useWeaponRadius

        settings.render.line[0] = ini.render.line
        settings.render.circle[0] = ini.render.circle
        settings.render.printString[0] = ini.render.printString

        settings.shoot.misses[0] = ini.shoot.misses
        settings.shoot.shotsPerMiss[0] = ini.shoot.shotsPerMiss
        settings.shoot.removeAmmo[0] = ini.shoot.removeAmmo
    end
end

function saveSettings()
    inicfg.save({
        search = {
            canSee = settings.search.canSee[0],
            radius = settings.search.radius[0],
            ignoreCars = settings.search.ignoreCars[0],
            searchMethod = settings.search.searchMethod[0],
            useWeaponRadius = settings.search.useWeaponRadius[0]
        },
        render = {
            line = settings.render.line[0],
            circle = settings.render.circle[0],
            printString = settings.render.printString[0]
        },
        shoot = {
            misses = settings.shoot.misses[0],
            shotsPerMiss = settings.shoot.shotsPerMiss[0],
            removeAmmo = settings.shoot.removeAmmo[0]
        }
    }, 'aim.ini')
end

function findPlayer()
    local peds = getAllChars()
    local selectedPed = nil
    local v = 1000000
    for k, ped in pairs(peds) do
        if ped ~= PLAYER_PED and (settings.search.canSee[0] and isCharOnScreen(ped) or not settings.search.canSee[0]) and not isCharDead(ped) then
            local _, id = sampGetPlayerIdByCharHandle(ped)
            if _ then
                local cHp = sampGetPlayerHealth(id) + sampGetPlayerArmor(id)
                local x, y, z = getCharCoordinates(ped)
                local mx, my, mz = getCharCoordinates(PLAYER_PED)
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if isLineOfSightClear(mx, my, mz, x, y, z, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) and getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < ((settings.search.useWeaponRadius[0] and weapon ~= nil and weapon.distance) or settings.search.radius[0]) then
                    if settings.search.searchMethod[0] == 0 then
                        if cHp < v then
                            v = cHp
                            selectedPed = ped
                        end
                    elseif settings.search.searchMethod[0] == 1 then
                        if getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < v then
                            v = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                            selectedPed = ped
                        end
                    elseif settings.search.searchMethod[0] == 2 then
                        if shootingAtMe == id then
                            --shootingAtMe = -1
                            selectedPed = ped
                            break
                        else
                            if getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < v then
                                v = getDistanceBetweenCoords3d(mx, my, mz, x, y, z)
                                selectedPed = ped
                            end
                        end
                    end
                end
            end
        end
    end
    return selectedPed
end

--[[function sendData()
    local data = samp_create_sync_data("player")
    local dataa = samp_create_sync_data("aim")
    data.send()
    dataa.send()
end]]

local weapons = {
    {
        id = 22,
        delay = 160,
        dmg = 8999.25,
        distance = 300,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 23,
        delay = 120,
        dmg = 13.2,
        distance = 300,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 24,
        delay = 800,
        dmg = 46.2,
        distance = 400,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 25,
        delay = 800,
        dmg = 30.3,
        distance = 400,
        camMode = 53,
        weaponState = 1
    },
    {
        id = 26,
        delay = 120,
        dmg = 3.3,
        distance = 400,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 27,
        delay = 120,
        dmg = 4.95,
        distance = 4000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 28,
        delay = 50,
        dmg = 6.6,
        distance = 4000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 29,
        delay = 90,
        dmg = 8.25,
        distance = 4000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 30,
        delay = 90,
        dmg = 9.9,
        distance = 40000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 31,
        delay = 90,
        dmg = 9.9,
        distance = 4000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 32,
        delay = 70,
        dmg = 6.6,
        distance = 40000,
        camMode = 53,
        weaponState = 2
    },
    {
        id = 33,
        delay = 800,
        dmg = 24.75,
        distance = 400,
        camMode = 53,
        weaponState = 1
    },
    {
        id = 34,
        delay = 900,
        dmg = 41.25,
        distance = 4000,
        camMode = 7,
        weaponState = 1
    },
    {
        id = 38,
        delay = 20,
        dmg = 46.2,
        distance = 40000,
        camMode = 53,
        weaponState = 2
    },
    
}

function getWeaponInfoById(id)
    for k, weapon in pairs(weapons) do
        if weapon.id == id then
            return weapon
        end
    end
    return nil
end

function rand()
    return math.random(-50, 50) / 100
end

function getMyId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
end

function ev.onBulletSync(playerId, data)
    if data.targetId == getMyId() then
        shootingAtMe = playerId
    end
end

function ev.onSendTakeDamage(playerId, damage, weapon, bodypart)
    shootingAtMe = playerId
end

function ev.onSendGiveDamage(data)
    if state then
        return false
    end
end

function ev.onSendPlayerSync(data)
    if state then
        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local b = 0 * math.pi / 360.0
                local h = 0 * math.pi / 360.0 
                local angle = getHeadingFromVector2d(x - mx, y - my)
                local a = angle * math.pi / 360.0

                local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)
                
                --data.quaternion[0] = c1 * c2 * c3 - s1 * s2 * s3
                --data.quaternion[3] = -( c1 * s2 * c3 - s1 * c2 * s3 )

                data.keys.aim = 1

                if canShoot and isCharShooting(PLAYER_PED) then
                    local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                    if weapon ~= nil then
                        data.keys.secondaryFire_shoot = 1
                        lua_thread.create(function() 
                            canShoot = false
                            
                            if miss or not settings.shoot.misses[0] then
                                miss = false
                            end
                            if toMiss >= settings.shoot.shotsPerMiss[0] then
                                miss = true
                                toMiss = 0
                            end
                            if not miss and settings.shoot.misses[0] then
                                toMiss = toMiss + 1
                            end
                            local sync = samp_create_sync_data('bullet')
                            if miss then
                                sync.targetType = 0
                                sync.targetId = 65535
                            else
                                sync.targetType = 1
                                sync.targetId = targetId
                            end
                            sync.center = {x = rand(), y = rand(), z = rand()}
                            sync.origin = {x = mx + rand(), y = my + rand(), z = mz + rand()}
                            sync.target = {x = x + rand(), y = y + rand(), z = z + rand()}
                            sync.weaponId = getCurrentCharWeapon(PLAYER_PED)
                            sync.send()
                            if settings.shoot.removeAmmo[0] then
                                --[[local weaponId = getCurrentCharWeapon(PLAYER_PED)
                                local ammo = getAmmoInCharWeapon(PLAYER_PED, weaponId) - 1
                                removeWeaponFromChar(PLAYER_PED, weaponId)
                                giveWeaponToChar(PLAYER_PED, weaponId, ammo)]]
                                --setCharAmmo(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), getAmmoInCharWeapon(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED)) - 1)
                                addAmmoToChar(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), -1)
                            end
                            if not miss then
                                sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 9)
                            end
                            if settings.render.printString[0] then
                                printStringNow(miss and 'Shot missed' or string.format('Player ~r~%d ~w~damaged', targetId), 500)
                            end
                            --wait(weapon.delay)
                            canShoot = true
                        end)
                    end
                end
            end
        end
    end
end

function Draw3DCircle(x, y, z, radius, color)
    local screen_x_line_old, screen_y_line_old;

    for rot = 0, 360 do
        local rot_temp = math.rad(rot)
        local lineX, lineY, lineZ = radius * math.cos(rot_temp) + x, radius * math.sin(rot_temp) + y, z
        local screen_x_line, screen_y_line = convert3DCoordsToScreen(lineX, lineY, lineZ)
        if screen_x_line ~=nil and screen_x_line_old ~= nil then renderDrawLine(screen_x_line, screen_y_line, screen_x_line_old, screen_y_line_old, 3, color) end
        screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
    end
end

function ev.onSendAimSync(data)
    if state and fakemode[0] then
        camX = data.camPos.x
		camY = data.camPos.y
		camZ = data.camPos.z
		
		frontX = data.camFront.x
		frontY = data.camFront.y
		frontZ = data.camFront.z

        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if weapon ~= nil then
                    local b = 0 * math.pi / 360.0
                    local h = 0 * math.pi / 360.0 
                    local angle = getCharHeading(ped)
                    local a = angle * math.pi / 360.0

                    local c1, c2, c3 = math.cos(h), math.cos(a), math.cos(b)
                    local s1, s2, s3 = math.sin(h), math.sin(a), math.sin(b)

                    data.camMode = weapon.camMode
                    data.weaponState = weapon.weaponState

                    data.camPos.x = mx
                    data.camPos.y = my
                    data.camPos.z = mz

                    local dx = x - data.camPos.x
                    local dy = y - data.camPos.y
                    local dz = z - data.camPos.z

                    data.camFront.x = dx / vect3_length(dx, dy, dz)
                    data.camFront.y = dy / vect3_length(dx, dy, dz)
                    data.camFront.z = dz / vect3_length(dx, dy, dz)
                end
            end
        end
    end
end

function vect3_length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function sendMessage(message)
    sampAddChatMessage('{6EFB6E}[Silent AimV2 By @gringomdz]: {FFFFFF}' .. message, -1)
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    -- from SAMP.Lua
    local raknet = require 'samp.raknet'
    --require 'samp.synchronization'

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    -- copy player's sync data to the allocated memory
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    -- function to send packet
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    -- metatable to access sync data and 'send' function
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

function darkpurpletTheme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    colors[clr.Text]				   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]		   = ImVec4(0.50, 0.30, 0.60, 1.00)
    colors[clr.WindowBg]			   = ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.ChildBg]		           = ImVec4(0.10, 0.10, 0.10, 0.40)
    colors[clr.PopupBg]				= ImVec4(0.08, 0.08, 0.08, 1.00)
    colors[clr.Border]				 = ImVec4(0.70, 0.70, 0.70, 0.40)
    colors[clr.BorderShadow]		   = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]				= ImVec4(0.15, 0.15, 0.15, 1.00)
    colors[clr.FrameBgHovered]		 = ImVec4(0.30, 0.20, 0.50, 0.71)
    colors[clr.FrameBgActive]		  = ImVec4(0.40, 0.30, 0.60, 0.79)
    colors[clr.TitleBg]				= ImVec4(0.50, 0.30, 0.70, 0.80)
    colors[clr.TitleBgActive]		  = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.TitleBgCollapsed]	   = ImVec4(0.50, 0.30, 0.70, 0.50)
    colors[clr.MenuBarBg]			  = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.ScrollbarBg]			= ImVec4(0.16, 0.16, 0.16, 1.00)
    colors[clr.ScrollbarGrab]		  = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.ScrollbarGrabActive]	= ImVec4(0.70, 0.50, 0.90, 1.00)
    colors[clr.CheckMark]			  = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.SliderGrab]			 = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.SliderGrabActive]	   = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.Button]				 = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.ButtonHovered]		  = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.ButtonActive]		   = ImVec4(0.70, 0.50, 0.90, 1.00)
    colors[clr.Header]				 = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.HeaderHovered]		  = ImVec4(0.60, 0.40, 0.80, 0.57)
    colors[clr.HeaderActive]		   = ImVec4(0.70, 0.50, 0.90, 0.89)
    colors[clr.Separator]			  = ImVec4(1.00, 1.00, 1.00, 0.40)
    colors[clr.SeparatorHovered]	   = ImVec4(1.00, 1.00, 1.00, 0.60)
    colors[clr.SeparatorActive]		= ImVec4(1.00, 1.00, 1.00, 0.80)
    colors[clr.ResizeGrip]			 = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.ResizeGripHovered]	  = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.ResizeGripActive]	   = ImVec4(0.70, 0.50, 0.90, 1.00)
    colors[clr.PlotLines]			  = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.PlotLinesHovered]	   = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.PlotHistogram]		  = ImVec4(0.50, 0.30, 0.70, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(0.60, 0.40, 0.80, 1.00)
    colors[clr.TextSelectedBg]		 = ImVec4(0.50, 0.30, 0.70, 0.72)
    colors[clr.ModalWindowDimBg]       = ImVec4(0.17, 0.17, 0.17, 0.48)
end