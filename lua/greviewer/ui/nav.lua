local M = {}

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

    local line = vim.api.nvim_win_get_cursor(0)[1]

    for _, hunk in ipairs(hunks) do
        if hunk.start > line then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { hunk.start, 0 })
            vim.cmd("normal! zz")
            return
        end
    end

    if wrap and #hunks > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { hunks[1].start, 0 })
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

    local line = vim.api.nvim_win_get_cursor(0)[1]

    for i = #hunks, 1, -1 do
        local hunk = hunks[i]
        local hunk_end = hunk.start + math.max(hunk.count - 1, 0)
        if hunk_end < line then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { hunk.start, 0 })
            vim.cmd("normal! zz")
            return
        end
    end

    if wrap and #hunks > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { hunks[#hunks].start, 0 })
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

    local hunks = file.hunks
    if hunks and #hunks > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { hunks[1].start, 0 })
        vim.cmd("normal! zz")
    end
end

function M.last_hunk()
    local buffer = require("greviewer.ui.buffer")
    local file = buffer.get_current_file_from_buffer()
    if not file then
        return
    end

    local hunks = file.hunks
    if hunks and #hunks > 0 then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, { hunks[#hunks].start, 0 })
        vim.cmd("normal! zz")
    end
end

return M
