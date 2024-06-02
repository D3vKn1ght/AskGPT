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

  local res, code, responseHeaders, status = http.request({
    url = api_url,
    method = "POST",
    headers = {
      ["accept"] = "application/json",
      ["Content-Type"] = "application/json",
      ["Content-Length"] = tostring(#requestBody)
    },
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  })

  if not res then
    return "Có lỗi xảy ra, vui lòng thử lại sau"
  end

  if code ~= 200 then
    return "Có lỗi xảy ra, mã lỗi: " .. tostring(code)
  end

  local response_str = table.concat(responseBody)
  local success, response = pcall(json.decode, response_str)

  if not success then
    return "Có lỗi xảy ra trong quá trình giải mã phản hồi, vui lòng thử lại sau"
  end

  return response
end

return queryChatGPT
