local HttpService = game:GetService("HttpService")

local function getRequester()
    return http_request or request or (syn and syn.request) or (http and http.request)
end

local requester = getRequester()
if not requester then
    warn("Aucune fonction HTTP disponible dans cet environnement.")
    return
end

local function postPayload(payload)
    local body = HttpService:JSONEncode(payload)
    local ok, res = pcall(function()
        return requester({
            Url = webhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Content-Length"] = tostring(#body) },
            Body = body
        })
    end)
    if not ok then
        return false, res
    end
    return true, res
end

local function splitMessage(text, maxLen)
    maxLen = maxLen or 1900
    local parts = {}
    local i = 1
    while i <= #text do
        local chunk = text:sub(i, i + maxLen - 1)
        table.insert(parts, chunk)
        i = i + maxLen
    end
    return parts
end

local function sendLongText(text)
    local parts = splitMessage(text)
    for idx, part in ipairs(parts) do
        local payload = { content = string.format("Part %d/%d\n```%s```", idx, #parts, part) }
        local ok, res = postPayload(payload)
        if not ok then
            warn("Envoi vers webhook échoué :", res)
            return false
        end
    end
    return true
end

function printToDiscord(text)
    if #text <= 1900 then
        local payload = { content = string.format("```%s```", text) }
        local ok, res = postPayload(payload)
        if not ok then
            warn("Envoi vers webhook échoué :", res)
            return false
        end
        return true
    else
        return sendLongText(text)
    end
end
