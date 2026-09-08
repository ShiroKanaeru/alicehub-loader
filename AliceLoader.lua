-- AliceHUB Loader
local API = "https://alicehub-api.shirokanaerus.workers.dev"
local FALLBACK_LOGO = "rbxassetid://71638246809611"

return function(token)
    assert(type(token) == "string" and #token > 0, "AliceHUB: token missing")

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local Player = Players.LocalPlayer
    assert(Player, "AliceHUB: LocalPlayer not found")

    local Env = (getgenv and getgenv()) or _G
    Env.AliceClientToken = token

    local function httpGet(url)
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)
        if not ok then
            return nil, tostring(result)
        end
        return result
    end

    local function ensureFolder(path)
        if type(makefolder) ~= "function" then return end
        local ok, exists = pcall(function()
            return type(isfolder) == "function" and isfolder(path)
        end)
        if not ok or not exists then
            pcall(makefolder, path)
        end
    end

    local function prepareLogo()
        Env.AliceHUBLogoAsset = FALLBACK_LOGO

        if type(writefile) ~= "function" then
            return
        end

        ensureFolder("AliceHUB")
        ensureFolder("AliceHUB/assets")

        local logoPath = "AliceHUB/BrandLogo.png"
        local assetPath = "AliceHUB/assets/BrandLogo.png"
        local versionPath = "AliceHUB/assets/BrandLogo.version"
        local wantedVersion = "2"

        local currentVersion
        if type(readfile) == "function" and type(isfile) == "function" then
            local okVersion, versionExists = pcall(isfile, versionPath)
            if okVersion and versionExists then
                pcall(function()
                    currentVersion = tostring(readfile(versionPath) or "")
                end)
            end
        end

        local logoExists = false
        if type(isfile) == "function" then
            pcall(function()
                logoExists = isfile(logoPath)
            end)
        end

        if not logoExists or currentVersion ~= wantedVersion then
            local bytes = httpGet(API .. "/assets/logo?v=" .. HttpService:UrlEncode(wantedVersion))
            if type(bytes) == "string" and #bytes > 100 then
                pcall(writefile, logoPath, bytes)
                pcall(writefile, assetPath, bytes)
                pcall(writefile, versionPath, wantedVersion)
                logoExists = true
            end
        end

        local getAsset = getcustomasset or getsynasset
        if logoExists and type(getAsset) == "function" then
            local okAsset, asset = pcall(getAsset, logoPath)
            if okAsset and type(asset) == "string" and #asset > 0 then
                Env.AliceHUBLogoAsset = asset
                Env.AliceHUBBrandLogoAsset = asset
                Env.AliceHUBLogoPath = logoPath
            end
        end
    end

    pcall(prepareLogo)

    local sessionBody, sessionErr = httpGet(
        API
            .. "/client/session?token=" .. HttpService:UrlEncode(token)
            .. "&username=" .. HttpService:UrlEncode(Player.Name)
            .. "&gameId=" .. HttpService:UrlEncode(tostring(game.GameId))
            .. "&placeId=" .. HttpService:UrlEncode(tostring(game.PlaceId))
    )
    assert(type(sessionBody) == "string", "AliceHUB HTTP error: " .. tostring(sessionErr))

    local decodeOk, sessionData = pcall(function()
        return HttpService:JSONDecode(sessionBody)
    end)
    assert(decodeOk and type(sessionData) == "table", "AliceHUB: invalid session response")
    assert(sessionData.ok and type(sessionData.session) == "string",
        sessionData.error or "AliceHUB authorization failed")

    if type(sessionData.access) == "table" then
        Env.AliceHUBAccess = {
            status = sessionData.access.status or sessionData.access.plan or "Active",
            plan = sessionData.access.plan,
            expiresAt = sessionData.access.expiresAt,
            permanent = sessionData.access.permanent == true,
        }
    end

    local payload, payloadErr = httpGet(
        API .. "/script?session=" .. HttpService:UrlEncode(sessionData.session)
    )
    assert(type(payload) == "string", "AliceHUB payload error: " .. tostring(payloadErr))

    local chunk, compileError = loadstring(payload)
    assert(type(chunk) == "function", "AliceHUB payload compile failed: " .. tostring(compileError))
    return chunk()
end
