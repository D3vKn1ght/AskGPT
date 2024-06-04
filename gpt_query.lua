local https = require("api_key")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("json")

local function queryGemini(message_history)
  local api_key = API_KEY
  local api_url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=" .. api_key

  local headers = {
    ["Content-Type"] = "application/json",
  }

  local requestBody = json.encode({
    contents = message_history
  })

  local responseBody = {}

  local res, code, responseHeaders = https.request {
    url = api_url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  -- -- Debugging: Print the request and response details
  -- print("Request URL: ", api_url)
  -- print("Request Headers: ", json.encode(headers))
  -- print("Request Body: ", requestBody)
  -- print("Response Code: ", code)
  -- print("Response Body: ", table.concat(responseBody))

  if code ~= 200 then
    return "Có lỗi xảy ra, mã lỗi: " .. tostring(code) .. "\nPhản hồi: " .. table.concat(responseBody)
  end

  local response = json.decode(table.concat(responseBody))
  return response.candidates[1].content.parts[1].text
end

return queryGemini
