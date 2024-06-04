local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local queryGemini = require("gpt_query")

local function showChatGPTDialog(ui, highlightedText, message_history)
  local title, author =
      ui.document:getProps().title or _("Unknown Title"),
      ui.document:getProps().authors or _("Unknown Author")
  local message_history = message_history or {
    {
      role = "system",
      content =
      "The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly. Answer as concisely as possible in Vietnamese.",
    },
  }
  local input_dialog
  input_dialog = InputDialog:new {
    title = _("Hỏi một câu hỏi về đoạn văn này"),
    input_hint = _("Nhập câu hỏi của bạn ở đây..."),
    input_type = "text",
    buttons = {
      {
        {
          text = _("Hủy bỏ"),
          callback = function()
            UIManager:close(input_dialog)
          end,
        },
        {
          text = _("Hỏi"),
          callback = function()
            local InfoMessage = require("ui/widget/infomessage")
            local loading = InfoMessage:new {
              text = _("Loading..."),
              timeout = 1,
            }
            UIManager:show(loading)

            -- Cung cấp ngữ cảnh cho câu hỏi
            local context_message = {
              role = "user",
              parts = {
                { text = "I'm reading something titled '" .. title .. "' by " .. author .. ". I have a question about the following highlighted text: " .. highlightedText }
              }
            }
            table.insert(message_history, context_message)

            -- Đặt câu hỏi
            local question = input_dialog:getInputText()
            if question == "" then
              question = _("What is the meaning of this?")
            end
            local question_message = {
              role = "user",
              parts = {
                { text = question }
              }
            }
            table.insert(message_history, question_message)

            local answer = queryGemini(message_history)
            -- Lưu câu trả lời vào lịch sử tin nhắn
            local answer_message = {
              role = "assistant",
              parts = {
                { text = answer }
              }
            }

            table.insert(message_history, answer_message)
            UIManager:close(input_dialog)
            local result_text = _("Văn bản được đánh dấu: ") .. "\"" .. highlightedText .. "\"" ..
                "\n\n" .. _("Người dùng: ") .. question ..
                "\n\n" .. _("ChatGPT: ") .. answer

            local function createResultText(highlightedText, message_history)
              local result_text = _("Văn bản được đánh dấu: ") .. "\"" .. highlightedText .. "\"\n\n"

              for i = 3, #message_history do
                if message_history[i].role == "user" then
                  result_text = result_text .. _("Người dùng: ") .. message_history[i].parts[1].text .. "\n\n"
                else
                  result_text = result_text .. _("ChatGPT: ") .. message_history[i].parts[1].text .. "\n\n"
                end
              end

              return result_text
            end


            local function handleNewQuestion(chatgpt_viewer, question)
              -- Thêm câu hỏi mới vào lịch sử tin nhắn
              table.insert(message_history, { role = "user", parts = { { text = question } } })

              -- Gửi truy vấn đến Gemini với lịch sử tin nhắn đã cập nhật
              local answer = queryGemini(message_history)

              -- Thêm câu trả lời vào lịch sử tin nhắn
              table.insert(message_history, { role = "assistant", parts = { { text = answer } } })

              -- Cập nhật văn bản kết quả
              local result_text = createResultText(highlightedText, message_history)

              -- Cập nhật văn bản và làm mới viewer
              chatgpt_viewer:update(result_text)
            end

            local chatgpt_viewer = ChatGPTViewer:new {
              title = _("AskGPT"),
              text = result_text,
              onAskQuestion = handleNewQuestion, -- Truyền callback function
            }

            UIManager:show(chatgpt_viewer)
          end,
        },
      },
    },
  }
  UIManager:show(input_dialog)
  input_dialog:onShowKeyboard()
end

return showChatGPTDialog
