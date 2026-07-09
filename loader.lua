-- // KeyAuth & Public Cloudflare Configuration
local KeyAuth_Config = {
    ApplicationName = "Trustinmypj's Application", 
    OwnerId = "ehokqtt2yF",                 
    Secret = "0ed4639ccc6d837b2400fc35977bef57a6fd7741e84227c48a50e12244555303",               
    Version = "1.0",
    
    -- YOUR UNCRACKABLE PROXY LINK
    SecureBackendUrl = "https://painhub-auth-gateway.trustinmypj.workers.dev", 
    SaveFileName = "painhub_auth_key.txt"
}

-- // Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- // Auto-Detect Mobile Executor Request & File Functions
local customRequest = (request or http_request or syn.request or (http and http.request))
local fileSupport = (isfile and readfile and writefile and delfile)

if not customRequest then
    player:Kick("Your mobile executor does not support secure network requests.")
    return
end

-- // Cleanup Duplicate Loaders
for _, old in pairs(player.PlayerGui:GetChildren()) do
    if old.Name == "PainHub_KeyLoader" then old:Destroy() end
end

-- // Interface Construction (Mobile Responsive Layout)
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "PainHub_KeyLoader"
sg.ResetOnSpawn = false

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 320, 0, 180)
frame.Position = UDim2.new(0.5, -160, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1.5
stroke.Color = Color3.fromRGB(255, 0, 0)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 12)
title.BackgroundTransparency = 1
title.Text = "PAIN HUB | SECURE AUTH"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(0.85, 0, 0, 40)
box.Position = UDim2.new(0.075, 0, 0, 55)
box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
box.Text = ""
box.PlaceholderText = "Enter Key Auth License..."
box.PlaceholderColor3 = Color3.fromRGB(90, 90, 95)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Font = Enum.Font.GothamBold
box.TextSize = 12
box.ClearTextOnFocus = false
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

local boxStroke = Instance.new("UIStroke", box)
boxStroke.Thickness = 1
boxStroke.Color = Color3.fromRGB(50, 50, 55)

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0.85, 0, 0, 40)
btn.Position = UDim2.new(0.075, 0, 0, 110)
btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
btn.Text = "ACTIVATE SCRIPT"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 12
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

-- // Secure KeyAuth API Helper
local sessionId = nil
local function keyAuthRequest(bodyData)
    local response = customRequest({
        Url = "https://keyauth.win/api/1.2/",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/x-www-form-urlencoded" },
        Body = bodyData
    })
    if response and response.Body then return HttpService:JSONDecode(response.Body) end
    return nil
end

-- // Session Core Initialization
local initBody = string.format("type=init&name=%s&ownerid=%s&secret=%s&version=%s",
    HttpService:UrlEncode(KeyAuth_Config.ApplicationName), HttpService:UrlEncode(KeyAuth_Config.OwnerId), HttpService:UrlEncode(KeyAuth_Config.Secret), HttpService:UrlEncode(KeyAuth_Config.Version)
)

local initResult = keyAuthRequest(initBody)
if initResult and initResult.success then sessionId = initResult.sessionid else
    title.Text = "API INITIALIZATION FAILED"
    btn.Text = "ERROR CONNECTING"
    btn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
end

local function getMobileHWID()
    return (gethwid and gethwid()) or (get_hwid and get_hwid()) or game:GetService("RbxAnalyticsService"):GetClientId()
end

-- // Master Authentication Execution Routine
local function startAuthentication(enteredKey)
    if not sessionId then return end
    
    title.TextColor3 = Color3.fromRGB(255, 255, 0)
    title.Text = "AUTHENTICATING HWID..."
    
    local licenseBody = string.format("type=license&key=%s&hwid=%s&sessionid=%s&name=%s&ownerid=%s&secret=%s&version=%s",
        HttpService:UrlEncode(enteredKey), HttpService:UrlEncode(getMobileHWID()), HttpService:UrlEncode(sessionId), 
        HttpService:UrlEncode(KeyAuth_Config.ApplicationName), HttpService:UrlEncode(KeyAuth_Config.OwnerId), 
        HttpService:UrlEncode(KeyAuth_Config.Secret), HttpService:UrlEncode(KeyAuth_Config.Version)
    )
    local authResult = keyAuthRequest(licenseBody)
    
    if authResult and authResult.success then
        title.TextColor3 = Color3.fromRGB(0, 255, 0)
        title.Text = "KEY VALIDATED. FETCHING SOURCE..."
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        btn.Text = "SUCCESS"
        
        if fileSupport then
            writefile(KeyAuth_Config.SaveFileName, enteredKey)
        end
        
        task.wait(0.4)
        
        -- Securely fetch via Cloudflare Worker Proxy passing ONLY the active session ID
        local scriptFetch = customRequest({
            Url = KeyAuth_Config.SecureBackendUrl,
            Method = "GET",
            Headers = {
                ["KeyAuth-Session"] = sessionId
            }
        })
        
        if scriptFetch and scriptFetch.Body and scriptFetch.StatusCode == 200 then
            sg:Destroy()
            local func = loadstring(scriptFetch.Body)
            if func then func() end
        else
            box.Text = ""
            title.TextColor3 = Color3.fromRGB(255, 0, 0)
            title.Text = "SECURE ENGINE FETCH FAILED"
        end
    else
        box.Text = ""
        title.TextColor3 = Color3.fromRGB(255, 0, 0)
        local errMsg = (authResult and authResult.message) or "UNKNOWN ERROR"
        title.Text = errMsg:upper()
        btn.Text = "ACTIVATE SCRIPT"
        btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        
        if fileSupport and isfile(KeyAuth_Config.SaveFileName) then
            delfile(KeyAuth_Config.SaveFileName)
        end
        
        local originalPos = frame.Position
        for i = 1, 5 do
            frame.Position = originalPos + UDim2.new(0, math.random(-4, 4), 0, 0)
            task.wait(0.02)
        end
        frame.Position = originalPos
    end
end

btn.MouseButton1Click:Connect(function()
    local enteredKey = box.Text:gsub("%s+", "")
    if enteredKey == "" then return end
    startAuthentication(enteredKey)
end)

if sessionId and fileSupport and isfile(KeyAuth_Config.SaveFileName) then
    local cachedKey = readfile(KeyAuth_Config.SaveFileName):gsub("%s+", "")
    if cachedKey ~= "" then
        box.Text = cachedKey
        title.Text = "DETECTED SAVED KEY..."
        task.wait(0.2)
        task.spawn(function()
            startAuthentication(cachedKey)
        end)
    end
end
