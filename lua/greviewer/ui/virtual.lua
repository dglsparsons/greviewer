local state = require("greviewer.state")
local buffer = require("greviewer.ui.buffer")

local M = {}

local ns = vim.api.nvim_create_namespace("greviewer_virtual")

local function define_highlights()
    vim.api.nvim_set_hl(0, "GReviewerVirtualBorder", { fg = "#5c6370", default = true })
    vim.api.nvim_set_hl(0, "GReviewerVirtualText", { fg = "#abb2bf", bg = "#3e4451", default = true })
    vim.api.nvim_set_hl(0, "GReviewerVirtualDelete", { fg = "#e06c75", bg = "#3b2d2d", default = true })
end

function M.toggle_at_cursor()
    define_highlights()

    local file = buffer.get_current_file_from_buffer()
    if not file then
        vim.notify("Not in a review buffer", vim.log.levels.WARN)
        return
    end

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local hunk = M.find_hunk_at_line(file.hunks, line)

    if not hunk then
        vim.notify("No changes at cursor position", vim.log.levels.INFO)
        return
    end

    if #hunk.old_lines == 0 then
        vim.notify("No old content to show (pure addition)", vim.log.levels.INFO)
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local is_expanded = state.is_hunk_expanded(file.path, hunk.start)

    if is_expanded then
        M.collapse(bufnr, hunk, file.path)
    else
        M.expand(bufnr, hunk, file.path)
    end
end

function M.expand(bufnr, hunk, file_path)
    local virt_lines = {}

    local border_width = 50
    local header = hunk.hunk_type == "delete" and " deleted " or " was "
    local top_border = string.format(
        "%s%s%s",
        string.rep("─", 2),
        header,
        string.rep("─", math.max(border_width - #header - 2, 0))
    )
    table.insert(virt_lines, { { "╭" .. top_border, "GReviewerVirtualBorder" } })

    for _, old_line in ipairs(hunk.old_lines) do
        local hl = hunk.hunk_type == "delete" and "GReviewerVirtualDelete" or "GReviewerVirtualText"
        table.insert(virt_lines, { { "│ " .. old_line, hl } })
    end

    local bottom_border = string.rep("─", border_width)
    table.insert(virt_lines, { { "╰" .. bottom_border, "GReviewerVirtualBorder" } })

    local row = math.max(hunk.start - 1, 0)
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if row >= line_count then
        row = line_count - 1
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        id = hunk.start,
        virt_lines = virt_lines,
        virt_lines_above = true,
    })

    state.set_hunk_expanded(file_path, hunk.start, true)
end

function M.collapse(bufnr, hunk, file_path)
    vim.api.nvim_buf_del_extmark(bufnr, ns, hunk.start)
    state.set_hunk_expanded(file_path, hunk.start, false)
end

function M.find_hunk_at_line(hunks, line)
    if not hunks then
        return nil
    end

    for _, hunk in ipairs(hunks) do
        local hunk_end = hunk.start + math.max(hunk.count - 1, 0)

        if hunk.hunk_type == "delete" then
            if line == hunk.start or line == hunk.start - 1 then
                return hunk
            end
        else
            if line >= hunk.start and line <= hunk_end then
                return hunk
            end
        end
    end

    return nil
end

function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
