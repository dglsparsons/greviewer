local M = {}

local state = {
    active_review = nil,
}

function M.set_review(review_data)
    state.active_review = {
        pr = review_data.pr,
        files = review_data.files,
        comments = review_data.comments,
        current_file_idx = 1,
        buffers = {},
        expanded_hunks = {},
    }
    return state.active_review
end

function M.get_review()
    return state.active_review
end

function M.clear_review()
    if state.active_review then
        for _, buf in pairs(state.active_review.buffers) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end
    state.active_review = nil
end

function M.get_current_file()
    local review = state.active_review
    if not review then
        return nil
    end
    return review.files[review.current_file_idx]
end

function M.set_current_file_idx(idx)
    if state.active_review then
        state.active_review.current_file_idx = idx
    end
end

function M.get_file_buffer(file_path)
    if state.active_review then
        return state.active_review.buffers[file_path]
    end
    return nil
end

function M.set_file_buffer(file_path, bufnr)
    if state.active_review then
        state.active_review.buffers[file_path] = bufnr
    end
end

function M.is_hunk_expanded(file_path, hunk_start)
    if state.active_review then
        local key = file_path .. ":" .. hunk_start
        return state.active_review.expanded_hunks[key] == true
    end
    return false
end

function M.set_hunk_expanded(file_path, hunk_start, expanded)
    if state.active_review then
        local key = file_path .. ":" .. hunk_start
        state.active_review.expanded_hunks[key] = expanded
    end
end

function M.get_comments_for_file(file_path)
    if not state.active_review then
        return {}
    end
    local file_comments = {}
    for _, comment in ipairs(state.active_review.comments) do
        if comment.path == file_path then
            table.insert(file_comments, comment)
        end
    end
    return file_comments
end

function M.add_comment(comment)
    if state.active_review then
        table.insert(state.active_review.comments, comment)
    end
end

return M
