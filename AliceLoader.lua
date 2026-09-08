-- AliceHUB Loader v2.5.0
local API="https://alicehub-api.shirokanaerus.workers.dev"
local FALLBACK_LOGO="rbxassetid://71638246809611"
return function(token)
    assert(type(token)=="string" and #token>0,"AliceHUB: token missing")
    if not game:IsLoaded() then game.Loaded:Wait() end
    local Players=game:GetService("Players")
    local HttpService=game:GetService("HttpService")
    local Player=Players.LocalPlayer
    assert(Player,"AliceHUB: LocalPlayer not found")
    local Env=(getgenv and getgenv()) or _G
    Env.AliceClientToken=token
    if type(Env.AliceHUBReleaseSession)=="function" then pcall(Env.AliceHUBReleaseSession) end
    if Env.AliceHUBTeleportConnection then pcall(function() Env.AliceHUBTeleportConnection:Disconnect() end) Env.AliceHUBTeleportConnection=nil end
    Env.AliceHUBHeartbeatGeneration=(tonumber(Env.AliceHUBHeartbeatGeneration) or 0)+1
    local generation=Env.AliceHUBHeartbeatGeneration
    local function httpGet(url)
        local ok,res=pcall(function() return game:HttpGet(url,true) end)
        if not ok then return nil,tostring(res) end
        return res
    end
    local function decode(text)
        if type(text)~="string" then return nil end
        local ok,data=pcall(function() return HttpService:JSONDecode(text) end)
        if ok and type(data)=="table" then return data end
    end
    local function ensureFolder(path)
        if type(makefolder)~="function" then return end
        local ok,exists=pcall(function() return type(isfolder)=="function" and isfolder(path) end)
        if not ok or not exists then pcall(makefolder,path) end
    end
    local function prepareLogo()
        Env.AliceHUBLogoAsset=FALLBACK_LOGO; Env.AliceHUBBrandLogoAsset=FALLBACK_LOGO
        if type(writefile)~="function" then return end
        ensureFolder("AliceHUB"); ensureFolder("AliceHUB/assets")
        local logoPath="AliceHUB/BrandLogo.png", assetPath="AliceHUB/assets/BrandLogo.png", versionPath="AliceHUB/assets/BrandLogo.version", wantedVersion="2"
        local currentVersion
        if type(readfile)=="function" and type(isfile)=="function" then local ok,e=pcall(isfile,versionPath); if ok and e then pcall(function() currentVersion=tostring(readfile(versionPath) or "") end) end end
        local logoExists=false; if type(isfile)=="function" then pcall(function() logoExists=isfile(logoPath) end) end
        if not logoExists or currentVersion~=wantedVersion then
            local bytes=httpGet(API.."/assets/logo?v="..HttpService:UrlEncode(wantedVersion).."&t="..HttpService:UrlEncode(tostring(os.time())))
            if type(bytes)=="string" and #bytes>100 then pcall(writefile,logoPath,bytes); pcall(writefile,assetPath,bytes); pcall(writefile,versionPath,wantedVersion); logoExists=true end
        end
        local getAsset=getcustomasset or getsynasset
        if logoExists and type(getAsset)=="function" then local ok,asset=pcall(getAsset,logoPath); if ok and type(asset)=="string" and #asset>0 then Env.AliceHUBLogoAsset=asset; Env.AliceHUBBrandLogoAsset=asset; Env.AliceHUBLogoPath=logoPath end end
    end
    local function getClientId()
        ensureFolder("AliceHUB"); local path="AliceHUB/client_instance.id"
        if type(isfile)=="function" and type(readfile)=="function" then local ok,e=pcall(isfile,path); if ok and e then local v; pcall(function() v=tostring(readfile(path) or "") end); v=v and v:gsub("[^%w_-]","") or ""; if #v>=8 and #v<=96 then return v end end end
        local v=("AHC_"..HttpService:GenerateGUID(false)):gsub("[^%w_-]",""); if type(writefile)=="function" then pcall(writefile,path,v) end; return v
    end
    pcall(prepareLogo)
    local clientId=getClientId()
    local function acquire()
        local url=API.."/client/session?token="..HttpService:UrlEncode(token).."&username="..HttpService:UrlEncode(Player.Name).."&userId="..HttpService:UrlEncode(tostring(Player.UserId)).."&clientId="..HttpService:UrlEncode(clientId).."&gameId="..HttpService:UrlEncode(tostring(game.GameId)).."&placeId="..HttpService:UrlEncode(tostring(game.PlaceId)).."&t="..HttpService:UrlEncode(tostring(os.time()).."-"..tostring(math.random(100000,999999)))
        local body,err=httpGet(url); if type(body)~="string" then return nil,"AliceHUB HTTP error: "..tostring(err) end
        local data=decode(body); if not data then return nil,"AliceHUB: invalid session response" end
        if not data.ok or type(data.session)~="string" or type(data.lease)~="string" then return nil,data.error or "AliceHUB authorization failed" end
        return data
    end
    local sessionData,sessionErr=acquire(); assert(sessionData,sessionErr or "AliceHUB authorization failed")
    local lease=sessionData.lease
    local heartbeatEvery=math.max(15,tonumber(sessionData.heartbeatEvery) or 30)
    local activeTtl=math.max(60,tonumber(sessionData.activeSessionTtl) or 150)
    local function apply(data)
        if type(data.access)=="table" then Env.AliceHUBAccess={status=data.access.status or data.access.plan or "Active",plan=data.access.plan,expiresAt=data.access.expiresAt,permanent=data.access.permanent==true} end
        if type(data.slots)=="table" then Env.AliceHUBSlots={used=tonumber(data.slots.used) or 0,max=tonumber(data.slots.max) or 0} end
        Env.AliceHUBActiveSession={username=Player.Name,userId=Player.UserId,clientId=clientId,slotMode="active_sessions",heartbeatEvery=heartbeatEvery,autoReleaseSeconds=activeTtl}
    end
    apply(sessionData)
    local function release()
        if generation~=Env.AliceHUBHeartbeatGeneration then return false end
        local l=lease; if type(l)~="string" or l=="" then return false end; lease=nil
        local body=httpGet(API.."/client/release?lease="..HttpService:UrlEncode(l).."&t="..HttpService:UrlEncode(tostring(os.time())))
        return type(body)=="string"
    end
    Env.AliceHUBReleaseSession=release
    Env.AliceHUBTeleportConnection=Player.OnTeleport:Connect(function(state) if generation==Env.AliceHUBHeartbeatGeneration and state==Enum.TeleportState.Started then pcall(release) end end)
    task.spawn(function()
        local failures=0
        while generation==Env.AliceHUBHeartbeatGeneration do
            task.wait(heartbeatEvery); if generation~=Env.AliceHUBHeartbeatGeneration then return end
            local okHeartbeat=false
            if type(lease)=="string" and lease~="" then
                local body=httpGet(API.."/client/heartbeat?lease="..HttpService:UrlEncode(lease).."&t="..HttpService:UrlEncode(tostring(os.time()).."-"..tostring(math.random(100000,999999))))
                local data=decode(body)
                if data and data.ok then okHeartbeat=true; failures=0; heartbeatEvery=math.max(15,tonumber(data.heartbeatEvery) or heartbeatEvery); activeTtl=math.max(60,tonumber(data.activeSessionTtl) or activeTtl); if type(data.slots)=="table" then Env.AliceHUBSlots={used=tonumber(data.slots.used) or 0,max=tonumber(data.slots.max) or 0} end end
            end
            if not okHeartbeat then
                failures+=1
                if failures>=2 then local fresh=acquire(); if fresh then sessionData=fresh; lease=fresh.lease; heartbeatEvery=math.max(15,tonumber(fresh.heartbeatEvery) or heartbeatEvery); activeTtl=math.max(60,tonumber(fresh.activeSessionTtl) or activeTtl); failures=0; apply(fresh) end end
                local maxFailures=math.max(4,math.ceil(activeTtl/heartbeatEvery))
                if failures>=maxFailures and generation==Env.AliceHUBHeartbeatGeneration then pcall(function() Player:Kick("AliceHUB session expired. Rejoin and execute your loader again.") end); return end
            end
        end
    end)
    local payload,payloadErr=httpGet(API.."/script?session="..HttpService:UrlEncode(sessionData.session).."&t="..HttpService:UrlEncode(tostring(os.time())))
    assert(type(payload)=="string","AliceHUB payload error: "..tostring(payloadErr))
    local chunk,compileError=loadstring(payload); assert(type(chunk)=="function","AliceHUB payload compile failed: "..tostring(compileError)); return chunk()
end
