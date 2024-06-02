local InputDialog = require("ui/widget/inputdialog")
local ChatGPTViewer = require("chatgptviewer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local queryChatGPT = require("gpt_query")

local function showChatGPTDialog(ui, highlightedText, message_history)
  local title, author =
      ui.document:getProps().title or _("Unknown Title"),
      ui.document:getProps().authors or _("Unknown Author")
  local message_history = message_history or {
    {
      role = "system",
      content =
      "The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly.  Answer as concisely as possible in Vietnamese.",
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

            -- Give context to the question
            local context_message = {
              role = "user",
              content = "I'm reading something titled '" ..
                  title ..
                  "' by " .. author .. ". I have a question about the following highlighted text: " .. highlightedText,
            }
            table.insert(message_history, context_message)

            -- Ask the question
            local question = input_dialog:getInputText()
            local question_message = {
              role = "user",
              content = question,
            }
            table.insert(message_history, question_message)

            local answer = queryChatGPT(message_history)
            -- Save the answer to the message history
            local answer_message = {
              role = "assistant",
              content = answer,
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
                  result_text = result_text .. _("Người dùng: ") .. message_history[i].content .. "\n\n"
                else
                  result_text = result_text .. _("ChatGPT: ") .. message_history[i].content .. "\n\n"
                end
              end

              return result_text
            end


            local function handleNewQuestion(chatgpt_viewer, question)
              -- Add the new question to the message history
              table.insert(message_history, { role = "user", content = question })

              -- Send the query to ChatGPT with the updated message_history
              local answer = queryChatGPT(message_history)

              -- Add the answer to the message history
              table.insert(message_history, { role = "assistant", content = answer })

              -- Update the result text
              local result_text = createResultText(highlightedText, message_history)

              -- Update the text and refresh the viewer
              chatgpt_viewer:update(result_text)
            end

            local chatgpt_viewer = ChatGPTViewer:new {
              title = _("AskGPT"),
              text = result_text,
              onAskQuestion = handleNewQuestion, -- Pass the callback function
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
