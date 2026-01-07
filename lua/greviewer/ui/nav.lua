local M = {}

local function collect_change_lines(hunks)
    local lines = {}
    local seen = {}
    for _, hunk in ipairs(hunks) do
        for _, ln in ipairs(hunk.added_lines or {}) do
            if not seen[ln] then
                table.insert(lines, ln)
                seen[ln] = true
            end
        end
        for _, ln in ipairs(hunk.deleted_at or {}) do
            if not seen[ln] then
                table.insert(lines, ln)
                seen[ln] = true
            end
        end
    end
    table.sort(lines)
    return lines
end

function M.next_hunk(wrap)
    local buffer = require("greviewer.ui.buffer")
    local file = buffer.get_current_file_from_buffer()
    if not file then
        vim.notify("Not in a review buffer", vim.log.levels.WARN)
        return
    end

    local hunks = file.hunks
    if not hunks or #hunks == 0 then
        vim.notify("No changes in this file", vim.log.levels.INFO)
        return
    end

    local change_lines = collect_change_lines(hunks)
    if #change_lines == 0 then
        vim.notify("No changes in this file", vim.log.levels.INFO)
        return
    end

    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    for _, ln in ipairs(change_lines) do
        if ln > cursor_line then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { ln, 0 })
            vim.cmd("normal! zz")
            return
        end
    end

    if wrap then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { change_lines[1], 0 })
        vim.cmd("normal! zz")
        vim.notify("Wrapped to first change", vim.log.levels.INFO)
    else
        vim.notify("No more changes below", vim.log.levels.INFO)
    end
end

function M.prev_hunk(wrap)
    local buffer = require("greviewer.ui.buffer")
    local file = buffer.get_current_file_from_buffer()
    if not file then
        vim.notify("Not in a review buffer", vim.log.levels.WARN)
        return
    end

    local hunks = file.hunks
    if not hunks or #hunks == 0 then
        vim.notify("No changes in this file", vim.log.levels.INFO)
        return
    end

    local change_lines = collect_change_lines(hunks)
    if #change_lines == 0 then
        vim.notify("No changes in this file", vim.log.levels.INFO)
        return
    end

    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    for i = #change_lines, 1, -1 do
        if change_lines[i] < cursor_line then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { change_lines[i], 0 })
            vim.cmd("normal! zz")
            return
        end
    end

    if wrap then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { change_lines[#change_lines], 0 })
        vim.cmd("normal! zz")
        vim.notify("Wrapped to last change", vim.log.levels.INFO)
    else
        vim.notify("No more changes above", vim.log.levels.INFO)
    end
end

function M.first_hunk()
    local buffer = require("greviewer.ui.buffer")
    local file = buffer.get_current_file_from_buffer()
    if not file then
        return
    end

    local change_lines = collect_change_lines(file.hunks or {})
    if #change_lines > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { change_lines[1], 0 })
        vim.cmd("normal! zz")
    end
end

function M.last_hunk()
    local buffer = require("greviewer.ui.buffer")
    local file = buffer.get_current_file_from_buffer()
    if not file then
        return
    end

    local change_lines = collect_change_lines(file.hunks or {})
    if #change_lines > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { change_lines[#change_lines], 0 })
        vim.cmd("normal! zz")
    end
end

return M
