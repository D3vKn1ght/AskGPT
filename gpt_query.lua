local API_KEY = require("api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")

local function queryChatGPT(message_history)
  local api_url = "http://trungtran.id.vn:8000/chat/"

  local requestBody = json.encode({
    model = "gpt-3.5-turbo",
    messages = message_history,
  })

  local responseBody = {}

  local res, code, responseHeaders = https.request {
    url = api_url,
    method = "POST",
    headers = {
      ["accept"] = "application/json",
      ["Content-Type"] = "application/json",
      ["Content-Length"] = tostring(#requestBody)
    },
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  if code ~= 200 then
    error("Error querying ChatGPT API: " .. code)
  end

  local response = json.decode(table.concat(responseBody))
  return response.choices[1].message.content
end

return queryChatGPT
