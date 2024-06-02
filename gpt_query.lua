local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

local function queryChatGPT(message_history)
  local api_url = "http://trungtran.id.vn:8000/chat/"

  local requestBody = json.encode({
    model = "gpt-3.5-turbo",
    messages = message_history,
  })

  local responseBody = {}

  local res, code, responseHeaders = http.request {
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

  if not res then
    error("Error querying ChatGPT API: " .. (code or "unknown error"))
  end

  if code ~= 200 then
    error("Error querying ChatGPT API: " .. code .. " " .. (responseBody[1] or ""))
  end

  local response_str = table.concat(responseBody)
  local response = json.decode(response_str)

  -- Debug: print the raw response string
  print("Raw response: ", response_str)

  -- Assuming the response is directly the message
  if not response then
    error("Invalid response from ChatGPT API: " .. response_str)
  end

  return response
end

return queryChatGPT
