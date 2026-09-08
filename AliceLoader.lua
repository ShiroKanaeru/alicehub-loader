-- AliceHUB Loader v2.5.3
-- Executor compatibility build
local API = "https://alicehub-api.shirokanaerus.workers.dev"
local FALLBACK_LOGO = "rbxassetid://71638246809611"

return function(token)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    local Player = Players.LocalPlayer

    assert(type(token) == "string" and #token > 0, "AliceHUB: token missing")
    if not game:IsLoaded() then game.Loaded:Wait() end
    assert(Player, "AliceHUB: LocalPlayer not found")

    local Env = (getgenv and getgenv()) or _G
    Env.AliceClientToken = token

    -- Small temporary boot/error UI.
    local bootGui, bootText
    local function bootRoot()
        local pg = Player:FindFirstChildOfClass("PlayerGui")
        if pg then return pg end
        local ok, found = pcall(function()
            return Player:WaitForChild("PlayerGui", 5)
        end)
        if ok and found then return found end
        if type(gethui) == "function" then
            local okHui, hui = pcall(gethui)
            if okHui and hui then return hui end
        end
        return CoreGui
    end

    local function makeBoot()
        pcall(function()
            local root = bootRoot()
            local old = root and root:FindFirstChild("AliceHUB_LoaderBoot")
            if old then old:Destroy() end

            local gui = Instance.new("ScreenGui")
            gui.Name = "AliceHUB_LoaderBoot"
            gui.ResetOnSpawn = false
            gui.IgnoreGuiInset = true
            gui.DisplayOrder = 2147483000
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = root

            local frame = Instance.new("Frame")
            frame.AnchorPoint = Vector2.new(0.5, 0)
            frame.Position = UDim2.new(0.5, 0, 0, 18)
            frame.Size = UDim2.fromOffset(310, 58)
            frame.BackgroundColor3 = Color3.fromRGB(24, 15, 19)
            frame.BorderSizePixel = 0
            frame.Parent = gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(181, 48, 83)
            stroke.Thickness = 1.5
            stroke.Transparency = 0.1
            stroke.Parent = frame

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Position = UDim2.fromOffset(12, 7)
            title.Size = UDim2.new(1, -24, 0, 20)
            title.Font = Enum.Font.Code
            title.Text = "AliceHUB"
            title.TextColor3 = Color3.fromRGB(242, 236, 239)
            title.TextSize = 16
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = frame

            local status = Instance.new("TextLabel")
            status.BackgroundTransparency = 1
            status.Position = UDim2.fromOffset(12, 29)
            status.Size = UDim2.new(1, -24, 0, 19)
            status.Font = Enum.Font.Code
            status.Text = "Starting..."
            status.TextColor3 = Color3.fromRGB(190, 180, 185)
            status.TextSize = 12
            status.TextXAlignment = Enum.TextXAlignment.Left
            status.TextTruncate = Enum.TextTruncate.AtEnd
            status.Parent = frame

            bootGui = gui
            bootText = status
        end)
    end

    local function setBoot(text)
        pcall(function()
            if bootText and bootText.Parent then
                bootText.Text = tostring(text or "")
            end
        end)
    end

    local function destroyBoot(delaySeconds)
        task.delay(delaySeconds or 0, function()
            pcall(function()
                if bootGui and bootGui.Parent then bootGui:Destroy() end
            end)
            bootGui, bootText = nil, nil
        end)
    end

    makeBoot()

    local function fail(message)
        local msg = tostring(message or "Unknown loader error")
        setBoot("Error: " .. msg)
        warn("[AliceHUB] " .. msg)
        task.delay(10, function()
            pcall(function()
                if bootGui and bootGui.Parent then bootGui:Destroy() end
            end)
        end)
        error("AliceHUB: " .. msg, 0)
    end

    -- Compatibility HTTP layer.
    local function executorRequest()
        if type(request) == "function" then return request end
        if type(http_request) == "function" then return http_request end
        if type(http) == "table" and type(http.request) == "function" then return http.request end
        if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
        if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
        return nil
    end

    local function requestBody(url)
        local req = executorRequest()
        if not req then return nil, "request() unavailable" end

        local ok, response = pcall(req, {
            Url = url,
            URL = url,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
                ["User-Agent"] = "AliceHUB/2.5.3"
            }
        })
        if not ok then
            return nil, tostring(response)
        end

        if type(response) == "string" then
            return response
        end

        if type(response) == "table" then
            local body = response.Body or response.body or response.ResponseBody
            local code = tonumber(response.StatusCode or response.Status or response.status_code or response.status)
            if type(body) == "string" and #body > 0 then
                if code and code >= 400 then
                    return body, "HTTP " .. tostring(code)
                end
                return body
            end
            return nil, "request() response body kosong"
        end

        return nil, "request() response tidak dikenal"
    end

    local function httpGet(url)
        -- First try Roblox/executor HttpGet.
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(result) == "string" and #result > 0 then
            return result, nil, "HttpGet"
        end

        local ok2, result2 = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok2 and type(result2) == "string" and #result2 > 0 then
            return result2, nil, "HttpGetCached"
        end

        local body, reqErr = requestBody(url)
        if type(body) == "string" and #body > 0 then
            return body, reqErr, "request"
        end

        return nil, tostring(reqErr or result2 or result or "HTTP unavailable"), "none"
    end

    local function decode(text)
        if type(text) ~= "string" then return nil end
        local ok, data = pcall(function()
            return HttpService:JSONDecode(text)
        end)
        if ok and type(data) == "table" then return data end
        return nil
    end


    local function responsePreview(value)
        local s = tostring(value or "")
        s = s:gsub("[%c]+", " "):gsub("%s+", " ")
        if #s > 120 then s = s:sub(1, 120) .. "..." end
        return s
    end

    local function getJson(url)
        -- Important for some Lite executors: game:HttpGet can return an
        -- HTML/proxy page while request() returns the actual Worker JSON.
        local body, firstErr, firstMethod = httpGet(url)
        local data = decode(body)
        if data then
            return data, nil, firstMethod
        end

        -- If the first successful transport returned non-JSON, explicitly
        -- retry with the executor request API instead of accepting that body.
        if firstMethod ~= "request" then
            local retryBody, retryErr = requestBody(url)
            local retryData = decode(retryBody)
            if retryData then
                return retryData, nil, "request"
            end

            local detail = responsePreview(retryBody)
            if detail == "" then detail = responsePreview(body) end
            return nil,
                "API balas non-JSON"
                .. (detail ~= "" and (": " .. detail) or "")
                .. (retryErr and (" | " .. tostring(retryErr)) or ""),
                "request"
        end

        local detail = responsePreview(body)
        return nil,
            "API balas non-JSON" .. (detail ~= "" and (": " .. detail) or "")
            .. (firstErr and (" | " .. tostring(firstErr)) or ""),
            firstMethod
    end

    local function ensureFolder(path)
        if type(makefolder) ~= "function" then return end
        local exists = false
        if type(isfolder) == "function" then
            pcall(function() exists = isfolder(path) end)
        end
        if not exists then pcall(makefolder, path) end
    end

    local function prepareLogo()
        Env.AliceHUBLogoAsset = FALLBACK_LOGO
        Env.AliceHUBBrandLogoAsset = FALLBACK_LOGO

        if type(writefile) ~= "function" then return end

        ensureFolder("AliceHUB")
        ensureFolder("AliceHUB/assets")

        local logoPath = "AliceHUB/BrandLogo.png"
        local assetPath = "AliceHUB/assets/BrandLogo.png"
        local versionPath = "AliceHUB/assets/BrandLogo.version"
        local wantedVersion = "2"

        local currentVersion
        if type(readfile) == "function" and type(isfile) == "function" then
            local exists = false
            pcall(function() exists = isfile(versionPath) end)
            if exists then
                pcall(function() currentVersion = tostring(readfile(versionPath) or "") end)
            end
        end

        local logoExists = false
        if type(isfile) == "function" then
            pcall(function() logoExists = isfile(logoPath) end)
        end

        if not logoExists or currentVersion ~= wantedVersion then
            local bytes = httpGet(
                API .. "/assets/logo?v=" .. HttpService:UrlEncode(wantedVersion)
                    .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
            )
            if type(bytes) == "string" and #bytes > 100 then
                pcall(writefile, logoPath, bytes)
                pcall(writefile, assetPath, bytes)
                pcall(writefile, versionPath, wantedVersion)
                logoExists = true
            end
        end

        local getAsset = getcustomasset or getsynasset
        if logoExists and type(getAsset) == "function" then
            local ok, asset = pcall(getAsset, logoPath)
            if ok and type(asset) == "string" and asset ~= "" then
                Env.AliceHUBLogoAsset = asset
                Env.AliceHUBBrandLogoAsset = asset
                Env.AliceHUBLogoPath = logoPath
            end
        end
    end

    local function randomClientId()
        local ok, guid = pcall(function()
            return HttpService:GenerateGUID(false)
        end)
        if ok and type(guid) == "string" and #guid > 0 then
            return ("AHC_" .. guid):gsub("[^%w_-]", "")
        end
        return "AHC_" .. tostring(Player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    end

    local function getClientId()
        ensureFolder("AliceHUB")
        local path = "AliceHUB/client_instance.id"

        if type(isfile) == "function" and type(readfile) == "function" then
            local exists = false
            pcall(function() exists = isfile(path) end)
            if exists then
                local value
                pcall(function() value = tostring(readfile(path) or "") end)
                value = value and value:gsub("[^%w_-]", "") or ""
                if #value >= 8 and #value <= 96 then return value end
            end
        end

        local value = randomClientId()
        if type(writefile) == "function" then pcall(writefile, path, value) end
        return value
    end

    setBoot("Preparing...")
    pcall(prepareLogo)

    -- End previous lease only after the new execution has visibly started.
    if type(Env.AliceHUBReleaseSession) == "function" then
        pcall(Env.AliceHUBReleaseSession)
    end
    if Env.AliceHUBTeleportConnection then
        pcall(function() Env.AliceHUBTeleportConnection:Disconnect() end)
        Env.AliceHUBTeleportConnection = nil
    end

    Env.AliceHUBHeartbeatGeneration = (tonumber(Env.AliceHUBHeartbeatGeneration) or 0) + 1
    local generation = Env.AliceHUBHeartbeatGeneration
    local clientId = getClientId()

    local function acquire()
        setBoot("Connecting...")
        local url =
            API
            .. "/client/session?token=" .. HttpService:UrlEncode(token)
            .. "&username=" .. HttpService:UrlEncode(Player.Name)
            .. "&userId=" .. HttpService:UrlEncode(tostring(Player.UserId))
            .. "&clientId=" .. HttpService:UrlEncode(clientId)
            .. "&gameId=" .. HttpService:UrlEncode(tostring(game.GameId))
            .. "&placeId=" .. HttpService:UrlEncode(tostring(game.PlaceId))
            .. "&t=" .. HttpService:UrlEncode(tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999)))

        local data, err, method = getJson(url)
        if not data then
            return nil, tostring(err or "Response API tidak valid")
        end
        if not data.ok then
            return nil, tostring(data.error or data.code or "Authorization gagal")
        end
        Env.AliceHUBLastTransport = method
        if type(data.session) ~= "string" or type(data.lease) ~= "string" then
            return nil, "Session API tidak lengkap"
        end
        return data
    end

    local sessionData, sessionErr = acquire()
    if not sessionData then fail(sessionErr) end

    setBoot("Authorized • " .. tostring(sessionData.slots and sessionData.slots.used or "?")
        .. "/" .. tostring(sessionData.slots and sessionData.slots.max or "?"))

    local lease = sessionData.lease
    local heartbeatEvery = math.max(15, tonumber(sessionData.heartbeatEvery) or 30)
    local activeTtl = math.max(60, tonumber(sessionData.activeSessionTtl) or 150)

    local function apply(data)
        if type(data.access) == "table" then
            Env.AliceHUBAccess = {
                status = data.access.status or data.access.plan or "Active",
                plan = data.access.plan,
                expiresAt = data.access.expiresAt,
                permanent = data.access.permanent == true
            }
        end
        if type(data.slots) == "table" then
            Env.AliceHUBSlots = {
                used = tonumber(data.slots.used) or 0,
                max = tonumber(data.slots.max) or 0
            }
        end
        Env.AliceHUBActiveSession = {
            username = Player.Name,
            userId = Player.UserId,
            clientId = clientId,
            slotMode = "active_sessions",
            heartbeatEvery = heartbeatEvery,
            autoReleaseSeconds = activeTtl
        }
    end
    apply(sessionData)

    local function release()
        if generation ~= Env.AliceHUBHeartbeatGeneration then return false end
        local currentLease = lease
        if type(currentLease) ~= "string" or currentLease == "" then return false end
        lease = nil
        local body = httpGet(
            API .. "/client/release?lease=" .. HttpService:UrlEncode(currentLease)
                .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
        )
        return type(body) == "string"
    end

    Env.AliceHUBReleaseSession = release

    local okTeleport, teleportConnection = pcall(function()
        return Player.OnTeleport:Connect(function(state)
            if generation == Env.AliceHUBHeartbeatGeneration and state == Enum.TeleportState.Started then
                pcall(release)
            end
        end)
    end)
    if okTeleport then Env.AliceHUBTeleportConnection = teleportConnection end

    task.spawn(function()
        local failures = 0
        while generation == Env.AliceHUBHeartbeatGeneration do
            task.wait(heartbeatEvery)
            if generation ~= Env.AliceHUBHeartbeatGeneration then return end

            local heartbeatOk = false
            if type(lease) == "string" and lease ~= "" then
                local data = select(1, getJson(
                    API .. "/client/heartbeat?lease=" .. HttpService:UrlEncode(lease)
                        .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
                ))
                if data and data.ok then
                    heartbeatOk = true
                    failures = 0
                    heartbeatEvery = math.max(15, tonumber(data.heartbeatEvery) or heartbeatEvery)
                    activeTtl = math.max(60, tonumber(data.activeSessionTtl) or activeTtl)
                    if type(data.slots) == "table" then
                        Env.AliceHUBSlots = {
                            used = tonumber(data.slots.used) or 0,
                            max = tonumber(data.slots.max) or 0
                        }
                    end
                end
            end

            if not heartbeatOk then
                failures = failures + 1
                if failures >= 2 then
                    local fresh = acquire()
                    if fresh then
                        sessionData = fresh
                        lease = fresh.lease
                        heartbeatEvery = math.max(15, tonumber(fresh.heartbeatEvery) or heartbeatEvery)
                        activeTtl = math.max(60, tonumber(fresh.activeSessionTtl) or activeTtl)
                        failures = 0
                        apply(fresh)
                    end
                end
            end
        end
    end)

    setBoot("Loading " .. tostring(sessionData.game and sessionData.game.target or "payload") .. "...")

    local payload, payloadErr = httpGet(
        API .. "/script?session=" .. HttpService:UrlEncode(sessionData.session)
            .. "&t=" .. HttpService:UrlEncode(tostring(os.time()))
    )
    if type(payload) ~= "string" then fail("Payload HTTP gagal: " .. tostring(payloadErr)) end

    local chunk, compileError = loadstring(payload)
    if type(chunk) ~= "function" then fail("Payload compile gagal: " .. tostring(compileError)) end

    setBoot("Loaded")
    destroyBoot(1.2)

    local okRun, runErr = pcall(chunk)
    if not okRun then fail("Payload error: " .. tostring(runErr)) end
end
