local state = require("greviewer.state")
local buffer = require("greviewer.ui.buffer")
local cli = require("greviewer.cli")

local M = {}

local ns = vim.api.nvim_create_namespace("greviewer_comments")

local function define_highlights()
    vim.api.nvim_set_hl(0, "GReviewerComment", { fg = "#61afef", italic = true, default = true })
    vim.api.nvim_set_hl(0, "GReviewerCommentSign", { fg = "#61afef", bold = true, default = true })
end

function M.add_at_cursor()
    define_highlights()

    local file = buffer.get_current_file_from_buffer()
    local pr_url = buffer.get_pr_url_from_buffer()

    if not file or not pr_url then
        vim.notify("Not in a review buffer", vim.log.levels.WARN)
        return
    end

    local line = vim.api.nvim_win_get_cursor(0)[1]

    vim.ui.input({ prompt = "Comment: " }, function(body)
        if not body or body == "" then
            return
        end

        vim.notify("Submitting comment...", vim.log.levels.INFO)

        cli.add_comment(pr_url, {
            path = file.path,
            line = line,
            side = "RIGHT",
            body = body,
        }, function(data, err)
            if err then
                vim.notify("Failed to add comment: " .. err, vim.log.levels.ERROR)
                return
            end

            vim.notify("Comment added!", vim.log.levels.INFO)

            local comment = {
                id = data.comment_id,
                path = file.path,
                line = line,
                side = "RIGHT",
                body = body,
                author = "you",
                created_at = os.date("%Y-%m-%dT%H:%M:%S"),
                html_url = data.html_url or "",
            }
            state.add_comment(comment)

            local bufnr = vim.api.nvim_get_current_buf()
            M.show_comment(bufnr, comment)
        end)
    end)
end

function M.show_comment(bufnr, comment)
    if not comment.line then
        return
    end

    local row = comment.line - 1
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if row >= line_count then
        return
    end

    local display_body = comment.body
    if #display_body > 50 then
        display_body = display_body:sub(1, 47) .. "..."
    end
    display_body = display_body:gsub("\n", " ")

    local text = string.format(" %s: %s", comment.author, display_body)

    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        virt_text = { { text, "GReviewerComment" } },
        virt_text_pos = "eol",
        sign_text = "",
        sign_hl_group = "GReviewerCommentSign",
        priority = 20,
    })
end

function M.show_existing(bufnr, file_path)
    define_highlights()

    local comments = state.get_comments_for_file(file_path)

    for _, comment in ipairs(comments) do
        M.show_comment(bufnr, comment)
    end
end

function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
